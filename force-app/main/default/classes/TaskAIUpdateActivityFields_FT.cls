/**
 * @description       : Test class for Task: AI : Update Activity Fields Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 24-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class TaskAIUpdateActivityFields_FT {
    @isTest
    // Test Inserting Task to check Location and Queue are updated
    static void testUpdateActivityFields() {
        // Given: Create a task
        Task t = (Task)MonConTestDataFactory.createSObject(new Task(), false);
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Engage' LIMIT 1];
        t.RecordTypeId = rt.Id;
        
        User u = [SELECT Id, Location__c, Queue__c, User_Role_Name__c FROM User WHERE IsActive = true AND User_Role_Name__c = 'Monash Connect' LIMIT 1];
        t.OwnerId = u.Id;
    
        // When: Insert task
        test.startTest();
        System.runAs(u) {
            insert t;
        }
        test.stopTest();

        // Then: Validate Location and Queue are updated
        t = [SELECT Id, Location__c, Queue__c FROM Task WHERE Id = :t.Id];
        Assert.areEqual(t.Location__c, u.Location__c, 'Task location not set');
        Assert.areEqual(t.Queue__c, u.Queue__c, 'Task queue not set');
    }
}