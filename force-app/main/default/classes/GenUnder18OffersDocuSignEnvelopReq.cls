/**
 * @description Handler to construct and perform the callout to DocuSign
 * to create a signature (in DocuSign terminology, Envelop) when the 
 * applicant is under 18 years old.
 * @group Offers DocuSign Signature
 */
public class GenUnder18OffersDocuSignEnvelopReq implements OffersDocuSignCreateSignatureHandler {

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

    public GenUnder18OffersDocuSignEnvelopReq() {
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
        emailContent.emailBlurb = generateEmailContent(envelopSetting.emailBlurb, quotesIdentifiedWithOffer[0], offerSetting.Guardian_Sign_Contact_Us_Email_Address__c);

        ContentVersion documentToSign = contentVersionSelector.selectContentVersionById(
        Id.valueOf(quotesIdentifiedWithOffer[0].Primary_Document__c));
        OffersDocuSignCreateEnvReqBodyBuild.Document document = new OffersDocuSignCreateEnvReqBodyBuild.Document();
        document.documentBody = EncodingUtil.base64Encode(documentToSign.VersionData);
        document.documentName = documentToSign.Title;
        document.fileExtension = documentToSign.FileExtension;
        document.documentId = 1;


        OffersDocuSignCreateEnvReqBodyBuild.Recipient applicant = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        applicant.documentId = 1;
        applicant.dateSignedAnchorString = docuSignTabSetting.get('Applicant').dateSignedAnchorString;
        applicant.signHereAnchorString = docuSignTabSetting.get('Applicant').signHereAnchorString;
        applicant.name = context.getApplicantSigner().getName();
        applicant.email = context.getApplicantSigner().getEmail();
        applicant.clientUserId = context.getQuoteId();
        applicant.recipientId = '1';
        applicant.routingOrder = Integer.valueOf(docuSignTabSetting.get('Applicant').routingOrder);

        OffersDocuSignCreateEnvReqBodyBuild.Recipient guardian = new OffersDocuSignCreateEnvReqBodyBuild.Recipient();
        guardian.documentId = 1;
        guardian.dateSignedAnchorString = 
        docuSignTabSetting.get('Guardian').dateSignedAnchorString;
        guardian.signHereAnchorString = 
        docuSignTabSetting.get('Guardian').signHereAnchorString;
        guardian.name = context.getGuardianSigner().getName();
        guardian.email = context.getGuardianSigner().getEmail();
        guardian.recipientId = '2';
        guardian.routingOrder = Integer.valueOf(docuSignTabSetting.get('Guardian').routingOrder);

        OffersDocuSignCreateEnvReqBodyBuild builder = new OffersDocuSignCreateEnvReqBodyBuild();
        DocuSignCreateEnvelopsReqBody reqBody = builder
            .setEmailDetails(emailContent)
            .setBrandId(offerSetting.DocuSign_Brand_Id__c)
            .setReminder(constructReminder(envelopSetting))
            .addDocument(document)
            .addRecipient(applicant)
            .addRecipient(guardian)
            .getResult();

        docuSignCreateEnvelopsRequest.createEnvelop(
        this.docuSignAuthSetting.getAccountId(), reqBody);
        context.setDocuSignAccountId(this.docuSignAuthSetting.getAccountId()); 
        context.setEnvelopId(docuSignCreateEnvelopsRequest.getEnvelopId());       
        this.nextHandler.handle(context);
    }

    private String generateEmailContent(String template, 
        SBQQ__Quote__c quote, String contactUsEmail) {
        StringTemplate stringTemplate = new StringTemplate(template);
        stringTemplate.substitute('applicantName', quote.Contact_Firstname__c + ' ' + quote.Contact_Lastname__c);
        Date expiryDate = quote.Calculated_Expiry_Date__c;
        String expiryYear = String.valueOf(expiryDate.year());
        String expiryMonth = String.valueOf(expiryDate.month());
        String expiryDay = String.valueOf(expiryDate.day());

        stringTemplate.substitute('expiryDate', expiryDay + '/' + expiryMonth + '/' + expiryYear);
        stringTemplate.substitute('quoteNumber', quote.Name);
        stringTemplate.substitute('contactUsEmailAddress', contactUsEmail);
        return stringTemplate.render();
    }

    private OffersDocuSignCreateEnvReqBodyBuild.Reminder constructReminder(SystemSettingWrapper.DocusignEnvelopSetting setting) {
        OffersDocuSignCreateEnvReqBodyBuild.Reminder 
        reminder = new OffersDocuSignCreateEnvReqBodyBuild.Reminder();
        reminder.reminderDelay = Integer.valueOf(setting.reminderDelay);
        reminder.reminderEnabled = Boolean.valueOf(setting.reminderEnabled);
        reminder.reminderFrequency = Integer.valueOf(setting.reminderFrequency);
        return reminder;
    }
}