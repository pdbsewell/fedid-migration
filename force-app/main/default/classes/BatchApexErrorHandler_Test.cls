/**
 * @author P.Victoriano
 * @date 02/11/2021
 * @description Test class for BatchApexErrorHandler
 **/
@isTest(isParallel = true)
private class BatchApexErrorHandler_Test {
    @isTest
    static void processTests() {
        BatchApexErrorHandler handler;
        //Given - A fake failed batch job 
        String id1 = fflib_IDGenerator.generate(AsyncApexJob.SObjectType);
        BatchApexErrorEvent err = new BatchApexErrorEvent();
        err.AsyncApexJobId = id1;
        err.Message = 'Failed';
        err.JobScope = fflib_IDGenerator.generate(Account.SObjectType);
        String id2 = fflib_IDGenerator.generate(ApexClass.SObjectType);
        ApexClass classA = new ApexClass();
        classA.Id = id2;
        classA.Name = 'TestBatch';
        AsyncApexJob ajob = new AsyncApexJob();
        //Set Read Only Fields for Mocking
        ajob = (AsyncApexJob)fflib_ApexMocksUtils.setReadOnlyFields(
            ajob,
            AsyncApexJob.class,
            new Map<SObjectField, Object> {
            AsyncApexJob.ApexClassId => classA.Id
        });
        ajob.Id = id1;
        Set<Id> asyncApexJobIds = new Set<Id> {
            id1
        };
        //Init Mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        DBManager mockDBManager = (DBManager)mocks.mock(DBManager.class);
        //Set Mocks
        mocks.startStubbing();
        //Expecting query on AsyncApexJob once
        mocks.when(
            mockDBManager.soqlQuery([SELECT Id, ApexClass.Name FROM AsyncApexJob WHERE Id IN: asyncApexJobIds])
            ).thenReturn(new List<AsyncApexJob> {ajob});
        mocks.stopStubbing();
        //When
        Test.startTest();
        {
            handler = new BatchApexErrorHandler();
            //Set Instance Mocks
            DBManager.setInstance(mockDBManager);
            //Perform process
            handler.process(err);
            handler.execute();
        }
        Test.stopTest();
        //Then - Checks for capured errors
        System.assertEquals(1, handler.asyncApexJobIds.size(), 'No Failed events captured');
        //Check Mock was called once
        ((DBManager) mocks.verify(mockDBManager, 1))
        .soqlQuery([SELECT Id, ApexClass.Name FROM AsyncApexJob WHERE Id IN: asyncApexJobIds]);
    }
}