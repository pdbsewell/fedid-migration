/**
 * @description     :   Test class for Configuration Rule : AI : Update Fields flow
 * @author          :   Sachin Shetty
 * @date            :   22-05-2025
 * @group           :   Platforms
 * @revision
 *  22-05-2025      Sachin Shetty    - EPCP-4492  created test class to test the Configuration Rule : AI : Update Fields Flow
 */ 
@isTest (isParallel = true)
public class ConfigurationAttributeAIUpdateFields_FT {
	/**
     * @description test setting the external id for a product action
     */
    @isTest
    static void shouldSetExternalId() {
        // Disable Trigger
        TriggerCommon.disableTrigger('SBQQ__ConfigurationAttribute__c');

        // GIVEN
        // A test Configuration Attribute 
        SBQQ__ConfigurationAttribute__c testConfigurationAttribute = new SBQQ__ConfigurationAttribute__c(Name = 'Test Config Attribute');

        // WHEN
        // A Configuration Attribute is created
        Test.startTest();
            insert testConfigurationAttribute;
        Test.stopTest();

        // THEN
        // Verify that the Configuration Attribute's external id is set
        List<SBQQ__ConfigurationAttribute__c> updatedConfigurationRules = [SELECT Id, External_Id__c FROM SBQQ__ConfigurationAttribute__c WHERE Id = :testConfigurationAttribute.Id];
        Assert.areEqual(((Id) UserInfo.getOrganizationId()).to15() + '_' + testConfigurationAttribute.Id, updatedConfigurationRules[0].External_Id__c, 'External Id not set');

        // Enable Trigger
        TriggerCommon.enableTrigger('SBQQ__ConfigurationAttribute__c');
    }
}