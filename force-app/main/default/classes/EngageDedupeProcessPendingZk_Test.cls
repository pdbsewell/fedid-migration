@isTest(isParallel=true)
public class EngageDedupeProcessPendingZk_Test {
    @testSetup
    public static void testNewInterimSetup() {
        
        //Test with Zkipster Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Zkipster_Interface' AND RecordType.NamespacePrefix = ''].Id;
        Id nonStudentRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Non_Student' AND RecordType.NamespacePrefix = ''].Id;
        
        ucinn_ascendv2__Org_Wide_Configuration__c owc = new ucinn_ascendv2__Org_Wide_Configuration__c(Name = 'Default Org Wide Config', ucinn_ascendv2__New_Contact_Record_Type_ID__c = nonStudentRecordTypeID);
        
        insert owc;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPending3', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'Pending',
                                                                                Birth_Date_Text__c = '12/04/1927',
                                                                                Deceased_Date_Text__c = '20/12/2018');
        
        ucinn_ascendv2__Interim__c testInterim1 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPending4', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim1', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'Pending',
                                                                                Birth_Date_Text__c = '1927',
                                                                                Deceased_Date_Text__c = '2018');
        
        //Should append manual review reason.
        ucinn_ascendv2__Interim__c testInterim2 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPending5', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim2', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'Pending',
                                                                                Birth_Date_Text__c = '12/04/1927/200',
                                                                                Deceased_Date_Text__c = '12/20/2018/123');
        insert new List<ucinn_ascendv2__Interim__c> {testInterim, testInterim1, testInterim2};
    }
    
    @isTest
    public static void testNewInterimBatch() {
        Test.startTest();
        
        EngageDedupeProcessPendingZk reBatch = new EngageDedupeProcessPendingZk();
        reBatch.additionalVariables.put('recordTypeName', 'Zkipster Interface');
        reBatch.batchConstructor('Zkipster Interface');
        reBatch.batchStart(null);
        reBatch.BatchExecute(null, Database.query((String) reBatch.additionalVariables.get('query')));
        
        Test.stopTest();
        
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending3'][0];
        ucinn_ascendv2__Interim__c testInterim1 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending4'][0];
        ucinn_ascendv2__Interim__c testInterim2 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending5'][0];
        
        System.assert(testInterim.ucinn_ascendv2__Contact__c != null, 'This interim should have a contact created.');
        System.assert(testInterim.ucinn_ascendv2__Manual_Review_Reason__c == null, 'This interim should have no manual review reason.');
    }
}