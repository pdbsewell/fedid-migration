/**
 * @File Name          : MutexLock_Test.cls
 * @Description        : Test class for MutexLock
**/
@isTest(isParallel=true)
private class MutexLock_Test {

    @TestSetup
    static void makeData(){
        AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
        String appName = AsyncExplodingLeadsDispatcher.CONFIG_NAME;

        //insert mutex record
        Mutex__c mutexRec = new Mutex__c();
        mutexRec.Name = appName;
        mutexRec.is_Locked__c = false;
        insert mutexRec;
    }

    /**
     * @description test the execution of any class that implements IMutexLockable
     *  this test verifies that the config data of the dispatcher was instantiated correctly
     */
    @isTest 
    static void testExecute() {
        Test.startTest();
            AsyncExplodingLeadsDispatcher dispatcher = (AsyncExplodingLeadsDispatcher) AsyncExplodingLeadsDispatcher.getInstance();
            MutexLock.execute(dispatcher);
        Test.stopTest();
        //verify that config data was instantiated
        System.assert(dispatcher.config != null, 'Config data was not loaded!');
    }
}