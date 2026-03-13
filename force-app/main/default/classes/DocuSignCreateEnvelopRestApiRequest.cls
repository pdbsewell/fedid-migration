/**
 * @description Use the DocuSignCreateEnvelopsRequest class make a callout to 
 * DocuSign to create an Envelop using DocuSign's REST API
 * @group DocuSign Create Envelop
 */
public class DocuSignCreateEnvelopRestApiRequest implements DocuSignCreateEnvelopsRequest {

    private String envelopeId;

    /**
     * @description Performs a callout to DocuSign to create an Envelop
     * @param accountId The DocuSign account Id
     * @param requestBody The request body payload to the sent to DocuSign
     * to create the envelop
     */
    public void createEnvelop(String accountId, DocuSignCreateEnvelopsReqBody requestBody) {
        // validate input parameters
        if (!isCreateEnvelopReqParamsValid(accountId, requestBody)) {
            throw new IllegalArgumentException('Account Id and request body is required.');
        }

        String url = 'callout:DocuSign/restapi/v2.1/accounts/'+ accountId + '/envelopes';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(requestBody));

        HttpResponse httpResponse = http.send(request);
        System.debug(httpResponse);
        System.debug(httpResponse.getBody());

        // 201 indicates success response
        if (httpResponse.getStatusCode() == 201) {
            SuccessResponse response = (SuccessResponse) JSON.deserialize(httpResponse.getBody(), SuccessResponse.class); 
            this.envelopeId = response.envelopeId;
        } else if (httpResponse.getStatusCode() == 401) {
            throw new DocuSignUnauthorizedAccessException('DocuSign Create Envelop authentication failed.');
        } else {
            throw new DocuSignCreateEnvelopsReqException(
                'DocuSign Create Envelop unknown error. Status code returned: ' 
                + httpResponse.getStatusCode() + ', response: ' 
                + httpResponse.getBody() 
            );
        }
    }

    /**
     * @description Returns the DocuSign envelop Id returned from 
     * creating the envelop.
     * The DocuSign envelop must be created before calling this 
     * method
     * @return The DocuSign envelop Id
     */
    public String getEnvelopId() {
        return this.envelopeId;
    }

    private boolean isCreateEnvelopReqParamsValid(String accountId, DocuSignCreateEnvelopsReqBody requestBody) {
        return (String.isNotBlank(accountId) && (requestBody != null));
    }

    /**
     * @description Success response from DocuSign for JSON deserialization
     */
    private class SuccessResponse {
        public String envelopeId;
        public String uri;
        public String statusDateTime;
        public String status;
    }

    /**
     * @description Error response from DocuSign for JSON deserialization
     */
    private class ErrorResponse {
        public String errorCode;
        public String message;
    }
}