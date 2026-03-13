/**
 * @File Name          : QueueExplodeLead_Test.cls
 * @Description        : Test class for QueueExplodeLead.
 * @Author             : Nick Guia
 * @Group              : Lead Management
 */
@isTest(isParallel=true)
private class QueueExplodeLead_Test {

	//since mutex is batched by 30, this cannot be increased further as Queueables
	//cannot be chained on test classes
	private static Integer MAX_SPS_RECORD;

	@TestSetup
	static void setup() {
		AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
		String appName = AsyncExplodingLeadsDispatcher.CONFIG_NAME;
		dispatcher.getConfig();
		MAX_SPS_RECORD = dispatcher.batchSize;

		//create setup sps records before switching on Exploding Leads
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(MAX_SPS_RECORD);
		spsList[0].Exploding_Leads_V2__c = true;
		//switch off trigger so exploding leads won't run yet
		TriggerCommon.disableTrigger('Staged_Prospective_Student__c');
		insert spsList;
		TriggerCommon.enableTrigger('Staged_Prospective_Student__c');

		//Turn on environment settings - Exploding Leads Active
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
		insert envSettings;

		//create a Monash University Global Account record and use ID in custom setting
		Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

		//create Mutex record for managing asynchronous Exploding Leads
		Mutex__c mutexRec = new Mutex__c();
		mutexRec.Name = appName;
		mutexRec.is_Locked__c = false;
		insert mutexRec;
	}

    /**
	 * @description test logic for running Exploding Leads asynchronously:
	 *  Is_Synchronous__c = false
	 *  The result should be SPS with Status = 'Success' and
	 *  Exploded_Target__c should be populated
	 */
	@isTest
	static void executeTest() {
		//initialise AsyncExplodingLeadsDispatcher
		AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();

		Test.startTest();
		dispatcher.start();
		if(dispatcher.acquire()) {
			dispatcher.execute();
		}
		Test.stopTest();

        for(Staged_Prospective_Student__c iSps : [SELECT Id, Status__c, Exploded_Target__c 
            FROM Staged_Prospective_Student__c]) 
        {
			//verify that SPS exploded properly
			System.assertEquals('Success', iSps.Status__c,
			                    'Exploding Leads encountered an error.');

			//verify that Contact got created successully
			System.assert (iSps.Exploded_Target__c != null,
			               'Unable to create Contact record for SPS');
		}
    }
}