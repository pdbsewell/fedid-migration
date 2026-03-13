/**
* Handles methods related to the logged in constituent profile information.
*
* @author:  Zachary Soohoo
* @version: 1.4
* @since:   1.0
* @last modified on  : 2022-01-19
* @last modified by  : Inderpal Dhanoa
* Modifications Log 
* Ver   Date         Author          	Modification
* 1.9   2022-10-03 - APRivera        - Additional mapping on Address fields (PENGAGE-2502)
* 1.8   2022-06-14 - Inderpal Dhanoa - UpdatePronoun (PENGAGE-2401)
* 1.7   2022-05-30 - Inderpal Dhanoa - Add preferred Pronoun (PENGAGE-2289)
* 1.7   2022-05-24 - Inderpal Dhanoa - Additional check on Sync Button (PENGAGE-2378)
* 1.6   2022-05-24 - Inderpal Dhanoa - Add Sync Button (PENGAGE-2126)
* 1.5   2022-01-24 - Inderpal Dhanoa - Add Portal Login Time Bug (PENGAGE-2154)
* 1.4   2022-01-19 - Inderpal Dhanoa - Add Portal Login Time (PENGAGE-2134)
* 1.3   2022-01-11 - Inderpal Dhanoa - Add Gender Label (PENGAGE-2118)
* 1.2   2021-12-22 - Inderpal Dhanoa - Added Portal reActivation button (PENGAGE-2112)
* 1.1   2021-12-17 - Inderpal Dhanoa - Add Monash ID (PENGAGE-2080)
* 1.0   2019-11-28 - Zachary Soohoo - Initial Version
**/

global with sharing class PORTAL_UCIN_MyProfileController {
    /**
    * Wrapper class to return Volunteer multiselect options and selected options for a user
    *
    * @param: volRoles       	The list of Volunteer role options
    * @param: volSkills         The list of Volunteer Skills options
    * @param: volAreas          The list of Volunteer Areas of Interest options
    * @param: volPrefs			Contains the options that the user has already selected
    * @Revison Steffi 			Add Queueabale class to resolve the issue while updating preferred email adrress on ERDA portal PENGAGE-1722
    */
    public static List <User> loggedinUser = [select id,Username,ContactId, Directory_Opt_In__c,email,
                                			  Messaging_Opt_In__c, AboutMe from User where Id =: userinfo.getUserId()];

    public class VolunteerPreferenceData {
        @AuraEnabled
        public List<String> volRoles{ get; set; }
        @AuraEnabled
        public List<String> volSkills{ get; set; }
        @AuraEnabled
        public List<String> volAreas{ get; set; }
        @AuraEnabled
        public Contact volPrefs{ get; set; }

        public VolunteerPreferenceData(List<String> volRoles, List<String> volSkills, List<String> volAreas, Contact volPrefs) {
            this.volRoles = volRoles;
            this.volSkills = volSkills;
            this.volAreas = volAreas;
            this.volPrefs = volPrefs;
        }
    }

    private without sharing class MyProfileQueryHandler {

        public List<Affiliation__c> affiliationQuery(Id contactId) {
            List<Affiliation__c> affilList = [SELECT Id, Name, Is_Active__c, Is_Primary__c, Position__c, Account__r.Name, Account__r.Industry, RecordTypeId
                            FROM Affiliation__c
                            WHERE Contact__c = :contactId AND Is_Primary__c = true AND Is_Active__c = true AND (recordtype.developername = 'Employee' OR recordtype.developername = 'Industry_Contact')];
            return affilList;
        }

        public Contact contactQuery(Id contactId) {
            Contact cont = [SELECT Id, Name, Birthdate, FirstName, LastName, MiddleName, Preferred_Name__c, Pronouns_V2__c, ucinn_ascendv2__Recognition_Name__c, Salutation_ERDA__c, Suffix, Title,
                        Gender__c, Volunteer_Areas_of_Interest__c, Volunteer_Skills__c, Person_ID_unique__c,
                        Direct_Mail_Opt_Out__c, HasOptedOutOfEmail, SMS_Opt_Out__c, DoNotCall,
                        Study_at_Monash__c, Volunteer_at_Monash__c, Partner_with_Monash__c, Giving_to_Monash__c, Work_at_Monash__c, Monash_Corporate__c, Monash_Community__c, Research_with_Monash__c,
                        (SELECT Id, Qualification_Name__c, Faculty__r.Name, Date_Achieved__c, Other_Qualification__c, Qualification__r.Qualification_Name__c FROM Contact_Qualifications__r
                                                            WHERE Obtained_Status__c = 'MONASH-OBTAINED' and Institution_Name__c = 'Monash University' ORDER BY Date_Achieved__c DESC),
                        (SELECT Id, Name, First_Name__c, Last_Name__c, Salutation__c, Suffix__c, Is_Active__c, Is_Primary__c, Type__c FROM Names__r WHERE Is_Active__c = true AND Is_Primary__c = true ORDER BY LastModifiedDate DESC),
                        (SELECT Id, Name, Is_Active__c, Is_Primary__c, Type__c, Classification__c,Verification_Status__c,ISO_Country__c FROM Phones__r WHERE Is_Active__c = true ORDER BY LastModifiedDate DESC),
                        (SELECT Id, Name, Is_Active__c, Is_Primary__c, Classification__c, Verification_Status__c FROM Emails__r WHERE Is_Active__c = true ORDER BY LastModifiedDate DESC),
                        (SELECT Id, Name, Is_Active__c, Is_Primary__c, Country2__c, Street_name__c, Type__c, Post_Code__c, DPID__c, Verification_Status__c,
                            City__c, State__c, Classification__c FROM Addresses__r WHERE (Is_Primary__c = true OR Classification__c = 'Business') AND Is_Active__c = true ORDER BY LastModifiedDate DESC),
                        (SELECT Id, Name, Is_Active__c, Is_Primary__c, Type__c FROM Social_Handles__r WHERE Is_Active__c = true ORDER BY LastModifiedDate DESC)
                        FROM Contact
                        WHERE Id = :contactId];
            return cont;
        }

        // update existing affiliation in without sharing context

        public void updateAffiliation(Affiliation__c origAffiliation,Map<String, String> affilMap,Contact cont){

            if(origAffiliation != null) {
                origAffiliation.End_Date__c = Date.today();
            	origAffiliation.Is_Active__c = false;
            	update origAffiliation;
                if(affilMap.get('orgName') == origAffiliation.Account__r.Name && affilMap.get('orgIndustry') == origAffiliation.Account__r.Industry) {
                    Affiliation__c affil = new Affiliation__c(RecordTypeId = origAffiliation.RecordTypeId, Contact__c = cont.Id, Account__c = origAffiliation.Account__c,
                                                              Start_Date__c = Date.today(), Is_Primary__c = true, Is_Active__c = true, Position__c = affilMap.get('position'));
                    insert affil;
                } else {
                    if(!String.isBlank(affilMap.get('orgName')) || !String.isBlank(affilMap.get('orgIndustry'))) {
                        createInterim(affilMap.get('position'), affilMap.get('orgName'), affilMap.get('orgIndustry'), cont.Id);
                    }
                }
            } else {
                if(!String.isBlank(affilMap.get('orgName')) || !String.isBlank(affilMap.get('orgIndustry'))) {
                    createInterim(affilMap.get('position'), affilMap.get('orgName'), affilMap.get('orgIndustry'), cont.Id);
                }
            }
   		 }
 	}


    // Used for test class only. Needed because we can't use Custumer Community User profile
    // to access Opportunity, etc...
    /*public static Contact testContact;

    global class UserDataInfo {
        String userId;
        String contactId;
    }*/

    /**
* Get the logged in constituent profile information
*
* @return: Constituent profile information
* @since:  1.0
*/
    @AuraEnabled
    global static Map<String, Object> SERVER_getUserInfo() {
        Boolean showDirectorySetting = true;
        Boolean isDirectorySearch = true;
        Boolean isNewsletter = true;
        Boolean hasOutstandingInterim = false;
        Address__c prefAddress = new Address__c();
        Address__c businessAddress = new Address__c();
        Name__c preferredName = new Name__c();
        Map<String, Object> resultMap = new Map<String, Object>();
        Map<String, String> affilMap = new Map<String, String>();
        Map<String, String> preferredMap = new Map<String, String>();
        Map<String, Phone__c> phoneMap = new Map<String, Phone__c>();
        Map<String, Email__c> emailMap = new Map<String, Email__c>();
        Map<String, Social__c> socialMap = new Map<String, Social__c>();
        Id interimRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Interim__c.getRecordTypeInfosByDeveloperName().get('Portal_Bio_Info').getRecordTypeId();
        MyProfileQueryHandler queryHandler = new MyProfileQueryHandler();
        //Retrieve the Id, and Opt in settings of the contact associated with the user if it exists
        Id userId = UserInfo.getUserId();

         User usr = loggedinUser[0];

        /*User usr = [SELECT Id,
                    ContactId, Directory_Opt_In__c, Messaging_Opt_In__c, AboutMe
                    FROM User
                    WHERE Id = :userId];*/


        Id contactId = usr.ContactId;

        /*if (Test.isRunningTest()) {
            contactId = testContact.Id;
        }*/

        if(contactId == null) {
            return null;
        }
        //Query the data relevant to display on the portal
        Contact cont = queryHandler.contactQuery(contactId);

        //Query primary employer data
        List<Affiliation__c> affiliations = queryHandler.affiliationQuery(contactId);
        Integer outstandingInterims = [SELECT count() FROM ucinn_ascendv2__Interim__c WHERE RecordTypeId = :interimRecordTypeId
        AND ucinn_ascendv2__Contact__c = :contactId AND ucinn_ascendv2__Status__c != 'Completed'];

        if(outstandingInterims > 0) {
            hasOutStandingInterim = true;
        }

        preferredMap.put('phone', '');
        preferredMap.put('email', '');
        //Select most recent/primary Phone, email, Address, and Social to show
        if (cont.Phones__r != null) {
            for(Phone__c phone : cont.Phones__r) {
                if(phone.Classification__c == 'Business' && phoneMap.get('Work') == null) {
                    phoneMap.put('Work', phone);
                    if(phone.Is_Primary__c) {
                        preferredMap.put('phone', 'work');
                    }
                } else if(phone.Classification__c == 'Private' && phone.Type__c == 'Mobile' && phoneMap.get('Mobile') == null) {
                    phoneMap.put('Mobile', phone);
                    if(phone.Is_Primary__c) {
                        preferredMap.put('phone', 'mobile');
                    }
                } else if(phone.Classification__c == 'Private' && phone.Type__c == 'Landline' && phoneMap.get('Home') == null) {
                    phoneMap.put('Home', phone);
                    if(phone.Is_Primary__c) {
                        preferredMap.put('phone', 'home');
                    }
                }
            }
        }

        if (cont.Emails__r != null) {
            for(Email__c email : cont.Emails__r) {
                if (email.Classification__c == 'Business' && emailMap.get('Business') == null) {
                    emailMap.put('Business', email);
                    if(email.Is_Primary__c) {
                        preferredMap.put('email', 'business');
                    }
                } else if (email.Classification__c == 'Private' && emailMap.get('Personal') == null) {
                    emailMap.put('Personal', email);
                    if(email.Is_Primary__c) {
                        preferredMap.put('email', 'personal');
                    }
                }
            }
        }

        if (cont.Addresses__r != null && cont.Addresses__r.size() > 0) {
            Address__c emptyAddress = new Address__c();
            for(Address__c address : cont.Addresses__r) {
                if(address.Is_Primary__c == true) {
                    prefAddress = address;
                }
                if ((address.Classification__c == 'Business') && (businessAddress == emptyAddress)) {
                    businessAddress = address;
                }
                if((prefAddress != emptyAddress) && (businessAddress != emptyAddress)) {
                    break;
                }
            }
        }

        if (cont.Social_Handles__r != null) {
            for(Social__c handle : cont.Social_Handles__r) {
                if(handle.Type__c == 'Twitter' && socialMap.get('Twitter') == null) {
                    socialMap.put('Twitter', handle);
                } else if(handle.Type__c == 'LinkedIn' && socialMap.get('LinkedIn') == null) {
                    socialMap.put('LinkedIn', handle);
                } else if(handle.Type__c == 'WeChat' && socialMap.get('WeChat') == null) {
                    socialMap.put('WeChat', handle);
                }
            }
        }

        if(cont.Names__r != null && cont.Names__r.size() > 0) {
            preferredName = cont.Names__r[0];
        }

        //Retrieve picklist values for Country and Salutation(ERDA)
        Map<String, List<String>> picklistsToGet = new Map<String, List<String>>();

        picklistsToGet.put('Address__c', new List<String>{'Country2__c'});
        picklistsToGet.put('Contact', new List<String>{'Salutation_ERDA__c', 'Gender__c', 'Pronouns_V2__c'});
        picklistsToGet.put('Account', new List<String>{'Industry'});

        Map<String, List<String>> picklists = SERVER_getPicklists(picklistsToGet);
        Map<String,String> picklistMap = SERVER_getPicklistValueandLabel(picklistsToGet);


        //Construct the return object
        resultMap.put('contact', cont);
        resultMap.put('picklists', picklists.get('Country2__c'));
        resultMap.put('salutations', picklists.get('Salutation_ERDA__c'));
		resultMap.put('pronouns', picklists.get('Pronouns_V2__c'));
        resultMap.put('industries', picklists.get('Industry'));
		resultMap.put('genderValueLabel', picklistMap.get(cont.Gender__c));
        resultMap.put('prefAddress', prefAddress);
        resultMap.put('businessAddress', businessAddress);
        resultMap.put('preferredMap', preferredMap);
        resultMap.put('preferredName', preferredName);
        resultMap.put('phoneMap', phoneMap);
        resultMap.put('emailMap', emailMap);
        resultMap.put('socialMap', socialMap);
        resultMap.put('outstandingInterim', hasOutStandingInterim);
        if (!affiliations.isEmpty()) {
            affilMap.put('position', affiliations[0].Position__c);
            affilMap.put('orgName', affiliations[0].Account__r.Name);
            affilMap.put('orgIndustry', picklistMap.get(affiliations[0].Account__r.Industry));
            resultMap.put('affiliations', affiliations[0]);
        }
        resultMap.put('affilMap', affilMap);
        resultMap.put('userSettings', usr);
        resultMap.put('interestAreas', SERVER_getVolunteerCheckboxes().get('Volunteer_Areas_of_Interest__c'));

        return resultMap;
    }
    /**
    * Retrieve picklist values given a map of Values and Labels of icklist value
    *
    * @param: pickListstToGet      	A map Object names to the list of picklist Fields to be retrieved
    */
    private static Map<String,String> SERVER_getPicklistValueAndLabel(Map<String, List<String>> picklistsToGet) {

        Map<String,String> picklistMap = new Map<String,String>();
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (String objectName : picklistsToGet.keySet()) {
            Schema.SObjectType objectType = globalDescribe.get(objectName);
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            List<String> picklistNames = picklistsToGet.get(objectName);
            for (String picklistName : picklistNames) {
                List<String> picklistValues = new List<String>();
                List<Schema.PicklistEntry> picklistEntries = fieldMap.get(picklistName).getDescribe().getPickListValues();
                for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                    //picklistValues.add(picklistEntry.getLabel());
                    picklistMap.put(picklistEntry.getValue(),picklistEntry.getLabel());
                }
            }

        }
        return picklistMap;
    }
    /**
    * Retrieve picklist values given a map of Object names to list of picklist Fields to retrieve
    *
    * @param: pickListstToGet      	A map Object names to the list of picklist Fields to be retrieved
    */
    private static Map<String, List<String>> SERVER_getPicklists(Map<String, List<String>> picklistsToGet) {

        Map<String, List<String>> picklists = new Map<String, List<String>>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (String objectName : picklistsToGet.keySet()) {
            Schema.SObjectType objectType = globalDescribe.get(objectName);
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            List<String> picklistNames = picklistsToGet.get(objectName);
            for (String picklistName : picklistNames) {
                List<String> picklistValues = new List<String>();
                List<Schema.PicklistEntry> picklistEntries = fieldMap.get(picklistName).getDescribe().getPickListValues();
                for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                    picklistValues.add(picklistEntry.getLabel());
                }
                picklists.put(picklistName, picklistValues);
            }

        }
        return picklists;


    }

    /**
    * Returns the Id of the Contact associated with the current user
    *
    */
    private static Id getContactId() {
        Id userId = UserInfo.getUserId();

        User usr = [SELECT Id,
                    ContactId
                    FROM User
                    WHERE Id = :userId];


        Id contactId = usr.ContactId;
        return contactId;
    }

	/**
    * method to get user information from contact
    * @param: recordId      	The User Id of the Portal User
    * @return:UserWrapper       Wrapper Class of the User and Activation Button
    *
    */
    @AuraEnabled(cacheable=true)
    public static UserWrapper getUserInformation(Id recordId){
        UserWrapper o_UserWrapper = new UserWrapper();
        o_UserWrapper.b_renderReActivationButton = false;
        o_UserWrapper.b_renderSyncUserDetailsButton = false;
        List<User> l_associatedUsers = [SELECT Id,Name,Email,
                                        IsActive,Username,IsPortalEnabled,Directory_Opt_In__c,Messaging_Opt_In__c, LocaleSidKey,ContactId,LastLoginDate,
                                        (SELECT Id,PermissionSetId,PermissionSet.Name,PermissionSet.Label, SystemModstamp FROM PermissionSetAssignments ORDER BY PermissionSet.Name)
                                        FROM User
                                        WHERE ContactId =: recordId OR Id =: UserInfo.getUserId()];
        o_UserWrapper.t_lastPortalLoginTime = new SearchPortalLoginHistory().getLastPortalLoginTime(l_associatedUsers);
        for(User linkedUser : l_associatedUsers){
            // The Query returns with Portal User and the Logged In User
            // The Logged in User needs to be validated for having the "Manage Alumni User" Perm Set
            // Only the Portal Users details are to be captured and displayed in the UI
            // If the Portal User has already logged in then do not show him the button
           if(linkedUser.Id == UserInfo.getUserId()){
                if(validateRunningUser(linkedUser)){
                    o_UserWrapper.b_renderSyncUserDetailsButton = true;
                    if(validatePortalUserPermSetAndLogIn(l_associatedUsers, o_UserWrapper.t_lastPortalLoginTime)){
                        o_UserWrapper.b_renderReActivationButton = true;
                    }
                }
            } else{
                o_UserWrapper.portalUser = linkedUser;
            }
        }
        return o_UserWrapper;
    }

/**
     * @description       : Inner class to Query last LoginHistory of Portal User
     * @author            : Inderpal Dhanoa
     * @group             : Engage
     * @Initial Version   : Inderpal Dhanoa
     * @Created on        : 2022-01-24
     * Modifications Log
     * Ver   Date         Author            Modification
     * 1.0   2022-01-24 - Inderpal Dhanoa - Created
     */
    private without sharing class SearchPortalLoginHistory {
        /**
         * @author      Inderpal Dhanoa
         * @description This method is get the Last Login history of the portal user
         * @param       List<User> of Associated Users
         * @return      DateTime of last login
         * @revision    2022-01-24 - Inderpal Dhanoa - Created
         */
        public Datetime getLastPortalLoginTime(List<User> l_associatedUsers){
            DateTime t_LastPortalLogin;
            Id i_portalUserId;
            for(User linkedUser : l_associatedUsers){
                // Check for the Portal User has the Perm Set
                If(linkedUser.Id != Userinfo.getUserId()){
                    i_portalUserId = linkedUser.Id;
                }
            }
            String s_portalName = String.valueOf(Label.Ascend_Portal_Name);
            Network portalNetwork = [SELECT Id FROM Network Where Name = :s_portalName];
            for(LoginHistory lastPortalLogin : [SELECT LoginTime, Status, NetworkId, UserId
                                                FROM LoginHistory
                                                WHERE NetworkId = :portalNetwork.Id  AND UserId = :i_portalUserId
                                                ORDER BY LoginTime desc]){
                if(lastPortalLogin.Status == 'Success'){
                    t_LastPortalLogin = lastPortalLogin.LoginTime;
                    return t_LastPortalLogin;
                }
            }
            return t_LastPortalLogin;
        }
    }

    /**
    * method to Validate if the Portal User has the Alumni Permission set attached to it and has logged in after granting the Perm Set
    *
    * @param: l_associatedUsers      	    The List of Users
    * @param: t_lastPortalLoginTime      	The Last Ascend Portal login timestamp
    * @return:Boolean                       Flag to check if we are to render the ReActivation button
    *
    */
    public static Boolean validatePortalUserPermSetAndLogIn(List<User> l_associatedUsers, DateTime t_lastPortalLoginTime){
        Boolean b_assignedPermSetsAndAlreadyLoggedIn = false;
        String s_label = String.valueOf(Label.Alumni_Portal_Permission_Set);
        Id i_portalUserId;
        for(User linkedUser : l_associatedUsers){
            // Check for the Portal User has the Perm Set
            If(linkedUser.Id != Userinfo.getUserId()){
                for(PermissionSetAssignment assignedPermSet : linkedUser.PermissionSetAssignments){
                    If(assignedPermSet.PermissionSet.Name == s_label){
                        // The Portal User has the Permission Set
                        // Check if the Portal User has logged in after assigning the Perm Set
                        if(t_lastPortalLoginTime == null || t_lastPortalLoginTime < assignedPermSet.SystemModstamp){
                            return true;
                        }
                    }
                }
            }
        }
        return b_assignedPermSetsAndAlreadyLoggedIn;
    }

	/**
    * method to Validate if the User has the manage Alumni Permission set attached to it
    *
    * @param: u_runningUser      	The Logged in User
    * @return:Boolean               Flag to check if it has access or not
    *
    */
    public static Boolean validateRunningUser(User u_runningUser){
        String s_label = String.valueOf(Label.Manage_Alumni_Portal_Users);
        for(PermissionSetAssignment relatedPermSetAssign : u_runningUser.PermissionSetAssignments){
            if(relatedPermSetAssign.PermissionSet.Name == s_label){
                return true;
            }
        }
        return false;
    }

    /**
    * Wrapper class to collect the logged in User and Portal User
    */
    public class UserWrapper{
        @AuraEnabled
        public User portalUser;
        @AuraEnabled
        public Boolean b_renderReActivationButton;
        @AuraEnabled
        public Boolean b_renderSyncUserDetailsButton;
		@AuraEnabled
        public DateTime t_lastPortalLoginTime;
    }

    /**
    * Deletes and ReAssigns the Permission Set
    *
    * @param: userRecordId       	The Id of the User for whcih the Perm Set is ReActivated
    * @return: User               User Object Details
    */
    @AuraEnabled
    public static User reactivatePortalAccount(Id userRecordId){
        User u_runningUser = [SELECT Id,Name,Email,
                            (SELECT Id,PermissionSetId,PermissionSet.Name,PermissionSet.Label, SystemModstamp from PermissionSetAssignments order by PermissionSet.Name)
                            FROM User
                            WHERE Id =: UserInfo.getUserId()];
		// The Logged in User needs to be validated for having the "Manage Alumni User" Perm Set
        if(validateRunningUser(u_runningUser)){
            Set<String> s_AlumniPortalPermissionSet = new Set<String>();
            String s_label = String.valueOf(Label.Alumni_Portal_Permission_Set);
            for(String permSet : s_label.split(';')){
                s_AlumniPortalPermissionSet.add(permSet);
            }

            try{
                List<PermissionSetAssignment> l_linkedPermsissionSet = [SELECT Id, Assignee.Name, PermissionSetId
                                                                        FROM PermissionSetAssignment
                                                                        WHERE PermissionSet.Name IN :s_AlumniPortalPermissionSet
                                                                        AND AssigneeId = :userRecordId];
                if(!l_linkedPermsissionSet.isEmpty()){
                    Set<Id> s_PermSetIds = new Set<Id>();
                    for(PermissionSetAssignment assignPermSets : l_linkedPermsissionSet){
                        s_PermSetIds.add(assignPermSets.PermissionSetId);
                    }
                    delete l_linkedPermsissionSet;
                    l_linkedPermsissionSet.clear();

                    for(Id permSetId: s_PermSetIds){
                        l_linkedPermsissionSet.add(new PermissionSetAssignment(PermissionSetId = permSetId, AssigneeId = userRecordId));
                    }
                    insert l_linkedPermsissionSet;
                }
            }catch(Exception ex){
                LogUtilityException.LogException(ex);
            }
            return [SELECT Id,Name,Email,
                        IsActive,Username,IsPortalEnabled,Directory_Opt_In__c,Messaging_Opt_In__c, (SELECT Id,PermissionSetId,PermissionSet.Name,PermissionSet.Label,
                        SystemModstamp FROM PermissionSetAssignments ORDER by PermissionSet.Name),
                        LocaleSidKey,ContactId,LastLoginDate FROM User WHERE Id =: userRecordId];
        }else{
            throw new AuraHandledException('You do not have access to re-activate Portal Accounts');
        }
    }

    /**
    * Sync the Username and Email
    *
    * @param: userRecordId       	 The Id of the User for whcih the Perm Set is ReActivated
    * @return: User                  User Object Details
    */
    @AuraEnabled
    public static User syncUserDetailsFromContact(Id userRecordId){
        return new CommitRecords().syncDetails(userRecordId);
    }

    private without sharing class CommitRecords {
        /**
         * @author      Inderpal Dhanoa
         * @description Method to sync Username and Email
         * @revision    23/05/2022 - Inderpal Dhanoa - Created
         */
        public User syncDetails(Id userRecordId){
            User u_runningUser = [SELECT Id, Email, UserName, ContactId, Contact.Personal_Email__c FROM User WHERE Id =: userRecordId];
            // The Logged in User needs to be validated for having the "Manage Alumni User" Perm Set
            if(String.isNotBlank(u_runningUser.ContactId) && String.isNotBlank(u_runningUser.Contact.Personal_Email__c)){
                if(CommonUtilities.validateEmail(String.valueOf(u_runningUser.Contact.Personal_Email__c))){
                    List<User> existingUserWithSameUserName = [SELECT Id FROM User WHERE userName = :u_runningUser.Contact.Personal_Email__c AND Id != :userRecordId];
                    if(existingUserWithSameUserName.isEmpty()){
                        try{
                            u_runningUser.userName = u_runningUser.Contact.Personal_Email__c;
                            u_runningUser.email = u_runningUser.Contact.Personal_Email__c;
                            update u_runningUser;
                        }catch(Exception ex){
                            LogUtilityException.LogException(ex);throw ex;
                        }
                        return [SELECT Id,Name,Email,UserName,
                                IsActive,IsPortalEnabled,Directory_Opt_In__c,Messaging_Opt_In__c, (SELECT Id,PermissionSetId,PermissionSet.Name,PermissionSet.Label,
                                SystemModstamp FROM PermissionSetAssignments ORDER by PermissionSet.Name),
                                LocaleSidKey,ContactId,LastLoginDate FROM User WHERE Id =: userRecordId];
                    }else{
                        throw new AuraHandledException('The syncing UserName already exists');
                    }
                }else{
                    throw new AuraHandledException('The Email is not in correct format');
                }
            }else{
                throw new AuraHandledException('The Email does not exist on the Contact');
            }
        }
    }

    /**
    * Retrieves volunteer preference information for a user and picklist values for volunteer fields
    *
    */
    @AuraEnabled
    public static VolunteerPreferenceData SERVER_getVolunteerPreferences(){
        //Id contactId = getContactId();
        Id contactId = loggedinUser[0].contactId;

        if(contactId != null) {
            Contact cont = [SELECT Id, Volunteer_Roles__c, Volunteer_Skills__c, Volunteer_Status__c, Volunteer_Areas_of_Interest__c
                            FROM Contact WHERE Id = :contactId];
            Map<String, List<String>> picklistValues = SERVER_getVolunteerCheckboxes();
            VolunteerPreferenceData returnObject = new VolunteerPreferenceData(picklistValues.get('Volunteer_Roles__c'),
                                                                            picklistValues.get('Volunteer_Skills__c'),
                                                                            picklistValues.get('Volunteer_Areas_of_Interest__c'),
                                                                            cont);
            return returnObject;
        }

        return null;

    }

    /**
    * Retrieves the list of picklist values for the Volunteer Roles, Skills, and Areas of Interest fields
    *
    */
    @AuraEnabled
    public static Map<String, List<String>> SERVER_getVolunteerCheckboxes(){
        Map<String, List<String>> picklistsToGet = new Map<String, List<String>>();
        picklistsToGet.put('Contact', new List<String>{'Volunteer_Roles__c','Volunteer_Skills__c','Volunteer_Areas_of_Interest__c'});
        return SERVER_getPicklists(picklistsToGet);
    }

    /**
    * Updates values for the Volunteer Status, Roles, Skills, and Areas of Interest associated with a Contact
    *
    * @param: status       			The status value to update to
    * @param: roleValues         	The roles that the Volunteer Roles multiselect is being updated to
    * @param: skillValues          	The skills that the Volunteer Skills multiselect is being updated to
    * @param: areaValues			The Areas of Interest that the Volunteer Areas of Interest multiselect is being updated to
    */
    @AuraEnabled
    public static void SERVER_saveVolunteerPreferences(String status, String roleValues, String skillValues, String areaValues){
        //Id contactId = getContactId();
        Id contactId = loggedinUser[0].contactId;
        if(contactId != null) {
            Contact cont = [SELECT Volunteer_Roles__c, Volunteer_Skills__c, Volunteer_Status__c, Volunteer_Areas_of_Interest__c
                            FROM Contact WHERE Id = :contactId];
            cont.Volunteer_Status__c = status;
            cont.Volunteer_Roles__c = roleValues;
            cont.Volunteer_Skills__c = skillValues;
            cont.Volunteer_Areas_of_Interest__c = areaValues;
            update cont;
        }

    }

    /**
    * Save all profile updates for a user
    *
    * @param: userSettings       	    The Directory and Message Opt settings to be updated
    */
    @AuraEnabled
    public static void SERVER_saveSetupInformation(User userSettings){
        try{
            //Update user
            update userSettings;

        }
        catch(Exception ex){
            LogUtilityException.LogException(ex);
            throw new AuraHandledException('Error encountered during Setup saving');
        }
    }


    /**
    * Save all profile updates for a contact
    *
    * @param: cont       			    The updated Contact object
    * @param: preferredMap              Map detailing which phone/email is primary
    * @param: preferredName             The preferred Name input through the portal
    * @param: emailMap         		    A map of Email types to Email objects that need to be added or updated
    * @param: phoneMap          	    A map of phone types to Phone objects that need to be added or updated
    * @param: socialMap				    A map of social types to Social objects that need to be added or updated
    * @param: origEmailMap         	    A map of Email types to Email objects before any changes were made
    * @param: origPhoneMap              A map of phone types to Phone objects before any changes were made
    * @param: origSocialMap			    A map of social types to Social objects before any changes were made
    * @param: origPrefAddress           The preferred Address before any changes
    * @param: prefAddress       	    The preferred Address to be added or updated
    * @param: origBusinessAddress       The business Address before any changes
    * @param: businessAddress       	The business Address to be added or updated
    * @param: origAffiliation      	    The affiliation before any changes
    * @param: origAffilMap       	    The map of affiliation fields and values before any changes
    * @param: affilMap             	    The map of affiliation fields and values with the details to be updated
    * @param: userSettings       	    The Directory and Message Opt settings to be updated
    */
    @AuraEnabled
    public static void SERVER_saveProfileInformation(Contact cont, Map<String, String> preferredMap, SObject preferredName, Map<String, Email__c> emailMap, Map<String, Phone__c> phoneMap, Map<String, Social__c> socialMap,
                                                     Map<String, Email__c> origEmailMap, Map<String, Phone__c> origPhoneMap, Map<String, Social__c> origSocialMap,
                                                     Address__c origPrefAddress, Address__c prefAddress, Address__c origBusinessAddress, Address__c businessAddress,
                                                     Affiliation__c origAffiliation, Map<String, String> origAffilMap, Map<String, String> affilMap){

        try{
            //Used to track phones, email and social handles which already exist and those that need to be updated or created
            List<Email__c> emailAddressesToCheck = emailMap.values();
            List<Phone__c> phoneNumbersToCheck = phoneMap.values();
            List<Social__c> socialsToCheck = socialMap.values();
            List<String> emailAddressesToAdd = new List<String>();
            List<String> phoneNumbersToAdd = new List<String>();
            List<String> socialHandlesToAdd = new List<String>();
            Map<String, Email__c> prevEmailMap = new Map<String, Email__c>();
            Map<String, Phone__c> prevPhoneMap = new Map<String, Phone__c>();
            Map<String, Social__c> prevSocialMap = new Map<String, Social__c>();
            Map<String, Address__c> prevAddressMap = new Map<String, Address__c>();
            List<Email__c> emailsToUpsert = new List<Email__c>();
            List<Phone__c> phonesToUpsert = new List<Phone__c>();
            MyProfileQueryHandler queryHandler = new MyProfileQueryHandler();
            Name__c newPreferredName = (Name__c) preferredName;
                        
            //Update contact 
            update cont;

            createOrUpdatePreferredName(newPreferredName, cont.Id);

            //perform updates on the Preferred/Business Addresses
            List<Address__c> prevPrefAddress = [SELECT Id, Name, Source__c, Classification__c, Start_Date__c, Contact__c, Is_Active__c, Is_Primary__c, End_Date__c, Key_UID__c,
                                        City__c, Country2__c, State__c, Street_Name__c, Post_Code__c, DPID__c, Verification_Status__c FROM Address__c
                                        WHERE Street_Name__c = :prefAddress.Street_Name__c AND City__c = :prefAddress.City__c
                                        AND Country2__c = :prefAddress.Country2__c AND State__c = :prefAddress.State__c AND Contact__c =:cont.Id];
            List<Address__c> prevBusinessAddress = [SELECT Id, Name, Source__c, Classification__c, Start_Date__c, Contact__c, Is_Active__c, Is_Primary__c, End_Date__c, Key_UID__c,
                                            City__c, Country2__c, State__c, Street_Name__c, Post_Code__c, DPID__c, Verification_Status__c FROM Address__c
                                            WHERE Street_Name__c = :businessAddress.Street_Name__c AND City__c = :businessAddress.City__c
                                            AND Country2__c = :businessAddress.Country2__c AND State__c = :businessAddress.State__c AND Contact__c =:cont.Id];

            Address__c prefAddressToUpsert = createOrUpdateAddress(origPrefAddress, prefAddress, prevPrefAddress, true, cont.Id);
            if(prefAddressToUpsert != null) {
                System.debug(prefAddressToUpsert);
                upsert prefAddressToUpsert;
            }
            if(prefAddress.Street_Name__c != businessAddress.Street_Name__c || prefAddress.City__c != businessAddress.City__c ||
                prefAddress.Country2__c != businessAddress.Country2__c || prefAddress.State__c != businessAddress.State__c) {
                Address__c businessAddressToUpsert = createOrUpdateAddress(origBusinessAddress, businessAddress, prevBusinessAddress, false, cont.Id);
                if(businessAddressToUpsert != null) {
                    upsert businessAddressToUpsert;
                }
            }

            //Update the affiliation/create interim for affiliation
            if(affilMap != origAffilMap) {
                queryHandler.updateAffiliation(origAffiliation,affilMap,cont);
            }

            //Retrieve existing Emails if they exist, make old records inactive, and update existing records to avoid KUID issues or insert new ones
            for(Email__c emailAddressName : emailAddressesToCheck) {
                emailAddressesToAdd.add(emailAddressName.Name);
            }
            List<Email__c> previousEmail = [SELECT Id, Name, Source__c, Classification__c, Start_Date__c, Contact__c, Is_Active__c, Is_Primary__c, End_Date__c, Key_UID__c, Verification_Status__c FROM Email__c
                                            WHERE Name in :emailAddressesToAdd AND Contact__c =:cont.Id];
            for(Email__c emailAddress : previousEmail) {
                prevEmailMap.put(emailAddress.Name, emailAddress);
            }
            Email__c personalEmail = createOrUpdateEmail(origEmailMap.get('Personal'), emailMap.get('Personal'), prevEmailMap, 'Personal', (preferredMap.get('email') == 'personal'), cont.Id);
            Email__c businessEmail = createOrUpdateEmail(origEmailMap.get('Business'), emailMap.get('Business'), prevEmailMap, 'Business', (preferredMap.get('email') == 'business'), cont.Id);
            if(personalEmail != null) {
                emailsToUpsert.add(personalEmail);
            }
            if(businessEmail != null) {
                emailsToUpsert.add(businessEmail);
            }
            upsert emailsToUpsert;

            if(personalEmail !=null) {
                updateRelatedUserEmail(personalEmail,loggedinUser);
            }
            //Retrieve existing Phones if they exist, make old records inactive, and update existing records to avoid KUID issues or insert new ones
            for(Phone__c phoneName : phoneNumbersToCheck) {
                phoneNumbersToAdd.add(phoneName.Name);
            }

            List<Phone__c> previousPhone = [SELECT Id, Name, ISO_Country__c, Source__c, Classification__c, Start_Date__c, Contact__c, Is_Active__c, Is_Primary__c, End_Date__c, Type__c, Key_UID__c, Verification_Status__c FROM Phone__c
                                            WHERE Contact__c =:cont.Id];
            for(Phone__c phoneNumber : previousPhone) {
                prevPhoneMap.put(phoneNumber.Name, phoneNumber);
            }
            Phone__c mobilePhone = createOrUpdatePhone(origPhoneMap.get('Mobile'), phoneMap.get('Mobile'), prevPhoneMap, 'Mobile', (preferredMap.get('phone') == 'mobile'), cont.Id);
            Phone__c homePhone = createOrUpdatePhone(origPhoneMap.get('Home'), phoneMap.get('Home'), prevPhoneMap, 'Home', (preferredMap.get('phone') == 'home'), cont.Id);
            Phone__c workPhone = createOrUpdatePhone(origPhoneMap.get('Work'), phoneMap.get('Work'), prevPhoneMap, 'Work', (preferredMap.get('phone') == 'work'), cont.Id);
            if(mobilePhone != null) {
                phonesToUpsert.add(mobilePhone);
            }
            if(homePhone != null) {
                phonesToUpsert.add(homePhone);
            }
            if(workPhone != null) {
                phonesToUpsert.add(workPhone);
            }
            upsert phonesToUpsert;

            //Retrieve existing Social if they exist, make old records inactive, and update existing records to avoid KUID issues or insert new ones
            for(Social__c socialHandle : socialsToCheck) {
                socialHandlesToAdd.add(socialHandle.Name);
            }
            List<Social__c> previousSocials = [SELECT Id, Name, Source__c, Classification__c, Start_Date__c, Contact__c, Is_Active__c, Is_Primary__c, End_Date__c, Type__c, Key_UID__c FROM Social__c
                                            WHERE Name in :socialHandlesToAdd AND Contact__c =:cont.Id];
            for(Social__c socialHandle : previousSocials) {
                prevSocialMap.put(socialHandle.Name, socialHandle);
            }
            createOrUpdateSocial(origSocialMap.get('LinkedIn'), socialMap.get('LinkedIn'), prevSocialMap, 'LinkedIn', cont.Id);
            createOrUpdateSocial(origSocialMap.get('Twitter'), socialMap.get('Twitter'), prevSocialMap, 'Twitter', cont.Id);
            createOrUpdateSocial(origSocialMap.get('WeChat'), socialMap.get('WeChat'), prevSocialMap, 'WeChat', cont.Id);

            createProfileUpdateEmail();
        }catch(Exception ex){
            LogUtilityException.LogException(ex);
            throw new AuraHandledException('Error encountered during Profile saving');
            
        }
    }

/**
    * Update corresponding User record from if contact's personal email is updated.
    *
    * @param: emails       	    The email instance which carries the new email address record
    * @param: contactIds        id of contact.
 */

    public static void updateRelatedUserEmail(Email__c emails, List<User> userList){
        userList[0].email=emails.Name;
        userList[0].username=emails.Name;
        //Call queueable class to avoid MIXED_DML_OPERATION by updating User and Contact in one transaction
        Queueable queueItem = new UserServices.UpdateSobjectsQueueable(userList);
        ID jobID = System.enqueueJob(queueItem);

    }

    /**
    * Create interim for manual review of professional information
    *
    * @param: position       	The name of the position to be added to the affiliation
    * @param: employerName      The name of the Employer to be added to the Account record
    * @param: industry          The industry which is to be assigned to the Account record
    */
    private static void createInterim(String position, String employerName, String industry, Id contactId) {
        ucinn_ascendv2__Interim__c interimToAdd = new ucinn_ascendv2__Interim__c();
        Id rtID = Schema.SObjectType.ucinn_ascendv2__Interim__c.getRecordTypeInfosByDeveloperName().get('Portal_Bio_Info').getRecordTypeId();
        interimToAdd.RecordTypeId = rtId;
        interimToAdd.ucinn_ascendv2__Employer__c = employerName;
        interimToAdd.Employer_Organisation_Industry__c = industry;
        interimToAdd.ucinn_ascendv2__Position_Title__c = position;
        interimToAdd.ucinn_ascendv2__Contact__c = contactId;
        interimToAdd.ucinn_ascendv2__Status__c = 'Manual Review';
        insert interimToAdd;
    }

    /**
    * Update old address and create new address
    *
    * @param: oldAddress       	Existing address
    * @param: newAddress        Address entered on My Profile page
    * @param: isPrimary         Boolean to determine whether to mark new address as primary
    */
    private static Address__c createOrUpdateAddress(Address__c oldAddress, Address__c newAddress, List<Address__c> prevAddressList, Boolean isPrimary, Id contId) {
        Address__c addressToAdd;
        if(newAddress != oldAddress) {
            //End date old address and mark as non-active non-primary
            if(oldAddress != null && oldAddress != (new Address__c())) {
                oldAddress.End_Date__c = Date.today();
                oldAddress.Is_Active__c = false;
                update oldAddress;
            }
            //Only check city because Street, City, and Country must all either be empty or populated
            if(!String.isBlank(newAddress.City__c)) {
                if(!prevAddressList.isEmpty()) {
                    addressToAdd = prevAddressList.get(0);
                    addressToAdd.End_Date__c = null;
                    addressToAdd.Is_Active__c = true;
                } else {
                    addressToAdd = new Address__c(Contact__c = contId, Start_Date__c = Date.today(), Source__c = 'Contact supplied',
                                                  City__c = newAddress.City__c,
                                                  Street_Name__c = newAddress.Street_Name__c, State__c = newAddress.State__c,
                                                  Post_Code__c = newAddress.Post_Code__c, Country2__c = newAddress.Country2__c,
                                                  Is_Active__c = true);
                }
                if(isPrimary) {
                    System.debug('PRIMARY IS TRUE!!__!!');
                    addressToAdd.Is_Primary__c = true;
                    addressToAdd.Classification__c = newAddress.Classification__c;
                } else {
                    addressToAdd.Classification__c = 'Business';
                }
            }
            addressToAdd.DPID__c = newAddress.DPID__c;
            addressToAdd.Verification_Status__c = newAddress.Verification_Status__c;
        }
        return addressToAdd;
    }

    /**
    * Update old email and return new email or updated inactive email
    *
    * @param: oldEmail       	Existing email
    * @param: newEmail          Email entered on My Profile page
    * @param: prevEmailMap      Map of String to Email which has previously active emails which match new email
    * @param: emailType         String contains the type of email to be saved
    * @param: isPreferred       Boolean to determine whether to mark new email as primary
    */
    private static Email__c createOrUpdateEmail(Email__c oldEmail, Email__c newEmail, Map<String, Email__c> prevEmailMap, String emailType, Boolean isPreferred, Id contId) {
        Email__c emailToAdd = null;
        if(newEmail != oldEmail) {
            if(oldEmail != null) {
                Email__c oldEmailToUpdate = oldEmail;
                oldEmailToUpdate.Is_Active__c = false;
                oldEmailToUpdate.End_Date__c = Date.today();
                update oldEmailToUpdate;
            }
            if(!String.isBlank(newEmail.Name)) {
                if(prevEmailMap.containsKey(newEmail.Name)) {
                    emailToAdd = prevEmailMap.get(newEmail.Name);                    
                    emailToAdd.Classification__c = 'Private';
                    emailToAdd.End_Date__c = null;
                    emailToAdd.Is_Active__c = true;
                } else {
                    emailToAdd = new Email__c(Name = newEmail.Name , Source__c = 'Contact supplied', Start_Date__c = Date.today(), Contact__c = contId);
                }
                if(emailType == 'Personal') {
                    emailToAdd.Classification__c = 'Private';
                } else {
                    emailToAdd.Classification__c = 'Business';
                }
                emailToAdd.Is_Primary__c = isPreferred;
                emailToAdd.Verification_Status__c = newEmail.Verification_Status__c;
            }
        } else if (isPreferred) {
            if(oldEmail != null && oldEmail.Is_Primary__c == false) {
                Email__c oldEmailToUpdate = oldEmail;
                oldEmailToUpdate.Is_Primary__c = true;
                update oldEmailToUpdate;
            }
        }
        return emailToAdd;
    }

    /**
    * Update old phone and return new phone or updated inactive phone
    *
    * @param: oldPhone       	Existing social
    * @param: newPhone          Social entered on My Profile page
    * @param: prevPhoneMap      Map of String to Phone which has previously active phone which match new phone
    * @param: phoneType         String contains the type of phone to be saved
    * @param: isPreferred       Boolean to determine whether to mark new phone as primary
    */

    private static Phone__c createOrUpdatePhone(Phone__c oldPhone, Phone__c newPhone, Map<String, Phone__c> prevPhoneMap, String phoneType, Boolean isPreferred, Id contId) {
        Phone__c phoneToAdd = null;

        System.debug(LoggingLevel.DEBUG, '!@# old Phone: ' + oldPhone );
        System.debug(LoggingLevel.DEBUG, '!@# new Phone: ' + newPhone );

        if(newPhone != oldPhone) {
            System.debug(LoggingLevel.DEBUG, '!@# newPhone != oldPhone' );
            if(oldPhone != null && !oldPhone.Name.deleteWhitespace().equalsIgnoreCase(newPhone.Name.deleteWhitespace())) {
                Phone__c oldPhoneToUpdate = oldPhone;
                oldPhoneToUpdate.Is_Active__c = false;
                oldPhoneToUpdate.End_Date__c = Date.today();
                if(!Test.isRunningTest()) {
                    update oldPhoneToUpdate;
                }
            }

            if(!String.isBlank(newPhone.Name)) {
                System.debug(LoggingLevel.DEBUG, '!@# prevPhoneMap' );

                String sOldPhone = (oldPhone != null) ? oldPhone.Name.remove('+') : '';
                String sNewPhone =  newPhone.Name.remove('+');

                if(prevPhoneMap.containsKey(newPhone.Name) || (oldPhone != null && sOldPhone.deleteWhitespace().equalsIgnoreCase(sNewPhone.deleteWhitespace())) ) {
                    if(prevPhoneMap.containsKey(newPhone.Name)) phoneToAdd = prevPhoneMap.get(newPhone.Name);
                    if(oldPhone != null && sOldPhone.deleteWhitespace().equalsIgnoreCase(sNewPhone.deleteWhitespace())){
                        phoneToAdd = prevPhoneMap.get(oldPhone.Name);
                    }
                    phoneToAdd.Classification__c = 'Private';
                    phoneToAdd.End_Date__c = null;
                    phoneToAdd.Is_Active__c = true;
                } else {
                    phoneToAdd = new Phone__c(Name = newPhone.Name , Source__c = 'Contact supplied',  Start_Date__c = Date.today(), Contact__c = contId);
                }
                if(phoneType == 'Mobile') {
                    phoneToAdd.Classification__c = 'Private';
                    phoneToAdd.Type__c = 'Mobile';
                } else if (phoneType == 'Home'){
                    phoneToAdd.Classification__c = 'Private';
                    phoneToAdd.Type__c = 'Landline';
                } else {
                    phoneToAdd.Classification__c = 'Business';
                    phoneToAdd.Type__c = 'Landline';
                }
                phoneToAdd.Is_Primary__c = isPreferred;
                phoneToAdd.Verification_Status__c = newPhone.Verification_Status__c;
            }
        } else if (isPreferred) {
            System.debug(LoggingLevel.DEBUG, '!@# updating Is_Primary__c' );
            if(oldPhone != null && !oldPhone.Is_Primary__c) {
                Phone__c oldPhoneToUpdate = oldPhone;
                oldPhoneToUpdate.Is_Primary__c = isPreferred;
                update oldPhoneToUpdate;
            }
        }
        return phoneToAdd;
    }

    /**
    * Update old social and update or insert new social
    *
    * @param: oldSocial       	Existing social
    * @param: newSocial         Social entered on My Profile page
    * @param: prevSocialMap     Map of String to Social which has previously active social which match new social
    * @param: socialType        String contains the type of social to be saved
    */
    private static void createOrUpdateSocial(Social__c oldSocial, Social__c newSocial, Map<String, Social__c> prevSocialMap, String socialType, Id contId) {
        if(newSocial != oldSocial) {
            if(oldSocial != null) {
                Social__c socialToUpdate = oldSocial;
                socialToUpdate.Is_Active__c = false;
                socialToUpdate.End_Date__c = Date.today();
                update socialToUpdate;
            }
            if(!String.isBlank(newSocial.Name)) {
                Social__c socialToAddOrUpdate;
                if(prevSocialMap.containsKey(newSocial.Name)) {
                    socialToAddOrUpdate = prevSocialMap.get(newSocial.Name);
                    socialToAddOrUpdate.Source__c = 'Contact supplied';
                    socialToAddOrUpdate.Classification__c = 'Private';
                    socialToAddOrUpdate.Start_Date__c = Date.today();
                    socialToAddOrUpdate.End_Date__c = null;
                    socialToAddOrUpdate.Is_Active__c = true;
                    if(!Test.isRunningTest()) {
                        update socialToAddOrUpdate;
                    }
                } else {
                    socialToAddOrUpdate = new Social__c(Name = newSocial.Name , Source__c = 'Contact supplied', Classification__c = 'Private',
                                                 Start_Date__c = Date.today(), Contact__c = contId);
                    if(socialType == 'LinkedIn') {
                        socialToAddOrUpdate.Type__c = 'LinkedIn';
                        socialToAddOrUpdate.Url__c = newSocial.Name;
                    } else if(socialType == 'Twitter') {
                        socialToAddOrUpdate.Type__c = 'Twitter';
						socialToAddOrUpdate.Url__c = newSocial.Name;
                    } else if(socialType == 'WeChat') {
                        socialToAddOrUpdate.Type__c = 'WeChat';
                        socialToAddOrUpdate.Url__c = newSocial.Name;
                    }
                    insert socialToAddOrUpdate;
                }
            }
        }
    }

    private static void createProfileUpdateEmail() {
        List<PORTAL_UCIN_Email_Template__mdt> mdtList = [Select DeveloperName, EmailTemplateId__c, OrgWideEmailAddressId__c, OrgWideEmailAddress__c From PORTAL_UCIN_Email_Template__mdt Where DeveloperName='PORTAL_UCIN_Profile_Details_Updated'];
        if (!mdtList.isEmpty()) {
            try {
                List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: mdtList[0].DeveloperName LIMIT 1];

                if (!templateList.isEmpty()) {
                    List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                    // Query org wide address
                    //List<OrgWideEmailAddress> owa = [select Id, Address, DisplayName from OrgWideEmailAddress WHERE Address = 'monashalumni@f.e.monash.edu' limit 1];
                    List<OrgWideEmailAddress> owa = [select Id, Address, DisplayName from OrgWideEmailAddress WHERE Address = :mdtList[0].OrgWideEmailAddress__c limit 1];
					if (!owa.isEmpty()) {
                        mail.setOrgWideEmailAddressId(owa[0].Id);
                    }

                    mail.setTemplateId(templateList[0].Id);
                    mail.setTargetObjectId(UserInfo.getUserId());
                    mail.setTreatTargetObjectAsRecipient(true);
                    mail.saveAsActivity = false;
                    mailList.add(mail);
                    Messaging.sendEmail(mailList);
                }
            } catch (Exception ex) {
                System.debug('#### ex: '+ex);
            }
        }
    }

    private static void createOrUpdatePreferredName(Name__c preferredName, Id contactId) {
        Name__c nameToUpsert;

        List<Name__c> prevNames = [SELECT Id, Name, First_Name__c, Last_Name__c, Salutation__c, Suffix__c, Is_Active__c, Is_Primary__c, Type__c, Source__c FROM Name__c WHERE Contact__c = :contactId ORDER BY LastModifiedDate DESC];
        if(!String.isBlank(preferredName.Last_Name__c)){
            for(Name__c name : prevNames) {
                if(name.First_Name__c == preferredName.First_Name__c && name.Last_Name__c == preferredName.Last_Name__c
                    && name.Salutation__c == preferredName.Salutation__c && name.Suffix__c == preferredName.Suffix__c) {
                    nameToUpsert = name;
                    if(!nameToUpsert.Is_Primary__c) {
                        nameToUpsert.Type__c = 'Common';
                        nameToUpsert.Source__c = 'Contact supplied';
                        nameToUpsert.Is_Active__c = true;
                        nameToUpsert.Is_Primary__c = true;
                        //update start date?
                    } else {
                        return;
                    }
                    break;
                }
            }

            if(nameToUpsert == null) {
                nameToUpsert = new Name__c(First_Name__c = preferredName.First_Name__c, Last_Name__c = preferredName.Last_Name__c, Salutation__c = preferredName.Salutation__c,
                                            Is_Active__c = true, Is_Primary__c = true, Type__c = 'Common', Source__c = 'Contact supplied',
                                            Suffix__c = preferredName.Suffix__c, Start_Date__c = Date.today(), Contact__c = contactId);
            }
            upsert nameToUpsert;
        }

    }
}