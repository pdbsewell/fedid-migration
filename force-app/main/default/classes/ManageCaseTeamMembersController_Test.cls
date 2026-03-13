/*
 * @author	ayush.agrawal@monash.edu
 * @group	Student Admin - Academic Progress
 */

@isTest
public class ManageCaseTeamMembersController_Test {
	@testSetup
    static void setup() {
        // Contact.
        List<Contact> contacts = new List<Contact>();
        Contact contact_1 = new Contact(
            Person_ID_Unique__c = '10000001',
            LastName = 'LastName'
        );
        contacts.add(contact_1);
        
        Contact contact_2 = new Contact(
            SAP_Staff_ID__c = '10000002',
            LastName = 'LastName'
        );
        contacts.add(contact_2);
        
        insert contacts;
        
        // Campaign.
        Campaign campaign_1 = new Campaign(
            Name = 'AP - 2021 - First - Final',
            EndDate = Date.today() + 15,
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId()
        );
        insert campaign_1;
        
        // Case.
        Case case_1 = new Case(
            Campaign__c = campaign_1.Id,
            Category_Level_1__c = '1-3',
            ContactId = contact_1.Id,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Academic_Progress_Assessment').getRecordTypeId()
        );
        insert case_1;
    }
	
    @isTest
    static void testManageCaseTeamMembers() {
        List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
        
        Case c = [SELECT Id FROM Case LIMIT 1];
        
        // Add.
        ManageCaseTeamMembersController.execute(c.Id, 'Add', new List<String>{}, new List<String>{'10000002'});
        
        caseTeamMembers = [SELECT Id FROM CaseTeamMember WHERE ParentId = :c.Id];

        System.assertEquals(1, caseTeamMembers.size(), 'Manage Case Team Members functionality is not working.');
        
        // Remove.
        ManageCaseTeamMembersController.execute(c.Id, 'Remove', new List<String>{}, new List<String>{'10000002'});
        
        caseTeamMembers = [SELECT Id FROM CaseTeamMember WHERE ParentId = :c.Id];

        System.assertEquals(0, caseTeamMembers.size(), 'Manage Case Team Members functionality is not working.');
        
        // Add Bulk.
        ManageCaseTeamMembersController.execute('', 'Add', new List<String>{'10000001'}, new List<String>{'10000001','10000002'});
        
        caseTeamMembers = [SELECT Id FROM CaseTeamMember WHERE ParentId = :c.Id];

        System.assertEquals(2, caseTeamMembers.size(), 'Manage Case Team Members functionality is not working.');
        
        // Remove Bulk.
        ManageCaseTeamMembersController.execute('', 'Remove', new List<String>{'10000001'}, new List<String>{'10000001','10000002'});
        
        caseTeamMembers = [SELECT Id FROM CaseTeamMember WHERE ParentId = :c.Id];

        System.assertEquals(0, caseTeamMembers.size(), 'Manage Case Team Members functionality is not working.');
    }

}