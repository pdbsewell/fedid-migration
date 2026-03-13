/**
 * @author Carl Vescovi, PwC
 * @description Services class to provide Case sObject centric logical support
 * @group Enquiry Management
 * @revision DEC.04.2017     Nick Guia   - code refactor to fix too many SOQL error. <br/>
 *           OCT.28.2019     Nick Guia   - Added populateCaseLead <br/>
 *           JAN.07.2020     APRivera    - removed unused methods and comments <br/>
 */
public class CaseServices {
    public static final String CURRENT_COURSE = 'Current Course';
    public static final Set<String> setSolvedStatus = new Set<String>{'Solved', 'Referred Off-System', 'Referred by Phone'};
    public static final Set<String> setOpenStatus = new Set<String>{'Open', 'Awaiting Customer Feedback', 'Pending Investigation'};

    public static Id CASE_PROFESSIONALYEAR_RECTYPE {
        get {
            if(CASE_PROFESSIONALYEAR_RECTYPE == null){
                CASE_PROFESSIONALYEAR_RECTYPE = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Year_Enquiry').getRecordTypeId();
            }
            return CASE_PROFESSIONALYEAR_RECTYPE;
        }
        set;
    }

    public static Id CASE_PROFESSIONALYEAR_QUEUE {
        get {
            if(CASE_PROFESSIONALYEAR_QUEUE == null){
                CASE_PROFESSIONALYEAR_QUEUE = [SELECT Id
                FROM Group
                WHERE DeveloperName = 'MonashCollege_ProfessionalYear_Enquiries'
                AND Type = 'Queue'
                LIMIT 1].Id;
            }
            return CASE_PROFESSIONALYEAR_QUEUE;
        }
        set;
    }

    /*******************************************************************************
    * @author       Ven Vairavan
    * @date         04/07/2019
    * @description  Return Monash Future Enquiry Queue Name for Monash College
    * @revision     04/07/2019 - Initial Version
    *******************************************************************************/
    public static Id CASE_PROFESSIONALFUTUREYEAR_QUEUE {
        get {
            if(CASE_PROFESSIONALFUTUREYEAR_QUEUE == null){
                CASE_PROFESSIONALFUTUREYEAR_QUEUE = [SELECT Id
                FROM Group
                WHERE DeveloperName = 'MonashCollege_MPP_Future_Enquiries'
                AND Type = 'Queue'
                LIMIT 1].Id;
            }
            return CASE_PROFESSIONALFUTUREYEAR_QUEUE;
        }
        set;
    }

    /**
     * future method to log errors from console web service callouts,
     * to prevent 'you have work pending' issues on subsequent callouts
     *
     * @param proc describes the process that was in progress
     * @param cls  name of the class that the error occured in
     * @param meth name of the method that the error occured in
     * @param msg the message that the exception returned
     */
    @future
    public static void storeExLog(string proc, string cls, string meth, string msg){
        system.debug('** Err logged - '+proc+':'+cls+':'+meth+':'+msg);
        ExLog.write(proc, cls, meth, msg);
    }

    /**
     * @author                      Kristian Vegerano
     * @description                 Prepopulate Case Business Hours Ages fields
     * @param newCaseList - List of Case records on the trigger batch
     */

    /**
     * clear the 'Last Email Received' field on open cases that have just had a task logged to them
     * NG: DEC.04.2017 - This method should be moved to TaskTriggerHandler
     */
    public class clearLastEmailReceived implements Triggers.Handler {
        public void run(){
            Set<Id> caseIds = new Set<Id>();
            for(Task tsk : (List<Task>)Trigger.new) caseIds.add(tsk.WhatId);

            List<Case> cases = new List<Case>([SELECT Id, Origin, Latest_Inbound_Email__c, RecordType.Name
            FROM Case
            WHERE ( Id IN: caseIds
            AND Latest_Inbound_Email__c != NULL
            AND IsClosed = FALSE )]);
            if(!cases.isEmpty()){
                for(Case cse : cases) {
                    if(CaseUtilities.isAllowedRecordType(cse.RecordTypeId)) {
                        cse.Latest_Inbound_Email__c = null;
                    }
                }
                TriggerCommon.disableTrigger('Case'); // avoid unnecessary processing
                update cases;
                TriggerCommon.enableTrigger('Case');
            }
        }
    }

    /**
     * @author       Ryan Wilson
     * @date         08/03/2017
     * @description  Method to do callout to Calabrio to get the agents call id
     * @revision
     */
    public class LogRecordingOnActivityInsert implements Triggers.Handler {
        public void run() {
            User currentUser = [SELECT UserRoleId, UserRole.Name, Email, FederationIdentifier, Id, Name FROM User WHERE Id =:UserInfo.getUserId()];
            CalabrioIntegration__c testCal = CalabrioIntegration__c.getValues('Credentials');

            String strUserRole = currentUser.UserRoleId != null? currentUser.UserRole.Name: 'eSolutions'; //to avoid null reference error if Current User has no Role

            Set<Id> caseIds = new Set<Id>();
            for(Task tsk : (List<Task>)Trigger.new) caseIds.add(tsk.WhatId);

            List<Case> cases = new List<Case>([SELECT Id, Origin
            FROM Case
            WHERE Id IN:caseIds]);
            if(!cases.isEmpty()){
                for(Case cse : cases) {
                    if(!TriggerCommon.inFutureContext){
                        //Calabrio callout once activity has been logged
                        if(testCal != null && testCal.AllowCallout__c && testCal.AllowedStaff__c.contains(strUserRole)){
                            if(cse.Origin == 'Phone'){
                                try{
                                    CalabrioServices.calabrioCallout(currentUser.FederationIdentifier, cse.Id);
                                }catch(Exception e){
                                    ExLog.add('CaseServices','Case','checkForActiveCall', e);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @author              Kristian Vegerano
     * @description         Class supporting sending SingleEmailMessage to be queued (asynchronously) -
     *                      Required to be queued so that attachments related to the enquiry may will be available before sending an email
     */
    public class MgeSendEmailToFacultyQueueable implements Queueable {
        //List of Emails to be sent
        private List<Case> caseList;

        public MgeSendEmailToFacultyQueueable(List<Case> newCaseList) {
            this.caseList = newCaseList;
        }
        // main method implementing the interface method
        public void execute(QueueableContext context) {
            CaseServices.mgeSendEmailToFaculty(caseList);
        }
    }

    /**
     * @author              Kristian Vegerano
     * @description         Method that compiles email messages to be sent to faculty which includes the attachment submitted from the form
     * @param newMap        Trigger.newMap context variable
     */
    public static void mgeSendEmailToFaculty(List<Case> includedEnquiriesList) {
        //Initialize Variables
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        //Retrieve Deferral Request Email Template
        EmailTemplate deferredRequestEmailTemplate = [SELECT Id FROM EmailTemplate WHERE Name = 'Deferral Request' LIMIT 1];

        //Retrieve org wide address for mgro
        List<OrgWideEmailAddress> owaMGRO = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'mge-apply@f.e.monash.edu' LIMIT 1];

        //Retrieve attachments related to the enquiries on the trigger context
        Map<Id, List<Id>> enquiryAttachmentsMap = new Map<Id, List<Id>>();
        for(Attachment loopAttachment : [SELECT Id, ParentId FROM Attachment WHERE ParentId IN :(new Map<Id, Case>(includedEnquiriesList)).keySet()]){
            //Add attachment ids
            if(!enquiryAttachmentsMap.containsKey(loopAttachment.ParentId)){
                enquiryAttachmentsMap.put(loopAttachment.ParentId, new List<Id>());
            }
            enquiryAttachmentsMap.get(loopAttachment.ParentId).add(loopAttachment.Id);
        }

        //Generate single email messages based off from the enquiries
        for (Case loopCase : includedEnquiriesList) {
            // Create a new Email Message
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            // Set list of recipient addresses
            List<String> sendTo = new List<String>();
            if(loopCase.Faculty_Email__c != null){
                sendTo.add(loopCase.Faculty_Email__c);
            }
            if(loopCase.Supplied_Supervisors_Email__c != null){
                sendTo.add(loopCase.Supplied_Supervisors_Email__c);
            }
            mail.setToAddresses(sendTo);

            // Set who the email is sent from
            mail.setReplyTo('mge-apply@f.e.monash.edu');
            if(owaMGRO.size() > 0){
                mail.setOrgWideEmailAddressId(owaMGRO.get(0).Id);
            }

            //Set attachments if exist
            if(enquiryAttachmentsMap.containsKey(loopCase.Id)){
                mail.setEntityAttachments(enquiryAttachmentsMap.get(loopCase.Id));
            }

            // (Optional) Set list of people who should be CC'ed
            List<String> ccTo = new List<String>();
            ccTo.add('mgro-apply@monash.edu');
            mail.setCcAddresses(ccTo);

            // Add email template Id
            mail.setTemplateId(deferredRequestEmailTemplate.Id);

            // Add relevant enquiry record
            mail.setWhatId(loopCase.Id);

            // Add relevant contact record
            mail.setTargetObjectId(loopCase.ContactId);

            // Do not send to contact
            mail.setTreatTargetObjectAsRecipient(false);

            // Add your email to the master list
            mails.add(mail);
        }

        //Queue emails
        if(mails.size() > 0){
            if(!Test.isRunningTest()){
                Messaging.sendEmail(mails);
            }
        }
    }

    /**
     * @description Populates the Lead field in Case with the related "active"
     *   Prospective Student Lead related to the Case's Contact
     * @param caseList : Case records to be processed
     */
    public static void populateCaseLead(List<Case> caseList) {
        Set<Id> contactId = new Set<Id>();
        Map<Id, List<Case>> casesByConIdMap = new MAp<Id, List<Case>>();
        Map<Id, Lead> leadByContactId = new Map<Id, Lead>();

        //collect cases mapped by contact ID
        for(Case iCase : caseList) {
            if(iCase.ContactId != null) {
                List<Case> conCases = casesByConIdMap.get(iCase.ContactId);
                if(conCases == null) {
                    conCases = new List<Case>();
                }
                conCases.add(iCase);
                casesByConIdMap.put(iCase.ContactId, conCases);
            }
        }

        //collect active prospective student leads related to the contact
        for(Lead iLead : [SELECT Id, Contact__c
                        FROM Lead 
                        WHERE Active_Lead_Contact_Id__c IN :casesByConIdMap.keySet()
                        AND RecordTypeId = :StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT
                        ORDER BY LastModifiedDate ASC]) 
        {
            leadByContactId.put(iLead.Contact__c, iLead);
        }

        //assign lead IDs to the cases
        for(Id iConId : casesByConIdMap.keySet()) {
            Lead psLead = leadByContactId.get(iConId);
            if(psLead != null) {
                for(Case iCase : casesByConIdMap.get(iConId)) {
                    iCase.Lead__c = psLead.Id;
                }
            }
        }
        
    }
}