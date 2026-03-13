/**
 * @author David Browaeys
 * @description Test class for BulkGenerateOfferBatch
 * @group Bulk Data Processing
 */
@isTest(isParallel=true)
public inherited sharing class BulkGenerateOfferBatch_Test {
    @isTest static void testStart(){
        Test.startTest();
        Database.executeBatch( new BulkGenerateOfferBatch(), 1);
        Test.stopTest();
    }
    @isTest static void testBatchExecuteError(){
        //Account Createion
        TriggerCommon.disableTrigger('Account');
        Account acc = (Account)TestDataFactory.createSObject(new Account(Callista_Org_Unit_Code__c = 'DIRECT'), true);
        //Contact Creation
        TriggerCommon.disableTrigger('Contact');
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(Lastname='Con1',AccountId = acc.Id, Person_ID_unique__c='123456'), true);
        
        TriggerCommon.disableTrigger('Calendar__c');
        Calendar__c calendar = (Calendar__c)TestDataFactory.createSObject(new Calendar__c(), true);
        
        TriggerCommon.disableTrigger('Bulk_Data_Processing__c');
        Bulk_Data_Processing__c bdp = (Bulk_Data_Processing__c)TestDataFactory.createSObject(new Bulk_Data_Processing__c(Transfer_Calendar__c = '2021/1', Person_ID__c = '123456', Transfer_Course_Campus__c = 'CLAYTON', Calendar__c = calendar.Id), 'TestDataFactorySettings.BulkDataProcessingDefaults', true);
        
        Test.startTest();
        BulkGenerateOfferBatch batch = new BulkGenerateOfferBatch();
        batch.bdpOfferGenService = (BulkGenerateOfferService) Test.createStub(BulkGenerateOfferService.class, new BulkGenerateOfferServiceMock());
        batch.execute(null, new Bulk_Data_Processing__c[]{bdp});
		bdp = [SELECT id, Status__c FROM Bulk_Data_Processing__c WHERE Id =: bdp.Id];
        Test.stopTest();
        System.assert(bdp.Status__c == 'Offer Error');
    }
    
    private class BulkGenerateOfferServiceMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
			if (stubbedMethodName != null){
                throw new IllegalArgumentException('Mock exception');
			}
            return null;
        }
    }
}