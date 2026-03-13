/**
 * @description       : Test class for ACP: AS: Update Certificate Be Printed
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 04-07-2025
 */
@isTest(isParallel=true)
public with sharing class ACPASUpdateCertificateBePrinted_FT {
    
    @testSetup
    // Setup test data
    static void setupTestData() {
        insert new Bypass_Mute_Request__c(Bypass_All_Flows__c=false);
        Contact applicant = StudFirst_TestHelper.createApplicant();
        insert applicant;
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        insert application;
        Course__c course = StudFirst_TestHelper.createCourse();
        course.Type__c = 'Short_Course';
        insert course;
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        courseOffering.Course__c = course.Id;
        insert courseOffering;
        Application_Course_Preference__c ACP =  StudFirst_TestHelper.createCoursePreferences(application,applicant,courseOffering,course);
        insert ACP;
    }
    
    @isTest
    // Test Course Type Pass Status
    static void testCourseTypePassStatus() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = [SELECT Id FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        ACP.Course_Result__c = 'Pass';
        
        // When: Update Application_Course_Preference record
        Test.startTest();
        update ACP;
        Test.stopTest();
        
        // Then: Verify results
        Application_Course_Preference__c insertedACP = [
            SELECT Id, Certificate_to_be_printed__c
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];
        
        Assert.areEqual('Completion without credit points', insertedACP.Certificate_to_be_printed__c, 'Certificate Be Printed should be true');
    }
    
    @isTest
    // Test Course Type Pass With Credit Points Status
    static void testCourseTypePassWithCreditPointsStatus() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = [SELECT Id FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        ACP.Course_Result__c = 'Pass with credit points';
        
        // When: Update Application_Course_Preference record
        Test.startTest();
        update ACP;
        Test.stopTest();
        
        // Then: Verify results
        Application_Course_Preference__c insertedACP = [
            SELECT Id, Certificate_to_be_printed__c
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];
        
        Assert.areEqual('Completion with credit points', insertedACP.Certificate_to_be_printed__c, 'Certificate Be Printed should be false');
    }

    @isTest
    // Test Course Type Fail Status
    static void testCourseTypeFailStatus() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = [SELECT Id FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        ACP.Course_Result__c = 'Fail';
        
        // When: Update Application_Course_Preference record
        Test.startTest();
        update ACP;
        Test.stopTest();
        
        // Then: Verify results
        Application_Course_Preference__c insertedACP = [
            SELECT Id, Certificate_to_be_printed__c
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];
        
        Assert.isNull(insertedACP.Certificate_to_be_printed__c, 'Certificate Be Printed should be null');
    }

    @isTest
    // Test Course Type Attended Status
    static void testCourseTypeAttendedStatus() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = [SELECT Id FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        ACP.Course_Result__c = 'Attended';
        
        // When: Update Application_Course_Preference record
        Test.startTest();
        update ACP;
        Test.stopTest();
        
        // Then: Verify results
        Application_Course_Preference__c insertedACP = [
            SELECT Id, Certificate_to_be_printed__c
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];
        
        Assert.areEqual('Attendance', insertedACP.Certificate_to_be_printed__c, 'Certificate Be Printed should be false');
    }

    @isTest
    // Test Course Type Incomplete Status
    static void testCourseTypeIncompleteStatus() {
        // Given: Create a new Application_Course_Preference record
        Application_Course_Preference__c ACP = [SELECT Id FROM Application_Course_Preference__c ORDER BY createddate DESC LIMIT 1];
        ACP.Course_Result__c = 'Incomplete';
        
        // When: Update Application_Course_Preference record
        Test.startTest();
        update ACP;
        Test.stopTest();
        
        // Then: Verify results
        Application_Course_Preference__c insertedACP = [
            SELECT Id, Certificate_to_be_printed__c
            FROM Application_Course_Preference__c 
            WHERE Id = :ACP.Id
            LIMIT 1
        ];
        
        Assert.isNull(insertedACP.Certificate_to_be_printed__c, 'Certificate Be Printed should be null');
    }
}