/**
 * @author          Peter Sewell, Salesforce
 * @description     Services class to provide Security centric logical support
 * @revision        
 *  2021-10-11 - Peter Sewell - initial version
 *  2023-12-06 - Peter Sewell - Disable SSO enforcement feature when run in a sandbox
*/
public without sharing class SecurityServices {

    /*
    * Constants
    */

    // Names of sandboxs where MFA is to be enforced
    public static final String SIT_SANDBOX_NAME = 'sit';
    public static final String STAGING_SANDBOX_NAME = 'staging';
    // API name of permission set to enforce MFA
    public static final String MFA_ENFORCEMENT_PERM_SET = 'Auth_Enforce_MFA';
    // SOQL used to select users for whom MFA is to be enforced - effectively the logic to find in-scope MFA users
    // If there are users who should either be excluded or included for MFA, this is where the change needs to happen
    public static final String MFA_ENFORCEMENT_QUERY = 
        'SELECT Id from User WHERE ' +
        'IsActive = true AND ' +
        'Profile.PermissionsApiUserOnly = false AND ' +
        '(Profile.UserLicense.Name = \'Salesforce\' OR Profile.UserLicense.Name = \'Salesforce Platform\') AND ' +
        '(NOT (Profile.Name LIKE \'Integration%\')) AND ' +
        'Monash_User_Type__c != \'eSol Test User\' AND ' +
        'Monash_User_Type__c != \'eSol Integration User\' AND ' +
        'Id NOT IN (SELECT AssigneeId from PermissionSetAssignment WHERE PermissionSetId = :mfaPermSetId) ';
    public static final String MFA_ENFORCEMENT_QUERY_FILTERED_BY_USERS = 
        MFA_ENFORCEMENT_QUERY +
        'AND Id IN :userIds ';
    
    /**
    * @author Peter Sewell
    * @date 2021-10-11
    * @description Returns set of Ids of all Users in the Org who require MFA enforcement
    * @return set of Ids of Users who require MFA enforcement
    */
    public static Set<Id> findUsersRequiringMfaEnforcement () {
        return findUsersRequiringMfaEnforcement ( null ) ; // Null filter param means all MFA users in Org 
    }

    /**
    * @author Peter Sewell
    * @date 2021-10-11
    * @description Returns filtered set of User Ids for users who require MFA enforcement
    * @param List<Id> userIds - list of Ids of Users to check for MFA enforcement
    * @return Ids of Users in Org who require MFA enforcement filtered by userIds
    */
    public static Set<Id> findUsersRequiringMfaEnforcement(List<Id> userIds) {
        
        Set<Id> usersRequiringMfaEnforcement = new Set<Id> () ;

        // Only enforce MFA if the Org is Sandbox, otherwise return
        // Also, keep executing this method if in a Prod Org AND running in Test class, otherwise we wont get code coverage in Prod
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (!runningInASandbox && !Test.isRunningTest()) {return usersRequiringMfaEnforcement;}

        // Only enforce MFA if the Sandbox is SIT or Staging (**TODO move sandbox names to metadata)
        // Sandbox names are expected to be found in Custom Settings 
        Sandbox_Details__c setting = Sandbox_Details__c.getOrgDefaults();
        if (!(setting.sandboxName__c == SIT_SANDBOX_NAME || setting.sandboxName__c == STAGING_SANDBOX_NAME)) {return usersRequiringMfaEnforcement;}

        // Get Id of MFA enforcement perm set 
        List<PermissionSet> permSets = new List<PermissionSet>();
        permSets = [SELECT Id FROM PermissionSet WHERE Name = :MFA_ENFORCEMENT_PERM_SET LIMIT 1];
        if (permSets == null || permSets.size() != 1) {return usersRequiringMfaEnforcement;}
        Id mfaPermSetId = permSets[0].Id; // NB. mfaPermSetId is referenced in MFA_ENFORCEMENT_QUERY as a bind variable, so be careful if changing name

        // Get Set of Ids of Users for whom MFA enforcement is required
        String mfaEnforcementQuery = (userIds != null) ? MFA_ENFORCEMENT_QUERY_FILTERED_BY_USERS : MFA_ENFORCEMENT_QUERY;
        Map<ID, User> usersRequiringMfaEnforcementMap = new Map<Id, User>((List<User>)Database.query (mfaEnforcementQuery)) ;
        usersRequiringMfaEnforcement.addAll (usersRequiringMfaEnforcementMap.keyset()) ;
        
        // If running in Prod, ensure we *always* return no mfa users - a no surprise policy :-)
        if (!runningInASandbox) { usersRequiringMfaEnforcement.clear();}

        return (usersRequiringMfaEnforcement) ;
    }

    /**
    * @author Peter Sewell
    * @date 2023-12-06
    * @description Disable SSO enforcement feature in sandboxes
    */
    public static void disableSsoEnforcementInSandbox () {
        // Only enforce MFA if the Org is Sandbox
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (runningInASandbox || Test.isRunningTest()) {
            Feature_Switch_TSP__c fs = Feature_Switch_TSP__c.getOrgDefaults();
            fs.Detect_Non_SSO_Login__c = false;
            upsert fs;
        }
    }

}