/**
* @author Jasmin Joy Rudio
* @description SBQQ__QuoteLine__c object service class
* @group SF Offers
*
**/
public with sharing class QuoteLineService {
    /********CONSTRUCTORS**********/            
    public QuoteLineService() {}
    

    /**
    * @description update the expiry date on the quote lines corresponding to grant/scholarship (when a quote is published)
    * @param quoteIdSet - Id of the quote records getting published.
    * @param prodFamilyList - The product familes corresponding to grant/scholarship 
    * @return void
    **/   
    public static void setQuoteLineExpiry (set<Id> quoteIdSet, List<String>prodFamilyList){
        List<SBQQ__QuoteLine__c> quoteLines = new QuoteLinesSelector().selectByQuoteIdAndProductFamily(quoteIdSet,prodFamilyList);
        if(!quoteLines.IsEmpty()){
            for(SBQQ__QuoteLine__c ql : quoteLines){
                if(ql.SBQQ__Product__r.Expiry_days__c != NULL){
                    ql.Expiry_Date__c = Date.today().addDays(ql.SBQQ__Product__r.Expiry_days__c.intValue());
                }
            }
        }
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();
        update quoteLines;
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
    }
    
    /**
    * @description get list of Quote line record filter by parent Quote id paramater
    * @param offerId - parent SBQQ__Quote__c id
    * @return a list of SBQQ__QuoteLine__c
    **/    
    //@AuraEnabled(cacheable=true)
    public static List<SBQQ__QuoteLine__c> getQuoteLineList(String offerId){
        System.debug('** offerId: ' + offerId);
        Id quoteId = Id.valueOf(offerId);
        List<SBQQ__QuoteLine__c> quoteLines = new QuoteLinesSelector().selectByIdWithQuoteLines(new Set<Id>{quoteId});
        System.debug('** getQuoteLineList: ' + quoteLines);
        return quoteLines;
        
    }

    /**
    * @description return List of Quote Line Bundles with primary quote line items
    * @param offerId - parent SBQQ__Quote__c id
    * @return a list of SBQQ__QuoteLine__c
    **/       
    //@AuraEnabled(cacheable=true)
    public static List<SBQQ__QuoteLine__c> getQuoteLineBundles(String offerId){
        List<SBQQ__QuoteLine__c> quoteLines = new QuoteLinesSelector().selectBundleByQuoteId(new Set<String>{offerId});
        return quoteLines;
        
    }
    /**
    * @description get list of Quote line record filter by parent Quote id paramater
    * @param offerId - parent SBQQ__Quote__c id
    * @return a list of SBQQ__QuoteLine__c
    **/    
    //@AuraEnabled(cacheable=true)
    public static List<SBQQ__QuoteLine__c> selectByIdHiddenPricing(String offerId){
        Id quoteId = Id.valueOf(offerId);
        List<SBQQ__QuoteLine__c> quoteLines = new QuoteLinesSelector().selectByIdHiddenPricing(new Set<Id>{quoteId});
        return quoteLines;
        
    }
    /**
     * processPublishedQuoteLines This method 
     * @param  quoteIds quoteIds description
     */
    @namespaceAccessible
    public static void processPublishedQuoteLines(Set<Id> quoteIds)
    {
        List<SBQQ__QuoteLine__c> quoteLines = new QuoteLinesSelector().getBundlesForQuote(quoteIds);
        Map<Id,SBQQ__QuoteLine__c> quoteLinesToUpdate = new Map<Id,SBQQ__QuoteLine__c>();

        // Herman 2020-01-10
        // list to capture quotes with technical errors
        List<SBQQ__Quote__c> quotesWithErrors = new List<SBQQ__Quote__c>();
        List<Opportunity> opps = new List<Opportunity>();
        

        for(SBQQ__QuoteLine__c bundle : quoteLines)
        {
            try{
                string bundleCode = ((SBQQ__QuoteLine__c)bundle).SBQQ__Product__r.Document_Generation_Spec__c;
                string methodName = 'publishQuote';
                // TODO: refactor to use Type.forName()
                if(bundleCode == 'EnglishOfferSpecification') {
                    new EnglishOfferSpecification().run(bundle,quoteLines,quoteLinesToUpdate);
                } else if(bundleCode == 'OfferSpecification') {
                    new OfferSpecification().run(bundle,quoteLines,quoteLinesToUpdate);
                } else if(bundleCode == 'DiplomaOfferSpecification')
                {
                    new DiplomaOfferSpecification().run(bundle,quoteLines,quoteLinesToUpdate);
                } else {
                    continue;
                }    
            }catch(Exception err){ //log event for unexpected exception
				quotesWithErrors.add(QuoteService.sendQuoteToTechQueue(bundle.SBQQ__Quote__c, 'Technical error transforming quote line. ' + err.getMessage() + ' ' + err.getLineNumber()));
                opps.add(OpportunityService.updateOpptyForSpecialistReview(bundle.SBQQ__Quote__r.SBQQ__Opportunity2__c));
            }
        }
        update opps;
        update quoteLinesToUpdate.values();
        SBQQ.TriggerControl.disable();
        update quotesWithErrors;
        SBQQ.TriggerControl.enable();
    }
    /**
     * isCourseProduct This methods returns true if the quote line product family is a course
     * @param  ql ql quote line which is tested
     * @return    return boolean true/false
     */
    private static boolean isCourseProduct(SBQQ__QuoteLine__c ql)
    {
        return !String.isBlank(ql.SBQQ__ProductFamily__c) 
        && Constants.COURSE_PRODUCTS.contains(ql.SBQQ__ProductFamily__c);
    }
    
    public virtual class OfferSpecification
    {
        /**
         * call This implements callable interface, manipulates quote line bundles for quote document presentation purposes
         * @param  bundle Quote Line which requires transformation.
         * @param  children full List of quote lines on the quote
         * @param  impactedQuotes   list of quotes which require update
         * @return void
         */
        
        public virtual void run(SBQQ__QuoteLine__c bundle,  List<SBQQ__QuoteLine__c> children, Map<Id,SBQQ__QuoteLine__c> impactedQuotes)
        {
            for( SBQQ__QuoteLine__c childLine  : children ){
                if(childLine.Id == bundle.Id){
                    continue;
                }
            
				if(QuoteLineService.isCourseProduct(childLine) && bundle.Id == childLine.SBQQ__RequiredBy__c){
                    bundle.Offer_Primary_Quote_Line__c = childLine.Id;
                    impactedQuotes.put(bundle.Id, bundle);
                    break;
                }
            }
            if(bundle.Offer_Primary_Quote_Line__c == null){
                throw new LogUtilityException('Bundle without course');
            }
            return;
        }
    }
            
    public virtual class EnglishOfferSpecification extends OfferSpecification
    {
        /**
         * call This implements callable interface, manipulates quote line bundles for quote document presentation purposes
         * @param  bundle Quote Line which requires transformation.
         * @param  children full List of quote lines on the quote
         * @param  impactedQuotes   list of quotes which require update
         * @return void
         */
        public override void run(SBQQ__QuoteLine__c bundle,  List<SBQQ__QuoteLine__c> children, Map<Id,SBQQ__QuoteLine__c> impactedQuotes)
        {
            super.run(bundle, children, impactedQuotes);

            bundle.Admin_Fee__c = 0;
            for( SBQQ__QuoteLine__c childLine  : children ){
				if(childLine.SBQQ__ProductFamily__c == 'Admin Fee' && bundle.Id == childLine.SBQQ__RequiredBy__c){
                    bundle.Admin_Fee__c += childLine.SBQQ__NetTotal__c;
               }
            }
            if(bundle.Offer_Primary_Quote_Line__c == null){
                throw new LogUtilityException('Bundle without course');
            }
            return;
        }
    }

    public virtual class DiplomaOfferSpecification extends  OfferSpecification
    {
        /**
         * call This implements callable interface, manipulates quote line bundles for quote document presentation purposes
         * @param  bundle Quote Line which requires transformation.
         * @param  children full List of quote lines on the quote
         * @param  impactedQuotes   list of quotes which require update
         * @return void
         */

        public override void run(SBQQ__QuoteLine__c bundle, List<SBQQ__QuoteLine__c> children, Map<Id,SBQQ__QuoteLine__c> impactedQuotes)
        {
            super.run(bundle, children, impactedQuotes);
            
            SBQQ__QuoteLine__c primaryDiplomaLine = null;
            SBQQ__QuoteLine__c secondaryDiplomaLine = null;
            for( SBQQ__QuoteLine__c childLine  : children ){
				if(QuoteLineService.isCourseProduct(childLine)) {
                    if( QuoteLineService.isCourseProduct(childLine) &&  bundle.Id == childLine.SBQQ__RequiredBy__c ) {
                        bundle.Offer_Primary_Quote_Line__c = childLine.Id;
                        primaryDiplomaLine = childLine;
                        // Diploma Part 1 => should be already linked via super call
                    } else if(QuoteLineService.isCourseProduct(childLine) && primaryDiplomaLine != null  && primaryDiplomaLine.Id == childLine.SBQQ__RequiredBy__c) {
                        bundle.Offer_Option_Quote_Line__c = childLine.Id;
                        secondaryDiplomaLine = childLine; // Diploma Part 2      
                    } 
                }
                if(bundle.Offer_Primary_Quote_Line__c == null) {
                    throw new LogUtilityException('Bundle without course.');
                }            
            }

            if (secondaryDiplomaLine == null) {
                throw new LogUtilityException('The course, product, or course fee for Diploma part 2 is missing in UniCRM. Please contact your Salesforce or Callista Specialist.');
            }

            // roll up totals to the bundle. Cannot access the SBQQ__PackaListTotal__c in this context ()
            bundle.Total_Tuition_Fee__c = ((primaryDiplomaLine.SBQQ__ListTotal__c != null) ? primaryDiplomaLine.SBQQ__ListTotal__c : 0)+((secondaryDiplomaLine.SBQQ__ListTotal__c != null) ? secondaryDiplomaLine.SBQQ__ListTotal__c : 0);
            bundle.CreditPoints__c = ((primaryDiplomaLine.CreditPoints__c != null) ? primaryDiplomaLine.CreditPoints__c : 0)+((secondaryDiplomaLine.CreditPoints__c != null) ? secondaryDiplomaLine.CreditPoints__c : 0);
            bundle.Net_Total_Tuition_Fee__c = ((primaryDiplomaLine.SBQQ__SpecialPrice__c != null) ? primaryDiplomaLine.SBQQ__SpecialPrice__c : 0)+((secondaryDiplomaLine.SBQQ__SpecialPrice__c != null) ? secondaryDiplomaLine.SBQQ__SpecialPrice__c : 0);
            // roll up the RPL / special price to the diploma part-1 nested bundle
            primaryDiplomaLine.Net_Total_Tuition_Fee__c =  bundle.Net_Total_Tuition_Fee__c;

            impactedQuotes.put(primaryDiplomaLine.Id, primaryDiplomaLine);
        }

    }

    public class QuotePublishHandler{
        public Set<ID> quoteIds;
        public QuoteLinesSelector selector;
        public SBQQ__QuoteLine__c[] quoteLines;
        public QuotePublishHandler(Set<ID> quoteIds){
            this.quoteIds = quoteIds;
            this.selector = new QuoteLinesSelector();
        }
        public QuotePublishHandler run(){
            this.quoteLines = this.selector.selectByIdWithQuoteLines(quoteIds);

            for(SBQQ__QuoteLine__c ql : this.quoteLines){
                ql.Published__c = true;
            }
            return this;
        }
        public void finalise(){
            TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
            TriggerCommon.disableTrigger('SBQQ__Quote__c');
            SBQQ.TriggerControl.disable();
            update this.quoteLines;
            TriggerCommon.enableTrigger('SBQQ__QuoteLine__c');
            TriggerCommon.enableTrigger('SBQQ__Quote__c');
            SBQQ.TriggerControl.enable();
        }
    }

    /**
    * @description Method to sync opportunity line items with a Quote's line items; excludes Bundle and optional items
    * @author Vinothraja
    * @return List<OpportunityLineItem> Returns the synced opportunity line items for further processing 
    * @params oppID - Id of the Opportunity to be synced, if left null, quote's Opportunity will be used for sync
    * quoteID - Id of the Quote whose LineItems to be considered as source; if left null, Opportunity's Primary Quote will be used for sync
    */        
    public static List<OpportunityLineItem> syncQuoteAndOpptyLineItems(String oppID, String quoteId){
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem> ();
        if (!(String.isBlank(oppID) && String.isBlank(quoteId))) {
            // if oppID is null, Quote's Opportunity will be used for sync
            if (String.isBlank(oppID)) {
                oppID = [SELECT SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE id = :quoteId]?.SBQQ__Opportunity2__c;
            }
            // Fetching ALL the Opportunity's Line Items
            List<Opportunity> lstOppty = [SELECT SBQQ__PrimaryQuote__c, 
                                                (SELECT Product2Id, ProductCode, Application_Course_Preference__c, UnitPrice
                                                    FROM OpportunityLineItems)
                                            FROM Opportunity 
                                            WHERE id = :oppID]; 
            if (lstOppty != null && lstOppty.size() >0){
                // if quoteId is null, Opportunity's Primary Quote will be used for sync
                if (String.isBlank(quoteId)) {
                    quoteId = lstOppty[0].SBQQ__PrimaryQuote__c;
                }
                Map<Id,OpportunityLineItem> mapOpptyProducts = new Map<Id,OpportunityLineItem> ();

                for (OpportunityLineItem oli: lstOppty[0].OpportunityLineItems) {
                    mapOpptyProducts.put(oli.Product2Id, oli);
                }
                for (SBQQ__QuoteLine__c qli :  [SELECT id, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__ProductFamily__c, Application_Course_Preference__c, SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__Quantity__c, SBQQ__PricebookEntryId__c, Expiry_Date__c  
                                                    FROM SBQQ__QuoteLine__c 
                                                    WHERE SBQQ__Quote__c = :quoteId
                                                    AND SBQQ__ProductFamily__c <> 'Bundle' // Bundles are exluded from sync
                                                    AND SBQQ__ProductCode__c <> 'BUNHEALTH' // OSHC is excluded from sync
                                                    AND SBQQ__Quantity__c <> 0 // Line items with zero quantity are excluded from sync
                                                    AND SBQQ__Optional__c = false]) { 
                    // STEP 1: Check if Product already exists in Opportunity Products
                    if (mapOpptyProducts.containsKey(qli.SBQQ__Product__c)) {
                        OpportunityLineItem updatableOli = mapOpptyProducts.get(qli.SBQQ__Product__c);
                        // STEP 1a: If Opportunity Product exists but is of a different PRICE, update the price
                        if (updatableOli.UnitPrice != qli.SBQQ__NetPrice__c) {
                            updatableOli.UnitPrice = qli.SBQQ__NetPrice__c;
                            oppLineList.add(updatableOli); 
                        }
                        mapOpptyProducts.remove(qli.SBQQ__Product__c);
                    // STEP 2: If Opportunity Product does not exist, create a new one
                    } else {
                        OpportunityLineItem addOli = new OpportunityLineItem();
                        addOli.OpportunityId = oppID;
                        addOli.Quantity = qli.SBQQ__Quantity__c;
                        addOli.Product2Id = qli.SBQQ__Product__c;
                        addOli.PricebookEntryId = qli.SBQQ__PricebookEntryId__c;
                        addOli.UnitPrice = qli.SBQQ__NetPrice__c == null ? 0 : qli.SBQQ__NetPrice__c;
                        addOli.Application_Course_Preference__c = qli.Application_Course_Preference__c;
                        addOli.Expiry_Date__c = qli.Expiry_Date__c;
                        
                        oppLineList.add(addOli); 
                    }
                }
            }
        }
        return oppLineList;         
    } 
}