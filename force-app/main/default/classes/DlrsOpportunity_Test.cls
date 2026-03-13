/**
 * @description       : Test class to validate the rollup definitions defined for DLRS (declrarative lookup rollup summaries)
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2020-12-22
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.2   2023-10-01   Davey Yu        ENGAGEIE-1784 replace picklist value signed all with fully signed
 * 1.1   2020-10-01   Stefan Scheit   Added generated test (from DLRS tool), but had to comment it out.
 * 1.0   2020-09-17   Stefan Scheit   Initial Version
**/
@isTest(isParallel=false) // Tests on Opportunity leverage Test.getStandardPricebookId() which cannot be called from parallel Apex tests
public class DlrsOpportunity_Test {

    /**
     * Auto Generated and copied from the Declarative Lookup Rollup Summaries Tool package (dlrs)
     * DISABLED DUE TO Engage Alumni validation rule: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, A proposal must be associated with an organization or a constituent.: []
    
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_OpportunityTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Opportunity());
    }
	**/

    @isTest
    public static void testRollups() {
        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Enterprise' LIMIT 1][0];
        
        // GIVEN: Oppty Cluster is defined
        Opportunity_Cluster__c opptyGroup = new Opportunity_Cluster__c();
        opptyGroup.Name = 'OpptyGroup';
        insert opptyGroup;
        
        // GIVEN: 3 different account (for external organisations) are in place
        Account acct1 = new Account(Name='Acct1');
        Account acct2 = new Account(Name='Acct2');
        Account acct3 = new Account(Name='Acct3');
		Database.insert(new List<Account> {acct1, acct2, acct3});        
        
        // GIVEN: An open oppties are associated to it
        Opportunity oppty1 = new Opportunity();
        oppty1.AccountId = acct1.Id;
        oppty1.RecordTypeId = recType.Id;
        oppty1.Name = 'Oppty1';
        oppty1.Amount = 1.00;
        oppty1.CloseDate = Date.today()+1;
        oppty1.StageName = 'Open';
        oppty1.Opportunity_Cluster__c = opptyGroup.Id;
        
        // GIVEN: A closed/won oppty is associated
        Opportunity oppty2 = new Opportunity();
        oppty2.AccountId = acct2.Id;
        oppty2.RecordTypeId = recType.Id;
        oppty2.Name = 'Oppty2';
        oppty2.Amount = 2.00;
        oppty2.CloseDate = Date.today()+2;
        oppty2.StageName = 'Closed Won';
        //ENGAGEIE-1784 replaced signed all values with fully signed
        oppty2.Contract_Status__c = 'Fully Signed'; // required for closed won
        oppty2.Opportunity_Cluster__c = opptyGroup.Id;
        
        // GIVEN: A closed/lost oppty is associated
        Opportunity oppty3 = new Opportunity();
        oppty3.AccountId = acct3.Id;
        oppty3.RecordTypeId = recType.Id;
        oppty3.Name = 'Oppty1';
        oppty3.Amount = 4.00;
        oppty3.CloseDate = Date.today()+4;
        oppty3.StageName = 'Closed Lost';
        //ENGAGEIE-1549 udpate to new closed reason values
        oppty3.Closed_Reason__c = 'Other'; // required for closed lost
        oppty3.Closed_Reason_Details__c = 'My details'; // required for closed lost
        oppty3.Opportunity_Cluster__c = opptyGroup.Id;
        
        // WHEN: Opportunities are created/inserted against the oppty cluster/group. This will trigger rollup summaries.
        Database.insert(new List<Opportunity> {oppty1, oppty2, oppty3});
        
        // THEN: Rollups (via the lookup relationship) were calculated
        opptyGroup = [SELECT Id, Count_of_Opportunities__c, Lost_Opportunities__c, Open_Opportunities__c, Total_Opportunity_Amount__c, Won_Amount__c, Won_Opportunities__c FROM Opportunity_Cluster__c WHERE Id = :opptyGroup.Id];
        System.debug(opptyGroup);
        System.assertEquals(3, opptyGroup.Count_of_Opportunities__c, 'Enterprise Count of Opps rollup is not executed as expected.'); //Enterprise Count of Opps
        System.assertEquals(1, opptyGroup.Lost_Opportunities__c, 'Enterprise Lost Opps rollup is not executed as expected.'); //Enterprise Lost Opps
        System.assertEquals(1, opptyGroup.Open_Opportunities__c, 'Enterprise Open Opps (not closed) rollup is not executed as expected.'); //Enterprise Open Opps (not closed)
        System.assertEquals(oppty1.Amount + oppty2.Amount + oppty3.Amount, opptyGroup.Total_Opportunity_Amount__c, 'Enterprise Total Cluster Amount rollup is not executed as expected.'); //Enterprise Total Cluster Amount
        System.assertEquals(oppty2.Amount, opptyGroup.Won_Amount__c, 'Enterprise Won Amount rollup is not executed as expected.'); //Enterprise Won Amount
        System.assertEquals(1, opptyGroup.Won_Opportunities__c, 'Enterprise Won Opps rollup is not executed as expected.'); //Enterprise Won Opps
    }
}