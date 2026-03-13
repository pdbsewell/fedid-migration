/**
 * @author          Peter Sewell
 * @description     Test class for SecurityServices class
 * @revision        2021-10-11 - Peter Sewell - Initial version [EPCP-1667]
 */
@isTest (isParallel=false)
public class SecurityServices_Test {

    /**
     * Test method to validate MFA enforcement would be bypassed for Prod Org
     */
    @isTest
    static void testFindUsersRequiringMfaEnforcementProdByPass() {
             
        // Fudge sandbox name to make it in-scope for MFA so all the code runs
        // If we dont do this, we wont get code coverage other than when tests run in SIT or STAGING
        Sandbox_Details__c setting = Sandbox_Details__c.getOrgDefaults();
        setting.sandboxName__c = SecurityServices.SIT_SANDBOX_NAME;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            Database.upsert(setting);
        }

        Test.startTest(); 

        // Find Ids of users in-scope for MFA enforcement
        Set<Id> usersRequiringMfa = new Set<Id> () ;
        usersRequiringMfa.addAll (SecurityServices.findUsersRequiringMfaEnforcement()) ;

        Test.stopTest();

        // No users should be assigned MFA permset in prod
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (!runningInASandbox) {
            System.assert (usersRequiringMfa.size()==0, 'MFA enforcement should always be bypassed in a Prod Org') ;
        }
    }

    /**
     * Test method to validate MFA enforcement would be bypassed for out of scope Sandbox
     */
    @isTest
    static void testFindUsersRequiringMfaEnforcementSandboxByPass() {
        
        // Fudge sandbox name in custom settings to make it out-of-scope for MFA
        Sandbox_Details__c setting = Sandbox_Details__c.getOrgDefaults();
        setting.sandboxName__c = 'outofscope';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            Database.upsert(setting);
        }

        Test.startTest(); 

        // Find Ids of users in-scope for MFA enforcement
        Set<Id> usersRequiringMfa = new Set<Id> () ;
        usersRequiringMfa.addAll (SecurityServices.findUsersRequiringMfaEnforcement()) ;

        Test.stopTest();

        // No users should be assigned MFA permset in an out-of-scope sandbox
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (runningInASandbox) {
            System.assert (usersRequiringMfa.size()==0, 'MFA enforcement should always be bypassed sandboxes other than SIT and STAGING') ;
        }
    }

    /**
     * Test method to validate that SSO enforcement is disabled in a Sandbox
     */
    @isTest
    static void testdisableSsoEnforcementInSandbox() {
        
        // Set custom setting to true
        Feature_Switch_TSP__c fs = Feature_Switch_TSP__c.getOrgDefaults();
        fs.Detect_Non_SSO_Login__c = true;
        upsert fs;

        Test.startTest(); 
            SecurityServices.disableSsoEnforcementInSandbox();
        Test.stopTest();
        
        fs = Feature_Switch_TSP__c.getOrgDefaults();
        System.assert (fs.Detect_Non_SSO_Login__c == false, 'SSO enforcement switch should have been disabled') ;
    }
}