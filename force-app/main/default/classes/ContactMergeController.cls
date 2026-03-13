/*******************************************************************************
* @author       Russell Cadapan
* @date         20/11/2020
* @description  Service class for ContactMergeWizard LWC
* @revision     1.0
*               Paul Victoriano 23.Apr.2021 - add without sharing context
*               Paul Victoriano 28.Apr.2021 - Link to EPCP-1184
*               Paul Victoriano 2.Jul.2021 - Link to EPCP-1244
*               Paul Victoriano 25.Aug.2021 - Link to EPCP-1611
*               Russell Cadapan 06.Dec.2021 - Link to EPCP-1735: Extending the contact matches through Contact Point Search
*               Paul Victoriano 28.Jun.2023 - Link to EPCP-2841
*******************************************************************************/
public without sharing class ContactMergeController {
    public static String MERGE_STATUS_INPROGRESS = 'In Progress';
    public static String MERGE_STATUS_COMPLETED = 'Completed';
    public static String USER_OBJECT = 'User';
    public static String CONTACT_OBJECT = 'Contact';

    /**
     * @description hasValidationBypass checks for Custom permissions
     * @author pvic0002
     * @return   return boolean
     */ 
    @AuraEnabled
    public static Boolean hasValidationBypass() {
        Boolean accessBool = false;
        try {
            accessBool = FeatureManagement.checkPermission('Contact_Merge_Bypass_Check');
        } catch (Exception e) {
            LogUtilityException.logException(e);
        }
        return accessBool;
    }

    /**
     * @description elevatePermissions Activates / Deactivates Session assigned permissions
     * @param  isElev true/false
     */
    @AuraEnabled
    public static Boolean elevatePermissions(Boolean isElev) {
        //Retrieve Required Permission Sets for Contact Merge
        Map<String, Id> mapCMperms = new Map<String,Id>();
        for (PermissionSet ps :[SELECT Id, Name FROM PermissionSet WHERE Name = 'Manage_User_and_Modify_All_Data' OR Name = 'Contact_Merge_App_Access']) {
            mapCMperms.put(ps.Name, ps.Id);
        }
        //Check if Contact Merge App Access Permission Set is assigned
        if (mapCMperms.containsKey('Contact_Merge_App_Access')) {
            Id conPSId = mapCMperms.get('Contact_Merge_App_Access');
            Id userId = UserInfo.getUserId();
            Integer psaAssigned = [SELECT count() FROM PermissionSetAssignment WHERE
                                   AssigneeId =:userId AND
                                                PermissionSetId =:conPSId];
            if (psaAssigned > 0) {
                Map<String, String> sessionInfo = new Map<String, String>();
                List<SessionPermSetActivation> lspsa = new List<SessionPermSetActivation>();
                //Not Testable System.UnexpectedException: Current session unavailable due to context
                if (!Test.isRunningTest()) {
                    sessionInfo = Auth.SessionManagement.getCurrentSession();
                }
                String parentSession = sessionInfo.get('ParentId');
                String sessionId = sessionInfo.get('SessionId');
                if (String.isNotBlank(parentSession)) {
                    sessionId = parentSession;
                }
                if (!Test.isRunningTest()) {
                    lspsa = [SELECT Id FROM SessionPermSetActivation
                             WHERE AuthSessionId = :sessionId
                                                   AND PermissionSetId = :mapCMperms.get('Manage_User_and_Modify_All_Data')
                                                                         LIMIT 1];
                }
                if (isElev == true && mapCMperms.containsKey('Manage_User_and_Modify_All_Data')) {
                    // activate the permission set
                    SessionPermSetActivation activation = new SessionPermSetActivation();
                    activation.AuthSessionId = sessionId;
                    activation.PermissionSetId = mapCMperms.get('Manage_User_and_Modify_All_Data');
                    activation.Description = 'Created by ContactMergeController';
                    //Add Permissions if Empty
                    if (!Test.isRunningTest() && lspsa.isEmpty()) {
                        insert activation;
                    }
                } else if (isElev == false && mapCMperms.containsKey('Manage_User_and_Modify_All_Data')) {
                    delete lspsa;
                }
            }
        }
        return true;
    }

    /*
     * Method Name: getEntityData
     * Description: method to query and generate the entity data wrapper that contains Contact, Account, and User object
     */
    @AuraEnabled
    public static List<ContactMergeData> getEntityData(String firstName, String lastName, String email, String personId, String contactId) {
        List<ContactMergeData> entityDataList = new List<ContactMergeData>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, DuplicateFieldInfo> duplicateContactIds = new Map<Id,DuplicateFieldInfo>();
        if (String.isNotBlank(contactId)) {
            contactIds.add(contactId.trim());
        }
        // search contact records
        Map<Id,Contact> searchedContactList = new Map<Id,Contact>(ContactMergeHelper.getContacts(firstName, lastName, email, personId, contactIds));
        if (!searchedContactList.isEmpty()) {
            if (searchedContactList.size() <= 25) {
                Set<Id> setTemp = new Set<Id>(searchedContactList.keySet());
                // set the identified duplicate contact record's id
                duplicateContactIds = ContactMergeHelper.findDuplicateContacts(setTemp);
                // re-trigger the findDuplicateContacts method trying to retrieve the contact queried by person/record Id as a potential duplicate
                if (String.isNotBlank(personId) || String.isNotBlank(contactId)) {
                    if (duplicateContactIds.size() <= 25) {
                        duplicateContactIds = ContactMergeHelper.findDuplicateContacts(duplicateContactIds.keySet());
                    }
                }
                if (!duplicateContactIds.isEmpty()) {
                    // if duplicates are found, query the related user and generate the wrapper
                    Map<Id,Contact> duplicatedContactList = new Map<Id,Contact>(
                        ContactMergeHelper.getContacts(null, null, null, null, duplicateContactIds.keySet())
                        );
                    entityDataList = formDataList(duplicatedContactList, duplicateContactIds, false);
                }
            }
        }
        if (searchedContactList.size() > 25 || duplicateContactIds.size() > 25) {
            throw new CustomException('Too many records found. Please refine your search parameters.');
        }
        if (!searchedContactList.isEmpty()) {
            if (duplicateContactIds.isEmpty()) {
                List<ContactMergeData> matchedContacts = getMatchingContactPoints(firstName,lastName,email,new Set<Id> {});
                if (matchedContacts.size() > 1) {
                    entityDataList.addAll(matchedContacts);
                }
            } else   {
                entityDataList.addAll(getMatchingContactPoints(firstName,lastName,email,duplicateContactIds.keySet()));
            }
        }
        return entityDataList;
    }

    /*
     * Method Name: getMatchingContactPoints
     * Description: method to find matching contacts through contact points based from search parameter
     */
    public static List<ContactMergeData> getMatchingContactPoints(String fname, String lname, String email, Set<Id> duplicateContactIds) {
        List<ContactMergeData> cmdList = new List<ContactMergeData>();
        Set<Id> cpContactIds = new Set<Id>();
        if (String.isNotBlank(email)) {
            cpContactIds.addAll(ContactMergeHelper.findPotentialDuplicateContactsByEmail(email.trim()));
        }
        if (String.isNotBlank(lname)) {
            cpContactIds.addAll(ContactMergeHelper.findPotentialDuplicateContactsByName(fname.trim(), lname.trim()));
        }
        Set<Id> matchingContactIds = new Set<Id>();
        for (Id i: cpContactIds) {
            if (!duplicateContactIds.contains(i)) {
                matchingContactIds.add(i);
            }
        }
        // perform SOQL to retrieve contact records that are matched with the contact points
        Map<Id,Contact> contactMatchedFromContactPointsMap;
        if (!matchingContactIds.isEmpty()) {
            contactMatchedFromContactPointsMap = new Map<Id,Contact>(ContactMergeHelper.getContacts(null, null, null, null, matchingContactIds));
        }
        Map<Id, DuplicateFieldInfo> contactPointDFIMap;
        if (contactMatchedFromContactPointsMap != null && !contactMatchedFromContactPointsMap.isEmpty()) {
            contactPointDFIMap = new Map<Id, DuplicateFieldInfo>();
            // generate DuplicateFieldInfo for each contact
            for (Contact c: contactMatchedFromContactPointsMap.values()) {
                DuplicateFieldInfo dfi = new DuplicateFieldInfo();
                dfi.recordId = c.Id;
                dfi.dupRuleName = 'Contact_Point_Match';
                dfi.matchDescription = 'Contact Point Match 10';
                contactPointDFIMap.put(c.Id, dfi);
            }
            cmdList = formDataList(contactMatchedFromContactPointsMap, contactPointDFIMap, true);
        }
        return cmdList;
    }

    /**
     * formDataList Helper method to Form Data List
     * @param  duplicatedContactList duplicatedContactList description
     * @param  duplicateContactIds   duplicateContactIds description
     * @param  conEmailMatchSet      conEmailMatchSet description
     * @return                       return description
     */
    @TestVisible
    private static List<ContactMergeData> formDataList(Map<Id,Contact> duplicatedContactList, Map<Id, DuplicateFieldInfo> duplicateContactIds, Boolean isExtension) {
        List<ContactMergeData> entityDataList = new List<ContactMergeData>();
        // get the users related to the contact
        Map<Id, User> userContactMap = new Map<Id, User>();
        for (User u : [SELECT Id, Username, FirstName, LastName, FederationIdentifier, Email, ContactId, LastLoginDate,
                       (SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.Type FROM PermissionSetAssignments ORDER BY PermissionSet.Name)
                       FROM User WHERE ContactId IN:duplicatedContactList.keySet() AND IsActive = TRUE]) {
            userContactMap.put(u.ContactId, u);
        }
        // generate the list of entity data
        for (Contact con : duplicatedContactList.values()) {
            ContactMergeData data = new ContactMergeData(con, null, duplicateContactIds.get(con.Id));
            // map the user record
            if (userContactMap.containsKey(con.Id)) {
                data.linkUser(userContactMap.get(con.Id));
            }
            //
            entityDataList.add(data);
            //Sort Data everytime records comes in
            //entityDataList.sort();
        }
        if (!entityDataList.isEmpty()) {
            //Sort Data Final time records comes in
            entityDataList.sort();
            //
            ContactMergeData dataWrap = entityDataList.get(0);
            dataWrap.isPrimary = isExtension ? false: true;
            dataWrap.primaryClass = isExtension ? null : 'success';
        }
        return entityDataList;
    }

    /*
     * Method Name: mergeUser
     * Description: method to merge User records
     */
    @AuraEnabled
    public static MergeUserWrapper mergeUser(Id primaryUserId, Id duplicateUserId, List<Id> primaryPermSetIds, List<Id> duplicatePermSetIds) {
        MergeUserWrapper dupUserName = new MergeUserWrapper();
        List<PermissionSetLicenseAssign> psaLicInsert = new List<PermissionSetLicenseAssign>();
        List<PermissionSetAssignment> permissionAssignments = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> permissionAssignmentsGroup = new List<PermissionSetAssignment>();
        // map of account id and its record
        Map<Id, User> userObjectMap = new Map<Id, User>((List<User>) ContactMergeHelper.queryAllObjectFields(new Set<Id> {primaryUserId, duplicateUserId}));
        User primaryUser = userObjectMap.get(primaryUserId);
        User duplicateUser = userObjectMap.get(duplicateUserId);
        //Return the Duplicate Usernames to send notification email to surviving user
        //Do not Send on Monash email with FedId
        if (String.isNotBlank(duplicateUser.UserName) && String.isNotBlank(duplicateUser.Email)) {
            dupUserName.userName = duplicateUser.UserName;
            dupUserName.userId = duplicateUser.Id;
            dupUserName.email = duplicateUser.Email;
            dupUserName.federationId = duplicateUser.FederationIdentifier;
        }
        // set the federation id into the primary user record
        if (String.isBlank(primaryUser.FederationIdentifier)) {
            if (String.isNotBlank(duplicateUser.FederationIdentifier)) {
                primaryUser.FederationIdentifier = duplicateUser.FederationIdentifier;
            }
        }
        //For Linkage to Okta
        if (String.isBlank(primaryUser.MonashObjectId__c)) {
            if (String.isNotBlank(duplicateUser.MonashObjectId__c)) {
                primaryUser.MonashObjectId__c = duplicateUser.MonashObjectId__c;
            }
        }
        //Set Merge status and timestamp
        primaryUser.Duplicate_Merge_Status__c = 'In Progress';
        primaryUser.Last_Merge_Timestamp__c = DateTime.now();
        // flush the federation id from the duplicate user and deactivate it
        duplicateUser.IsActive = false;
        duplicateUser.FederationIdentifier = null;
        duplicateUser.MonashObjectId__c = '';
        duplicateUser.CommunityNickName = 'Disabled_' + String.valueOf(math.random()).substring(0,6);
        //re-assign permission set license assignment
        List<PermissionSetLicenseAssign> permAssignLics = new List<PermissionSetLicenseAssign>([SELECT Id, AssigneeId,PermissionSetLicenseId FROM PermissionSetLicenseAssign WHERE AssigneeId =: duplicateUser.Id]);
        if (permAssignLics != null && !permAssignLics.isEmpty()) {
            for (PermissionSetLicenseAssign psla:permAssignLics) {
                PermissionSetLicenseAssign pslaAss = new PermissionSetLicenseAssign();
                pslaAss.AssigneeId = primaryUser.Id;
                pslaAss.PermissionSetLicenseId = psla.PermissionSetLicenseId;
                //Add to list
                psaLicInsert.add(pslaAss);
            }
        }
        // re-assign permission sets to the surviving user (if not yet assigned)
        List<PermissionSetAssignment> permAssigns = new List<PermissionSetAssignment>(
            [SELECT AssigneeId,PermissionSetGroupId,PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =: duplicateUser.Id]
            );
        Set<Id> survivingPermissionSets = new Set<Id>(primaryPermSetIds);
        if (!permAssigns.isEmpty()) {
            for (PermissionSetAssignment psARec: permAssigns) {
                if (psARec.PermissionSetGroupId != null) {
                    permissionAssignmentsGroup.add(
                        new PermissionSetAssignment(
                            PermissionSetGroupId = psARec.PermissionSetGroupId,
                            AssigneeId = primaryUserId)
                        );
                } else  {
                    permissionAssignments.add(
                        new PermissionSetAssignment(PermissionSetId = psARec.PermissionSetId,
                                                    AssigneeId = primaryUserId)
                        );
                }
            }
        }
        try {
            //Seperate the updates of the user
            update duplicateUser;
            //
            update primaryUser;
            //
            if (!psaLicInsert.isEmpty()) {
                //Try insert new permissionset license assignment
                Database.insert(psaLicInsert,false);
            }
            //
            if (!permissionAssignments.isEmpty()) {
                //No need to track Duplicate Permission Set assignments
                Database.insert(permissionAssignments,false);
            }
            if (!permissionAssignmentsGroup.isEmpty()) {
                //No need to track Duplicate Permission Set assignments
                Database.insert(permissionAssignmentsGroup,false);
            }
            Map<Id,PermissionSetAssignment> permissionAssignmentsDelete = new Map<Id,PermissionSetAssignment>(
                [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId IN: duplicatePermSetIds AND AssigneeId = : duplicateUser.Id]
                );
            if (permissionAssignmentsDelete.isEmpty() == false) {
                delete permissionAssignmentsDelete.values();
            }
        }
        catch (Exception e) {
            LogUtilityException.logException(e);
            throw e;
        }
        return dupUserName;
    }

    /*
     * Method Name: mergeAccount
     * Description: method to merge Account records from the data wrapper
     */
    @AuraEnabled
    public static String mergeAccount(Id primaryAccountId, Id duplicateAccountId, Id primaryContactId) {
        Boolean hasLockRow = false;
        if (primaryAccountId != duplicateAccountId) {
            // map of account id and its record
            Map<Id, Account> accountObjectMap = new Map<Id, Account>();
            // query all fields
            accountObjectMap = new Map<Id, Account>((List<Account>) ContactMergeHelper.queryAllObjectFields(new Set<Id> {primaryAccountId, duplicateAccountId}));
            if (!accountObjectMap.isEmpty()) {
                // Before merging, perform mapping of surviving fields through iteration of custom metadata
                // DO HERE
                Account primaryAccount = accountObjectMap.get(primaryAccountId);
                Account duplicateAccount = accountObjectMap.get(duplicateAccountId);
                // Merge accounts into master
                try {
                    if (primaryAccount != null && duplicateAccount != null) {
                        // Before merging, perform mapping of surviving fields through iteration of custom metadata
                        primaryAccount = ContactMergeHelper.mapCompareAccount(primaryAccount, duplicateAccount);
                        //Copy over Primary Constituent values
                        if (primaryContactId != null) {
                            if (primaryAccount.ucinn_ascendv2__Primary_Contact__c != null || duplicateAccount.ucinn_ascendv2__Primary_Contact__c != null) {
                                primaryAccount.ucinn_ascendv2__Primary_Contact__c = primaryContactId;
                            }
                        }
                        //
                        performMerge(primaryAccount, duplicateAccount);
                    }
                }
                catch (Exception e) {
                    LogUtilityException.logException(e);
                    hasLockRow = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
                    if (hasLockRow == false) {
                        throw e;
                    }
                }
                //Implement a retry as possible for Locking due to same parent roll up  delays
                if (hasLockRow) {
                    performMerge(primaryAccount, duplicateAccount);
                }
            }
        }
        return 'Account:' + duplicateAccountId;
    }

    /*
     * Method Name: mergeContact
     * Description: method to merge Contact records from the data wrapper
     */
    @AuraEnabled
    public static String mergeContact(Id primaryContactId, Id duplicateContactId) {
        Boolean hasLockRow = false;
        if (primaryContactId != duplicateContactId) {
            // map of contact id and its record
            Map<Id, Contact> contactObjectMap = new Map<Id, Contact>();
            // query all fields
            contactObjectMap = new Map<Id, Contact>((List<Contact>) ContactMergeHelper.queryAllObjectFields(new Set<Id> {primaryContactId, duplicateContactId}));
            if (!contactObjectMap.isEmpty()) {
                Contact primaryContact = contactObjectMap.get(primaryContactId);
                Contact duplicateContact = contactObjectMap.get(duplicateContactId);
                // Merge accounts into master
                try {
                    if (primaryContact != null && duplicateContact != null) {
                        // Before merging, perform mapping of surviving fields through iteration of custom metadata
                        primaryContact = ContactMergeHelper.mapCompareContact(primaryContact, duplicateContact);
                        //Remove Constituent Dup Names
                        removeDupConstituentFullName(duplicateContact.Id);

                        Triggers.bypass('Person360RollDown'); // EPCP-2100

                        // bypass rollup; ContactMergePerson360 will do this instead
                        // this is causing significant locking contention and must soon be retired from Contact Trigger
                        Triggers.bypass('InvokeRollUpContactPointsAsync'); 

                        performMerge(primaryContact, duplicateContact);

                        Triggers.clearBypass('Person360RollDown');
                        Triggers.clearBypass('InvokeRollUpContactPointsAsync');
                    }
                }
                catch (Exception e) {
                    LogUtilityException.logException(e);
                    hasLockRow = e.getMessage()?.contains('UNABLE_TO_LOCK_ROW');
                    if (hasLockRow != null && hasLockRow == false) {
                        throw e;
                    }
                }
                //Implement a retry as possible for Locking due to same parent roll up  delays
                if (hasLockRow) {
                    performMerge(primaryContact, duplicateContact);
                }
            }
        }
        return 'Contact:' + duplicateContactId;
    }

    /**
     * @description removeDupConstituentFullName removes the default type for Constituent
     * @author pvic0002
     * @param  conId conId description
     * @return       return description
     */
    @TestVisible
    private static void removeDupConstituentFullName(Id conId) {
        List<ucinn_ascendv2__Contact_Name__c> constituentNames = [SELECT Id, ucinn_ascendv2__Type__c FROM ucinn_ascendv2__Contact_Name__c WHERE ucinn_ascendv2__Contact__c =:conId];
        if (constituentNames != null) {
            for (ucinn_ascendv2__Contact_Name__c rec :constituentNames) {
                rec.ucinn_ascendv2__Type__c = 'Other';
            }
            update constituentNames;
        }
    }

    /**
     * performMerge Perform Database Merge Operation
     * @param  primaryObj primaryObj description
     * @param  dupObj     dupObj description
     */
    @TestVisible
    private static void performMerge(SObject primaryObj, SObject dupObj) {
        if (primaryObj != null && dupObj != null) {
            Id pId = primaryObj?.Id;
            Id dId = dupObj?.Id;
            if (pId != dId && pId != null && dId != null) {
                String unlockErr = '';
                Boolean hasMergeFailed = false;
                for (Database.MergeResult mergeRes :Database.merge(primaryObj, new List<SObject> {dupObj}, false)) {
                    if (mergeRes.isSuccess() == false) {
                        hasMergeFailed = true;
                        for (Database.Error dbErr :mergeRes.getErrors()) {
                            LogUtilityException.addLogEvent('ERROR', dupObj, dbErr, 'ContactMergeController.performMerge');
                            unlockErr += dbErr.getStatusCode() + ' ' + dbErr.getMessage() + '\n';
                        }
                    }
                }
                if (hasMergeFailed) {
                    LogUtilityException.publishAll();
                    throw new CustomException(unlockErr);
                }
            }
        }
    }

    /*
     * Method Name: recalculatePrimaryLeads
     * Description: method to recalculate primary leads after contact merging
     */
    @AuraEnabled
    public static String recalculatePrimaryLeads(Id primaryContactId) {
        Map<Id, List<Lead> > contactToLeadMap = RecalculatePrimaryLeadServices.getContactAndLeadMap(primaryContactId);
        if (!contactToLeadMap.isEmpty()) {
            try {
                RecalculatePrimaryLeadServices.reCalculate(contactToLeadMap);
            }
            catch (Exception e) {
                LogUtilityException.logException(e);
                throw e;
            }
        }
        return 'Lead:' + primaryContactId;
    }

    /**
     * evaluateCulateContactPoints Evaluate Contact Points for Surviving Contact and Cleanup
     * @param  primaryContactId primaryContactId Record Id
     */
    @AuraEnabled
    public static String evaluateCulateContactPoints(Id primaryContactId) {
        try {
            Feature_Switch__c fs = Feature_Switch__c.getInstance();
            if(!fs.Enable_CPA_for_Contact_Merge__c) {

                //Container To Recalculate Leads
                if (primaryContactId != null) {
                    // bypass contact point rollup triggers - DISABLEMENT
                    ContactServices.RePopulateHashFoAllContactPointsWrapper wrapRes = ContactServices.rePopulateHashFoAllContactPoints(
                        new Set<Id> {primaryContactId},
                        true
                        );
                    if (wrapRes != null && wrapRes.vsrList != null && wrapRes.vrecordsToUpdate != null) {
                        List<SObject> sobjectsDel = new List<SObject>();
                        Integer icnt = 0;
                        for (Database.SaveResult dsr :wrapRes.vsrList) {
                            //Check if failed due to DUPLICATE_VALUE and perform clean-up
                            if (dsr.success == false &&
                                dsr.getErrors().get(0).statusCode == System.StatusCode.DUPLICATE_VALUE) {
                                SObject sob = wrapRes.vrecordsToUpdate.get(icnt);
                                sobjectsDel.add(sob);
                            }
                            icnt++;
                        }
                        //Perform delete of duplicate Contact Point Records
                        if (sobjectsDel.isEmpty() == false) {
                            // bypass contact point rollup triggers - DISABLEMENT
                            triggerCommon.disableTrigger('Contact');
                            triggerCommon.disableTrigger('Name__c');
                            triggerCommon.disableTrigger('Email__c');
                            triggerCommon.disableTrigger('Phone__c');
                            triggerCommon.disableTrigger('Address__c');
                            triggerCommon.disableTrigger('Social__c');
                            Database.DeleteResult[] drList = Database.delete(sobjectsDel, false);
                            // bypass contact rollup triggers - RE-ENABLEMENT
                            triggerCommon.enableTrigger('Contact');
                            triggerCommon.enableTrigger('Name__c');
                            triggerCommon.enableTrigger('Email__c');
                            triggerCommon.enableTrigger('Phone__c');
                            triggerCommon.enableTrigger('Address__c');
                            triggerCommon.enableTrigger('Social__c');
                        }
                    }
                }
            } else {
                // bypass contact point rollup triggers
                TriggerCommon.disableTrigger('Contact');
                TriggerCommon.disableTrigger('Name__c');
                TriggerCommon.disableTrigger('Email__c');
                TriggerCommon.disableTrigger('Phone__c');
                TriggerCommon.disableTrigger('Address__c');
                TriggerCommon.disableTrigger('Social__c');
                
                /**
                 * - merge Person360 objects
                 * - recalculate new hash keys, and reparent CPAs
                 * - calculate new primaries
                 * - explicitly roll up new primaries to Contact
                 * - temporarily runs a partial commit due to known locking issues. Once that
                 *   is permanently resolved, this needs to change to allOrNone = true
                 */
                BaseClass.ResultSet rs = new ContactMergePerson360(primaryContactId).mergePerson360();
                LogUtilityException.logCommitRecords(rs);

                TriggerCommon.enableTrigger('Contact');
                TriggerCommon.enableTrigger('Name__c');
                TriggerCommon.enableTrigger('Email__c');
                TriggerCommon.enableTrigger('Phone__c');
                TriggerCommon.enableTrigger('Address__c');
                TriggerCommon.enableTrigger('Social__c');
            }
        } catch (BaseClass.BaseClassException bce) {
            LogUtilityException.logException(bce);
        } catch (Exception e) {
            LogUtilityException.logException(e);
            throw e;
        }
        return 'ContactPoint:' + primaryContactId;
    }

    /**
     * recalCulateContactPoints Recalculate Contact Points for Surviving Contact
     * @param  primaryContactId primaryContactId Record Id
     */
    @AuraEnabled
    public static String recalCulateContactPoints(Id primaryContactId, Boolean byPass) {
        try {
            Feature_Switch__c fs = Feature_Switch__c.getInstance();
            /**
             * this will not be needed anymore if we use the new ContactMergePerson360 class
             * since that class would already recalculate the new primaries post-merging
             */
            if(!fs.Enable_CPA_for_Contact_Merge__c) {
                // recalculate contact points
                ContactServices.invokeReCalculateContactPrimaryContactPoints(new Set<Id> {primaryContactId});      
            }

            if(!byPass) {
                runBulkRecalculations(new Set<Id> {primaryContactId});
            }
        }
        catch (Exception e) {
            LogUtilityException.logException(e);
            throw e;
        }
        return 'ContactPoint:' + primaryContactId;
    }

    /**
     * runRecalculations Recalculate Contact Points for Surviving Contacts in BULK operations
     * @param  primaryContactIds set of contact ids
     */
    public static void runBulkRecalculations(Set<Id> contactIds) {
        // recalculate Service for CourseAttempt
        CourseAttemptChangeEventService.cdcSCARollup service = new CourseAttemptChangeEventService.cdcSCARollup();
        service.run(new List<Id> (contactIds), new Map<String, Integer>());
        // update GivingSummary batch
        Map<String, Object> params = new Map<String, Object>();
        params.put('contactIdToProcessSet', contactIds);
        params.put('batchSize', 200);
        ucinn_ascendv2.ascend_UTIL_RunBatch.ascend_GIFT_UpdateGivingSummaryBatch(params);
        // re-generate ERDA salutation
        regenerateERDASalutations(contactIds);
    }

    /**
     * Method Name: updateUserMergeStatus
     * Description: Method to update the merge status of surviving User record
     * @param  primaryContactUserId - Primary Contact or Primary User Id, used to query the User record
     */
    @AuraEnabled
    public static void updateUserMergeStatus(Id primaryContactUserId) {
        updateUserMergeStatus(new Set<Id> {primaryContactUserId});
    }

    /**
     * Method Name: updateUserMergeStatus
     * Description: Method to update the merge status of surviving User record
     * @param  primaryContactUserIds - List of Primary Contact or Primary User Ids, used to query the User record
     */
    public static void updateUserMergeStatus(Set<Id> primaryContactUserIds) {
        if (!primaryContactUserIds.isEmpty()) {
            String queryString = 'SELECT Id, Duplicate_Merge_Status__c, Last_Merge_Timestamp__c FROM User WHERE Duplicate_Merge_Status__c =:MERGE_STATUS_INPROGRESS';
            String sobjectType = ((new List<Id>(primaryContactUserIds)).get(0))?.getSObjectType()?.getDescribe()?.getName();
            if (sobjectType == USER_OBJECT) {
                queryString += ' AND Id IN:primaryContactUserIds';
            } else if (sobjectType == CONTACT_OBJECT)   {
                queryString += ' AND ContactId IN:primaryContactUserIds';
            } else   {
                return;
            }
            List<sObject> l_result = Database.query(queryString);
            List<User> l_usersToUpdate = (List<User>)l_result;
            if (!l_usersToUpdate.isEmpty()) {
                try {
                    Datetime timeStamp = DateTime.now();
                    for (User userToUpdate : l_usersToUpdate) {
                        userToUpdate.Duplicate_Merge_Status__c = MERGE_STATUS_COMPLETED;
                        userToUpdate.Last_Merge_Timestamp__c = timeStamp;
                    }
                    update l_usersToUpdate;
                }
                catch (Exception e) {
                    LogUtilityException.logException(e);
                    throw e;
                }
            }
        }
    }

    @AuraEnabled
    public static string sendMergeConfirmation(Id primaryUserId, String dupAccountEmails) {
        Map<String, Network> mapCommIds = new Map<String, Network>();
        Set<String> userNames = new Set<String>();
        Set<String> activeCommunityAccess = new Set<String>();
        //Retrieve Portal Access
        if (primaryUserId != null) {
            for (Network nt:[SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name IN ('my.application','ascendportal')]) {
                mapCommIds.put(nt.Name, nt);
            }
            //Alumni_Portal_Permission_Set, Customer_Community_Ask_Monash_Student, Customer_Community_My_Application
            for (PermissionSetAssignment passignment: [SELECT PermissionSetId, PermissionSet.Type, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId =:primaryUserId]) {
                if (passignment.PermissionSet != null &&
                    passignment.PermissionSet.Type != 'Profile') {
                    Network ntObj;
                    String sURL;
                    if (passignment.PermissionSet.Name == 'Alumni_Portal_Permission_Set') {
                        ntObj = mapCommIds.get('ascendportal');
                    } else if (passignment.PermissionSet.Name == 'Customer_Community_My_Application') {
                        ntObj = mapCommIds.get('my.application');
                    }
                    if (ntObj != null) {
                        sURL = Network.getLoginUrl(ntObj.Id);
                        if (sURL.contains('/s/login')) {
                            sURL = sURL.replace('/s/login', '');
                        }
                        sURL = sURL.replace('/login', '');
                        activeCommunityAccess.add(sURL);
                    }
                }
            }
        }
        if (dupAccountEmails != null) {
            //Store Non Monash emails
            List<MergeUserWrapper> mwrapList = (List<MergeUserWrapper>)JSON.deserialize(dupAccountEmails, List<MergeUserWrapper>.class);
            for (MergeUserWrapper wrap:mwrapList) {
                //SKip if Monash Email
                if (EmailServices.isMonashEmail(wrap.email) == false) {
                    userNames.add(wrap.userName);
                }
            }
            if (userNames.isEmpty() == false) {
                Boolean bypassOWE = Environment_Settings__c.getInstance().Merge_Bypass_Org_Wide_Email__c;
                Messaging.SendEmailResult[] emailResults;
                EmailTemplate et = [SELECT Id, IsActive FROM EmailTemplate WHERE DeveloperName = 'Contact_Merge_Notification' LIMIT 1];
                User primUser = [SELECT Id, Username, Email, ContactId FROM User WHERE Id =:primaryUserId LIMIT 1];
                if (et != null && primUser != null && userNames.isEmpty() == false && et.IsActive) {
                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, primUser.Id, primUser.ContactId);
                    String subject = email.getSubject();
                    String body = dataReplace(email.gethtmlBody(), primUser.Username, userNames, activeCommunityAccess);
                    //If True bypasses using Org Wide email on ReplyTo
                    if (bypassOWE == false) {
                        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@f.e.monash.edu' LIMIT 1];
                        if (owea != null && !owea.isEmpty()) {
                            email.setOrgWideEmailAddressId(owea.get(0).Id);
                        }
                    } else {
                        email.setReplyTo('noreply@f.e.monash.edu');
                        email.setSenderDisplayName('No-Reply Monash');
                    }
                    email.setToAddresses(new List<String> {primUser.Email});
                    email.setTargetObjectId(primaryUserId);
                    email.setSubject(subject);
                    email.sethtmlBody(body);
                    email.setSaveAsActivity(false);
                    emailResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {email}, false);
                    LogUtilityException.logEmailErrors(emailResults);
                }
            }
        }
        return 'Success';
    }

    @TestVisible
    private static String dataReplace(String body, String primUname, Set<String> dupAccountEmails, Set<String> portalAccounts) {
        String content = body;
        if (String.isNotBlank(content) && content.contains('[[Content Starts Here]]')) {
            String sreplace = '<ul>';
            String srPortal = '<ul>';
            //For UserNames
            for (String sval :dupAccountEmails) {
                sreplace += '<li>' + sval + '</li>';
            }
            sreplace += '</ul>';
            //For Portals List
            for (String spA :portalAccounts) {
                srPortal += '<li>' + spA + '</li>';
            }
            srPortal += '</ul>';
            content = content.replace('[[Content Starts Here]]',sreplace);
            content = content.replace('[[Portal Starts Here]]', srPortal);
            if (String.isNotBlank(primUname)) {
                content = content.replace('[[Surviving Username]]',primUname);
            }
        }
        return content;
    }

    /**
     * regeneration of ERDA Salutations of a surviving contact records
     * @param  Set<Id> primaryContactIds set of surviving contact record Ids
     */
    private static void regenerateERDASalutations(Set<Id> primaryContactIds) {
        // perform deletion of existing ERDA Salutations
        // get all ERDA salutation records where Author = Standard
        List<Ucinn_ascendv2__Salutation__c> contactERDASalutations = [SELECT Id
                                                                      FROM Ucinn_ascendv2__Salutation__c
                                                                      WHERE Ucinn_ascendv2__Salutation_Author__c = 'Standard' and Ucinn_ascendv2__Contact__c IN: primaryContactIds];
        // delete records
        if (!contactERDASalutations.isEmpty()) {
            ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', false);
            delete contactERDASalutations;
            ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);
        }
        // perform re-creation of ERDA Salutations
        EngageSalutationHelper engageSalutationHelper = new EngageSalutationHelper();
        engageSalutationHelper.createOrUpdateSalutationRecords(primaryContactIds);
    }
    
    /**
     * @author      Sachin Shetty
     * @description Get contact records for supplied contact Ids
     * @param       List<Id> contactIds
     * @return      List<Contact>
     * @revision    2024-02-04 - Sachin Shetty - Created
     */
    @AuraEnabled
    public static List<Contact> getContactData(List<Id> contactIds){
        try {
            List<Contact> contactsList = new List<Contact>();
            contactsList = [SELECT Id, Exclude_From_Merge__c FROM Contact WHERE Id IN :contactIds];
            return contactsList;
        } catch (Exception e) {
            LogUtilityException.logException(e);
            return null;
        }
    }

    public class MergeUserWrapper {
        @AuraEnabled
        public Id userId;
        @AuraEnabled
        public String userName;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String federationId;
    }

    public class CustomException extends Exception {}
}