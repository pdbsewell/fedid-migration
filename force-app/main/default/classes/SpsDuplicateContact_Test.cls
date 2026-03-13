/**
 * @author Nick Guia
 * @date 30-09-2020
 * @group Lead Management
 * @description test class for SpsDuplicateContact 
 **/
@isTest(isParallel=true)
private class SpsDuplicateContact_Test {

    @TestSetup
    static void makeData(){
        Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
		insert envSettings;

		List<Contact> duplicateContacts = new List<Contact>();

		for(Contact con : TestHelper.createProspectiveStudentContact(1)) {
			con.FirstName = 'SpsDuplicateContact_Test';
			con.LastName = 'SpsDuplicateContact_Test';
			con.Email = 'Test@test.org';
			duplicateContacts.add(con);
		}
		insert duplicateContacts;
    }

    /**
     * @description test merging multiple SPS records within the class instance
     */
    @isTest
    static void shouldMergeSpsRecords() {
        //given
        SpsDuplicateContact dupCon;
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(2);
        Staged_Prospective_Student__c mergedSps;

        Test.startTest();
        
        //when
        dupCon = new SpsDuplicateContact(spsList);
        mergedSps = dupCon.getMergedSps();

        Test.stopTest();

        //then
        System.assert(mergedSps != null, 'Unable to merge SPS records!');
    }

    /**
     * @description test Assigning Contact IDs to all SPS records within the class instance
     */
    @isTest
    static void shouldAssignContactIdsToSps() {
        //given
        SpsDuplicateContact dupCon;
        List<Staged_Prospective_Student__c> spsList = TestHelper.createSPS(2);
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        
        //when
        dupCon = new SpsDuplicateContact(spsList);
        dupCon.con = con;
        dupCon.propagateContactIds();

        Test.stopTest();

        //then
        System.assert(dupCon.spsList != null, 'Unexpected NULL value for SPS List');
        System.assert(!dupCon.spsList.isEmpty(), 'Unexpected empty value for SPS List');
        for(Staged_Prospective_Student__c iSps : dupCon.spsList) {
            System.assertEquals(con.Id, iSps.Exploded_Target__c, 'Unable to propagate Contact ID to SPS records');
        }   
    }

    /**
     * @description test update SPS record to Fatal Error if no Contact was linked
     */
    @isTest
    static void shouldUpdateSpsStatusToFatalError() {
        //given
        SpsDuplicateContact dupCon;
        Staged_Prospective_Student__c spsRec = TestHelper.createSPS(1)[0];

        Test.startTest();
        
        //when
        dupCon = new SpsDuplicateContact(spsRec);
        dupCon.propagateContactIds();

        Test.stopTest();

        //then
        System.assert(dupCon.spsList != null, 'Unexpected NULL value for SPS List');
        System.assert(!dupCon.spsList.isEmpty(), 'Unexpected empty value for SPS List');
        for(Staged_Prospective_Student__c iSps : dupCon.spsList) {
            System.assertEquals(null, iSps.Exploded_Target__c, 'Unexpected Contact ID found in SPS');
            System.assertEquals(Label.SPS_Status_Fatal_Error, iSps.Status__c, 'Unable to update SPS status to Fatal Error');
        }
    }
}