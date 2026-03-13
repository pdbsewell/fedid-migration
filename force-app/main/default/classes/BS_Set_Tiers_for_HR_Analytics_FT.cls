/**
* @author Ven Vairavan
* @date 02/05/2025
* @group Test Class for BS_Set_Tiers_for_HR_Analytics flow
* @description  Test Class to test the functionality of Case_BS_Set_Tiers_for_HR_Enquiry Flow
* @history    Initial Creation
*
**/
@isTest // (isParallel=true) not set due to APEX_DATA_ACCESS_RESTRICTION operations not permitted User
public class BS_Set_Tiers_for_HR_Analytics_FT {
    
    @testSetup
    static void setupTestData() {
        // Create a RecordType for HR Cases if required
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'HR' AND SObjectType = 'Case' LIMIT 1];

        // Create a test Case record
        Case testCase = new Case(
            RecordTypeId = rt.Id,
            Origin = 'hr-analytics@monash.edu',
            Subject = 'Test HR Case'
        );
        insert testCase;
    }

    @isTest
    static void testFlowExecution() {
        // Fetch the created Case
        Case testCase = [SELECT Id, Category__c, Tier_Level__c FROM Case LIMIT 1];

        // Start test execution
        Test.startTest();

        // Re-fetch the case to trigger before-save flow
        update testCase;

        Test.stopTest();

        // Fetch updated record
        Case updatedCase = [SELECT Id, Category__c, Tier_Level__c FROM Case WHERE Id = :testCase.Id];

        // Assert the flow updates the expected fields
        Assert.areEqual('HR Analytics', updatedCase.Category__c, 'Category should be updated by the flow');
        Assert.areEqual('Tier 3 - CoE', updatedCase.Tier_Level__c, 'Tier Level should be updated by the flow');
    }
}