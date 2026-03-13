/**
* @description Utility Class for Sending Email to Agents
* @author Richard Cook
**/
public without sharing class OffersEmailService {
    
    private static boolean hasRun = false;

    /**
    * @description Data structure to contain required fields to invoke email from process
    **/    
    public class OffersEmailRequest
    {
        @InvocableVariable(required=true)
        public ID recordId;
        
        @InvocableVariable(label='Email Template Developer Name' required=true)
        public String emailDeveloperName;
        
        @InvocableVariable(label='Organisation Wide Email Display Name' required=true)
        public String oweDisplayName;
        
        @InvocableVariable(required=true label='Scenario key' description='Set this field with an unique value to allow the method to be called multiple names in the same transaction')
        public string scenarioKey;
        
        @InvocableVariable
        public Id contentVersionId;
        
        @InvocableVariable(label='Email address to send to' description='Either enter Sent to Adress or Send to Id')
        public string sendToAddress;
        
        @InvocableVariable(label='Contact Id address to send to' description='Either enter Sent to Adress or Contact Id to Id')
        public string sendToId;        
    }
    
    private static void ToggleRun()
    {
        hasRun = ! hasRun;
    }

    /**
    * @description Data structure to contain required fields to invoke email from process
    * @param requests OffersEmailService.OffersEmailRequest data structure representing the emails to send
    * @return void
    **/    
    @InvocableMethod(label='Email Offer')
    public static void emailOffer(List<OffersEmailService.OffersEmailRequest> requests) 
    {
        if(!hasRun )
        {
            ToggleRun();
        } else {
            return;
        }
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        for (OffersEmailService.OffersEmailRequest request : requests) {
            
            Boolean validSendTo = !string.isBlank ( request.sendToAddress) || !string.isBlank ( request.sendToId);
            if( validSendTo)
            {
                mailList.add(constructEmailMessage(request));
            }
            
        }
        
            Messaging.reserveSingleEmailCapacity(mailList.size());
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mailList, false);
            String errorString = '';
            for(Messaging.SendEmailResult ser : results) {
                if(! ser.isSuccess())
                {
                    errorString += ser.getErrors()[0].getMessage();
                    errorString += ser.getErrors()[0].getTargetObjectId();
                    
                }
            }
            if(!string.isBlank(errorString))
            {
                throw new LogUtilityException(errorString);
            }
        return ;
    }
    
    @testVisible
    /**
    * @description Convert  OffersEmailService.OffersEmailRequest to Messaging.SingleEmailMessage
    * @param requests OffersEmailService.OffersEmailRequest incoming data
    * @return Messaging.SingleEmailMessage
    **/     
    private static Messaging.SingleEmailMessage constructEmailMessage(OffersEmailService.OffersEmailRequest oaer)
    {
        try {                   
            List<EmailTemplate> templateList = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE IsActive = true 
                                                AND DeveloperName =: oaer.emailDeveloperName LIMIT 1];
            if (!templateList.isEmpty()) {
                EmailTemplate emailTemplate = templateList[0]; 
                Messaging.SingleEmailMessage mail = null;
                if(string.isBlank(oaer.sendToId))
                {
                    mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, null, oaer.recordId);
                    mail.setToAddresses(new String[]{oaer.sendToAddress});
                } else {
                    mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(oaer.sendToId);
                    mail.setTemplateId(emailTemplate.Id);
                    mail.setWhatId(oaer.recordId);
                }
                
                List<OrgWideEmailAddress> owa = [select Id, Address, DisplayName from OrgWideEmailAddress WHERE DisplayName = :oaer.oweDisplayName limit 1];
                if (!owa.isEmpty()) {
                    mail.setOrgWideEmailAddressId(owa[0].Id);
                }
                if(! string.isBlank(oaer.contentVersionId))
                {
                    mail.setEntityAttachments(new String[]{String.valueOf(oaer.contentVersionId)});
                } 
                
                mail.saveAsActivity = true;
                return mail;
                
            }                    
        } catch (Exception ex) {
            throw new LogUtilityException(ex);
        }
        return null;
    }
    
    

}