/**
 * @description       : Test class for Lead : AI : Lead Management
 * @author            : rajesh.punjabi@monash.edu
 * @group             : 
 * @last modified on  : 07-05-2025
 * @last modified by  : rajesh.punjabi@monash.edu
**/
@isTest(isParallel=true)
public with sharing class LeadAILeadManagement_FT {
    @isTest
    static void updateCompanyName() {
        // GIVEN : Create a new Lead
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Company',
            Status = 'Open',
            LeadSource = 'Web - SR Event'
        );

        // WHEN : Update the Lead Source
        Test.startTest();
        insert lead;
        Test.stopTest();
        
        // THEN: Lead updated to Student
        // Verify the Company Name was updated
        Lead updatedLead = [SELECT Id, Company FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual('Student', updatedLead.Company);
    }
}