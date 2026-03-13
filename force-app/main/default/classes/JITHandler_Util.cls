/*------------------------------------------------------------
Author:         Author
Company:        Monash
Description:    Utilities class for JIT provisioning
Inputs:        
Test Class:    JITHandler_Util_Test

History
18/12/2017      Gabriel Ludik (GL)  Created 
------------------------------------------------------------*/
public without sharing class JITHandler_Util {
    
    private class JitUtilException extends Exception{}
    
    //Get profile Id
    //--------------
    public static Profile getProfile (String profileName){
            
        	System.debug('JITHandler_Util  get profile - name=' + profileName);
            
        	Profile baseProfile;
            
        	if (profileName != null && profileName != '' ) {
                baseProfile = [SELECT Id,name FROM Profile where name = :profileName];
            }
            
            return baseProfile;
        
    }
    
    //Assign permission set
    //---------------------
    public static void assignPermissionSet (Id assignPermissionSet, Id userId){
        
        try {
            
            System.debug('JITHandler_Util assignPermissionSet - assignPermissionSet=' + assignPermissionSet + ' :userId=' +userId);
            
            if (assignPermissionSet != null && userId != null ) {
            	List<PermissionSetAssignment> listpsa = new List<PermissionSetAssignment>();
                listpsa = [SELECT Id FROM PermissionSetAssignment where PermissionSetId = :assignPermissionSet and AssigneeId = :userId]; 
                if (listpsa.isEmpty()) {
                    System.debug('JITHandler_Util assignPermissionSet - inserting PermissionSetAssignment');
                    PermissionSetAssignment psa = new PermissionSetAssignment
                                (PermissionSetId = assignPermissionSet, AssigneeId = userId);
                    insert psa; 
                    System.debug('JITHandler_Util  assignPermissionSet - after insert PermissionSetAssignment Id=' + psa.Id);
                } 
            }
        }
        
        Catch(Exception e){
            throw new JitUtilException('JITHandler_Util  - An error occurred assignPermissionSet. The error message is: ' + e.getMessage());
        }
    }
    
    //Assign permission set - ASYNC
    //-----------------------------
    @future
    public static void assignPermissionSetAsync (string communityName, string role, Id userId){

        try {

            System.debug('JITHandler_Util assignPermissionSetAsync - communityName=' + communityName + ' :role=' +role + ' :userId' + userId);

            //Gets the permission set based on community name & role
            Map<Id, String> mapPermissionSets = new Map<Id, String>();
            mapPermissionSets = getCommunityPermissions(communityName, role);

            //Add permissionsets to user
            if(!mapPermissionSets.isEmpty()){
                // list of community permission set assignments to be inserted
                List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();

                // find all existing permission sets assigned to the user and store in a set
                Set<Id> existingPermissionSetIds = new Set<Id>();
                for(PermissionSetAssignment psa: [SELECT Id, PermissionSetId FROM PermissionSetAssignment where AssigneeId = :userId]){
                    existingPermissionSetIds.add(psa.PermissionSetId);
                }

                // iterate through the community permission sets and validate if the assignment exists
                for(Id key: mapPermissionSets.keySet()){
                    // if the community permission set is not assigned, create a permission set assignment
                    if(!existingPermissionSetIds.contains(key)){
                        psaList.add(new PermissionSetAssignment(PermissionSetId = key, AssigneeId = userId));
                    }
                }

                if(!psaList.isEmpty()){
                    insert psaList;
                }
            }

            //Change profile of user
            Profile baseProfile = [SELECT Id,name FROM Profile where name = 'Customer Community General User'];
            User usr = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey, ProfileId FROM User WHERE Id=:userId];
            usr.ProfileId = baseProfile.Id ;
            update usr;
        }

        Catch(Exception e){
            throw new JitUtilException('JITHandler_Util - An error occurred assignPermissionSet. The error message is: ' + e.getMessage());
        }
    }
    
    //Community Object
    //----------------
    public static Network getCommunity (Id communityId){
        
        System.debug('JITHandler_Util get communityId - communityId=' + communityId);
        
        Network community;
        if (communityId != null ) {
            community = [SELECT Id,Name FROM Network where Id = :communityId];
        }
                                    
        return community;
        
    }
    
    //Build all the permissionsets for a community and the contact role
    //------------------------------------------------------------------
    public static Map<Id, string> getCommunityPermissions (string communityName, string role) {

        System.debug('JITHandler_Util get permission set - communityName=' + communityName + ' role=' + role);

        Map<Id, String> mapPermissionSets = new Map<Id, String>();

        If (communityName != null && role != null) {
            Set<String> permissionSetNames = new Set<String>();

            for (Community_Profiles_Permissions__mdt cpp: [SELECT Id, Permission_Set_Name__c FROM Community_Profiles_Permissions__mdt where Community_Name__c = :communityName and Role__c = :role ]) {
                System.debug('JITHandler_Util get permission set - Id=' + cpp.Id + ' name=' + cpp.Permission_Set_Name__c);
                permissionSetNames.add(cpp.Permission_Set_Name__c);
            }

            if(!permissionSetNames.isEmpty()){
                for (PermissionSet ps: [SELECT Id,Name FROM PermissionSet where Name IN : permissionSetNames]) {
                    mapPermissionSets.put(ps.Id, ps.Name);
                }
            }
        }

        return mapPermissionSets;
    }

    //Build the profile for a community and the contact role
    //------------------------------------------------------
    public static Map<string, string> getCommunityProfile (string communityName, string role) {
        
        System.debug('JITHandler_Util getCommunityProfile - communityName=' + communityName + ' role=' + role);
        
        Map<string, string> mapProfiles = new Map<string, string>();
        
        If (communityName != null && role != null) {
            	Community_Profiles_Permissions__mdt cpp = [SELECT Id, Profile_Name__c, Temp_Profile_Name__c FROM 
                                                                                  Community_Profiles_Permissions__mdt where 
                                                                                  Community_Name__c = :communityName and Role__c = :role];
            	mapProfiles.put('Temp_Profile_Name__c', cpp.Temp_Profile_Name__c);
            	mapProfiles.put('Profile_Name__c', cpp.Profile_Name__c);
       }
        
        System.debug('JITHandler_Util getCommunityProfile - profiles=' + mapProfiles);
        
        return mapProfiles;
    }
    
}