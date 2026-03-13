/**
 * @File Name          : SpsTriggerHandler_Test.cls
 * @Description        : Test class for SpsTriggerHandler.
 * @Author             : Nick Guia
 * @Group              : Lead Management
 */
@IsTest(isParallel=true)
private class SpsTriggerHandler_Test {

	private static Integer MAX_SPS_RECORD;

	@TestSetup
	static void setup(){
		//Turn on environment settings - Exploding Leads Active
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
		insert envSettings;

		//create a Monash University Global Account record and use ID in custom setting
		Id globalMonashId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

		//create Mutex record for managing asynchronous Exploding Leads
		AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
		String appName = AsyncExplodingLeadsDispatcher.CONFIG_NAME;
		dispatcher.getConfig();
		MAX_SPS_RECORD = dispatcher.batchSize;

		//insert mutex record
		Mutex__c mutexRec = new Mutex__c();
		mutexRec.Name = appName;
		mutexRec.is_Locked__c = false;
		insert mutexRec;
	}

	/**
	 * @description test logic for inserting new SPS records with
	 *  Is_Synchronous__c = true
	 *  The result should be SPS with Status = 'Success' and
	 *  Exploded_Target__c should be populated
	 */
	@isTest
	static void explodingLeadsInsertSyncTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(1);
		//make all sps records run synchronously
		for(Staged_Prospective_Student__c iSps : spsList) {
			iSps.Is_Synchronous__c = true;
		}

		Test.startTest();

		//insert sps
		insert spsList;

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

	/**
	 * @description test logic for Re-processing SPS records with
	 *  Is_Synchronous__c = true
	 *  The result should be SPS with Status = 'Success' and
	 *  Exploded_Target__c should be populated
	 */
	@isTest
	static void explodingLeadsUpdateSyncTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(1);
		//make all sps records run synchronously
		for(Staged_Prospective_Student__c iSps : spsList) {
			iSps.Is_Synchronous__c = true;
			//set status to 'Partial Error' so it won't process just yet
			iSps.Status__c = Label.SPS_Status_Partial_Error;
		}
		insert spsList;

		Test.startTest();

		//update sps statuses to 'Re-process'
		for(Staged_Prospective_Student__c iSps : spsList) {
			iSps.Status__c = Label.SPS_Status_Reprocess;
		}
		update spsList;

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

	/**
	 * @description test logic for inserting new SPS records with
	 *  Is_Synchronous__c = false
	 *  The result should be SPS with Status = 'Success' and
	 *  Exploded_Target__c should be populated
	 */
	@isTest
	static void explodingLeadsInsertAsyncTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(1);
		//make all sps records run synchronously
		for(Staged_Prospective_Student__c iSps : spsList) {
			iSps.Is_Synchronous__c = false;
		}

		Test.startTest();

		//insert sps
		insert spsList;

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

	/**
	 * @description test logic for Re-processing SPS records with
	 *  Is_Synchronous__c = false
	 *  The result should be SPS with Status = 'Success' and
	 *  Exploded_Target__c should be populated
	 */
	@isTest
	static void explodingLeadsUpdateAsyncTest() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(1);
		//make all sps records run synchronously
		for(Staged_Prospective_Student__c iSps : spsList) {
			iSps.Is_Synchronous__c = false;
			//set status to 'Partial Error' so it won't process just yet
			iSps.Status__c = Label.SPS_Status_Partial_Error;
		}
		insert spsList;

		Test.startTest();

		//update sps statuses to 'Re-process'
		for(Staged_Prospective_Student__c iSps : spsList) {
			iSps.Status__c = Label.SPS_Status_Reprocess;
		}
		update spsList;

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

	/**
	 * @description test bulk insert of SPS records. This process leverages
	 *  the MutexLock mechanism to prevent race condition, and locking contention.
	 *  The bulk insert will be processed by batches (first in - first out)
	 * 	Given that we cannot chain Queueable jobs in unit tests, the maximum
	 * 	number of batch size should be 40
	 */
	@isTest
	static void bulkInsertAsync() {
		List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(MAX_SPS_RECORD);

		Test.startTest();

		insert spsList;

		Test.stopTest();

		Integer count = 0;
		for(Staged_Prospective_Student__c iSps : [SELECT Id, Status__c FROM Staged_Prospective_Student__c]) {
			count++;
            //verify that SPS exploded properly
			System.assertEquals('Success', iSps.Status__c,
			                    'Exploding Leads encountered an error.');
        }
    }
}