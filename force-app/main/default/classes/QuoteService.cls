/**
* @author David Browaeys
* @date 21/10/2019
* @group SF Offer
* @description 
*/
global inherited sharing class QuoteService {

    public static Map<Id, Product2> productMap = new Map<Id, Product2>();
     /**
    * @description get Quote record filter by Id paramater
    * @param offerId - SBQQ__Quote__c Id to be retrieved
    * @return a single SBQQ__Quote__c
    **/ 
    //@AuraEnabled
    public static SBQQ__Quote__c getOfferDetails(String offerId){        
        Set<String> idSet = new Set<String>{offerId};
        List<SBQQ__Quote__c> quoteList = new QuotesSelector().selectQuoteById(idSet);
        if(quoteList.size() > 0){
            return quoteList[0];
        }
        return new SBQQ__Quote__c();
        
    }
     /**
    * @description get list of Quote record filter by primary contact or owner id paramater
    * @param contactId - SBQQ__PrimaryContact__c id
    * @param ownerId - User id
    * @return a list of SBQQ__Quote__c
    **/
    //@AuraEnabled(cacheable=true)
    public static List<SBQQ__Quote__c> getOfferList(String contactId, String ownerId){
        return new QuotesSelector().selectQuoteByContactOwner(contactId,  ownerId);
    }
    
    /**
    * @description get list of Quote record filter by primary contact or owner id paramater
    * @param contactId - SBQQ__PrimaryContact__c id
    * @param ownerId - User id
    * @return a list of SBQQ__Quote__c
    **/
    //@AuraEnabled
    public static List<OfferListWrapper> getCurrentOfferList(String contactId, String ownerId, Integer limitNum, Integer offset){
        List<OfferListWrapper> offerWrapperList = new List<OfferListWrapper>();
        for(SBQQ__Quote__c quote: new QuotesSelector().selectQuoteByWithPagination(contactId,  ownerId, limitNum, offset)){
            OfferListWrapper wrapper = new OfferListWrapper();
            wrapper.quote = quote;
            wrapper.quoteLineList = quote.SBQQ__LineItems__r;
            wrapper.lastQuoteLine = (quote.SBQQ__LineItems__r.size() > 0 ? quote.SBQQ__LineItems__r[0] : null);
            for(SBQQ__QuoteLine__c ql: quote.SBQQ__LineItems__r){
                if(ql.SBQQ__ProductFamily__c == 'Grant' || ql.SBQQ__ProductFamily__c == 'Scholarship'){
                    wrapper.grantQuoteLine = ql;
                }
            }
            offerWrapperList.add(wrapper);
        }
        return offerWrapperList;
    }
    
    public class OfferListWrapper{
        @AuraEnabled
        public SBQQ__Quote__c quote {get; set;}
        @AuraEnabled
        public List<SBQQ__QuoteLine__c> quoteLineList {get; set;}
        @AuraEnabled
        public SBQQ__QuoteLine__c lastQuoteLine {get; set;}
        @AuraEnabled
        public SBQQ__QuoteLine__c grantQuoteLine {get; set;}
    }
    
   /**
    * @author Jasmin Joy Rudio
    * @date 11/14/2019
    * @description Update Quote Expiry status and Opportunity to regenerate new Quote
    * @param Quote record 
    * @return Opportunity record to be updated
    */
    public static Opportunity updateQuoteExpiry(SBQQ__Quote__c quote){
        //additional query of updated records were required as the same record was being validated/processed by the Quote line process builder
        //SBQQ__Quote__c quote = QuoteService.getOfferDetails(quoteObj.Id);
        String oldExpiryStatus = quote.Expiry_Status__c;
        String oldStatus = quote.SBQQ__Status__c;
        quote.Expiry_Status__c = '';
        
        if(quote.SBQQ__Status__c == 'Created'
            || quote.SBQQ__Status__c == 'Preview Created'
            || quote.SBQQ__Status__c == 'In Review')
        {
            quote.Expiry_Status__c = 'Expired prior to publishing';

        }else if(quote.SBQQ__Status__c == 'Published'
                || quote.SBQQ__Status__c == 'Email sent'
                || quote.SBQQ__Status__c == 'Portal viewed')
        {
            quote.Expiry_Status__c = 'Expired in portal';

        }else if(quote.SBQQ__Status__c == 'Pending signature')
        {
            quote.Expiry_Status__c = 'Expired in DocuSign';
        }
        
        //quote.SBQQ__Primary__c = false;
        quote.SBQQ__Status__c = 'Expired and regenerated';
        quote.Expiry_Status_Date__c = (quote.Expiry_Status__c != oldExpiryStatus ? Date.today() : quote.Expiry_Status_Date__c);
        quote.Offer_Status_Date__c = (quote.SBQQ__Status__c != oldStatus ? Date.today() : quote.Offer_Status_Date__c);
        
        Opportunity opp = new Opportunity();
        opp.Id = quote.SBQQ__Opportunity2__c;
        opp.Primary_Quote_Regeneration_Date__c = Datetime.now();
        opp.StageName = 'Processing Offer';
        opp.NextStep = 'Generate Offer';
        return opp;
    }

   /**
    * @author Mathew Jose
    * @date 11/11/2019
    * @description Syncing opportunity with the calculated quote fields
    * @param Quote record 
    * @return expiry status string
    */
    public static Opportunity syncOpportunityWithQuote(SBQQ__Quote__c quote){
        Opportunity opp = new Opportunity();
        opp.Id = quote.SBQQ__Opportunity2__c;
        opp.AccountId = quote.SBQQ__Account__c;
        opp.Agent_Account__c = quote.SBQQ__Partner__c;
        opp.Offer_End_Date__c = quote.SBQQ__EndDate__c;
        opp.Offer_Start_Date__c = quote.SBQQ__StartDate__c;
        opp.Offer_Type__c = quote.Offer_Type__c;
        opp.PrimaryContact__c = quote.SBQQ__PrimaryContact__c;
        opp.Visa_Start_Date__c = quote.Visa_Start_Date__c;
        opp.Visa_End_Date__c =	quote.Visa_End_Date__c;
        return opp;

    } 

   /**
    * @author Mathew Jose
    * @date 11/11/2019
    * @description create Quote PE
    * @return Quote_Event__e
    */
    public static Quote_Event__e createQuoteEvent(SBQQ__Quote__c quote){
        return new Quote_Event__e(Quote_Id__c = quote.Id);
    }  

    /**
    * @author David Browaeys
    * @date 10/01/2020
    * @description Assign quote to business queue
    * @param quote the quote record to update
    * @return void
    */
    public static Group[] businessQueue;
    public static void assignQuoteToBusinessQueue(SBQQ__Quote__c quote){
        if (businessQueue == null) {
            businessQueue = [select Id from Group where Type = 'Queue' AND DeveloperName = :Constants.BUSINESS_OFFER_QUEUE];
        }
        quote.OwnerId = businessQueue[0].Id;    
    }
   /**
    * @author Richard Cook
    * @description method which checks whether a successfull callback has occured on the quote from the CPQ pricing service
    * @param quoteId record Id for update
    * @return Boolean
    */                 
    @AuraEnabled
    public static Boolean quoteCalculationComplete(Id quoteId)
    {
        SBQQ__Quote__c myQuote = new QuotesSelector().selectQuoteById(new Set<String>{quoteId})[0];
        return myQuote.Calculate_API_Response_Time__c != null;
    }
   /**
    * @author Richard Cook
    * @Revision Kristian, Shalini - Update Nominated_Health_Cover__c & trigger CPQ recalculation
    * @description update quote selection, with OSHC quote line selection
    * @param hqr Data transfer object containing selection made on quote
    * @return QuoteOSHCView
    */    
    //@AuraEnabled
    public static QuoteOSHCView setQuoteOSHCView(FormPageService.HeathQuoteRequest hqr) {
        QuoteOSHCView vm = getQuoteOSHCView(hqr.quoteId, true);
        if(vm.isLocked)
        {
            throw new AuraHandledException('Quote is in a state which cannot be modified.'); 
        }

        // call logic to select overseas health cover and recalculate cpq
       QuoteService.selectHealthCoverAndRecalculate(hqr.quoteId, 
                                                    hqr.selectedProvider, 
                                                    hqr.selectedProviderName, 
                                                    hqr.subStatus, 
                                                    hqr.selectedHealthOption);
        SBQQ__Quote__c existingQuote = new QuotesSelector().selectById(new Set<Id>{hqr.quoteId})[0];
       // sync opportunity's nominated health cover
        TriggerCommon.disableTrigger('Opportunity');
        update new Opportunity(Id = existingQuote.SBQQ__Opportunity2__c, Nominated_Health_Cover__c = hqr.selectedHealthOption);
        TriggerCommon.enableTrigger('Opportunity');

        return vm;            
    }

    /**
    * @author       Kristian Vegerano
    * @description  Update quote's selected health cover and recalculate cpq
    * @param        quoteId - quote id to be updated
    *               selectedProvider - nominated provider type
    *               selectedProviderName - nominated provider name
    *               subStatus - new sub status of the quote
    *               selectedHealthOption - nominated health cover option
    * @return       CPQ_ApiDataModels.QuoteModel - updated cpq quote model
    */    
    public static void selectHealthCoverAndRecalculate(Id quoteId, String selectedProvider, String selectedProviderName, String subStatus, String selectedHealthOption){
    
          
            CPQ_ApiDataModels.QuoteModel myQuote = CPQ_APIService.getQuote(quoteId);
            myQuote.record.Health_Cover_Provider_Type__c = selectedProvider;
            myQuote.record.Health_Cover_Provider_Name__c = selectedProviderName;
            if(subStatus!=null)
            {
                myQuote.record.Sub_Status__c = subStatus;
            }
            for(CPQ_ApiDataModels.QuoteLineModel qm: myQuote.lineItems)
            {
                // Product Options do not sync CA like in QLE need to set them all
                if(qm.record != null && qm.record.SBQQ__ProductFamily__c == 'OSHC')
                {
                    qm.record.Health_Cover_Type__c = selectedHealthOption;
                }
            }
            myQuote.record.Calculate_API_Request_Time__c  = Datetime.now();
            myQuote.record.Calculate_API_Response_Time__c  = null;
            myQuote = CPQ_APIService.save(myQuote);  // FIXME: Is this necessary or will calculate do it?
            CPQ_APIService.calculate(myQuote, QuoteBasicCallback.class.toString() );
         
    }

   /**
    * @author Richard Cook
    * @description retrieve OSHC related information for quote selection on community portal
    * @param quoteId Id - record which is requested
    * @param requestUpdate Boolean - request to lock record
    * @return QuoteOSHCView
    */      
    //@AuraEnabled
    public static QuoteOSHCView getQuoteOSHCView(Id quoteId, Boolean requestUpdate)
    {
        if(quoteId == null || requestUpdate == null)
        {
            throw new AuraHandledException('Invalid input sent to system');
        }
        return new QuoteOSHCView(quoteId, requestUpdate);
    }
   /**
    * @author Richard Cook
    * @description determine whether. This logic is also enforced client side in LWC offerRegenerat.js
    * @param QuoteStatus String status of record which update is requested for
    * @return Boolean
    */       
    @TestVisible
    private static Boolean canRegenerate(String QuoteStatus)
    {
        return QuoteStatus == Constants.QUOTE_STATUS_PUBLISHED;
    }
  /**
    * @author Richard Cook
    * @description Perform Quote regeneraction action. This will generate a new quote using QuoteService.CPQQuoteGenerator execute
    * and update the status on the existing quote / opprty
    * @param existingQuoteId recordId
    * @return Id
    */  
    @AuraEnabled
    public static Id doRegenerate(Id existingQuoteId){
        return new RegenerateQuote(existingQuoteId).execute();
    }  
    public without sharing class RegenerateQuote{
        Id existingQuoteId;
        public RegenerateQuote(Id existingQuoteId){
            this.existingQuoteId = existingQuoteId;
        }
        public Id execute(){
            if(existingQuoteId == null){
                throw new IllegalArgumentException('Invalid quote Id');  
                }
            Set<Id> quoteIds = new Set<Id>();
            quoteIds.add(existingQuoteId);      
            SBQQ__Quote__c existingQuote = new QuotesSelector().selectById(quoteIds)[0];

            if(!CanRegenerate(existingQuote.SBQQ__Status__c))
                throw new AuraHandledException('Cannot regenerate this quote');

            Set<Id> oppSet = new SEt<Id>();
            oppSet.add(existingQuote.SBQQ__Opportunity2__c);        
            List<Opportunity> oppList = new OpportunitiesSelector().selectByIdWithOpportunityLines(oppSet);
            Opportunity opp = null;
            if(oppList.size() > 0)
            {
                opp = oppList[0];
            }
            QuoteGenerator genService = new QuoteGenerator(opp);
            genService.execute();
            existingQuote.Offer_Manually_Regenerated__c = true;
            existingQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_EXPIRED_REGEN;
            update existingQuote;

            opp.StageName = Constants.OPPTY_STATUS_SPEC_REVIEW;
            opp.Primary_Quote_Regeneration_Date__c = Datetime.now();
                opp.OwnerId = Userinfo.getUserId();
                update opp;

            return genService.getQuoteId();
        }             
    }  
    /**
    * @description expire quote 
    * @author David Browaeys
    * @param quote quote to expire
    * @return void
    * @example 
    * QuoteService.updateQuoteForExpiry(myQuote);
    */
    public static void updateQuoteForExpiry(SBQQ__Quote__c quote){
        quote.Status_When_Offer_Expired__c = quote.SBQQ__Status__c;
        quote.Expiry_Status_Date__c = Date.today();
        quote.Docusign_Expiry_Time__c = Datetime.now();
    }

    /**
    * @Revision Shalini Mendu 05/07/2022 - add MFA permission set 
	* @author Herman Castano
	* @date 05/02/2020
	* @description add CC/MFA portal permission set to new portal users
	* @return 
	*/    
    public static void assignCCUserPermSet(List<SBQQ__Quote__c> quotes, Set<ID> contactIds) {
        if (contactIds.size() > 0) {
            //Filter in applicants that do not have MFA access yet - Checking MFA and not my.app to capture historic users
            //who have My App Permission set and not MFA
            Set<Id> existingMyAppContactIds = new Set<Id>();
            for(PermissionSetAssignment loopAssignment : [SELECT Id, AssigneeId, Assignee.ContactId, Assignee.LastLoginDate  
                                                        FROM PermissionSetAssignment 
                                                        WHERE Assignee.ContactId IN :contactIds
                                                            AND PermissionSet.Name = :Constants.MYAPP_PERMSET_NAME]){
                //exclude the user if they have already logged in - exclusion logic below after the loop
                if(loopAssignment.Assignee.LastLoginDate != null){
                    existingMyAppContactIds.add(loopAssignment.Assignee.ContactId);
                }
          
            }

            //Only process contacts that don't have MFA access yet
            Set<Id> includedContactSet = new Set<Id>();
            for(Id loopContactId : contactIds){
                if(!existingMyAppContactIds.contains(loopContactId)){
                    includedContactSet.add(loopContactId);
                }
            }

            List<User> existingUsers = new List<User>([
                SELECT id, ContactId
                FROM User
                WHERE ContactId in :includedContactSet
                AND IsActive = TRUE]);  
            Map<ID, User> userPortals = new Map<Id,User>();
            for (User u : existingUsers){
                userPortals.put(u.ContactId,u);
            }
            for (SBQQ__Quote__c q : quotes) {
                if(includedContactSet.contains(q.SBQQ__PrimaryContact__c)){
                    if (userPortals.get(q.SBQQ__PrimaryContact__c) == null) {
                        q.addError('No user exist for this applicant. Please contact a system administrator.');
                    }
                }
            }
            //Add My.app and MFA permission sets
            List<PermissionSet> permSetsToAdd = new List<PermissionSet>(
                [SELECT Id, Name 
                    FROM PermissionSet 
                    WHERE Name IN ( :Constants.MYAPP_PERMSET_NAME, :Constants.MYAPP_MFA_PERMSET_NAME)] ); 
               UserServices.addPermSetToPortalUsers(existingUsers, permSetsToAdd, true);
        }
    }

    /**
     * @description Get Offer tech queue 
     */
    public static Group[] techQueue {get{
        if (techQueue == null){
            techQueue = [Select Id, Name, Type 
                             From Group 
                             Where Type = 'Queue'
                             And DeveloperName =: Constants.TECHNICAL_OFFER_QUEUE
                             Limit 1];
        }
		return techQueue;
    } private set;}
    /**
     * @description Send quote to tech queue and update statis for error
     * @param quoteId selected quote id
     * @param error
     */
    public static SBQQ__Quote__c sendQuoteToTechQueue(String quoteId, String error){
        // Update Quote substatus, Error log and assign the quote to the technical error queue
        return new SBQQ__Quote__c(
            Id = quoteId, 
            Sub_Status__c='Offer creation/update error', 
            Sub_status_changed_on__c = Datetime.now(),
            Error_Log__c = error,
            OwnerId=techQueue[0].Id);
    }

    /*
     * @author       Kristian Vegerano
     * @date         23/07/2020
     * @description  Class supporting the logic to update the quote's managing faculty based on its line items
     * @revision	 1.0
     */
    public static void updateManagingFaculty(List<SBQQ__Quote__c> quotes) {
        //Initialize variables
        Map<Id, SBQQ__Quote__c> quotesMap = new Map<Id, SBQQ__Quote__c>(quotes);

        //Process quote line items - set the quote's managing faculty based on the quote line's acp managing faculty
        for(SBQQ__QuoteLine__c loopQuoteLine : new QuoteLinesSelector().selectByQuoteIdAndProductFamily(quotesMap.keySet(), new List<String>{'Course','Diploma','English Course'})){
            if(loopQuoteLine.Application_Course_Preference__r.Managing_Faculty__c != null){
                if(quotesMap.containsKey(loopQuoteLine.SBQQ__Quote__c)){
                    quotesMap.get(loopQuoteLine.SBQQ__Quote__c).Managing_Faculty__c = loopQuoteLine.Application_Course_Preference__r.Managing_Faculty__c;
                }
            }
        }
    }

    /*
     * @author       Kristian Vegerano
     * @date         01/08/2020
     * @description  Method that sends offer confirmation email to the students on offer publish
     */
    public static void sendPublishEmailToApplicant(Map<Id, SBQQ__Quote__c> contactToQuoteMap) {
        //Filter out applicants that doesnt have my.app access yet
        Set<Id> existingMyAppContactIds = new Set<Id>();
        for(PermissionSetAssignment loopAssignment : [SELECT Id, AssigneeId, Assignee.ContactId, Assignee.LastLoginDate  
                                                      FROM PermissionSetAssignment 
                                                      WHERE Assignee.ContactId IN :contactToQuoteMap.keySet()
                                                        AND PermissionSet.Name = :Constants.MYAPP_PERMSET_NAME]){
            //include the user if they already logged in
            if(loopAssignment.Assignee.LastLoginDate != null){
                existingMyAppContactIds.add(loopAssignment.Assignee.ContactId);
            }
        }
        

        //include the user if running in test context - resolving mixed dml
        if(Test.isRunningTest()){
            for(SBQQ__Quote__c loopQuote : contactToQuoteMap.values()){
                existingMyAppContactIds.add(loopQuote.SBQQ__PrimaryContact__c);
            }
        }

        //Retrieve relevant email message
        EmailTemplate publishEmailToApplicant;
        for(EmailTemplate loopTemplate : [SELECT Id, Name, DeveloperName, HtmlValue, Subject 
                                          FROM EmailTemplate 
                                          WHERE DeveloperName = 'OfferPublishedForApplicant'
                                          ORDER BY Name DESC]){
            publishEmailToApplicant = loopTemplate;
        }

        //Retrieve quote records
        Set<Id> quoteIds = new Set<Id>();
        for(SBQQ__Quote__c loopQuote : contactToQuoteMap.values()){
            quoteIds.add(loopQuote.Id);
        }

        //Retrieve opportunity details
        Map<Id, Opportunity> contactToOpportunityMap = new Map<Id, Opportunity>();
        for(Opportunity loopOpportunity : [SELECT Id, Agent_Account__c, Agent_Account__r.Email__c, Agent_Name__c, Calculated_Expiry_Date__c, SBQQ__PrimaryQuote__c,
                                                  SBQQ__PrimaryQuote__r.Offer_has_grant__c, SBQQ__PrimaryQuote__r.Offer_has_scholarship__c, Regeneration_Reason__c,
                                                  PrimaryContact__c, PrimaryContact__r.Under_18__c, PrimaryContact__r.Email, PrimaryContact__r.Name, PrimaryContact__r.FirstName, PrimaryContact__r.LastName, PrimaryContact__r.Person_ID__c, 
                                                  PrimaryContact__r.MailingStreet, PrimaryContact__r.MailingCity, PrimaryContact__r.MailingState, PrimaryContact__r.MailingPostalCode, 
                                                  PrimaryContact__r.MailingCountry, CloseDate, Primary_Quote_Regeneration_Date__c
                                           FROM Opportunity 
                                           WHERE SBQQ__PrimaryQuote__c IN :quoteIds]){
            contactToOpportunityMap.put(loopOpportunity.PrimaryContact__c, loopOpportunity);
        }
        
        //Substitute proper values for the placeholders per contact
        Map<Id, String> emailContentMap = new Map<Id, String>();        
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();

        //Retrieve MU Docs queue
        Group muDocsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SRA_IA_MU_Docs' LIMIT 1];
        //Retrieve MU Docs org-wide address
        String fromEmail = 'mu.documents@f.e.monash.edu';
        OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'mu.documents@f.e.monash.edu' LIMIT 1];
        
        
        //Retrive community login url to access image static resource outside salesforce
        Network communityNetwork = [SELECT Id, Name FROM Network WHERE Name = 'my.application' LIMIT 1];
        String communityUrl = Network.getLoginUrl(communityNetwork.Id);
        //communityUrl = communityUrl.replace('/admissions/s/login', '');

        for(Id loopContactId : existingMyAppContactIds){
            //add email details per contact
            String contactEmailContent = publishEmailToApplicant.HtmlValue;
            Opportunity relatedOpportunity = contactToOpportunityMap.get(loopContactId);

            if(relatedOpportunity != null){
                //Set applicant first name
                if(relatedOpportunity.PrimaryContact__r.FirstName != null){
                    contactEmailContent = contactEmailContent.replace('<ApplicantFirstName/>', relatedOpportunity.PrimaryContact__r.FirstName);
                }

                //Set header content item
                String headerContent = 'We\'re absolutely delighted to tell you that you have an offer to study at Monash University';
                if(relatedOpportunity.SBQQ__PrimaryQuote__r.Offer_has_grant__c != 0 || relatedOpportunity.SBQQ__PrimaryQuote__r.Offer_has_scholarship__c != 0){
                    if(relatedOpportunity.SBQQ__PrimaryQuote__r.Offer_has_grant__c != 0){
                        headerContent = headerContent + ' including a grant';
                    }
                    if(relatedOpportunity.SBQQ__PrimaryQuote__r.Offer_has_scholarship__c != 0){
                        headerContent = headerContent + ' including a scholarship';
                    }
                }
                headerContent = headerContent + '.';
                contactEmailContent = contactEmailContent.replace('<HeaderContent/>', headerContent);

                //Show regenerated blurb
                if(relatedOpportunity.Primary_Quote_Regeneration_Date__c != null){
                    contactEmailContent = contactEmailContent.replace('<IsOfferRegenerated/>', 'inline');
                }else{
                    contactEmailContent = contactEmailContent.replace('<IsOfferRegenerated/>', 'none');
                }

                //Show regenerated blurb
                if(relatedOpportunity.Primary_Quote_Regeneration_Date__c != null){
                    contactEmailContent = contactEmailContent.replace('<IsOfferRegenerated/>', 'inline');
                }else{
                    contactEmailContent = contactEmailContent.replace('<IsOfferRegenerated/>', 'none');
                }

                //Set opportunity regeneration reason
                if(relatedOpportunity.Regeneration_Reason__c != null){
                    contactEmailContent = contactEmailContent.replace('<OfferRegenerationReason/>', relatedOpportunity.Regeneration_Reason__c);
                    
                    contactEmailContent = contactEmailContent.replace('<OfferRegenerationReasonBlank/>', 'none');
                    contactEmailContent = contactEmailContent.replace('<OfferRegenerationReasonPopulated/>', 'inline');
                }else{
                    contactEmailContent = contactEmailContent.replace('<OfferRegenerationReasonBlank/>', 'inline');
                    contactEmailContent = contactEmailContent.replace('<OfferRegenerationReasonPopulated/>', 'none');
                }

                //Determine if the expire date should be shown
                if(relatedOpportunity.Calculated_Expiry_Date__c != null){
                    if(relatedOpportunity.Calculated_Expiry_Date__c > System.TODAY().addDays(-7)){
                        contactEmailContent = contactEmailContent.replace('<IsShowExpire/>', 'inline');
                    }else{
                        contactEmailContent = contactEmailContent.replace('<IsShowExpire/>', 'none');
                    }
                }

                //Set opportunity expire date
                if(relatedOpportunity.Calculated_Expiry_Date__c != null){
                    contactEmailContent = contactEmailContent.replace('<ExpireDate/>', DateTime.newInstance(relatedOpportunity.Calculated_Expiry_Date__c.year(), relatedOpportunity.Calculated_Expiry_Date__c.month(), relatedOpportunity.Calculated_Expiry_Date__c.day()).format('d MMMM yyyy'));
                }

                //Set template's under 18 message
                if(relatedOpportunity.PrimaryContact__r.Under_18__c){
                    contactEmailContent = contactEmailContent.replace('<IsUnder18/>', 'inline');
                }else{                
                    contactEmailContent = contactEmailContent.replace('<IsUnder18/>', 'none');
                }

                //set community login
                contactEmailContent = contactEmailContent.replace('<CommunityLoginLink/>', communityUrl);            

                //Replace image url to use community to access static resource
                contactEmailContent = contactEmailContent.replace('/resource', communityUrl + '/admissions/resource');

                //attach the email content to the contact
                emailContentMap.put(loopContactId, contactEmailContent);

                //Build email message
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setPlainTextBody(emailContentMap.get(loopContactId).stripHtmlTags());
                message.setHtmlBody(emailContentMap.get(loopContactId));
                message.setSubject('Monash University has made you an offer!');
                message.setReplyTo(fromEmail);
                message.setOrgWideEmailAddressId(orgWideAddress.Id);
                message.setToAddresses(new List<String>{ contactToOpportunityMap.get(loopContactId).PrimaryContact__r.Email });
                message.setWhatId(contactToOpportunityMap.get(loopContactId).Id);
                message.setTargetObjectId(loopContactId);
                messageList.add(message);
                
            }
        }   

        //Send email message
        if(!Test.isRunningTest()){
            if(!messageList.isEmpty()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messageList);
                if (results[0].success) {
                    //debugging here
                } else {
                    //debugging here
                }
            }
        }
    }
      /*
     * @author       Shalini Mendu
     * @date         30/05/2022
     * @description  Subscriber to the event Async_Process__e to run
     * CPQ calculation in system context
     */
    public class SyncQuote implements IPlatformEventInvocable {
        public void execute(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
                String quoteId;
                String selectedProvider;   
                String selectedProviderName;  
                String selectedHealthOption;
                //convert back all the JSON into String
                for(AsyncProcessPayload payload : payloads) {
                    quoteId = payload.get('quoteId').toString().remove('"');
                    selectedProvider = payload.get('selectedProvider').toString().remove('"');    
                    selectedProviderName = payload.get('selectedProviderName').toString().remove('"');
                    selectedHealthOption = payload.get('selectedHealthOption').toString().remove('"');

                }
                //Call the calculation method
                selectHealthCoverAndRecalculate(Id.valueOf(quoteId) , selectedProvider, selectedProviderName, null, selectedHealthOption);
            }
        }
    }
}