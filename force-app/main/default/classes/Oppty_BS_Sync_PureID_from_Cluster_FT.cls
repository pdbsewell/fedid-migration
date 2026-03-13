/* Test class for Opportunity : BS : Handle Opportunity Updates Flow 
* @author   :   Vinothraja
* @date     :   17/07/2025
* @group    :   Platforms
* @description This class is used to test the Oppty_BS_Handle_Oppty_Updates_FT class
* @revision
*  17-07-2025      Vinothraja    - Initial creation
*/
@isTest(isParallel = false) // Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class Oppty_BS_Sync_PureID_from_Cluster_FT {
    @TestSetup
    static void makeData() {
        TriggerCommon.disableTrigger('Account');    
        // A valid Opportunity Cluster with Pure IDs 
        Opportunity_Cluster__c cluster = (Opportunity_Cluster__c)TestDataFactory.createSObject(
                                                new Opportunity_Cluster__c(
                                                    Name = 'Opp Cluster', 
                                                    PURE_Application_ID__c = '123',
                                                    PURE_Award_ID__c = '456')
                                                , true);

        Account acc = (Account)TestDataFactory.createSObject(
                            new Account(
                                Name = 'testCreateExternalAccount',
                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId()
                            ), true);

        TriggerCommon.enableTrigger('Account');
    }
    // Test method to verify the flow handles opportunity creation correctly
    @isTest
    private static void testSyncPureIdWithOpportunityCreates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        Opportunity_Cluster__c cluster = [SELECT Id, PURE_Application_ID__c, PURE_Award_ID__c FROM Opportunity_Cluster__c WHERE Name = 'Opp Cluster' LIMIT 1];

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                Opportunity_Cluster__c = cluster.Id,
                                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(),
                                StageName = 'Identify Opportunity',
                                Source__c = null,
                                CloseDate = Date.today().addDays(1)
                            ), false);

        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            insert opp;
        Test.stopTest();
            
        // THEN
        // Verify that the Opportunity's Pure IDs are synced correctly
        opp = [SELECT PURE_Award_ID__c, PURE_Application_ID__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(cluster.PURE_Application_ID__c, opp.PURE_Application_ID__c, 'Opportunity should have the cluster\'s PURE Application ID');
        Assert.areEqual(cluster.PURE_Award_ID__c, opp.PURE_Award_ID__c, 'Opportunity should have the cluster\'s PURE Award ID');
    }
    // Test method to verify the flow handles opportunity updates correctly
    @isTest
    private static void testSyncPureIdWithOpportunityUpdates() {
        // GIVEN
        Account acc = [SELECT Id FROM Account WHERE Name = 'testCreateExternalAccount' LIMIT 1];
        Opportunity_Cluster__c cluster = [SELECT Id, PURE_Application_ID__c, PURE_Award_ID__c FROM Opportunity_Cluster__c WHERE Name = 'Opp Cluster' LIMIT 1];

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(
                            new Opportunity(
                                Name = 'testCreateEnterpriseOpportunity',
                                AccountId = acc.Id,
                                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId(),
                                StageName = 'Identify Opportunity',
                                CloseDate = Date.today().addDays(1)
                            ), true);
        // Verify that the opportunity's PURE Ids are blank before update -- NEGATIVE TEST
        opp = [SELECT PURE_Award_ID__c, PURE_Application_ID__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isNull(opp.PURE_Award_ID__c, 'Opportunity\'s PURE Application ID should be blank before update');
        Assert.isNull(opp.PURE_Application_ID__c, 'Opportunity\'s PURE Award ID should be blank before update');

        // WHEN
        // Insert the opportunity to trigger the flow
        Test.startTest();
            opp.Opportunity_Cluster__c = cluster.Id;
            opp.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Enterprise' LIMIT 1].Id; // Change record type to trigger update logic
            opp.Source__c = null;
            update opp;
        Test.stopTest();
            
        // THEN
        // Verify that the Opportunity's Pure IDs are synced correctly
        opp = [SELECT PURE_Award_ID__c, PURE_Application_ID__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(cluster.PURE_Application_ID__c, opp.PURE_Application_ID__c, 'Opportunity should have the cluster\'s PURE Application ID');
        Assert.areEqual(cluster.PURE_Award_ID__c, opp.PURE_Award_ID__c, 'Opportunity should have the cluster\'s PURE Award ID');
    }
}