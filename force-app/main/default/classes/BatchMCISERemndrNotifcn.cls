/**
 * @author Inderpal Dhanoa
 * @date 03.Sep.2023
 * @description Batch class for Monash Connect to send out reminder mails for U18 Students. 
 * @group Monash Connect
 * @revision    Inderpal D, 03.Sep.2023 - Initial Version
 */
public with sharing class BatchMCISERemndrNotifcn implements Database.Batchable<sObject>, Database.Stateful { 
    String S_EVENT_TAG = String.ValueOf(Label.MC_ISE_Calendly_Link);
    List<OrgWideEmailAddress> owea; 
    List<EmailTemplate> emailTemp;
    Id campId;
    Set<Id> s_revisedCaseIds;

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/09/2023
    * @description  Constructor for Batch Class
    * @revision     03/09/2023 - Created
    *******************************************************************************/ 
    public BatchMCISERemndrNotifcn(Id campaignId, Set<Id> s_revisedCaseIdList) {
        owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :String.valueOf(Label.Monash_Connect_ISE)];
        emailTemp = [SELECT Id, Name, Htmlvalue FROM EmailTemplate WHERE Folder.Name like '%International Student Engagement%' AND Name = :String.valueOf(Label.Monash_Connect_ISE_Rem_Email_Temp)];
        campId = campaignId;
        s_revisedCaseIds = s_revisedCaseIdList;
    }
    
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/09/2023
    * @description  Batch Start class
    * @revision     03/09/2023- Created
    *******************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        String query = 'SELECT Id, ContactId, Contact.Email, First_Name_case_corrected__c, JSON_Payload__c FROM CASE WHERE Campaign__c = :campId AND Id IN :s_revisedCaseIds';
        return Database.getQueryLocator(query);    
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/09/2023
    * @description  Batch execute method
    * @revision     03/09/2023 - Created
    *******************************************************************************/
    public void execute(Database.BatchableContext bc, List<Case> records){
        // Check all Enquiries for which Calendly Events are not accepted
        String s_inviteURLWithEnqId, s_emailBody;
        Messaging.SingleEmailMessage mail;
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        // Send Email invites
        for(Case linkedEnq : records){
            mail = new Messaging.SingleEmailMessage();
            s_emailBody = emailTemp[0].Htmlvalue;
            s_emailBody = s_emailBody.replace('{{{Recipient.First_Name__c}}}', linkedEnq.First_Name_case_corrected__c);
            mail.setSubject(emailTemp[0].Name);
            mail.setToAddresses(new String[]{linkedEnq.Contact.Email});
            mail.setTargetObjectId(linkedEnq.contactId);
            mail.setWhatId(linkedEnq.Id);
            s_inviteURLWithEnqId = ' <a href="' + String.valueOf(linkedEnq.JSON_Payload__c) + '">' + S_EVENT_TAG + '</a>';
            s_emailBody = s_emailBody.replace(S_EVENT_TAG, s_inviteURLWithEnqId);
            mail.setHtmlBody(s_emailBody);
            mail.saveAsActivity = true;
            mail.setOrgWideEmailAddressId(owea[0].Id);
            mails.add(mail);           
        }

        try {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
        } catch (Exception e) {
            LogUtilityException.logException(e,'BatchMCISSRemndrNotifcn execute Email Delivery');
        }
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         03/09/2023
    * @description  Batch Finish Method
    * @revision     03/09/2023 - Created
    *******************************************************************************/
    public void finish(Database.BatchableContext bc){
       
    }
}