@isTest(isParallel=true) 
private class PersonMergingHelper_Test {
    static Contact masterCon { get; set; }
    static Contact childCon { get; set; }
    static List<DuplicateRecordSet> dupRecordSet { get; set; }
    /**
     * Set up Data
     */
    @testSetup static void setupDataCS() {
        //Set up Custom Setting
        Environment_Settings__c cs = new Environment_Settings__c();
        cs.Contact_Merge_Max_Rerun__c = 1;
        cs.Contact_Merge_Max_Records__c = 200;
        cs.Contact_Merge_Job_Name__c = 'Contact Perfect%';
        cs.SetupOwnerId = UserInfo.getOrganizationId();
        insert cs;
    }
    /**
     * Test for merging contacts with out community users and 2 matching callista record Id
     */
    static testMethod void personIdSameTest() {
        //Given
        setupDataManual();
        //When
        childCon.Person_ID_unique__c = '998876';
        saveConDups();
        Test.startTest();
        retrieveDups();
        PersonMergingHelper helper = new PersonMergingHelper();
        helper.init(dupRecordSet);
        //Then
        Test.stopTest();
        Assert.areEqual(1, [SELECT count() FROM Contact], 'Contact Merge Failed:');
    }
    /**
     * Test for merging contacts with out community users and Master as Callista and Child non Callista
     */
    static testMethod void callistaMasterFoundTest() {
        //Given
        setupDataManual();
        //When
        childCon.Person_ID_unique__c = '';
        saveConDups();
        Test.startTest();
        retrieveDups();
        PersonMergingHelper helper = new PersonMergingHelper();
        helper.init(dupRecordSet);
        //Then
        Test.stopTest();
        Assert.areEqual(1, [SELECT count() FROM Contact], 'Contact Merge Failed:');
    }
    /**
     * Test for merging contacts with MyApp fields override Callista records
     */
    static testMethod void reservationFieldsFromMyAppTest() {
        //Given
        setupDataManual();
        //When
        masterCon.Citizenship__c = '';
        masterCon.Citizenship_Code__c = '';
        masterCon.Residency_Status__c = '';
        childCon.Person_ID_unique__c = '';
        saveConDups();
        Test.startTest();
        retrieveDups();
        PersonMergingHelper helper = new PersonMergingHelper();
        helper.init(dupRecordSet);
        //Then
        Test.stopTest();
        List<Contact> contactTest = [SELECT Id, Citizenship__c, Citizenship_Code__c, Residency_Status__c FROM Contact];
        Assert.areEqual(1, contactTest.size(), 'Contact Merge Failed:');
        //Check if Results from Child are merged to Master on Merge
        Assert.areEqual(childCon.Citizenship__c, contactTest[0].Citizenship__c, 'Citizenship__c Failed:');
        Assert.areEqual(childCon.Citizenship_Code__c, contactTest[0].Citizenship_Code__c, 'Citizenship_Code__c Failed:');
        Assert.areEqual(childCon.Residency_Status__c, contactTest[0].Residency_Status__c, 'Residency_Status__c Failed:');
    }
    /**
     * Test for merging contacts with child community users activated and MAster with no Community user
     */
    static testMethod void childHasCommunityTest() {
        //Given
        setupDataManual();
        //When
        childCon.Person_ID_unique__c = '';
        saveConDups();
        //Set up Community User Access
        setUpCommunity(childCon, 0);
        Test.startTest();
        retrieveDups();
        PersonMergingHelper helper = new PersonMergingHelper();
        helper.init(dupRecordSet);
        Assert.areNotEqual(0, dupRecordSet.size(), 'Duplicate Count ');
        //Then
        Test.stopTest();
    }
    /**
     * Test for merging contacts with child community users activated and MAster with Community user 
     */
    static testMethod void masterandChildHasCommunityTest() {
        //Given
        setupDataManual();
        //When
        childCon.Person_ID_unique__c = '';
        saveConDups();
        //Set up Community User Access
        setUpCommunity(masterCon, 1);
        setUpCommunity(childCon, 2);
        Test.startTest();
        retrieveDups();
        PersonMergingHelper helper = new PersonMergingHelper();
        helper.init(dupRecordSet);
        Assert.areNotEqual(0, dupRecordSet.size(), 'Duplicate Count ');
        //Then
        Test.stopTest();

    }
    /**
     * Set up data manually
     */
    private static void setupDataManual() {

        Contact con = new Contact();
        con.Person_ID_unique__c = '12345';
        con.Birthdate = Date.today().addYears(- 20);
        con.Citizenship__c = 'INTERNATIONAL';
        con.Citizenship_Code__c = '4';
        con.Residency_Status__c = 'Australian Permanent Resident';
        con.Email = 'test@test.com';
        con.Monash_Email_Address__c = 'test@test.com';
        con.FirstName = 'testFirstName';
        con.LastName = 'testLastName';
        con.Gender__c = 'None';
        con.MobilePhone = '0412345678';
        //ASsign master Contact
        masterCon = con;
        //Assign Child contact 
        childCon = con.clone(false, true);
    }
    /**
     * Retrieve DupRecordSet
     */
    private static void retrieveDups() {

        dupRecordSet = [SELECT Id, DuplicateRuleId,
                        ParentId,
                        RecordCount,
                        DuplicateRule.DeveloperName,
                        DuplicateRule.SobjectType,
        (SELECT Id, RecordId, DuplicateRecordSetId FROM DuplicateRecordItems)
                        FROM DuplicateRecordSet
                        WHERE DuplicateRule.SobjectType = 'Contact'
                        AND RecordCount > 1
                        ORDER BY DuplicateRuleId];
        Assert.areNotEqual(null, dupRecordSet, 'No Duplicate Record Set Created');
    }
    /**
     * Save contacts
     */
    private static void saveConDups() {
        List<Contact> contacts = new List<Contact> { masterCon, childCon };
        //
        Database.DMLOptions insertDML = new Database.DMLOptions();
        insertDML.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] srs = Database.insert(contacts, insertDML);
        for (Database.SaveResult sr : srs) {
            Assert.isTrue(sr.isSuccess(), 'Failed saving Contacts');
        }
        DuplicateRule dR = [SELECT Id FROM DuplicateRule WHERE MasterLabel LIKE 'Contact Perfect%' LIMIT 1];
        DuplicateRecordSet dupRS = new DuplicateRecordSet(DuplicateRuleId = dR.Id);
        insert dupRS;
        DuplicateRecordItem[] dupitems = new List<DuplicateRecordItem> {
            new DuplicateRecordItem(DuplicateRecordSetId = dupRS.Id, RecordId = masterCon.Id),
            new DuplicateRecordItem(DuplicateRecordSetId = dupRS.Id, RecordId = childCon.Id)
        };
        insert dupitems;
        Assert.areNotEqual(null, dupRS.Id, 'Failed Creating Duplicate Record Set');

    }
    /**
     * Create Community User
     * @param conRec Contact Record
     */
    private static void setUpCommunity(Contact conRec, Integer iCnt) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :UserServices.CUSTOMER_COMMUNITY_PROFILE_COMMON LIMIT 1];
        
        User adminUser = [SELECT Id, UserRoleId 
                            From User 
                            WHERE Profile.Name='System Administrator'
                            AND UserRoleId != NULL
                            AND isActive = TRUE
                            Limit 1];

        System.runAs(adminUser) {
            User u = new user();
            u.ProfileId = p.Id;
            u.LastName = conRec.LastName;
            u.Email = conRec.Email;
            u.ContactId = conRec.Id;
            u.Alias = 'testAl' + iCnt;
            u.Username = 'testComm@community.com' + iCnt;
            u.CommunityNickname = 'comm1234' + iCnt;
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'America/Los_Angeles';
            u.LanguageLocaleKey = 'en_US';
            u.EmailEncodingKey = 'UTF-8';
            u.IsActive = true;
            insert u;
        }
    }
}