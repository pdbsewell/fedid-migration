/**
 * @description       : Service class for AccountMergeWizard LWC
 * @author            : Inderpal Dhanoa
 * @date              : 2021-04-10
 * @group             : Enterprise
 * @last modified on  : 2024-04-17
 * @last modified by  : Sachin Shetty
 * Modifications Log 
 * Date         Author          Modification
 * 2024-04-17 - Sachin Shetty   - Update to point to DBConnect fields
 * 2025-02-19 - Vinothraja      - Removed Debug statements; Added sourcesystemidentifier to the excluded fields; Fixed PMD violations
**/
public without sharing class AccountMergeController {

    private static Set<String> excludedAccountFields = new Set<String> {'ispartner', 'iscustomerportal', 'sourcesystemidentifier'};
    private static Map<String, Object> m_classNameObject = new Map<String, Object>();
    
    /*
     * Method Name: initiateGivingSummary
     * @param  primaryAccountId primary Account ID description
     * Description: method to initiate GivingSummary
    */
    @AuraEnabled
    public static void initiateGivingSummary(Id primaryAccountId){
        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(primaryAccountId);    //-- Add the Account id here
        Map<String, Object> params = new Map<String, Object>();
        params.put('accountIdsToProcessSet', accountIdSet);
        params.put('batchSize', 200);
        ucinn_ascendv2.ascend_UTIL_RunBatch.ascend_GIFT_UpdateGivingSummaryBatch(params);
    }

    /*
     * Method Name: validateEditAccess
     * @param  primaryAccountId primary Account ID description
     * Description: method to initiate GivingSummary
    */
    public static void validateEditAccess(Set<Id> setAllAccountIds){
        List<UserRecordAccess> lstUserAccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId in :setAllAccountIds];
        if(lstUserAccess == null || lstUserAccess.isEmpty()){
            throw new AuraHandledException('You do not have merge access on the Accounts');
        }else{
            for(Id accountId : setAllAccountIds){
                Boolean boolUserHasEditAccess = false;
                for(UserRecordAccess userRecAccess : lstUserAccess){
                    if(userRecAccess.HasEditAccess && userRecAccess.RecordId == accountId){
                        boolUserHasEditAccess = true;
                    }
                }
                if(!boolUserHasEditAccess){
                    throw new AuraHandledException('You do not have merge access on the Account: ' + accountId);
                }
            }
        }
    }
    
    /*
    * Method Name: mergeAccounts
     * @param  primaryAccountId primary Account ID description
     * @param  duplicateAccountId duplicate Account ID description
     * @param initiateGivingSummary boolean parameter to check if givingSummary Job needsto be intiated
     * Description: method to merge 2 Accounts
    */
    @AuraEnabled
    public static Id mergeAccounts(Id primaryAccountId, Id duplicateAccountId, Boolean initiateGivingSummary) { 
        Boolean hasLockRow = false;
        Boolean ownerUpdated= false;
        Id previousOwnerId;
        Account primaryAccount;
        Account duplicateAccount;
        Set<Id> setAllAccountIds = new Set<Id>{primaryAccountId, duplicateAccountId};
        Map<Id, Account> accountMap;
        validateEditAccess(setAllAccountIds);
        
        accountMap = new Map<Id, Account>((List<Account>) queryAllObjectFields(setAllAccountIds));
        try{ 
            primaryAccount = accountMap.get(primaryAccountId);
            previousOwnerId = primaryAccount.OwnerId;
            duplicateAccount = accountMap.get(duplicateAccountId); 
            // Before merging, perform mapping of surviving fields through iteration of custom metadata
            primaryAccount = mapCompareAccount(primaryAccount, duplicateAccount);
            if(previousOwnerId != primaryAccount.OwnerId){
                ownerUpdated = true;
            }else{
                previousOwnerId = duplicateAccount.OwnerId; 
            }
            performMerge(primaryAccount, duplicateAccount, ownerUpdated, primaryAccount.OwnerId, previousOwnerId, initiateGivingSummary);  
        }catch(Exception e) {
            LogUtilityException.logException(e);
            hasLockRow = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
            if(hasLockRow == false) {
                throw e; 
            }else{
                // Implement a retry as possible for Locking due to same parent roll up  delays
                // Merge the Account 
                performMerge(primaryAccount, duplicateAccount, ownerUpdated, primaryAccount.OwnerId, previousOwnerId, initiateGivingSummary);
            }
        }
        return primaryAccountId;
    }


    /**
     * mapCompareAccount Merge Field Values from Account
     * @param  masterAcc masterAcc description
     * @param  childAcc  childAcc description
     */
    public static Account mapCompareAccount(Account masterAcc, Account childAcc) {
        Map<String, Schema.DescribeFieldResult> fieldMetadataMap;
        Account_Merge_Mapping__mdt mdtConfig;

        Map<String, Object> masterFieldsToValue = masterAcc.getPopulatedFieldsAsMap();  
        Map<String, Object> childFieldsToValue = childAcc.getPopulatedFieldsAsMap();
        //Add fields from Master and Child populated
        Set<String> strFields = new Set<String>();
        strFields.addAll(masterFieldsToValue.keySet());
        strFields.addAll(childFieldsToValue.keySet()); 
        Map<String, Account_Merge_Mapping__mdt> mdtAccountMapping = new Map<String, Account_Merge_Mapping__mdt>();
        List<Account_Merge_Mapping__mdt> allMDTPersonMapp = Account_Merge_Mapping__mdt.getall().values();
        for (Account_Merge_Mapping__mdt mdt : allMDTPersonMapp) {
            mdtAccountMapping.put(mdt.SObjectField__c, mdt);
        }
        //Retrieve Populated fields of contacts
        if (mdtAccountMapping.isEmpty() == false && strFields.isEmpty() == false) {

            fieldMetadataMap = populateFieldMetadata(Account.getSObjectType().getDescribe(), strFields);

            for (String sFields : strFields) {
                //Reset the Metadata
                mdtConfig = null;
                // booleans will never be null, only true / false.  so separate logic to handle this data type
                Schema.DescribeFieldResult dfr = fieldMetadataMap.get(sFields);
                if (mdtAccountMapping.containsKey(sFields) && sFields != 'Id') {
                    mdtConfig = mdtAccountMapping.get(sFields);
                }
                //Begin Field Compare and populate
                masterAcc = (Account) fileLevelMapping(sFields,
                                                       dfr,
                                                       masterAcc,
                                                       childAcc,
                                                       mdtConfig,
                                                       mdtConfig?.ClassName__c);
            }
        }
        return masterAcc;
    }

    /**
     * mapCompareAccount Merge Field Values from Account
     * @param  masterAcc masterAcc description
     * @param  childAcc  childAcc description
     */
    @TestVisible
    private static SObject fileLevelMapping(String sFields, 
                                            Schema.DescribeFieldResult dfr,
                                            SObject parentSObj,
                                            SObject targSObj,
                                            Object mdtConfig,
                                            String className) {
        // Metadata exists to govern field merging Rules 
        if(mdtConfig != null && !String.isBlank(className)) { 
            IFieldMerge mergeLogic;
            if(m_classNameObject.containskey(className)){
                mergeLogic = (IFieldMerge) m_classNameObject.get(className);
            }else{
                mergeLogic = (IFieldMerge) System.Type.forName(className).newInstance(); 
                m_classNameObject.put(className, (Object)mergeLogic);
            }
            parentSObj = (SObject)mergeLogic.mergeField(dfr, parentSObj, targSObj);
            
        }// If the child record has values and the parent does not have values then take the Child Record
        else{
            FieldMergeDefault defaultFieldMerge = new FieldMergeDefault();
            parentSObj = (SObject)defaultFieldMerge.mergeField(dfr, parentSObj, targSObj);
        }
        return parentSObj;   
    }

    /**
     * Retrieves map of Field + DescribeFieldResult for Contact, used to determine actions based on field level metadata
     * 
    */
    public static Map<String, Schema.DescribeFieldResult> populateFieldMetadata(
        Schema.DescribeSObjectResult dsor, Set<String> fields) {
        Map<String, Schema.DescribeFieldResult> fieldMetadataMap;
        Map<String, Schema.SObjectField> objectFields = dsor.fields.getMap();

        if (fieldMetadataMap != null) {
            fieldMetadataMap.clear();
        } else {
            fieldMetadataMap = new Map<String, Schema.DescribeFieldResult>();
        }

        // iterate over the requested fields and get the describe info for each one.
        // add it to a map with field name as key
        for(String field : fields) {
            // skip fields that are not part of the object
            if (objectFields.containsKey(field)) {
                Schema.DescribeFieldResult dr = objectFields.get(field).getDescribe();
                // add the results to the map to be returned
                fieldMetadataMap.put(field, dr);
            }
        }
        //
        return fieldMetadataMap;
    }

     /*
    * Method Name: queryAllObjectFields
    * Description: method to query all fields from an sObject
    * Return: List<sObject> - list of sObjects
    */
    public static List<sObject> queryAllObjectFields(Set<Id> recordIds) {

        // get a sample of record id from the param
        Id rId = new List<Id>(recordIds)[0];

        // access schema
        DescribeSObjectResult describeResult = rId.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        // Get all of the fields on the object
        Set<String> fieldNames = fieldMap.keySet();

        if(describeResult.getName() == 'Account') {
            fieldNames.removeAll(excludedAccountFields);
        }
        // Build a Dynamic Query String.
        String soqlQuery = 'SELECT '+ String.join(new List<String>(fieldNames),',')  +' FROM ' + describeResult.getName() + ' WHERE Id IN: recordIds';
        // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
        List<sObject> records = Database.query(soqlQuery);
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, records);
        return securityDecision.getRecords();
    }


     /**
     * performMerge Perform Database Merge Operation
     * @param  primaryObj             primaryObj description
     * @param  dupObj                 dupObj description
     * @param  ownerUpdated           ownerUpdated if the Owner is updated or not
     * @param  newOwnerId             Id of the new Owner
     * @param  previousOwnerId        Id of the prev Owner
     * @param  initiateGivingSummary  boolean to check if the givingSummary needs to be initiated 
     * @param  accountsToBeMerged     count of the no of Accounts pending to be merged 
     */
    @TestVisible
    private static void performMerge(SObject primaryObj, SObject dupObj, Boolean ownerUpdated, Id newOwnerId, Id previousOwnerId, Boolean initiateGivingSummary) {
        try {
            if(primaryObj != null && dupObj != null) {
                Id pId = primaryObj?.Id;
                Id dId = dupObj?.Id;
                Map<Id, List<AccountTeamMember>> mapRelatedTeamMembers = getTeamMembers(pId, dId);
                Map<Id, List<TopicAssignment>> mapRelatedTopicAssignments = getRelatedTopics(pId, dId);
                if(pId != dId && pId != null && dId != null) {
                    Database.merge(primaryObj, new List<SObject> {dupObj}, true);
                    // Upsert on Account Team members based on Scenarios (Owner update, no Owner Update) 
                    if(!mapRelatedTeamMembers.isEmpty()){
                        if(ownerUpdated){
                            // If owner is updated then the Members get Deleted and need to be re-Inserted
                            checkAndReInsertAccountTeamMembers(pId, dId, mapRelatedTeamMembers, newOwnerId, previousOwnerId);
                        }else{
                            // If owner is not-updated , the losing Owner of the Duplicate record needs to be added as a Team member
                            updateSecondaryAccountTeamMembers(pId, dId, mapRelatedTeamMembers, newOwnerId, previousOwnerId);
                        }                        
                    }
                    // Insert on Topic Assignments 
                    if(!mapRelatedTopicAssignments.isEmpty()){
                        // After merge the TopicAssignments are to be re-linked to Surviving Account
                        checkAndReInsertTopicAssignments(pId, dId, mapRelatedTopicAssignments, newOwnerId, previousOwnerId);                        
                    }
                    // After merging the last Account, initiate the Giving Sumary Batch Job 
                    if(initiateGivingSummary){
                        initiateGivingSummary(pId);
                    }
                }                
            }
        } catch(Exception e) {
            LogUtilityException.logException(e);
            throw e;
        }
    }

     /**
     * getRelatedTopics to get the related topics 
     * @param  primaryAccountId       primaryAccountId description of survivor Account Id
     * @param  secondaryAccountId     secondaryAccountId description of duplicate Account Id 
     */
    public static Map<Id, List<TopicAssignment>> getRelatedTopics(Id primaryAccountId, Id secondaryAccountId){
        Map<Id, List<TopicAssignment>> mapRelatedTopicAssignments = new Map<Id, List<TopicAssignment>>();
        for(TopicAssignment relTopic : [SELECT EntityId,Id,EntityType,EntityKeyPrefix,NetworkId,TopicId FROM TopicAssignment WHERE EntityId = :primaryAccountId OR EntityId = :secondaryAccountId]){
            List<TopicAssignment> lstRelatedTopicAssignments = mapRelatedTopicAssignments.get(relTopic.EntityId); 
            if(lstRelatedTopicAssignments != null && !lstRelatedTopicAssignments.isEmpty()){
                lstRelatedTopicAssignments.add(relTopic);
            }else{
                lstRelatedTopicAssignments = new List<TopicAssignment>();
                lstRelatedTopicAssignments.add(relTopic);
            }
            mapRelatedTopicAssignments.put(relTopic.EntityId, lstRelatedTopicAssignments);
        }
        return mapRelatedTopicAssignments;    
    }

    /**
     * deleteAccountTeamMember after merge delete non Human profiles team members  
     * @param  lstPrimaryTeamMember      lstPrimaryTeamMember description list of Team Members of primary team members
     * @param  lstSecondaryTeamMember    lstSecondaryTeamMember description list of Team Members of secondary team members
     * @param  currentMember             currentMember current of Team Member 
     */
    public static Boolean deleteAccountTeamMember(List<AccountTeamMember> lstPrimaryTeamMember, List<AccountTeamMember> lstSecondaryTeamMember, AccountTeamMember currentMember){
        if(lstPrimaryTeamMember != null && !lstPrimaryTeamMember.isEmpty()){
            for(AccountTeamMember primaryTeamMemb : lstPrimaryTeamMember){
                if(primaryTeamMemb.UserId == currentMember.UserId){
                    return false;
                }    
            } 
        }
        if(lstSecondaryTeamMember != null && !lstSecondaryTeamMember.isEmpty()){
            for(AccountTeamMember secondaryTeamMemb : lstSecondaryTeamMember){
                if(secondaryTeamMemb.UserId == currentMember.UserId && !humanUserProfile((String)secondaryTeamMemb.User.Profile.Name)){
                    return true;
                }    
            } 
        }
        return false;
    }

    /**
     * deleteAccountTeamMember after merge delete non Human profiles team members  
     * @param  primaryAccountId                      primaryAccountId description of survivor Account Id
     * @param  secondaryAccountId                    secondaryAccountId description of duplicate Account Id
     * @param  mapRelatedTopicAssignments            Map of topics related to surviving & duplicate account 
     * @param  newOwnerId                            newOwnerId Owner Id of the surviving Account
     * @param  previousOwnerId                       previousOwnerId Owner Id of the duplicate Account 
     */
    public static void checkAndReInsertTopicAssignments(Id primaryObjId, Id duplicateObjId, Map<Id, List<TopicAssignment>> mapRelatedTopicAssignments, Id newOwnerId, Id previousOwnerId){
        List<TopicAssignment> lstInsertTopicAssignment = new List<TopicAssignment>();
        List<TopicAssignment> lstSecondaryTopicAssignment = mapRelatedTopicAssignments.get(duplicateObjId);
        List<TopicAssignment> lstPrimaryTopicAssignment = mapRelatedTopicAssignments.get(primaryObjId);

        if(lstSecondaryTopicAssignment != null && !lstSecondaryTopicAssignment.isEmpty()){
            for(TopicAssignment secondaryTopicAssgn : lstSecondaryTopicAssignment){
                Boolean boolTopicExistsOnPrimary = false;
                // Insert the previously deleted sec Team Members, 
                // Do not insert duplicate Members
                if(lstPrimaryTopicAssignment != null && !lstPrimaryTopicAssignment.isEmpty()){
                    for(TopicAssignment primaryTopicAssgn : lstPrimaryTopicAssignment){
                        // Insert the previously deleted prim Team Members
                        if(secondaryTopicAssgn.TopicId == primaryTopicAssgn.TopicId){
                            boolTopicExistsOnPrimary = true;    
                        }
                    } 
                }
                if(!boolTopicExistsOnPrimary){
                    TopicAssignment insertSecondaryTopic = new TopicAssignment(EntityId = primaryObjId, NetworkId = secondaryTopicAssgn.NetworkId, TopicId = secondaryTopicAssgn.TopicId);
                    lstInsertTopicAssignment.add(insertSecondaryTopic);
                }
            } 
        }
        // If the Owner of the Master record is losing Ownership of the Record, then he should be retained as a Team Member
        if(!lstInsertTopicAssignment.isEmpty()){
            insert lstInsertTopicAssignment;
        } 
    }


    /**
     * Checks all the Secondary Account team Members after merge and then updates their Team Member Role, Access Level
     * /**
     * performMerge Perform Database Merge Operation
     * @param  primaryObjId                 primaryObj Id
     * @param  duplicateObjId               duplicateObjId Id
     * @param  mapRelatedTeamMembers         Map of Account Id and AccountTeamMembers of both Accounts
     * @param  newOwnerId                   newOwnerId, survivor Account Owner Id
     * @param  previousOwnerId              previousOwnerId, duplicate Account Owner Id
     */
    public static void updateSecondaryAccountTeamMembers(Id primaryObjId, Id duplicateObjId, Map<Id, List<AccountTeamMember>> mapRelatedTeamMembers, 
                                                         Id newOwnerId, Id previousOwnerId){
        List<AccountTeamMember> lstAllTeamMemb = new List<AccountTeamMember>();
        List<AccountTeamMember> lstDeleteTeamMemb = new List<AccountTeamMember>();
        List<AccountTeamMember> lstSecondaryTeamMember = mapRelatedTeamMembers.get(duplicateObjId);
        List<AccountTeamMember> lstPrimaryTeamMember = mapRelatedTeamMembers.get(primaryObjId);
        Boolean boolLosingOwnerExists = false;
    
        lstAllTeamMemb = [SELECT Id, UserId, User.Profile.Name, AccountId, AccountAccessLevel, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :primaryObjId];
        if(!lstAllTeamMemb.isEmpty()){
            for(AccountTeamMember teamMemb : lstAllTeamMemb){
                // Check if Secondary Team Member had a Non Human Profile then Delete this new Incoming team member from the Primary Account's team Members
                if(!humanUserProfile(teamMemb.User.Profile.Name) ){
                    if(deleteAccountTeamMember(lstPrimaryTeamMember, lstSecondaryTeamMember, teamMemb)){
                        lstDeleteTeamMemb.add(teamMemb);
                    }
                }                
                if(teamMemb.UserId == previousOwnerId && newOwnerId != previousOwnerId){//&& humanUserProfile(teamMemb.User.Profile.Name)
                    boolLosingOwnerExists = true;
                }  
            }
        }
        // If the Owner of the losing Record is a Human Profile, he should be retained as a Team Member on the Surviving Record
        if(!boolLosingOwnerExists && humanUserProfileCheck(previousOwnerId) && newOwnerId != previousOwnerId){
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.UserId = previousOwnerId;
            newAccTeamMember.AccountAccessLevel = 'Read' ;
            newAccTeamMember.AccountId = primaryObjId;
            newAccTeamMember.TeamMemberRole = 'Account Team Member';
            insert newAccTeamMember; 
        } 
        // Delete the team Members which are added from Duplicate Account and the team Members have non-Human profiles
        if(!lstDeleteTeamMemb.isEmpty()){
            delete lstDeleteTeamMemb;
        }
    }

    /**
     * Checks all the Secondary Account team Members after merge and then updates their Team Member Role, Access Level
     * /**
     * performMerge Perform Database Merge Operation
     * @param  primaryObjId                      primaryObj Id
     * @param  duplicateObjId                    duplicateObjId Id
     * @param  mapRelatedTeamMembers              Map of Account Id and AccountTeamMembers 
     * @param  newOwnerId                        Updated Owner Id of the Master Record
     * @param  previousOwnerId                   previous OwnerId, duplicate Account Owner Id
     */
    public static void checkAndReInsertAccountTeamMembers(Id primaryObjId, Id duplicateObjId, Map<Id, List<AccountTeamMember>> mapRelatedTeamMembers, 
                                                          Id newOwnerId, Id previousOwnerId){
        List<AccountTeamMember> lstInsertTeamMember = new List<AccountTeamMember>();
        List<AccountTeamMember> lstSecondaryTeamMember = mapRelatedTeamMembers.get(duplicateObjId);
        List<AccountTeamMember> lstPrimaryTeamMember = mapRelatedTeamMembers.get(primaryObjId);
        Boolean boolLosingOwnerExists = false;

        if(lstPrimaryTeamMember != null && !lstPrimaryTeamMember.isEmpty()){
            for(AccountTeamMember primaryTeamMemb : lstPrimaryTeamMember){
                // Insert the previously deleted Prim Team Members
                AccountTeamMember newAccTeamMember = new AccountTeamMember();
                newAccTeamMember.UserId = primaryTeamMemb.UserId;
                newAccTeamMember.AccountAccessLevel = primaryTeamMemb.AccountAccessLevel;
                newAccTeamMember.AccountId = primaryObjId;
                newAccTeamMember.TeamMemberRole = primaryTeamMemb.TeamMemberRole;
                lstInsertTeamMember.add(newAccTeamMember);
                if(previousOwnerId == primaryTeamMemb.UserId){
                    boolLosingOwnerExists = true;
                }
            } 
        }

        if(lstSecondaryTeamMember != null && !lstSecondaryTeamMember.isEmpty()){
            for(AccountTeamMember secondaryTeamMemb : lstSecondaryTeamMember){
                // Insert the previously deleted sec Team Members, 
                // Do not insert duplicate Members
                if(!duplicateExists(secondaryTeamMemb.UserId, lstInsertTeamMember) && humanUserProfile(secondaryTeamMemb.User.Profile.Name) ){ 
                    AccountTeamMember newAccTeamMember = new AccountTeamMember();
                    newAccTeamMember.UserId = secondaryTeamMemb.UserId;
                    newAccTeamMember.AccountAccessLevel = secondaryTeamMemb.AccountAccessLevel ;
                    newAccTeamMember.AccountId = primaryObjId;
                    newAccTeamMember.TeamMemberRole = secondaryTeamMemb.TeamMemberRole; 
                    lstInsertTeamMember.add(newAccTeamMember);
                }
                // Add the losing Owner as a Team Member && Do not re-insert losing team account team Member
                if(!boolLosingOwnerExists && previousOwnerId == secondaryTeamMemb.UserId){
                    boolLosingOwnerExists = true;
                }
            } 
        }
        // If the Owner of the Master record is losing Ownership of the Record, then he should be retained as a Team Member
        if(!boolLosingOwnerExists && humanUserProfileCheck(previousOwnerId)){
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.UserId = previousOwnerId;
            newAccTeamMember.AccountAccessLevel = 'Read' ;
            newAccTeamMember.AccountId = primaryObjId;
            newAccTeamMember.TeamMemberRole = 'Account Team Member';
            lstInsertTeamMember.add(newAccTeamMember);
        }
         insert lstInsertTeamMember;        
    }

     /**
     * Checks if duplicate User exists and reverts with Boolean Value
     * /**
     * @param  existingUserId                   Id for existingUser 
     * @param  insertTeamMembers                List of the AccountTeamMembers 
     * @param  Boolean                          returns check if User already exists
     */
    public static Boolean duplicateExists(Id existingUserId, List<AccountTeamMember> insertTeamMembers) {
        for(AccountTeamMember accteamMemb : insertTeamMembers){
            if(accteamMemb.UserId == existingUserId){
                return true;
            }
        }
        return false;
    }

     /**
     * Checks if User has a system profile, reverts with Boolean Value
     * /**
     * @param  userId                           Id for existingUser 
     * @param  Boolean                          returns check if User already exists
     */
    public static Boolean humanUserProfileCheck(Id userId) {
        List<User> selectedUser = [SELECT Id, Profile.name FROM USER WHERE Id = :userId];
        if(selectedUser != null && !selectedUser.isEmpty()){
            String strProfileName = selectedUser[0].Profile.Name;
            if(strProfileName == 'System Administrator' || strProfileName.contains('Integration')){
                return false;
            }
        }
        return true;
    }

    /**
     * Checks if User has a system profile, reverts with Boolean Value
     * /**
     * @param  profileName                      Name of the profile 
     * @param  Boolean                          returns check if User already exists
     */
    public static Boolean humanUserProfile(String profileName) {
        if(profileName == 'System Administrator' || profileName.contains('Integration')){
            return false;
        }
        return true;
    }

     /**
     * Gets the list of all the related team members based on Account Id of primary and Secondary User
     * /**
     * @param  primaryAccountId                    Id for primaryAccount User 
     * @param  secondaryyAccountId                 Id for secondary Account User 
     * @param  Map                                 returns Map<Id, List<AccountTeamMember>> of AccountId and List<AccountTeamMember>
     */
    public static Map<Id, List<AccountTeamMember>> getTeamMembers(Id primaryAccountId, Id secondaryyAccountId) {
        Map<Id, List<AccountTeamMember>> mapRelatedAccountMembers = new Map<Id, List<AccountTeamMember>>();
        for(AccountTeamMember accteamMemb : [SELECT Id, UserId,User.Profile.Name,AccountId,TeamMemberRole,AccountAccessLevel,Account.OwnerId FROM AccountTeamMember WHERE AccountId = :primaryAccountId OR AccountId = :secondaryyAccountId]){
            List<AccountTeamMember> lstRelatedAccountMembers = mapRelatedAccountMembers.get(accteamMemb.AccountId); 
            if(lstRelatedAccountMembers != null && !lstRelatedAccountMembers.isEmpty()){
                lstRelatedAccountMembers.add(accteamMemb);
            }else{
                lstRelatedAccountMembers = new List<AccountTeamMember>();
                lstRelatedAccountMembers.add(accteamMemb);
            }
            mapRelatedAccountMembers.put(accteamMemb.AccountId, lstRelatedAccountMembers);
        }
        return mapRelatedAccountMembers;
    }

        /*
    * Method Name: getEntityData
    * Description: method to get records from the data wrapper 
    */
    @AuraEnabled
    public static AccountMergeWrapper getEntityData(Id onLoadAccountId) {
        try{
            AccountMergeWrapper accountMergeWrapper = new AccountMergeWrapper();
            accountMergeWrapper.isAdminUser = false;
            List<AccountWrapper> lstRelatedAccounts = new List<AccountWrapper>();   
            Set<Id> setAccountIds = new Set<Id>();
            Set<Id> setAccessAccountIds = new Set<Id>(); 
            setAccountIds.add(onLoadAccountId);
            Map<Id, Account> mapDuplicateAccountIds = findDuplicateAccounts(setAccountIds); 
            for(UserRecordAccess userRecAccess : [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId in :mapDuplicateAccountIds.keyset()]){
                if(userRecAccess.HasEditAccess){
                    setAccessAccountIds.add(userRecAccess.recordId);
                }
            }
            for (PermissionSetAssignment psa: [SELECT Id,PermissionSet.Name,AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId()]){
                if(psa.PermissionSet.Name.equals('AccountMerge')){
                    accountMergeWrapper.isAdminUser = true;
                }
            }
            List<Account> lstAllAccounts = [SELECT Id, Name, DBC_DUNS_Number__c, BillingAddress, Website, SicDesc, Owner.Name 
                                           FROM Account 
                                           WHERE Id in :setAccessAccountIds OR Id = :onLoadAccountId];
            if(!lstAllAccounts.isEmpty()){
                for(Account acc : lstAllAccounts){ 
                    if(acc.Id == onLoadAccountId){
                        AccountWrapper accWrap = new AccountWrapper();
                        accWrap.isPrimary = true;
                        accWrap.isIncluded = true;
                        accWrap.id = acc.Id;
                        accWrap.name = acc.Name;
                        Address billingAddress = acc.BillingAddress;
                        accWrap.mailingAddress = getAddress(acc.BillingAddress);
                        accWrap.website = acc.WebSite;
                        accWrap.industryClassification = acc.SicDesc;
                        accWrap.owner = acc.Owner.Name;
                        accWrap.dunsNumber = acc.DBC_DUNS_Number__c;
                        lstRelatedAccounts.add(accWrap);
                        break;
                    } 
                }
                for(Account acc : lstAllAccounts){
                    if(acc.Id != onLoadAccountId){
                        AccountWrapper accWrap = new AccountWrapper();
                        accWrap.isPrimary = false;
                        accWrap.isIncluded = false;
                        accWrap.id = acc.Id;
                        accWrap.name = acc.name;
                        accWrap.mailingAddress = getAddress(acc.BillingAddress);
                        accWrap.website = acc.WebSite;
                        accWrap.industryClassification = acc.SicDesc;
                        accWrap.owner = acc.Owner.Name;
                        accWrap.dunsNumber = acc.DBC_DUNS_Number__c;
                        lstRelatedAccounts.add(accWrap);
                    } 
                }
            }
            accountMergeWrapper.relatedAccounts = lstRelatedAccounts;
            return accountMergeWrapper;//lstRelatedAccounts;
        } catch(Exception e) {
            LogUtilityException.logException(e);
            throw e;
        }
    }

    /*
    * Method Name: getAddress
    * Description: method to get the details of the Address
    * Return: String of City and Country
    */
    public static String getAddress(Address billingAddress){
        String extractedAddress = '';
        if(String.valueOf(billingAddress) != null && String.valueOf(billingAddress) != ''){//
            if(billingAddress.getCity() != null && billingAddress.getCity() != ''){
                extractedAddress = billingAddress.getCity();
            }
            if(billingAddress.getCountry() != null && billingAddress.getCountry() != ''){ 
                extractedAddress = extractedAddress + ', ' + billingAddress.getCountry(); 
            }
        }
        return extractedAddress;
    }

    /*
    * Method Name: findDuplicateContacts
    * Description: method to find duplicates and their match confidence
    * Return: Map<Id, Decimal> - map of duplicate Account id and Record
    */
    @SuppressWarnings('PMD.AvoidDebugStatements')
    public static Map<Id, Account> findDuplicateAccounts(Set<Id> accountIds){
        Map<Id, Account> mapConfidence = new Map<Id,Account>();
        try {
            List<Datacloud.FindDuplicatesResult> duplicateResult = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(new List<Id>(accountIds));
            if(!duplicateResult.isEmpty()){
                for (Datacloud.FindDuplicatesResult findDupeResult : duplicateResult) {
                    for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                            for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                mapConfidence.put(matchRecord.getRecord().Id, (Account)matchRecord.getRecord());
                            }
                        }
                    }
                }
            }
        } catch(System.HandledException exc) {
            // no action, this exception only occurs if there aren't any (active) duplication rules in the org
        } catch (Exception e) {
            // throw any other error
            throw(e);
        }
        return mapConfidence;
    }
    
    public class AccountMergeWrapper{
        @AuraEnabled
        public Boolean isAdminUser;
        @AuraEnabled
        public List<AccountWrapper> relatedAccounts;
    }

    public class AccountWrapper{
        @AuraEnabled
        public Boolean isPrimary;
        @AuraEnabled
        public Boolean isIncluded;
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String mailingAddress;
        @AuraEnabled
        public String website;
        @AuraEnabled
        public String industryClassification;
        @AuraEnabled
        public String dunsNumber;
        @AuraEnabled
        public String owner;
    }
}