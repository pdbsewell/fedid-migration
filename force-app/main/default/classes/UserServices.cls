/**
 * @author          Carl Vescovi, PwC
 * @group           Trigger Handler
 * @description     Trigger Handler class to provide User sObject centric logical support
 * @revision        
 *  initial    - Carl Vescovi - initial version
 *  2017-04-02 - Ant Custodio - Added trigger handler logic to map user details to contact (for community users)
 *  2019-02-15 - Stefan Scheit - Added trigger handler logic to assign detault permission sets to community users
 *  2019-10-30 - KEvasco (GrowthOps) - Added auto permission set assignment for Einstein Discovery Writeback
 *  2020-07-28 - Stefan Scheit - Updated AssignPermissionSets to differentiate between staff and student community users
 *  2021-03-22   Steffi  Narang  Updated AssignPermissionSets to assigned Alumin portal permission set   (PENGAGE-1710)
 *  2021-04-05 - Vinothraja Added SyncAssociatedPartnerContact method to Sync Partner portal user details with associated contact
 *  2021-06-01   Steffi  Narang  Updated AssignPermissionSets to assigned Alumin portal permission set  Removed dependency for ERDA permisison set  (PENGAGE-1867)
 *  2021-07-30   P.Victoriano - Remove Communities Filter on Permission Set Assignment and Clean up exception handling
 *  2021-08-15   P.Victoriano - Fixes for extra exception logging - Fix Mixed DML logic [EPCP-1597] 
 *  2021-10-10 - Peter Sewell - Assign MFA enforcement permission set to users in SIT and STAGING [EPCP-1667]
 *  2021-11-01 - Peter Sewell - Sync auditable inserts and updates to User record to UserShadow object for tracking of field changes
 *  2023-11-01 - Matthew Maramot - Uplifted AssignPermSet method to use bindExtended framework
 *  2023-07-03 - Peter Sewell - Set MFA_Mobile_Verified_External__c to false if MobilePhone is updated 
 *  2024-10-10 - Angelo rivera - Rolls up Username from User object to Contact record
 */
public without sharing class UserServices {
    
    //My Information Default Setting - Enquiry Type
    public static final String CURRENT_STUDENT_VALUE = 'Current Course';
    public static final String FUTURE_STUDENT_VALUE = 'Future Course';

    //My Information Default Setting - Origin
    public static final String BACK_OFFICE_GENERAL = 'Back Office - General';
    public static final String FACE_TO_FACE_ORIGIN = 'Face to Face';
    public static final String PHONE_ORIGIN = 'Phone';

    //My Information Default Setting - User's Queue values
    public static final String CURRENT_STUDENT = 'Current Student';
    public static final String FUTURE_STUDENT = 'Future Student';

    public static final String PHONE = 'Phone & Online';
    public static final String FACE_TO_FACE = 'Face to Face & Online';
    
    // Standard customer community profile
    public static final String CUSTOMER_COMMUNITY_PROFILE_COMMON = Label.Customer_Community_General_User;
    
    /*******************************************************************************
    * @author       Peter Sewell
    * @date         03/07/2023
    * @description  Set MFA_Mobile_Verified_External__c to false if MobilePhone is changed, 
    *               indicating number is no longer verified by external SMS verification service
    *               
    *******************************************************************************/
    public class ClearVerifiedMobileFlagOnMobileChange extends TriggerAbstract {

        // UPDATE
        public override void process(SObject record, SObject oldRec) {
            User userRecord = (User)record;
            User oldUserRecord = (User)oldRec;
            // Look for records where mobile has been updated
            if(CommonUtilities.fieldHasChanged('MobilePhone', userRecord, oldUserRecord)){
                records.add(userRecord);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            for(User usr:(List<User>) records) {
                usr.MFA_Mobile_Verified_External__c = false; // Indicate mobile is no longer user verified
            }
        }
    }

    /*******************************************************************************
    * @author       Matthew Maramot
    * @date         11/01/2023
    * @description  Default handler of Permission Set assignments for Users
    *               
    *******************************************************************************/
    public class AssignPermissionSets extends TriggerAbstract {

        private List<User> userList = new List<User>();
        Map<Id, User> oldUserMap = new Map<Id, User>();
                
        public override void process(SObject record) {
            User userRecord = (User)record;
            if(userRecord.isActive){
                userList.add(userRecord);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            User userRecord = (User)record;
            User oldUserRecord = (User)oldRec;
            if(userRecord.isActive){
                oldUserMap.put(oldUserRecord.Id, oldUserRecord);
                userList.add(userRecord);
            }
        }

        public override void execute() {
            try {
                if(userList.isEmpty() == false){
                    UserUtility.AssignPermissionSets(userList, OldUserMap);
                }
            }
            catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }
    
    /*******************************************************************************
    * @author       Stefan Scheit
    * @date         20/02/2018
    * @description  Class supporting the logic to be queued (asynchronously)
    * @revision
    *  2021-11-01 - Stefan Scheit - Change error logging to support standard framework (to avoid MIXED_DML_OPERATION errors) if updates on configuration records fail.
    *******************************************************************************/
    public class UpdateSobjectsQueueable implements Queueable {
        // List of Sobjects to be udpated
        private List<SObject> sobjects;

        public UpdateSobjectsQueueable(List<SObject> sobjects) {
            this.sobjects = sobjects;
        }
        // main method implementing the interface method
        public void execute(QueueableContext context) {
            try {
                Database.update(this.sobjects, true);
            } catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
                nebula.logger.error(ex.getmessage(), sobjects);
            } finally {
                nebula.logger.saveLog();
            } 
        }
    }
    /*******************************************************************************
    * @author       Stefan Scheit
    * @date         26/02/2019
    * @description  Class supporting the logic to be queued (asynchronously)
    * @revision     1.0
    *  2021-04-26 - Steffi Narang - PENGAGE-1819
    *  2021-11-15 - Stefan Scheit - Change error logging to support standard framework (to avoid MIXED_DML_OPERATION errors) if updates on configuration records fail.
    *******************************************************************************/
    public class InsertSobjectsQueueable implements Queueable {
        // List of Sobjects to be udpated
        private List<SObject> sobjects;
        private Boolean bAllOrNothing;

        public InsertSobjectsQueueable(List<SObject> sobjects, Boolean bAllOrNothing) {
            Set<sobject> myset = new Set<sobject>();
            List<sobject> result = new List<sobject>();
            myset.addAll(sObjects);
            result.addAll(myset);
            
            this.sobjects = result;
            this.bAllOrNothing = bAllOrNothing;            
        }
        // main method implementing the interface method
        public void execute(QueueableContext context) {
            try{
                Database.SaveResult[] srList = Database.insert(this.sobjects, this.bAllOrNothing);
                for (integer i=0 ;i<srList.size(); i++) {
                    if (!srList[i].isSuccess()) {
                        // Operation failed, so get all errors
                        for (Database.Error err: srList[i].getErrors()) {
                            if (!err.getMessage().contains('Duplicate PermissionSetAssignment')) {
                                nebula.logger.error(err.getMessage(),srList[i]);
                            }
                        }
                    }
               }

            } catch(Exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
                nebula.logger.error(ex.getMessage(), sobjects);
            } 
        }
    }

    /**
    * user details specific to console user settings
    */
    public static Map<Id, User> usersMap(Set<Id> userIds) {
        return new Map<Id, User>([
            select id, Enquiry_Role__c, Location__c, Profile.Name, My_Information_LastUpdate__c, Default_Enquiry_Record_Type__c, Queue__c
            from User
            where id in:userIds
        ]);
    }

    /** 
    * cached context user details
    */
    public static User contextUser {
        get {
            if (contextUser == null) {
                contextUser = usersMap(new Set<Id>{
                        UserInfo.getUserId()
                }).get(UserInfo.getUserId());
            }
            return contextUser;
        }
        private set;
    }

    /**
    * map of user and queue names to id
    * @return map of user or group id to name - so aggregates both into a single map
    */
    public static Map<id, string> userOrGroupName {
        get {
            if (userOrGroupName == null) {
                userOrGroupName = new Map<id, string>();
                for (User u : [select id,firstname,lastname from User limit 1000]) {
                    string fn = (u.firstname == null) ? '' : u.firstname;
                    userOrGroupName.put(u.id, fn + ' ' + u.lastname);
                }
                for (Group grp : [select id, name from Group where Type = 'Queue']) {
                    userOrGroupName.put(grp.id, grp.name);
                }
            }
            return userOrGroupName;
        }
        set;
    }

    /** returns a map of role name by user id */
    public static Map<id, string> userRoleName {
        get {
            if (userRoleName == null) {
                userRoleName = new Map<id, string>();
                for (list<user> uList : [select id, userrole.name from user where userrole.name != null limit 3000]) {
                    for (user u : uList) userRoleName.put(u.id, u.userrole.name);
                }
            }
            return userRoleName;
        }
        set;
    }


    /**
     * update user records in the without sharing context
     * @param users list of user records to update
     */
    public static void updateUsers(list<user> users) {
        update users;
    }

    /**
    * @author Herman Castano
    * @date 05/02/2020
    * @description creates a list of permSets required for a CC user to be able to accept offers
    * @return 
    */
    public static List<PermissionSet> getPermiSetsToAdd(String permSets) {
        if (permSets == null){
            return  null;
        }
        List<String> permSetNamesToAdd = permSets.split(',');
        // Do not assigm 'Customer_Community_My_Application' at this moment. 
        // Welcome email is sent if this permSet when assigned
        // It will be assigned when offer is signed by applicant

        List<PermissionSet> permSetsToAdd = new List<PermissionSet>(
            [SELECT Id, Name 
             FROM PermissionSet 
             WHERE Name IN :permSetNamesToAdd]);
        return permSetsToAdd;
    }
    
    /**
    * @author Herman Castano
    * @date 05/02/2020
    * @description creates a list of package licenses required for a CC user to be able to accept offers
    * @return 
    */
    public static List<PackageLicense> getPackageLicenseToAdd(String packlicense) {
        if (packlicense == null){
            return  null;
        }
        List<String> packlicenseNamesToAdd = packlicense.split(',');
        // Do not assigm 'Customer_Community_My_Application' at this moment. 
        // Welcome email is sent if this permSet when assigned
        // It will be assigned when offer is signed by applicant

        List<PackageLicense> packlicenseToAdd = new List<PackageLicense>(
            [SELECT Id, NamespacePrefix 
             FROM PackageLicense 
             WHERE NamespacePrefix IN :packlicenseNamesToAdd]); 
        return packlicenseToAdd;
    }
    
    /**
    * @author Herman Castano
    * @date 05/02/2020
    * @description get existing permSets already assigned (by user)
    * @return 
    */
    public static Map<String,PermissionSetAssignment> getExistingPermSetAssigment(List<User> userList, Set<Id> permissionSetIds) {
        Map<String,PermissionSetAssignment> tmp = new Map<String,PermissionSetAssignment>();
        for (PermissionSetAssignment psa : [
                                    SELECT id, AssigneeId, PermissionSetId
                                    FROM PermissionSetAssignment 
                                    WHERE AssigneeId in :userList 
                                        AND PermissionSetId IN :permissionSetIds
                                ]) {
            tmp.put(psa.PermissionSetId +'_'+psa.AssigneeId,psa);
        }
        return tmp;
    }

    /**
    * @author Herman Castano
    * @date 05/02/2020
    * @description get existing package licenses already assigned (by user)
    * @return 
    */
    public static Map<String,UserPackageLicense> getExistingUserPackageLicense(List<User> userList) {
        Map<String,UserPackageLicense> tmp = new Map<String,UserPackageLicense>();
        for (UserPackageLicense psa : [
                                    SELECT id, UserId, PackageLicenseId
                                    FROM UserPackageLicense 
                                    WHERE UserId in :userList
                                ]) {
            tmp.put(psa.PackageLicenseId +'_'+psa.UserId,psa);
        }
        return tmp;
    }
    
    /**
    * @author Herman Castano
    * @date 05/02/2020
    * @description add CPQ permission set to portal users
    * @return 
    */
    public static void addPermSetToPortalUsers(List<User> userList, List<PermissionSet> permSetsToAdd, Boolean isQueueable){
        List<PermissionSetAssignment> permSetAssignmentExistingUsers = new List<PermissionSetAssignment>();
        // List<PermissionSet> permSetsToAdd = new List<PermissionSet>(getPermiSetsToAdd());
        Map<String,PermissionSetAssignment>  existingPermSetAssigment = getExistingPermSetAssigment(userList, new Map<Id, PermissionSet>(permSetsToAdd).keySet());
        for (user u : userList) {                   
            for (PermissionSet ps:permSetsToAdd) {
                // Herman: check if permsets are not assigned already 
                // Kristian: remove the check because we are deleting all assignments before re-assigning it back (to trigger community welcome email)
                //if (existingPermSetAssigment.get(ps.Id + '_' + u.Id) == null) {
                    permSetAssignmentExistingUsers.add(new PermissionSetAssignment(
                        PermissionSetId = ps.Id, 
                        AssigneeId = u.Id));
                //}
            }
        }
        if (permSetAssignmentExistingUsers.size()>0) {
            if (isQueueable == true) {
                RemoveAndReassignPermissionSetDmlOptionQueueable insertQueuable = new RemoveAndReassignPermissionSetDmlOptionQueueable(permSetAssignmentExistingUsers, existingPermSetAssigment.values()); // do not fail all records if a particular item fails
                Id jobId = System.enqueueJob(insertQueuable);
            } else {                
                //delete already assigned permission sets
                delete existingPermSetAssigment.values();

                //added dml option to ensure that community welcome email message is sent
                Database.DMLOptions dlo = new Database.DMLOptions();    
                dlo.EmailHeader.triggerUserEmail = true;
                Database.insert(permSetAssignmentExistingUsers, dlo);
            }            
        }
    }
      

    /*
     * @author       Kristian Vegerano
     * @date         22/07/2020
     * @description  Class supporting the logic to be queued (asynchronously) with dmloptions set to send email to the user
     * @revision        1.0
     */
    public class RemoveAndReassignPermissionSetDmlOptionQueueable implements Queueable {
        // List of Sobjects to be udpated
        private List<SObject> sobjects;
        private List<SObject> permissionSetAssignmentsList;

        public RemoveAndReassignPermissionSetDmlOptionQueueable(List<SObject> sobjects, List<SObject> permissionSetAssignmentsList) {
            this.sobjects = sobjects;
            this.permissionSetAssignmentsList = permissionSetAssignmentsList;
        }

        // main method implementing the interface method
        public void execute(QueueableContext context) {
            //delete already assigned permission sets
            delete permissionSetAssignmentsList;

            //added dml option to ensure that community welcome email message is sent
            Database.DMLOptions dlo = new Database.DMLOptions();   
            dlo.EmailHeader.triggerOtherEmail = true; 
            dlo.EmailHeader.triggerUserEmail = true;
            Database.insert(this.sobjects, dlo);
        }
    }
    
    /**
    * @author Herman Castano
    * @date 05/02/2020
    * @description add CPQ permission set to portal users
    * @return 
    */
    public static void addPackageLicenseToPortalUsers(List<User> userList, List<PackageLicense> packageLicensesToAdd, Boolean isQueueable){
        List<UserPackageLicense> userPackageLicenses = new List<UserPackageLicense>();

        Map<String,UserPackageLicense>  existingPermSetAssigment = getExistingUserPackageLicense(userList);
        for (user u : userList) {                   
            for (PackageLicense ps:packageLicensesToAdd) {
                // Check if permsets are not assigned already
                if (existingPermSetAssigment.get(ps.Id + '_' + u.Id) == null) {
                    userPackageLicenses.add(new UserPackageLicense(
                        PackageLicenseId = ps.Id, 
                        UserId = u.Id));
                }
            }
        }
        if (userPackageLicenses.size()>0) {
            if (isQueueable == true) {
                InsertSobjectsQueueable insertQueuable = new InsertSobjectsQueueable(userPackageLicenses, false); // do not fail all records if a particular item fails
                Id jobId = System.enqueueJob(insertQueuable);
            } else {
                Database.insert(userPackageLicenses,false);
            }            
        }
    }

    /*
     * @author       Kristian Vegerano
     * @date         12.Feb.2021
     * @description  This method is used to assign partner community access permission set when a user has been created by a delegated admin partner user
     */
    public class AssignPartnerPermissionDelegatedUser extends TriggerAbstract {

        /**
        * Handle after update event checking and filtering
        */
        public override void process(SObject record, SObject oldRec) {
            //Start process
            User contextUser = (User)record;

            //Process all accounts
            records.add(record);
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                ExperienceAuthenticationServices.assignPartnerPermissionDelegatedUser((List<User>)records);
            }
        }
    }

    /*
     * @author       Kristian Vegerano
     * @date         12.Mar.2021
     * @description  Create a contact for the context user if the current/running user is a partner delegated admin trying to create a new partner user
     *               Mainly used for Monash Abroad Partners delegated administrators creating new partners
     */
    public class CreateAssociatedPartnerContact extends TriggerAbstract {

        /**
        * Handle after update event checking and filtering
        */
        public override void process(SObject record, SObject oldRec) {
            //Process all accounts
            records.add(record);
        }

        /**
        * Run functionality logic
        */
        public override void execute() {
            // Execute logic if running user is a monash abroad community user (delegated administrator)
            User currentUser = [SELECT Id, Profile.Name, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            if(currentUser.Profile.Name == Constants.PARTNER_USER_PROFILE || Test.isRunningTest()){

                // Initialize variables
                Id partnerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
                Id partnerProfileId = [SELECT Id FROM Profile WHERE Name = :Constants.PARTNER_USER_PROFILE LIMIT 1].Id;
                Map<String, Contact> newContactMap = new Map<String, Contact>();

                // Create contact for users that have a profile of Monash Partner Community Login User and contact field is blank
                for(User contextUser : (List<User>)records){
                    if((contextUser.ProfileId == partnerProfileId && contextUser.ContactId == null)){
                        
                        // Create a contact record and associated it to the user
                        newContactMap.put(contextUser.Username, new Contact(FirstName = contextUser.FirstName,
                                                                            MiddleName = contextUser.MiddleName,
                                                                            LastName = contextUser.LastName,
                                                                            Email = contextUser.Email,
                                                                            RecordTypeId = partnerRecordTypeId,
                                                                            AccountId = currentUser.Contact.AccountId));

                    }
                }

                // Insert new contact records if there are
                if(!newContactMap.isEmpty()){
                    insert newContactMap.values();

                    // Re-associated user record to be inserted to the contact record
                    for(User contextUser : (List<User>)records){
                        if(newContactMap.containsKey(contextUser.Username)){
                            contextUser.ContactId = newContactMap.get(contextUser.Username).Id;
                        }
                    }
                }
            }
        }
    }
    /**
     * @author      Vinothraja
     * @date        05.Apr.2021
     * @description Update the Associated contact with the Portal user's Profile details upon update
     */
    public class SyncAssociatedPartnerContact implements Triggers.Handler {
        /**
        * Update the Associated contact with the Portal user's edited Profile details
        */
        public void run() {

            //Create a set of Monash Abroad Partner Portal users only
            Set<id> setPartnerPortalUsers = new Set<Id> ();

            for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment
                           WHERE PermissionSet.Name = :Constants.PARTNER_PERMISSION_SET 
                           AND AssigneeId IN :Trigger.newMap.keyset()]) {
                setPartnerPortalUsers.add(psa.AssigneeId);
            }
            
            try {
                List<Contact> lstSyncableContacts = new List<Contact> ();
                for (Id userId : setPartnerPortalUsers) {
                    User user = (User)Trigger.newMap.get(userId);
                    User oldUserRecord = (User)Trigger.oldMap.get(userId);
                    if (user.isActive && user.ContactId!= null) {
                        Contact con = new Contact();
                        con.id = user.ContactId;
                        // Check whether User's Profile has been updated. If so, sync Associated Contact's Details
                        if(CommonUtilities.fieldHasChanged('FirstName', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('MiddleName', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('LastName', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('Suffix', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('Title', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('Email', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('CompanyName', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('Phone', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('MobilePhone', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('Street', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('State', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('City', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('Postalcode', user, oldUserRecord)
                            || CommonUtilities.fieldHasChanged('Country', user, oldUserRecord)) {
                            con.FirstName = user.FirstName==null?'':user.FirstName;
                            con.MiddleName = user.MiddleName==null?'':user.MiddleName;
                            con.LastName = user.LastName==null?'':user.LastName;
                            con.Suffix = user.Suffix==null?'':user.Suffix;
                            con.Title = user.Title==null?'':user.Title;
                            if (!String.isBlank(user.Email)) { //To avoid Email IDs being blanked out while syncing
                                con.Email = user.Email;
                            }
                            con.Company__c = user.CompanyName==null?'':user.CompanyName;
                            con.Phone = user.Phone==null?'':user.Phone;
                            con.mobilephone = user.MobilePhone==null?'':user.MobilePhone;
                            con.mailingstreet = user.Street==null?'':user.Street;
                            con.mailingstate = user.State==null?'':user.State;
                            con.mailingcity = user.City==null?'':user.City;
                            con.mailingpostalcode = user.PostalCode==null?'':user.PostalCode;
                            con.mailingcountry = user.Country==null?'':user.Country;
                            lstSyncableContacts.add(con);
                        }
                    }
                }
                    
                if (!lstSyncableContacts.isEmpty()) {
                    update lstSyncableContacts;
                }
            } catch (exception ex) {
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }
    
      /**
     * @author      SMendu
     * @date        29.Sep.2021
     * @description Prevent deactivation of Primary Account Holder user 
     */
    public class PreventPrimaryAccountHolderDeactivation extends TriggerAbstract {
        List<Id> usrIdList = new List<Id>();
        public override void process(SObject newRec, SObject oldRec) {
            if(!((User)newRec).IsActive)
            {
                records.add(newRec);
                usrIdList.add(newRec.Id);
            }
        }

        public override void execute() {
            List<AccountTeamMember> accTeamMember = ([select UserId from AccountTeamMember where TeamMemberRole=:AccountTeamConstants.PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER and UserId in :usrIdList]);
            for(AccountTeamMember acc:accTeamMember)
            {
                for(User usr:(List<User>) records)
                {
                    if(acc.UserId == usr.Id)
                    {
                        usr.addError(System.Label.StopPrimaryUserDeactivation);
                    }
                }
            }
        }

       
    }
    /**
     * @author      Peter Sewell
     * @date        01/11/2021
     * @description Upsert User details to User Shadow object  
     * @revision    Initial
     */
    public class SyncUserToUserShadow implements Triggers.Handler {
        /**
        * Upsert the associated UserShadow with the User's details
        */
        public void run() {
            List<UserShadow__c> toSyncUserShadow = new List<UserShadow__c>();
            for(User user : (List<User>) Trigger.new) {
                if (isSyncToUserShadow(user)) {
                    UserShadow__c us = new UserShadow__c();
                    us.Name = user.Username;
                    us.Email__c = user.Email;
                    us.FederationIdentifier__c = user.FederationIdentifier;
                    us.IsActive__c = user.IsActive;
                    us.Last_Provisioning_Action__c = user.Last_Provisioning_Action__c;
                    us.ManagerId__c = user.ManagerId;
                    us.Profile_Name__c = user.User_Profile_Name__c;
                    us.Provisioning_Request_Id__c = user.Provisioning_Request_Id__c;
                    us.Provisioning_Source__c = user.Provisioning_Source__c;
                    us.Role_Name__c = user.User_Role_Name__c;
                    us.Username__c = user.Username;
                    toSyncUserShadow.add(us);
                }
            }
            // Sync to UserShadow if we have in-scope changes and we are not running in a batch (where we run the risk of hitting queueable limit of 2)
            if ((toSyncUserShadow.size() > 0) && !System.isBatch()) {
                ID jobID = System.enqueueJob(new UserServices.SyncUserToUserShadowAsync(toSyncUserShadow));
            }
        }

        private Boolean isSyncToUserShadow(User user) {
            Boolean isSync = false;
            if (Trigger.isInsert) {
                isSync = (user.UserType != 'CspLitePortal');
            } else if (Trigger.isUpdate) {
                User oldUserRecord =  (User) Trigger.oldMap.get(User.Id);
                isSync = (
                    (user.UserType != 'CspLitePortal') && 
                    (CommonUtilities.fieldHasChanged('Username', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('Email', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('FederationIdentifier', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('IsActive', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('Last_Provisioning_Action__c', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('ManagerId', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('UserRoleId', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('ProfileId', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('Provisioning_Request_Id__c', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('Provisioning_Source__c', user, oldUserRecord)
                        || CommonUtilities.fieldHasChanged('Username', user, oldUserRecord))
                );
            }
            return isSync;
        }
    }    
    /**
     * @author      Peter Sewell
     * @date        01/11/2021
     * @description Upsert User details to User Shadow object asynchronously to avoid mixed DML error
     * @revision    Initial
     */
    public class SyncUserToUserShadowAsync implements Queueable {

        List<UserShadow__c> passedUserShadowList = new List<UserShadow__c>();
        public SyncUserToUserShadowAsync (List<UserShadow__c> us) {
               this.passedUserShadowList = us;
        }
        public void execute(QueueableContext context) {
            try {
                upsert passedUserShadowList Username__c;
            } 
            catch(Exception ex) {
                nebula.logger.error('SyncUserToUserShadowAsync DML Error',passedUserShadowList);
                nebula.logger.exception(ex.getMessage(), ex);
            } finally {
                nebula.logger.saveLog();
            }
        }
    }
    /**
     * @author       P.Victoriano
     * @date         19/Nov/2021
     * @description  Clears FederationId and UserName on before context
     **/
    public class ClearFedIdUserName extends TriggerAbstract {
        /**
         * @description process Clears User info on before insert context
         */
        public override void process(SObject newRec) {
            User oUsr = (User)newRec;
            if (oUsr.IsActive == false) {
                clearDetails(oUsr);
            }
        }

        /**
         * @description process Clears User info on before update context
         */
        public override void process(SObject newRec, SObject oldRec) {
            User oUsr = (User)newRec;
            if (oUsr.IsActive == false) {
                clearDetails(oUsr);
            }
        }

        /**
         * @description clearDetails Removes Details in User
         */
        @TestVisible
        private void clearDetails(User usr) {
            String uAlias = CommonUtilities.createAliasForUser(usr.FirstName, usr.LastName);
            DateTime dt = Datetime.now();
            String myDeDt = dt.format('dd-MM-yyyy');
            Long lng = dt.getTime();
            String alisStr = String.format('{0}{1}', new List<String> {
                uAlias,
                String.valueOf(lng)
            });
            String combVal = String.format('{0}-{1}-{2}{3}', new List<String> {
                usr.Email,
                Sandbox_Details__c.getOrgDefaults().sandboxName__c,
                myDeDt,
                '-'+dt.getTime()
            });
            //
            CommonUtilities.populateSObjectStrLengthByDescribe(combVal, usr, User.Username);
            CommonUtilities.populateSObjectStrLengthByDescribe(alisStr, usr, User.Alias);
            CommonUtilities.populateSObjectStrLengthByDescribe(alisStr, usr, User.CommunityNickName);
            usr.CallCenterId = null;
            usr.FederationIdentifier = null;
        }
    }
    /**
     * @author       P.Victoriano
     * @date         19/Nov/2021
     * @description  Removes PermissionSets on Deactivated Users
     **/
    public class RemovePermissionsUser extends TriggerAbstract {
        Set<Id> userIds = new Set<Id>();
        /**
         * @description process Check if IsActive is Changed to false
         */
        public override void process(SObject newRec, SObject oldRec) {
            User oUsr = (User)newRec;
            User oldUsr = (User)oldRec;
            if (oUsr.IsActive == false && oUsr.IsActive != oldUsr.IsActive) {
                userIds.add(oUsr.Id);
            }
        }

        /**
         * @description execute handle on Trigger logic
         */
        public override void execute() {
            //Has records to process
            if(userIds.isEmpty() == false){
                List<PermissionSetAssignment> permsSets = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN:userIds AND PermissionSet.IsOwnedByProfile = false];
                if(permsSets != null && !permsSets.isEmpty()){
                    //No need to track 
                    Database.delete(permsSets,false);
                }
                List<PermissionSetLicenseAssign> permAssignLics = [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId IN:userIds];
                if(permsSets != null && !permsSets.isEmpty()){
                    //No need to track 
                    Database.delete(permAssignLics,false);
                }
            }
        }
    }
    /**
     * @author       Jitender Padda
     * @date         05/03/2024
     * @description  Syncs name details from Contact based on authcate match
     **/
    public class SyncDetailsFromContact extends TriggerAbstract {
        Map<String, User> authcateToUserMap = new Map<String, User>();

        public override void process(SObject record) {
            User newUser = (User) record;

            if (newUser.FederationIdentifier == null || newUser.ContactId != null) {
                return;
            }

            authcateToUserMap.put(newUser.FederationIdentifier, newUser);
        }

        public override void execute() {
            if (authcateToUserMap.size() > 0) {

                for (Contact authcateMatchedUser : [
                    SELECT Id, FirstName, LastName, Authcate__c
                    FROM Contact
                    WHERE Authcate__c IN :authcateToUserMap.keySet()
                    ORDER BY LastModifiedDate // will ensure recently modified contact name is copied
                ]) {
                    User user = authcateToUserMap.get(authcateMatchedUser.Authcate__c);

                    if(user != null){
                        if (user.FirstName != authcateMatchedUser.FirstName || user.LastName != authcateMatchedUser.LastName) {
                            user.FirstName = authcateMatchedUser.FirstName;
                            user.LastName = authcateMatchedUser.LastName;
                        }
                    }
                }
            }
        }
    }

    /**
     * @author       APRivera
     * @date         09/10/2024
     * @description  This ensures that the username from the User object is automatically rolled up to the Contact
     **/
    public class SyncUsernameToContact extends TriggerAbstract {
        public override void process(SObject newRec) {
            User oUsr = (User)newRec;
            if (oUsr.IsActive == true && oUsr.ContactId != null) {
                records.add(newRec);
            }
        }

        public override void process(SObject newRec, SObject oldRec) {
            User nUsr = (User)newRec;
            User oUsr = (User)oldRec;
            if (nUsr.IsActive == true && nUsr.ContactId != null) {
                if(CommonUtilities.fieldHasChanged('Username', nUsr, oUsr)){
                    records.add(newRec);
                }
            }
        }

        /**
         * @description AsyncProcessPayload to create payload and invokes Async_Process__e
         */
        public override void execute() {
            if(!records.isEmpty()){
                Set<Id> userIdSet = new Set<Id>();
                for(User usr: (List<User>) records){
                    userIdSet.add(usr.Id);
                }

                if(!userIdSet.isEmpty()){
                    AsyncProcessPayload payload = new AsyncProcessPayload();
                    payload.put ('userIdSet', userIdSet);
                    Async_Process__e ap = new Async_Process__e (
                            Process_Name__c = 'UserServices.UpdateContact',
                            Parameter__c = payload.serialize()
                    );
                    EventBus.publish(ap);
                }
            }
        }
    }

    /**
     * @author       APRivera
     * @date         09/10/2024
     * @description  Updates the MyApp_Username__c on Contact record
     **/
    public class UpdateContact implements IPlatformEventInvocable {

        private Set<Id> userIdSet = new Set<Id>();

        /**
         * @description initialize process by extracting the method parameters from the platform event payload
         * @param payloads - Lists of AsyncProcessPayload
         */
        private void initialize(List<AsyncProcessPayload> payloads) {
            if(payloads != null) {
                for(AsyncProcessPayload payload : payloads) {
                    //first, cast the get return of Map<String, Object> into Map<Id, String>
                    List<Object> objList = (List<Object>) payload.get('userIdSet');
                    //then, instantiate a Set out of it
                    for(Object io : objList) {
                        //parse object to ID
                        this.userIdSet.add(Id.valueOf(io.toString()));
                    }
                }
            }
        }

        public void execute(List<AsyncProcessPayload> payload) {
            try {
                initialize(payload);
                run(this.userIdSet);
            } catch(Exception ex) {
                nebula.Logger.error(ex.getMessage(), ex);
            } finally {
                nebula.Logger.saveLog();
            }
        }

        /**
         * @description initialize process by extracting the method parameters from the platform event payload
         * @param usrIds - set of user ids
         */
        public void run(Set<Id> usrIds) {
            if(!usrIds.isEmpty()){
                List<Contact> listContactsToUpdate = new List<Contact>();
                Map<Id, String> mapUsernameByContactIds = new Map<Id, String>();

                for(User usr : [SELECT Id, ContactId, Username FROM User WHERE Id IN : usrIds]){
                    mapUsernameByContactIds.put(usr.ContactId, usr.Username);
                }

                if(!mapUsernameByContactIds.isEmpty()){
                    for(Contact con : [SELECT Id, MyApp_Username__c FROM Contact WHERE Id IN : mapUsernameByContactIds.keySet()]){
                        con.MyApp_Username__c = mapUsernameByContactIds.get(con.Id);
                        listContactsToUpdate.add(con);
                    }

                    if(!listContactsToUpdate.isEmpty()){
                        try{
                            Database.update(listContactsToUpdate);
                        } catch(Exception ex) {
                            nebula.Logger.error(ex.getMessage(), ex);
                        } finally {
                            nebula.Logger.saveLog();
                        }
                    }
                }
            }
        }
    }

}