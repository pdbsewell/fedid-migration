/**
 * @description Use the DocuSignUpdateEnvelopRestApiRequest class make a 
 * callout to DocuSign to update an Envelop using DocuSign's REST API
 * @group DocuSign Update Envelop
 */
public class DocuSignUpdateEnvelopRestApiRequest 
        implements DocuSignUpdateEnvelopsRequest{

    /**
     * @description Update DocuSign Envelop using DocuSign's REST API
     * Throws IllegalArgumentException if parameters are missing
     * Throws DocuSignUpdateEnvelopsReqException if API response is error
     * Throws DocuSignUnauthorizedAccessException if there is an authentication 
     * error
     * @param accountId The DocuSign accountId
     * @param envelopId The envelop id for the envelop to be updated
     * @param requestBody Request Body for the envelop to be updated to
     */
    public void updateEnvelop(String accountId, String envelopId, 
            DocuSignUpdateEnvelopsReqBody requestBody) {

        if (String.isBlank(accountId) || String.isBlank(envelopId) 
                || requestBody == null) {
            throw new IllegalArgumentException(
                'Account Id, envelop Id or request body is missing for update envelop'
            );
        }

        String url = 'callout:DocuSign/restapi/v2.1/accounts/'+ accountId + '/envelopes/' + envelopId;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('PUT');
        request.setBody(JSON.serialize(requestBody));

        HttpResponse httpResponse = http.send(request);

        // 200 indicates success response
        // 400 is usually the error response
        
        if (httpResponse.getStatusCode() == 401) {
            throw new DocuSignUnauthorizedAccessException(
                'DocuSign Update Envelop authentication failed.'
            );
        } else if (httpResponse.getStatusCode() != 200) {
            throw new DocuSignUpdateEnvelopsReqException(
                'DocuSign Update Envelop unknown error. Status code returned: ' 
                + httpResponse.getStatusCode() + ', response: ' 
                + httpResponse.getBody() 
            );
        }
    }
}