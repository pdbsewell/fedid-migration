/**
 * @description       : User Utility/Helper methods
 * @author            : Matthew Maramot
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2023-01-10   Matthew Maramot Added utility methods to to conduct AssignPermissionSets [EPCP-2479]
 * 1.1   2023-12-05   Peter Sewell    Updated isInternal criteria to exclude where User.Monash_User_Type__c == 'eSol Integration User'
 **/
public with sharing class UserUtility {  
    
    // User types
    public static final List<String> COMMUNITY_USER = new List<String>{'CspLitePortal', 'PowerPartner', 'CustomerSuccess', 'PowerCustomerSuccess'}; // customer communities   
    public static final String STANDARD_USER = 'Standard'; // standard user type
    public static final String INTEGRATION_USER_TYPE = 'eSol Integration User'; // Monash_User_Type__c on User object

    // System Setting Custom Metadata values
    public static final String USER_DEFAULT_PERMS_CUSTOM_METADATATYPE_FEATURE = 'USER_DEFAULT_PERMISSIONS';

    // Custom Metadata User Types
    public static final String USER_DEFAULT_PERMS_INTERNAL = 'UDPInternal';
    public static final String USER_DEFAULT_PERMS_MFA = 'UDPmfa';
    public static final String USER_DEFAULT_PERMS_COMMUNITY_ALL = 'UDPCommunityAll';
    public static final String USER_DEFAULT_PERMS_COMMUNITY_STAFF = 'UDPCommunityStaff';
    public static final String USER_DEFAULT_PERMS_COMMUNITY_STUDENT = 'UDPCommunityStudent';   

    /*******************************************************************************
    * @author       Stefan Scheit
    * @date         15/02/2019     
    * @description  Trigger implementation to assign default permission sets to community users when they are created.
    *               This relies on org config data to be present (i.e. the relevant permission sets)
    * @revision     1.1 (28/07/2020)
    *  2021-10-10 - Peter Sewell - Assign MFA enforcement permission set to users in SIT and STAGING [EPCP-1667]
    *  2023-11-01 - Matthew Maramot - Updated to use new framework and custom metadata [EPCP-2479]
                                    - Migrated from UserServices to UserUtility [EPCP-2479]
    *******************************************************************************/
    public static void AssignPermissionSets(List<User> userList, Map<Id, User> oldUserMap) {
        // list of permission set assignments to be created
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();

        // Retrieve custom metadata and split based off Permission Sets and Permission Set Groups
        List<System_Settings__mdt> userPermMetadatas = SystemSettingsUtil.getInstance().getByFeature(USER_DEFAULT_PERMS_CUSTOM_METADATATYPE_FEATURE);
        Map<String,Set<PermissionSet>> permissionSetMap = getDefaultPermSets(userPermMetadatas);
        Map<String,Set<PermissionSetGroup>> permissionSetGroupMap = getDefaultPermSetGroups(userPermMetadatas);
        System.debug(LoggingLevel.FINE, 'PermissionSetMap: '+permissionSetMap);
        System.debug(LoggingLevel.FINE, 'PermissionSetGroupMap: '+permissionSetGroupMap);

        // set of (active) customer community users
        Set<String> contactIds = new Set<String>();
        for(User user : userList) {
            if (COMMUNITY_USER.contains(user.UserType) && user.isActive) {
                contactIds.add(user.ContactId);
            }
        }

        // map of (active) customer community users
        Map<Id,Contact> communityContactMap = new Map<ID, Contact>([SELECT Id, Person_ID_unique__c, SAP_Staff_Id__c, Authcate__c, PAG_MoID__c FROM Contact WHERE Id IN :contactIds]);
        PermissionSetAssignment psa = null;
        Contact contact = null;
        User oldUser = null;

        // list of all api users (Perm Sets)
        List<Id> apiUsers = new List<Id>();
        List<PermissionSetAssignment> apiUsersPSA = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN :userList AND PermissionSet.PermissionsApiUserOnly = true];
        for(PermissionSetAssignment permSetAssgn : apiUsersPSA ){
            apiUsers.add(permSetAssgn.AssigneeId);    
        }

        // execute for all users
        List<Id> userIdsToCheckForMfaAssignment = new List<Id>();

        for(User newUser : userList) {
            userIdsToCheckForMfaAssignment.add(newUser.Id); // Create List of Ids of users in trigger
            contact = communityContactMap.get(newUser.ContactId);
            
            // NOTE: If statements are used as a User can meet multiple conditions
            // Community (Staff)
            if(isCommunityStaff(newUser, contact, oldUserMap)){
                permSetAssignments.addAll(addAssignments(USER_DEFAULT_PERMS_COMMUNITY_STAFF,newUser.Id,permissionSetMap,permissionSetGroupMap));
            }

            // Community (Student) 
            if(isCommunityStudent(newUser,contact,oldUserMap)){
                permSetAssignments.addAll(addAssignments(USER_DEFAULT_PERMS_COMMUNITY_STUDENT,newUser.Id,permissionSetMap,permissionSetGroupMap));
            }

            // Community (All)
            if(isCommunity(newUser, contact, oldUserMap)){
                    permSetAssignments.addAll(addAssignments(USER_DEFAULT_PERMS_COMMUNITY_ALL,newUser.Id,permissionSetMap,permissionSetGroupMap));
            }

            // Internal User (All)
            if(isInternal(newUser, apiUsers, oldUserMap)){
                permSetAssignments.addAll(addAssignments(USER_DEFAULT_PERMS_INTERNAL,newUser.Id,permissionSetMap,permissionSetGroupMap));
            }
        }

        // Assign MFA enforcement perm set but only for users in-scope of MFA, as determined by findUsersRequiringMfaEnforcement
        for (Id mfaUserId : SecurityServices.findUsersRequiringMfaEnforcement(userIdsToCheckForMfaAssignment)) {
            permSetAssignments.addAll(addAssignments(USER_DEFAULT_PERMS_MFA,mfaUserId,permissionSetMap,permissionSetGroupMap));
        }

        // Insert permSetAssignments
        try{
            if (permSetAssignments.size()>0) {
                //PV - Used for Retry
                Integer recCount = 0;
                Map<String, PermissionSetAssignment> mixRetryMap = new Map<String, PermissionSetAssignment>();
                //Steffi updated below changes
                Database.SaveResult[] srList = Database.insert(permSetAssignments, false);
                for (Database.SaveResult sr: srList) {
                    if (sr.isSuccess() == false) {
                        // Operation failed, re-Queue again if Mixed DML erros               
                        for (Database.Error err: sr.getErrors()) {
                            //PV - change to status code compare
                            if(err.getStatusCode() == System.StatusCode.MIXED_DML_OPERATION){
                                //PV - Get the record that failed amd process
                                PermissionSetAssignment psaRetry = permSetAssignments.get(recCount);
                                String psakeyID = ''+psaRetry.PermissionSetId + psaRetry.AssigneeId;
                                mixRetryMap.put(psakeyID, psaRetry);
                                //
                            }else if (!err.getMessage().contains('Duplicate PermissionSetAssignment')) {
                                LogUtilityException.addLogEvent('AssignPermissionSets Error', sr, err, 'UserUtility.AssignPermissionSets');
                            }
                        }
                    }
                    recCount++;
                }
                //publish eceptions
                LogUtilityException.publishAll(); 
 
                //retry mixedDML's
                if(!mixRetryMap.isEmpty()){
                    // create queueable (just in case other non-config objects (e.g. Account or Contact) were updated as part of same transaction)
                    UserServices.InsertSobjectsQueueable insertQueuable = new UserServices.InsertSobjectsQueueable(mixRetryMap.values(), false); // do not fail all records if a particular item fails
                    Id jobId = System.enqueueJob(insertQueuable);
                    System.debug(LoggingLevel.FINEST, UserUtility.AssignPermissionSets.class+': Queued job with id ['+jobId+'] to assign permission sets ['+mixRetryMap.values()+']');
                }
            }
        } catch(Exception exc) {
            LogUtilityException.logException('UserUtility', permSetAssignments, exc, 'AssignPermissionSets DML Error', 'ERROR');
        }
    }

    /**
     * @author      Matthew Maramot
     * @date        2022-11-22 - Matthew Maramot
     * @description Retrieves the User Default Permission Sets from the System Settings custom metadata
     */
    public static Map<String, Set<PermissionSet>> getDefaultPermSets(List<System_Settings__mdt> userPermMetadatas){
        //Initialise Variables
        Map<String, Set<String>> permissionSetNamesMap = new Map<String, Set<String>>();
        Map<String, Set<PermissionSet>> permissionSetIdsMap = new Map<String,Set<PermissionSet>>();
        UserPermsCustomMetadataWrapper formatDetails;
        Set<String> permSetNames = new Set<String>();
        List<String> permsList;
        
        if(!userPermMetadatas.isEmpty()){
            try{
                for(System_Settings__mdt objSettings : userPermMetadatas){
                    // Deserialize JSON value
                    formatDetails = (UserPermsCustomMetadataWrapper) JSON.deserialize(objSettings.Value__c, UserPermsCustomMetadataWrapper.class);
                    permsList = formatDetails.Permissions.split(';');
                    
                    // Map User Type against Permission Set Names
                    if(formatDetails.Permission_Type == 'Permission Set'){
                        if(!permissionSetNamesMap.containsKey(objSettings.Key__c)) {
                            permissionSetNamesMap.put(objSettings.Key__c, new Set<String>());
                            permissionSetIdsMap.put(objSettings.Key__c, new Set<PermissionSet>());
                        }
                        permissionSetNamesMap.get(objSettings.Key__c).addAll(permsList);
                        
                        // Record all permission set names for query
                        permSetNames.addAll(permsList);
                    }
                }
                // Query all permission sets and add to map
                if(!permSetNames.isEmpty()) {
                    for(PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames AND PermissionSetGroupId = null AND ProfileId = null]) {
                        for (String key : permissionSetIdsMap.keySet()) {
                            // Add permission set Ids paired againts key
                            if (permissionSetNamesMap.get(key).contains(permSet.Name)) {
                                permissionSetIdsMap.get(key).add(permSet);
                             }
                        }
                    }
                }
            }
            catch (Exception err){
                logUtilityException.logException( err, 'Did not deserialize User Default Permissions Sets from custom metadata correctly');
            }      
        }
        return permissionSetIdsMap;
    }

    /**
     * @author      Matthew Maramot
     * @date        2022-11-22 - Matthew Maramot
     * @description Retrieves the User Default Permissions Set Groups from the System Settings custom metadata
     */
    public static Map<String, Set<PermissionSetGroup>> getDefaultPermSetGroups(List<System_Settings__mdt> userPermMetadatas){
        //Initialise Variables
        Map<String, Set<String>> permissionSetNamesMap = new Map<String, Set<String>>();
        Map<String, Set<PermissionSetGroup>> permissionSetIdsMap = new Map<String,Set<PermissionSetGroup>>();
        UserPermsCustomMetadataWrapper formatDetails;
        Set<String> permSetNames = new Set<String>();
        List<String> permsList;
        
        if(!userPermMetadatas.isEmpty()){
            try{
                for(System_Settings__mdt objSettings : userPermMetadatas){
                    // Deserialize JSON value
                    formatDetails = (UserPermsCustomMetadataWrapper) JSON.deserialize(objSettings.Value__c, UserPermsCustomMetadataWrapper.class);
                    permsList = formatDetails.Permissions.split(';');
                    
                    // Map User Type against Permission Set Group Names
                    if(formatDetails.Permission_Type == 'Permission Set Group'){
                        if(!permissionSetNamesMap.containsKey(objSettings.Key__c)) {
                            permissionSetNamesMap.put(objSettings.Key__c, new Set<String>());
                            permissionSetIdsMap.put(objSettings.Key__c, new Set<PermissionSetGroup>());
                        }
                        permissionSetNamesMap.get(objSettings.Key__c).addAll(permsList);
                        
                        // Record all permission set names for query
                        permSetNames.addAll(permsList);
                    }
                }
                // Query all permission sets and add to map
                if(!permSetNames.isEmpty()) {
                    for(PermissionSetGroup permSet : [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :permSetNames]) {
                        for (String key : permissionSetIdsMap.keySet()) {
                            // Add permission set Ids paired againts key
                            if (permissionSetNamesMap.get(key).contains(permSet.DeveloperName)) {
                                permissionSetIdsMap.get(key).add(permSet);
                             }
                        }
                    }
                }
            }
            catch (Exception err){
                logUtilityException.logException( err, 'Did not deserialize User Default Permissions Sets from custom metadata correctly');
            }      
        }
        return permissionSetIdsMap;
    }

    /**
     * @author      Matthew Maramot
     * @date        2023-01-10 - Matthew Maramot
     * @description creates PermissionSetAssignment based on input permSets and permSetGroups
    */
    public static List<PermissionSetAssignment> addAssignments(String assignmentType, Id userId, Map<String,Set<PermissionSet>> permissionSetMap, Map<String,Set<PermissionSetGroup>> permissionSetGroupMap ){
        // Initialise Create variables
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        PermissionSetAssignment psa = null;
        
        // Assign Permission Sets
        if(permissionSetMap.containsKey(assignmentType)){
            for(PermissionSet permSet : permissionSetMap.get(assignmentType)) {
                psa = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = userId);
                permSetAssignments.add(psa);
            }
        }
        // Assign Permission Set Groups
        if(permissionSetGroupMap.containsKey(assignmentType)){
            for(PermissionSetGroup permSetGroup : permissionSetGroupMap.get(assignmentType)) {
                psa = new PermissionSetAssignment(PermissionSetGroupId = permSetGroup.Id, AssigneeId = userId);
                permSetAssignments.add(psa);
            }
        }
        return permSetAssignments;
    }

    /**
     * @author      Matthew Maramot
     * @date        2023-01-10 - Matthew Maramot
     * @description Returns True or False whether user is Community Staff
    */
    public static Boolean isCommunityStaff(User u, Contact c, Map<Id, User> oldUserMap){
        // Has contact
        if(c != null){
            // Community User and Active
            if(COMMUNITY_USER.contains(u.UserType) && u.IsActive){
                // Has SAP Id and Authcate
                if(String.isNotBlank(c.SAP_Staff_Id__c) && String.isNotBlank(c.Authcate__c)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @author      Matthew Maramot
     * @date        2023-01-10 - Matthew Maramot
     * @description Returns True or False whether user is Community Student
    */
    public static Boolean isCommunityStudent(User u, Contact c, Map<Id, User> oldUserMap){
        // Has contact
        if(c != null){
            // Community User and Active
            if(COMMUNITY_USER.contains(u.UserType) && u.IsActive){
                // Has Person Id and Authcate
                if(String.isNotBlank(c.Person_ID_unique__c) && String.isNotBlank(c.Authcate__c)){
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @author      Matthew Maramot
     * @date        2023-01-10 - Matthew Maramot
     * @description Returns True or False whether user is Community
    */
    public static Boolean isCommunity(User u, Contact c, Map<Id, User> oldUserMap){
        // oldUserMap is empty if Insert
        if(oldUserMap.isEmpty()){
            // Community User and Active
            if(COMMUNITY_USER.contains(u.UserType) && u.IsActive){
                return true;
            }
        }
        // else is Update
        else{
            // Community User and Active
            User oldU = oldUserMap.get(u.Id);
            if(oldU != null){
                if(COMMUNITY_USER.contains(u.UserType)  && u.isActive && !oldU.isActive){
                    return true;
                }
            } 
        }
        
        return false;
    }

    /**
     * @author      Matthew Maramot
     * @date        2023-01-10 - Matthew Maramot
     * @description Returns True or False whether user is Internal
     * @revision    
     * 2023-12-05   Peter Sewell    Exempt Monash_User_Type__c == 'eSol Integration User'
    */
    public static Boolean isInternal(User u, List<Id> apiUsers, Map<Id, User> oldUserMap){
        
        // Internal user exceptions and exemptions...(ie. Not internal)
        
        // Not interested in inactive users
        if (!u.IsActive) {
            return false;
        }

        // Only interested in updates where user transitions from not-active -> active 
        if(u.isActive && oldUserMap.get(u.Id) != null && oldUserMap.get(u.Id).isActive) {
            return false;
        }

        // Exclude non standard users
        if (u.UserType != STANDARD_USER) {
            return false;
        }

        // Exclude API-only users, where API only is set in profile
        Profile userProfile = [SELECT Name, PermissionsApiUserOnly FROM Profile WHERE Id = :u.ProfileId];
        if (userProfile.PermissionsApiUserOnly) {
            return false;
        }

        // Exclude API-only users passed into method as a list
        if (apiUsers.contains(u.Id)) {
            return false;
        }   

        // Exclude users explicitly classified as integration users
        if (u.Monash_User_Type__c == INTEGRATION_USER_TYPE) {
            return false;
        }

        // Otherwise we have ourselves an internal user!
        //
        return true;
    }

    /**
    * @author      Matthew Maramot
    * @date        2022-11-22 - Matthew Maramot
    * @description Wrapper for custom metadata values
   */
   public class UserPermsCustomMetadataWrapper {
    @AuraEnabled
    public String Permission_Type {get; set;}
    @AuraEnabled
    public String Permissions {get; set;}

    public UserPermsCustomMetadataWrapper(){
        this.Permission_Type = '';
        this.Permissions = '';
    }

    public UserPermsCustomMetadataWrapper(String permType, String applyTo, String perms){
        this.Permission_Type = permType;
        this.Permissions = perms;
    }
}
}