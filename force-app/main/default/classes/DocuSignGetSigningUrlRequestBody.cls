/**
 * @description The request body for JSON deserialization for 
 * callouts to the DocuSign Get Signing URL.
 * Reference: 
 * https://developers.docusign.com/esign-rest-api/reference/Envelopes/EnvelopeViews/createRecipient
 * @group DocuSign Get Signing URL
 * @revision
 * 		17-08-2025	- Sachin Shetty	- Added Constructor
 */
public class DocuSignGetSigningUrlRequestBody {
    
    /**
     * @description Required by DocuSign. Choose a value that most 
     * closely matches the technique your application used to 
     * authenticate the recipient / signer. Choose a value from 
     * this list: Biometric, Email, HTTPBasicAuth, Kerberos ,
     * KnowledgeBasedAuth, None, PaperDocuments, Password, 
     * RSASecureID, SingleSignOn_CASiteminder, SingleSignOn_InfoCard, 
     * SingleSignOn_MicrosoftActiveDirectory, SingleSignOn_Other, 
     * SingleSignOn_Passport, SingleSignOn_SAML, Smartcard, 
     * SSLMutualAuth, X509Certificate
     * This information is included in the Certificate of Completion.
     */
    public String authenticationMethod;

    /**
     * @description A sender-created value. If provided, the 
     * recipient is treated as an embedded (captive) recipient 
     * or signer. Use your application's client ID (user ID) 
     * for the recipient. Doing so enables the details of 
     * your application's authentication of the recipient to 
     * be connected to the recipient's signature if the 
     * signature is disputed or repudiated. 
     * Maximum length: 100 characters.
     */
    public String clientUserId;

    /**
     * @description Specifies the email of the recipient. 
     */
    public String email;

    /**
     * @description A local reference that senders use to map 
     * recipients to other objects, such as specific document 
     * tabs. Within an envelope, each recipientId must be unique, 
     * but there is no uniqueness requirement across envelopes. 
     * For example, many envelopes assign the first recipient 
     * a recipientId of 1.
     */
    public String recipientId;

    /**
     * @description The URL to which the user should be redirected 
     * after the signing session has ended. DocuSign redirects to 
     * the URL and includes an event query parameter that can be 
     * used by your application. 
     * Maximum Length: 500 characters. 
     * If the returnUrl exceeds this limit, the user is redirected 
     * to a truncated URL.
     */
    public String returnUrl;

    /**
     * @description The domain in which the user authenticated.
     */
    public String securityDomain;

    /**
     * @description The username of the recipient. 
     */
    public String userName;

    /**
     * @description Specifies whether a browser should be allowed to 
     * render a page in a frame or IFrame. Setting this property 
     * ensures that your content is not embedded into unauthorized 
     * pages or frames. Valid values are: deny: The page cannot be 
     * displayed in a frame. same_origin: The page can only be 
     * displayed in a frame on the same origin as the page itself.
     * allow_from: The page can only be displayed in a frame on the 
     * origin specified by the xFrameOptionsAllowFromUrl property.
     */
    public String xFrameOptions;
    
    // Default constructor
    public DocuSignGetSigningUrlRequestBody() { //NOPMD
    }
}