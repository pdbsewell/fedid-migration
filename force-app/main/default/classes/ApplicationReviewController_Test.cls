/* @author       trentdelaney
* @date         26/9/18
* @description  test class for ApplicationReviewController
* @revision
* 20.Jun.2024 - Vishal Gupta - MGROI-267 review page refactor, 
                adding more test data to cover the maximum test cases
*******************************************************************************/
@isTest(isParallel=false) // Set isParallel to false to overcome mixed DML operation exception on parallel Apex test
private class ApplicationReviewController_Test {

    @IsTest
    /**
     * @author      trentdelaney
     * @description Tests creating the ApplicationReviewController
     * @revision    26/9/18 created
     *
     * GIVEN the student has applied for the my application from student portal
     * WHEN they are logged in and applied to see the submitted or draft application
     * THEN system shoud see the application review page when they come to the review page
     */
    static void test_GetFullApplication()
    {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        app.Type_of_Study__c = 'Exchange';
        update app;

        // Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        Qualification__c qual2 = StudFirst_TestHelper.createQualification('Tertiary');
        insert qual2;

        Qualification__c qual3 = StudFirst_TestHelper.createQualification('Other');
        insert qual3;

        Qualification__c qual4 = StudFirst_TestHelper.createQualification('English');
        insert qual4;

        // Create Contact Qualifications
        Contact_Qualification__c contactQualification1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        insert contactQualification1;

        Contact_Qualification__c contactQualification2 = StudFirst_TestHelper.createContactQualification(c, qual2, 'Tertiary Education');
        insert contactQualification2;

        Contact_Qualification__c contactQualification3 = StudFirst_TestHelper.createContactQualification(c, qual3, 'Other Qualification');
        insert contactQualification3;

        Contact_Qualification__c contactQualification4 = StudFirst_TestHelper.createContactQualification(c, qual4, 'English Test');
        insert contactQualification4;

        // Create Application Qualifications provided
        Application_Qualification_Provided__c aqp1 = StudFirst_TestHelper.createAppQualProvided(app.Id, contactQualification1.Id);
        insert aqp1;

        // Create Work Experience
        Work_Experience__c workExperience = StudFirst_TestHelper.createWorkExperience(c);
        insert workExperience;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        String returnValue = ApplicationReviewController.GetFullApplication(app.Id);
        Assert.areNotEqual(returnValue, null, 'Application review return something but not null');
    }

    @IsTest
    /**
     * @author      vishal
     * @description Tests creating the ApplicationReviewController
     * @revision    10/9/24 created
     *
     * GIVEN the student has applied for the my application from student portal
     * WHEN they are logged in and applied to see the submitted or draft application
     * THEN system shoud see the application review page when they come to the review page
     */
    static void test_GetFullApplicationGraduateResearch()
    {
        Contact c = StudFirst_TestHelper.createApplicant();
        insert c;

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        app.Type_of_Study__c = 'Graduate Research';
        update app;

        // Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        Qualification__c qual2 = StudFirst_TestHelper.createQualification('Tertiary');
        insert qual2;

        Qualification__c qual3 = StudFirst_TestHelper.createQualification('Other');
        insert qual3;

        Qualification__c qual4 = StudFirst_TestHelper.createQualification('English');
        insert qual4;

        // Create Contact Qualifications
        Contact_Qualification__c contactQualification1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        insert contactQualification1;

        Contact_Qualification__c contactQualification2 = StudFirst_TestHelper.createContactQualification(c, qual2, 'Tertiary Education');
        insert contactQualification2;

        Contact_Qualification__c contactQualification3 = StudFirst_TestHelper.createContactQualification(c, qual3, 'Other Qualification');
        insert contactQualification3;

        Contact_Qualification__c contactQualification4 = StudFirst_TestHelper.createContactQualification(c, qual4, 'English Test');
        insert contactQualification4;

        // Create Application Qualifications provided
        Application_Qualification_Provided__c aqp1 = StudFirst_TestHelper.createAppQualProvided(app.Id, contactQualification1.Id);
        insert aqp1;

        // Create Work Experience
        Work_Experience__c workExperience = StudFirst_TestHelper.createWorkExperience(c);
        insert workExperience;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        Document_Checklist__c checklist = new Document_Checklist__c();
        checklist.application__c = app.Id;
        checklist.status__c = 'Requested';
        checklist.Unique_ID__c = app.Id + 'CV';
        insert checklist;

        String returnValue = ApplicationReviewController.GetFullApplication(app.Id);
        Assert.areNotEqual(returnValue, null, 'Application review return something but not null');
        
    }
}