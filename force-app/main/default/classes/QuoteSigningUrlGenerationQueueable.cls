/**
 * @description Queueable that starts asynchronous the process for generating a 
 * DocuSign Signing URL for offers 
 * @group Offers
 */
public inherited sharing class QuoteSigningUrlGenerationQueueable 
        implements Queueable, Database.AllowsCallouts {
    
    private Id quoteId;
    private OffersDocuSignCreateSignatureHandler createSignatureHandler;
    private Dao quoteDao;
    private QuotesSelector quotesSelector;

    /**
     * @description Constructor to set the quote and related dependencies
     * @param quoteId The Id of the quote where the signing URL should be 
     * generated for
     * @param createSignatureHandler The handler that starts of the create 
     * signature process
     * @param quoteDao The data access object for quote data operations
     * @param quotesSelector The quote selector for querying quote
     */
    public QuoteSigningUrlGenerationQueueable(Id quoteId, 
            OffersDocuSignCreateSignatureHandler createSignatureHandler,
            Dao quoteDao, QuotesSelector quotesSelector) {
        // although 4 parameters is a bit long, its a bit overkill to use an 
        // abstract factory or other techniques to reduce the number of 
        // parameters for this class
        this.quoteId = quoteId;
        this.createSignatureHandler = createSignatureHandler;
        this.quoteDao = quoteDao;
        this.quotesSelector = quotesSelector;
    }

    /**
     * @description Executes the process to generate a signing URL
     * Any exceptions are handled by updating the quote to error status
     */
    public void execute(QueueableContext context) {

        try {

            OffersDocuSignCreateSignReqContext signContext = 
                new OffersDocuSignCreateSignReqContext(this.quoteId);

            // The first handler will decide 
            // the next actions
            this.createSignatureHandler.handle(signContext);

        } catch (Exception e) {
            
            Group[] techQueue = [SELECT Id, Name, Type FROM Group 
                WHERE Type = 'Queue' 
                AND DeveloperName =: Constants.TECHNICAL_OFFER_QUEUE LIMIT 1];
            SBQQ__Quote__c quote =  this.quotesSelector
                .selectQuoteById(new Set<String>{quoteId})[0];
            quote.Sub_Status__c = 'DocuSign error';
            quote.Error_Log__c= e.getMessage() + ', ' + e.getStackTraceString(); 
            quote.OwnerId = techQueue[0].Id;
            this.quoteDao.updateRecords(new List<SBQQ__Quote__c> {quote});
        }
    }

}