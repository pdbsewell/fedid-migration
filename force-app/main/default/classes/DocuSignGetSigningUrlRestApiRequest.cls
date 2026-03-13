/**
 * @description Implementation of the DocuSign Get Signing URL using 
 * DocuSign's REST API as part of DocuSign's embedded signing flow.
 * DocuSign's eSignature REST API refers to this as the EnvelopViews:
 * createRecipient
 * Reference:
 * https://developers.docusign.com/esign-rest-api/reference/Envelopes/EnvelopeViews/createRecipient
 * @group DocuSign Signing URL
 */
public class DocuSignGetSigningUrlRestApiRequest implements DocuSignGetSigningUrlRequest {
    
    /**
     * @description Callout to DocuSign using DocuSign's REST API to 
     * get DocuSign's Signing URL
     * Throws IllegalArgumentException for any invalid parameters
     * Throws DocuSignUnauthorizedAccessException when Docusign 
     * responds with 401
     * Throws DocuSignGetSignUrlReqFailException if Get Signing
     * URL callout response is an error
     * @param docuSignAccountId The DocuSign Account Id
     * @param envelopId The envelopId associated to the Signing request.
     * @param requestBody The request body of the request with the details
     * of the signing request
     * @return String of the URL which the user should be redirected to
     */
    public String getSigningUrl(String docuSignAccountId, String envelopId, DocuSignGetSigningUrlRequestBody requestBody) {
        if (String.isBlank(docuSignAccountId) || String.isBlank(envelopId)) {
            throw new IllegalArgumentException('Required DocuSign Account Id or Envelop Id attributes for Signing URL request are missing.');
        }

        String url = 'callout:DocuSign/restapi/v2.1/accounts/' + docuSignAccountId + '/envelopes/' + envelopId + '/views/recipient';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(requestBody));

        HttpResponse httpResponse = http.send(request);

        // 201 indicates success response
        if (httpResponse.getStatusCode() == 201) {
            DocuSignGetSigningUrlSuccessResponse response = (DocuSignGetSigningUrlSuccessResponse) 
                JSON.deserialize(httpResponse.getBody(), DocuSignGetSigningUrlSuccessResponse.class); 
            return response.url;
        } else if (httpResponse.getStatusCode() == 401) {
            throw new DocuSignUnauthorizedAccessException('DocuSign Get Signing URL authentication failed.');
        } else {
            throw new DocuSignGetSignUrlReqFailException('DocuSign Get Signing URL unsuccessful for envelop: ' + envelopId 
                + '. Response status code: ' + String.valueOf(httpResponse.getStatusCode()) 
                + ', response from DocuSign: ' + httpResponse.getBody());
        }
    }

    /**
     * @description Success response from DocuSign for JSON deserialization
     */
    private class DocuSignGetSigningUrlSuccessResponse {
        /**
         * @description The view URL to be navigated to.
         */
        public String url;
    }
}