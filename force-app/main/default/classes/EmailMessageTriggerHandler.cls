/**
* @author          Kristian Vegerano
* @description     Trigger Handler for EmailMessage object.This is part of code refactor to fix too many SOQL error.
*                  To mitigate amount of effort to required, Trigger handler criteria will not be implemented for now,
*                  and will be part of future code optimization.
* @revision        07/11/2018 - added saveHtmlDescription
*                  04/04/2018 - added executeEmailMessageRedirectionRule
*                  11/04/2020 - PV Added Reassign to Loands And Grants on Reply
* @revision       Shalini Mendu - RW2-146-Low Engagement Enquiry details
* @revision        26/03/2021 Inderpal Dhanoa - ENGAGEIE-742-Enterprise Backbone - New email received indicator
* @revision        27/07/2022 - Sagar Johri added the method getCaseId [JIRA : EPCP-2155]
* @revision        27/07/2022 - Sagar Johri updated the trigger framework [JIRA : EPCP-2155]
* @revision        16/04/2024 - Jitender Padda: update redirection logic to be more scalable
*                                               added logic for Faculty field
*/
public class EmailMessageTriggerHandler{


    @TestVisible

    public class handleBeforeInsert extends TriggerAbstract {
        
        private List<EmailMessage> replyEmailList = new List<EmailMessage>();

        public override void process(SObject record) {
            
            EmailMessage em = (EmailMessage)record;
	
             // SA-863 Link Course Mapper Link, if available.
            if(!em.Incoming){
                courseMapperLinkMatcher(em);
            }

            EmailMessageTriggerHandler.assignEmailToLatestEnquiry(em);
            em.Original_Enquiry_Id__c = em.ParentId;
            
            if(em.Incoming) {
                //Check if email message contains an Email Token or Header Ids
                if((em.TextBody != null && EmailMessageUtility.hasEmailTokens(em.textBody)) || EmailMessageUtility.hasHeaderIds(em)) {
                    replyEmailList.add(em);
                }
            }
        }

        public override void execute() {
            try {
                if(replyEmailList.size() > 0) {
                    Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
                    if(environmentSettings.Reopen_Enquiry_Rule_Active__c) {
                       	//Run transfer enquiry rules, reopen case or create an enquiry clone and assign the email message
                       	EmailMessageTriggerHandler.executeEnquiryReopenRules(replyEmailList);
                    }
                    //Run email redirection rule
                    EmailMessageTriggerHandler.executeEmailMessageRedirectionRule(replyEmailList);
                }
            }
            catch(Exception e) {
                LogUtilityException.logException(e);
            }
        }
    }
    
    public class handleAfterInsert extends TriggerAbstract {
        
        private List<EmailMessage> listEmailMessage = new List<EmailMessage>();
        private List<EmailMessage> listEM_AddressToEmail = new List<EmailMessage>();
        
        public override void process(SObject record) {
            EmailMessage em = (EmailMessage)record;
            listEmailMessage.add(em);
            if(em.ToAddress != null && em.ParentId != null) {
                listEM_AddressToEmail.add(em);
            }
        }
        
        public override void execute() {
            try{
                if(listEM_AddressToEmail.size() > 0){
                    EmailMessageServices.mapEmailToAddressToCases(listEM_AddressToEmail);
                }
                EmailMessageTriggerHandler.alignReopenedEnquiryOrigin(listEmailMessage);
                
                EmailMessageTriggerHandler.onInsertEMailMessageUpdateRelatedCaseDetails(listEmailMessage);
                
                EmailMessageTriggerHandler.saveHtmlDescription(listEmailMessage);
            }
            catch (Exception err) {
                LogUtilityException.logException(err);
            }

        }
    }
    
    /**
    * @author                      Sagar Johri
    * @description                 Fetch the case ID from email using the header on the mail (EPCP-1292)
    * @param newEmailMessageList   Email Message for which case id is to be fetched
    */
    public static Id getCaseId(EmailMessage eMessage) {
        
        Id caseId = null;
        String messageHeaderName = '';
        String messageHeadervalue = '';
        String referencesHeaderName = '';
        String referencesHeaderValue = '';
        String inReplyToHeaderName = '';
        String inReplyToHeaderValue = '';
        if (String.isNotBlank(eMessage.Headers)) {
            List<String> headerList = eMessage.Headers.split('\n');
            system.debug('Header'+eMessage.Headers);
            for (String header : headerList) {
                if (header.contains('Message-ID:')) {
                    List<String> messageNameValue = header.split(':');
                    messageHeaderName = messageNameValue[0];
                    messageHeadervalue = messageNameValue[1];
                }
                if (header.contains('References:')) {
                    List<String> referencesNameValue = header.split(':');
                    referencesHeaderName = referencesNameValue[0];
                    referencesHeaderValue = referencesNameValue[1];
                }
                if (header.contains('In-Reply-To:')) {
                    List<String> inReplyToNameValue = header.split(':');
                    inReplyToHeaderName = inReplyToNameValue[0];
                    inReplyToHeadervalue = inReplyToNameValue[1];
                }
            }
        }

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header messageHeader = new Messaging.InboundEmail.Header();
        messageHeader.Name = messageHeaderName.trim();
        messageHeader.value = messageHeadervalue.trim();
        headers.add(messageHeader);
        
        Messaging.InboundEmail.Header referencesHeader = new Messaging.InboundEmail.Header();
        referencesHeader.Name = referencesHeaderName.trim();
        referencesHeader.value = referencesHeaderValue.trim();
        headers.add(referencesHeader);
        
        Messaging.InboundEmail.Header inReplyToHeader = new Messaging.InboundEmail.Header();
        inReplyToHeader.Name = inReplyToHeaderName.trim();
        inReplyToHeader.value = inReplyToHeaderValue.trim(); 
        headers.add(inReplyToHeader);
        
        try {
            caseId = Cases.getCaseIdFromEmailHeaders(headers);
        } 
        catch(Exception err) {
            LogUtilityException.logException(err);
        }
        return caseId;
    }

    /**
    * @author                      Inderpal Dhanoa
    * @description                 Method that updates the related Case Status 
    * @param newEmailMessageList   List of Email Messages on the trigger batch
    */
    public static void onInsertEMailMessageUpdateRelatedCaseDetails(List<EmailMessage> newEmailMessageList) {
        try{
            //Filter new emails to reply emails
            List<EmailMessage> newEmailList = new List<EmailMessage>();
            Set<Id> s_relatedCaseIds = new Set<Id>();
            for(EmailMessage loopEmailMessage : newEmailMessageList) {
                if(loopEmailMessage.RelatedToId != null && loopEmailMessage.Status == '0'){  
                    //Check if email message is related to a Case
                    Id relatedToId = loopEmailMessage.RelatedToId;
                    if(relatedToId.getSobjectType() == Case.SObjectType) {
                        s_relatedCaseIds.add(loopEmailMessage.RelatedToId);
                    }
                }
            }
            if(!s_relatedCaseIds.isEmpty()){
                List<Case> l_relatedCases = [SELECT Id, Status FROM Case WHERE Id in :s_relatedCaseIds AND RecordType.DeveloperName = 'Enterprise'];
                if(!l_relatedCases.isEmpty()){
                    for(Case loopCase : l_relatedCases){
                        // New EMail is tagged to an Open Case then "New Email received" indicator should be set.
                        if(loopCase.Status == 'Closed'){
                            loopCase.Status = 'Reopened';
                        }
                    }
                    update l_relatedCases;
                } 
            }
        }catch(Exception e) {
            LogUtilityException.logException(e);
        }
    }
    
    /**
    * @author                      Kristian Vegerano
    * @description                 Method that saves the html body of the email message to the parent enquiry
    * @param newEmailMessageList   List of Email Messages on the trigger batch
    */
    public static void saveHtmlDescription(List<EmailMessage> newEmailMessageList) {
        if(newEmailMessageList != null && !newEmailMessageList.isEmpty()){
            //Filter new emails to reply emails
            List<EmailMessage> newEmailList = new List<EmailMessage>();

            //Filter for DOI & AP enquiries
            List<String> recordTypeExcludeList = new List<String>{'Declaration_of_Interest','Academic_Progress_Assessment'}; 
            
            //Get parentIds of the emailmessage
            Set<Id> parentIds = new Set<Id>();
            for(EmailMessage em : newEmailMessageList) {
                if(em.ParentId != null) {
                    parentIds.add(em.ParentId);
                }
            }

            //Retrieve parent case details
            Map<Id, Case> parentCaseMap = new Map<Id, Case>();
            for(Case loopCase : [SELECT Id, Recordtype.DeveloperName FROM Case WHERE Id IN :parentIds AND RecordType.DeveloperName IN :recordTypeExcludeList]) {
                parentCaseMap.put(loopCase.Id, loopCase);
            }

            for(EmailMessage loopEmailMessage : newEmailMessageList) {
                if(loopEmailMessage.Incoming) {
                    //Check if email message contains a thread id and is not an excluded Record Type
                    if(!EmailMessageUtility.hasEmailTokens(loopEmailMessage.textBody) && !EmailMessageUtility.hasHeaderIds(loopEmailMessage) 
                    && (!parentCaseMap.containsKey(loopEmailMessage.ParentId))) {
                        newEmailList.add(loopEmailMessage);
                    }
                }
            }

            if(newEmailList.size() > 0) {
                //Save html body of the email message to the html description of the enquiry
                EmailMessageServices.saveHtmlDescription(newEmailList);
            }
        }
    }

       /**
    * @author                      Kristian Vegerano
    * @description                 Ensures that the emailmessage is attached to the latest enquiry
    * @param newEmailMessageList   List of Email Messages on the trigger batch
    */
    public static void assignEmailToLatestEnquiry(EmailMessage newEmailMessage) {
        String returnedId;
        Boolean foundThreadId = false;
        //Determine which emails to be mapped to cases
        try {
            // Primary method - Thread via Email Tokens
            if(EmailMessageUtility.hasEmailTokens(newEmailMessage.textBody)){
                returnedId = EmailMessages.getRecordIdFromEmail(newEmailMessage.Subject, newEmailMessage.TextBody, newEmailMessage.HTMLBody);
                foundThreadId = true;
            }
            // Secondary method - Thread via Header Ids
            else if(EmailMessageUtility.hasHeaderIds(newEmailMessage)){
                returnedId = EmailMessageTriggerHandler.getCaseId(newEmailMessage);
                foundThreadId = true;
            }

            if(foundThreadId){
                // Check for linked enquiry
                Case parentCase;
                if(String.isNotBlank(newEmailMessage.ParentId)){
                    parentCase = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id =: newEmailMessage.ParentId];
                }
                
                // Allow null assignment for Post-App and Pre-App enquiries to prevent duplication due to their enquiry re-open config 
                if(parentCase != null && (parentCase.RecordType.DeveloperName == 'Post_Application_Enquiry' || parentCase.RecordType.DeveloperName == 'SR_Enquiry')){
                    newEmailMessage.ParentId = returnedId;
                }

                // Otherwise, only allow non-null parent id assignments
                else if(String.isNotBlank(returnedId)){
                    newEmailMessage.ParentId = returnedId;
                }
            }
            
        }
        catch(Exception ex) {
            //Ignore errors related to non-existing email threads because of environment refresh
            System.debug('!!@@##: '+ex.getMessage());
			LogUtilityException.logException(ex);
        }
    }

     /**
    * @author                      Kristian Vegerano
    * @description                 When an inbound email is received, determine if there is a transfer rule related to the parent enquiry and process enquiry
    * @param newEmailMessageList   List of Email Messages on the trigger batch
    */
    public static void executeEnquiryReopenRules(List<EmailMessage> newEmailMessageList) {
        try {
            //Initialize Variables
            List<EmailMessage> processEmailMessagesList = new List<EmailMessage>();

            //Determine which emails to be mapped to cases
            for(EmailMessage loopEmailMessage : newEmailMessageList) {
                if((loopEmailMessage.Incoming == true || Test.isRunningTest()) && loopEmailMessage.ParentId != null) {
                    processEmailMessagesList.add(loopEmailMessage);
                }
            }

            //Update Cases when there are EmailMessage records needs to get processed
            if(processEmailMessagesList.size() > 0) {
                EmailMessageServices.executeEnquiryReopenRules(processEmailMessagesList);
            }
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'EmailMessageTriggerHandler.executeEnquiryReopenRules: ' + e.getMessage() + '\n' + e.getStackTraceString()
            );
            LogUtilityException.logException(e);
        }
    }

    /**
    * @author                      Kristian Vegerano
    * @description                 When an inbound email is received with multiple system address on to and cc address, align the created enquiries based on the system address
    * @param newEmailMessageList   List of Email Messages on the trigger batch
    */
    public static void alignReopenedEnquiryOrigin(List<EmailMessage> newEmailMessageList) {
        //For Loans and grants to reassign to Queue
        Map<Id, Case> loansGrantCasesReAssign = new Map<Id, Case>();
        try {
            //Moved here from handleAfterInsert to reuse existing logic for Loans and Grants
            Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
            //Initialize Variables
            List<EmailMessage> processEmailMessagesList = new List<EmailMessage>();
            Map<String, Set<String>> emailRecipientsMap = new Map<String, Set<String>>();

            //Get parentIds of the emailmessage
            Set<Id> parentIds = new Set<Id>();
            for(EmailMessage loopEmailMessage : newEmailMessageList) {
                if(loopEmailMessage.ParentId != null) {
                    parentIds.add(loopEmailMessage.ParentId);
                }
            }

            //Retrieve parent case details
            Map<Id, Case> parentEnquiryMap = new Map<Id, Case>();
            for(Case loopCase : [SELECT Id, ParentId, Origin, Category_Level_1__c, Subject, Recordtype.DeveloperName, Owner.Name
            FROM Case WHERE Id IN :parentIds]) {
                parentEnquiryMap.put(loopCase.Id, loopCase);
            }

            //Retrieve Email to Case - Origin Mapping
            Map<String, EmailToCaseMapping__mdt> emailToCaseAddressMap = new Map<String, EmailToCaseMapping__mdt>();
            if(environmentSettings.Reopen_Enquiry_Rule_Active__c) {
                for(EmailToCaseMapping__mdt loopEmailToCaseAddressMapping :
                [SELECT Id, MasterLabel, DeveloperName, Active__c, Case_Origin__c, Email_Address__c, Enquiry_Record_Type__c
                FROM EmailToCaseMapping__mdt
                WHERE Active__c = true]) {
                    emailToCaseAddressMap.put(loopEmailToCaseAddressMapping.Email_Address__c, loopEmailToCaseAddressMapping);
                }
            }

            //Determine which emails to be mapped to cases
            for(EmailMessage loopEmailMessage : newEmailMessageList) {
                //Reopen Enquiry Rule Logic
                if(environmentSettings.Reopen_Enquiry_Rule_Active__c) {
                    if((loopEmailMessage.Incoming == true || Test.isRunningTest()) && loopEmailMessage.ParentId != null) {
                        //Compile to and cc emails
                        if(!emailRecipientsMap.containsKey(loopEmailMessage.Subject + ':::' + loopEmailMessage.FromAddress)) {
                            emailRecipientsMap.put(loopEmailMessage.Subject + ':::' + loopEmailMessage.FromAddress, new Set<String>());
                        }

                        //Add all ToAddress
                        if(loopEmailMessage.ToAddress != null) {
                            for(String address : loopEmailMessage.ToAddress.split(';')) {
                                if(emailToCaseAddressMap.containsKey(address.trim().remove('f.e.'))) {
                                    emailRecipientsMap.get(loopEmailMessage.Subject + ':::' + loopEmailMessage.FromAddress).add(address.trim().remove('f.e.'));
                                }
                            }
                        }
                        //Add all CCAddress
                        if(loopEmailMessage.CcAddress != null) {
                            for(String address : loopEmailMessage.CcAddress.split(';')) {
                                if(emailToCaseAddressMap.containsKey(address.trim().remove('f.e.'))) {
                                    emailRecipientsMap.get(loopEmailMessage.Subject + ':::' + loopEmailMessage.FromAddress).add(address.trim().remove('f.e.'));
                                }
                            }
                        }

                        //Define if the emailmessage should be processed synchronously or asynchronously
                        if(parentEnquiryMap.containsKey(loopEmailMessage.ParentId)) {
                            if(parentEnquiryMap.get(loopEmailMessage.ParentId).ParentId != null) {
                                processEmailMessagesList.add(loopEmailMessage);
                            }
                        }
                    }
                }
            }

            //Process emails with single/multiple system address on TO and CC asynchronously
            if(processEmailMessagesList.size() > 0){
                EmailMessageServices.CorrectReopenedEnquiryAssignment correctReopenQueue
                    = new EmailMessageServices.CorrectReopenedEnquiryAssignment(processEmailMessagesList,
                    emailToCaseAddressMap,
                    emailRecipientsMap,
                    loansGrantCasesReAssign);
                ID jobID = System.enqueueJob(correctReopenQueue);
            }

        } catch(Exception err) {
            LogUtilityException.logException(err);
        }
    }

   /**
    * @author                      Kristian Vegerano
    * @description                 When an inbound email is received by a different email to case address from the parent enquiry's record type
    * @param newEmailMessageList   List of Email Messages on the trigger batch
    */
    public static void executeEmailMessageRedirectionRule(List<EmailMessage> newEmailMessageList) {
        try {
            //Initialize Variables
            List<EmailMessage> processedEmailMessageList = new List<EmailMessage>();

            // Email routing address map
            Map<Id, EmailRoutingAddress> emailRoutingAddressMap = EmailMessageUtility.getEmailRoutingAddressMap(newEmailMessageList);

            //Target Email to Redirection rule Map
            Map<String, Redirection_Enquiry_Rule__mdt> targetEmailToRedirectionRuleMap = EmailMessageUtility.getTargetEmailToRedirectionRuleMap();

            //Map of parent enquiry Id and matching rules
            Map<Id, List<Redirection_Enquiry_Rule__mdt>> redirectedEmailMessagesMap = new Map<Id, List<Redirection_Enquiry_Rule__mdt>>();
            
            //Retrieve map of parent enquiries
            Map<Id, Case> parentEnquiriesMap = EmailMessageUtility.retrieveParentEnquiriesMap(newEmailMessageList);

            for(EmailMessage loopMessage : newEmailMessageList) {

                //Check if incoming email
                if(loopMessage.Incoming && loopMessage.ParentId != null) {
                    Boolean hasMatched = false;
                    
                    // get Email Routing address to which this email was sent to
                    String matchEmail = emailRoutingAddressMap.get(loopMessage.EmailRoutingAddressId).Address;
                    matchEmail = EmailMessageUtility.cleanRoleAccountEmail(matchEmail);

                    // get rule based on the Email Routing address
                    Redirection_Enquiry_Rule__mdt redirectionRule = targetEmailToRedirectionRuleMap.get(matchEmail);
                    if(redirectionRule == null){
                        continue;
                    }

                    //Optional: Skip if the record type of the email message's parent enquiry does not match to the intended rule's From Enquiry Record Type
                    if(redirectionRule.From_Enquiry_Record_Type__c != null){
                        if(parentEnquiriesMap.get(loopMessage.ParentId).RecordType.DeveloperName != redirectionRule.From_Enquiry_Record_Type__c) {
                            continue;
                        }
                    }

                    //Skip if the parent case is already the target enquiry record type
                    if(parentEnquiriesMap.get(loopMessage.ParentId).RecordType.DeveloperName == redirectionRule.Target_Enquiry_Record_Type__c) {  

                        //Optional: Skip if Enquiry Redirection Key matches. 
                        if(redirectionRule.Enquiry_Redirection_Key__c != null){
                            if(parentEnquiriesMap.get(loopMessage.ParentId).Redirection_Key__c == redirectionRule.Enquiry_Redirection_Key__c) {
                                continue;
                            }
                            // create Enquiry as a mismatch indicates that the enquiry belongs to a different team within that record type.
                        }  
                        else continue;
                    }
                                
                    //Map check - parent enquiry of the email message does/still exist
                    if(parentEnquiriesMap.containsKey(loopMessage.ParentId)) {
                        //Check if it contains valid Email Token or Header Id
                        if(EmailMessages.getRecordIdFromEmail(loopMessage.Subject, loopMessage.TextBody, loopMessage.HTMLBody) == null && EmailMessageTriggerHandler.getCaseId(loopMessage) == null){
                            //Don't apply logic to new enquiries
                            continue;  
                        }
                        hasMatched = true;

                        //Add emailmessage to matching redirection rule
                        if(!redirectedEmailMessagesMap.containsKey(loopMessage.ParentId)) {
                            redirectedEmailMessagesMap.put(loopMessage.ParentId, new List<Redirection_Enquiry_Rule__mdt>());
                        }
                        redirectedEmailMessagesMap.get(loopMessage.ParentId).add(redirectionRule);
                    }

                    //Add matched emails
                    if(hasMatched) {
                        //Add email message to be processed later on
                        processedEmailMessageList.add(loopMessage);
                    }
                }
            }

            //Run email message redirection process
            if(processedEmailMessageList.size() > 0) {
                EmailMessageServices.executeEmailMessageRedirectionRule(processedEmailMessageList, redirectedEmailMessagesMap);
            }
        } catch (Exception err) {
            LogUtilityException.logException(err);
        }
    }
    
    /*
     * @author			Ayush Agrawal
     * @description		SA-863 Link course mapper link from outgoing email, if available.
     */
    public static void courseMapperLinkMatcher(EmailMessage em) {
        try {
            // Firebase Auto IDs are always 20 characters in length. And since, a regex isn't panning out due to
            // Salesforce governor limits, this is the best way forward.
            final Integer FIREBASE_AUTO_ID_LENGTH = 20;
            final Integer COURSE_MAPPER_LINK_LENGTH = Label.Course_Mapper_Link_Base.length() + FIREBASE_AUTO_ID_LENGTH;
            
            Integer startIndex = em.HtmlBody.indexOf(Label.Course_Mapper_Link_Base);                
            Integer endIndex = startIndex + COURSE_MAPPER_LINK_LENGTH;
        
            if(startIndex != -1 && em.HtmlBody.length() >= endIndex){
                em.Course_Mapper_Link__c = em.HtmlBody.substring(startIndex, endIndex);
            }
            
        } catch (Exception err) {
            LogUtilityException.logException(err);
        }
    }
    
}