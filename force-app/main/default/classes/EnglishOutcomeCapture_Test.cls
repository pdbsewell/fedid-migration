/**
 * Created by trentdelaney on 26/5/20.
 */

@IsTest(IsParallel=true)
public with sharing class EnglishOutcomeCapture_Test {
    public static String ENGLISH_TEST_NAME = 'EnglishOutcomeTest';

    @TestSetup
    public static void setup() {
        Contact c = StudFirst_TestHelper.createApplicant();
        c.FirstName = ENGLISH_TEST_NAME;
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;
        Application_Course_Preference__c pref = StudFirst_TestHelper.createCoursePreferences(app, c, offering, course);
        insert pref;

        Qualification__c qual = StudFirst_TestHelper.createOtherQualification();
        insert qual;

        Contact_Qualification__c contactQual = StudFirst_TestHelper.createContactQualification(c, qual, 'English Test');
        insert contactQual;

        Course_Preference_Qualification__c coursePreferenceQualification = new Course_Preference_Qualification__c();
        coursePreferenceQualification.Qualification_Type__c = 'English';
        coursePreferenceQualification.Type__c = 'English Test Results';
        coursePreferenceQualification.Application_Course_Preference_Parent__c = pref.Id;
        coursePreferenceQualification.Contact_Qualification__c = contactQual.Id;
        coursePreferenceQualification.Contact__c = c.Id;
        coursePreferenceQualification.Result__c = 'Satisfactory';
        insert coursePreferenceQualification;
    }

    @IsTest
    public static void testGetContactQualifications() {
        List<Contact> contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :ENGLISH_TEST_NAME
        ];
        Assert.areEqual(
            true, 
            contacts.size() > 0, 
            'Unable to get any contacts for the contact qualification test'
        );
		List<Application__c> app = [Select Id FROM Application__c];
        app[0].Status__c = 'Submitted';
        update app[0];
        List<Contact_Qualification__c> cqual = [Select Id FROM Contact_Qualification__c];
        //create application qualification provided
        Application_Qualification_Provided__c aqp = StudFirst_TestHelper.createAppQualProvided(app[0].Id, cqual[0].Id);
        insert aqp;
        List<Contact_Qualification__c> contactQualifications = EnglishOutcomeCapture.getContactQualifications(contacts[0].Id);
        Assert.areEqual(
            true,
            contactQualifications.size() > 0, 
            'Unable to get any contact qualifications from the contact for English Outcome Capture Assignment'
        );
    }
    
    @IsTest
    public static void testGetContactQualificationsByRecordType() {
        List<Contact> contacts = [
                SELECT Id
                FROM Contact
                WHERE FirstName = :ENGLISH_TEST_NAME
        ];
        Assert.areEqual(
            true, 
            contacts.size() > 0, 
            'Unable to get any contacts for the contact qualification test'
        );

        List<Contact_Qualification__c> contactQualifications = EnglishOutcomeCapture.getContactQualificationsByRecordType(contacts[0].Id, 'English Test Results');
        Assert.areEqual(
            true,
            contactQualifications.size() > 0, 
            'Unable to get any contact qualifications from the contact for English Outcome Capture Assignment'
        );
    }

    @IsTest
    public static void testGetCoursePreferenceQualifications() {
        List<Application_Course_Preference__c> coursePreferences = [
                SELECT Id
                FROM Application_Course_Preference__c
                WHERE Applicant__r.FirstName = :ENGLISH_TEST_NAME
        ];

        Assert.areEqual(
            true,
            coursePreferences.size() > 0, 
            'Unable to get any preferences for the contact qualification test'
        );
        List<Course_Preference_Qualification__c> coursePreferenceQualifications = EnglishOutcomeCapture.getCoursePreferenceQualifications(coursePreferences[0].Id);
        Assert.areEqual(
            true,
            coursePreferenceQualifications.size() > 0, 
            'Unable to get any Course Preference Qualifications'
        );
    }

    @IsTest
    public static void testCreateCoursePreferenceQualification() {
        List<Application_Course_Preference__c> coursePreferences = [SELECT Id FROM Application_Course_Preference__c WHERE Applicant__r.FirstName = :ENGLISH_TEST_NAME];
        List<Contact_Qualification__c> contactQualifications = [SELECT Id, Contact__r.Id FROM Contact_Qualification__c WHERE Contact__r.FirstName = :ENGLISH_TEST_NAME];
		Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        Assert.isNotNull(
            EnglishOutcomeCapture.getApplicationCoursePreferences(contactRecord.Id), 
            'Application course preferences should exist'
        ); 
        Assert.areEqual(
            EnglishOutcomeCapture.getCourseAttempts(contactRecord.Id).isEmpty(), 
            true, 
            'Course attempts do not exist'
        );
        Assert.areEqual(
            true,
            coursePreferences.size() > 0, 
            'Unable to get any preferences for the contact qualification test'
        );
        Assert.areEqual(
            true,
            contactQualifications.size() > 0, 
            'Unable to get any contact qualifications for the contact qualification test'
        );

        EnglishOutcomeCapture.RecordSaveList records = new EnglishOutcomeCapture.RecordSaveList();
        EnglishOutcomeCapture.RecordSaveStructure structure = new EnglishOutcomeCapture.RecordSaveStructure();
        structure.applicationCoursePreference = coursePreferences[0].Id;
        structure.type = 'English Test Results';
        structure.contactId = contactQualifications[0].Contact__r.Id;
        structure.recordId = contactQualifications[0].Id;
        structure.result = 'Satisfactory';
        records.records.add(structure);


        List<Course_Preference_Qualification__c> coursePreferenceQualifications = EnglishOutcomeCapture.createCoursePreferenceQualification(JSON.serialize(records));
        Assert.areEqual(
            true,
            coursePreferenceQualifications.size() > 1, 
            'Unable to insert course preference qualification'
        );
    }

    @IsTest
    public static void testRemoveCoursePreferenceQualification() {
        List<Course_Preference_Qualification__c> coursePreferenceQualifications = [
                SELECT Id
                FROM Course_Preference_Qualification__c
                WHERE Application_Course_Preference_Parent__r.Applicant__r.FirstName = :ENGLISH_TEST_NAME
        ];

        Assert.areEqual(
            true,
            coursePreferenceQualifications.size() > 0, 
            'Unable to get any course preference qualifications for the contact qualification test'
        );

        EnglishOutcomeCapture.removeCoursePreferenceQualification(coursePreferenceQualifications[0].Id);

        coursePreferenceQualifications = [
                SELECT Id
                FROM Course_Preference_Qualification__c
                WHERE Application_Course_Preference__r.Applicant__r.FirstName = :ENGLISH_TEST_NAME
        ];


        Assert.areEqual(
            true,
            coursePreferenceQualifications.size() == 0, 
            'Unable to remove record'
        );
    }
}