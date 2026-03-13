/**
 * @description The handler which invokes offers actions when the offer has been 
 * signed from the platform event notification.
 * @group Offers Signed Trigger Handler
 */
public inherited sharing class OffersEnvelopSignedEventTrigHandler 
        extends TriggerAbstract {
    
    private final String QUOTE_SIGNED_STATUS = 'Signed';

    @testVisible
    private QuotesSelector quotesSelector;

    @testVisible
    private Dao quoteDao;

    @testVisible
    private Dao opportunityDao;

    public OffersEnvelopSignedEventTrigHandler() {
        // probably need to move to constructor for trigger testing
        this.quotesSelector = new QuotesSelector();
        this.quoteDao = new SObjectDao();
        this.opportunityDao = new SObjectDao();
    }

    /**
     * @description Filter out record for update
     * @param rec New record to evaluate
     */
    public override void process(SObject rec){
        // platform event is already specific enough to not have to do anymore 
        // filtering
        records.add(rec);
    }

    /**
     * @description Updates relevant quotes statuses to signed
     */
    public override void execute(){
        try {
            this.updateRelatedQuotesToSigned((Offers_Envelop_Signed_Event__e[])records);
        } catch (Exception e) {
            LogUtilityException.logException(e);
        }

    }

    private void updateRelatedQuotesToSigned(List<Offers_Envelop_Signed_Event__e> envelopsSignedEvent) {

        List<SBQQ__Quote__c> quotesIdentified = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quotesToBeUpdated = new List<SBQQ__Quote__c>();
        Set<String> envelopIds = new Set<String>();

        // Find all quotes with envelops signed
        for (Offers_Envelop_Signed_Event__e envelopSignedEvent : envelopsSignedEvent) {

            String envelopId = envelopSignedEvent.Envelop_Id__c;
            
            // making this lowercase as the create envelop API returns the 
            // envelop in lowercase and this is stored on the quote as 
            // lowercase. However DocuSign connect creates records with envelop 
            // id in uppercase and this can result in mismatch when trying to 
            // query quote based on envelop id
            envelopIds.add(envelopId.toLowerCase());
        }

        quotesIdentified.addAll(this.quotesSelector
                .selectQuotesByPrimaryDocuSignEnvelopId(envelopIds));

        // update all quotes status to Signed
        for (SBQQ__Quote__c quoteIdentified : quotesIdentified) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteIdentified.Id);
            quote.SBQQ__Status__c = QUOTE_SIGNED_STATUS;
            quote.Sub_Status__c = Constants.QUOTE_SUBSTATUS_OFFER_SIGNED_AND_LOCKED;
            quotesToBeUpdated.add(quote);
        }
        SBQQ.TriggerControl.disable();
        
        this.quoteDao.updateRecords(quotesToBeUpdated);

        // After Quote is quoted, the parent opportunity needs to be updated 
        // to reflect the updates in Quote
        updateParentOpportunities(quotesIdentified);
        
        SBQQ.TriggerControl.enable();    

    }

    private void updateParentOpportunities(List<SBQQ__Quote__c> quotes) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (SBQQ__Quote__c quote : quotes) {
            opportunitiesToUpdate.add(
                new Opportunity(
                    id = quote.SBQQ__Opportunity2__c,
                    StageName = Constants.OPPTY_STATUS_SIGNED, 
                    Closed_from_Quote__c = true)
                );
        }
        this.opportunityDao.updateRecords(opportunitiesToUpdate);
    }
}