@isTest(isParallel=true)
public class EngageDedupeInterimCleanUpExtension_Test {
    @testSetup
    static void setupData(){
        ucinn_ascendv2__Interim_Record_Types__c recordType = new ucinn_ascendv2__Interim_Record_Types__c( Name = 'Raisers Edge Interface', ucinn_ascendv2__Record_Type_Name__c = 'Raisers Edge Interface');
        insert recordType;

        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'Test', ucinn_ascendv2__Last_Name__c = 'Interim', RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'New');
        insert testInterim;
    }

    @isTest
    static void testPopulateRecordTypeMapping(){
        EngageDedupeInterimCleanUpExtension edice = new EngageDedupeInterimCleanUpExtension();
    }
    
    @isTest
    static void testCleanListOfInterims(){
        List<ucinn_ascendv2__Interim__c> interimList = [SELECT Id, RecordTypeId FROM ucinn_ascendv2__Interim__c];
        Map<String,Object> addParams = new Map<String,Object>();
        EngageDedupeInterimCleanUpExtension edice = new EngageDedupeInterimCleanUpExtension();
        List<ucinn_ascendv2__Interim__c> resultList = edice.cleanListOfInterims(interimList, addParams);
        
        System.assertEquals(interimList[0].RecordTypeId, resultList[0].RecordTypeId);
    }
}