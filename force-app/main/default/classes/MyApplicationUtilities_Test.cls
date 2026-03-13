/**
 * @author Trent De Laney
 * @date 27 Nov 2019 at 3:30:55 pm
 * @group Test Class
 * @description Defines the tests for MyApplicationUtilities
 */
@IsTest
public without sharing class MyApplicationUtilities_Test {

    private final static String TEST_SETUP_NAME = 'MyApplicationUtilitiesTest';
    private final static String UNIQUE_ID = '1000';

    @TestSetup
    static void setup() {
        List<Contact> contacts = new List<Contact>();
        List<Application__c> applications = new List<Application__c>();
        List<Application_Course_Preference__c> prefs = new List<Application_Course_Preference__c>();
        List<Encumbrance__c> encs = new List<Encumbrance__c>();

        for (Integer i = 0; i < 2; i++) {
            Contact c = StudFirst_TestHelper.createApplicant();
            c.FirstName = TEST_SETUP_NAME + i;
            c.Person_ID_unique__c = UNIQUE_ID + i;
            contacts.add(c);

            Application__c a = StudFirst_TestHelper.createApplication(c);
            a.Guardian_Full_Name__c = TEST_SETUP_NAME + i;
            applications.add(a);
        }

        insert contacts;

        for (Integer i = 0; i < contacts.size(); i++) {
            Application__c a = StudFirst_TestHelper.createApplication(contacts[i]);
            a.Guardian_Full_Name__c = TEST_SETUP_NAME + i;
            applications.add(a);
        }

        insert applications;

        for (Integer i = 0; i < contacts.size(); i++) {
            Application_Course_Preference__c pref = new Application_Course_Preference__c();
            pref.Attendance_Mode__c = TEST_SETUP_NAME + i;
            pref.Applicant__c = contacts[i].Id;
            pref.Application__c = applications[i].Id;
            prefs.add(pref);
        }

        insert prefs;

        for (Integer i = 0; i < contacts.size(); i++) {
            Encumbrance__c enc = new Encumbrance__c();
            enc.Contact__c = contacts[i].Id;
            encs.add(enc);
        }

        insert encs;

        /********************************************************
        Setup User
        ********************************************************/
        String profileId = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Customer Community General User'
                LIMIT 1
        ].Id;

        Account accountRecord = new Account(Name = TEST_SETUP_NAME) ;
        insert accountRecord;

        Contact contactRecord = new Contact();
        contactRecord.FirstName = TEST_SETUP_NAME;
        contactRecord.LastName = TEST_SETUP_NAME;
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'INT-TEP';
        contactRecord.MailingCountry = 'AUSTRALIA';
        insert contactRecord;

        Integer rnd = Integer.valueOf(Math.random() * 9999);
        User userRec = new User(Alias = String.valueOf(rnd) + 'usr',
                Email = String.valueOf(rnd) + 'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = TEST_SETUP_NAME + 'User',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                Username = String.valueOf(rnd) + 'testuser@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'INT-TEP',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert userRec;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [
                    SELECT Id
                    FROM PermissionSet
                    WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME
            ].Id, AssigneeId = userRec.Id);
            insert psa;
        }

        Application__c app = new Application__c();
        app.Applicant__c = userRec.ContactId;
        app.Guardian_Full_Name__c = 'RecordAccessTest';
        insert app;

        Course__c course1 = new Course__c();
        course1.Name = 'CrsNme-1';
        course1.Course_Description__c = 'CourseDescription-1';
        course1.Course_Code__c = 'CourseCode-1';
        course1.Version__c = '1';
        course1.Faculty_Description__c = 'FacultyDescription-1';
        course1.Sub_Level__c = '41';
        course1.Title__c = 'Course Title';
        course1.Managing_Faculty__c = 'Faculty of Engineering';
        course1.Faculty_Code__c = 'FacCode';
        course1.Type__c = 'Course-All';
        insert course1;
    }

    @IsTest
    public static void test_IsDomestic() {
        System.assertEquals(true, MyApplicationUtilities.isDomestic('DOM-AUS'), 'Domestic Classification has been changed for domestic values');
    }

    @IsTest
    public static void test_IsNotDomestic() {
        System.assertEquals(false, MyApplicationUtilities.isDomestic('INTRNTNL'), 'International Classification has been changed for domestic values');
    }

    @IsTest
    public static void test_IsDomesticNullCheck() {
        System.assertEquals(false, MyApplicationUtilities.isDomestic(null), 'Unable to handle null in the function');
    }

    @IsTest
    public static void test_IsInternational() {
        System.assertEquals(true, MyApplicationUtilities.isInternational('INTRNTNL'), 'International Classification has been changed for international values');
    }

    @IsTest
    public static void test_IsNotInternational() {
        System.assertEquals(false, MyApplicationUtilities.isInternational('DOM-AUS'), 'Domestic Classification has been changed for international values');
    }

    @IsTest
    public static void test_IsInternationalNullCheck() {
        System.assertEquals(false, MyApplicationUtilities.isInternational(null), 'Unable to handle null in the function');
    }

    @IsTest
    public static void test_GetCitizenshipType() {
        //Setup Contact
        List<Contact> contacts = [
                SELECT FirstName
                FROM Contact
                WHERE FirstName = :TEST_SETUP_NAME + '0'
        ];

        System.assert(contacts.size() > 0);

        contacts[0].Citizenship__c = 'DOM-AUS';
        update contacts;

        System.assertEquals('DOM-AUS', MyApplicationUtilities.getCitizenshipType(contacts[0].Id), 'Unable to get the Citizenship information for contact');
    }

    @IsTest
    public static void test_GetCitizenshipTypeNoContactId() {
        System.assertEquals('ERROR', MyApplicationUtilities.getCitizenshipType('AAA'), 'Not guarding against invalid contact ID being passed');
    }

    @IsTest
    public static void test_GetCitizenshipTypeNull() {
        System.assertEquals('ERROR', MyApplicationUtilities.getCitizenshipType(null), 'Not guarding against null checks being passed to the function');
    }

    @IsTest
    public static void test_IntegrationInternationalTrue() {
        System.assertEquals(true, MyApplicationUtilities.integrationInternational('INTRNTNL'), 'International classification is returning domesic');
    }

    @IsTest
    public static void test_IntegrationInternationalFalse() {
        System.assertEquals(false, MyApplicationUtilities.integrationInternational('DOM-AUS'), 'Domestic classification is returning International');
        System.assertEquals(false, MyApplicationUtilities.integrationInternational('DOM-NZ'), 'Domestic classification is returning International');
        System.assertEquals(false, MyApplicationUtilities.integrationInternational('DOM-PR'), 'Domestic classification is returning International');
        System.assertEquals(false, MyApplicationUtilities.integrationInternational('HOM-HV'), 'Domestic classification is returning International');
    }

    @IsTest
    public static void test_GetApplicationCitizenshipType() {
        List<Application__c> applications = [
                SELECT Id
                FROM Application__c
                WHERE Guardian_Full_Name__c = :TEST_SETUP_NAME + '0'
        ];
        System.assert(applications.size() > 0);

        applications[0].Campus_Location__c = 'Australia';
        applications[0].Residency_Status__c = 'DOM-AUS';
        update applications;

        System.assertEquals('DOMESTIC', MyApplicationUtilities.getApplicationCitizenshipType(applications[0].Id), 'DOM-AUS classification is returning International for Australian Campus');
    }

    @IsTest
    public static void test_GetApplicationCitizenshipTypeBadMapping() {
        List<Application__c> applications = [
                SELECT Id
                FROM Application__c
                WHERE Guardian_Full_Name__c = :TEST_SETUP_NAME + '0'
        ];
        System.assert(applications.size() > 0);

        applications[0].Campus_Location__c = 'Malaysia';
        applications[0].Residency_Status__c = 'INTRNTNL';
        update applications;

        System.assertEquals(null, MyApplicationUtilities.getApplicationCitizenshipType(applications[0].Id), 'Invalid combination is passing for citizenship classification');
    }

    @IsTest
    public static void test_GetApplicationCitizenshipTypeNull() {
        System.assertEquals('DOMESTIC', MyApplicationUtilities.getApplicationCitizenshipType(null), 'Not returning an error for null values');
    }

    @IsTest
    public static void test_GetApplicationCitizenshipTypeIndonesia() {
        List<Application__c> applications = [
                SELECT Id
                FROM Application__c
                WHERE Guardian_Full_Name__c = :TEST_SETUP_NAME + '0'
        ];
        System.assert(applications.size() > 0);

        applications[0].Campus_Location__c = 'Indonesia';
        applications[0].Residency_Status__c = 'DOM-IDN';
        update applications;

        System.assertEquals('DOMESTIC', MyApplicationUtilities.getApplicationCitizenshipType(applications[0].Id), 'Invalid combination is passing for citizenship classification');
    }
    
    @IsTest
    public static void test_GetCitizenshipTypeByAppId() {
        List<Contact> contacts = [
                SELECT Id, Citizenship__c
                FROM Contact
                WHERE FirstName = :TEST_SETUP_NAME + '0'
        ];
        System.assert(contacts.size() > 0);

        contacts[0].Citizenship__c = 'INTERNATIONAL';
        update contacts;

        List<Application__c> applications = [
                SELECT Id
                FROM Application__c
                WHERE Applicant__c = :contacts[0].Id
        ];

        System.assert(applications.size() > 0);
        System.assertEquals('INTERNATIONAL', MyApplicationUtilities.getCitizenshipTypeByAppId(applications[0].Id), 'Unable to get the Citizenship Type from the Contact via Application ID');
    }

    @IsTest
    public static void test_GetCitizenshipTypeByAppIdNull() {
        System.assertEquals('ERROR', MyApplicationUtilities.getCitizenshipTypeByAppId(null), 'Unable to get the Citizenship Type from the Contact via Application ID');
    }

    @IsTest
    public static void test_GetCitizenshipTypeCodeByContactId() {
        List<Contact> contacts = [
                SELECT Id, Residency_Status__c
                FROM Contact
                WHERE FirstName = :TEST_SETUP_NAME + '0'
        ];
        System.assert(contacts.size() > 0);
        contacts[0].Residency_Status__c = 'DOM-AUS';
        update contacts;

        System.assertEquals('DOM-AUS', MyApplicationUtilities.getCitizenshipTypeCodeByContactId(contacts[0].Id), 'Unable to get Residency Status via the contact Id');
    }

    @IsTest
    public static void test_GetCitizenshipTypeCodeByContactIdNull() {
        System.assertEquals(null, MyApplicationUtilities.getCitizenshipTypeCodeByContactId(null), 'Function not handling null checks');
    }

    @IsTest
    public static void test_GetCitizenshipTypeCodeByContactIdBadId() {
        System.assertEquals(null, MyApplicationUtilities.getCitizenshipTypeCodeByContactId('AAA'), 'Function not handling bad id being passed');
    }

    @IsTest
    public static void test_GetApplicationStatusByAppId() {
        List<Contact> contacts = [
                SELECT Id, Citizenship__c
                FROM Contact
                WHERE FirstName = :TEST_SETUP_NAME + '0'
        ];
        System.assert(contacts.size() > 0);

        List<Application__c> applications = [
                SELECT Id
                FROM Application__c
                WHERE Applicant__c = :contacts[0].Id
        ];

        System.assert(applications.size() > 0);

        applications[0].Submission_Progress__c = 'Review';
        update applications;

        System.assertEquals('Review', MyApplicationUtilities.getApplicationStatusByAppId(applications[0].Id), 'Unable to get the status of the application');
    }

    @IsTest
    public static void test_GetApplicationStatusByIdNull() {
        System.assertEquals('ERROR', MyApplicationUtilities.getApplicationStatusByAppId(null), 'Function not handling null checks');
    }

    @IsTest
    public static void test_GetApplicationStatusByIdBadId() {
        System.assertEquals('ERROR', MyApplicationUtilities.getApplicationStatusByAppId('AAA'), 'Function not handling bad id being passed');
    }

    @IsTest
    public static void test_GetAppIdByAcpId() {
        List<Application_Course_Preference__c> prefs = [
                SELECT Id, Application__c
                FROM Application_Course_Preference__c
                WHERE Attendance_Mode__c = :TEST_SETUP_NAME + '0'
        ];
        System.assert(prefs.size() > 0);
        System.assertEquals(prefs[0].Application__c, MyApplicationUtilities.getAppIdByAcpId(prefs[0].Id), 'Unable to get the ID of the Application via the ACP');
    }

    @IsTest
    public static void test_GetAppIdByAcpIdNull() {
        System.assertEquals('ERROR', MyApplicationUtilities.getAppIdByAcpId(null), 'Function not handling null checks');
    }

    @IsTest
    public static void test_GetAppIdByAcpIdBadId() {
        System.assertEquals('ERROR', MyApplicationUtilities.getAppIdByAcpId('AAA'), 'Function not handling bad is being passed');
    }

    @IsTest
    public static void test_GetPicklistOptions() {
        List<String> results = MyApplicationUtilities.getPicklistOptions('Status__c', 'Application__c');
        System.assert(results.size() > 0, 'Unable to get Picklist Values');
    }

    @IsTest
    public static void test_GetPicklistOptionsNull() {
        List<String> results = MyApplicationUtilities.getPicklistOptions(null, null);
        System.assertEquals(0, results.size(), 'Unable to handle null values');
    }

    @IsTest
    public static void test_GetPicklistOptionsBadValues() {
        List<String> results = MyApplicationUtilities.getPicklistOptions('132', 'Bad');
        System.assertEquals(0, results.size(), 'Unable to handle bad values');
    }

    @IsTest
    public static void test_GetPicklistOptionsMap() {
        Map<String, String> results = MyApplicationUtilities.getPicklistOptionsMap('Status__c', 'Application__c');
        System.assert(results.size() > 0, 'Unable to get Picklist Values');
    }

    @IsTest
    public static void test_GetPicklistOptionsMapNull() {
        Map<String, String> results = MyApplicationUtilities.getPicklistOptionsMap(null, null);
        System.assertEquals(0, results.size(), 'Unable to handle null values');
    }

    @IsTest
    public static void test_GetPicklistOptionsMapBadValues() {
        Map<String, String> results = MyApplicationUtilities.getPicklistOptionsMap('Bad', 'Value');
        System.assertEquals(0, results.size(), 'Unable to handle bad values');
    }

    @IsTest
    public static void test_GetEncumbrancesByContact() {

        List<Contact> contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :TEST_SETUP_NAME + '0'
        ];
        System.assert(contacts.size() > 0, 'Unable to find contacts');

        List<Encumbrance__c> enc = MyApplicationUtilities.getEncumbrancesByContact(contacts[0].Id);
        System.assert(enc.size() > 0, 'Unable to get Encumbrances for Contact');
    }

    @IsTest
    public static void test_GetEncumbrancesByContactNull() {
        List<Encumbrance__c> enc = MyApplicationUtilities.getEncumbrancesByContact(null);
        System.assertEquals(0, enc.size(), 'Unable to handle null values');
    }

    @IsTest
    public static void test_GetRecordAccessForUserByIds() {

        User user = [
                SELECT ContactId
                FROM User
                WHERE LastName = :TEST_SETUP_NAME + 'User'
        ];

        List<Application__c> applications = [
                SELECT Id
                FROM Application__c
                WHERE Guardian_Full_Name__c = 'RecordAccessTest'
        ];

        System.assert(applications.size() > 0, 'Could not find applications for record access test');
        System.assertNotEquals(null, MyApplicationUtilities.getRecordAccessForUserByIds(applications[0].Id, user.Id), 'Unable to get access to this record for the user');
    }

    @IsTest
    public static void test_GetRecordAccessForUserByIdsNull() {
        System.assertEquals(null, MyApplicationUtilities.getRecordAccessForUserByIds(null, null), 'Unable to handle null values');
    }

    @IsTest
    public static void test_IsMonashStudentFeeWaiver() {
        List<Contact> contacts = [
                SELECT Person_ID_unique__c, Birthdate
                FROM Contact
                WHERE FirstName = :TEST_SETUP_NAME + '0'
        ];

        System.assert(contacts.size() > 0, 'Unable to retrieve contact for Student Waiver');
        System.assertEquals(true, MyApplicationUtilities.isMonashStudentFeeWaiver(contacts[0].Person_ID_unique__c, contacts[0].Birthdate), 'Unable to match contact for fee waiver for previous student');
    }

    @IsTest
    public static void test_IsMonashStudentFeeWaiverNull() {
        System.assertEquals(true, MyApplicationUtilities.isMonashStudentFeeWaiver(null, null), 'Unable to match contact for fee waiver for previous student');
    }

    @IsTest
    public static void test_AustralianCampusLocation(){
        System.assertEquals('Australia', MyApplicationUtilities.ConvertCampusToLocation('CLAYTON'), 'Incorrect country returned for processing campus');
    }


    @IsTest
    public static void test_MalaysianCampusLocation(){
        System.assertEquals('Malaysia', MyApplicationUtilities.ConvertCampusToLocation('MALAYSIA'), 'Incorrect country returned for processing campus');
    }

    @isTest
    public static void test_FindCurrentPreviousStudent_NoMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     WHERE FirstName = :TEST_SETUP_NAME + '0'
                                     LIMIT 1];

        String result;
        Test.startTest();
            result = MyApplicationUtilities.findCurrentPreviousStudent(contactList[0].Person_ID_unique__c + '1', contactList[0].Birthdate);
        Test.stopTest();
        
        System.assertEquals('NoMatch', result);
    }

    @isTest
    public static void test_FindCurrentPreviousStudent_HasMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     WHERE FirstName = :TEST_SETUP_NAME + '0'
                                     LIMIT 1];

        String result;
        Test.startTest();
            result = MyApplicationUtilities.findCurrentPreviousStudent(contactList[0].Person_ID_unique__c, contactList[0].Birthdate);
        Test.stopTest();
        
        System.assertEquals('HasMatch', result);
    }

    @isTest
    public static void test_FindCurrentPreviousStudent_CurrentMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     WHERE FirstName = :TEST_SETUP_NAME + '0'
                                     LIMIT 1];
        List<Course__c> courseList = [SELECT Id 
                                     FROM Course__c
                                     LIMIT 1];
        insert new Course_Attempt__c(Contact__c = contactList[0].Id,
                                     Course__c = courseList[0].Id,
                                     Course_Attempt_Status__c = 'Enrolled');

        String result;
        Test.startTest();
            result = MyApplicationUtilities.findCurrentPreviousStudent(contactList[0].Person_ID_unique__c, contactList[0].Birthdate);
        Test.stopTest();
        
        System.assertEquals('CurrentMatch', result);
    }

    @isTest
    public static void test_FindCurrentPreviousStudent_PreviousMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     WHERE FirstName = :TEST_SETUP_NAME + '0'
                                     LIMIT 1];        
        List<Course__c> courseList = [SELECT Id 
                                      FROM Course__c
                                      LIMIT 1];
        insert new Course_Attempt__c(Contact__c = contactList[0].Id,
                                     Course__c = courseList[0].Id,
                                     Course_Attempt_Status__c = 'Discontin');

        String result;
        Test.startTest();
            result = MyApplicationUtilities.findCurrentPreviousStudent(contactList[0].Person_ID_unique__c, contactList[0].Birthdate);
        Test.stopTest();

        System.assertEquals('PreviousMatch', result);
    }

    @isTest
    public static void test_DocklandsCampusLocation()
    {
        TriggerCommon.disableTrigger('Contact');
     

        List<Contact> conList = new List<Contact>();
        Contact c = StudFirst_TestHelper.createApplicant();
        c.Person_ID_unique__c = '12341578';
        conList.add(c);
       
        Application__c app = StudFirst_TestHelper.createApplication(c);
        app.campus__c ='DOCKLANDS';
        insert app;
        Application__c appRet = [select Campus_Location__c from Application__c where id=:app.Id];

        System.assertEquals('Australia', appRet.Campus_Location__C , 'The campus location must be Australia.');
    }
}