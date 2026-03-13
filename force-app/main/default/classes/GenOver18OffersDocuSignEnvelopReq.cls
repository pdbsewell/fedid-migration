/**
 * @description Handler to construct and perform the callout to DocuSign
 * to create a signature (in DocuSign terminology, Envelop) when the 
 * applicant is over 18 years old.
 * @group Offers DocuSign Signature
 */
public class GenOver18OffersDocuSignEnvelopReq implements OffersDocuSignCreateSignatureHandler {

    @testVisible
    private ContentVersionSelector contentVersionSelector;

    @testVisible
    private QuotesSelector quotesSelector;

    @testVisible
    private OffersDocuSignCreateSignatureHandler nextHandler;

    @testVisible
    private DocuSignCreateEnvelopsRequest docuSignCreateEnvelopsRequest;

    @testVisible
    private DocuSignAuthProviderSetting docuSignAuthSetting;

    private String FEATURE_DOCUSIGN_ENVELOP_SETTING = 'DOCUSIGN_ENVELOP_SETTING';
    private String KEY_OFFERS = 'Offers';
    private String FEATURE_OFFERS = 'DOCUSIGN_TAB_OFFERS';

    public GenOver18OffersDocuSignEnvelopReq() {
        this.contentVersionSelector = new ContentVersionSelector();
        this.quotesSelector = new QuotesSelector();
        this.docuSignCreateEnvelopsRequest = new DocuSignCreateEnvelopRestApiRequest();
        this.nextHandler = new OffersGenerateGetSigningUrlHandler();
        this.docuSignAuthSetting = new DocuSignAuthProviderSetting();
    }

    /**
     * @description Handler which will construct the payload and perform the callout 
     * to create a DocuSign envelop for the applicant
     * The applicant is expected to sign using DocuSign's embedded flow
     * If the quote should not be sent for signing, nothing will happen (void).
     * @param context Context for the handler. This method expects the context's
     * Applicant Signer to have all the applicant details
     */
    public void handle(OffersDocuSignCreateSignReqContext context) {

        List<SBQQ__Quote__c> quotesIdentifiedWithOffer = quotesSelector.selectQuoteById(new Set<String>{ String.valueOf(context.getQuoteId())});
        if (quotesIdentifiedWithOffer.isEmpty() || String.isEmpty(quotesIdentifiedWithOffer[0].Primary_Document__c)) {
            throw new QueryException('Quote was not found or primary document is missing');
        }

        Offer_Setting__c offerSetting = Offer_Setting__c.getOrgDefaults();

        // query Docusign Tabs from SystemSetting Metadata
        Map<String,SystemSettingWrapper.DocusignTab> docuSignTabSetting = CustomMetadataService.getDocusignTabs(FEATURE_OFFERS);

        // query Docusign Envelop Settings from SystemSetting Metadata
        SystemSettingWrapper.DocusignEnvelopSetting envelopSetting =  CustomMetadataService.getDocusignEnvelopSettings(FEATURE_DOCUSIGN_ENVELOP_SETTING, KEY_OFFERS);
        
        OffersDocuSignCreateEnvReqBodyBuild.EmailContent emailContent = new OffersDocuSignCreateEnvReqBodyBuild.EmailContent();
        emailContent.subject = envelopSetting.emailSubject;

        ContentVersion documentToSign = contentVersionSelector.selectContentVersionById(Id.valueOf(quotesIdentifiedWithOffer[0].Primary_Document__c)); // [SELECT Id, VersionData, FileExtension, Title FROM ContentVersion WHERE Id = '0685P0000001wiWQAQ'];
        OffersDocuSignCreateEnvReqBodyBuild.Document document = new OffersDocuSignCreateEnvReqBodyBuild.Document();
        document.documentBody = EncodingUtil.base64Encode(documentToSign.VersionData);
        document.documentName = documentToSign.Title;
        document.fileExtension = documentToSign.FileExtension;
        document.documentId = 1;


        OffersDocuSignCreateEnvReqBodyBuild.Recipient recipient = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        recipient.documentId = 1;
        recipient.dateSignedAnchorString = docuSignTabSetting.get('Applicant').dateSignedAnchorString;
        recipient.signHereAnchorString = docuSignTabSetting.get('Applicant').signHereAnchorString;
        recipient.name = context.getApplicantSigner().getName();
        recipient.email = context.getApplicantSigner().getEmail();
        recipient.clientUserId = context.getApplicantSigner().getUserId();
        recipient.recipientId = '1';
        recipient.routingOrder = Integer.valueOf(docuSignTabSetting.get('Applicant').routingOrder);

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder
            .setBrandId(offerSetting.DocuSign_Brand_Id__c)
            .setEmailDetails(emailContent)
            .addDocument(document)
            .addRecipient(recipient)
            .getResult();

        docuSignCreateEnvelopsRequest.createEnvelop(this.docuSignAuthSetting.getAccountId(), reqBody);
        context.setDocuSignAccountId(this.docuSignAuthSetting.getAccountId()); 
        context.setEnvelopId(docuSignCreateEnvelopsRequest.getEnvelopId());       
        this.nextHandler.handle(context);
    }
}