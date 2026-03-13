/**
* @author Inderpal Dhanoa
* @date 12.Aug.2021
* @group Batch Class
* @description  Batch Class to send escalation notifications (AcadIntgEsclationNotifBatch)
 * Modifications Log  
 * Date         Author                 Modification
 * 2025-02-26 - Tom Gangemi     -      Fix parent case detection
 * 2024-08-26 - Tom Gangemi     -      Add Case Comments and Nebula Logging
 * 2024-08-14 - Tom Gangemi     -      Fix missing SOQL field in filterEmailedEnquiries
 * 2023-11-15 - Tom Gangemi     -      Dont count automated emails in untouched case check & tidy up
 * 2022-11-07 - Tom Gangemi     -      Use Teaching_Responsibility__c instead of Managing_Faculty__c
 * 2020-09-14 - Inderpal Dhanoa -      Updated Batch Job feed off unit instead of course
 * 2019-07-12 - Inderpal Dhanoa -      Create Batch Job
*/
public without sharing class AcadIntgEsclationNotifBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    public final Id busineessHoursId;

    public final Integer chiefExamEscDays = Integer.valueOf(Label.ChiefExamEscDays);
    public final Integer facultyEscDays = Integer.valueOf(Label.FacultyEscDays);
    public final Integer associateDeanEscDays = Integer.valueOf(Label.AssociateDeanEscDays);
    public final Integer untouchedSecondsCutoff = Integer.valueOf(Label.UntouchedCase);
    public final String fromAddress = Label.AI_Digest_Email_Address;
    private String originalTransactionId; // used for Nebula logging

    public Datetime now = Datetime.now(); // made public & non-final for testing purposes

    // CE Ids with the list of the Cases they will be notified of
    private Map<Id, List<Case>> enquiryNotifsByCeId = new Map<Id, List<Case>>();
    // Faculty Ids with the list of enquiries (via CUA) for which they will be notified
    private Map<Id, List<Case_Unit_Attempt__c>> cuaNotifsByFacultyId = new Map<Id, List<Case_Unit_Attempt__c>>();
    // Associate Dean Ids with the list of enquiries (via CUA) for which they will be notified
    private Map<Contact, List<Case_Unit_Attempt__c>> cuaNotifsByAdId = new Map<Contact, List<Case_Unit_Attempt__c>>();

    // used to track sent emails in unit tests
    @TestVisible private static Messaging.SingleEmailMessage[] sentChiefExamEmails = new Messaging.SingleEmailMessage[0];
    @TestVisible private static Messaging.SingleEmailMessage[] sentFacRoleEmails = new Messaging.SingleEmailMessage[0];
    @TestVisible private static Messaging.SingleEmailMessage[] sentAssocDeanEmails = new Messaging.SingleEmailMessage[0];
    
	/**
	 * Batch Class constructor
     *  Method Name: AcadIntgEsclationNotifBatch
     *  Description: Batch Class constructor to get the Business Hours Id
     */
    public AcadIntgEsclationNotifBatch() {
        BusinessHours bHours = [SELECT Id FROM BusinessHours WHERE Name = 'Default' AND IsDefault = TRUE];
        busineessHoursId = bHours.Id;
    }

    /**
     * Implement start method (from interface) to create a query and return the QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        this.originalTransactionId = Nebula.Logger.getTransactionId();

        // Exclude all empty or already modified email values
        Set<Id> unWorkedEnquiries = new Set<Id>();
        List<Case> aiEnquiries = [
            SELECT Id, CreatedDate, ParentId, LastModifiedDate, case_waiting_time__c, IsClosed,
                (SELECT Id
                FROM Cases
                WHERE RecordType.DeveloperName = 'Complaint' AND Origin = 'Web - Monash Forms')
            FROM Case
            WHERE RecordType.DeveloperName = 'Complaint' AND Enquiry_Type__c = 'Student Misconduct'
            AND Category_Level_1__c = 'Academic Integrity Breach' AND Origin = 'Web - Monash Forms'
            AND (IsClosed = FALSE OR (ParentId != NULL AND Parent.IsClosed = FALSE))
            ORDER BY CaseNumber ASC
        ];

        // Don't send reminders for parent cases
        aiEnquiries = selectNonParentEnquiries(aiEnquiries);

        for(Case enq : aiEnquiries) {
            if(Test.isRunningTest()) {
                unWorkedEnquiries.add(enq.Id);
                continue;
            }

            // Allow for {untouchedSeconds} as Case may have been modified by automations upon creation
            Long untouchedSeconds = (enq.LastModifiedDate.getTime() - enq.CreatedDate.getTime()) / 1000;
            if(untouchedSeconds < untouchedSecondsCutoff && !enq.IsClosed) {
                // Case is open and has not been touched
                Integer i_businessDaysBetween = getNoOfBusinessDaysBetweenDates(enq.CreatedDate, now);
                if(i_businessDaysBetween == chiefExamEscDays || i_businessDaysBetween == facultyEscDays || i_businessDaysBetween == associateDeanEscDays){
                    unWorkedEnquiries.add(enq.Id);
                }
            }
        }

        // Remove any enquiries that have a non-automated outbound email
        if(!unWorkedEnquiries.isEmpty()) {
            unWorkedEnquiries = selectNonEmailedEnquiries(unWorkedEnquiries);
        }

        String query = 'SELECT Id,OwnerId,CreatedDate,CaseNumber,Case_waiting_time__c,LastModifiedDate,Subject,Case_Owner_String__c,Case_Link_URL__c FROM CASE WHERE Id IN :unWorkedEnquiries ORDER by OwnerId ASC';
        Nebula.Logger.info('Academic Integrity Enquiries to be escalated: ' + unWorkedEnquiries.size());
        Nebula.Logger.saveLog();
        return Database.getQueryLocator(query);
    }

    /*
     * @param       unWorkedEnquiries Set of Enquiries
     * @return      return Set of Enquiry Ids
     * Description: Filters out any enquiries that have a non-automated outbound email
    */
    public static Set<Id> selectNonEmailedEnquiries(Set<Id> unWorkedEnquiries){
        for(EmailMessage sentEmail : [
            SELECT RelatedToId FROM EmailMessage
            WHERE Incoming = FALSE AND RelatedToId IN :unWorkedEnquiries AND CreatedBy.Profile.Name != 'Integration - Monash Forms'
            ORDER BY CreatedDate DESC])
        {
            unWorkedEnquiries.remove(sentEmail.RelatedToId);
        }
        return unWorkedEnquiries;
    }
    
    /**
     * Implement execute method (from interface) to run the business logic
     */
    public void execute(Database.BatchableContext bc, List<Case> unWorkedEnquiries) {
        Set<Id> unWorkedFacultyEnquiries = new Set<Id>();
        Set<Id> unWorkedAssocDeanEnquiries = new Set<Id>();
        Map<Id, List<Case>> chiefExamLinkedEnquiries = new Map<Id, List<Case>>();
        Map<Id, List<Case_Unit_Attempt__c>> facRoleLinkedCaseUnitAttempt = new Map<Id, List<Case_Unit_Attempt__c>>();
        Map<Contact, List<Case_Unit_Attempt__c>> assocDeanLinkedCaseUnitAttempt = new Map<Contact, List<Case_Unit_Attempt__c>>();

        for(Case unWorkedEnquiry : unWorkedEnquiries){
            Integer i_NoOfDaysBetween = getNoOfBusinessDaysBetweenDates(unWorkedEnquiry.createdDate, now);
            if(!test.isRunningTest()){
                if(i_NoOfDaysBetween == facultyEscDays || i_NoOfDaysBetween == associateDeanEscDays){
                    unWorkedFacultyEnquiries.add(unWorkedEnquiry.Id);
                }
                if(i_NoOfDaysBetween == associateDeanEscDays){
                    unWorkedAssocDeanEnquiries.add(unWorkedEnquiry.Id);
                }
            }else{
                unWorkedFacultyEnquiries.add(unWorkedEnquiry.Id);
                unWorkedAssocDeanEnquiries.add(unWorkedEnquiry.Id);
            }
            
            List<Case> linkedCases = chiefExamLinkedEnquiries.get(unWorkedEnquiry.OwnerId);
            if(linkedCases == null) {
                linkedCases = new List<Case>();
            }
            linkedCases.add(unWorkedEnquiry);
            chiefExamLinkedEnquiries.put(unWorkedEnquiry.OwnerId, linkedCases);
        }
        facRoleLinkedCaseUnitAttempt = linkFacRoleWithCaseUnitAttmpts(unWorkedFacultyEnquiries, true);
        assocDeanLinkedCaseUnitAttempt = linkAsscociateDeanWithCaseUnitAttmpts(unWorkedAssocDeanEnquiries);

        // Club together all the Enquires for the CE's from each Batch
        if(!chiefExamLinkedEnquiries.isEmpty()){
            for(Id ownerId : chiefExamLinkedEnquiries.keySet()){
                List<Case> l_chiefExamLinkedEnquiries =  chiefExamLinkedEnquiries.get(ownerId);
                List<Case> l_finalChiefExamLinkedEnquiries;
                if(enquiryNotifsByCeId.containsKey(ownerId)){
                    l_finalChiefExamLinkedEnquiries = enquiryNotifsByCeId.get(ownerId);
                }else{
                    l_finalChiefExamLinkedEnquiries = new List<Case>();    
                }
                l_finalChiefExamLinkedEnquiries.addAll(l_chiefExamLinkedEnquiries);
                enquiryNotifsByCeId.put(ownerId,l_finalChiefExamLinkedEnquiries);
            }
        } 

        // Club together all the Enquires for the Faculty from each Batch
        if(!facRoleLinkedCaseUnitAttempt.isEmpty()){
            for(Id facultyId : facRoleLinkedCaseUnitAttempt.keySet()){
                List<Case_Unit_Attempt__c> lfacRoleLinkedCaseUnitAttempt = facRoleLinkedCaseUnitAttempt.get(facultyId);
                List<Case_Unit_Attempt__c> lfinalFacRoleLinkedCaseUnitAttempt;
                if(cuaNotifsByFacultyId.containsKey(facultyId)){
                    lfinalFacRoleLinkedCaseUnitAttempt = cuaNotifsByFacultyId.get(facultyId);
                }else{
                    lfinalFacRoleLinkedCaseUnitAttempt = new List<Case_Unit_Attempt__c>();
                }
                lfinalFacRoleLinkedCaseUnitAttempt.addAll(lfacRoleLinkedCaseUnitAttempt);
                cuaNotifsByFacultyId.put(facultyId,lfinalFacRoleLinkedCaseUnitAttempt);
            }
        }
        
        // Club together all the Enquires for the Assoc Dean from each Batch
        if(!assocDeanLinkedCaseUnitAttempt.isEmpty()){
            for(Contact associateDean : assocDeanLinkedCaseUnitAttempt.keySet()){
                List<Case_Unit_Attempt__c> lAssocDeanLinkedCaseUnitAttempt =  assocDeanLinkedCaseUnitAttempt.get(associateDean);
                List<Case_Unit_Attempt__c> lfinalAssocDeanLinkedCaseUnitAttempt;
                if(cuaNotifsByAdId.containsKey(associateDean)){
                    lfinalAssocDeanLinkedCaseUnitAttempt = cuaNotifsByAdId.get(associateDean);
                }else{
                    lfinalAssocDeanLinkedCaseUnitAttempt = new List<Case_Unit_Attempt__c>();
                }
                lfinalAssocDeanLinkedCaseUnitAttempt.addAll(lAssocDeanLinkedCaseUnitAttempt);
                cuaNotifsByAdId.put(associateDean,lfinalAssocDeanLinkedCaseUnitAttempt);
            }
        }
    }

    /**
     * Implement finsh method (from interface) to wrap up processing.
     */
    public void finish(Database.BatchableContext bc) {
        Nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        Nebula.Logger.setAsyncContext(bc);

        // order of the below code means only highest priority escalation comment will be posted
        Map<Id,CaseComment> commentsByCaseId = new Map<Id,CaseComment>();

        // Dispatch Emails to CE's
        if(!enquiryNotifsByCeId.isEmpty()){
            commentsByCaseId.putAll(dispatchEmailToChiefExaminers(enquiryNotifsByCeId));
        } 

        // Dispatch Emails to Faculty Role Account
        if(!cuaNotifsByFacultyId.isEmpty()){
            commentsByCaseId.putAll(dispatchEmailToFacultyRole(cuaNotifsByFacultyId));
        }
        
        // Dispatch Emails to Associate Dean Contact
        if(!cuaNotifsByAdId.isEmpty()){
            commentsByCaseId.putAll(dispatchEmailToAssoctDean(cuaNotifsByAdId));
        }

        // insert all case comments
        TriggerCommon.disableTrigger('CaseComment'); // ensure Comments don't update the Case
        insert commentsByCaseId.values();

        Nebula.Logger.saveLog();
    }

    /**
     * For a given list of enquiries, remove any that are parent cases
     */
    public static Case[] selectNonParentEnquiries(Case[] enquires) {
        List<Case> filteredEnquiries = new List<Case>();
        for (Case c : enquires) {
            // if the enquiry has no children, add the original instance of it to the filtered list
            if (c.Cases.size() == 0) {
                filteredEnquiries.add(c);
            }
        }
        return filteredEnquiries;
    }

	/*
    * Method Name: linkFacRoleWithCaseUnitAttmpts
     * @param       s_unWorkedFacultyEnquiries Set of Unworked Enquiries
     * @param       b_validateEmail, when getting the linked faculties, the Email validation needs to be done, 
     *              when used to collect Faulties linked for Associate deans, the Email Validation is skipped as it needs to be done on the Contact
     * @return      return Map of Faculty Id with all the linked case Unit Attempts
     * Description: Check for all the linked case Unit Attempts linked with each faculty
    */
    public Map<Id, List<Case_Unit_Attempt__c>> linkFacRoleWithCaseUnitAttmpts(Set<Id> unWorkedFacultyEnquiries, Boolean validateEmail){
        Map<Id, List<Case_Unit_Attempt__c>> FacRoleLinkedCaseUnitAttempt = new Map<Id, List<Case_Unit_Attempt__c>>();
        for(Case_Unit_Attempt__c unworkedCaseUnitAttmpt :  [
            SELECT Id, Enquiry__r.CaseNumber, Enquiry__r.Case_Link_URL__c, Enquiry__r.Owner.Name, Enquiry__r.Owner.Email, Enquiry__r.Unit_Code__c,
                Enquiry__r.CreatedDate, Enquiry__r.LastModifiedDate, Enquiry__r.case_waiting_time__c, Enquiry__r.Subject,
                Unit_Attempt__r.Teaching_Responsibility__r.Name, Unit_Attempt__r.Teaching_Responsibility__r.Email_2__c,
                Unit_Offering__r.Teaching_Responsibility__r.Name, Unit_Offering__r.Teaching_Responsibility__r.Email_2__c
            FROM Case_Unit_Attempt__c
            WHERE Enquiry__c IN :unWorkedFacultyEnquiries AND Recordtype.DeveloperName = 'Academic_Integrity'
            ORDER BY Enquiry__r.CaseNumber ASC])
        {
			Boolean unitOfferingExists = false;
            List<Case_Unit_Attempt__c> linkedCaseUnitAttmpts;
            // Check if the Enquiry is linked to a Case Unit Attempt is linked to a Unit OFFERING
            if(unworkedCaseUnitAttmpt.Unit_Offering__c != null && unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r != null){
                    if(validateEmail){
                        // when getting the linked faculties, the Email validation needs to be done
                        if(String.isNotBlank(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Email_2__c) && CommonUtilities.validateEmail(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Email_2__c)){
                            unitOfferingExists = true;
                            if(FacRoleLinkedCaseUnitAttempt.containsKey(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Id)){
                                linkedCaseUnitAttmpts = FacRoleLinkedCaseUnitAttempt.get(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Id);
                            }else{
                                linkedCaseUnitAttmpts = new List<Case_Unit_Attempt__c>();  
                            }
                            linkedCaseUnitAttmpts.add(unworkedCaseUnitAttmpt);
                            FacRoleLinkedCaseUnitAttempt.put(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Id, linkedCaseUnitAttmpts);
                        }                        
                    }else{
                        // when used to collect Faulties linked for Associate deans, the Email Validation is skipped as it needs to be done on the Contact
                        unitOfferingExists = true;
                        if(FacRoleLinkedCaseUnitAttempt.containsKey(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Id)){
                            linkedCaseUnitAttmpts = FacRoleLinkedCaseUnitAttempt.get(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Id);
                        }else{
                            linkedCaseUnitAttmpts = new List<Case_Unit_Attempt__c>();  
                        }
                        linkedCaseUnitAttmpts.add(unworkedCaseUnitAttmpt);
                        FacRoleLinkedCaseUnitAttempt.put(unworkedCaseUnitAttmpt.Unit_Offering__r.Teaching_Responsibility__r.Id, linkedCaseUnitAttmpts);
                    }
            // Check if the Enquiry is linked to a Case Unit Attempt is linked to a Unit ATTEMPT 
            } else if(!unitOfferingExists && unworkedCaseUnitAttmpt.Unit_Attempt__c != null && unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r != null){
                    if(validateEmail){
                        // when getting the linked faculties, the Email validation needs to be done
                        if(String.isNotBlank(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Email_2__c) && CommonUtilities.validateEmail(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Email_2__c)){
                            if(FacRoleLinkedCaseUnitAttempt.containsKey(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Id)){
                                linkedCaseUnitAttmpts = FacRoleLinkedCaseUnitAttempt.get(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Id);
                            }else{
                                linkedCaseUnitAttmpts = new List<Case_Unit_Attempt__c>(); 
                            } 
                            linkedCaseUnitAttmpts.add(unworkedCaseUnitAttmpt);
                            FacRoleLinkedCaseUnitAttempt.put(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Id, linkedCaseUnitAttmpts);
                        }
                    }else{
                        // when used to collect Faulties linked for Associate deans, the Email Validation is skipped as it needs to be done on the Contact
                        if(FacRoleLinkedCaseUnitAttempt.containsKey(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Id)){
                            linkedCaseUnitAttmpts = FacRoleLinkedCaseUnitAttempt.get(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Id);
                        }else{
                            linkedCaseUnitAttmpts = new List<Case_Unit_Attempt__c>(); 
                        } 
                        linkedCaseUnitAttmpts.add(unworkedCaseUnitAttmpt);
                        FacRoleLinkedCaseUnitAttempt.put(unworkedCaseUnitAttmpt.Unit_Attempt__r.Teaching_Responsibility__r.Id, linkedCaseUnitAttmpts);
                    }
                
            }           
        }
        return FacRoleLinkedCaseUnitAttempt;
    }

	/*
    * Method Name:  linkAsscociateDeanWithCaseUnitAttmpts
     * @param       s_unWorkedFacultyEnquiries Set of Unworked Enquiries
     * @return      return Map of Faculty Id with all the linked case Unit Attempts
     * Description: Check for all the linked case Unit Attempts linked with each faculty
    */
	public Map<Contact, List<Case_Unit_Attempt__c>> linkAsscociateDeanWithCaseUnitAttmpts(Set<Id> unWorkedFacultyEnquiries){
        // Retrieve the Enquiries which are 10 Business days old 

        Map<Id, List<Case_Unit_Attempt__c>> facRoleLinkedCaseUnitAttempt =
            linkFacRoleWithCaseUnitAttmpts(unWorkedFacultyEnquiries, false);

		Id employeeRecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
        Map<Contact, List<Case_Unit_Attempt__c>> assocDeanLinkedCaseUnitAttempt = new Map<Contact, List<Case_Unit_Attempt__c>>();
        Map<Id,Set<Id>> assocDeanLinkedFaculties = new Map<Id,Set<Id>>();
        // Link all the Faculties associated to a Dean, One Dean could be linked to multiple Faculties
        for(Affiliation__c linkedAff : [SELECT Id, Start_Date__c, End_Date__c, Account__c, Contact__c, Contact__r.Email 
                                        FROM Affiliation__c 
                                        WHERE Account__c IN :facRoleLinkedCaseUnitAttempt.keySet()
                                        AND RecordTypeId = :employeeRecordTypeId AND Is_Active__c = TRUE
                                        AND Roles__c INCLUDES ('Associate Dean')]) {
            if(linkedAff.Start_Date__c <= Date.today() && String.isNotBlank(linkedAff.Contact__r.Email) && CommonUtilities.validateEmail(linkedAff.Contact__r.Email) && 
                (linkedAff.End_Date__c >= Date.today() || linkedAff.End_Date__c == null)){
                Set<Id> s_linkedFaculties;
                if(assocDeanLinkedFaculties.containsKey(linkedAff.Contact__c)){
                    s_linkedFaculties = assocDeanLinkedFaculties.get(linkedAff.Contact__c);
                }else{
                    s_linkedFaculties = new Set<Id>(); 
                }
                s_linkedFaculties.add(linkedAff.Account__c);
                assocDeanLinkedFaculties.put(linkedAff.Contact__c, s_linkedFaculties);
            }
        }
        // One Dean could be linked to multiple Faculties
        // Get all the Enquiries linked to all Faculties associated with each Dean  
        for(Contact linkedAssocDean : [SELECT Id, Name, Email,AccountId FROM Contact WHERE Id IN :assocDeanLinkedFaculties.keySet()]){
            if(assocDeanLinkedFaculties.containsKey(linkedAssocDean.Id)){
                // List all the Faculties associated with this Dean
                Set<Id> linkedFacultyId = assocDeanLinkedFaculties.get(linkedAssocDean.Id);
                List<Case_Unit_Attempt__c> facultyLinkedCaseUnitAttmpts = new List<Case_Unit_Attempt__c>();
                for(Id facultyId : linkedFacultyId){
                    // List all the Enquiries associated with this Faculty
                    facultyLinkedCaseUnitAttmpts = facRoleLinkedCaseUnitAttempt.get(facultyId);
                    if(!facultyLinkedCaseUnitAttmpts.isEmpty()){
                        List<Case_Unit_Attempt__c> l_assocDeanLinkedCases;
                        if(assocDeanLinkedCaseUnitAttempt.containsKey(linkedAssocDean)){
                            l_assocDeanLinkedCases = assocDeanLinkedCaseUnitAttempt.get(linkedAssocDean);
                        }else{
                            l_assocDeanLinkedCases = new List<Case_Unit_Attempt__c>(); 
                        }
                        l_assocDeanLinkedCases.addAll(facultyLinkedCaseUnitAttmpts);
                        assocDeanLinkedCaseUnitAttempt.put(linkedAssocDean, l_assocDeanLinkedCases);
                    }                            
                }
            }
        }
        return assocDeanLinkedCaseUnitAttempt;
    }

	/*
    * Method Name:  dispatchEmailToFacultyRole
     * @param       m_FacRoleLinkedCaseUnitAttempt Map of Faculty Id with all the linked case Unit Attempts
     * @return      void 
     * Description: Check for all Faculty Id with all the linked case Unit Attempts and dispatch an Email
    */
    public Map<Id,CaseComment> dispatchEmailToFacultyRole(Map<Id, List<Case_Unit_Attempt__c>> m_FacRoleLinkedCaseUnitAttempt){
        // Generate the Emails
        Map<Id,CaseComment> commentsByCaseId = new Map<Id,CaseComment>();
        Map<String,Id[]> escalatedCasesByRecipientId = new Map<String,Id[]>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        List<EmailTemplate> unReadEmailAlert = [SELECT Id,Htmlvalue FROM EmailTemplate WHERE Developername = 'Academic_Integrity_Breach_Reminder_FacultyRoleAccounts_ACE_1628130396670'];
        for(Id facultyRoleId : m_FacRoleLinkedCaseUnitAttempt.keySet()) {
            List<Case_Unit_Attempt__c> linkedCases = m_FacRoleLinkedCaseUnitAttempt.get(facultyRoleId);
            String name = '';
            String toAddress = '';
            if(linkedCases[0].Unit_Offering__c != null && linkedCases[0].Unit_Offering__r.Teaching_Responsibility__r != null){
                name = linkedCases[0].Unit_Offering__r.Teaching_Responsibility__r.Name;
                toAddress = linkedCases[0].Unit_Offering__r.Teaching_Responsibility__r.Email_2__c;
            }else if(linkedCases[0].Unit_Attempt__c != null && linkedCases[0].Unit_Attempt__r.Teaching_Responsibility__r != null){
                name = linkedCases[0].Unit_Attempt__r.Teaching_Responsibility__r.Name;
                toAddress = linkedCases[0].Unit_Attempt__r.Teaching_Responsibility__r.Email_2__c;
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String htmlBody = ''; 
            if(!unReadEmailAlert.isEmpty()){
                htmlBody = unReadEmailAlert[0].HtmlValue;
            }else if(test.isRunningTest()){
                htmlBody = '<b>'+ facultyEscDays +' Days Inactive</b><br />' + '<b>'+ associateDeanEscDays +' Days Inactive</b><br />';
            }                   

            // If the Email template does not exist then do not send out Emails
            if(String.isNotBlank(htmlBody)){
                htmlBody = htmlBody.replace('{{{Case.Case_Owner_Name__c}}}', name);
                htmlBody = formatEmailForADEFaculty(htmlBody, linkedCases, 'FacultyRole');
                htmlBody = removeUnusedDetails(htmlBody, 'FacultyRole');
                mail.setSubject('Academic Integrity Breach Reminder Faculties');
                mail.setToAddresses(new String[]{toAddress});
                mail.setHtmlBody(htmlBody);
                mail.saveAsActivity = false;
                mail.setOrgWideEmailAddressId(owea[0].Id);
                mails.add(mail);
                for(Case_Unit_Attempt__c cua : linkedCases) {
                    Id[] recipientsCases = escalatedCasesByRecipientId.get(toAddress);
                    if(recipientsCases == null) {
                        escalatedCasesByRecipientId.put(toAddress, new Id[]{cua.Enquiry__c});
                    } else {
                        recipientsCases.add(cua.Enquiry__c);
                    }

                    CaseComment cc = commentsByCaseId.get(cua.Enquiry__c);
                    if(cc == null) {
                        cc = new CaseComment(ParentId = cua.Enquiry__c, CommentBody = 'AI Escalation Email sent to Faculty: '+toAddress);
                        commentsByCaseId.put(cua.Enquiry__c, cc);
                    } else {
                        cc.CommentBody += ', '+toAddress;
                    }
                }
            }
        }
        try {
            Messaging.sendEmail(mails);
            sentFacRoleEmails.addAll(mails);
            Nebula.Logger.info('Escalation emails sent to Faculty Role:\n'+JSON.serializePretty(escalatedCasesByRecipientId));
        } catch (Exception e) {
            Nebula.Logger.error('Error sending escalation email to Faculty Role', e);
        }
        return commentsByCaseId;
    }

	/*
    * Method Name:  dispatchEmailToAssoctDean
     * @param       m_AssocDeanLinkedCaseUnitAttempt Map of Contact with all the linked case Unit Attempts
     * @return      void 
     * Description: Check for all Contact with all the linked case Unit Attempts and dispatch Emails
    */
    public Map<Id,CaseComment> dispatchEmailToAssoctDean(Map<Contact, List<Case_Unit_Attempt__c>> assocDeanLinkedCaseUnitAttempt){
        // Generate the Emails
        Map<Id,CaseComment> commentsByCaseId = new Map<Id,CaseComment>();
        Map<String,Id[]> escalatedCasesByRecipientId = new Map<String,Id[]>();
    	List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        List<EmailTemplate> unReadEmailAlert = [SELECT Id,Htmlvalue FROM EmailTemplate WHERE Developername = 'Academic_Integrity_Breach_Reminder_FacultyRoleAccounts_ACE_1628130396670'];
        for(Contact associateDean : assocDeanLinkedCaseUnitAttempt.keySet()) {
            List<Case_Unit_Attempt__c> linkedCases = assocDeanLinkedCaseUnitAttempt.get(associateDean);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String htmlBody = ''; 
            if(!unReadEmailAlert.isEmpty()){
                htmlBody = unReadEmailAlert[0].HtmlValue;
            }else if(test.isRunningTest()){
                htmlBody = '<b>'+ facultyEscDays +' Days Inactive</b><br />' + '<b>'+ associateDeanEscDays +' Days Inactive</b><br />';
            }
            // If the Email template does not exist then do not send out Emails
            if(String.isNotBlank(htmlBody)){
                for(Case_Unit_Attempt__c cua : linkedCases) {
                    Id[] recipientsCases = escalatedCasesByRecipientId.get(associateDean.Email);
                    if(recipientsCases == null) {
                        escalatedCasesByRecipientId.put(associateDean.Email, new Id[]{cua.Enquiry__c});
                    } else {
                        recipientsCases.add(cua.Enquiry__c);
                    }

                    CaseComment cc = commentsByCaseId.get(cua.Enquiry__c);
                    if(cc == null) {
                        cc = new CaseComment(ParentId = cua.Enquiry__c, CommentBody = 'AI Escalation Email sent to Associate Dean: '+associateDean.Email);
                        commentsByCaseId.put(cua.Enquiry__c, cc);
                    } else {
                        cc.CommentBody += ', '+associateDean.Email;
                    }
                }
                htmlBody = htmlBody.replace('{{{Case.Case_Owner_Name__c}}}', associateDean.Name);
                htmlBody = formatEmailForADEFaculty(htmlBody, linkedCases, 'ADE');
                mail.setSubject('Academic Integrity Breach Reminder Associates');
                mail.setToAddresses(new String[]{associateDean.Email});
                mail.setHtmlBody(htmlBody);
                mail.saveAsActivity = false;
                mail.setOrgWideEmailAddressId(owea[0].Id);  
                mails.add(mail);
            }
        }
        try {
            Messaging.sendEmail(mails);
            sentAssocDeanEmails.addAll(mails);
            Nebula.Logger.info('Escalation emails sent to Associate Deans:\n'+JSON.serializePretty(escalatedCasesByRecipientId));
        } catch (Exception e) {
            Nebula.Logger.error('Error sending escalation email to Associate Dean', e);
        }
        return commentsByCaseId;
    }

	/*
    * Method Name:  dispatchEmailToChiefExaminers
     * @param       m_ChiefExamLinkedEnquiries Map of User Id with all the linked cases
     * @return      void 
     * Description: Check for all UserIds with all the linked cases and dispatch Emails
    */
    public Map<Id,CaseComment> dispatchEmailToChiefExaminers(Map<Id, List<Case>> chiefExamLinkedEnquiries){
        // Generate the Emails
        Map<Id,CaseComment> commentsByCaseId = new Map<Id,CaseComment>();
        Map<String,Id[]> escalatedCasesByRecipientId = new Map<String,Id[]>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        List<EmailTemplate> unReadEmailAlert = [SELECT Id, Htmlvalue FROM EmailTemplate WHERE Developername = 'Academic_Integrity_Breach_Reminder_Chief_Examiners_1627956992559'];
        Map<Id,User> users = new Map<Id,User>([SELECT Email FROM User WHERE Id IN :chiefExamLinkedEnquiries.keySet()]);
        for(Id unReadEnquiryOwnerId : chiefExamLinkedEnquiries.keySet()) {
            User owner = users.get(unReadEnquiryOwnerId);
            if(owner != null) {
                // unReadEnquiryOwnerId is a user ID
                List<Case> linkedCases = chiefExamLinkedEnquiries.get(unReadEnquiryOwnerId);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String htmlBody = ''; 
                if(!unReadEmailAlert.isEmpty()){
                    htmlBody = unReadEmailAlert[0].HtmlValue;
                }else if(test.isRunningTest()){
                    htmlBody = '<b>'+ chiefExamEscDays +' Days Inactive</b><br />'+'<b>'+ facultyEscDays +' Days Inactive</b><br />' + '<b>'+ associateDeanEscDays +' Days Inactive</b><br />';
                }
                // If the Email template does not exist then do not send out Emails
                if(String.isNotBlank(htmlBody)){
                    for(Case linkedCase : linkedCases) {
                        Id[] recipientsCases = escalatedCasesByRecipientId.get(owner.Email);
                        if(recipientsCases == null) {
                            escalatedCasesByRecipientId.put(owner.Email, new Id[]{linkedCase.Id});
                        } else {
                            recipientsCases.add(linkedCase.Id);
                        }

                        CaseComment cc = commentsByCaseId.get(linkedCase.Id);
                        if(cc == null) {
                            cc = new CaseComment(ParentId = linkedCase.Id, CommentBody = 'AI Escalation Email sent to CE: '+owner.Email);
                            commentsByCaseId.put(linkedCase.Id, cc);
                        } else {
                            cc.CommentBody += ', '+owner.Email;
                        }
                    }
                    htmlBody = htmlBody.replace('{{{Case.Case_Owner_Name__c}}}', linkedCases[0].Case_Owner_String__c);
                    htmlBody = formatEmailForCE(htmlBody, linkedCases);
                    htmlBody = removeUnusedDetails(htmlBody, 'CE');
                    mail.setSubject('Academic Integrity Breach Reminder Chief Examiners');
                    mail.setTargetObjectId(unReadEnquiryOwnerId);
                    mail.setHtmlBody(htmlBody);
                    mail.saveAsActivity = false;
                    mail.setOrgWideEmailAddressId(owea[0].Id);
                    mails.add(mail);    
                }
            }
        }
        try {
            Messaging.sendEmail(mails);
            sentChiefExamEmails.addAll(mails);
            Nebula.Logger.info('Escalation emails sent to Chief Examiners:\n'+JSON.serializePretty(escalatedCasesByRecipientId));
        } catch (Exception e) {
            Nebula.Logger.error('Error sending escalation email to Chief Examiners', e);
        }
        return commentsByCaseId;
    }

	/*
    * Method Name:  formatEmailForCE
     * @param       htmlBody String of the HTM body from Email template
     * @param       linkedCases List of cases
     * @return      void 
     * Description: Check for html template and append the cases 
    */
    public String formatEmailForCE(String htmlBody, List<Case> linkedCases){
        for(Case linkedCase : linkedcases){
            String content = '';
            content = (linkedCase.Subject == null ? ' ' : linkedCase.Subject) + '<br/>';
            String s_NewCaseDetails = '<a href="'+linkedCase.Case_Link_URL__c+'/view">'+linkedCase.CaseNumber+'</a> ' + content;
            Integer noOfDaysBetween = getNoOfBusinessDaysBetweenDates(linkedCase.createdDate, now);
            String s_initialCaseDetails;
            if(noOfDaysBetween == chiefExamEscDays || noOfDaysBetween == facultyEscDays || noOfDaysBetween == associateDeanEscDays){
                s_initialCaseDetails = '<b>'+noOfDaysBetween+' Days Inactive</b><br />';
                s_NewCaseDetails = s_initialCaseDetails + s_NewCaseDetails; 
                htmlBody = htmlBody.replace(s_initialCaseDetails, s_NewCaseDetails);
            }
        }
        return htmlBody;
    }

	/*
    * Method Name:  formatEmailForADEFaculty
     * @param       htmlBody String of the HTM body from Email template
     * @param       linkedCases List of case unit attempts
     * @param       s_formatFor string to check if the fromatting is to be done for Associate or Faculty 
     * @return      String of the formatted Email 
     * Description: Check for html template and append the cases 
    */
    public String formatEmailForADEFaculty(String htmlBody, List<Case_Unit_Attempt__c> linkedCases, String formatFor){
        for(Case_Unit_Attempt__c linkedCase : linkedcases){
            String content = (linkedCase.Enquiry__r.Owner.Name == null ? ' ' : linkedCase.Enquiry__r.Owner.Name) + ' ' + linkedCase.Enquiry__r.Owner.Email + ' ' + (linkedCase.Enquiry__r.Unit_Code__c == null ? ' ' : linkedCase.Enquiry__r.Unit_Code__c)  + '<br/>';
            String s_NewCaseDetails = '<a href="'+linkedCase.Enquiry__r.Case_Link_URL__c+'/view">'+linkedCase.Enquiry__r.CaseNumber+'</a> ' + content;
            Integer noOfDaysBetween = getNoOfBusinessDaysBetweenDates(linkedCase.Enquiry__r.createdDate, now);
            String s_initialCaseDetails;
            if(formatFor == 'FacultyRole'){
                if(noOfDaysBetween == facultyEscDays || noOfDaysBetween == associateDeanEscDays){
                    s_initialCaseDetails = '<b>'+noOfDaysBetween+' Days Inactive</b><br />';
                    s_NewCaseDetails = s_initialCaseDetails + s_NewCaseDetails; 
                    htmlBody = htmlBody.replace(s_initialCaseDetails, s_NewCaseDetails);
                }
            }else if(formatFor == 'ADE'){
                s_initialCaseDetails = '<b>'+ facultyEscDays +' Days Inactive</b><br />';
                htmlBody = htmlBody.replace(s_initialCaseDetails, '');
                if(noOfDaysBetween == associateDeanEscDays){
                    s_initialCaseDetails = '<b>'+noOfDaysBetween+' Days Inactive</b><br />';
                    s_NewCaseDetails = s_initialCaseDetails + s_NewCaseDetails; 
                    htmlBody = htmlBody.replace(s_initialCaseDetails, s_NewCaseDetails);
                }
            }
        }
        return htmlBody;
    }
	
	/*
    * Method Name:  removeUnusedDetails
     * @param       htmlBody String of the HTM body from Email template
     * @param       s_formatFor string to check if the fromatting is to be done for Associate or Faculty 
     * @return      String of the formatted Email 
     * Description: Check for html template and removed unused details 
    */
	public String removeUnusedDetails(String htmlBody, String formatFor){
	    // The Email Template has placeholders for 3,5,10 days, 
		// If there are no Enquiries for any day, then the section is to be removed from the Email template
        String removeText;
        if(formatFor == 'CE'){
            removeText = '<b>'+ chiefExamEscDays +' Days Inactive</b><br />\n<br />';
            if(htmlBody.contains(removeText)){
                htmlBody = htmlBody.replace(removeText, '');
            }
            removeText = '<b>'+ associateDeanEscDays +' Days Inactive</b><br />\n<br />';
            if(htmlBody.contains(removeText)){
                htmlBody = htmlBody.replace(removeText, '');
            }
            removeText = '<b>'+ facultyEscDays +' Days Inactive</b><br />\n<br />';
            if(htmlBody.contains(removeText)){
                htmlBody = htmlBody.replace(removeText, '');
            }
        }else if(formatFor == 'FacultyRole'){
            removeText = '<b>'+ associateDeanEscDays +' Days Inactive</b><br />\n<br />';
            if(htmlBody.contains(removeText)){
                htmlBody = htmlBody.replace(removeText, '');
            }
            removeText = '<b>'+ facultyEscDays +' Days Inactive</b><br />\n<br />';
            if(htmlBody.contains(removeText)){
                htmlBody = htmlBody.replace(removeText, '');
            }
        }
        return htmlBody;    
    }

	/*
    * Method Name:  getNoOfBusinessDaysBetweenDates
     * @param       startDate Start Date 
     * @param       endDate End date
     * @return      Integr of the formatted Email 
     * Description: Check to get the business days between 2 days 
    */
    public Integer getNoOfBusinessDaysBetweenDates(DateTime startDate, DateTime endDate){
        Long inputMillisecs = BusinessHours.diff(busineessHoursId, startDate, endDate);
        Double hours = inputMillisecs/3600000;      
        return math.mod(math.floor(hours/8).intValue(),365);
    }

	/*
    * Method Name:  getNoOfBusinessDaysBetweenDates
     * @param       startDate Start Date 
     * @param       endDate End date
     * @return      Integr of the formatted Email 
     * Description: Check to get the business days between 2 days 
    */
    public void execute(SchedulableContext sc) {
        AcadIntgEsclationNotifBatch batchObj = new AcadIntgEsclationNotifBatch (); 
        Database.executeBatch(batchObj,100);
    }
}