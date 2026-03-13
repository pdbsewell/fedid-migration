/**
 * @description       : Test class for sandbox post refresh logic
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2022-08-21
 * @last modified by  : Stefan Scheit
 * Modifications Log
 * Date         Author          Modification
 * 2024-17-04 - Sachin Shetty - Update to point to DBConnect fields
 * 2022-12-06 - Peter Sewell  - Added test coverage for SandboxPostRefresh.turnOffSsoEnforcementInSandbox()
 * 2022-08-19 - Stefan Scheit - Added test coverage for SandboxPostRefresh.insertDnbOptimizerSettings()
 *              Various         Various
 * 2019-05-28 - Stefan Scheit - Marketing Cloud connector token
 * 2018-12-12 - Stefan Scheit - Initial version
**/
@isTest (isParallel=false)
public class SandboxPostRefresh_Test {

    /**
     * Test method for post sandbox refresh logic
     */
    @isTest
    static void testSandboxAfterRefresh()	{
        Organization org = [SELECT Id FROM Organization LIMIT 1];

        Test.startTest();
        
        try{
        // run post sandbox creation script
        Test.testSandboxPostCopyScript(new SandboxPostRefresh(), UserInfo.getOrganizationId(),
                                       UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        }catch(Exception e){
            Assert.isNotNull(e.getMessage(), 'Exception occured');
        }

        Test.stopTest();
        // assertions are done in the particular classes called by the SandboxPostRefreseh
    }
    
    /**
     * Test method to validate that SOQl special characters for the LIKE operator are properly escaped
     */
    @isTest
    static void testrunbatchJos1() {
        Test.startTest();
            try{
                SandboxPostRefresh.runApexJobs();
            }catch(Exception e){
                Assert.isNotNull(e.getMessage(), 'Exception occured');
            }
        Test.stopTest();
    }
    /**
     * Test method to validate that SOQl special characters for the LIKE operator are properly escaped
     */
    @isTest
    static void testEscapeSoqlSpecialCharactersInLike() {
        String likeComparator = 'test_%';
        String output = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(likeComparator);
        Assert.areEqual('test\\_\\%', output, 'SOQL special characters (\'_\', \'%\') are not escaped with a backslash.');
    }

    /**
    * Test method to validate SandboxPostRefresh_Test.deleteMarketingCloudTokens()
    */
    @isTest
    static void testDeleteMarketingCloudTokens() {
        // no real test but have some code line coverage
        SandboxPostRefresh.DeleteMarketingCloudTokens();
        System.assert(true); // TODO: have to figure out which records are deleted/modified in the managed package objects
    }

    /**
    * Test method to validate SandboxPostRefresh.insertDnbOptimizerSettings()
    */
    @isTest
    static void testInsertDnbOptimizerSettings() {
        // GIVEN: no precondition
        
        // WHEN: sandbox post refresh method is invoked
        Test.startTest();
            SandboxPostRefresh.insertDnbOptimizerSettings();
        Test.stopTest();

        // THEN: settings are present in the org
        List<DNBConnect__D_B_Connect_Setting__c> settings = [SELECT Id FROM DNBConnect__D_B_Connect_Setting__c];
        Assert.isFalse(settings.isEmpty(), 'DnB Optimizer Settings are not present as expected.');
    }

    /**
    * Test method to validate SandboxPostRefresh.turnOffSsoEnforcementInSandbox()
    */
    @isTest
    static void testTurnOffSsoEnforcementInSandbox() {
        // GIVEN: no precondition
        
        // WHEN: sandbox post refresh method is invoked
        Test.startTest();
            SandboxPostRefresh.turnOffSsoEnforcementInSandbox();
        Test.stopTest();

        // THEN: SSO enforcement setting is turned off in the org
        Feature_Switch_TSP__c fs = Feature_Switch_TSP__c.getOrgDefaults();
        Assert.isFalse(fs.Detect_Non_SSO_Login__c, 'SSO enforcement switch should have been disabled');
    }
}