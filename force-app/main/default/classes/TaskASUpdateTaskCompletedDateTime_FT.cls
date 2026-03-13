/**
 * @description       : Test class for Task: AS : Update Task Completed DateTime Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 24-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class TaskASUpdateTaskCompletedDateTime_FT {
    private static User testUser;
    private static RecordType engageRecordType;
    
    @testSetup
    // Setup test data
    static void setupTestData() {
        // Create test user
        testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        // Get Engage record type
        engageRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Engage' LIMIT 1];
    }
    
    // Create test task
    private static Task createTestTask(String status) {
        setupTestData();
        Task t = (Task)MonConTestDataFactory.createSObject(new Task(), false);
        t.RecordTypeId = engageRecordType.Id;
        t.OwnerId = testUser.Id;
        t.Status = status;
        return t;
    }
    
    @isTest
    // Test Inserting Task to check Time/Date field is updated
    static void testInsertTaskCompletedDateTime() {
        // Given: Create a task
        Task t = createTestTask('Completed');
    
        // When: Insert task
        test.startTest();
        insert t;
        test.stopTest();

        // Then: Validate task completed date time
        t = [SELECT Id, Completed_Date_Time__c FROM Task WHERE Id = :t.Id];
        Assert.isNotNull(t.Completed_Date_Time__c, 'Task completed date time not set');
    }

    @isTest
    // Test Updating Task to check Time/Date field is updated
    static void testUpdateTaskCompletedDateTime() {
        // Given: Create a task
        Task t = createTestTask('In Progress');
        insert t;
    
        // When: Update task
        test.startTest();
        t.Status = 'Completed';
        update t;
        test.stopTest();

        // Then: Validate task completed date time
        t = [SELECT Id, Completed_Date_Time__c FROM Task WHERE Id = :t.Id];
        Assert.isNotNull(t.Completed_Date_Time__c, 'Task completed date time not set');
    }
}