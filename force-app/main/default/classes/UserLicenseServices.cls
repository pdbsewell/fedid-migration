/*******************************************************************************
* @author       Angelo Rivera
* @date         02/04/2019
* @description  Class supporting the logic on user license management
* @revision     1.0
*******************************************************************************/
public without sharing class UserLicenseServices {

    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         02/04/2019
    * @description  Class which checks the records updates on user:
    *               - Activation, Deactivation, Change of role, Creation
    * @revision     1.0
    *               30/04/2019 - RUSSELL CADAPAN - changed the code to handle business logic based on the modified object model
    *******************************************************************************/

    // a string that contains an "Active" status
    public static final String ROLE_LICENSE_STATUS_ACTIVE = 'Active';
    // a string that contains an "Inactive" status
    public static final String ROLE_LICENSE_STATUS_INACTIVE = 'Inactive';
    // a string that contains an active reason
    public static final String ROLE_LICENSE_REASON_ACTIVE = 'User Activated';
    // a string that contains an Inactive reason
    public static final String ROLE_LICENSE_REASON_INACTIVE = 'User Deactivated';
    // a string that contains an Change of Role reason
    public static final String ROLE_LICENSE_REASON_CHANGE_ROLE_NEW = 'Transferred from another role: ';
    // a string that contains an Change of Role reason
    public static final String ROLE_LICENSE_REASON_CHANGE_ROLE_OLD = 'Transferred to another role: ';

    public class CheckUserRecordUpdates implements Triggers.Handler{

        public void run(){
            
            // a set of profile Ids with Salesforce license
            Set<Id> setSalesforceProfiles = new Set<Id>();
            
            // store all the profile Ids into a set
            for(Profile prf: [SELECT Id, UserLicenseId FROM Profile where UserLicenseId  IN (SELECT Id FROM UserLicense WHERE Name = 'Salesforce')]){
                setSalesforceProfiles.add(prf.Id);
            }
            
            // a map of roles Id and it's name stored in salesforce
            Map<Id, String> mapUserRolesByIds = getUserRoleName();

            // a set of user Ids that has been updated / inserted
            Set<Id> setNewUserIds = new Set<Id>();
            for(User newUserRecord : (List<User>)Trigger.new){
                setNewUserIds.add(newUserRecord.Id);
            }

            // a map of user id and a list of existing role licenses
            Map<Id, List<Role_License__c>> mapUserToUnitLicenses = new Map<Id, List<Role_License__c>>();

            // a map of user id and a set of existing role licenses' names
            Map<Id, Set<String>> mapUserToUnitLicenseName = new Map<Id, Set<String>>();

            // get all the existing role licenses per user that has been part of the Trigger.new
            for(Role_License__c roleLicense: [SELECT Id, Name, Role__c, User_Lookup__c, Status__c, Reason__c FROM Role_License__c WHERE User_Lookup__c IN: setNewUserIds]){

                // per user, collect all the related role license records and role license name
                if(mapUserToUnitLicenses.containsKey(roleLicense.User_Lookup__c)){
                    mapUserToUnitLicenses.get(roleLicense.User_Lookup__c).add(roleLicense);
                    mapUserToUnitLicenseName.get(roleLicense.User_Lookup__c).add(roleLicense.Role__c);
                }
                else{
                    mapUserToUnitLicenses.put(roleLicense.User_Lookup__c, new List<Role_License__c>{roleLicense});
                    mapUserToUnitLicenseName.put(roleLicense.User_Lookup__c, new Set<String>{roleLicense.Role__c});
                }
            }

            // a list of role licenses to be updated
            List<Role_License__c> listUserRoleLicenseToUpdate = new List<Role_License__c>();

            // a list of role licenses to be updated
            List<Role_License__c> listUserRoleLicenseToInsert = new List<Role_License__c>();
            
            // a map of Role Name, and the Id of the parent Business Unit
            Map<String, Id> mapRoleToParentBusinessUnit = getParentBusinessUnitByRole();

            // for each user record included in the Trigger.new
            for(User newUserRecord: (List<User>) Trigger.new){
                // run this engine only for users with role assignment and Salesforce profile license
                if(newUserRecord.UserRoleId != null && setSalesforceProfiles.contains(newUserRecord.ProfileId)){
                    // a string that contains the current role the user is assigned to.
                    String newUserRoleName = mapUserRolesByIds.get(newUserRecord.UserRoleId);

                    // EVENT: for new users created ONLY, automatically create a new role license
                    if(Trigger.isInsert){
                        createRoleLicense(mapRoleToParentBusinessUnit, listUserRoleLicenseToInsert, newUserRoleName, newUserRecord.Id, newUserRecord.IsActive, ROLE_LICENSE_REASON_ACTIVE);
                    }
                    else{

                        // an sObject that contains the old User instance
                        User oldUserRecord = (User)Trigger.oldMap.get(newUserRecord.Id);

                        // a boolean to identify if the user activity is changed
                        Boolean bStatusChanged = oldUserRecord.IsActive != newUserRecord.IsActive;

                        // a string that contains the old role the user is assigned to.
                        String oldUserRoleName = mapUserRolesByIds.get(oldUserRecord.UserRoleId);

                        // EVENT: for activation, deactivation, and role change ONLY
                        if((oldUserRecord.IsActive && !newUserRecord.IsActive) || (!oldUserRecord.IsActive && newUserRecord.IsActive) || (oldUserRoleName != newUserRoleName)){

                            // if the user is already existing in the Unit License object, proceed to next logic
                            if(mapUserToUnitLicenses.containsKey(newUserRecord.Id)){

                                // a list of Role Licenses related to the user
                                List<Role_License__c> listUserRoleLicense = mapUserToUnitLicenses.get(newUserRecord.Id);

                                // a map role license name and it's record
                                Map<String, Role_License__c> mapRoleNameToUserLicense = new Map<String, Role_License__c>();

                                // for all Role Name associated to the user, store it in a map
                                for(Role_License__c roleLicense: listUserRoleLicense){
                                    mapRoleNameToUserLicense.put(roleLicense.Role__c, roleLicense);
                                }

                                // if the current User is existing as user look up in the Role License object
                                if(mapUserToUnitLicenseName.containsKey(newUserRecord.Id)){

                                    // a set thatcontains all the role the user has been assigned to.
                                    Set<String> setUserToUnitLicenseName = mapUserToUnitLicenseName.get(newUserRecord.Id);

                                    // if the current role is existing to the set of role names, update the unit license status field to Active and provide a reason
                                    if(setUserToUnitLicenseName.contains(newUserRoleName)){

                                        // set the status to active if the User is activated
                                        String strRoleLicenseStatus = (oldUserRecord.IsActive && !newUserRecord.IsActive) ||  (!oldUserRecord.IsActive && !newUserRecord.IsActive) ? ROLE_LICENSE_STATUS_INACTIVE : ROLE_LICENSE_STATUS_ACTIVE;
                                        // set the reason with an activity message if the User is activated
                                        String strRoleLicenseReason = (oldUserRecord.IsActive && !newUserRecord.IsActive) ||  (!oldUserRecord.IsActive && !newUserRecord.IsActive) ? ROLE_LICENSE_REASON_INACTIVE: ROLE_LICENSE_REASON_ACTIVE;
                                        
                                        // get the role license and map the values, and then add it to the list of role licence for update
                                        Role_License__c existingRoleLicense = mapRoleNameToUserLicense.get(newUserRoleName);
                                        existingRoleLicense.Status__c = strRoleLicenseStatus;
                                        existingRoleLicense.Reason__c = oldUserRoleName != newUserRoleName ? ROLE_LICENSE_REASON_CHANGE_ROLE_NEW + oldUserRoleName : strRoleLicenseReason;
                                        listUserRoleLicenseToUpdate.add(existingRoleLicense);

                                        // if the role has been changed
                                        if(oldUserRoleName != newUserRoleName){
                                            // identify and get the old role license
                                            if(mapRoleNameToUserLicense.containsKey(oldUserRoleName)){

                                                // set the role license status to inactive and the reason with an inactivity message and map the values
                                                Role_License__c existingOldRoleLicense = mapRoleNameToUserLicense.get(oldUserRoleName);
                                                existingOldRoleLicense.Status__c = ROLE_LICENSE_STATUS_INACTIVE;
                                                existingOldRoleLicense.Reason__c = ROLE_LICENSE_REASON_CHANGE_ROLE_OLD + newUserRoleName;

                                                // then add it to the list of role licence for update
                                                listUserRoleLicenseToUpdate.add(existingOldRoleLicense);
                                            }
                                        }
                                        
                                    }
                                    // else it means that the user exists as a user lookup in the role license object but the new role does not
                                    // hence, create a new Unit License record and provide an activity status and reason and;
                                    // update the old role license
                                    else{
                                        createRoleLicense(mapRoleToParentBusinessUnit, listUserRoleLicenseToInsert, newUserRoleName, newUserRecord.Id, newUserRecord.IsActive, ROLE_LICENSE_REASON_CHANGE_ROLE_NEW + oldUserRoleName);

                                        // if the role has been changed
                                        if(oldUserRoleName != newUserRoleName){
                                            // identify and get the old role license
                                            if(mapRoleNameToUserLicense.containsKey(oldUserRoleName)){

                                                // set the role license status to inactive and the reason with an inactivity message and map the values
                                                Role_License__c existingOldRoleLicense = mapRoleNameToUserLicense.get(oldUserRoleName);
                                                existingOldRoleLicense.Status__c = ROLE_LICENSE_STATUS_INACTIVE;
                                                existingOldRoleLicense.Reason__c = ROLE_LICENSE_REASON_CHANGE_ROLE_OLD + newUserRoleName;

                                                // then add it to the list of role licence for update
                                                listUserRoleLicenseToUpdate.add(existingOldRoleLicense);
                                            }
                                        }
                                    }
                                }
                            }

                            // else it means that the user does not exists as a user lookup in the role license object, hence, creat a new Unit License record and provide an activity status and reason
                            else{
                                createRoleLicense(mapRoleToParentBusinessUnit, listUserRoleLicenseToInsert, newUserRoleName, newUserRecord.Id, newUserRecord.IsActive, ROLE_LICENSE_REASON_ACTIVE);
                            }
                        }
                    }
                }
            }
            
            System.debug('!@#listUserRoleLicenseToInsert: ' + listUserRoleLicenseToInsert);
            System.debug('!@#listUserRoleLicenseToUpdate: ' + listUserRoleLicenseToUpdate);
            // insert the role licenses using an asynchronous call via queueable class
            if(!listUserRoleLicenseToInsert.isEmpty()){
                Queueable queueItem = new UserServices.InsertSobjectsQueueable(listUserRoleLicenseToInsert, false);
                ID jobID = System.enqueueJob(queueItem);
            }

            // update the role licenses using an asynchronous call via queueable class
            if(!listUserRoleLicenseToUpdate.isEmpty()){
                Queueable queueItem = new UserServices.UpdateSobjectsQueueable(listUserRoleLicenseToUpdate);
                ID jobID = System.enqueueJob(queueItem);
            }
        }

        /*******************************************************************************
        * @author       Angelo Rivera
        * @date         02/04/2019
        * @description  Method that retrieves roles in the system
        * @parameter    n/a
        * @return       Map<Id, String> mapUserRolesByIds
        * @revision     1.0
        *******************************************************************************/
        private Map<Id, String> getUserRoleName(){
            Map<Id, String> mapUserRolesByIds = new Map<Id, String>();
            for(UserRole userRole : [Select Id, Name from UserRole]){
                mapUserRolesByIds.put(userRole.Id, userRole.Name);
            }
            return mapUserRolesByIds;
        }

        /*******************************************************************************
        * @author       Russell Cadapan
        * @date         26/04/2019
        * @description  Method that creates a map of role name and it's parent business license id
        * @parameter    n/a
        * @return       Map<String, Id> mapRoleToBusinessUnit
        * @revision     1.0
        *******************************************************************************/
        private Map<String, Id> getParentBusinessUnitByRole(){

            // a map that contains the role name and it's parent business unit id
            Map<String, Id> mapRoleToBusinessUnit = new Map<String, Id>();

            // a map that contains the License Mapping (custom metadata) role name and it's parent Busines License name
            Map<String, String> mapRoleToParent = new Map<String, String>();

            // a map that contains the parent Business License name and it's id 
            Map<String, Id> mapBusinessUnit = new Map<String, Id>();

            // a set that contains License Mapping (custom metadata) Busines License names
            Set<String> setBusinessUnitNames = new Set<String>();


            // get all the license mapping from Salesforce and;
            // 1) store the role name and it's parent business license name in a map
            // 2) store all the parent business license names in a set
            for(License_Mapping__mdt licenseMapping: [SELECT Id, Business_Unit__c, MasterLabel FROM License_Mapping__mdt]){
                mapRoleToParent.put(licenseMapping.MasterLabel, licenseMapping.Business_Unit__c);
                setBusinessUnitNames.add(licenseMapping.Business_Unit__c);
            }

            // using the set of parent business license names stored in a set, get all the business license records that has the same Name as what are in the set
            // then, store the business license name and it's id in a map
            for(Business_License__c businessUnit: [SELECT Id, Name FROM Business_License__c WHERE Name IN: setBusinessUnitNames]){
                mapBusinessUnit.put(businessUnit.Name, businessUnit.Id);
            }

            // for each role name
            for(String s: mapRoleToParent.keySet()){
                // get the parent business id
                if(mapBusinessUnit.containsKey(mapRoleToParent.get(s))){
                    Id parentId = mapBusinessUnit.get(mapRoleToParent.get(s));

                    // store the role name, and the parent business license id in a map
                    mapRoleToBusinessUnit.put(s, parentId);
                }
            }

            // return the map that contains the role name, and its parent business license id
            return mapRoleToBusinessUnit;
        }

        /*******************************************************************************
        * @author       Russell Cadapan
        * @date         26/04/2019
        * @description  Method that creates an instance of Role License object and map the values correspondingly
        * @parameter    Map<String, Id> mapRoleToParentBusinessUnit         - a map of role name and it's parent business unit id (mapping stored in License Mapping custom metadata)
                        List<Role_License__c> listUserRoleLicenseToInsert   - a list of role license object to be created
                        String userRoleName                                 - a string of the user's current role
                        Id userId                                           - an id of the user updated / inserted
                        Boolean isActive                                    - a boolean of user's activity status

        * @return       Map<String, Id> mapRoleToBusinessUnit
        * @revision     1.0
        *******************************************************************************/
        private void createRoleLicense(Map<String, Id> mapRoleToParentBusinessUnit, List<Role_License__c> listUserRoleLicenseToInsert, String userRoleName, Id userId, Boolean isActive, String strReason){
            // an Id of the role's parent business license
            Id parentBusinessLicenseId;

            // get the parent business license id from the License Mapping custom metadata
            if(mapRoleToParentBusinessUnit.containsKey(userRoleName)){
                parentBusinessLicenseId = mapRoleToParentBusinessUnit.get(userRoleName);
            }

            // if there is a parent business license id for the role name, create the role license record. if not, do nothing
            if(parentBusinessLicenseId != null){
                listUserRoleLicenseToInsert.add(new Role_License__c(Role__c = userRoleName, User_Lookup__c = userId, Status__c = isActive ? ROLE_LICENSE_STATUS_ACTIVE : ROLE_LICENSE_STATUS_INACTIVE, Reason__c =  strReason, Parent_Business_Unit__c = parentBusinessLicenseId));
            }
        }
    }
}