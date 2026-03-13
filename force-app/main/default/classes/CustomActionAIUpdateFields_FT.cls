/**
 * @description     :   Test class for Custom Action : AI : Update Fields flow
 * @author          :   Sachin Shetty
 * @date            :   23-05-2025
 * @group           :   Platforms
 * @revision
 *  23-05-2025      Sachin Shetty    - EPCP-4518  created test class to test the Custom Action : AI : Update Fields Flow
 */ 
@isTest (isParallel = true)
public class CustomActionAIUpdateFields_FT {
	/**
     * @description test setting the external id for a Custom Action Condition
     */
    @isTest
    static void shouldSetExternalId() {
        // GIVEN
        // A test Custom Action 
        SBQQ__CustomAction__c testCustomAction = new SBQQ__CustomAction__c(Name = 'Test Custom Action',
        													SBQQ__DisplayOrder__c = 1);   

        // WHEN
        // A Custom Action is created
        Test.startTest();
            insert testCustomAction;
        Test.stopTest();

        // THEN
        // Verify that the Custom Action's external id is set
        List<SBQQ__CustomAction__c> updatedCustomActions = [SELECT Id, External_Id__c FROM SBQQ__CustomAction__c WHERE Id = :testCustomAction.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testCustomAction.Id, updatedCustomActions.get(0).External_Id__c, 'External Id not set');
    }
}