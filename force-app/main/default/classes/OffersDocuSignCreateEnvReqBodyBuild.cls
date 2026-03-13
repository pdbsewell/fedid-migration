/**
 * @description Builder for the DocuSign Create Envelop callout request body
 * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
 * 
 * This builder does not use the composite and inline templates
 * @group Offers DocuSign Signature
 */
public class OffersDocuSignCreateEnvReqBodyBuild {

    @testVisible
    private DocuSignCreateEnvelopsReqBody requestBody;

    /**
     * @description Constructor for DocuSignCreateEnvelopsReqBodyBuilder
     * Sets any default values required for the request body
     */
    public OffersDocuSignCreateEnvReqBodyBuild() {
        this.requestBody = new DocuSignCreateEnvelopsReqBody();
        this.requestBody.status = 'sent';   // don't think there is a use case to use something different
        this.requestBody.recipients = new DocuSignCreateEnvelopsReqBody.EnvelopeRecipients();
        this.requestBody.recipients.signers = new List<DocuSignCreateEnvelopsReqBody.Signer>();

        this.requestBody.notification = new DocuSignCreateEnvelopsReqBody.Notification();

        // Offers expiration will be controlled by Salesforce making envelop 
        // void API calls. Setting the expireAfter to 999 ensures the expiration
        // will not occur unintentionally in case the DocuSign settings are 
        // changed
        DocuSignCreateEnvelopsReqBody.Expirations offersEnvExpiration = 
            new DocuSignCreateEnvelopsReqBody.Expirations();
        offersEnvExpiration.expireAfter = '999';
        offersEnvExpiration.expireEnabled = 'true';
        offersEnvExpiration.expireWarn = '0';
        this.requestBody.notification.expirations = offersEnvExpiration;

        // If set to "true", signers will be able to comment on the document
        // there are no requirements for offers to allow comments and the system is
        // not expected to handle any comments
        this.requestBody.allowComments = 'false';   

        // Do not allow reassigning of signers as there is no requirements for this
        this.requestBody.allowReassign = 'false';

        // Do not allow signer to print and sign it on paper
        this.requestBody.enableWetSign = 'false';
    }

    /**
     * @description Sets the brandId DocuSign will use to format the email and 
     * signing screens
     * @param brandId The brand Id that will be used
     * @return Returns the current instance of the builder
     */
    public OffersDocuSignCreateEnvReqBodyBuild setBrandId(String brandId) {
        this.requestBody.brandId = brandId;
        return this;
    }
    
    /**
     * @description Sets the email details for the signers
     * These values will be used by the API and will be used in DocuSign's 
     * email to signers.
     * @param emailContent Email content to be set
     * @returns Returns the current instance of the builder
     */
    public OffersDocuSignCreateEnvReqBodyBuild setEmailDetails(EmailContent emailContent) {
        this.requestBody.emailSubject = emailContent.subject;
        this.requestBody.emailBlurb = emailContent.emailBlurb;
        return this;
    }

    /**
     * @description Adds recipients who will perform the signing and the required 
     * information (e.g. anchor string)
     * @param recipient Recipient to be added
     * @returns Returns the current instance of the builder
     */
    public OffersDocuSignCreateEnvReqBodyBuild addRecipient(Recipient recipient) {
        
        // Construct signHere Tabs
        DocuSignCreateEnvelopsReqBody.SignHere signTab = new DocuSignCreateEnvelopsReqBody.SignHere();
        signTab.anchorString = recipient.signHereAnchorString;
        signTab.anchorXOffSet = '0';
        signTab.anchorYOffSet = '0';
        signTab.documentId = String.valueOf(recipient.documentId);

        DocuSignCreateEnvelopsReqBody.DateSigned dateSignedTab = new DocuSignCreateEnvelopsReqBody.DateSigned();
        dateSignedTab.anchorString = recipient.dateSignedAnchorString;
        dateSignedTab.anchorXOffSet = '0';
        dateSignedTab.anchorYOffSet = '0';
        dateSignedTab.documentId = String.valueOf(recipient.documentId);

        DocuSignCreateEnvelopsReqBody.EnvelopeRecipientTabs tabs = new DocuSignCreateEnvelopsReqBody.EnvelopeRecipientTabs();
        tabs.signHereTabs = new List<DocuSignCreateEnvelopsReqBody.SignHere>{signTab};
        tabs.dateSignedTabs = new List<DocuSignCreateEnvelopsReqBody.DateSigned>{dateSignedTab};

        DocuSignCreateEnvelopsReqBody.Signer signer = new DocuSignCreateEnvelopsReqBody.Signer();
        signer.email = recipient.email;
        signer.clientUserId = recipient.clientUserId;
        signer.name = recipient.name;
        signer.recipientId = recipient.recipientId;
        signer.routingOrder = String.valueOf(recipient.routingOrder);
        signer.tabs = tabs;

        this.requestBody.recipients.signers.add(signer);

        return this;
    }

    /**
     * @description Adds the Document for signing.
     * @param document Document to be added
     * @returns Returns the current instance of the builder
     */
    public OffersDocuSignCreateEnvReqBodyBuild addDocument(Document document) {
        DocuSignCreateEnvelopsReqBody.Document requestBodyDocument = new DocuSignCreateEnvelopsReqBody.Document();
        requestBodyDocument.documentBase64 = document.documentBody;
        requestBodyDocument.documentId = String.valueOf(document.documentId);
        requestBodyDocument.fileExtension = document.fileExtension;
        requestBodyDocument.name = document.documentName;

        // only 1 document is used for offers, change this if more is required
        this.requestBody.documents = new List<DocuSignCreateEnvelopsReqBody.Document>{requestBodyDocument}; 
        return this;
    }

    /**
     * @description Adds reminder for the envelop
     * @param reminder Reminder to be added
     * @return Returns the current instance of the builder
     */
    public OffersDocuSignCreateEnvReqBodyBuild setReminder(Reminder reminder) {

        // conversion to string as required by the docusign api
        DocuSignCreateEnvelopsReqBody.Reminders reminderBody = 
            new DocuSignCreateEnvelopsReqBody.Reminders();
        reminderBody.reminderDelay =  String.valueOf(reminder.reminderDelay);
        reminderBody.reminderEnabled =  String.valueOf(reminder.reminderEnabled);
        reminderBody.reminderFrequency = String.valueOf(reminder.reminderFrequency);
        
        this.requestBody.notification.reminders = reminderBody;
        return this;
    }

    /**
     * @description Method to obtain the request body constructed by the builder
     * @return Returns DocuSignCreateEnvelopsReqBody with the values constructed by the builder 
     */
    public DocuSignCreateEnvelopsReqBody getResult() {
        if (!isMandatoryFieldsDefined()) {
            throw new IllegalArgumentException('Mandatory values for creating the request are missing.');
        }
        return this.requestBody;
    }

    /**
     * @description Basic validation to ensure mandatory fields required for
     * the Envelop Create request are populated
     * Assumes the composite and inline templates are not used.
     * If the composite/inline templates are to be used, then this method 
     * should be updated to only conditionally check based on whether composite 
     * templates are being used.
     * 
     * DocuSign Create Envelop Documentation:
     * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
     */
    private boolean isMandatoryFieldsDefined() {
        return String.isNotBlank(this.requestBody.emailSubject) &&
            this.requestBody.documents != null;
    }

    public class EmailContent {
        public String subject;
        public String emailBlurb;
    }

    public class Recipient {
        public String name;
        public String email;

        /**
         * @description A local reference that senders use to map recipients 
         * to other objects, such as specific document tabs. Within an envelope, 
         * each recipientId must be unique, but there is no uniqueness requirement 
         * across envelopes. For example, many envelopes assign the first 
         * recipient a recipientId of 1.
         * Only integers or GUID values are supported.
         * DocuSign Reference: https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
         */
        public String recipientId;
        public Integer routingOrder;

        /**
         * @description Specifies whether the recipient is embedded or remote.
         * If the clientUserId property is not null then the recipient is embedded. 
         * Use this field to associate the signer with their userId in your app. 
         * Authenticating the user is the responsibility of your app when 
         * you use embedded signing.
         * Note: if the clientUserId property is set and either SignerMustHaveAccount 
         * or SignerMustLoginToSign property of the account settings is set to true, 
         * an error is generated on sending.
         * Maximum length: 100 characters.
         * DocuSign Reference https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
         */
        public String clientUserId;
        public String signHereAnchorString;
        public String dateSignedAnchorString;

        /**
         * @description The documentId is set by the API client. It is an integer 
         * that falls between 1 and 2,147,483,647. The value is encoded as a 
         * string without commas. The values 1, 2, 3, and so on are typically 
         * used to identify the first few documents in an envelope. Tab 
         * definitions include a documentId property that specifies 
         * the document on which to place the tab.
         * DocuSign Reference https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
         */
        public Integer documentId;
    }

    public class Document {
        public String documentBody;
        public Integer documentId;
        public String fileExtension;
        public String documentName;
    }

    public class Reminder {

        /**
         * @description Number of days before the reminder email sent out based 
         * on the envelop created date if the signer has not signed
         */
        public Integer reminderDelay;

        /**
         * @description Enables reminders if set to true, diable reminder with 
         * false
         */
        public boolean reminderEnabled;

        /**
         * @description Number of days between each reminder email
         */
        public Integer reminderFrequency;
    }
    
}