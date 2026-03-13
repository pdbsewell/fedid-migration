@isTest(isParallel=true)
public class EngageDedupeProcessPendingDef_Test {
    @testSetup
    public static void testNewInterimSetup() {
        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Online_Donation_Interface' AND RecordType.NamespacePrefix = 'ucinn_ascendv2'].Id;
        Id nonStudentRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Non_Student' AND RecordType.NamespacePrefix = ''].Id;
        
        ucinn_ascendv2__Org_Wide_Configuration__c owc = new ucinn_ascendv2__Org_Wide_Configuration__c(Name = 'Default Org Wide Config', ucinn_ascendv2__New_Contact_Record_Type_ID__c = nonStudentRecordTypeID);
        
        insert owc;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPending', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'Pending',
                                                                                Birth_Date_Text__c = '12/04/1927',
                                                                                Deceased_Date_Text__c = '20/12/2018');
        
        ucinn_ascendv2__Interim__c testInterim1 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPending1', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim1', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'Pending',
                                                                                Birth_Date_Text__c = '1927',
                                                                                Deceased_Date_Text__c = '2018');
        
        //Should append manual review reason.
        ucinn_ascendv2__Interim__c testInterim2 = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestPending2', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim2', 
                                                                                RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'Pending',
                                                                                Birth_Date_Text__c = '12/04/1927/200',
                                                                                Deceased_Date_Text__c = '12/20/2018/123');
        insert new List<ucinn_ascendv2__Interim__c> {testInterim, testInterim1, testInterim2};
    }
    
    @isTest
    public static void testNewInterimBatch() {
        Test.startTest();
        
        EngageDedupeProcessPendingDef reBatch = new EngageDedupeProcessPendingDef();
        reBatch.additionalVariables.put('recordTypeName', 'Online Donation Interface');
        reBatch.batchConstructor( 'Online Donation Interface');
        reBatch.batchStart(null);
        reBatch.BatchExecute(null, Database.query((String) reBatch.additionalVariables.get('query')));
        
        Test.stopTest();
        
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending'][0];
        ucinn_ascendv2__Interim__c testInterim1 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending1'][0];
        ucinn_ascendv2__Interim__c testInterim2 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending2'][0];

        System.assert(testInterim.ucinn_ascendv2__Contact__c != null, 'This interim should have a contact created.');
        System.assert(testInterim.ucinn_ascendv2__Manual_Review_Reason__c == null, 'This interim should have no manual review reason.');
       
    }
    
    @isTest
    public static void testNewInterimNoInProgressClass() {
        /* This test is no longer relevant.
        Test.startTest();
        ucinn_ascendv2.ascend_DEDUPE_GlobalWrapper.startProcessInterims(new Map<String, Object>{'recordTypeDeveloperName' => 'Workday_Interface',
                                                                                                'interimNewBatchSize' => 5,
                                                                                                'interimPendingBatchSize' => 5,
                                                                                                'interimInProgressBatchSize' => 5});
        Test.stopTest();
        
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending'][0];
        ucinn_ascendv2__Interim__c testInterim1 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending1'][0];
        ucinn_ascendv2__Interim__c testInterim2 = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__First_Name__c =: 'TestPending2'][0];

        System.assert(testInterim.ucinn_ascendv2__Contact__c == null, 'This interim should not have a contact created.');
        System.assert(testInterim.ucinn_ascendv2__Manual_Review_Reason__c == null, 'This interim should have no manual review reason.');
        System.assert(testInterim.ucinn_ascendv2__Status__c == 'Pending', 'This interim should have a status of Pending.');
        */
    }
}