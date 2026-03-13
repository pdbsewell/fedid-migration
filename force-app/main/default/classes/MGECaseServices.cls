/**
 * @description Monash Graduate Education Services class to provide Case sObject centric logical support
 * @revision
 *  MAR.01.2019     APRivera    - Created
 */

public class MGECaseServices {

    public static Id MGE_RECTYPEID {
        get {
            if(MGE_RECTYPEID == null){
                MGE_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MGE_Enquiry').getRecordTypeId();
            }
            return MGE_RECTYPEID;
        }
        set;
    }

    /**
     * @author              Kristian Vegerano
     * @description         Method that defaults values for the mge enquiries submitted via form "Change of Commencement Date Form""
     * @param newMap        Trigger.newMap context variable
     */
    public static void mgeDefaultValuesIncludeAttachmentOnEmailToFaculty(List<Case> lstCase, Set<Id> setCaseIds) {
        //Initialize Variables
        List<Case> includedEnquiriesList = new List<Case>();
        Map<Id, Case> caseFormulaMap = new Map<Id, Case>();

        //Retrieve values from formula fields
        for(Case loopCase : [SELECT Id, Faculty_Email_Mapping__c, Supplied_Supervisors_Email__c, ContactId, File_Attachment__c
                                FROM Case WHERE Id IN :setCaseIds]){
            caseFormulaMap.put(loopCase.Id, loopCase);
        }

        for(Case loopCase : lstCase){
            //Default MGE Enquiry field values
            includedEnquiriesList.add(new Case(Id = loopCase.Id,
                    Enquiry_Type__c = 'Future Course',
                    Category_Level_1__c = 'MGE Admissions',
                    Category_Level_2__c = 'Deferral',
                    Subject = 'Deferral Request',
                    Priority = 'Medium',
                    Faculty_Email__c = caseFormulaMap.get(loopCase.Id).Faculty_Email_Mapping__c,
                    Supplied_Supervisors_Email__c = caseFormulaMap.get(loopCase.Id).Supplied_Supervisors_Email__c,
                    ContactId = caseFormulaMap.get(loopCase.Id).ContactId,
                    Status = 'Awaiting Customer Feedback'));
        }

        //Update the enquiry to apply defaulted values
        if(includedEnquiriesList.size() > 0){
            //Updated enquiries with defaulted value
            update includedEnquiriesList;

            List<Case> filteredMgroNoAttachmentList = new List<Case>();
            for(Case loopCase : includedEnquiriesList){
                if(caseFormulaMap.get(loopCase.Id).File_Attachment__c == null){
                    //Include enquiry if there are no attachment included on the submitted mgro form
                    filteredMgroNoAttachmentList.add(loopCase);
                }
            }

            if(filteredMgroNoAttachmentList.size() > 0){
                Queueable queueItem = new MgeSendEmailToFacultyQueueable(filteredMgroNoAttachmentList);
                Id jobID = System.enqueueJob(queueItem);
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
            mgeSendEmailToFaculty(caseList);
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

}