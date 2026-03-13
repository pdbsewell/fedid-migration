/**
 * @description       : Test class for Assignment: AI : Ascend Update Prospect Status Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 12-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class AssignmentAIascendUpdateStatus_FT {
    @isTest
    static void testAssignmentAIascendUpdateStatus() {
        // Given: Create a contact & Assignment
        ucinn_ascendv2__Assignment__c assignment = new ucinn_ascendv2__Assignment__c();

        TriggerCommon.disableTrigger('Contact');
        Contact contact = new Contact(FirstName = 'Test', LastName = '123134124');
        insert contact;
        Contact relationshipManager = new Contact(FirstName = 'Test', LastName = '123923124');
        insert relationshipManager;
        TriggerCommon.enableTrigger('Contact');

        assignment.ucinn_ascendv2__Assignment_Start_Date__c = System.now().date();
        RecordType assignmentRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Contact_Assignment' LIMIT 1];
        assignment.RecordTypeId = assignmentRT.Id;
        assignment.ucinn_ascendv2__Assignment_Type__c = 'Primary Relationship Manager - Development';
        assignment.ucinn_ascendv2__Contact__c = contact.Id;
        assignment.ucinn_ascendv2__Assigned_Relationship_Mngr_Contact__c = relationshipManager.Id;
        
        // When: Insert Assignment
        test.startTest();
        insert assignment;
        test.stopTest();

        // Then: Validate Assignment Start Date
        assignment = [SELECT Id, ucinn_ascendv2__Contact__r.ucinn_ascendv2__Stage_of_Readiness__c FROM ucinn_ascendv2__Assignment__c WHERE Id = :assignment.Id];
        Assert.areEqual('Assigned', assignment.ucinn_ascendv2__Contact__r.ucinn_ascendv2__Stage_of_Readiness__c, 'Assignment Stage of Readiness not updated');
    }
}