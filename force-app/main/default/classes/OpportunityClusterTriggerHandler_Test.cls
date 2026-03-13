@isTest//(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests 
public with sharing class OpportunityClusterTriggerHandler_Test {
    /**
	 * SyncPureIdWithOpportunity Test Method to check Opportunity Cluster Sync
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync Pure Id with Opportunities.
	*******************************************************************************/
	@isTest
        private static void testSyncPureIdWithOpportunity() {

        Opportunity_Cluster__c cluster = new Opportunity_Cluster__c (Name = 'Opp Cluster', PURE_Application_ID__c = '123');
        insert cluster;
 		
        Account acc = new Account(	Name = 'testCreateExternalAccount',
                                 	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        
        insert acc;
        Opportunity opp = new Opportunity(	Name = 'testCreateEnterpriseOpportunity',
                                            AccountId = acc.Id,
                                            Opportunity_Cluster__c = cluster.Id,
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(),
                                          	StageName = 'Identify Opportunity',
                                          	CloseDate = Date.today().addDays(1));
		insert opp;

        Test.startTest();

        cluster = [SELECT Id,PURE_Application_ID__c FROM Opportunity_Cluster__c WHERE Name = 'Opp Cluster'];
        cluster.PURE_Application_ID__c = '1234';
        cluster.PURE_Award_ID__c = '5678';
        update cluster;
        
        opp = [SELECT Id, PURE_Award_ID__c, PURE_Application_ID__c, AccountId FROM OPPORTUNITY LIMIT 1];
        System.assertEquals('1234',opp.PURE_Application_ID__c);

        Test.StopTest();
    }
}