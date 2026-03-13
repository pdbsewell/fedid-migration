/**
 * @description Unit tests for GradsUtils
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GradsUtils_Test {

    @IsTest
    static void testConfig() {
        // GIVEN - Mocked system settings
        GradsUtils.JournalConfig jc = new GradsUtils.JournalConfig();
        jc.scheduledBatchEnabled = true;
        jc.accounts = new Map<String,String>{
            'FEES_GRADUATION' => '159',
            'FEES_LATE' => '160'
        };
        jc.aggregateAccount = '161';

        GradsUtils.SyncConfig sc = new GradsUtils.SyncConfig();
        sc.namedCredential = 'MyNamedCredential';
        sc.triggerEnabled = true;
        sc.asyncProcessEnabled = false;

        GradsUtils.Prices prices = new GradsUtils.Prices();
        prices.attendanceAustralia = 100.0;
        prices.attendanceInternational = 200.0;
        GradsUtils.AppConfig ac = new GradsUtils.AppConfig();
        ac.prices = prices;

        SystemSettingsUtil.getInstance().genSystemSettings.putAll(new Map<String, System_Settings__mdt>{
            GradsUtils.JOURNAL_CONF_NAME => new System_Settings__mdt(QualifiedApiName = GradsUtils.JOURNAL_CONF_NAME, Value__c = JSON.serialize(jc)),
            GradsUtils.SYNC_CONF_NAME => new System_Settings__mdt(QualifiedApiName = GradsUtils.SYNC_CONF_NAME, Value__c = JSON.serialize(sc)),
            GradsUtils.APP_CONF_NAME => new System_Settings__mdt(QualifiedApiName = GradsUtils.APP_CONF_NAME, Value__c = JSON.serialize(ac))
        });

        // WHEN - The system settings are retrieved
        GradsUtils.JournalConfig resultJc = GradsUtils.getJournalConfig();
        GradsUtils.SyncConfig resultSc = GradsUtils.getSyncConfig();
        GradsUtils.AppConfig resultAc = GradsUtils.getAppConfig();

        // THEN - The expected values should be returned
        Assert.areEqual(jc.scheduledBatchEnabled, resultJc.scheduledBatchEnabled);
        Assert.areEqual(jc.accounts, resultJc.accounts);
        Assert.areEqual(jc.aggregateAccount, resultJc.aggregateAccount);

        Assert.areEqual(sc.namedCredential, resultSc.namedCredential);
        Assert.areEqual(sc.triggerEnabled, resultSc.triggerEnabled);
        Assert.areEqual(sc.asyncProcessEnabled, resultSc.asyncProcessEnabled);

        Assert.areEqual(prices.attendanceAustralia, resultAc.prices.attendanceAustralia);
        Assert.areEqual(prices.attendanceInternational, resultAc.prices.attendanceInternational);
    }

    @IsTest
    static void testMappings() {
        // GIVEN an award type WHEN it's looked up THEN it should map to the correct value
        Assert.areEqual('Combined', GradsUtils.getCrmAwardType('COMBINED'));
        Assert.areEqual('ALTERNATIVE EXITS', GradsUtils.getCallistaAwardType('Alternative Exit'));
    }

    /**
     * Test various small methods, combined to avoid unnecessary testing time
     */
    @IsTest
    static void testMisc() {
        // GIVEN - Code running in a Integration user context
        User integrationUser = [SELECT Id FROM User WHERE Profile.Name = 'Integration - Monash Forms'];
        System.runAs(integrationUser) {
            // WHEN - The user is checked for being a portal user
            // THEN - The user should be identified as a portal user
            Assert.areEqual(true, GradsUtils.isPortalUser());
        }
        // GIVEN - Code running in a non-portal user context
        GradsUtils.isPortalUser = null; // Reset the static variable to ensure a fresh check
        // WHEN - The user is checked for being a portal user
        // THEN - The user should not be identified as a portal user
        Assert.areEqual(false, GradsUtils.isPortalUser());

        // GIVEN - A Graduation Award with a specific integration ID
        // WHEN - The integration ID is generated
        String uniqueKey = GradsUtils.createApplicationUniqueKey('123', '456');
        // THEN - The integration ID should match the expected format
        Assert.areEqual('123|456', uniqueKey);

        // GIVEN - A Graduation Award with a specific integration ID
        Graduation_Award__c award = new Graduation_Award__c(
            Course_Code__c = 'ABC123',
            Award_Course_Code__c = 'XYZ456',
            Award_Code_1__c = 'AWD789',
            Award_Code_2__c = 'AWD101'
        );

        // WHEN - The integration ID is generated
        Id appId = fflib_IDGenerator.generate(Graduation_Application__c.SObjectType);
        String integrationId = GradsUtils.createAwardIntegrationId(award, appId);

        // THEN - The integration ID should match the expected format
        String expectedIntegrationId = appId + '|ABC123|XYZ456|AWD789-AWD101';
        Assert.areEqual(expectedIntegrationId, integrationId);
    }
}