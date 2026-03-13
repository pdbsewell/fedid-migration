/**
 * @author       P.Sewell
 * @date         27.Aug.2024
 * @description  Controller for LWC loginRedirect
 * @revision
 *               27.Aug.24 P.Sewell - Create Class
 *               04.Sep.24 P.Sewell - Remove trailing slash from base URL if present
 *               21.Oct.24 P.Sewell - Support redirect params as query strings to customise redirection
 **/
public with sharing class LoginRedirectController {
    
    // Constants
    //
    public static final String SOURCE_SITE_NAME = 'Ask_Monash';                     // Site user logs into
    public static final String DEFAULT_REDIRECT_NETWORK_NAME = 'my.application';    // Network (portal) user is redirected to
    public static final String DEFAULT_MEMBER_PERMSET_TO_ASSIGN = 'Customer_Community_My_Application';  // Perm set to make user member of target network

    // Returns login redirect URL 
    //
    @AuraEnabled
    public static String getRedirectUrl() {
        return getSitePath() + '/servlet/networks/switch?networkId=' + getRedirectNetworkId() + '&';
    }

    // Returns login redirect URL 
    //
    @AuraEnabled
    public static String getRedirectUrlWithPath(String redirectPath, String siteLabel) {
        
        // Sanitise inputs
        if (String.isBlank(redirectPath) || String.isBlank(siteLabel)) {
            raiseException('Parameters cannot be blank');
        }

        // Ensure redirectPath is relative not absolute
        if (!isRelativeUrl(redirectPath)) {
            raiseException('Redirect path must be relative');
        }

        String networkId = getRedirectNetworkId(getNetworkNameBySettingName(siteLabel));
        String urlPath = EncodingUtil.urlEncode(redirectPath, 'UTF-8');

        return 
            getSitePath() + 
            '/servlet/networks/switch?networkId=' + networkId + 
            '&startURL=' + urlPath;
    }

    // Make user a member of the portal to which they will be redirected
    //
    @AuraEnabled
    public static void makeMemberOfTargetPortal() {
        assignPermissionSetsIfNotAssigned(UserInfo.getUserId(), new List<String>{DEFAULT_MEMBER_PERMSET_TO_ASSIGN});
    }

    // Make user a member of the portal to which they will be redirected, 
    // specifying perm sets via siteLabel (used to find perm sets in custom setting)
    //
    @AuraEnabled
    public static void makeMemberOfTargetPortalByName(String siteLabel) {
        assignPermissionSetsIfNotAssigned(UserInfo.getUserId(), getNetworkPermSetsBySettingName(siteLabel));
    }

    // Returns as a string the id of network of the  
    // portal to which the user will be redirected
    // using default network name
    //
    @TestVisible
    private static String getRedirectNetworkId() { 
        return getRedirectNetworkId(DEFAULT_REDIRECT_NETWORK_NAME);
    }

    // Returns as a string the id of network of the  
    // portal to which the user will be redirected
    //
    @TestVisible
    private static String getRedirectNetworkId(String networkName) {
        
        if (String.isBlank(networkName)) {
            raiseException('Network name cannot be blank');
        }

        String networkId = '';

        // Query the Network object to find the network by name
        for (Network siteNetwork : [SELECT Id, Name FROM Network WHERE Name = :networkName LIMIT 1]) {
            networkId = siteNetwork.Id;
            networkId = networkId.left(15); // network switch URL requires 15 char id
        }
        
        if (String.isBlank(networkId)) {
            raiseException('Network Id not found for network name:' + networkName);
        }

        return networkId;
    }


    // Returns the base path of the URL to which the network id 
    // is then appended to form the network switch URL
    //
    @TestVisible
    private static String getSitePath() {

        String sitePath = '';

        // Query to find the Site Id
        for (Site theSite : [SELECT Id, name FROM Site WHERE Name = :SOURCE_SITE_NAME]) {

            // Query to find the Site URL for Site Id
            for (SiteDetail siteDet : [SELECT SecureUrl FROM SiteDetail WHERE DurableId = :theSite.Id]) {
                sitePath = removeTrailingSlash(siteDet.SecureUrl);
            }
        }

        return sitePath;
    }

    // Remove trailing slash from string
    //
    @TestVisible
    private static String removeTrailingSlash(String str) {
        // Check if the last character is a forward slash (can be in Prod orgs)
        if (str.endsWith('/')) {
            // Remove the last character
            str = str.substring(0, str.length() - 1);
        }
        return str;
    }

    // Checks if the user has the permission set assigned.
    // If not, assign the permission sets to the user.
    // Return true if the user ends up with the perm sets assigned, false if not
    //
    @TestVisible
    private static void assignPermissionSetsIfNotAssigned(Id userId, List<String> permSetNames) {
 
        // Step 0: Ensure all perm sets are in Org
        List<Id> permissionSetIds = new List<Id>();
        for (PermissionSet permSet : [SELECT Id FROM PermissionSet WHERE Name IN :permSetNames]) {
            permissionSetIds.add(permSet.Id);
        }
        if (permissionSetIds.size() <> permSetNames.size()) { 
            raiseException('One or more permission sets not found in org:' + permSetNames);
        }

        // Step 1: Query the existing permission set assignments for the user
        List<PermissionSetAssignment> existingAssignments = [
            SELECT PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId
        ];

        // Step 2: Get a set of already assigned permission set IDs
        Set<Id> assignedPermissionSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : existingAssignments) {
            assignedPermissionSetIds.add(psa.PermissionSetId);
        }

        // Step 3: Filter out permission sets already assigned
        List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
        for (Id permissionSetId : permissionSetIds) {
            if (!assignedPermissionSetIds.contains(permissionSetId)) {
                // Step 4: Create new permission set assignments for unassigned permission sets
                PermissionSetAssignment psa = new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = permissionSetId
                );
                newAssignments.add(psa);
            }
        }

        // Step 5: Insert the new permission set assignments if there are any
        if (!newAssignments.isEmpty()) {
            try {
                insert newAssignments;
            } catch (DmlException ex) {
                raiseException('One or more permission sets could not be assigned:' + ex.getMessage());
            }
        }
    }

    // Method to check if the URL is relative and return a boolean
    //
    @TestVisible
    public static Boolean isRelativeUrl(String inputUrl) {
        if (String.isBlank(inputUrl)) {
            return false;
        }

        // Check if the URL starts with 'http://', 'https://', or '//' (common absolute URL patterns)
        if (inputUrl.startsWithIgnoreCase('http://') || inputUrl.startsWithIgnoreCase('https://') || inputUrl.startsWith('//')) {
            return false;
        }

        // Ensure the URL starts with a '/' to represent a relative path within the domain
        if (!inputUrl.startsWith('/')) {
            return false;
        }

        // If all checks pass, return TRUE
        return true;
    }

    // Method to get network name from custom setting
    //
    @TestVisible
    public static String getNetworkNameBySettingName(String settingName) {
        if (String.isBlank(settingName)) {
            raiseException('Setting name cannot be blank');
        }

        // Retrieve the custom setting row by Name for a list custom setting
        for (Login_Redirect_Settings__c setting : [SELECT Network_Name__c 
                                              FROM Login_Redirect_Settings__c 
                                              WHERE Name = :settingName 
                                              LIMIT 1]) {
            return setting.Network_Name__c;
        }

        raiseException('No custom setting found with the provided name: ' + settingName);

        return null;
    }

    // Method to get list of perm set API names from custom setting
    //
    @TestVisible
    public static List<String> getNetworkPermSetsBySettingName(String settingName) {
        if (String.isBlank(settingName)) {
            raiseException('Setting name cannot be blank');
        }

        // Retrieve the custom setting row by Name for a list custom setting
        for (Login_Redirect_Settings__c setting : [SELECT Permission_Sets__c 
                                              FROM Login_Redirect_Settings__c 
                                              WHERE Name = :settingName 
                                              LIMIT 1]) {
            
            // extract copmma separated perm set names
            String permSetString = setting.Permission_Sets__c;
            List<String> permSetList = new List<String>();
            // trim spaces
            for(String permSet : permSetString.split(',')) {
                permSetList.add(permSet.trim());
            }
            return permSetList;
        }

        raiseException('No custom setting found with the provided name: ' + settingName);

        return null;
    }

    private static void raiseException(String message) {
        nebula.logger.error (message);
        nebula.logger.saveLog();
        throw new LoginRedirectException(message);
    }

    public class LoginRedirectException extends Exception {

    }
}