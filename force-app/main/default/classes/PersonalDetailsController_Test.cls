/**
 * @author Trent De Laney
 * @date 13 Dec 2018 at 11:07:04 am
 * @group Test Class
 * @description Defines the test classes for Personal Details Controller
 */
@IsTest(IsParallel=false) // Avoid error : DML operations aren't permitted on this type of object: User
public class PersonalDetailsController_Test {

    @TestSetup
    static void setup() {
        // insert experience mfa custom setting
        ExperienceMFASetting__c	mfaSetting = new ExperienceMFASetting__c();
        mfaSetting.Autotest_Bypass_Key__c = 'bypasskeyword';
        insert mfaSetting;

        Contact testContact = new Contact(LastName = 'TestLastName',
                                          Person_ID_unique__c = '11111111', 
                                          Birthdate = System.today().addYears(-19));
        insert testContact;

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
    public static void test_GetPersonalDetailsInitLoad()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        // add an application
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Status__c = 'SUBMITTED';
        insert app;

        // get a test country
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry testCountry = ple[0];

        // insert a test record
        Country_Attribute__c countryAttr = new Country_Attribute__c();
        countryAttr.Country__c = testCountry.getValue();
        insert countryAttr;

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('ShouldShowInternalMFA', true);

        app.Status__c = 'CANCELLED';
        update app;

        Test.startTest();
        // setup test data
        ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;
        
        System.runAs(u){
            //Positive test
            Map<String, Object> mapResults = PersonalDetailsController.GetPersonalDetailsInitLoad(app.Id, '');
            List<Map<String,String>>  listMap = PersonalDetailsController.getCountryAttributes();

            Contact contact = (Contact) mapResults.get(PersonalDetailsController.FIELD_CONTACT);
            Application__c application = (Application__c) mapResults.get(PersonalDetailsController.FIELD_PREVIOUS_APPLICATION);
            Assert.areEqual(u.ContactId, contact.Id, 'Contact should be returned');
            Assert.areEqual(app.Id, application.Id, 'Application should be returned');

            //Should return true - as CANCELLED is also added to the check on Previous applications statuses
            Assert.areEqual(true, mapResults.get(PersonalDetailsController.FIELD_HAS_PREVIOUS_APPLICATIONS));
      

            //Null Test
            mapResults = PersonalDetailsController.GetPersonalDetailsInitLoad(null, '');
            contact = (Contact) mapResults.get(PersonalDetailsController.FIELD_CONTACT);
            application = (Application__c) mapResults.get(PersonalDetailsController.FIELD_PREVIOUS_APPLICATION);
            Assert.areEqual(u.ContactId, contact.Id, 'Contact should be returned');
            Assert.areEqual(application, null, 'No application should be returned');
            List<Map<String, String>> genderOptions = (List<Map<String, String>>) mapResults.get(PersonalDetailsController.FIELD_GENDER_OPTIONS);
            Assert.areNotEqual(genderOptions, null, 'Gender values are not returned');

        }
        Test.stopTest();
    }

    @IsTest
    public static void test_GetPersonalDetailsInitLoadNoApplication()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        // get a test country
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry testCountry = ple[0];

        // insert a test record
        Country_Attribute__c countryAttr = new Country_Attribute__c();
        countryAttr.Country__c = testCountry.getValue();
        insert countryAttr;

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('ShouldShowInternalMFA', true);

        Test.startTest();
        // setup test data
        ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;

        System.runAs(u){            
            Contact contact;
            Application__c application;
            Map<String, Object> mapResults = new Map<String, Object>();

            //Negative Test
            mapResults = PersonalDetailsController.GetPersonalDetailsInitLoad(null, '');
            contact = (Contact) mapResults.get(PersonalDetailsController.FIELD_CONTACT);
            application = (Application__c) mapResults.get(PersonalDetailsController.FIELD_PREVIOUS_APPLICATION);
            Assert.areEqual(u.ContactId, contact.Id, 'Contact should be returned');
        }
        Test.stopTest();
    }

    @IsTest
    public static void test_SavePersonalDetails()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('ShouldShowInternalMFA', true);

        Test.startTest();
        // setup test data
        ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;

        System.runAs(u)
        {
            Map<String, Object> mapResults = PersonalDetailsController.GetPersonalDetailsInitLoad(app.Id, '');
            Contact contact = (Contact) mapResults.get(PersonalDetailsController.FIELD_CONTACT);
            //Check for Validation Errors Round 1
            contact.MailingCountry = 'Australia';
            contact.FirstName = '';
            contact.LastName = '';
            List<String> errors = PersonalDetailsController.SavePersonalDetails(contact, 'false');
            Assert.areNotEqual(errors.size(), 0, 'Some fields are populated');

            //Check for Validation Errors Round 2
            contact.MailingCountry = '';
            contact.Previously_Studied_at_Monash__c = true;
            contact.Previous_Monash_ID__c = 'AS123';
            contact.FirstName = '123';
            contact.LastName = '123';
            errors = PersonalDetailsController.SavePersonalDetails(contact, 'false');
            Assert.areNotEqual(errors.size(), 0, 'Fields have been populated');

            //Check for correct save
            //Test for Salutation optional
            contact.Salutation = null;
            contact.Salutation_erda__c = 'Mr';
            contact.FirstName = 'Test';
            contact.LastName = 'User';
            contact.Birthdate = Date.today().addYears(-11);
            contact.Gender__c = 'M';
            contact.MobilePhone = '11112222';
            contact.Personal_Email__c = 'test@test.com';
            contact.MailingStreet = '123 Test St';
            contact.MailingCity = 'Melbourne';
            contact.MailingCountry = 'Australia';
            contact.MailingState = 'Victoria';
            contact.MailingPostalCode = '3000';
            contact.Residency_Status__c = 'DOM-AUS';
            contact.Previously_Studied_at_Monash__c = true;
            contact.Previous_Monash_ID__c = '1234567';
            errors = PersonalDetailsController.SavePersonalDetails(contact, 'false');
            Assert.areEqual(errors.size(), 0, 'Should be no errors relating to the saving of Contact');

            contact.Residency_Status__c = 'INT-TEP';
            errors = PersonalDetailsController.SavePersonalDetails(contact, 'false');
            Assert.areEqual(errors.size(), 0, 'Should be no errors relating to the saving of Contact');


            //PersonalDetailsController.SavePersonalDetails(c);
        }
        Test.stopTest();
    }

    @IsTest
    public static void test_GetPicklistValues()
    {
        Map<String, String> values = PersonalDetailsController.GetPicklistValues('Contact','Residency_Status__c');
        Assert.areNotEqual(values.size(), 0, 'Picklist values for Residency Status should be returned');
    }

    @IsTest
    public static void test_UpdateApplication()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.HasDisabilities__c = 'No';
        insert app;

        System.runAs(u)
        {
            PersonalDetailsController.UpdateApplication(app.Id, 'Yes');
            Application__c newApp = [SELECT HasDisabilities__c FROM Application__c WHERE Id = :app.Id];
            Assert.areEqual(newApp.HasDisabilities__c, 'Yes', 'Excepted Has Disabilities to be marked as "Yes"');
            
            PersonalDetailsController.saveApplicationDisabilityConsent(app.Id, 'Yes');
            Assert.areEqual([select Disability_Opt_In__c from Application__c where id=:app.Id].Disability_Opt_In__c, 'Yes', 'Expected to have Disability_Opt_In__c as "Yes" ');
    
        }
    }

    @IsTest
    public static void test_UnlinkedUser()
    {
        //Negative condition to unlink the contact from the user
        User u = StudFirst_TestHelper.createCommunityUser();
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        // build mock current user details
        Map<String, Object> currentUserDetails = new Map<String, Object>();
        currentUserDetails.put('HasVerified', true);
        currentUserDetails.put('ShouldShowInternalMFA', true);

        Test.startTest();
        // setup test data
        ExperienceMFAServices.testCurrentUserDetails = currentUserDetails;

        Map<String, Object> mapResults = PersonalDetailsController.GetPersonalDetailsInitLoad(null, '');
        Contact contact = (Contact) mapResults.get(PersonalDetailsController.FIELD_CONTACT);
        Assert.areEqual(contact, null);
        
        
          Test.stopTest();

    }

    @IsTest
    public static void test_HasACPonApplication()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;

        Contact applicant = [SELECT Id FROM Contact WHERE Id = :u.ContactId];

        //Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;
        //Create Course Offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;

        Boolean condition = PersonalDetailsController.HasACPonApplication(app.Id);
        Assert.areEqual(condition, false);

        condition = PersonalDetailsController.HasACPonApplication(null);
        Assert.areEqual(condition, false);

        Application_Course_Preference__c pref = StudFirst_TestHelper.createCoursePreferences(app, applicant, offering, course);
        insert pref;

        condition = PersonalDetailsController.HasACPonApplication(app.Id);
        Assert.areEqual(condition, true);
    }

    @IsTest
    public static void test_FindMatchingStudent_NoMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     LIMIT 1];

        String result;
        Test.startTest();
            result = PersonalDetailsController.findMatchingStudent(contactList[0].Person_ID_unique__c + '1', String.valueOf(contactList[0].Birthdate));
        Test.stopTest();
        
        Assert.areEqual('NoMatch', result);
    }

    @IsTest
    public static void test_FindMatchingStudent_HasMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     LIMIT 1];

        String result;
        Test.startTest();
            result = PersonalDetailsController.findMatchingStudent(contactList[0].Person_ID_unique__c, String.valueOf(contactList[0].Birthdate));
        Test.stopTest();
        
        Assert.areEqual('HasMatch', result);
    }

    @IsTest
    public static void test_FindMatchingStudent_CurrentMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     LIMIT 1];
        List<Course__c> courseList = [SELECT Id 
                                      FROM Course__c
                                      LIMIT 1];
        insert new Course_Attempt__c(Contact__c = contactList[0].Id,
                                     Course__c = courseList[0].Id,
                                     Course_Attempt_Status__c = 'Enrolled');

        String result;
        Test.startTest();
            result = PersonalDetailsController.findMatchingStudent(contactList[0].Person_ID_unique__c, String.valueOf(contactList[0].Birthdate));
        Test.stopTest();
        
        Assert.areEqual('CurrentMatch', result);
    }

    @IsTest
    public static void test_FindMatchingStudent_PreviousMatch() {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c, Birthdate
                                     FROM Contact
                                     LIMIT 1];
        List<Course__c> courseList = [SELECT Id 
                                      FROM Course__c
                                      LIMIT 1];
        insert new Course_Attempt__c(Contact__c = contactList[0].Id,
                                     Course__c = courseList[0].Id,
                                     Course_Attempt_Status__c = 'Discontin');

        String result;
        Test.startTest();
            result = PersonalDetailsController.findMatchingStudent(contactList[0].Person_ID_unique__c, String.valueOf(contactList[0].Birthdate));
        Test.stopTest();

        Assert.areEqual('PreviousMatch', result);
    }
    
     /*
    * Testing update of Disability Opt In on the Application
    */
    @IsTest
    public static void test_UpdateDisabilityOptIn()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;
	
        System.runAs(u)
        {
            Test.startTest();
            	PersonalDetailsController.saveApplicationDisabilityConsent(app.Id, 'Yes');
            Test.stopTest();
            Assert.areEqual([select Disability_Opt_In__c from Application__c where id=:app.Id].Disability_Opt_In__c, 'Yes', 'Expected to have Disability_Opt_In__c as "Yes" ');
    
        }
    }

    /*
    * Testing SSO user login
    */
    @IsTest
    static void isSSOUserTest()
    {
        JitHandler_Test.testCreateUserForExistingContact();
        User u = [SELECT Id, ContactId FROM User WHERE isActive = true LIMIT 1];
        System.runAs(u) {
            Assert.areEqual(false, PersonalDetailsController.isSSOUser(u.ContactId), 'Expected to have isSSOUser as false');
            MyAppWelcomeEmailController objInstance = new MyAppWelcomeEmailController();
            MyAppWelcomeEmailController.LoginHistoryClass loginHistoryRecord = new MyAppWelcomeEmailController.LoginHistoryClass(MyAppWelcomeEmailController.SSO_IDENTIFIER + 'Single-Sign-on', 'Success');
            Assert.areEqual(true, objInstance.checkSSOLoginFromHistory(loginHistoryRecord), 'Expected to have isSSOUser as true');
        }
    }


    @IsTest
    static void test_saveApplicationMalaysianDetails() {
        // Setup test data: Create a test application
        Application__c testApp = new Application__c();
        testApp.Currently_residing_in_Malaysia__c = false;
        testApp.Malaysian_NRIC_Passport__c = 'OldPassport123';
        testApp.Malaysia_pass_expiry__c = null;
        testApp.Malaysia_pass_type__c = '';
        insert testApp;

        // Test inputs
        String appId = testApp.Id;
        String newPassport = 'NewPassport456';
        Boolean residingMalaysia = true;
        Date newPassExpiry = Date.today().addYears(2);
        String newPassType = 'STUDENT';

        // Test case 1: Valid application update
        Test.startTest();
        PersonalDetailsController.saveApplicationMalaysianDetails(appId, newPassport, residingMalaysia, newPassExpiry, newPassType);
        Test.stopTest();

        // Verify the changes in the application record
        Application__c updatedApp = [SELECT Malaysian_NRIC_Passport__c, Currently_residing_in_Malaysia__c,
                Malaysia_pass_expiry__c, Malaysia_pass_type__c
        FROM Application__c
        WHERE Id = :appId];
        Assert.areEqual(newPassport, updatedApp.Malaysian_NRIC_Passport__c, 'Passport should be updated');
        Assert.areEqual(residingMalaysia, updatedApp.Currently_residing_in_Malaysia__c, 'Currently residing in Malaysia should be updated');
        Assert.areEqual(newPassExpiry, updatedApp.Malaysia_pass_expiry__c, 'Passport expiry should be updated');
        Assert.areEqual(newPassType, updatedApp.Malaysia_pass_type__c, 'Passport type should be updated');
    }
    /*
    * Testing to Save Application Malaysian Details
    */
    @IsTest
    static void saveApplicationMalaysianDetailsTest()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        //Given: we have an application from my.app
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;
        System.runAs(u) {
            //When: the user tries to update the Malaysian personal details
            PersonalDetailsController.saveApplicationMalaysianDetails(app.Id, 'testId', true, Date.Today().addDays(100), 'STUDENT');
            //Then:it should update the details
            Application__c appAfterUpdate = [SELECT Malaysian_NRIC_Passport__c FROM Application__c where Id =:app.Id];
            Assert.areEqual(appAfterUpdate.Malaysian_NRIC_Passport__c, 'testId', 'details updated');
        }
    }
    /*
    * Testing to Save Existing_Aus_disability_support__c
    */
    @IsTest
    static void updateExistingAusDisabilitySupportTest()
    {
        User u = StudFirst_TestHelper.createCommunityUser();
        //Given: we have an application from my.app
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        insert app;
        System.runAs(u) {
            //When: the user tries to update the Malaysian personal details
            PersonalDetailsController.updateExistingAusDisabilitySupport(app.Id, 'Yes');
            //Then:it should update the details
            Application__c appAfterUpdate = [SELECT Existing_Aus_disability_support__c FROM Application__c where Id =:app.Id];
            Assert.areEqual(appAfterUpdate.Existing_Aus_disability_support__c, 'Yes', 'details updated');
        }
    }
}