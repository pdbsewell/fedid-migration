/**
 * @description Builder for constructing the request body used in the 
 * DocuSign Get Signing URL API callout. This builder applies default 
 * values and providers setters on fields relevant to Offers.
 * @group DocuSign Signing URL
 */
public inherited sharing class OffersDocuSignGetSignUrlReqBodBuild {
    
    @testVisible
    private DocuSignGetSigningUrlRequestBody requestBody;

    /**
     * @description Constructor to constuct the DocuSignGetSigningUrlRequestBody
     * with default values relevant to Offers
     * @param email The email address used to generate the related envelop
     * @param fullName The full name used to generate the related envelop
     */
    public OffersDocuSignGetSignUrlReqBodBuild(String email, String fullName) {
        this.requestBody = new DocuSignGetSigningUrlRequestBody();
        if (String.isBlank(email)) {
            throw new IllegalArgumentException('Email value is blank. Email is required for DocuSign Signing URL API');
        } else {
            this.requestBody.email = email;
        }

        if (String.isBlank(fullName)) {
            throw new IllegalArgumentException('Full Name is blank. Full Name is required for DocuSign Signing URL API');
        } else {
            this.requestBody.userName = fullName;
        }

        // put default values here
        this.requestBody.xFrameOptions = 'deny';
        this.requestBody.recipientId = '1';
        this.requestBody.authenticationMethod = 'password';
    }

    /**
     * @description Sets the Docusign recipient Id on the Signing URL 
     * request body. This recipient Id should match the intended 
     * signer's recipient Id that was used to generate the envelop Id
     * @param recipient The recipient Id as an integer
     */
    public OffersDocuSignGetSignUrlReqBodBuild setRecipientId(Integer recipientId) {
        this.requestBody.recipientId = String.valueOf(recipientId);
        return this;
    }

    /**
     * @description Sets the DocuSign clientUserId on the Signing URL 
     * request body. This client user Id should match the intended 
     * signer's clientUserId that was used to generate the envelop Id
     * @param clientUserId The signer's clientUserId, the clientUserId 
     * should not exceed 100 characters, otherwise an IllegalArgumentException 
     * will be thrown.
     */
    public OffersDocuSignGetSignUrlReqBodBuild setClientUserId(String clientUserId) {
        if (clientUserId.length() > 100) {
            throw new IllegalArgumentException('clientUserId exceeds DocuSign\'s 100 character limit.');
        } else {
            this.requestBody.clientUserId = clientUserId;
        }
        return this;
    }

    /**
     * @description Sets the DocuSign returnUrl on the Signing URL 
     * request body.
     * @param returnUrl The URL that the user will be redirected to 
     * once the user has completed the signing process. This value 
     * should not exceed 500 characters. If this value exceeds 500 
     * characters, an IllegalArgumentException will be thrown
     */
    public OffersDocuSignGetSignUrlReqBodBuild setReturnUrl(String returnUrl) {
        // DocuSign's documentation mentions a 500 character limit and if the
        // number of characters exceeds this limit, the URL may be truncated
        // As the functionality is not expected more than 500 characters in the 
        // an exception will be thrown as the side effects of using more than 
        // 500 characters is not known.
        if (returnUrl.length() > 500) {
            throw new IllegalArgumentException('Return URL exceeds DocuSign\'s 500 character limit.');
        } else {
            this.requestBody.returnUrl = returnUrl;
        }
        return this;
    }

    /**
     * @description Returns the DocuSignGetSigningUrlRequestBody built
     */
    public DocuSignGetSigningUrlRequestBody getResult() {
        return this.requestBody;
    }

}