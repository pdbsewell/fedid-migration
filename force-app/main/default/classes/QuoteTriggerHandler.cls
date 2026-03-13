/*
 * @File Name          : QuoteTriggerHandler.cls
 * @Description        : Service layer containing most business logic for Quote object 
 * @Author             : Mathew Jose
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 3/5/2020, 11:50:01 AM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    11/11/2019       Mathew Jose             Initial Version
 * 1.1    12/05/2021       Vinothraja              SFTG-1956 Added logic to filter out MA opportunities from Acceptance Checklist process
 * 1.2    30/06/2022       Vinothraja              SFTG-2780 Added logic to sync Quote and Oppty line items
 * 1.3    24/06/2025       Vishal Gupta            MGROI-787 send the Graduate research scholarship offers to callista when its accepted or rejected
**/
public class QuoteTriggerHandler {
    public static Boolean lockUserCreation = false;
    public static Boolean skipDocumentCheckList = false;
    
    public class ClauseGeneration extends TriggerAbstract { 
        Set<ID> quoteIds = new Set<ID>();

        public override void process(SObject rec) {
            Quote_Event__e record = (Quote_Event__e) rec;
            if (quoteIds.contains(record.Quote_Id__c) == false) quoteIds.add(record.Quote_Id__c);
        }

        public override void execute() {
            if (quoteIds.isEmpty() == false){
                SBQQ__QuoteLine__c[] quoteLines = new QuoteLinesSelector().selectByIdWithQuoteLines(quoteIds);
                if(!quoteLines.IsEmpty()){
                    try {
                        //add clause calculation logic here
                        new OfferClauseService(quoteLines).execute();
                    } catch(Exception ex){
                        nebula.logger.error(ex.getMessage(), quoteLines);
                        nebula.logger.exception(ex.getMessage(), ex);
                    } finally {
                        nebula.logger.saveLog();
                    }
                }
            }
        }

    }
    
    /**
    * @author David Browaeys
    * @date 11/14/2019
    * @description Update Quote status fields for every Quote related business proccess
    */
    public class QuoteStatusUpdates extends TriggerAbstract{
        @TestVisible Map<String,SBQQ__Quote__c> oldQuotes = new Map<String,SBQQ__Quote__c>();
        @TestVisible Opportunity[] opportunities = new Opportunity[0];
        @TestVisible List<Product2> productList = new List<Product2>();
        @TestVisible Quote_Event__e[] quoteEvents = new Quote_Event__e[0];
        @TestVisible Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteForQuotaRecalc = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        @TestVisible List<SBQQ__Quote__c> updateManagingFaculty = new List<SBQQ__Quote__c>();

        private final Set<String> CLOSED_LOST_STATUSES = 
            new Set<String> {
                'Deferred', 
                'Rejected', 
                'Cancelled', 
                'Expired and regenerated', 
                'Expired'
            };
        /**
         * Process all quote records in trigger context
         * @param  rec    new record
         * @param  oldRec old record
         */
        public override void process(SObject rec, SObject oldRec) {
            SBQQ__Quote__c q = (SBQQ__Quote__c) rec, oldQuote = (SBQQ__Quote__c) oldRec;
          
            handleExpiryDate(q, oldQuote);
            if (q.Product_Status__c != oldQuote.Product_Status__c || 
                    q.SBQQ__Status__c != oldQuote.SBQQ__Status__c || 
                    q.Sub_Status__c != oldQuote.Sub_Status__c) {

                oldQuotes.put(oldQuote.Id, oldQuote);
                switch on q.SBQQ__Status__c {
                    when  'In Review'{
                        handleInReview(q);
                    }
                    when  'Approved'{
                        handleApproved(q);
                    }
                    when  'Published'{
                        handlePublished(q);
                    }
                    when  'Signed'{
                        handleSigned(q);
                    }
                    when  'Deferred', 'Rejected', 'Cancelled', 'Expired and regenerated', 'Expired'{
                        records.add(q);
                    }
                    when else {
                        //No action identified for this quote status.
                    }
                }
                handleQuote(q);
            }
            
            if(!String.isBlank(q.Sub_Status__c) && q.Sub_Status__c != oldQuote.Sub_Status__c){
                captureTimeStamps(q);
            }
        }

         /**
         * Capture timestamps for some Quote sub status values
         * @param  rec    new record
         */
        public void captureTimeStamps(SBQQ__Quote__c q)
        {  
           
            switch on q.Sub_Status__c.toUpperCase(){
                when 'PRICING COMPLETED' {
                    q.Pricing_Completed_TimeStamp__c = Datetime.now();
                }
                when 'PREVIEW REQUESTED' {
                    q.Preview_Requested_TimeStamp__c = Datetime.now();
                }
                when 'PREVIEW IN QA' {
                    q.Document_Generated_TimeStamp__c  = Datetime.now();
                }
                when 'READY FOR ACKNOWLEDGEMENT' {
                    q.Student_Acknowledgement_TimeStamp__c = Datetime.now();
                }
                when 'SIGNED AND LOCKED' {
                    q.Signed_TimeStamp__c = Datetime.now();
                }
            }
        }

        /**
         * Execute all post quote processing actions. 
         */
        public override void execute() {
            for (SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) records) {
                if (CLOSED_LOST_STATUSES.contains(quote.SBQQ__Status__c)) {
                    handleClosedLost(quote);
                }
            }
            if (!opportunities.isEmpty()) {
                Map<Id,Opportunity> oppsForUpdate = new Map<Id,Opportunity> ();
                for(Opportunity opp : opportunities) { // SFTG-1846 Included to avoid trying to Update new opportunities
                    if (String.isNotBlank(opp.id)) {
                        oppsForUpdate.put(opp.id, opp);
                    }
                }
                update oppsForUpdate.values();
            } 
            
            OfferGrantScholarshipQuotaService quotaService = 
                new OfferGrantScholarshipQuotaService(
                    new QuoteLinesSelector(),
                    new SObjectDao()
                );
            if (quoteForQuotaRecalc.isEmpty() == false) quotaService.updateQuota(quoteForQuotaRecalc);

            if (quoteEvents.isEmpty() == false) EventBus.publish(quoteEvents);
            if (!updateManagingFaculty.isEmpty()) QuoteService.updateManagingFaculty(updateManagingFaculty);
        }
        /**
         * This method handles quote expiry date validation to update status accordingly
         * @param  quote quote record in the current context
         */ 
        public void handleExpiryDate(SBQQ__Quote__c quote, SBQQ__Quote__c oldQuote){
            if( quote.SBQQ__ExpirationDate__c != oldQuote.SBQQ__ExpirationDate__c
                && Date.today() > quote.SBQQ__ExpirationDate__c
                && quote.SBQQ__Status__c != 'Expired and regenerated'
                && quote.SBQQ__Status__c != 'Expired'
                && quote.SBQQ__Status__c != 'Cancelled'
                && quote.SBQQ__Status__c != 'Deferred'
                && quote.SBQQ__Status__c != 'Rejected'){

                    quote.SBQQ__Status__c = 'Expired';
            }
        }
        /**
         * Common method to handle all quotes
         * @param  quote quote record in the current context
         */ 
        public void handleQuote(SBQQ__Quote__c quote){
            if(quote.Template_Type__c == 'Domestic Coursework Australia' && quote.OpportunityStage__c != 'Canceled/Rejected' && !CLOSED_LOST_STATUSES.contains(quote.SBQQ__Status__c)  )
            {
                opportunities.add(new Opportunity(Id = quote.SBQQ__Opportunity2__c, StageName = 'Review Offer',Preview_Ready__c=true)); 
            }
            quote.Sub_status_changed_on__c = Datetime.now();
            if (oldQuotes.get(quote.Id).In_Technical_Error__c != quote.In_Technical_Error__c  && quote.In_Technical_Error__c  == true && quote.OwnerId != QuoteService.techQueue[0].Id){
                quote.OwnerId = QuoteService.techQueue[0].Id;
            }
            if (quote.Contact_Access__c != null && quote.SBQQ__Primary__c == false) {  //hide quote from portal if not primary
                quote.Contact_Access__c = null;
            }
            if( quote.Product_Status__c != oldQuotes.get(quote.Id).Product_Status__c 
                 && (quote.Product_Status__c == 'Grant expired' || quote.Product_Status__c == 'Scholarship expired')
                 && quote.SBQQ__Status__c != 'Expired and regenerated'
                 && quote.SBQQ__Status__c != 'Expired'
                 && quote.SBQQ__Status__c != 'Signed'){   
        
                    Opportunity opp = QuoteService.updateQuoteExpiry(quote);    
                    if (opp != null) {
                        opportunities.add(opp);
                    }
            }
        }
        /**
         * This method handles In Review quotes
         * @param  quote quote record in the current context
         */
        public void handleInReview(SBQQ__Quote__c quote){
            if (quote.Sub_Status__c == 'Pricing Completed' && quote.Sub_Status__c != oldQuotes.get(quote.Id).Sub_Status__c) {
                Quote_Event__e evt = QuoteService.createQuoteEvent(quote);
                if (evt != null) {
                    quoteEvents.add(evt);
                }
            }else if (quote.Sub_Status__c == 'Auto Clauses Attached' && quote.Sub_Status__c != oldQuotes.get(quote.Id).Sub_Status__c) {
               
                quote.Clauses_Attached_TimeStamp__c = Datetime.now();
                SBQQ__Quote__c qq =  [select SBQQ__Opportunity2__r.Template_Type__c from SBQQ__Quote__c where id=:quote.Id];
               if(quote.Template_Type__c == 'Domestic Coursework Australia')
               {
                    quote.SBQQ__Status__c = 'In Review';
                    quote.Sub_Status__c = 'Preview in QA';
               }else{
                    quote.Sub_Status__c = 'Preview Requested';
               }
              
            }else if (quote.Sub_Status__c == 'Business request review' && quote.Sub_Status__c != oldQuotes.get(quote.Id).Sub_Status__c) {
                QuoteService.assignQuoteToBusinessQueue(quote);
            }
        }
        /**
         * This method handles Approved quotes
         * @param  quote quote record in the current context
         */
        public void handleApproved(SBQQ__Quote__c quote){
            if (quote.SBQQ__Status__c != oldQuotes.get(quote.Id).SBQQ__Status__c) {
                opportunities.add(new Opportunity(Id = quote.SBQQ__Opportunity2__c, StageName = 'Review Offer')); 
            }
        }
        /**
         * This method handles Published quotes
         * @param  quote quote record in the current context
         */
        public void handlePublished(SBQQ__Quote__c quote){
            if( quote.SBQQ__Primary__c == true && quote.SBQQ__Status__c != oldQuotes.get(quote.Id).SBQQ__Status__c){
                quote.Assessor_Published_TimeStamp__c = Datetime.now();
                quote.Contact_Access__c = quote.SBQQ__PrimaryContact__c;
                opportunities.add(QuoteService.syncOpportunityWithQuote(quote));
            }
            
            updateManagingFaculty.add(quote);
        }
        /**
         * This method handles Signed quotes
         * @param  quote quote record in the current context
         */
        public void handleSigned(SBQQ__Quote__c quote){
            if (quote.SBQQ__Status__c != oldQuotes.get(quote.Id).SBQQ__Status__c) {
                OfferGrantScholarshipQuotaService.QuoteWithOldQuote signedQuoteWithOldQuote = 
                    new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(quote, oldQuotes.get(quote.Id));
                //update product quota if quote is signed or expired/cancelled/rejected
                quoteForQuotaRecalc.put(quote.Id, signedQuoteWithOldQuote); 
            }
        }
        /**
         * This method handles all closed lost status such as Cancelled, Deferred, Expired, etc. 
         * @param  quote quote record in the current context
         */
        public void handleClosedLost(SBQQ__Quote__c quote){
            OfferGrantScholarshipQuotaService.QuoteWithOldQuote lostQuoteWithOldQuote = 
                new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(quote, oldQuotes.get(quote.Id));
            quoteForQuotaRecalc.put(quote.Id, lostQuoteWithOldQuote);

            if (oldQuotes.get(quote.Id).SBQQ__Status__c != 'Signed' && quote.SBQQ__Status__c != 'Deferred' && String.isNotBlank(quote.Primary_DocuSign_Envelop_Id__c) && records.size() == 1 && quote.Docusign_Expiry_Time__c == null){
                System.enqueueJob(new QuoteExpiryQueueable(new OffersDocuSignEnvelopExpiry(new DocuSignUpdateEnvelopRestApiRequest()), quote)); //expire offer in docusign
            }

            if (quote.Contact_Access__c != null && quote.SBQQ__Status__c == 'Cancelled') {  //hide quote from portal 
                quote.Contact_Access__c = null;
            }

            if(quote.SBQQ__Status__c != 'Expired and regenerated' && quote.SBQQ__Primary__c && quote.OpportunityStage__c != 'Canceled/Rejected') { //close opportunity 
                if (quote.SBQQ__Status__c == 'Deferred') {
                    opportunities.add(new Opportunity(Id = quote.SBQQ__Opportunity2__c, StageName = 'Canceled/Rejected', Closed_Reason__c = quote.SBQQ__Status__c, 
                        Closed_Reason_Details__c = 'Student deferred offer', Closed_from_Quote__c = true));  
                } else {
                    opportunities.add(new Opportunity(Id = quote.SBQQ__Opportunity2__c, StageName = 'Canceled/Rejected', Closed_Reason__c = quote.SBQQ__Status__c, 
                                                        Closed_Reason_Details__c = 'Student rejected offer', Closed_from_Quote__c = true));
                }
            }   
        }
    }

    /**
     *  This class is responsible for initiating updates to quote lines when the status of the quote is modified;
     */
    public class QuoteLineTransform extends TriggerAbstract{
        @TestVisible Map<Id,SBQQ__Quote__c> oldQuotes = new Map<Id,SBQQ__Quote__c>();
        @TestVisible Set<Id> impactedQuotes = new Set<Id>();
        @TestVisible Set<Id> quotesInTechError = new Set<Id>();
        @TestVisible Set<Id> contactIdForPublishedQuotes = new Set<Id>();
        @TestVisible Set<Id> signedOpportunityIds = new Set<Id>();
        @TestVisible Map<Id,SBQQ__Quote__c> newQuotes = new Map<Id,SBQQ__Quote__c>();
                
        @TestVisible Map<Id, SBQQ__Quote__c> publishedQuotes = new Map<Id, SBQQ__Quote__c>();
        @TestVisible List<SBQQ__Quote__c> checkForUsersQuotes = new List<SBQQ__Quote__c>();
        @TestVisible Set<ID> contactIds = new Set<Id>();

        @TestVisible Map<Id, SBQQ__Quote__c> contactQuoteMap = new Map<Id, SBQQ__Quote__c>();

        /**
         * Process all records in trigger context
         * @param  rec    new record
         * @param  oldRec old record
         */
        public override void process(SObject rec, SObject oldRec) {
            SBQQ__Quote__c currentQuote = (SBQQ__Quote__c) rec;
            SBQQ__Quote__c oldQuote = (SBQQ__Quote__c)oldRec;
            newQuotes.put(currentQuote.id, currentQuote);
          
            if (oldQuote.Sub_Status__c != currentQuote.Sub_Status__c && currentQuote.Sub_Status__c == Constants.QUOTE_SUBSTATUS_QAPREVIEW) {
                checkForUsersQuotes.add(currentQuote);
                contactIds.add(currentQuote.SBQQ__PrimaryContact__c);     
            }  else if (oldQuote.SBQQ__Status__c != currentQuote.SBQQ__Status__c && currentQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_PUBLISHED) {
                publishedQuotes.put(currentQuote.Id, currentQuote);
                contactIdForPublishedQuotes.add(currentQuote.SBQQ__PrimaryContact__c);
                contactQuoteMap.put(currentQuote.SBQQ__PrimaryContact__c, currentQuote);
            } 

            Boolean shouldTransformQL = oldQuote.Sub_Status__c == Constants.QUOTE_PRICE_CALCULATED
            && oldQuote.Sub_Status__c != currentQuote.Sub_Status__c
            && oldQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_IN_REVIEW;
            
            if(shouldTransformQL) 
            {
                impactedQuotes.add(currentQuote.Id);
            } else if (oldQuote.SBQQ__Status__c != currentQuote.SBQQ__Status__c &&
                		currentQuote.SBQQ__Status__c == Constants.QUOTE_STATUS_SIGNED) {
                signedOpportunityIds.add(currentQuote.SBQQ__Opportunity2__c);
            }
        }
        /**
         * Execute all post quote processing actions. 
         */
        public override void execute() {
            //SFTG-1956 Do not run Acceptance Checklist for StudyAbroad and Exchange opportunities
            for (SBQQ__QuoteLine__c saeQuoteLines : [SELECT SBQQ__Quote__r.SBQQ__Opportunity2__c 
                                    FROM SBQQ__QuoteLine__c 
                                    WHERE SBQQ__Quote__c IN :newQuotes.keyset() 
                                    AND Application_Course_Preference__r.Application__r.Type_of_study__c IN (:Constants.STUDYTYPE_STUDYABROAD, :Constants.STUDYTYPE_EXCHANGE)]) {
                signedOpportunityIds.remove(saeQuoteLines.SBQQ__Quote__r.SBQQ__Opportunity2__c);
            }
            List<SBQQ__QuoteLine__c> gcoQL = [SELECT SBQQ__Quote__r.SBQQ__Opportunity2__c 
                                    FROM SBQQ__QuoteLine__c 
                                    WHERE SBQQ__Quote__c IN :newQuotes.keyset() 
                                    AND Application_Course_Preference__r.Outcome_Status_Value__c='OFFER-G-CO'];
            if (impactedQuotes.isEmpty() == false) QuoteLineService.processPublishedQuoteLines(impactedQuotes);
            if(!signedOpportunityIds.isEmpty() && skipDocumentCheckList != true) DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(signedOpportunityIds);
            if (checkForUsersQuotes.isEmpty() == false && lockUserCreation == false && gcoQL.size()==0) System.enqueueJob(new EnableCCUsersForOfferAcceptance(checkForUsersQuotes, contactIds));
            //Send email to applicants who already have my.app access  
            if (contactQuoteMap.isEmpty() == false && lockUserCreation == false) QuoteService.sendPublishEmailToApplicant(contactQuoteMap);  
            if (contactIdForPublishedQuotes.isEmpty() == false && lockUserCreation == false)QuoteService.assignCCUserPermSet(publishedQuotes.values(),contactIdForPublishedQuotes);
            if (publishedQuotes.isEmpty() == false) new QuoteLineService.QuotePublishHandler(publishedQuotes.keySet()).run().finalise();
        }    
    }
    /**
     * This class record a offer log for any update on Error Log field
     */
    public class OfferLogHandler extends TriggerAbstract{
        public Offer_Log__c[] logs;
        /**
         * Process all records in trigger context
         * @param  rec    new record
         * @param  oldRec old record
         */
        public override void process(SObject rec, SObject oldRec) {
            SBQQ__Quote__c currentQuote = (SBQQ__Quote__c) rec;
            SBQQ__Quote__c oldQuote = (SBQQ__Quote__c)oldRec;
             
            if (currentQuote.SBQQ__Opportunity2__c != null && currentQuote.Error_Log__c != null && currentQuote.Error_Log__c != oldQuote.Error_Log__c) {
                this.records.add(currentQuote);
            } 
        }
        /**
         * Execute all post quote processing actions. 
         */
        public override void execute() {
            this.logs = new Offer_Log__c[0];
            for (SBQQ__Quote__c q : (SBQQ__Quote__c[]) this.records){
                this.logs.add(
                    new Offer_Log__c(
                        Opportunity__c = q.SBQQ__Opportunity2__c,
                        Quote__c = q.Id,
                        Type__c = 'ERROR',
                        Message__c = q.Error_Log__c
                    )
                );
            }
            insert this.logs;
        }    
    }
    /**
     * This class syncs the Quote Line items to Opportunity, after CPQ calculations 
     */
    public class QuoteOpptySync extends TriggerAbstract{
        public List<OpportunityLineItem> syncedOpptyLineItems;
        /**
         * Process all records in trigger context
         * @param  rec    new record
         * @param  oldRec old record
         */
        public override void process(SObject rec, SObject oldRec) {
            SBQQ__Quote__c currentQuote = (SBQQ__Quote__c) rec;
            SBQQ__Quote__c oldQuote = (SBQQ__Quote__c)oldRec;
            // Check whether CPQ calculate is completed
            if (String.isNotBlank(currentQuote.Sub_Status__c) 
                && String.isNotBlank(oldQuote.Sub_Status__c) 
                && currentQuote.Sub_Status__c.equalsIgnoreCase(Constants.QUOTE_PRICE_CALCULATED) 
                && !oldQuote.Sub_Status__c.equalsIgnoreCase(currentQuote.Sub_Status__c)) {
                    this.records.add(currentQuote);
            }
        }
        /**
         * Execute all post quote processing actions. 
         */
        public override void execute() {
            this.syncedOpptyLineItems = new List<OpportunityLineItem> ();
            for (SBQQ__Quote__c q : (SBQQ__Quote__c[]) this.records){
                syncedOpptyLineItems.addAll(QuoteLineService.syncQuoteAndOpptyLineItems(null, q.id));
            }
            if (!syncedOpptyLineItems.isEmpty()){
                upsert syncedOpptyLineItems;
            }
        }    
    }

    /**
     * This class send the Graduate research scholarship offers to callista when its accepted or rejected 
     */
    public class GRScholarshipOfferResponseSync extends TriggerAbstract{
        public Set<String> quoteIds = new Set<String>();
        /**
         * Process all records in trigger context
         * @param  rec    new record
         * @param  oldRec old record
         */
        public override void process(SObject rec, SObject oldRec) {
            SBQQ__Quote__c currentQuote = (SBQQ__Quote__c) rec;
            SBQQ__Quote__c oldQuote = (SBQQ__Quote__c)oldRec;
            // Check whether CPQ calculate is completed
            if (String.isNotBlank(currentQuote.SBQQ__Status__c) 
                && currentQuote.SBQQ__Opportunity2__c != null
                && oldQuote.SBQQ__Status__c != currentQuote.SBQQ__Status__c
                && currentQuote.Is_GR_Offer__c
                && (currentQuote.SBQQ__Status__c == 'Accepted' || currentQuote.SBQQ__Status__c == 'Declined')) {
                    quoteIds.add(currentQuote.Id);
            } 
            //clearning the Decline_Reason__c when the status changed from rejected to something else
            if(Trigger.isBefore 
                && oldQuote.SBQQ__Status__c == 'Declined' 
                && oldQuote.SBQQ__Status__c != currentQuote.SBQQ__Status__c
                && currentQuote.Is_GR_Offer__c) {
                currentQuote.Decline_Reason__c = '';
            }
        }
        /**
         * Execute all post quote processing actions. 
         */
        public override void execute() {
            List<Opportunity> grOpportunities = new List<Opportunity>();
            //capture the opportunities for accepted and rejected offers
            
            for(SBQQ__Quote__c quote : new QuotesSelector().selectQuoteAndLineItemsById(quoteIds)) {
                if(quote.SBQQ__Status__c == 'Accepted') {
                    grOpportunities.add(closeOpportunity(quote.SBQQ__Opportunity2__c, 'Closed Won', 'Signed the offer'));
                    //trigger the Async platform event to send to callista
                    EventBus.publish(GRScholarshipOfferResponseService.formAsyncPayload(
                        quote.Id,
                        quote.SBQQ__Opportunity2__r.Application_Course_Preference__r?.GradRes_Callista_Id__c,
                        quote.SBQQ__Opportunity2__r.Application_Course_Preference__r?.Callista_Applicant_Id__c,
                        'OFFERED',
                        'ACCEPTED',
                        null,
                        null
                    ));
                } else if(quote.SBQQ__Status__c == 'Declined') {
                    grOpportunities.add(closeOpportunity(quote.SBQQ__Opportunity2__c, 'Canceled/Rejected', 'Declined the offer'));
                    //trigger the Async platform event to send to callista
                    EventBus.publish(GRScholarshipOfferResponseService.formAsyncPayload(
                        quote.Id,
                        quote.SBQQ__Opportunity2__r.Application_Course_Preference__r?.GradRes_Callista_Id__c,
                        quote.SBQQ__Opportunity2__r.Application_Course_Preference__r?.Callista_Applicant_Id__c,
                        'OFFERED',
                        'DECLINED',
                        quote.Decline_Reason__c,
                        null
                    ));
                }
            }
            //close the opportunities 
            if(!grOpportunities.isEmpty()) {
                update grOpportunities;
            }
        } 

        /**
         * form the Opportunity related to quote with stage closed and closed reason. 
         */
        private Opportunity closeOpportunity(Id oppId, String stageName, String reason) {
            Opportunity opp = new Opportunity(Id = oppId);
            opp.StageName = stageName;
            opp.Closed_Reason_Details__c = reason;
            return opp;
        }
    }
}