/**
 * @description       : Test class for ACP : AS : PD Transfer Course Offering
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 04-07-2025
 */
@isTest(isParallel=true)
public with sharing class ACPASPDTransferCourseOffering_FT {
    
    @testSetup
    // Setup test data
    static void setupTestData() {

        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);

        Contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        insert application;

        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        Payment__c payment = StudFirst_TestHelper.createPayment(courseOffering, applicant, application);
        insert payment;

        Application_Course_Preference__c ACP =  StudFirst_TestHelper.createCoursePreferences(application, applicant, courseOffering, course);
        insert ACP;
    }
    
    @isTest
    // Test PD Transfer Course Offering
    static void testPDTransferCourseOffering() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = [SELECT Id FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        ACP.Status__c = 'Registered';
        Course__c newCourse = StudFirst_TestHelper.createCourse();
        newCourse.Name = 'New Course';
        insert newCourse;
        Course_Offering__c newCourseOffering = StudFirst_TestHelper.createCourseOffering(newCourse);
        insert newCourseOffering;
        ACP.Course_Offering__c = newCourseOffering.Id;
        
        // When: Update Application_Course_Preference record
        Test.startTest();
        update ACP;
        Test.stopTest();
        
        // Then: Verify results
        Application_Course_Preference__c insertedACP = [
            SELECT Id, Course_Offering__c
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];

        Payment__c insertedPayment = [
            SELECT Id, Course_Offering__c
            FROM Payment__c 
            WHERE Course_Offering__c = :ACP.Course_Offering__c
            LIMIT 1
        ];
        
        Assert.areEqual(insertedPayment.Course_Offering__c, insertedACP.Course_Offering__c, 'Course Offering should be updated');
    }
}