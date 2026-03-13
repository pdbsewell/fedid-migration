/**
 * @File Name          : AsyncExplodingLeadsDispatcher_Test.cls
 * @Description        : Test class for AsyncExplodingLeadsDispatcher
 **/
@isTest(isParallel=true)
private class AsyncExplodingLeadsDispatcher_Test {

	@TestSetup
	static void makeData(){
		// get global monash account ID
		Id globalMonashAccountId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;

        AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
        String appName = AsyncExplodingLeadsDispatcher.CONFIG_NAME;

        //insert mutex record
        Mutex__c mutexRec = new Mutex__c();
        mutexRec.Name = appName;
        mutexRec.is_Locked__c = false;
        insert mutexRec;

        List<Staged_Prospective_Student__c> spsList = TestHelper.createSps(1);
        insert spsList;

        //Turn on environment settings - Exploding Leads Active
        //this should always go after creating setup SPS so that they won't process yet
		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Exploding_Leads_Active__c = true;
		insert envSettings;
    }
    /**
     * @description : Test scenario of getting the singleton instance of AsyncExplodingLeadsDispatcher
     */
    @isTest
    static void testGetInstance() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
        Test.stopTest();

        System.assert(dispatcher != null, 'Unable to get an instance of AsyncExplodingLeadsDispatcher!');
    }

    /**
     * @description : Test scenario of initialising AsyncExplodingLeadsDispatcher config information
     */
    @isTest
    static void testStart() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
            dispatcher.start();
        Test.stopTest();
        System.assert(dispatcher.config != null, 'Unable to initialise config data from start method');
    }
    /**
     * @description : Test scenario of acquiring a Mutex lock via an available Mutex__c record
     */
    @isTest
    static void testAcquire() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
            Boolean isAcquire = dispatcher.acquire();
        Test.stopTest();
        System.assert(isAcquire, 'Unable to acquire mutex lock');
    }
    /**
     * @description : Test execution logic. In this scenario, SPS records will be processed,
     *  so we need to Verify that their statuses got updated
     */
    @isTest
    static void testExecute() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
            dispatcher.start();
            dispatcher.acquire();
            dispatcher.execute();
        Test.stopTest();

        //verify that there are no more unprocessed SPS (Status not New or Re-processed)
        List<Staged_Prospective_Student__c> spsList = [SELECT Id, Status__c 
                                                        FROM Staged_Prospective_Student__c
                                                        WHERE Status__c = 'New' 
                                                        OR Status__c = 'Re-processed'];
        System.assert(spsList.isEmpty(), 'Unable to process all SPS records');
    }
    /**
     * @description : Test logic for callback. 
     * Verify that there are no more unprocessed SPS records
     */
    @isTest
    static void testCallBack() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
            dispatcher.start();
            dispatcher.acquire();
            dispatcher.callBack();
        Test.stopTest();

        //verify that there are no more unprocessed SPS (Status not New or Re-processed)
        List<Staged_Prospective_Student__c> spsList = [SELECT Id, Status__c 
                                                        FROM Staged_Prospective_Student__c
                                                        WHERE Status__c = 'New' 
                                                        OR Status__c = 'Re-processed'];
        System.assert(spsList.isEmpty(), 'Unable to process all SPS records');
    }
    /**
     * @description : Test that mutex lock has been released. There should be an available
     *  Mutex record with is_Locked = false
     */
    @isTest
    static void testRelease() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
            dispatcher.start();
            dispatcher.acquire();
            dispatcher.release();
        Test.stopTest();

        Mutex__c mutexRec = [SELECT Id 
                            FROM Mutex__c 
                            WHERE Name = :AsyncExplodingLeadsDispatcher.CONFIG_NAME 
                            AND is_Locked__c = FALSE];
        System.assert(mutexRec != null, 'Unable to release mutex lock after dispatcher callback');
    }

    /**
     * @description : Test load config from metadata. Any config variables should
     *  never be null to properly execute implementation.
     */
    @isTest
    static void testGetConfig() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
            dispatcher.getConfig();
        Test.stopTest();
        System.assert(dispatcher.config != null, 'Unable to initialise config data');
        System.assert(dispatcher.batchSize != null, 'Unable to initialise config batch size');
    }
}