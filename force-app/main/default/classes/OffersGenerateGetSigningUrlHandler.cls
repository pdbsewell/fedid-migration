/**
 * @description Handler to construct and perform the callout to DocuSign
 * to generate the signing URL and store it
 * @group Offers DocuSign Signature
 */
public inherited sharing class OffersGenerateGetSigningUrlHandler implements OffersDocuSignCreateSignatureHandler {
    
    @testVisible
    private DocuSignGetSigningUrlRequest docuSignGetSigningUrlRequest;

    @testVisible
    private QuotesSelector quotesSelector;

    @testVisible
    private Dao quoteDao;

    private OffersDocuSignSigningUrlConfig signingUrlConfig;

    public OffersGenerateGetSigningUrlHandler() {
        this.DocuSignGetSigningUrlRequest = new DocuSignGetSigningUrlRestApiRequest();
        this.quotesSelector = new QuotesSelector();
        this.quoteDao = new SObjectDao();
        this.signingUrlConfig = new OffersDocuSignSigningUrlConfig();
    }

    /**
     * @description Handler which will make the Get Signing URL request 
     * to DocuSign.
     * The applicant is expected to sign using DocuSign's embedded flow
     * @param context Context for the handler. This method expects the context's
     * envelop Id to be provided
     */
    public void handle(OffersDocuSignCreateSignReqContext context) {

        List<SBQQ__Quote__c> quotesIdentifiedWithOffer = quotesSelector.selectQuoteById(new Set<String>{ String.valueOf(context.getQuoteId())});
        if (quotesIdentifiedWithOffer.isEmpty()) {
            throw new QueryException('Quote was not found.');
        }
        SBQQ__Quote__c quote = quotesIdentifiedWithOffer[0];

        String applicantState = OffersDocusignReturnUrlState.applicantState(
            quote.SBQQ__PrimaryContact__r.Under_18__c,
            quote.Guardian_has_Email_Address__c
        );
        DocuSignGetSigningUrlRequestBody requestBody = 
            new OffersDocuSignGetSignUrlReqBodBuild(
                context.getApplicantSigner().getEmail(),
                context.getApplicantSigner().getName() )
            .setRecipientId(1)
            .setClientUserId(context.getApplicantSigner().getUserId())
            .setReturnUrl(this.signingUrlConfig.getDocuSignReturnUrl()+'?applicantState='+applicantState)
            .getResult();

        String signingUrl = this.docuSignGetSigningUrlRequest.getSigningUrl(
        context.getDocuSignAccountId(), context.getEnvelopId(), requestBody);
    
        quote.Primary_DocuSign_Envelop_Id__c = context.getEnvelopId();
        quote.DocuSign_Signing_URL_Created__c = DateTime.now();
        quote.DocuSign_Signing_URL__c = signingUrl;
        quote.Sub_Status__c = 'Pending signature in Docusign';

        this.quoteDao.updateRecords(new List<SBQQ__Quote__c> {quote});
        
        System.debug('Signing URL: ' + signingUrl);
    }
    
}