/**
 * @description Batchable Class to send reminder Email to Chief Examiners.
				Class implements Database.Schedule
 * @author Inderpal Dhanoa
 * @date 2021-07-21
 * @revision     SEP.22.2021   SA-977,  Unread Email Alert Fix 
 **/
global without sharing class AcadmIntegUnReadEmailNotifBatch implements Database.Batchable<sObject>, Schedulable{
    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Exclue all empty or already modified email values
        Id complRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
        Map<Id,Id> m_uniqueOwnerIdEnquiries = new Map<Id,Id>();
        for(Case unreadEnquiry :[SELECT Id, OwnerId, Owner.EMail FROM CASE WHERE RecordTypeId = :complRecordTypeId AND IsClosed = false 
                                 AND Alerts__c != '' AND Enquiry_Type__c = 'Student Misconduct'
                                 AND Category_Level_1__c = 'Academic Integrity Breach' AND Origin = 'Web - Monash Forms']){
            if(!m_uniqueOwnerIdEnquiries.containsKey(unreadEnquiry.OwnerId)){
                m_uniqueOwnerIdEnquiries.put(unreadEnquiry.OwnerId, unreadEnquiry.Id);
            }
        }
        return Database.getQueryLocator([SELECT Id, OwnerId, Case_Owner_Name__c FROM CASE WHERE Id IN :m_uniqueOwnerIdEnquiries.values()]);
    }
    
    /**
    * Implement execute method (from interface) to run the business logic
    */
    global void execute(Database.BatchableContext bc, List<Case> unReadEnquiries) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@f.e.monash.edu'];
        List<ListView> l_myEnqListView = [SELECT Id, DeveloperName FROM ListView WHERE DeveloperName = 'My_Cases'];
        // Generate URL for the List View https://xxx/lightning/o/Case/list?filterName=00B5P0000016f1VUAQ
        String baseURL = System.URL.getSalesforceBaseURL().toExternalForm();
		String listViewURL = 'a href="' + baseURL + '/lightning/o/Case/list?filterName=' + l_myEnqListView[0].Id + '"';
        List<EmailTemplate> unReadEmailAlert = [SELECT Id,Htmlvalue FROM EmailTemplate WHERE Developername = 'UnReadEmailAlert_1626844197401'];
        if(!unReadEmailAlert.isEmpty()){
            for(Case unReadEnquiry : unReadEnquiries) {
                String s_ownerId = String.valueOf(unReadEnquiry.OwnerId);
                // Owner should be a User, Lead, Contact or Person Account
                if(s_ownerId.startsWith('005') || s_ownerId.startsWith('003') || s_ownerId.startsWith('001') || s_ownerId.startsWith('00Q')){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    String htmlBody = unReadEmailAlert[0].HtmlValue;
                    htmlBody = htmlBody.replace('{{{Case.OwnerId}}}', unReadEnquiry.Case_Owner_Name__c);
                    htmlBody = htmlBody.replace('a href=""', listViewURL);
                    mail.setSubject('Unread Email Notifications'); 
                    mail.setTargetObjectId(unReadEnquiry.OwnerId);
                    mail.setHtmlBody(htmlBody);
                    mail.saveAsActivity = false;
                    mail.setOrgWideEmailAddressId(owea[0].Id);
                    mails.add(mail);
                }                
            }
            try {
                Messaging.sendEmail(mails);
            } catch (Exception e) {
                System.debug(e.getMessage());
                LogUtilityException.logException(e,'AcadmIntegUnReadEmailNotifBatch.execute');
            }
        }        
    }

    /**
    * Implement finsh method (from interface) to wrap up processing.
    */
    global void finish(Database.BatchableContext bc) {
    }

    global void execute(SchedulableContext sc) {
        AcadmIntegUnReadEmailNotifBatch batchObj = new AcadmIntegUnReadEmailNotifBatch (); 
        Database.executeBatch(batchObj,100);
    }
}