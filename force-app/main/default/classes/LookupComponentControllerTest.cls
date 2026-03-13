/**
* @author Inderpal Dhanoa
* @date 25 03 2021
* @description Test class for LookupComponentController
**/
    @IsTest(isParallel=true)
    public class LookupComponentControllerTest {
     /**
     * @author Inderpal Dhanoa
     * @description retrieves Related Enquiries on an Opportunity
     */
    @IsTest
    public static void getRelatedCasesTest(){
        Account accountRecord = new Account(name ='AccountTest') ;
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Monash Organisation').getRecordTypeId();
        insert accountRecord;

        Account accountRecord2 = new Account(name ='AccountTest2') ;
        accountRecord2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('External Organisation').getRecordTypeId();
        insert accountRecord2;
        
        Test.startTest();
        String searchTerm  = 'AccountTest';
        String objectName = 'Account';
        String filters = 'RecordType.DeveloperName = \'Monash_Organisation\'';
        String fields = 'Name';
        List<sObject> result = LookupComponentController.lookUp(searchTerm, objectName, filters, '', fields);
        system.assertEquals(result.size(), 1);

        result = LookupComponentController.lookUp(searchTerm, objectName, filters, accountRecord.Id, fields);
        system.assertEquals(result.size(), 1);
        Test.stopTest();  
    }   
}