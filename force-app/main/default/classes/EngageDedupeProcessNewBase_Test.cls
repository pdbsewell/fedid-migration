@isTest(isParallel=true)
public class EngageDedupeProcessNewBase_Test {
    
    @isTest
    //For testing Interim new batch. Interim new batch takes external data from a contact and attempts to match with a contact already in the system.
	public static void testNewInterimBatch() {
        // GIVEN
        //Create contact that should be found as duplicate in the system.
        Contact testContact = new Contact(LastName = 'Test',
                                          FirstName = 'Contact',
                                          Original_ID__c = '99999999999',
                                          Person_ID_Unique__c = '11111111111');
        
        insert new List<Contact>{testContact};
            
        
        //Test with RE Record type.
        RecordType reRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''];
        Id nonStudentRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Non_Student' AND RecordType.NamespacePrefix = ''].Id;
        
        ucinn_ascendv2__Org_Wide_Configuration__c owc = new ucinn_ascendv2__Org_Wide_Configuration__c(Name = 'Default Org Wide Config', ucinn_ascendv2__New_Contact_Record_Type_ID__c = nonStudentRecordTypeID);
        
        insert owc;
        // Interim record
        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'Test', 
                                                                                    ucinn_ascendv2__Last_Name__c = 'Contact', 
                                                                                    RecordTypeId = reRecordType.ID, 
                                                                                    Person_ID_Unique__c = '11111111111',
                                                                                    ucinn_ascendv2__Status__c = 'New');
        insert testInterim;

        EngageDedupeProcessNewBase base = new EngageDedupeProcessNewBase();
        base.batchConstructor(reRecordType.DeveloperName);
        base.batchStart(null);
        base.batchExecute(null, new List<ucinn_ascendv2__Interim__c> {testInterim});

        // WHEN
        // The batch is run
        Test.startTest();

        ucinn_ascendv2.ascend_DEDUPE_GlobalWrapper.startProcessInterims(new Map<String, Object>{'recordTypeDeveloperName' => 'Raisers_Edge_Interface',
            																					'interimNewBatchSize' => 5,
            																					'interimPendingBatchSize' => 5,
            																					'interimInProgressBatchSize' => 5});
        
            

        Test.stopTest();
        
        testInterim = [SELECT ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Interim__c WHERE Id =: testInterim.Id][0];

        // THEN
        // Contact should be linked to the interim
        Assert.areEqual(testContact.Id, testInterim.ucinn_ascendv2__Contact__c, 'Contact should be linked to the interim');
    }
}