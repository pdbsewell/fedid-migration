/**
 * @author Trent De Laney
 * @date 18 Nov 2019 at 1:41:00 pm
 * @group Test Class
 * @description Test class to cover the IDP validation library
 */
@IsTest(IsParallel=true)
private class IDPDataValidator_Test {

    private final static String CONTACT_NAME = 'IDPDataValidator';

    @TestSetup
    static void setup() {
        Contact o_testContact = StudFirst_TestHelper.createInternationalApplicant();
        o_testContact.FirstName = CONTACT_NAME;
        insert o_testContact;
        Application__c o_testApplication = StudFirst_TestHelper.createApplication(o_testContact);
        o_testApplication.Source_System__c = 'IDP';
        insert o_testApplication;
        Course__c o_testCourse = StudFirst_TestHelper.createCourse();
        insert o_testCourse;

        List<Course_Offering__c> offerings = new List<Course_Offering__c>();
        Course_Offering__c o_testCourseOffering = StudFirst_TestHelper.createCourseOffering(o_testCourse);
        offerings.add(o_testCourseOffering);
        Course_Offering__c o_testCourseOffering2 = StudFirst_TestHelper.createCourseOffering(o_testCourse);
        o_testCourseOffering2.Location_Code__c = 'MALAYSIA';
        offerings.add(o_testCourseOffering2);
        insert offerings;

        List<Application_Course_Preference__c> prefs = new List<Application_Course_Preference__c>();
        Application_Course_Preference__c o_testCoursePreference = StudFirst_TestHelper.createCoursePreferences(o_testApplication, o_testContact, o_testCourseOffering, o_testCourse);
        Application_Course_Preference__c o_testCoursePreference2 = StudFirst_TestHelper.createCoursePreferences(o_testApplication, o_testContact, o_testCourseOffering, o_testCourse);
        prefs.add(o_testCoursePreference);
        prefs.add(o_testCoursePreference2);
        insert prefs;

        Qualification__c o_testQualification = StudFirst_TestHelper.createQualification('IDP Test Qualification');
        insert o_testQualification;

        Contact_Qualification__c o_testContactQualification = StudFirst_TestHelper.createContactQualification(o_testContact, o_testQualification, 'Tertiary Education');
        insert o_testContactQualification;
    }

    /**
    * @author Trent De Laney
    * @description Tests a successful application validation from IDP Source System
    * @date 18 Nov 2019 at 1:49:10 pm
    */
    @IsTest
    static void testSuccessfulApplication() {
        //Get the application First
        List<Contact> li_contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :CONTACT_NAME
        ];

        System.assert(li_contacts.size() > 0);

        List<Application__c> li_applications = [
                SELECT Id
                FROM Application__c
                WHERE Applicant__c = :li_contacts[0].Id
        ];

        System.assert(li_applications.size() > 0);


        IDPDataValidator validator = new IDPDataValidator();
        validator.validateApplicationData(li_applications[0].Id);

        //Query the application again
        List<Application__c> li_validatedApplications = [
                SELECT Data_Validation_Errors__c, Campus_Location__c
                FROM Application__c
                WHERE Id = :li_applications[0].Id
        ];

        System.assert(li_validatedApplications.size() == 1);
        System.assertEquals('Australia', li_validatedApplications[0].Campus_Location__c, 'Unable to translate the campus information to a country');
        System.assertEquals(null, li_validatedApplications[0].Data_Validation_Errors__c, 'Validation of the Application failed for Assessment - ');
    }

    @IsTest
    static void testInvalidCitizenshipApplication() {
        //Get the application First
        List<Contact> li_contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :CONTACT_NAME
        ];

        System.assert(li_contacts.size() > 0);

        List<Application__c> li_applications = [
                SELECT Id, Residency_Status__c
                FROM Application__c
                WHERE Applicant__c = :li_contacts[0].Id
        ];

        System.assert(li_applications.size() > 0);

        li_applications[0].Residency_Status__c = 'INTRNTNL';
        li_applications[0].Visa_Type__c = '411';
        li_applications[0].Visa_Number__c = '';
        li_applications[0].Passport_Number__c = '';
        li_applications[0].Visa_Start_Date__c = null;
        li_applications[0].Visa_End_Date__c = null;
        update li_applications[0];

        IDPDataValidator validator = new IDPDataValidator();
        validator.validateApplicationData(li_applications[0].Id);

        //Query the application again
        List<Application__c> li_validatedApplications = [
                SELECT Data_Validation_Errors__c
                FROM Application__c
                WHERE Id = :li_applications[0].Id
        ];

        System.assert(li_validatedApplications.size() == 1);
        System.assertNotEquals(null, li_validatedApplications[0].Data_Validation_Errors__c, 'Validation of the Application succeeded for Assessment - ');
    }

    @IsTest
    public static void testDifferentCampusLocation() {
        List<Contact> contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :CONTACT_NAME
        ];

        System.assert(contacts.size() > 0, 'Unable to get contacts for ' + CONTACT_NAME);

        List<Course_Offering__c> courseOffers = [SELECT Id, Location_Code__c FROM Course_Offering__c WHERE Location_Code__c = 'MALAYSIA'];

        List<Application_Course_Preference__c> coursePreferences = [
                SELECT Id, Course_Offering__c
                FROM Application_Course_Preference__c
                WHERE Applicant__c = :contacts[0].Id
        ];

        System.assert(coursePreferences.size() > 1, 'Unable to get two ACPs for test');
        coursePreferences[0].Course_Offering__c = courseOffers[0].Id;
        update coursePreferences;

        List<Application__c> applications = [
                SELECT Id
                FROM Application__c
                WHERE Applicant__c = :contacts[0].Id
        ];

        System.assert(applications.size() > 0, 'Unable to get any applications back for ' + CONTACT_NAME);

        IDPDataValidator validator = new IDPDataValidator();
        validator.validateApplicationData(applications[0].Id);

        List<Application__c> li_validatedApplications = [
                SELECT Data_Validation_Errors__c
                FROM Application__c
                WHERE Id = :applications[0].Id
        ];

        System.assertNotEquals(null, li_validatedApplications[0].Data_Validation_Errors__c, 'Validation of the Application succeeded for Assessment - ');
    }
}