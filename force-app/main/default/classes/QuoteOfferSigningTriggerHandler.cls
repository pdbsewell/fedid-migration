/**
 * @description Trigger handler to start the process to get a signing URL when 
 * the user has acknowledged and the document has been generated
 * @group Offers
 */
public inherited sharing class QuoteOfferSigningTriggerHandler 
        extends TriggerAbstract {
    
    @testVisible
    private Dao quoteDao;

    @testVisible
    private QuotesSelector quotesSelector;

    @testVisible
    private OffersDocuSignCreateSignatureHandler initialCreateSignatureHandler;

    public QuoteOfferSigningTriggerHandler() {
        this.quoteDao = new SObjectDao();
        this.quotesSelector = new QuotesSelector();
        this.initialCreateSignatureHandler = new OffersSignatureRequiredHandler();
    }

    public override void process(SObject rec, SObject oldRec) {

        SBQQ__Quote__c oldQuote = (SBQQ__Quote__c) oldRec;
        SBQQ__Quote__c newQuote = (SBQQ__Quote__c) rec;

        /*
        Check the following:
        1. acknowledgement = true
        2. primary document not blank
        3. acknowledgement and/or primary document has changed
        */

        if ((oldQuote.Primary_Document__c != newQuote.Primary_Document__c || 
                oldQuote.Acknowledged_by_applicant__c 
                != newQuote.Acknowledged_by_applicant__c) && 
                (String.isNotBlank(newQuote.Primary_Document__c) && 
                newQuote.Acknowledged_by_applicant__c)) {
            records.add(newQuote);
        }
    }

    public override void execute() {

        if (!records.isEmpty()) {

            // Only the first record is supported
            // There are limits on the number of queueable jobs executed per 
            // transactions so this operation will fail regardless of whether 
            // it is bulkified
            if (records.size() > 1) {
                throw new UnsupportedOperationException(
                    'Bulk operation is not supported for generating signing URLs'
                );
            }

            Queueable quoteSigningUrlGenerationQueueable = 
                new QuoteSigningUrlGenerationQueueable(
                    records[0].Id,
                    this.initialCreateSignatureHandler,
                    this.quoteDao,
                    this.quotesSelector
                );
            System.enqueueJob(quoteSigningUrlGenerationQueueable);
        }

    }

}