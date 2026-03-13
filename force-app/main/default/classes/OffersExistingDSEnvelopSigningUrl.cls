/**
 * @description Service for generating Signing URLs for quotes with 
 * existing envelops
 * @group Offers DocuSign Signing URL
 */
public inherited sharing class OffersExistingDSEnvelopSigningUrl {
    
    private QuotesSelector quotesSelector;
    private DocuSignGetSigningUrlRequest docuSignGetSigningUrlRequest;
    private DocuSignAuthProviderSetting docuSignAuthProviderSetting;
    private OffersDocuSignSigningUrlConfig signingUrlConfig;

    /**
     * @description Constructor for setting dependencies
     * @param quotesSelector Quote Selector dependency
     * @param docuSignGetSigningUrlRequest docuSignGetSigningUrlRequest dependency
     */
    public OffersExistingDSEnvelopSigningUrl(QuotesSelector quotesSelector,
            DocuSignGetSigningUrlRequest docuSignGetSigningUrlRequest) {
        this.quotesSelector = quotesSelector;
        this.docuSignGetSigningUrlRequest =  docuSignGetSigningUrlRequest;
        this.DocuSignAuthProviderSetting = new DocuSignAuthProviderSetting();
        this.signingUrlConfig = new OffersDocuSignSigningUrlConfig();
    }

    /**
     * @description Creates and returns a signing url based on the quote. 
     * Assumes an envelop is already create for the quote
     * @param quoteId The quote Id where the Signing URL should be generated for
     * @return Returns the signing url as a String
     */
    public String getSigningUrl(Id quoteId) {
        // NOTE: The signing URL must align with the data sent during the 
        // envelop creation. If the data does not match, DocuSign will return 
        // an error (e.g. the name using the the signing URL request must match 
        // the name provided during envelop creation)

        // get all the required data
        List<SBQQ__Quote__c> quotes = this.quotesSelector.selectQuoteById(
            new Set<String>{String.valueOf(quoteId)}
        );
        SBQQ__Quote__c quote = quotes[0];
        if (!OffersSignersRequiredHandler.validateQuoteDataForSigning(quote) || String.isBlank(quote.Primary_DocuSign_Envelop_Id__c)) {
            throw new IllegalArgumentException('Quote is not valid');
        }

        String applicantState = OffersDocusignReturnUrlState.applicantState(
            quote.SBQQ__PrimaryContact__r.Under_18__c,
            quote.Guardian_has_Email_Address__c
        );

        // build the payload
        DocuSignGetSigningUrlRequestBody requestBody = 
            new OffersDocuSignGetSignUrlReqBodBuild(
                quote.Email__c,
                OffersSignersRequiredHandler.getFullNameNameFromQuote(quote))
            .setRecipientId(1)
            .setClientUserId(String.valueOf(quote.Id))
            .setReturnUrl(this.signingUrlConfig.getDocuSignReturnUrl()+'?applicantState='+applicantState)
            .getResult();

        // make the callout
        return this.docuSignGetSigningUrlRequest.getSigningUrl(
            DocuSignAuthProviderSetting.getAccountId(), 
            quote.Primary_DocuSign_Envelop_Id__c, requestBody);
    }
}