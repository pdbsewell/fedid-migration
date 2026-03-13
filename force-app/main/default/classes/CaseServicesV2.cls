/**
 * @author Carl Vescovi, PwC
 * @description Services class to provide Case sObject centric logical support
 * @group Enquiry Management
 * @revision    APRivera, 24.May.2019 - Created new Service Class.
 *              APRivera, 10.June.2018 - Refactored
 *              KEvasco (GrowthOps), 03.Sep.2019 - Added predictionPropensityToTransfer
 *              APRivera, 02.March.2020 - Excluded MonCon Support recordtype on Transfer Enquiry Rule
 *              APRivera, 02.March.2020 - Set Defaults on MonCon Support Cases
                Cartick Sub       - 25/02/2020 - Enquiry Age History processes made asynchronous
				Inderpal Dhanoa   - 19/05/2021 - sync the Opportunity Accounts with Enquiry Organisation Accounts
				Inderpal Dhanoa   - 22/07/2021 - sync the Approver/Rejecter with Enquiry (ENGAGEIE-995)
                Kristian Vegerano - 30/11/2021 - SFTG-2351 add rule condition such that if the selected is do not exclude then the rule is not grouped to any role
                Rajesh Punjabi    - 08/09/2023 - RO-288 Update Account Id for Enquiries if Contact RT=Student
                Martin Cadman     - 13/11/2023 - Removed Enquiry Age History references
                Mac Domingo       - 30/11/2023   - Added OrderBy clause to get contact record with the authcate value in case of duplicates
                Mac Domingo       - 05/12/2023   - Added checking when adding members in the map to avoid overwriting it.
                Arnie Ug          - 01/05/2023 - Changed SOSL to sort using Authcate instead of recordtype.name, change contact filtering method to prioritize email field on top of authcate
*/

public class CaseServicesV2 {

    public static Boolean isProcessed = false;
    public static final String INSERT_DML_TYPE = 'INSERT';
    public static final String UPDATE_DML_TYPE = 'UPDATE';
    public static final String OWNER_FIELD_API_NAME = 'OwnerId';
    public static final String STATUS_FIELD_API_NAME = 'Status';

    public static Id KNOWNTOMONASH_CONTACT_RT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();   //RO-288
    public static Id MONASHORGANISATION_ACCOUNT_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();   //RO-288

    //.. Rajesh Punjabi - 08/09/2023 - RO-288 Update Account Id for Enquiries if Contact RT=Student
    public static void updateAccountforKnownToMonashContact(List<Case> oMROCaseList, Set<Id> setContactIds){
        
        Map<Id, Contact> mapContact = new Map<Id, Contact>([SELECT Id, RecordTypeId, Name FROM Contact WHERE Id IN: setContactIds]);
        Id oMonashAccountId = [SELECT Id FROM Account WHERE RecordTypeId =:MONASHORGANISATION_ACCOUNT_RT AND Name = 'Monash University' LIMIT 1].Id;
        for(Case oCase: oMROCaseList){
            if(oCase.ContactId != null && mapContact.get(oCase.ContactId).RecordTypeId == KNOWNTOMONASH_CONTACT_RT){
                oCase.AccountId = oMonashAccountId;
            }
            else if(oCase.ContactId == null){
                oCase.AccountId = null;
            }
        } 
    }

    // updates course field on Case record
    public static void mapCourseCode(List<Case> lstCaseToInsert, Set<String> setCourses) {
        for(Case caseRecord : lstCaseToInsert){
            // look for a match on specialisation alone first - would be a course code that covers off specialisation
            String strSpec = (caseRecord.Course_Specialisation__c > '') ? caseRecord.Course_Specialisation__c.toLowerCase() : '';
            String strCourse = (caseRecord.Course_Code__c > '') ? caseRecord.Course_Code__c.toLowerCase() : '';
            Map<String, Course__c> mapCourseInfo = retrieveCourseInfo(setCourses);

            if(strSpec > '' && mapCourseInfo.containsKey(strCourse + strSpec)) {
                caseRecord.Course__c = mapCourseInfo.get(strCourse + strSpec).Id;
            } // eg F2002F20021
            else {
                // look for course code only, with no specialisation
                if(mapCourseInfo.containsKey(strCourse)) caseRecord.Course__c = mapCourseInfo.get(strCourse).Id; // eg F2002
            }
        }
    }

    // retrieves map of course info
    public static Map<String, Course__c> retrieveCourseInfo(Set<String> setCourses){
        Map<String, Course__c> mapCourseInfo = new Map<String, Course__c>();
        for(Course__c course : [SELECT Id, Name, Course_Code__c FROM Course__c
        WHERE (Name IN :setCourses OR Course_Code__c IN:setCourses) AND Depreciated__c = FALSE
        LIMIT 4000]) {
            String strCourseCode = course.Name.toLowerCase();
            String strSpecialisation = (course.Course_Code__c > '' ) ? course.Course_Code__c.toLowerCase() : '';
            if(strSpecialisation > '') mapCourseInfo.put(strSpecialisation, course);
            if(strSpecialisation == '') mapCourseInfo.put(strCourseCode, course);
        }
        return mapCourseInfo;
    }

    // updates queue owner field on case record
    public static void maintainLastQueueOwner(List<Case> listCase){
        Map<Id, String> mapQueue = CommonServices.mapQueue('Case');
        for(Case caseRecord : listCase){
            if(caseRecord.OwnerId.getSobjectType() == Group.SObjectType){
                caseRecord.Latest_Unassigned_Queue_OwnerId__c = caseRecord.OwnerId;
                if(caseRecord.Case_Queue_Name__c == null){
                    caseRecord.Case_Queue_Name__c = mapQueue.get(caseRecord.OwnerId);
                }
            }
            if(caseRecord.First_Response_Date_Time__c != null){
                caseRecord.Enquiry_Response_Time_Business_Hours__c = BusinessHours.diff(caseRecord.BusinessHoursId, caseRecord.CreatedDate, caseRecord.First_Response_Date_Time__c)/1000;
            }
        }
    }
	
    // updates queue owner field on case record
    public static void syncApproverRejecter(List<Case> listCase){
        for(Case caseRecord : listCase){
            caseRecord.Approver__c = UserInfo.getUserId();
            caseRecord.Date_Of_Approval__c = Date.today();
        }
    }

    // purpose is to intercept new web cases and see if there is an email address we can link case to.
    public static void checkForAndLinkToContacts(List<Case> listCase){
        Set<String> setEmailAddresses = new Set<String>();
        Map<String, Case> mapCasesBySuppliedEmail = new Map<String, Case>();
        Set<String> setFacultyEmailAddresses = CaseUtilities.setFacultyEmailAddresses;
        List<Case> lstCaseWithMatchedContact = new List<Case>();
        for(Case caseRecord : listCase){
            if(!setFacultyEmailAddresses.contains(caseRecord.SuppliedEmail)){
                setEmailAddresses.add(caseRecord.SuppliedEmail); // to define scope of contact query
                mapCasesBySuppliedEmail.put(caseRecord.SuppliedEmail, caseRecord); // store with email as key for quick reference later
            }
        }
        if(!setEmailAddresses.isEmpty()){
            linkContactToInboundCase(setEmailAddresses, mapCasesBySuppliedEmail, lstCaseWithMatchedContact);
            // if matched cases, then process mapping of case fields to contact records.
            if(!lstCaseWithMatchedContact.isEmpty()) {
                TriggerCommon.disableTrigger('Contact');
                ContactServices.copyMappedFieldsToCaseContacts(lstCaseWithMatchedContact);
                TriggerCommon.enableTrigger('Contact');
            }
        }
    }

    //Links inbound cases to existing Contacts where possible
    public static void linkContactToInboundCase(Set<String> setEmailAddresses, Map<String, Case> mapCasesBySuppliedEmail,
            List<Case> lstCaseWithMatchedContact){
        Map<String, Contact> mapExistingContactsByEmailAddress = getMapExistingContactsByEmailAddress(setEmailAddresses);
        List<Case> lstCaseWithoutMatchContact = new List<Case>();
        for(Case caseRecord : mapCasesBySuppliedEmail.values()){
            if(caseRecord.Enquiry_Type__c != CaseUtilities.CASE_TYPE_KEY_AGENT_INTERNATIONAL && caseRecord.Origin != CaseUtilities.ORIGIN_KEY_AGENT){
                splitContactName(caseRecord);
                if(mapExistingContactsByEmailAddress.containsKey(caseRecord.SuppliedEmail)){
                    // contact exists, so link the case to the existing contact record
                    caseRecord.ContactId = mapExistingContactsByEmailAddress.get(caseRecord.SuppliedEmail).Id;
                    lstCaseWithMatchedContact.add(caseRecord);
                }else{
                    lstCaseWithoutMatchContact.add(caseRecord);
                }
            }
        }
        if(!lstCaseWithoutMatchContact.isEmpty()){
            runSOSLToLinkContactToCase(lstCaseWithoutMatchContact, lstCaseWithMatchedContact);
        }
    }

    /**
    @description Links Cases to Contacts (if not already linked) based on email fields
    @param List of Cases without linked Contacts
    @param List of Cases with linked Contacts (Cases from former list are added here if matching Contacts are found)
    @revision Cartick Sub - 20 May 2020 - Refactor to avoid SOSL in loops
    **/
    public static void runSOSLToLinkContactToCase(List<Case> listCaseWithoutMatchContact, List<Case> listCaseWithMatchedContact) {

        // Find all Case email addresses and put into search string
        String searchTerms = '';
        for(Integer index = 0; index < listCaseWithoutMatchContact.size(); index++) {
            Case caseRecord = listCaseWithoutMatchContact[index];
            String suppliedEmail = String.valueOf(caseRecord.SuppliedEmail);
            if (String.isNotBlank(suppliedEmail)) {
                searchTerms += '"' + suppliedEmail + '"';
            }
            if (index != listCaseWithoutMatchContact.size() - 1) {
                searchTerms += ' OR ';
            }
        }

        // Use SOSL to get Contacts containing Case email addresses
        // Use authcate as an ordering field
        List<List<SObject>> listSearchResults = [
            FIND :searchTerms IN ALL FIELDS RETURNING
            Contact(Id,
            Applicant_Email_Address__c,
            Business_Email_Address__c,
            Email,
            Monash_Email_Address__c,
            Personal_Email__c,
            Authcate__c
            ORDER BY Authcate__c NULLS Last)
        ];

        // Build map of email addresses to Contact Ids
        Map<String,Id> mapContactEmails = new Map<String,Id>();

        for(List<SObject> listItems : listSearchResults) {
            for(SObject listItem : listItems) {
                Contact contactRecord = (Contact)listItem;
                String emailKey = (contactRecord.Applicant_Email_Address__c == null ? '' : contactRecord.Applicant_Email_Address__c) + ':' +
                                (contactRecord.Business_Email_Address__c == null ? '' : contactRecord.Business_Email_Address__c) + ':' +
                                (contactRecord.Email == null ? '' : contactRecord.Email) + ':' +
                                (contactRecord.Monash_Email_Address__c == null ? '' : contactRecord.Monash_Email_Address__c) + ':' +
                                (contactRecord.Personal_Email__c == null ? '' : contactRecord.Personal_Email__c);
                mapContactEmails.put(emailKey, contactRecord.Id);
            }
        }

        // Iterate through Cases again
        for(Case caseRecord : listCaseWithoutMatchContact) {
            try {
                String suppliedEmail = String.valueOf(caseRecord.SuppliedEmail);
                if (String.isNotBlank(suppliedEmail)) {
                    // Check if Case email can be found within any of the Contact email fields
                    for (String emailKey : mapContactEmails.keySet()) {
                        if (emailKey.contains(suppliedEmail)) {
                            caseRecord.ContactId = mapContactEmails.get(emailKey);
                            listCaseWithMatchedContact.add(caseRecord);
                            break; // Do not keep checking keys after we have found a matching one
                        }
                    }
                }
            } catch (Exception e) {
                ExLog.write('CaseTriggerHandler - on Insert', 'Case', 'CaseServices.checkForAndLinkToContacts', e.getMessage());
            }
        }
    }

    // Splits Contact Full Name to First and Last Name
    public static void splitContactName(Case caseRecord){
        // split the supplied name field out
        if(caseRecord.SuppliedName != null && caseRecord.SuppliedName.indexOf(' ') != -1){
            //check first if the supplied first/last name is blank before pre-populating
            if (caseRecord.Supplied_First_Name__c == '') {
                caseRecord.Supplied_First_Name__c = caseRecord.SuppliedName.split(' ')[0];
            }
            if (caseRecord.Supplied_Last_Name__c == '') {
                caseRecord.Supplied_Last_Name__c = caseRecord.SuppliedName.split(' ')[1];
            }
        }
    }

    /**
    * Retrieves existing contacts and creates map of contact by email address from Case
    * Map contacts with these addresses; considers system, monash and personal email address fields
    */
    public static Map<String, Contact> getMapExistingContactsByEmailAddress(Set<String> setEmailAddresses){
        Map<String, Contact> mapExistingContactsByEmailAddress = new Map<String, Contact>();
        Map<String, Contact> mapAuthcateContact = new Map<String, Contact>();
        if(!setEmailAddresses.isEmpty()){
            List<Contact> existingContactList = [SELECT Id, AccountId, Authcate__c, Email, Monash_Email_Address__c, Applicant_Email_Address__c
                                            FROM Contact WHERE (Monash_Email_Address__c IN:setEmailAddresses
                                            OR Applicant_Email_Address__c IN:setEmailAddresses
                                            OR Email IN:setEmailAddresses) ORDER BY Authcate__c NULLS Last LIMIT 10000];

            //Loop through field by field for multiple contacts, prioritizing email.
            List<String> emailFieldList = new List<String>{'Email', 'Monash_Email_Address__c','Applicant_Email_Address__c'};
            for(String emailField : emailFieldList){
                for(Contact existingContact : existingContactList){
                    String emailAdd = '';
                    if(String.isNotBlank((String)existingContact.get(emailField))) {
                        emailAdd = (String)existingContact.get(emailField);
                        //Add the first contact with the authcate to the map
                        if(!mapExistingContactsByEmailAddress.containsKey(emailAdd)){
                            mapExistingContactsByEmailAddress.put(emailAdd, existingContact);
                        }   
                    }     
                }   
            }
        }
        return mapExistingContactsByEmailAddress;
    }

    // Set recordtypeId using Case Type on case records before insert
    public static void setRecordTypeIdUsingCaseType(List<Case> listCase){
        Map<String, Id> mapRecordTypeIdByName = CaseUtilities.mapRecordTypeIdByName;
        for(Case caseRecord : listCase){
            if(caseRecord.Case_Type__c > '' && mapRecordTypeIdByName.containsKey(caseRecord.Case_Type__c)){
                caseRecord.RecordTypeId = mapRecordTypeIdByName.get(caseRecord.Case_Type__c);
            }
        }
    }

    //set default values on a new case if a user has valid defaults in place (service console user)
    public static void setDefaultsOnNewCases(List<Case> listCase, User usr) {
        Map<String, Id> mapRecordTypeIdByName = CaseUtilities.mapRecordTypeIdByName;
        if(usr != null){
            for(Case caseRecord : listCase){
                // map queue to case enq type field
                if(usr.Queue__c != null && usr.Queue__c == UserServices.CURRENT_STUDENT) caseRecord.Enquiry_Type__c = UserServices.CURRENT_STUDENT_VALUE;
                if(usr.Queue__c != null && usr.Queue__c == UserServices.FUTURE_STUDENT) caseRecord.Enquiry_Type__c = UserServices.FUTURE_STUDENT_VALUE;

                // set location managed onto enquiry
                caseRecord.Location_Code__c = usr.Location__c;

                // set case origin based on default
                if(usr.Enquiry_Role__c != null && usr.Enquiry_Role__c.indexOf('Back')!= -1) caseRecord.Origin = CaseUtilities.ORIGIN_BACK_OFFICE_GENERAL;
                if(usr.Enquiry_Role__c != null && usr.Enquiry_Role__c.indexOf('Face') != -1) caseRecord.Origin = CaseUtilities.ORIGIN_FACE_TO_FACE;
                if(usr.Enquiry_Role__c != null && usr.Enquiry_Role__c.indexOf('Phone')!= -1) caseRecord.Origin = CaseUtilities.ORIGIN_PHONE;

                //Setup user's default enquiry record type
                if(usr.Default_Enquiry_Record_Type__c != null) caseRecord.RecordTypeId = mapRecordTypeIdByName.get(usr.Default_Enquiry_Record_Type__c);

                if(caseRecord.RecordTypeId == MonConCaseServices.MONCONSUPPORT_RECTYPEID && caseRecord.Origin == MonConCaseServices.ORIGIN_WEB_PLAN_SUPPORT){
                    caseRecord.Enquiry_Type__c = UserServices.CURRENT_STUDENT_VALUE;
                    caseRecord.Student_Type__c = MonConCaseServices.STUDENT_TYPE_INTL;
                    caseRecord.Category_Level_1__c = MonConCaseServices.CAT_LEVEL_1;
                    caseRecord.Category_Level_2__c = MonConCaseServices.CAT_LEVEL_2;
                }
            }
        }
    }
	
	//syncs the Orgs in the Enquiry and the Enquiry Organisations (Junction Object)
    public static void updateEnquiryOrganisation(List<Case> listCase){
        List<Enquiry_Organisations__c> l_newEnquiryOrgs = new List<Enquiry_Organisations__c>();
        Set<Id> relatedOppId = new Set<Id>();
        Set<Id> relatedEnquiryId = new Set<Id>();
        for(Case caseRecord : listCase){
            relatedOppId.add(caseRecord.Opportunity__c);
            relatedEnquiryId.add(caseRecord.Id);
        }
        List<Enquiry_Organisations__c> l_relatedEnquiryOrgs = [SELECT Id, Enquiry__c, Account__c FROM Enquiry_Organisations__c WHERE Enquiry__c in :relatedEnquiryId];
        Map<Id,Opportunity> relatedAccounts = new Map<Id,Opportunity>((List<Opportunity>)[SELECT Id, Opportunity.Account.Record_Type_Dup__c, AccountId FROM Opportunity WHERE Id in :relatedOppId]);
        for(Case caseRecord : listCase){
            if(!String.isBlank((String)caseRecord.Opportunity__c)){
                Boolean b_OrgExists = false;
                Opportunity relOpp = relatedAccounts.get(caseRecord.Opportunity__c);
                if(!l_relatedEnquiryOrgs.isEmpty()){
                    for(Enquiry_Organisations__c relEnqOrgn : l_relatedEnquiryOrgs){
                        if(relEnqOrgn.Account__c == relOpp.AccountId && relEnqOrgn.Enquiry__c == caseRecord.Id){
                            b_OrgExists = true;
                            break;
                        }
                    }
                }
                if(!b_OrgExists && !String.isBlank((String)relOpp.AccountId) && relOpp.Account.Record_Type_Dup__c == 'External_Organisation'){
                    Enquiry_Organisations__c newEnquiryOrg = new Enquiry_Organisations__c(Account__c = relOpp.AccountId, Enquiry__c = caseRecord.Id);
                    l_newEnquiryOrgs.add(newEnquiryOrg);
                }
            }
        }
        try{
            if(!l_newEnquiryOrgs.isEmpty()){
                insert l_newEnquiryOrgs;
            }
        } catch (Exception e) {
            ExLog.write('CaseTriggerHandler - on Update', 'Case', 'CaseServices.updateEnquiryOrganisation', e.getMessage());
        }
    }

    // if case contact changes, then clear the case account field to overcome known issue in console presently
    public static void clearAccountFieldOnContactChange(List<Case> listCase){
        for(Case caseRecord : listCase){
            caseRecord.AccountId = null;
            MonConCaseServices.clearCourseRelatedFieldsOnCase(caseRecord);
        }
    }

    // Process Transfer Enquiry Rule custom metadata records when enquiries is transferred to a proper queue
    public static void transferEnquiryOwnership(List<Case> listCase, Map<Id, Case> oldMap){
        List<Case> lstCaseToProcess = new List<Case>();
        Set<Id> userOwnerIds = new Set<Id>();

        checkCaseIfCreatedNow(lstCaseToProcess, listCase, oldMap, userOwnerIds);
        if(!lstCaseToProcess.isEmpty()){
            Map<Id, User> ownerMap = CaseUtilities.retrieveCaseOwner(userOwnerIds);

            Map<Id, Group> queueMap = new Map<Id, Group>();
            Map<String, Group> queueNameMap = new Map<String, Group>();
            CaseUtilities.retrieveQueueMap(queueMap, queueNameMap);

            Map<String, Set<String>> roleHierarchyChildrenMap = CaseUtilities.retrieveRoleHierarchyChildren();

            //Retrieve business groups per role in the hierarchy
            Map<String, String> roleBusinessGroupMap = new Map<String, String>();
            for(String loopBusinessGroup : roleHierarchyChildrenMap.keySet()){
                for(String loopRole : roleHierarchyChildrenMap.get(loopBusinessGroup)){
                    roleBusinessGroupMap.put(loopRole, loopBusinessGroup);
                }
            }

            //Retrieve Business group - Queue assignment - key as the name of the queue where the enquiry is being transferred to
            Map<String, Set<String>> queueToBusinessGroupMap = new Map<String, Set<String>>();
            Map<String, Transfer_Enquiry_Rule__mdt> transferRuleMap = new Map<String, Transfer_Enquiry_Rule__mdt>();
            for(Transfer_Enquiry_Rule__mdt transferRule : [SELECT Id, DeveloperName, MasterLabel, ExcludedForRoleAndSubordinates__c,
                    Change_to_Record_Type__c, Priority__c, Queue_Name__c,
                    Status__c, Allow_Direct_User_Assignment__c
            FROM Transfer_Enquiry_Rule__mdt]){
                transferRuleMap.put(transferRule.Queue_Name__c, transferRule);

                //Assign queues to associated business group
                if(!queueToBusinessGroupMap.containsKey(transferRule.ExcludedForRoleAndSubordinates__c)){
                    queueToBusinessGroupMap.put(transferRule.ExcludedForRoleAndSubordinates__c, new Set<String>());
                }
                queueToBusinessGroupMap.get(transferRule.ExcludedForRoleAndSubordinates__c).add(transferRule.Queue_Name__c);
            }

            // process transfer enquiry ownership logic
            processTransferEnquiryOwnership(lstCaseToProcess,transferRuleMap,roleHierarchyChildrenMap,
                    ownerMap,queueNameMap,queueMap,oldMap,queueToBusinessGroupMap);

        }
    }

    // process transfer enquiry ownership logic
    public static void processTransferEnquiryOwnership(List<Case> lstCaseToProcess, Map<String, Transfer_Enquiry_Rule__mdt> transferRuleMap,
            Map<String, Set<String>> roleHierarchyChildrenMap,  Map<Id, User> ownerMap,
            Map<String, Group> queueNameMap, Map<Id, Group> queueMap, Map<Id, Case> oldMap,
            Map<String, Set<String>> queueToBusinessGroupMap){
        for(Case caseRecord : lstCaseToProcess){
            if( oldMap.get(caseRecord.Id).RecordTypeId != MonConCaseServices.MONCONSUPPORT_RECTYPEID) {
                //Determine if the new owner of the case is a queue or a user and get the relevant queue
                Id useTransferredQueue;
                if (Schema.User.SObjectType == caseRecord.OwnerId.getSobjectType()) {
                    //Iterate through each transfer rules that allows direct user assignment
                    for (Transfer_Enquiry_Rule__mdt loopTransferRule : transferRuleMap.values()) {
                        if (loopTransferRule.Allow_Direct_User_Assignment__c) {
                            //Check if the new owner's role is included on the roleHierarchyChildrenMap if so then allow the transfer
                            if (roleHierarchyChildrenMap.get(loopTransferRule.ExcludedForRoleAndSubordinates__c).contains(ownerMap.get(caseRecord.OwnerId).UserRole.Name)) {
                                //Use the queue on the applied transfer rule for processing
                                useTransferredQueue = queueNameMap.get(loopTransferRule.Queue_Name__c).Id;
                            }
                        }
                    }
                } else {
                    useTransferredQueue = caseRecord.OwnerId;
                }
                System.debug(LoggingLevel.DEBUG, '!@# useTransferredQueue: ' + useTransferredQueue);
                //Check if the new owner of the case is a queue and queuemap contains the id
                if (queueMap.containsKey(useTransferredQueue)) {
                    //Check if the new queue has a transfer rule associated with it
                    if (transferRuleMap.containsKey(queueMap.get(useTransferredQueue).Name)) {
                        Transfer_Enquiry_Rule__mdt appliedRule = transferRuleMap.get(queueMap.get(useTransferredQueue).Name);
                        //Check if the previous owner is a user or a queue
                        //Run logic if the previous queue is outside the business group of the applied rule OR
                        //Run logic if the previous user is outside the business group of the applied rule
                        if (//SFTG-2351 add rule condition such that if the selected is do not exclude then the rule is not grouped to any role
                            appliedRule.ExcludedForRoleAndSubordinates__c == CaseUtilities.DO_NOT_EXCLUDE||
                            (Schema.Group.SObjectType == oldMap.get(caseRecord.Id).OwnerId.getSobjectType() && !queueToBusinessGroupMap.get(appliedRule.ExcludedForRoleAndSubordinates__c).contains(queueMap.get(oldMap.get(caseRecord.Id).OwnerId).Name)) ||
                            (Schema.User.SObjectType == oldMap.get(caseRecord.Id).OwnerId.getSobjectType() && roleHierarchyChildrenMap.containsKey(appliedRule.ExcludedForRoleAndSubordinates__c) && !roleHierarchyChildrenMap.get(appliedRule.ExcludedForRoleAndSubordinates__c).contains(ownerMap.get(oldMap.get(caseRecord.Id).OwnerId).UserRole.Name))) {
                            //Apply recordtype based on the transfer rule
                            if (appliedRule.Change_to_Record_Type__c != null) {
                                if (!appliedRule.Change_to_Record_Type__c.equalsIgnoreCase(CaseUtilities.DO_NOT_CHANGE)) {
                                    caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(appliedRule.Change_to_Record_Type__c).getRecordTypeId();
                                }
                            }

                            //Apply status based on the transfer rule
                            if (appliedRule.Status__c != null) {
                                if (!appliedRule.Status__c.equalsIgnoreCase(CaseUtilities.DO_NOT_CHANGE)) {
                                    caseRecord.Status = appliedRule.Status__c;
                                }
                            }

                            //Apply priority based on the transfer rule
                            if (appliedRule.Priority__c != null) {
                                if (!appliedRule.Priority__c.equalsIgnoreCase(CaseUtilities.DO_NOT_CHANGE)) {
                                    caseRecord.Priority = appliedRule.Priority__c;
                                }
                            }

                            //Store the date/time of when the enquiry has been transffered
                            caseRecord.Latest_Transferred_Date__c = System.now();
                        }
                    }
                }
            }
        }
        transferRuleMap = null;
        roleHierarchyChildrenMap = null;
    }


    // checks if case is created now, Returns list of case to process and set of owner ids
    // Revision: 12/02/2020 - APRivera -Added additional validation of records to be processed on the logic
    public static void checkCaseIfCreatedNow(List<Case> lstCaseToProcess, List<Case> listCase, Map<Id, Case> oldMap, Set<Id> userOwnerIds){
        Map<Id, Case> enquiryEmailMessageMap = new Map<Id, Case>(); //Enquiry - EmailMessage map
        for(Case caseRecord : [SELECT Id, CreatedDate, CreatedBy.Email,
        (SELECT Id, ToAddress, CreatedDate, ParentId FROM EmailMessages WHERE Incoming = TRUE ORDER BY CreatedDate ASC LIMIT 1)
        FROM Case WHERE Id IN: oldMap.keySet()]){
            enquiryEmailMessageMap.put(caseRecord.Id, caseRecord);
        }
        if(!enquiryEmailMessageMap.isEmpty()){
            for(Case caseRecord : listCase){
                if(enquiryEmailMessageMap.containsKey(caseRecord.Id)){
                    //Check if the enquiry created date is now (this method should only run before update)
                    Boolean isCreatedNow = false;
                    if(System.now().year() == enquiryEmailMessageMap.get(caseRecord.Id).CreatedDate.year() &&
                            System.now().month() == enquiryEmailMessageMap.get(caseRecord.Id).CreatedDate.month() &&
                            System.now().day() == enquiryEmailMessageMap.get(caseRecord.Id).CreatedDate.day() &&
                            System.now().hour() == enquiryEmailMessageMap.get(caseRecord.Id).CreatedDate.hour() &&
                            System.now().minute() == enquiryEmailMessageMap.get(caseRecord.Id).CreatedDate.minute()){
                        isCreatedNow = true;
                    }
                    //Process only valid owner transfer updates
                    if(!isCreatedNow || Test.isRunningTest()){
                        if(Schema.User.SObjectType == caseRecord.OwnerId.getSobjectType()){
                            userOwnerIds.add(caseRecord.OwnerId);
                        }
                        if(Schema.User.SObjectType == oldMap.get(caseRecord.Id).OwnerId.getSobjectType()){
                            userOwnerIds.add(oldMap.get(caseRecord.Id).OwnerId);
                        }
                        lstCaseToProcess.add(caseRecord);
                    }
                }
            }
        }
        listCase.clear();
    }

    // adds course interests
    public static void addCourseInterests(Set<Id> setCaseIds){
        List<Enquiry_Interest__c> lstCourseInterests = new List<Enquiry_Interest__c>();
        Map<Id, Case> mapCasesByIds = new Map<Id, Case>();
        for(Case caseRecord : [SELECT Id, Origin, ContactId, Course__c, Course__r.Managing_Faculty__c,Course__r.Faculty_Code__c,
                Supplied_Area_of_Interest__c, Supplied_Name_of_Institution__c, Commencement_Year__c, Level_of_Study__c
        FROM Case WHERE Id IN: setCaseIds]){
            mapCasesByIds.put(caseRecord.Id, caseRecord);
        }

        for(Case caseRecord : mapCasesByIds.values()){
            if(caseRecord.Course__c != null){
                String managingFaculty = (caseRecord.Course__r.Managing_Faculty__c > '') ? caseRecord.Course__r.Managing_Faculty__c  :'';
                String facultyCode = (caseRecord.Course__r.Faculty_Code__c > '') ? caseRecord.Course__r.Faculty_Code__c : '';
                String suppliedInterest = (caseRecord.Supplied_Area_of_Interest__c > '') ? caseRecord.Supplied_Area_of_Interest__c : '';
                String commencementYear = (caseRecord.Commencement_Year__c > '') ? caseRecord.Commencement_Year__c : '';
                String nameOfInstitution = (caseRecord.Supplied_Name_of_Institution__c > '') ? caseRecord.Supplied_Name_of_Institution__c : '';

                lstCourseInterests.add(
                        new Enquiry_Interest__c(
                                Course__c = caseRecord.Course__c,
                                Case__c = caseRecord.Id,
                                Person__c = caseRecord.ContactId,
                                Study_Area__c = suppliedInterest,
                                Managing_Faculty__c = managingFaculty,
                                Managing_Faculty_Code__c = facultyCode,
                                Level_of_Study__c = caseRecord.Level_of_Study__c,
                                Commencement_Year__c = commencementYear,
                                Name_of_Institution__c = nameOfInstitution));
            }
        }
        if(!lstCourseInterests.isEmpty()) insert lstCourseInterests;
    }

    /*******************************************************************************
    * @author       Anonymous
    * @date         04/06/2018
    * @description  Method that counts the closed status on EAH
    * @revision     04/06/2018 - Initial Version
    *               11/02/2020 - APRivera - refactored
    *******************************************************************************/
    // updates contact based on case records
    public static void copyMappedFieldsToCaseContact(List<Case> lstCases){
        // copy mapped fields from Case to contact record
        List<Case_to_Contact_Field_Mapping__mdt> fieldMappings = CaseUtilities.lstCastToContactMappings;
        List<Contact> lstContacts = new List<Contact>();
        for(Case cse : lstCases){
            if(cse.ContactId != null){
                Contact c = new Contact(Id = cse.ContactId, Copy_from_Enquiry__c = false);
                for(Case_to_Contact_Field_Mapping__mdt fieldMapping : fieldMappings){
                    if(cse.get(fieldMapping.Case_API_name__c) != null) {
                        //Populate the contact field if it is blank
                        if(c.get(fieldMapping.Contact_Field_API_name__c) == null){
                            c.put(fieldMapping.Contact_Field_API_name__c, cse.get(fieldMapping.Case_API_name__c));
                            lstContacts.add(c);
                        }
                    }
                }
            }
        }
        try{
            if(!lstContacts.isEmpty()){
                update lstContacts;
                fieldMappings = null;
                CaseUtilities.lstCastToContactMappings.clear();
            }
        }catch (exception ex){
            ExLog.write('CaseServicesV2','Case','copyMappedFieldsToCaseContact','This case couldnt be mapped to contact:'+ ex.getMessage());
        }
    }

    // Method to do callout to Calabrio to get the agents call id
//    public static void checkforActiveCall(List<Case> listCase){
//        User currentUser = [SELECT UserRoleId, UserRole.Name, Email, FederationIdentifier, Id, Name
//                                FROM User WHERE Id =:UserInfo.getUserId()];
//
//        CalabrioIntegration__c testCal = CalabrioIntegration__c.getValues('Credentials');
//        String strUserRole = currentUser.UserRoleId != null ? currentUser.UserRole.Name: 'eSolutions'; //to avoid null reference error if Current User has no Role
//
//        if(testCal != null && testCal.AllowCallout__c && testCal.AllowedStaff__c.contains(strUserRole)) {
//            for(Case caseRecord : listCase){
//                try{
//                    CalabrioServices.calabrioCallout(currentUser.FederationIdentifier, caseRecord.Id);
//                }catch(Exception e){
//                    ExLog.add('CaseTriggerHandler','Case','checkForActiveCall', e);
//                }
//            }
//        }
//    }


    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         25/03/2019
    * @description  Class that will set Enquiry Origin Category
    * @revision     25/03/2019 - Initial Version
    *               FEB.12.2020  APRivera   - Used Set as placeholder of all Case origin to limit records
    *                                         to be retrieved from Custom Metadata
    *               NOV.12.2020 APRIVERA - Exclude Web - Monash Forms
    *******************************************************************************/
    public static void setEnquiryOrigin(List<Case> listCase, Set<String> setCaseOrigin){
        Map<String, String> mapEnquiryOriginCategoriesByLabel = CaseUtilities.getMapEnquiryOriginCategoriesByLabel(setCaseOrigin);
        for(Case caseRecord : listCase){
            if(caseRecord.Origin != 'Web - Monash Forms'){ // exclude this Origin
                if(mapEnquiryOriginCategoriesByLabel.containsKey(caseRecord.Origin)){
                    caseRecord.Channel_Mapping__c = mapEnquiryOriginCategoriesByLabel.get(caseRecord.Origin);
                }else{
                    caseRecord.Channel_Mapping__c = 'Other';
                }
            }
        }
        mapEnquiryOriginCategoriesByLabel.clear();
        CaseUtilities.mapEnquiryOriginCategoriesByLabelString.clear();
        CaseUtilities.mapEnquiryOriginCategoriesByLabel.clear();
    }



    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         25/03/2019
    * @description  Class that will set Enquiry Origin Category
    * @revision     18/06/19 - APRivera - refactored
    *******************************************************************************/
    public static void updateCaseBusinessWaitingTime(List<Case> listCase){
        Long timeInterval = Long.valueOf(Label.Email_Escalation_Milliseconds);
        for(Case caseRecord : listCase){
            caseRecord.case_waiting_time__c = BusinessHours.add(CaseUtilities.businessHoursId, System.now(),timeInterval);
        }
    }

    /**
	 * @author       Kevin Evasco (GrowthOps)
     * @date         09/03/2019
     * @description  Run prediction model on trigger records and writeback prediction outcome, explanation and recommendation.
     * @revision     10/01/2019 - Only perform writeback if all writeback fields are updateable
     */
//    public static void predictPropensityToTransfer() {
//    	if(System.isFuture()) return;
//        if(ed_insights.CheckRecursive.runOnce()) {
//
//            String CONFIG_NAME = 'Propensity to Transfer';
//
//        	try{
//                ed_insights__SDDPredictionConfig__c wbSettings = ed_insights__SDDPredictionConfig__c.getValues(CONFIG_NAME);
//                Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(wbSettings.ed_insights__object_api_name__c).getDescribe();
//                if(objectDescribe.fields.getMap().get(wbSettings.ed_insights__outcome_field_api_name__c).getDescribe().isUpdateable() &&
//                    objectDescribe.fields.getMap().get(wbSettings.ed_insights__commentary_field_api_name__c).getDescribe().isUpdateable() &&
//                    objectDescribe.fields.getMap().get(wbSettings.ed_insights__prescription_field_api_name__c).getDescribe().isUpdateable()) {
//
//                    // custom Settings' name
//                    ed_insights.TriggerHandler.insertUpdateHandle(CONFIG_NAME);
//                }
//            } catch(Exception e){
//            	ExLog.add('CaseTriggerHandler','Case','predictPropensityToTransfer', e);
//        	}
//        }
//    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			19-03-2021
	 * @description:	Populate category levels 1 and 2 based on enquiry summary for
	 * 					post-application enquiries. This is to replace the process builder
	 * 					SR_Internal_Enquiry_Populate_Cat_Fields.
	 */
    public static void mapCategoryLevelsForPostApplicationCases(List<Case> cases) {
        for(Case c : cases) {
            if(c.Enquiry_Summary__c == 'Application Progress follow-up') {
                
                c.Category_Level_1__c = 'Application';
                c.Category_Level_2__c = 'Application Progress follow up';
                
            } else if(c.Enquiry_Summary__c == 'Other') {
                
                c.Category_Level_1__c = 'Other';
                c.Category_Level_2__c = null;
                
            } else if(c.Enquiry_Summary__c == 'Acceptance process') {
                
                c.Category_Level_1__c = 'Offer';
                c.Category_Level_2__c = 'Accept Offer';
                
            } else if(c.Enquiry_Summary__c == 'Details Regarding Offer') {
                
                c.Category_Level_1__c = 'Offer';
                c.Category_Level_2__c = 'Offer Details';
                
            } else if(c.Enquiry_Summary__c == 'Confirmation of Enrolment (CoE)') {
                
                c.Category_Level_1__c = 'Confirmation of Enrolment (CoE)';
                c.Category_Level_2__c = 'CoE Status';
                
            } else if(c.Enquiry_Summary__c == 'Packaging of English Language Program') {
                
                c.Category_Level_1__c = 'Application';
                c.Category_Level_2__c = 'Package Request';
                
            } else if(c.Enquiry_Summary__c == 'Pending / Required documents') {
                
                c.Category_Level_1__c = 'Application';
                c.Category_Level_2__c = 'Supporting Documents';
                
            }
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Generate Latest_Transferred_Date__c and Enquiry_Reopened__c for student
	 * 					recruitment. This is to replace the process builder
	 * 					Student_Recruitment_Latest_Transferred_Date.
	 */
    public static void generateStudentRecruitmentTrackingDates(List<Case> cases, Map<Id, Case> oldCaseMap) {
        Set<String> priorValues = new Set<String>{
            'Admissions',
            'SRA Admissions VP',
            'SRA Admissions Dir',
            'Assessment International - BusEco',
            'Assessment International - Multi',
            'SRA Admissions Staff (MU)',
            'SRA Admissions Mgr (MU)',
            'SRA Admissions Staff (MC)',
            'SRA Admissions Mgr (MC)',
            'SRA Fees Mgr',
            'SRA Fees Staff'
        };
        
        for(Case c : cases) {
            if(c.Enquiry_Owner_Role__c == 'Student Rec Enquiries (Post-Application)' || c.Enquiry_Owner_Role__c == 'Student Rec Enquiries (Pre-Application)') {
                
                c.Latest_Transferred_Date__c = System.now();
                
            } else if(c.Enquiry_Owner_Role__c == 'MU Docs' && !priorValues.contains(oldCaseMap.get(c.Id).Enquiry_Owner_Role__c)) {
                
                c.Enquiry_Reopened__c = System.now();
                
            } else if(c.Enquiry_Owner_Role__c == 'MC Docs' && !priorValues.contains(oldCaseMap.get(c.Id).Enquiry_Owner_Role__c)) {
                
                c.Enquiry_Reopened__c = System.now();
                
            } else if(c.Enquiry_Owner_Role__c == 'IRS Fees' && !priorValues.contains(oldCaseMap.get(c.Id).Enquiry_Owner_Role__c)) {
                
                c.Enquiry_Reopened__c = System.now();
                
            }
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Populate case wrap-up values based on enquiry origin for
	 * 					post-application enquiries. This is to replace the process builder
	 * 					Student_Recruitment_Post_Application_Enquiry_Type.
	 */
    public static void mapOriginToOtherValuesForPostApplicationCases(List<Case> cases) {
        for(Case c : cases) {
            if(c.Origin == 'scenquiries@monash.edu' || c.Origin == 'Phone') {
                
                c.Category_Level_1__c = 'Application';
                c.Enquiry_Type__c = 'Post Application';
                
            } else if(c.Origin == 'adm-keyagent@monash.edu') {
                
                c.Category_Level_1__c = 'Application';
                c.Enquiry_Type__c = 'Key Agent - International';
                
            } else if(c.Origin == 'latereg@monash.edu') {
                
                c.Category_Level_1__c = 'Application';
                c.Enquiry_Type__c = 'Late Registration - International';
                
            } else if(c.Origin == 'lateregresponse@monash.edu') {
                
                c.Category_Level_1__c = 'Enrolment';
                c.Category_Level_2__c = 'Late Enrolment - MCPL';
                c.Enquiry_Type__c = 'Late Registration - Response';
                
            }
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Map enquiry origin to enquiry type for Monash College cases. This
	 * 					is to replace the process builder Manage_Incoming_Monash_College_Enquiries.
	 */
    public static void mapOriginToEnquiryTypeForMonashCollege(List<Case> cases) {
        for(Case c : cases) {
            c.Enquiry_Type__c = 'Future Course';
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Set priority high based on supplied email for Insurance enquiries. This
	 * 					is to replace the process builder High_Priority_Insurance_Addresses.
	 */
    public static void setPriorityForInsuranceCases(List<Case> cases) {
        Set<String> suppliedEmails = new Set<String>{
            'noreply@csnet.com.au',
            'help@dynamiqassist.com',
            'colin.brown@fullertonhealthcs.com.au'
        };
        
        for(Case c : cases) {
            if(suppliedEmails.contains(c.SuppliedEmail.toLowerCase())) {
                c.Priority = 'High';
            }
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Populate case wrap-up values based on enquiry origin for
	 * 					standard enquiries. This is to replace the process builder
	 * 					Faculty_field_updates and Monash_Connect_CoE_Email_Redirect.
	 */
    public static void mapOriginToOtherValuesForStandardCases(List<Case> cases) {
        for(Case c : cases) {
            if(c.Origin == 'Email - fee.extensions@monash.edu') {
                
                c.Category_Level_1__c = 'Fees & Financial Matters';
                c.Category_Level_2__c = 'Fee Extension';
                c.Enquiry_Type__c = 'Current Course';
                
            } else if(c.Origin == 'Email - law-clinicalplacement@monash.edu') {
                
                c.Category_Level_1__c = 'Professional Experience';
                c.Category_Level_2__c = 'Pre-placement';
                c.Enquiry_Type__c = 'Current Course';
                
            } else if(c.Origin == 'Email - Learning Adviser') {
                
                c.Category_Level_1__c = 'Student Advice';
                c.Category_Level_2__c = 'General Advice/Support';
                c.Enquiry_Type__c = 'Learning Advice';
                c.Subject = 'Learning Advice | ' + c.Subject;
                
            } else if(c.Origin == 'Web - Indonesia') {
                
                c.Enquiry_Type__c = 'Current Course';
                
            } else if(c.Origin == 'Email - COE') {
                
                c.Category_Level_1__c = 'International Visa';
                c.Category_Level_2__c = 'COE';
                c.Enquiry_Type__c = 'Current Course';
                c.Student_Type__c = 'International';
                
            }
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Customize subject for enquiries related to manual unit enrolment. This
	 * 					is to replace the process builder Manual_unit_Enrolment.
	 */
    public static void mapSubjectForManualUnitEnrolment(List<Case> cases) {
        for(Case c : cases) {
            c.Subject = c.Subject + ' - ' + System.now().format('dd MMMM yyyy, K:mm a');
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			20-03-2021
	 * @description:	Populate case values based on enquiry origin for
	 * 					hr enquiries. This is to replace the process builder
	 * 					HR_myDevelopment_Web2Case.
	 */
    public static void mapOriginToOtherValuesForHRCases(List<Case> cases) {
        for(Case c : cases) {
            if(c.Sub_Category__c == 'myDevelopment - Navigation' || c.Sub_Category__c == 'myDevelopment - Profile' || c.Sub_Category__c == 'myDevelopment - System Error') {
                
                c.Category__c = 'HR System';
                c.Tier_Level__c = 'Tier 1 - Monash Connect';
                
            } else if(c.Sub_Category__c == 'myDevelopment') {
                
                c.Category__c = 'Feedback';
                c.Tier_Level__c = 'Tier 1 - Monash Connect';
                
            } else if(c.Sub_Category__c == 'myDevelopment - Business Process') {
                
                c.Category__c = 'Policy & Procedure';
                c.Tier_Level__c = 'Tier 1 - Monash Connect';
                
            } else if(c.Sub_Category__c == 'Learning Activity' || c.Sub_Category__c == 'Awards') {
                
                c.Category__c = 'Staff Development';
                c.Tier_Level__c = 'Tier 3 - CoE';
                
            }
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @date:			13-04-2021
	 * @description:	Generate course linking fields for related course attempt
	 * 					for Monash Forms submissions.
	 */
    public static void mapCourseLinkingFieldsForMonashForms(List<Case> cases) {
        Set<Id> courseAttemptIds = new Set<Id>();
        
        for(Case c : cases) {
            courseAttemptIds.add(c.Course_Attempt__c);
        }
        
        Map<Id, Course_Attempt__c> courseAttemptsMap = new Map<Id, Course_Attempt__c>([SELECT
                                                                            Id,
                                                                            Attendance_Mode__c,
                                                                            Attendance_Type__c,
                                                                            Location__c,
                                                                            Course__c,
                                                                            Course_Attempt_Status__c,
                                                                            Course_Code__c,
                                                                            Course_Managing_Faculty__c
                                                                            FROM Course_Attempt__c WHERE Id IN :courseAttemptIds]);
        
        for(Case c : cases) {
            Course_Attempt__c ca = courseAttemptsMap.get(c.Course_Attempt__c);
            
            c.Attendance_Mode__c = ca.Attendance_Mode__c;
            c.Attendance_Type__c = ca.Attendance_Type__c;
            c.Campus__c = ca.Location__c;
            c.Course__c = ca.Course__c;
            c.Course_Attempt_Status__c = ca.Course_Attempt_Status__c;
            c.Course_Code__c = ca.Course_Code__c;
            c.Course_Linked__c = true;
            c.Home_Campus__c = ca.Location__c;
            c.Location_Code__c = ca.Location__c;
            if(c.RecordTypeId != MonConCaseServices.COMPLAINT_RECTYPEID
                    && c.Category_Level_1__c != 'Academic Integrity Breach'){
                c.Managing_Faculty__c = ca.Course_Managing_Faculty__c;
            }
        }
    }
    
    /*
	 * @author:			ayush.agrawal@monash.edu
	 * @group:			Student Admin
	 * @description:	Generate default values for Academic Progress
	 * 					Assessment cases.
	 */
    public static void setDefaultsForAcademicProgressAssessment(List<Case> cases) {
        Group unassignedQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Academic_Progress_Assessment_Unassigned' AND Type = 'Queue' LIMIT 1];
        
        Set<Id> campaignIds = new Set<Id>();
        
        for(Case c : cases) {
            campaignIds.add(c.Campaign__c);
        }
        
        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([SELECT Id, Name FROM Campaign WHERE Id IN :campaignIds]);
        
        for(Case c : cases) {
            if(c.Category_Level_1__c != null) {
                String categoryLevel1 = c.Category_Level_1__c;
                if(categoryLevel1.startsWith('AP')) {
                    List<String> splits = categoryLevel1.split(' ');
                    if(splits.size() > 1) {
                        categoryLevel1 = splits[1];
                    }
                }
                
                if(categoryLevel1.contains('-')) {
                    List<String> levelIndicatorSplit = categoryLevel1.split('-');
                    c.Enquiry_Type__c = 'Risk Level ' + levelIndicatorSplit[levelIndicatorSplit.size() - 1];
                } else {
                    c.Enquiry_Type__c = 'Risk Level ' + categoryLevel1;
                }
                
                if(c.Enquiry_Type__c == 'Risk Level 3') {
                    c.Origin = 'My Academic Progress Response';
                } else {
                    c.Origin = 'My Progress and Support';
                }
                
                c.Category_Level_1__c = 'AP ' + categoryLevel1;
                c.OwnerId = unassignedQueue.Id;
                c.Priority = null;
                c.Subject = c.Contact_Person_ID__c + ' - ' + campaigns.get(c.Campaign__c).Name;
            }
        }
    }

    /*
 * @author:			Angelo.Riveral@monash.edu
 * @date:			26/07/2021
 * @description:	Retrieves Useful links to be displayed in the 'Useful Links' component in Service Console
 */
    @AuraEnabled
    public static List<Service_Console_Useful_Link__mdt> retrieveUsefulLinks(){
        List<Service_Console_Useful_Link__mdt> listUsefulLinks = new List<Service_Console_Useful_Link__mdt>();
        for(Service_Console_Useful_Link__mdt mdt : [SELECT Title__c, URL__c, Order__c  FROM Service_Console_Useful_Link__mdt ORDER BY Order__c ASC ]){
            listUsefulLinks.add(mdt);
        }
        return listUsefulLinks;
    }

    /**
     * Return a list of Case records based on Form_Submission_ID__c (excluding the current case)
     * The result is displayed via the apexRelatedList lwc component
     */
    public class FormSubmissionRelatedCasesDataProvider implements ApexRelatedListController.DataProvider {

        public List<ApexRelatedListController.Record> getRecords(String ref) {
            ApexRelatedListController.Record[] cases = new ApexRelatedListController.Record[0];

            String fsid = [SELECT Form_Submission_ID__c FROM Case WHERE Id = :ref].Form_Submission_ID__c;

            if(String.isNotBlank(fsid)) {
                for(Case c :[
                    SELECT CaseNumber, Status, Owner.Name FROM Case
                    WHERE Form_Submission_ID__c = :fsid AND Id != :ref
                ]) {
                    List<ApexRelatedListController.RecordValue> recordValues = new List<ApexRelatedListController.RecordValue>{
                        new ApexRelatedListController.RecordValue('Status', c.Status),
                        new ApexRelatedListController.RecordValue('Owner Name', c.Owner.Name)
                    };
                    cases.add(new ApexRelatedListController.Record(c.Id, c.CaseNumber, recordValues));
                }
            }

            return cases;
        }
    }

}