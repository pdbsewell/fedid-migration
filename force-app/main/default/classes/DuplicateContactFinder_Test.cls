/**
 * @description       : Test class for DuplicateContactFinder. For these tests, we are just mocking the duplicate match 
 *                      result since DataCloud.FindDuplicates couldn't find duplicates that aren't actually inserted to the database.
 * @author            : Nick Guia
 * @date              : JUL.09.2019
 * @group             : Commons
 * @last modified on  : 04-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *  03-07-2023    Nick Guia   - added Account_Record_Type_Name__c = 'Household_Account' on contact match
**/
@isTest(isParallel=true)
private class DuplicateContactFinder_Test {

	private static final Integer SETUP_RECORD_COUNT = 1;

    /**
	 * @description reusable method for creating a test contact
	 *  that matches the first name, last name, and email with the
	 *  setup contact
	 */
	private static Contact createNewTestContact() {
		return new Contact(
			FirstName = 'DuplicateContactFinder_test_duplicate',
			LastName = 'DuplicateContactFinder_test_duplicate',
			Email = 'Test@test.org',
            Account_Record_Type_Name__c = 'Household_Account'
		);
	}

	@TestSetup 
    static void init() {

		Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
		insert envSettings;

		List<Contact> duplicateContacts = new List<Contact>();

		for(Contact con : TestHelper.createProspectiveStudentContact(SETUP_RECORD_COUNT)) {
			con.FirstName = 'DuplicateContactFinder_test_duplicate';
			con.LastName = 'DuplicateContactFinder_test_duplicate';
			con.Email = 'Test@test.org';
			duplicateContacts.add(con);
		}

        TriggerCommon.disableTrigger('Contact');
		insert duplicateContacts;
        TriggerCommon.enableTrigger('Contact');

	}

	/**
	 * Test scenario:
	 *  - initialise DuplicateContactFinder with only Contact as parameter. This will default on using the
	 *  duplicate rule defined in Environment_Settings__c.Contact_Loose_Match_Duplicate_Rule_Name__c
	 *  - initialise DuplicateContactFinder and provide a specific duplicate rule name
	 */
    @isTest
	static void initTest() {

		Contact con = createNewTestContact();
		String duplicateRuleName = Environment_Settings__c.getInstance().Contact_Loose_Match_Duplicate_Rule_Name__c;

		Test.startTest();

		DuplicateContactFinder finder1 = new DuplicateContactFinder(con);
		DuplicateContactFinder finder2 = new DuplicateContactFinder(con, duplicateRuleName);

		Test.stopTest();

		Assert.areEqual(duplicateRuleName, finder1.duplicateRuleName, 'Unexpected Duplicate Rule name value');
		Assert.areEqual(duplicateRuleName, finder2.duplicateRuleName, 'Unexpected Duplicate Rule name value');
	}

	/**
	 * Test scenario:
	 *  - Test mock the custom email fields in contact in order to run
	 *      the duplicate checking rules properly.
	 *  - expected outcome is that the custom email fields should have the same
	 *      value as the standard Email fields.
	 */
    @isTest
	static void mockEmailFieldsTest() {

		Contact con = createNewTestContact();
		List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];

		DuplicateContactFinder finder = new DuplicateContactFinder(con);
		Contact testcon;

		Test.startTest();

		//enable exploding Leads to include custom email fields in query
		finder.enableExplodingLeads();
		finder.mockEmailFields();
		testcon = finder.conRecord;

        Test.stopTest();

        Assert.areEqual(con.Email, testcon.Monash_Email_Address__c, 'Unexpected value for Monash_Email_Address__c');
        Assert.areEqual(con.Email, testcon.Personal_Email__c, 'Unexpected value for Personal_Email__c');
    }

    /**
     * Test scenario:
     *  - Test mock the custom email fields in contact in order to run
     *      the duplicate checking rules properly.
     *  - Clear the mocked email fields
     */
    @isTest
    static void clearEmailFieldsTest() {

        Contact con = createNewTestContact();

        Test.startTest();

            DuplicateContactFinder finder = new DuplicateContactFinder(con);
            finder.mockEmailFields();
            finder.clearEmailFields();
            Contact testcon = finder.getLatestContact();

        Test.stopTest();

        Assert.isNull(testcon.Monash_Email_Address__c, 'Unexpected value for Monash_Email_Address__c');
        Assert.isNull(testcon.Personal_Email__c, 'Unexpected value for Personal_Email__c');
    }

    /**
     * Test scenario:
     *  - Try to find the duplicates provided the duplicate matching rule that we want to use.
     */
    @isTest
    static void findDuplicatesTest() {

        Contact con = createNewTestContact();
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);

            finder.retrieveContactFields();

        Test.stopTest();

        Assert.areEqual(SETUP_RECORD_COUNT, finder.getDuplicatesCount(), 'Unexpected number of duplicate count');
        Assert.areEqual(SETUP_RECORD_COUNT, finder.matchedContacts.size(), 'Unexpected number of matched contact count');
    }

    /**
     * Test scenario:
     *  - Test get the count of duplicates found
     */
    @isTest
    static void getDuplicatesCountTest() {

        Contact con = createNewTestContact();
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        Integer duplicateCount;
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);
            finder.retrieveContactFields();
            duplicateCount = finder.getDuplicatesCount();

        Test.stopTest();

        Assert.areEqual(SETUP_RECORD_COUNT, duplicateCount, 'Unexpected number of duplicate count');
    }

    /**
     * Test scenario:
     *  - Test if getting the List of matched records returns the expected result
     */
    @isTest
    static void getMatchedRecordListTest() {

        Contact con = createNewTestContact();

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];
        List<Contact> matchedRecordList;
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);
            finder.retrieveContactFields();
            matchedRecordList = finder.getMatchedRecordList();

        Test.stopTest();
        Assert.isNotNull(matchedRecordList, 'Matched records map was not initialised');
    }

    /**
     * Test scenario:
     *  - Test if getting the Map of matched records returns the expected result
     */
    @isTest
    static void getMatchedRecordMapTest() {

        Contact con = createNewTestContact();

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];
        Map<Id, Contact> matchedRecordMap;
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);
            finder.retrieveContactFields();
            matchedRecordMap = finder.getMatchedRecordMap();

        Test.stopTest();

        Assert.isNotNull(matchedRecordMap, 'Matched records map was not initialised');
    }

    /**
     * Test scenario:
     *  - Test get the Contact record with latest LastModified date
     */
    @isTest
    static void getLatestLastModifiedTest() {
        
        Contact con = createNewTestContact();
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        List<Contact> conList;
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);
            finder.retrieveContactFields();
            conList = finder.getLatestLastModified(finder.matchedContacts);

        Test.stopTest();

        Assert.isFalse(conList.isEmpty(), 'Unexpected result when getting the latest LastModified contact');
    }

    /**
     * Test scenario:
     *  - Test get the Contact record with latest CreatedDate date
     */
    @isTest
    static void getLatestCreatedDateTest() {
        
        Contact con = createNewTestContact();
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);
            finder.retrieveContactFields();
            List<Contact> conList = finder.getLatestCreatedDate(finder.matchedContacts);

        Test.stopTest();

        Assert.isFalse(conList.isEmpty(), 'Unexpected result when getting the latest CreatedDate contact');
    }

    /**
     * Test scenario:
     *  - Test the generic method of getting the max date - dynamically based on provided field API.
     */
    @isTest
    static void getMaxByDateTest() {
        Contact con = createNewTestContact();
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);
            finder.retrieveContactFields();
            List<Contact> conList = finder.getMaxByDate(finder.matchedContacts, 'LastModifiedDate');

        Test.stopTest();

        Assert.isFalse(conList.isEmpty(), 'Unexpected result when getting the latest LastModifiedDate contact');
    }

    /**
     * Test scenario:
     *  - get the bare minimum fields required to check for matching contact:
     *  LastModifiedDate, and CreatedDate
     */
    @isTest
    static void retrieveContactFieldsTest() {
        Contact con = createNewTestContact();
        List<Contact> duplicateContacts = [SELECT Id FROM Contact LIMIT 10000];

        DuplicateContactFinder finder = new DuplicateContactFinder(con);
        
        Test.startTest();

            finder.mockEmailFields();
            finder.findDuplicates();

            //mock the match results
            finder.matchedContacts = duplicateContacts;
            finder.matchedContactsById = new Map<Id, Contact>(duplicateContacts);
            finder.retrieveContactFields();

        Test.stopTest();

        Contact matchedCon = finder.matchedContacts[0];
        Assert.isNotNull(matchedCon.LastModifiedDate, 'LastModifiedDate field not found in this context');
        Assert.isNotNull(matchedCon.CreatedDate, 'CreatedDate field not found in this context');
    }
}