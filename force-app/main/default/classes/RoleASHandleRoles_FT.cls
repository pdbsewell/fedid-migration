/**
 * @description : Test class for Role_AS_Handle_Roles Flow
 * @author      : Vinothraja
 * @date        : 02-06-2025
 * @group       : Platforms
 * @revision    :
 *  02-06-2025      Vinothraja    - EPCP-4552  created test class to test the Role : AS : Handle Roles Flow
 */
@isTest(isParallel = true)
public with sharing class RoleASHandleRoles_FT {
    @TestSetup
    static void makeData(){
        // Disable Trigger
        TriggerCommon.disableTrigger('Account');
        TriggerCommon.disableTrigger('Contact');

        Account account = new Account(Name = 'Acc');
        insert account;
        Contact contact = new Contact(lastname = 'Cnt09876', Accountid = account.id);
        insert contact;

        Agent_Onboarding_Settings__c cs = new Agent_Onboarding_Settings__c();
        cs.Role_RT_Developer_Name__c = 'Agency_Contact_Role';
        insert cs;
        
        // Enable Trigger
        TriggerCommon.enableTrigger('Account');
        TriggerCommon.enableTrigger('Contact');
    }
    /*
    * Test method to verify if the Principal Agent is populated correctly
    */
    @isTest
    private static void shouldSetPrincipalAgent() {
        // GIVEN
        // A Valid Account and Contact
        Contact agencyContact = [SELECT id, AccountId FROM Contact WHERE lastname = 'Cnt09876' LIMIT 1];

        // WHEN
        // A Role record is created
        RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType='Roles__c' AND Name = 'Agency Contact Role' LIMIT 1];

        Roles__c role = new Roles__c(Contact__c = agencyContact.id, 
                                    Account__c = agencyContact.accountId, 
                                    RecordTypeId = rt.Id,
                                    Role__c = 'Principal Agent');
        Test.startTest();
            insert role;
        Test.stopTest();
        
        // THEN
        // Verify whether Principal Agent field in Account is populated
        Account account = [ SELECT id, Principal_Agent__c FROM Account WHERE id = :agencyContact.accountId LIMIT 1];
        Assert.areEqual(agencyContact.id, account.Principal_Agent__c, 'Principal Agent not populated in Account');
    }
    /*
    * Test method to verify if the Branch Manager is populated correctly
    */
    @isTest
    private static void shouldSetBranchManager() {        // GIVEN
        // A Valid Account and Contact
        Contact agencyContact = [SELECT id, AccountId FROM Contact WHERE lastname = 'Cnt09876' LIMIT 1];

        // WHEN
        // A Role record is created
        RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType='Roles__c' AND Name = 'Agency Contact Role' LIMIT 1];

        Roles__c role = new Roles__c(Contact__c = agencyContact.id, 
                                    Account__c = agencyContact.AccountId, 
                                    RecordTypeId = rt.Id,
                                    Role__c = 'Branch Manager');
        Test.startTest();
            insert role;
        Test.stopTest();

        // THEN
        // Verify whether Branch Manager field in Account is populated
        Account account = [ SELECT id, Branch_Manager__c FROM Account WHERE id = :agencyContact.accountId LIMIT 1];
        Assert.areEqual(agencyContact.id, account.Branch_Manager__c, 'Branch Manager not populated in Account');
    }
}