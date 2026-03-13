/**
 * @author          Mark Johnson
 * @description    	Test class for EngageDedupeUtils
 * @revision        10/09/2019 - Mark Johnson - Initial version
 *                  18/02/2025 - Vinothraja - EPCP-4367 Fixed the failures, and increased Code Coverage
 */
@isTest(isParallel=true)
public class EngageDedupeUtils_Test {
    /* data setup */
    @testSetup
    public static void testDataSetup() {        
        //Create contact that should be found as duplicate in the system.
        Contact testContact = new Contact(LastName = 'Test',
                                          FirstName = 'Contact',
                                          Original_ID__c = '99999999999',
                                          Person_ID_Unique__c = '11111111111');
        
        insert new List<Contact>{testContact};
            
        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;
        Id nonStudentRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Non_Student' AND RecordType.NamespacePrefix = ''].Id;
        
        ucinn_ascendv2__Org_Wide_Configuration__c owc = new ucinn_ascendv2__Org_Wide_Configuration__c(Name = 'Default Org Wide Config', ucinn_ascendv2__New_Contact_Record_Type_ID__c = nonStudentRecordTypeID);
        
        insert owc;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'TestUtil', 
                                                                                ucinn_ascendv2__Last_Name__c = 'Interim', 
                                                                                RecordTypeId = reRecordTypeID, 
                                                                                ucinn_ascendv2__Status__c = 'Pending',
                                                                                RE_Id__c = '99999999999',
                                                                                ucinn_ascendv2__Phone_1__c = '1231234',
                                                                                Person_ID_Unique__c = '11111111111',
                                                                                Phone_1_Date_Last_Changed__c = Date.today().addDays(-1)
                                                                               );
        insert testInterim;
    }

    @isTest
	public static void testInterimUtils() {
		
        Test.startTest();
        ucinn_ascendv2.ascend_DEDUPE_GlobalWrapper.startProcessInterims(new Map<String, Object>{'recordTypeDeveloperName' => 'Raisers_Edge_Interface',
                                                                                                'interimNewBatchSize' => 5,
                                                                                                'interimPendingBatchSize' => 5,
                                                                                                'interimInProgressBatchSize' => 5});
        Test.stopTest();
        
        ucinn_ascendv2__Interim__c testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c 
                                                    FROM ucinn_ascendv2__Interim__c 
                                                    WHERE ucinn_ascendv2__First_Name__c =: 'TestUtil'][0];
        
        System.assert(testInterim.ucinn_ascendv2__Contact__c != null, 'This interim should have been assigned a contact.');
    }

    @isTest
    public static void testFixCreationDate() {
        //GIVEN
        // A Valid Record 
        Contact testContact = new Contact(LastName = 'Test',
        FirstName = 'Contact',
        Original_ID__c = '99999999999',
        Person_ID_Unique__c = '11111122222');
        insert testContact;
        
        // WHEN
        // The record's Created Date > Last Modified Date and the Date is fixed
        Test.setCreatedDate(testContact.Id, Date.today().addDays(2));
        Test.startTest();
            // testContact = [SELECT id, CreatedDate, LastModifiedDate FROM Contact WHERE Id = :testContact.Id];
            EngageDedupeUtils.fixCreationDate(testContact);
        Test.stopTest();
        
        // THEN
        // The created date needs to be fixed
        Assert.areEqual(testContact.CreatedDate, testContact.LastModifiedDate, 'The Created Date-Last Modified Date fix is not done properly');
    }

    @isTest
    public static void testEngageInterimFields() {
        // GIVEN 
        // Valid Interim record exists - covered in test data setup
        
        // WHEN
        // The EngageInterimFields class is instantiated
        ucinn_ascendv2__Interim__c currentInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c, 
                                                        ucinn_ascendv2__Email_1__c, ucinn_ascendv2__Email_2__c, Email_3__c,
                                                        ucinn_ascendv2__Email_1_Type__c, ucinn_ascendv2__Email_2_Type__c, Email_3_Type__c,
                                                        Email_1_Date_Last_Changed__c, Email_2_Date_Last_Changed__c, Email_3_Date_Last_Changed__c,
                                                        Email_1_Import_ID__c, Email_2_Import_ID__c, Email_3_Import_ID__c,
                                                        ucinn_ascendv2__Phone_1__c, ucinn_ascendv2__Phone_2__c, ucinn_ascendv2__Phone_3__c, ucinn_ascendv2__Phone_4__c, ucinn_ascendv2__Phone_5__c,
                                                        ucinn_ascendv2__Phone_1_Type__c, ucinn_ascendv2__Phone_2_Type__c, ucinn_ascendv2__Phone_3_Type__c, ucinn_ascendv2__Phone_4_Type__c, ucinn_ascendv2__Phone_5_Type__c,
                                                        Phone_1_Date_Last_Changed__c, Phone_2_Date_Last_Changed__c, Phone_3_Date_Last_Changed__c, Phone_4_Date_Last_Changed__c, Phone_5_Date_Last_Changed__c, 
                                                        Phone_1_Import_ID__c, Phone_2_Import_ID__c, Phone_3_Import_ID__c, Phone_4_Import_ID__c, Phone_5_Import_ID__c
                                                        FROM ucinn_ascendv2__Interim__c 
                                                        WHERE ucinn_ascendv2__First_Name__c =: 'TestUtil'][0];
        EngageDedupeUtils.EngageInterimFields fields = new EngageDedupeUtils.EngageInterimFields(currentInterim);

        // THEN
        // All the field inside EngageInterimFields should be set
        Assert.isTrue(fields.emailList.contains(currentInterim.ucinn_ascendv2__Email_1__c), 'Email 1 is not set properly');
    }

    @isTest
    public static void testGetPicklistValues() {
        // GIVEN
        // A valid picklist        
        List<Schema.PicklistEntry> picklistEntries = Address__c.Type__c.getDescribe().getPicklistValues();
        
        // WHEN
        // getPicklistValues is invoked on the picklist's entries
        Set<String> supportedAddressType = EngageDedupeUtils.getPicklistValues(picklistEntries);

        // THEN
        // The picklist values should be returned
        Assert.isTrue(supportedAddressType.contains('Mailing'), 'Picklist Entry\'s label is not fetched');
    }
    
    @isTest
    public static void testPopulateContactLookupForInterimsByRecordTypeAndSystemIds() {
        // GIVEN
        // A Valid contact
        Contact con = [ SELECT id FROM Contact WHERE Person_ID_Unique__c = '11111111111'];
        List<ucinn_ascendv2__Interim__c> testInterims = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c, RE_Id__c, Person_ID_Unique__c
                                                    FROM ucinn_ascendv2__Interim__c 
                                                    WHERE ucinn_ascendv2__First_Name__c =: 'TestUtil'];
        // WHEN
        // The utility method is invoked
        Test.startTest();
            EngageDedupeUtils.populateContactLookupForInterimsByRecordTypeAndSystemIds(testInterims);
        Test.stopTest();

        // THEN
        // The related contact is associated
        Assert.areEqual(con.Id, testInterims[0].ucinn_ascendv2__Contact__c, 'The contact is not associated properly');
    }
}