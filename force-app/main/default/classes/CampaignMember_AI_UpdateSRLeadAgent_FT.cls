/**
 * @description     :   Test class for Campaign Member : AI : Update SR Lead Agent Info flow
 * @author          :   Vinothraja
 * @date            :   30-06-2025
 * @group           :   Platforms
 * @revision
 *  30-06-2025      Vinothraja    - EPCP-4485  created 
 */ 
@isTest(isParallel=true)
public with sharing class CampaignMember_AI_UpdateSRLeadAgent_FT {
    /* Test Setup Method */
    @TestSetup
    static void makeData(){
        TriggerCommon.disableTrigger('Campaign');
        // Create a Campaign with required fields
        Campaign camp = TestHelper.createCampaign(1)[0];
        camp.Name = 'Test Campaign for AI Update SR Lead Agent';
        camp.StartDate = Date.today();
        camp.Status = 'Approved';
        camp.Agent_Other__c = 'Random Agent';                    
        insert camp;
        TriggerCommon.enableTrigger('Campaign');
    }
    /**
     * @description     :   Test method to verify that the Owning Agent is populated correctly on the Lead record when a Campaign Member is created.
     * @author          :   Vinothraja
     * @date            :   30-06-2025
     * @group           :   Platforms
     * @revision
     *  30-06-2025      Vinothraja    - EPCP-4485  created 
     */
    @isTest
    static void testCampaignMemberAIUpdateSRLeadAgent() {
        // GIVEN
        // A valid campaign record
        Campaign camp = [SELECT Id, Agent_Other__c FROM Campaign WHERE Name = 'Test Campaign for AI Update SR Lead Agent' LIMIT 1];
        // A valid Campaign Member record
        // Create a Campaign Member for the Campaign
        String leadID = TestDataFactory.createSObject(new Lead(LastName = 'Random Lead001898', Company = 'Random Campany 0098766'), true).Id; // Create a Lead and use its Id
        CampaignMember cm = new CampaignMember(
            CampaignId = camp.Id,
            LeadId = leadID
        );
        // WHEN
        // Campaign is created 
        Test.startTest();
            insert cm;
        Test.stopTest();
        
        // THEN
        // Owning Agent is filled
        Lead ld = [SELECT Owning_Agent__c FROM Lead WHERE id = :leadID LIMIT 1];
        Assert.areEqual(camp.Agent_Other__c, ld.Owning_Agent__c, 'Owning_Agent__c is not populated correctly on the related Lead record.');
    }
    /**
     * @description     :   Negative Test method to verify that the Owning Agent is not populated on the Lead record when a Campaign doesn't have Agent_Other__c field populated.
     * This test ensures that the Owning Agent is only updated when the Campaign has a valid Agent_Other__c value.
     * @author          :   Vinothraja
     * @date            :   30-06-2025
     * @group           :   Platforms
     * @revision
     *  30-06-2025      Vinothraja    - EPCP-4485  created 
     */
    @isTest
    static void testCampaignMemberAIUpdateSRLeadAgent_negative() {
        TriggerCommon.disableTrigger('Campaign');
        // GIVEN
        // A valid campaign record
        Campaign camp = [SELECT Id, Agent_Other__c FROM Campaign WHERE Name = 'Test Campaign for AI Update SR Lead Agent' LIMIT 1];
        camp.Agent_Other__c = null; // Set Agent_Other__c to null to simulate the negative case
        update camp; 
        TriggerCommon.enableTrigger('Campaign');
        // A valid Campaign Member record
        // Create a Campaign Member for the Campaign
        String leadID = TestDataFactory.createSObject(new Lead(LastName = 'Random Lead001898', Company = 'Random Campany 0098766'), true).Id; // Create a Lead and use its Id
        CampaignMember cm = new CampaignMember(
            CampaignId = camp.Id,
            LeadId = leadID
        );
        // WHEN
        // Campaign is created 
        Test.startTest();
            insert cm;
        Test.stopTest();
        
        // THEN
        // Owning Agent is filled
        Lead ld = [SELECT Owning_Agent__c FROM Lead WHERE id = :leadID LIMIT 1];
        Assert.isNull(ld.Owning_Agent__c, 'Owning_Agent__c should not be populated on the related Lead record when Agent_Other__c is null.');
    }
}