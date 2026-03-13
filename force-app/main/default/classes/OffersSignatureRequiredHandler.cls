/**
 * @description Handler to check if signing is required for Offers/Quotes
 * @group Offers DocuSign Signature
 */
public inherited sharing class OffersSignatureRequiredHandler implements OffersDocuSignCreateSignatureHandler {
    
    private final String QUOTE_PUBLISHED_STATUS = 'Published';
    
    private final String QUOTE_READY_FOR_ACKNOW_SUB_STATUS = 'Ready for acknowledgement';

    @testVisible
    private boolean isSignatureRequired;

    @testVisible 
    private OffersDocuSignCreateSignatureHandler nextHandler;

    @testVisible
    private QuotesSelector quotesSelector;

    public OffersSignatureRequiredHandler() {
        this.quotesSelector = new QuotesSelector();
        this.isSignatureRequired = false;
        this.nextHandler = new OffersSignersRequiredHandler();
    }

    /**
     * @description Handler which checks if the quote is in a state to 
     * be sent off to DocuSign for signing. 
     * If the quote should not be sent for signing, nothing will happen (void).
     */
    public void handle(OffersDocuSignCreateSignReqContext context) {

        SBQQ__Quote__c quote = quotesSelector.selectQuoteById(new Set<String>{String.valueOf(context.getQuoteId())})[0];

        if (QUOTE_PUBLISHED_STATUS.equals(quote.SBQQ__Status__c) 
                && quote.Acknowledged_by_applicant__c) {
            this.isSignatureRequired = true;
            this.nextHandler.handle(context);
        }
    }
}