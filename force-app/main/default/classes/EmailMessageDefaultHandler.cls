global without sharing class EmailMessageDefaultHandler implements Support.EmailTemplateSelector, QuickAction.QuickActionDefaultsHandler {
    
    /**
     * @description         Constructor
     */
    global EmailMessageDefaultHandler() {    
        
    }

    /**
     * @description         Default handler of email composer on classic
     */
    global ID getDefaultEmailTemplateId(ID caseId) {
        String emailTemplate=Label.defaultEmailTemplate;
        Id userRoleId=userInfo.getUserRoleId();
        
        if(userRoleId!=null) {
            UserRole role=[select Id,developerName from UserRole where id = :userRoleId];
            
            List<CaseRoleEmailTemplateMapping__mdt> roleEmailTemplateMapping=[select EmailTemplate__c,UserRoleName__c from CaseRoleEmailTemplateMapping__mdt where UserRoleName__c=:role.developerName];
            
            if(roleEmailTemplateMapping.size()>0) {
                emailTemplate=roleEmailTemplateMapping[0].EmailTemplate__c;
            }
        }
        
        List<EmailTemplate> etList=[SELECT id FROM EmailTemplate WHERE DeveloperName = :emailTemplate];        
        if(etList.size()==0) {
            throw new LimitException('No Email Template named '+emailTemplate+' found.');
        }
        return etList[0].id;
    }

    /**
     * @author              Kristian Vegerano
     * @description         Method that handles the behavior of email composer on first draft of the user - lightning
     * @param defaults      QuickAction.QuickActionDefaults[] - quick action handler
     */
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        /* HOLD OFF DRAFT AUTO PICKUP - PROVIDE READ ONLY DRAFT OF ENQUIRY OWNER FOR NOW
        
        //Initialize Variables
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults;
        
        //Retrieve quick action details
        sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults)defaults.get(0);
        
        //Retrieve the emailmessage record from the email composer quick action
        EmailMessage enquiryEmailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject();
        
        //Retrieve details of the parent enquiry
        Case contextEnquiry = [SELECT Id, CaseNumber, Enquiry_Type__c, Origin, RecordType.DeveloperName 
                               FROM Case 
                               WHERE Id = :sendEmailDefaults.getContextId()];
        
        //Handle defaulted draft email message              
        //EmailMessageDefaultHandler.defaultSharedDraft(enquiryEmailMessage, contextEnquiry);
        */
    }
    
    /* HOLD OFF DRAFT AUTO PICKUP - PROVIDE READ ONLY DRAFT OF ENQUIRY OWNER FOR NOW
        /**
         * @author              Kristian Vegerano
         * @description         Method that defaults the value of the emailmessage based from the lastest draft email
         * @param defaults      QuickAction.QuickActionDefaults[] - quick action handler
         
        global static void defaultSharedDraft(EmailMessage enquiryEmailMessage, Case parentEnquiry) {
            Set<String> activeDraftEnquiryRecordTypesList = new Set<String>();
            for(Email_Message_Shared_Draft_Configuration__mdt loopDraftSetting : [SELECT Id, Enquiry_Record_Type_DeveloperName__c 
                                                                                  FROM Email_Message_Shared_Draft_Configuration__mdt 
                                                                                  WHERE Active__c = true]){
                activeDraftEnquiryRecordTypesList.add(loopDraftSetting.Enquiry_Record_Type_DeveloperName__c);
            }
            
            //Process defaulting if parent enquiry record type is included on the draft setting
            if(activeDraftEnquiryRecordTypesList.contains(parentEnquiry.RecordType.DeveloperName)){
                //Retrieve the latest updated email message 
                EmailMessage draftEmailMessage = new EmailMessage();
                for(EmailMessage loopEmailMessage : [SELECT Id, Subject, FromAddress, ToAddress, CcAddress, BccAddress, TextBody, HtmlBody 
                                                     FROM EmailMessage 
                                                     WHERE ParentId = :parentEnquiry.Id 
                                                        AND Status = '5'
                                                     ORDER BY LastModifiedDate DESC LIMIT 1]){
                    draftEmailMessage = loopEmailMessage;
                }
                
                //Default the email message shown on the composer based of the latest modified draft email message
                if(draftEmailMessage.HtmlBody != null){             
                    //Default draft values
                    enquiryEmailMessage.Subject = draftEmailMessage.Subject;
                    enquiryEmailMessage.FromAddress = draftEmailMessage.FromAddress;
                    enquiryEmailMessage.ToAddress = draftEmailMessage.ToAddress;
                    enquiryEmailMessage.CcAddress = draftEmailMessage.CcAddress;
                    enquiryEmailMessage.BccAddress = draftEmailMessage.BccAddress;
                    enquiryEmailMessage.TextBody = draftEmailMessage.TextBody;
                    enquiryEmailMessage.HtmlBody = draftEmailMessage.HtmlBody;
                }
            }
        }
    */
}