/**
 * @description       : Sandbox post refresh logic, incl. sanitising email addresses on Contact and Channel__c records
 * @author            : Stefan Scheit
 * @group             : Utilities
 * @last modified on  : 2024-17-04
 * @last modified by  : Sachin Shetty
 * Modifications Log
 * Date         Author          Modification
 * 2024-17-04   Sachin Shetty   Update to point to DBConnect fields
 * 2023-12-06   Peter Sewell    Disable SSO enforcement feature switch in Sandboxes (SSO prod only)
 * 2022-10-18   Rajesh Punjabi  Added Profile for Monash Research Office.
 * 2022-08-19   Stefan Scheit   Added method to insert DnB Optimizer settings
 * 2021-10-10   P.Sewell        Update to support MFA enforcement in SIT and Staging
 * 2021-04-01   P.Victoriano    Fix System.UnexpectedException: No more than one executeBatch can be called from within a test method
 * 2019-07-23   P.Victoriano    Update to support Jenkins User Activation
 * 2019-05-28   Stefan Scheit   Marketing Cloud connector token, method deleteMarketingCloudTokens()
 * 2018-12-12   Stefan Scheit   Initial version
**/               
global class SandboxPostRefresh implements SandboxPostCopy {
    /**
     * Implements Interface method
     */
    global void runApexClass(SandboxContext context) {
        System.debug(LoggingLevel.DEBUG, String.valueOf(SandboxPostRefresh.class)+': Executing post sandbox refresh for sandbox with organisation id ['+context.organizationId()+'], sandbox id ['+context.sandboxId()+'], and sandbox name ['+context.sandboxName()+']');

        // Store Sandbox context in Custom Settings (should be the first thing we do in this method)
        SandboxPostRefresh.storeSandboxDetailsInSettings(context);

        // execute batch classes to sanitise email addresses
        if(!Test.isRunningTest()) {
            runApexJobs();
        }

        // remove Marketing Cloud settings/tokens
        SandboxPostRefresh.deleteMarketingCloudTokens();
        // insert DnB settings
        SandboxPostRefresh.insertDnbOptimizerSettings();
        // update CICD user
        SandboxPostRefresh.updateJenkinsCICDUser(context.sandboxName());
        // Assign MFA enforcement permission set for all in-scope sandbox users in the Org
        SandboxPostRefresh.assignMfaPermissionSet();
        // Dont enforce SSO in sandboxes
        SandboxPostRefresh.turnOffSsoEnforcementInSandbox();
    }
    /**
     * Store Sandbox context in Custom Settings
     */
    public static void storeSandboxDetailsInSettings(SandboxContext context) {
        try {
            Sandbox_Details__c setting = Sandbox_Details__c.getOrgDefaults();
            // Set sandbox name to 'SIT' if in a test so that we exercise MFA assignment logic
            setting.sandboxName__c = Test.isRunningTest() ? SecurityServices.SIT_SANDBOX_NAME : context.sandboxName();
            setting.sandboxId__c = context.sandboxId();
            setting.organizationId__c = context.organizationId();
            upsert setting;
        } catch (Exception exc) {
            Nebula.Logger.error('SandboxPostRefresh.turnOffSsoEnforcementInSandbox', exc);
            Nebula.Logger.saveLog();
        }
    }
    /**
    * @author Peter Sewell
    * @date 2021-10-11
    * @description Assign MFA enforcement permset to all in-scope users
    * @param List<Id> userIds - List of user Ids on which to run MFA perm set assignment logic, if 'null' check all users in Org
    */
    @future // Avoid mixed DML error
    public static void assignMfaPermissionSet() {
        
        try {
            // Get Id of MFA enforcement perm set 
            List<PermissionSet> permSets = new List<PermissionSet>();
            permSets = [SELECT Id FROM PermissionSet WHERE Name = :SecurityServices.MFA_ENFORCEMENT_PERM_SET LIMIT 1];
            if (permSets.size() != 1) {return ;}
            Id mfaPermSetId = permSets[0].Id;

            // Assign the MFA enforcement permission set 
            List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment> ();
            for (Id mfaUserId : SecurityServices.findUsersRequiringMfaEnforcement()) {
                PermissionSetAssignment psa = new PermissionSetAssignment() ;
                psa.AssigneeId = mfaUserId;
                psa.PermissionSetId = mfaPermSetId;
                psAssignments.add(psa);
            }
            system.debug ('SandboxPostRefresh.assignMfaPermissionSet: assigning MFA enforcement permission set to ' + psAssignments.size() + ' users') ;
            if (psAssignments.size() > 0 && !Test.isRunningTest()) {insert (psAssignments) ;}
        } catch (Exception exc) {
            system.debug ('SandboxPostRefresh.assignMfaPermissionSet: error assigning MFA enforcement permission set : ' + exc.getMessage()) ;
            Nebula.Logger.error('SandboxPostRefresh.turnOffSsoEnforcementInSandbox', exc);
            Nebula.Logger.saveLog();
        }
    }
    /**
     * @description Seperate Jobs from method invocation
     */
    public static void runApexJobs() {
        //This chained batch Jobs to prevent record Locking: ContactEmailsUpdateBatch > ChannelEmailsUpdateBatch > EmailUpdateBatch > AgencyEmailUpdateBatch
        Id jobIdContact = Database.executeBatch(new ContactEmailsUpdateBatch()); // sanitise Contact email addresses
        Id jobIdGroup = Database.executeBatch(new GroupEmailsUpdateBatch()); // sanitise Group/Queue email addresses
    }
    /**
     * Escape SOQl special characters for the LIKE operator (_, %), used by runApexClass()
     * @param inputString
     * @return outputString with escaped characters
     */
    public static String escapeSoqlSpecialCharactersInLike(String inputString) {
        // escape special characters for LIKE (_, %)
        return inputString.replaceAll('[_]', '\\\\_').replaceAll('[%]','\\\\%'); // prefix with single backslash (but works as escape in text and regex, hence 4)
    }

    /**
     * Remove Marketing Cloud session tokens
     */
    public static void deleteMarketingCloudTokens() {
        // delete via managed package helper methods (only if sandbox)
        Boolean sandbox;
        for(Organization o:[SELECT isSandbox FROM Organization LIMIT 1]) {
            sandbox = o.isSandbox;
        }
        // only execute in sandbox (and not as part of apex tests which would remove a working marketing cloud connector setup)
        if(sandbox && !Test.isRunningTest()) {
            try {
                et4ae5.SupportUtilities.deleteUserTokens('APIUSER');
                et4ae5.SupportUtilities.deleteUserTokens('APIUSER|7282917');
                et4ae5.SupportUtilities.deleteUserTokens('APIUSER|7297893');
                et4ae5.SupportUtilities.deleteUserTokens('APIUSER|7308071');
                et4ae5.SupportUtilities.deleteUserTokens('APIUSER|7301771');
            } catch (Exception exc) {
                Nebula.Logger.error('SandboxPostRefresh.turnOffSsoEnforcementInSandbox', exc);
                Nebula.Logger.saveLog();
            }
        }
    }

    /**
     * @author Stefan Scheit
     * @date 2022-08-19
     * @description Seed/insert Dun & Bradstreet (DnB) Optimizer settings for the 'Search before Create' feature into a sandbox where data/settings where not copied, e.g. Developer sandbox.
     * TODO: add list of profiles to a custom setting or custom metadata type record(s)
     */
    public static void insertDnbOptimizerSettings() {
        
        /*** configuration settings for DnB Optimizer feature 'Search before Create'. This is subject to change of the  ***/
        // DnB setting for a disabled profile
        final String SETTING_DISABLED = '{"SBC":{"LeadEnabled":false,"LeadDuplicateCreationEnabled":false,"LeadCustomMappingEnabled":false,"lead_data_mappings":[{"SF_Field":"Company","label":"Company Name","DNB_Field":"DNBoptimizer__BusinessName__c","defaultField":true},{"SF_Field":"Street","label":"Street","DNB_Field":"DNBoptimizer__combined_address__c","defaultField":true},{"SF_Field":"DBC_DUNS_Number__c","label":"DUNS Number","DNB_Field":"DNBoptimizer__DUNSNumber__c","defaultField":true},{"SF_Field":"City","label":"City","DNB_Field":"DNBoptimizer__PrimaryCityName__c","defaultField":true},{"SF_Field":"Country","label":"Country","DNB_Field":"DNBoptimizer__PrimaryCountryCode__c","defaultField":true},{"SF_Field":"PostalCode","label":"Postal Code","DNB_Field":"DNBoptimizer__PrimaryPostalCode__c","defaultField":true},{"SF_Field":"State","label":"State","DNB_Field":"DNBoptimizer__PrimaryStateProvinceAbbreviation__c","defaultField":true},{"SF_Field":"Phone","label":"Phone","DNB_Field":"DNBoptimizer__TelephoneNumber__c","defaultField":true}],"AccountEnabled":false,"AccountDuplicateCreationEnabled":false,"AccountCustomMappingEnabled":false,"account_data_mappings":[{"SF_Field":"Name","label":"Company Name","DNB_Field":"DNBoptimizer__BusinessName__c","defaultField":true},{"SF_Field":"BillingStreet","label":"Street Address","DNB_Field":"DNBoptimizer__combined_address__c","defaultField":true},{"SF_Field":"DBC_DUNS_Number__c","label":"DUNS Number","DNB_Field":"DNBoptimizer__DUNSNumber__c","defaultField":true},{"SF_Field":"BillingCity","label":"City","DNB_Field":"DNBoptimizer__PrimaryCityName__c","defaultField":true},{"SF_Field":"BillingCountry","label":"Country","DNB_Field":"DNBoptimizer__PrimaryCountryCode__c","defaultField":true},{"SF_Field":"BillingPostalCode","label":"Postal Code","DNB_Field":"DNBoptimizer__PrimaryPostalCode__c","defaultField":true},{"SF_Field":"BillingState","label":"State","DNB_Field":"DNBoptimizer__PrimaryStateProvinceAbbreviation__c","defaultField":true},{"SF_Field":"Phone","label":"Phone","DNB_Field":"DNBoptimizer__TelephoneNumber__c","defaultField":true},{"SF_Field":"Website","label":"Website","DNB_Field":"DNBoptimizer__WebAddress__c","defaultField":true}]}}';
        // DnB setting for an enabled profile
        final String SETTING_ENABLED = '{"SBC":{"LeadEnabled":false,"LeadDuplicateCreationEnabled":false,"LeadCustomMappingEnabled":false,"lead_data_mappings":[{"SF_Field":"Company","label":"Company Name","DNB_Field":"DNBoptimizer__BusinessName__c","defaultField":true},{"SF_Field":"Street","label":"Street","DNB_Field":"DNBoptimizer__combined_address__c","defaultField":true},{"SF_Field":"DBC_DUNS_Number__c","label":"DUNS Number","DNB_Field":"DNBoptimizer__DUNSNumber__c","defaultField":true},{"SF_Field":"City","label":"City","DNB_Field":"DNBoptimizer__PrimaryCityName__c","defaultField":true},{"SF_Field":"Country","label":"Country","DNB_Field":"DNBoptimizer__PrimaryCountryCode__c","defaultField":true},{"SF_Field":"PostalCode","label":"Postal Code","DNB_Field":"DNBoptimizer__PrimaryPostalCode__c","defaultField":true},{"SF_Field":"State","label":"State","DNB_Field":"DNBoptimizer__PrimaryStateProvinceAbbreviation__c","defaultField":true},{"SF_Field":"Phone","label":"Phone","DNB_Field":"DNBoptimizer__TelephoneNumber__c","defaultField":true}],"AccountEnabled":true,"AccountDuplicateCreationEnabled":false,"AccountCustomMappingEnabled":false,"account_data_mappings":[{"SF_Field":"Name","label":"Company Name","DNB_Field":"DNBoptimizer__BusinessName__c","defaultField":true},{"SF_Field":"BillingStreet","label":"Street Address","DNB_Field":"DNBoptimizer__combined_address__c","defaultField":true},{"SF_Field":"DBC_DUNS_Number__c","label":"DUNS Number","DNB_Field":"DNBoptimizer__DUNSNumber__c","defaultField":true},{"SF_Field":"BillingCity","label":"City","DNB_Field":"DNBoptimizer__PrimaryCityName__c","defaultField":true},{"SF_Field":"BillingCountry","label":"Country","DNB_Field":"DNBoptimizer__PrimaryCountryCode__c","defaultField":true},{"SF_Field":"BillingPostalCode","label":"Postal Code","DNB_Field":"DNBoptimizer__PrimaryPostalCode__c","defaultField":true},{"SF_Field":"BillingState","label":"State","DNB_Field":"DNBoptimizer__PrimaryStateProvinceAbbreviation__c","defaultField":true},{"SF_Field":"Phone","label":"Phone","DNB_Field":"DNBoptimizer__TelephoneNumber__c","defaultField":true},{"SF_Field":"Website","label":"Website","DNB_Field":"DNBoptimizer__WebAddress__c","defaultField":true}]}}';
        // DnB setting for an enabled profile with custom (prefill) mapping when creating account records
        final String SETTING_ENABLED_CUSTOM_MAPPING = '{"SBC":{"LeadEnabled":false,"LeadDuplicateCreationEnabled":false,"LeadCustomMappingEnabled":false,"lead_data_mappings":[{"SF_Field":"Company","label":"Company Name","DNB_Field":"DNBoptimizer__BusinessName__c","defaultField":true},{"SF_Field":"Street","label":"Street","DNB_Field":"DNBoptimizer__combined_address__c","defaultField":true},{"SF_Field":"DBC_DUNS_Number__c","label":"DUNS Number","DNB_Field":"DNBoptimizer__DUNSNumber__c","defaultField":true},{"SF_Field":"City","label":"City","DNB_Field":"DNBoptimizer__PrimaryCityName__c","defaultField":true},{"SF_Field":"Country","label":"Country","DNB_Field":"DNBoptimizer__PrimaryCountryCode__c","defaultField":true},{"SF_Field":"PostalCode","label":"Postal Code","DNB_Field":"DNBoptimizer__PrimaryPostalCode__c","defaultField":true},{"SF_Field":"State","label":"State","DNB_Field":"DNBoptimizer__PrimaryStateProvinceAbbreviation__c","defaultField":true},{"SF_Field":"Phone","label":"Phone","DNB_Field":"DNBoptimizer__TelephoneNumber__c","defaultField":true}],"AccountEnabled":true,"AccountDuplicateCreationEnabled":false,"AccountCustomMappingEnabled":true,"account_data_mappings":[{"SF_Field":"Name","label":"Company Name","DNB_Field":"DNBoptimizer__BusinessName__c","defaultField":true},{"SF_Field":"BillingStreet","label":"Street Address","DNB_Field":"DNBoptimizer__combined_address__c","defaultField":true},{"SF_Field":"DBC_DUNS_Number__c","label":"DUNS Number","DNB_Field":"DNBoptimizer__DUNSNumber__c","defaultField":true},{"SF_Field":"BillingCity","label":"City","DNB_Field":"DNBoptimizer__PrimaryCityName__c","defaultField":true},{"SF_Field":"BillingCountry","label":"Country","DNB_Field":"DNBoptimizer__PrimaryCountryCode__c","defaultField":true},{"SF_Field":"BillingPostalCode","label":"Postal Code","DNB_Field":"DNBoptimizer__PrimaryPostalCode__c","defaultField":true},{"SF_Field":"BillingState","label":"State","DNB_Field":"DNBoptimizer__PrimaryStateProvinceAbbreviation__c","defaultField":true},{"SF_Field":"Phone","label":"Phone","DNB_Field":"DNBoptimizer__TelephoneNumber__c","defaultField":true},{"SF_Field":"Website","label":"Website","DNB_Field":"DNBoptimizer__WebAddress__c","defaultField":true}]}}';
       
        // Profiles for which DnB 'Search before Create' should be enabled
        final Set<String> enableProfileSet = new Set<String>{
            'Enterprise Base Profile',
            'ascend Gift Supervisor',
            'ascend Development Research',
            'ascend Base User',
            'ascend Development Manager',
            'ascend Development Officer',
            'ascend Alumni Engagement User',
            'ascend Admin User',
            'ascend Stewardship Officer',
            'MRO Base Profile'
        };

        // delete existing settings (if profiles to be enabled are defined)
        List<DNBConnect__D_B_Connect_Setting__c> currentSettings = [SELECT Id FROM DNBConnect__D_B_Connect_Setting__c];
        try{
            Database.delete(currentSettings);
        } catch (Exception e) {
            LogUtilityException.logException(e);
        }
        
        // obtain profile id and create settings record
        List<DNBConnect__D_B_Connect_Setting__c> settingList = new List<DNBConnect__D_B_Connect_Setting__c>();
        DNBConnect__D_B_Connect_Setting__c settingRecord = null;
        for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN :enableProfileSet]) {
            settingRecord = new DNBConnect__D_B_Connect_Setting__c(
                Name = p.Name,
                DNBConnect__Profile_Id__c = p.Id,
                DNBConnect__Settings__c = SETTING_ENABLED_CUSTOM_MAPPING
            );
            settingList.add(settingRecord);
        }

        // add default global entry (with a disabled setting)
        settingRecord = new DNBConnect__D_B_Connect_Setting__c(
            Name = 'Global',
            DNBConnect__Profile_Id__c = 'Global',
            DNBConnect__Settings__c = SETTING_DISABLED
        );
        settingList.add(settingRecord);

        // Insert settings
        try{
            Database.insert(settingList);
        } catch (Exception e) {
            Nebula.Logger.error('SandboxPostRefresh.insertDnbOptimizerSettings', e);
            Nebula.Logger.saveLog();
        }
    }

    /**
     * Jenkins User Activation on Sandbox Refresh
     */
    @future
    public static void updateJenkinsCICDUser(String sandBoxNme) {
        try {
            List<User> usersList = [SELECT Id, Email, IsActive, Name, Username, UserPermissionsKnowledgeUser, UserPermissionsMarketingUser,UserPermissionsSupportUser
                                           FROM User WHERE Name = 'Jenkins User' LIMIT 1];
            Boolean sandbox = false;
            for(Organization o:[SELECT isSandbox FROM Organization LIMIT 1]) {
                sandbox = o.isSandbox;
            }
            // only execute in sandbox (and not as part of apex tests which would remove a working marketing cloud connector setup)
            if(sandbox || Test.isRunningTest()) {
                if(usersList != null && !usersList.isEmpty()) {
                    User usr = usersList.get(0);
                    //
                    Bypass_Mute_Request__c bmr = new Bypass_Mute_Request__c();
                    bmr.Bypass_All_Flows__c = true;
                    bmr.Bypass_All_Process__c = true;
                    bmr.Bypass_All_Validation_Rules__c = true;
                    bmr.Bypass_All_Triggers__c = true;
                    bmr.SetupOwnerId = usr.Id;
                    insert bmr;
                    //
                    usr.Email = 'esol-jenkins-unicrmadmin@monash.edu';
                    usr.Username = 'esol-jenkins-unicrmadmin@monash.edu'+'.'+sandBoxNme;
                    usr.IsActive = true;
                    usr.UserPermissionsInteractionUser = true;
                    usr.UserPermissionsKnowledgeUser = true;
                    usr.UserPermissionsLiveAgentUser = true;
                    usr.UserPermissionsMarketingUser = true;
                    usr.UserPermissionsSupportUser = true;
                    update usr;
                }
            }
        } catch(Exception e) {
            Nebula.Logger.error('SandboxPostRefresh.updateJenkinsCICDUser', e);
            Nebula.Logger.saveLog();
        }
    }
    /**
    * @author Peter Sewell
    * @date 2023-12-06
    * @description Turn off SSO enforcement feature switch in Sandboxes
    */
    @future // Avoid mixed DML error
    public static void turnOffSsoEnforcementInSandbox() {
        try {
            SecurityServices.disableSsoEnforcementInSandbox();
        } catch (Exception exc) {
            Nebula.Logger.error('SandboxPostRefresh.turnOffSsoEnforcementInSandbox', exc);
            Nebula.Logger.saveLog();
        }
    }
}