/**
 * @description       : Test class for CopadoJiraSync
 * @author            : Sachin Shetty
 * @group             : Test Class
 * @last modified on  : 2023-10-31
 * @last modified by  : Sachin Shetty
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2023-10-31 - Sachin Shetty - Initial Version
**/
@isTest//(IsParallel=true) In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public class CopadoJiraSync_Test {
    
	@testSetup static void dataSetup() {
        copadoccmint__Copado_Integration_Setting__c integrationSetting= new copadoccmint__Copado_Integration_Setting__c(
            Name = 'Test Integration',
            copadoccmint__External_System__c = 'JIRA', 
            copadoccmint__Named_Credential__c = 'Test Named Credential'
        );
        insert integrationSetting;
        
        copado__Project__c testProject = new copado__Project__c(
            copado__API_Name__c = 'Test Project',
        	copadoccmint__Copado_Integration_Setting__c = integrationSetting.Id
        );
        insert testProject;
    }

    @isTest
    public static void SyncJiraStories_Test() {
        // Given : Test project record
        CopadoJiraSync.ProjectRecord projRecord = new CopadoJiraSync.ProjectRecord();
        projRecord.recordId = [SELECT Id FROM copado__Project__c WHERE copado__API_Name__c = 'Test Project' LIMIT 1].Id;
        
        Test.startTest();
        	// When
        	List<String> resultIds = CopadoJiraSync.SyncJiraStories(new List<CopadoJiraSync.ProjectRecord>{projRecord});
        Test.stopTest();
        
        // Then
        Assert.areEqual('Test Message', resultIds.get(0)); 
    }
}