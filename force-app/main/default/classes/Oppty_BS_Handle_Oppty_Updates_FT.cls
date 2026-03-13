/* Test class for Opportunity : BS : Handle Opportunity Updates Flow 
* @author   :   Vinothraja
* @date     :   17/07/2025
* @group    :   Platforms
* @description This class is used to test the Oppty_BS_Handle_Oppty_Updates_FT class
* @revision
*  17-07-2025      Vinothraja    - Initial creation
*/
@isTest(isParallel = false) // Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class Oppty_BS_Handle_Oppty_Updates_FT {
    @TestSetup
    static void makeData(){
		TriggerCommon.disableTrigger('Account');

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

        //Account Creation
        Account acc = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        
		TriggerCommon.enableTrigger('Account');
    }
    // Test method to verify the flow handles opportunity creation correctly
    @isTest
    static void testHandleOpportunityCreates() {
        SBQQ.TriggerControl.disable();
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Accnt 1' LIMIT 1];
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Enterprise' LIMIT 1];
        // A valid opportunity
                // Opportunity creation
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(
                AccountId = acc.Id,
                Pricebook2Id = Test.getStandardPricebookId(), 
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                recordTypeId = rt.Id,
                Source__c = 'PURE'
            ), false);


        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            insert opp;
        Test.stopTest();

        // THEN
        // Verify that the opportunity's Qualification Outcome was created successfully
        opp = [SELECT Qualification_Outcome__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Pursue', opp.Qualification_Outcome__c, 'Opportunity\'s Qualification Outcome should be "Pursue"');
    }
    // Test method to verify the flow handles opportunity updates correctly
    @isTest
    static void testHandleOpportunityUpdates() {
        SBQQ.TriggerControl.disable();
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Accnt 1' LIMIT 1];
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Applicant Enrolment' LIMIT 1];
        // A valid opportunity
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(
                AccountId = acc.Id,
                Pricebook2Id = Test.getStandardPricebookId(), 
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                recordTypeId = rt.Id,
                Source__c = 'Website'
            ),true);
        // Verify that the opportunity's Qualification Outcome is blank before update -- NEGATIVE TEST
        opp = [SELECT Source__c, Qualification_Outcome__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isNull(opp.Qualification_Outcome__c, 'Opportunity\'s Qualification Outcome should be blank before update');

        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Enterprise' LIMIT 1];
            opp.RecordTypeId = rt.Id; // Change record type to trigger update logic
            opp.Source__c = 'PURE';
            update opp;
        Test.stopTest();

        // THEN
        // Verify that the opportunity's Qualification Outcome was updated successfully
        opp = [SELECT Qualification_Outcome__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Pursue', opp.Qualification_Outcome__c, 'Opportunity\'s Qualification Outcome should be "Pursue"');
    }
}