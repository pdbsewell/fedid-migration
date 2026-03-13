/**
 * @description     Test class specific to PaymentRequestItemWizard class
 * 
 * @author          K. Vegerano
 * @date            16/09/2020
 * 
 * @revision
 * 
 *      02/09/2020 - K Vegerano - created
 *  17.04.2023 Ken McGuire: Changed Comments__c (255 characters) to LongComments__c (4000 characters)
 */
@isTest(isParallel=true)
public with sharing class PaymentRequestItemWizard_Test {
    /**
     * Set up Data
     */
    @testSetup static void setupData(){
        Contact testContact = StudFirst_TestHelper.createApplicant();
        testContact.Person_ID_unique__c = '1111111';
        insert testContact;

        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency', Callista_Org_Unit_Code__c = 'TESTAU');
        insert testAgency;

        //Create payment record
        Payment_Request__c testPaymentRequest = new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678');
        insert testPaymentRequest;

        //Create course record
        Course__c testCourse = new Course__c();
        testCourse.Name = 'CrsNme-1';
        testCourse.Course_Description__c = 'CourseDescription-1';
        testCourse.Course_Code__c = 'CourseCode-1';
        testCourse.Version__c = '1';
        testCourse.Faculty_Description__c = 'FacultyDescription-1';
        testCourse.Sub_Level__c = '41';
        testCourse.Title__c = 'Course Title';
        testCourse.Managing_Faculty__c = 'Faculty of Engineering';
        testCourse.Faculty_Code__c = 'FacCode';
        testCourse.Type__c = 'Course-All';
        insert testCourse;

        //Create application
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'TESTAU';
        testApplication.Agent__c = testAgency.Id;
        testApplication.Applicant__c = testContact.Id;
        insert testApplication;

        Application_Course_Preference__c testACP = new Application_Course_Preference__c();
        testACP.Applicant__c = testContact.Id;
        testACP.LongComments__c = 'ACPInterfaceTest';
        testACP.Precedent_ID__c = 12345;
        testACP.Requirement_Satisfied_Code__c = 'ENGLISH';
        testACP.Recruitment_Reference_Code__c='VCE-DIRECT - VCE STUDENT - DIRECT';
        testACP.Callista_Sync_Successful__c = false;
        testACP.Application__c = testApplication.Id;
        testACP.Callista_Unique_Key_ADM__c = '11111111_a_b_c';
        insert testACP;

        //Create course attempt record
        Course_Attempt__c testCourseAttempt = new Course_Attempt__c();
        testCourseAttempt.Name = 'CrsAtt-1';
        testCourseAttempt.Contact__c = testContact.Id;
        testCourseAttempt.Course__c = testCourse.Id;
        testCourseAttempt.Course_Attempt_Status__c = 'Enrolled';
        testCourseAttempt.Commencement_Date__c = System.Date.today();
        testCourseAttempt.Attendance_Mode__c = 'IN';
        testCourseAttempt.Location__c = 'Clayton';
        testCourseAttempt.Application_Course_Preference__c = testACP.Id;
        insert testCourseAttempt;
    }

    static testMethod void test_RetrieveAgencyCourseAttempts() {
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, Object>();

        //Query payment request record
        Payment_Request__c testPaymentRequest = [SELECT Id FROM Payment_Request__c LIMIT 1];
        Application__c testApplication = [SELECT Id, Agent__c FROM Application__c];

        //Start tests
        Test.startTest();
        resultMap = PaymentRequestItemWizard.retrieveAgencyCourseAttempts(testPaymentRequest.Id);
        Test.stopTest();

        //Assert results
        System.assertEquals(true, resultMap.containsKey('AgencyCode'));
        System.assertEquals(true, resultMap.containsKey('AgencyName'));
        System.assertEquals(true, resultMap.containsKey('CourseAttempts'));
        System.assertEquals(true, resultMap.containsKey('ContactList'));
        System.assertEquals(true, resultMap.containsKey('InvoiceNumber'));
    }

    static testMethod void test_DoSearchStudent() {
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, Object>();

        //Query contact
        Contact testContact = [SELECT Id, Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c != null LIMIT 1];

        //Start tests
        Test.startTest();
        resultMap = PaymentRequestItemWizard.doSearchStudent(testContact.Person_ID_unique__c);
        Test.stopTest();

        //Assert results
        System.assertEquals(true, resultMap.containsKey('CourseAttempts'));
        System.assertEquals(true, resultMap.containsKey('ContactList'));
    }
}