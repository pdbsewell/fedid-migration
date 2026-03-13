/**
 * @author          Kristian Vegerano
 * @description     Apex class to hold all Email Message reusable codes
 * @history         05/04/2019 - created - added
 *                  05/04/2019 - added patternMatcher
 *                  05/04/2019 - added emailThreadIdPattern
 *                  05/04/2019 - added retrieveEnquiryFromLastThreadId
 *                  05/04/2019 - added clearThreadIds
 *                  05/04/2019 - added emailRedirectionRulesList
 *                  05/04/2019 - added emailRedirectionQueueMap
 *                  05/04/2019 - added emailRedirectionRecordTypeMap
 *                  05/04/2019 - added retrieveParentEnquiriesMap
 *                  05/04/2019 - added getThreadId
 *                  27/07/2022 - added hasHeaderIds
 *                  27/07/2022 - added clearHeaderIds
 *                  27/07/2022 - removed patternMatcher
 *                  27/07/2022 - removed emailThreadIdPattern
 *                  27/07/2022 - removed retrieveEnquiryFromLastThreadId
 *                  27/07/2022 - removed clearThreadIds
 *                  03/05/2023 - added Lightning Threading methods
 *                  16/04/2024 - added getTargetEmailToRedirectionRuleMap, getEmailRoutingAddressMap, 
 *                                     cleanRoleAccountEmail
 */
public class EmailMessageUtility {
    private static Matcher patternMatcher;
    private static Pattern emailTokenId = Pattern.compile('(?<=thread::)(.{23})(?=::)'); 
    public static Map<Id, EmailRoutingAddress> testEmailRoutingAddressMap; // used for test class only

    //Retrieve enquiry redirection rules
    public static List<Redirection_Enquiry_Rule__mdt> emailRedirectionRulesList {
        get{
            if(emailRedirectionRulesList == null){
                emailRedirectionRulesList = [SELECT Id, MasterLabel, DeveloperName, Active__c, Clear_Related_Contact__c, Redirected_Origin__c, 
                                                    Redirected_Queue__c, Redirected_Status__c, Redirected_Enquiry_Type__c, Redirected_Group__c, Redirected_Priority__c, Redirected_Student_Type__c, From_Enquiry_Record_Type__c,
                                                    Target_Email_Address__c, Target_Enquiry_Record_Type__c, Target_Faculty__c, Use_Assignment_Rules__c, Mark_original_as_parent__c, Internal_Comment_to_clone__c, Internal_Comment_to_original__c,
                                                    Enquiry_Redirection_Key__c
                                             FROM Redirection_Enquiry_Rule__mdt
                                             WHERE Active__c = true];
            }
            return emailRedirectionRulesList;
        }
        set;
    }
    
    /*
     * @author          Jitender Padda
     * @description     fetches a map of enquiry redirection rules based on Target Email Address
     */

    public static Map<String, Redirection_Enquiry_Rule__mdt> getTargetEmailToRedirectionRuleMap(){
        Map<String, Redirection_Enquiry_Rule__mdt> targetEmailToRedirectionRuleMap = new Map<String, Redirection_Enquiry_Rule__mdt>();

        for(Redirection_Enquiry_Rule__mdt redirectionRule : EmailMessageUtility.emailRedirectionRulesList){
            targetEmailToRedirectionRuleMap.put(redirectionRule.Target_Email_Address__c, redirectionRule);
        }

        return targetEmailToRedirectionRuleMap;
    }
    
    //Retrieve recordtypes for email redirection rules
    public static Map<String, RecordType> retrieveEmailRedirectionRecordTypeMap(List<Redirection_Enquiry_Rule__mdt> redirectionRulesList) {
       //Initialize variables
        Set<String> recordTypeSet = new Set<String>();
        for(Redirection_Enquiry_Rule__mdt loopRedirectionRule : redirectionRulesList){
            //Store record type developer name
            recordTypeSet.add(loopRedirectionRule.Target_Enquiry_Record_Type__c);
        }
        
        Map<String, RecordType> emailRedirectionRecordTypeMap = new Map<String, RecordType>();
        for(RecordType loopRecordType : [SELECT Id, DeveloperName 
                                         FROM RecordType
                                         WHERE DeveloperName IN :recordTypeSet
                                            AND SobjectType = 'Case']){
            emailRedirectionRecordTypeMap.put(loopRecordType.DeveloperName, loopRecordType);
        }
        
        return emailRedirectionRecordTypeMap;
    }
    
    //Retrieve queues for email redirection rules
    public static Map<String, Group> retrieveEmailRedirectionQueueMap(List<Redirection_Enquiry_Rule__mdt> redirectionRulesList) {
        //Initialize variables
        Set<String> groupDeveloperNameSet = new Set<String>();
        for(Redirection_Enquiry_Rule__mdt loopRedirectionRule : redirectionRulesList){
            //Store queue developer name
            groupDeveloperNameSet.add(loopRedirectionRule.Redirected_Queue__c);
        }
        
        Map<String, Group> emailRedirectionQueueMap = new Map<String, Group>();
        for(Group loopGroup : [SELECT Id, DeveloperName, Name
                               FROM Group
                               WHERE DeveloperName IN :groupDeveloperNameSet
                                    AND Type = 'Queue']){
            emailRedirectionQueueMap.put(loopGroup.DeveloperName, loopGroup);
        }
        
        return emailRedirectionQueueMap;
    }
    
    //Retrieve parent enquiries of email messages
    public static Map<Id, Case> retrieveParentEnquiriesMap(List<EmailMessage> newEmailMessageList) {
        //Initialize Variables
        Set<Id> parentEnquiryIds = new Set<Id>();
        for(EmailMessage loopEmailMessage : newEmailMessageList){  
            if(loopEmailMessage.ParentId != null){
                parentEnquiryIds.add(loopEmailMessage.ParentId);
            }
        }
        
        //Retrieve map of parent enquiries
        Map<Id, Case> parentEnquiriesMap = new Map<Id, Case>([SELECT Id, CaseNumber, AccountId, ContactId, RecordType.DeveloperName, RecordType.Name, CreatedDate,
                                                                    Faculty__c, Redirection_Key__c
                                                              FROM Case 
                                                              WHERE Id IN :parentEnquiryIds]);
        
        return parentEnquiriesMap;
    }
    
    //Retrieve enquiry reference id from enquiry id
    public static String getThreadId(String caseId){
        return 'ref:_'
                + UserInfo.getOrganizationId().left(5)
                + UserInfo.getOrganizationId().mid(10,5) + '._'
                + caseId.left(5)
                + caseId.mid(9,6) + ':ref';
    }
    
    //Returns a list of email messages cloned from the original email message going to the newly generated enquiries
    public static List<EmailMessage> cloneEmailsToEnquiries(List<EmailMessage> processedEmailMessageList, Map<Id, List<Case>> redirectedEnquiryMap, List<String> successCaseInserts){
        List<EmailMessage> updateEmailMessagesList = new List<EmailMessage>();
        Boolean isFromInternal = false;
        
        //Loop through each emailmessage and clone it for each redirected enquiries
        for(EmailMessage loopEmailMessage : processedEmailMessageList){
            if(redirectedEnquiryMap.containsKey(loopEmailMessage.ParentId)){
                
                Integer redirectCounter = 0;
                //Determine if the email is sent internally
                isFromInternal = loopEmailMessage.FromAddress.contains('f.e.');
                
                //Loop through each redireacted enquiries
                for(Case loopCase : redirectedEnquiryMap.get(loopEmailMessage.ParentId)){
                    // Only clone for successfully redirected cases
                    if(successCaseInserts.contains(loopCase.id)){
                        //Clone the email message
                        EmailMessage redirectedEmail;
                        
                        //Initialize email - whether to clone email or redirect the original - based off from email's from address if it contains f.e.
                        if(redirectCounter == 0 && isFromInternal){
                            redirectedEmail = loopEmailMessage;
                        }else{
                            redirectedEmail = loopEmailMessage.clone(false, true, true, false);
                        }
                                        
                        //Clear Email Tokens & Header Ids
                        if(redirectedEmail.TextBody != null){
                            redirectedEmail.TextBody = EmailMessageUtility.clearEmailTokens(redirectedEmail.textBody);
                        }
                        if(redirectedEmail.HTMLBody != null){
                            redirectedEmail.HTMLBody = EmailMessageUtility.clearEmailTokens(redirectedEmail.HTMLBody);
                        }
                        if(redirectedEmail.Headers != null){
                            redirectedEmail.Headers = EmailMessageUtility.clearHeaderIds(redirectedEmail);
                        }

                        //Link the new enquiry to the new
                        redirectedEmail.ParentId = loopCase.Id;
                        
                        //Do not add to the list if redirecting the original email message
                        if(!(redirectCounter == 0 && isFromInternal)){
                            //Add new email message to the list to be returned
                            updateEmailMessagesList.add(redirectedEmail);
                        }

                    }   
                    redirectCounter++;
                }
            }
        }
        
        //Return the list of newly created email messages for each redirected enquiries
        return updateEmailMessagesList;
    }
    
     /*
     * @author          Matthew Maramot
     * @description     Reads the header of an email message and checks for In-Reply-To & References field (used from email-to-case)
     * @param           eMessage - EmailMessage object representing an email within Salesforce
     * @return          outputs whether the References or In-Reply-To fields exist within the input header
     */
    public static Boolean hasHeaderIds(EmailMessage eMessage){
        Boolean hasHeaderId = false;
        
        //Check if the Email Message header contains In-Reply-To & References field
        String header = eMessage.Headers;
        if (String.isNotBlank(header)) {
            if (header.contains('References:') || header.contains('In-Reply-To:')) {
					hasHeaderId = true;
                }
        }
        
        //Return results
        return hasHeaderId;
    }

     /*
     * @author          Kristian Vegerano (modified by Matthew Maramot)
     * @description     Returns true or false whether an Email has a token
     * @param           textBody - text we are parsing to find Email Token
     */
    public static Boolean hasEmailTokens(String textBody){
        Boolean hasEmailToken = false;
        if(String.isNotBlank(textBody)){
            Matcher patternMatcher = emailTokenId.matcher(textBody); 
        
            //Check if the newBody matches the thread id pattern
            while (patternMatcher.find()) {
                hasEmailToken = true;
                break;
            }
        }
       
        //Return results
        return hasEmailToken;
    }
    
    /*
     * @author          Matthew Maramot
     * @description     Removes the In-Reply-To & References field (used from email-to-case) from the header of an email
     * @param           eMessage - EmailMessage object representing an email within Salesforce
     * @return          outputs an email header with the In-Reply-To & References field stripped
     */
    public static String clearHeaderIds(EmailMessage eMessage){    
        List<String> header = eMessage.Headers.split('\n');
        List<String> strippedHeader = new List<String>();

        // Skip In-Reply-To and References headers
        for(String s : header){
            if(!(s.contains('In-Reply-To:') || s.contains('References:')))    {
                strippedHeader.add(s);
            }
        }

        // Join result
        String finalHeader = String.join(strippedHeader, '\n');
        return finalHeader;
    }

    /*
     * @author          Kristian Vegerano (modified by Matthew Maramot)
     * @description     Removes Email Tokens from a body of text
     * @param           textBody - text to remove Email Tokens from
     */
    public static String clearEmailTokens(String newBody){    
        Matcher patternMatcher = emailTokenId.matcher(newBody); 
        
        List<String> emailTokenList = new List<String>();
        while (patternMatcher.find()) { 
            //Add the match to the set
            emailTokenList.add(patternMatcher.group());
        }
        
        //Remove the thread id from the text
        if(emailTokenList.size() > 0){
            for(String emailToken : emailTokenList){
                newBody = newBody.remove('thread::' + emailToken + '::');
            }
        }

        //Return text with cleared thread id
        return newBody;
    }

    /*
     * @author          Matthew Maramot
     * @description     Creates a custom Id based on EmailMessage message identifier
     * @param           eMessage - EmailMessage object representing an email within Salesforce
     */
    public static String getRedirectionId(EmailMessage eMessage){  
        String messageId = eMessage.MessageIdentifier;
        // Return final 100 chars of messageId, if less, return entire messageId
        if(messageId.length()>100){
            return messageId.substring(messageId.length()-100, messageId.length());
        }
        else{
            return messageId;
        }
    } 

    /*
     * @author          Jitender Padda
     * @description     fetches a map of Email Routing Addresses for the incoming email messages
     * @param           newEmailMessageList - EmailMessage object representing an email within Salesforce
     */
    public static Map<Id, EmailRoutingAddress> getEmailRoutingAddressMap(List<EmailMessage> newEmailMessageList){
        if(System.Test.isRunningTest()){
            return testEmailRoutingAddressMap;
        }

        Map<Id, EmailRoutingAddress> emailRoutingAddressMap = new Map<Id, EmailRoutingAddress>();

        for(EmailMessage loopMessage : newEmailMessageList) {
            emailRoutingAddressMap.put(loopMessage.EmailRoutingAddressId, null);
        }

        emailRoutingAddressMap = new Map<Id, EmailRoutingAddress>(
                                                        [SELECT Address 
                                                            FROM EmailRoutingAddress 
                                                            WHERE Id IN : emailRoutingAddressMap.keySet()
                                                        ]);

        return emailRoutingAddressMap;
    }

    /*
     * @author          Jitender Padda
     * @description     cleans role account email addresses for test/idmqat role accounts and removes domain
     * @param           roleAccountEmail - represents a Role account email address
     */
    public static String cleanRoleAccountEmail(String roleAccountEmail){
         // idmqat role accounts
         roleAccountEmail = roleAccountEmail.removeStart('c-');

        // sandbox test role accounts
        if(roleAccountEmail.contains('+')){
            roleAccountEmail = roleAccountEmail.split('\\+')[1]; 
        }

        // remove domain
        roleAccountEmail = roleAccountEmail.split('@')[0] + '@';

        return roleAccountEmail;
    }

    /*
     * @author          Matthew Maramot
     * @description     Creates a EmailRedirection Platform Event
     * @param           action - Action to pass to the platform event
     *                  parameter - Inputs to pass to the platform event
     */
    public static Email_Redirection_Event__e createEmailRedirectionEvent(String action, String parameter){  
        Email_Redirection_Event__e event = new Email_Redirection_Event__e();
        event.Action__c = action;
        event.Parameter__c = parameter;
        return event;
    } 

     /*
     * @author          Matthew Maramot
     * @description     Wrapper Class for Case Comments (EmailRedirection functinality)
     */
    public class CaseCommentWrapper {
        public Case originalCase { get; set; }
        public Case cloneCase { get; set; }
        public CaseComment caseComment { get; set; }
        public String type { get; set; }
    
        // Constructor
        public caseCommentWrapper(Case originalCase, Case cloneCase, CaseComment caseComment, String type) {
            this.originalCase = originalCase;
            this.cloneCase = cloneCase;
            this.caseComment = caseComment;
            this.type = type;
        }

        public void updateCaseCommentParent(){
            if(this.originalCase.Id != null && this.type == 'original'){
                this.caseComment.parentId = this.originalCase.Id;
            }

            if(this.cloneCase.Id != null && this.type == 'clone'){
                this.caseComment.parentId = this.cloneCase.Id;
            }
        }

        public void applyMergeFields(Case newClone){
            List<String> fieldMapping = new List<String>{
                this.originalCase.caseNumber, 
                this.originalCase.RecordType.Name, 
                newClone.caseNumber,
                newClone.RecordType.Name
            };
            this.caseComment.commentBody = String.format(this.caseComment.commentBody, fieldMapping);
        }

        public CaseComment getCaseComment(){
            return this.caseComment;
        }

        public Id getCloneCaseId(){
            return this.cloneCase.id;
        }

    }
}