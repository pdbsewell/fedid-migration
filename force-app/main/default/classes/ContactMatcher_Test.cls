/**
 * @author Nick Guia
 * @date 30-09-2020
 * @group Commons
 * @description test class for ContactMatcher
 **/
@isTest(isParallel=true)
private class ContactMatcher_Test {

    private static final Integer SETUP_RECORD_COUNT = 2;

    @TestSetup
    static void makeData(){
        Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
		insert envSettings;

		List<Contact> duplicateContacts = new List<Contact>();

		for(Contact con : TestHelper.createProspectiveStudentContact(SETUP_RECORD_COUNT)) {
			con.FirstName = 'ContactMatcher_Test_duplicate';
			con.LastName = 'ContactMatcher_Test_duplicate';
			con.Email = 'Test@test.org';
			duplicateContacts.add(con);
		}
		insert duplicateContacts;
    }

    /**
	 * @description reusable method for creating a test contact
	 *  that matches the first name, last name, and email with the
	 *  setup contact
	 */
	private static Contact createNewTestContact() {
		return new Contact(
			FirstName = 'ContactMatcher_Test_duplicate',
			LastName = 'ContactMatcher_Test_duplicate',
			Email = 'Test@test.org',
            Account_Record_Type_Name__c = 'Household_Account' //ADDED Account_Record_Type_Name__c FOR EPCP-2795
		);
    }
    
    /**
     * @description test match setup (duplicate) Contact records.
     * The number of matched contact records should match SETUP_RECORD_COUNT
     */
    @isTest
    static void shouldMatchExistingDuplicates() {
        //given
        Contact newCon = createNewTestContact();
        Map<String, DuplicateContact> duplicateResultMap;
        List<DuplicateContact> duplicateResultList;

        Test.startTest();

        //when
        ContactMatcher matcher = new ContactMatcher(newCon);
        matcher.run();
        duplicateResultMap = matcher.getDuplicateResultMap();
        duplicateResultList = matcher.getDuplicateResult();

        Test.stopTest();

        //then
        System.assert(duplicateResultMap != null, 'Unable to detect duplicate Contacts');
        for(DuplicateContact iDup : duplicateResultMap.values()) {
            //should find duplicates
            System.assert(iDup.hasDuplicates());
            //should find all duplicates in the setup
            System.assert(iDup.matchedContactRecords.size() == SETUP_RECORD_COUNT);
        }

        System.assert(duplicateResultList != null, 'Unable to detect duplicate Contacts');
        for(DuplicateContact iDup : duplicateResultList) {
            //should find duplicates
            System.assert(iDup.hasDuplicates());
            //should find all duplicates in the setup
            System.assert(iDup.matchedContactRecords.size() == SETUP_RECORD_COUNT);
        }
    }

    /**
     * @description test override the duplicate rule name used for
     * running the Contact matching.
     */
    @isTest
    static void shouldSetDuplicateRuleName() {
        //given
        Contact newCon = createNewTestContact();
        String ruleName = 'dummy_dupe_rule';

        Test.startTest();

        //when
        ContactMatcher matcher = new ContactMatcher(newCon);
        matcher.setDuplicateRuleName(ruleName);

        Test.stopTest();

        //then
        System.assertEquals(ruleName, matcher.duplicateRuleName, 'Unable to set duplicate rule name');
    }

    /**
     * @description get Contact with the latest Last Modified Date
     */
    @isTest
    static void shouldReturnLatestLastModifiedDate() {
        //given
        Contact newCon = createNewTestContact();
        List<Contact> conList = [SELECT Id, LastModifiedDate, CreatedDate 
                                FROM Contact 
                                LIMIT 10];
        List<Contact> latest;

        Test.startTest();

        //when
        ContactMatcher matcher = new ContactMatcher(newCon);
        latest = matcher.getLatestLastModified(conList);

        Test.stopTest();

        //then
        System.assert(latest != null, 'Unable to get latest modified Contact');
        System.assert(!latest.isEmpty(), 'Unable to get latest modified Contact');
    }

    /**
     * @description get Contact with the latest CreatedDate
     */
    @isTest
    static void shouldReturnLatestCreatedDate() {
        //given
        Contact newCon = createNewTestContact();
        List<Contact> conList = [SELECT Id, LastModifiedDate, CreatedDate 
                                FROM Contact 
                                LIMIT 10];
        List<Contact> latest;

        Test.startTest();

        //when
        ContactMatcher matcher = new ContactMatcher(newCon);
        latest = matcher.getLatestCreatedDate(conList);

        Test.stopTest();

        //then
        System.assert(latest != null, 'Unable to get latest created Contact');
        System.assert(!latest.isEmpty(), 'Unable to get latest created Contact');
    }

    /**
     * @description get latest Contact based on date field (API name) provided
     */
    @isTest
    static void shouldReturnLatestByDate() {
        //given
        Contact newCon = createNewTestContact();
        List<Contact> conList = [SELECT Id, LastModifiedDate, CreatedDate 
                                FROM Contact 
                                LIMIT 10];
        List<Contact> latest;

        Test.startTest();

        //when
        ContactMatcher matcher = new ContactMatcher(newCon);
        latest = matcher.getMaxByDate(conList, 'LastModifiedDate');

        Test.stopTest();

        //then
        System.assert(latest != null, 'Unable to get latest Contact');
        System.assert(!latest.isEmpty(), 'Unable to get latest Contact');
    }
}