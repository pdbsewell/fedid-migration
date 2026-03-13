/**
 * @description JSON Web Token (JWT) grant OAuth request for accessing Docusign 
 * resources using DocuSign's REST API.
 * This OAuth type is used for server to server integration with DocuSign 
 * and is the recommended authentication type for this type of integration
 * Reference https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-jsonwebtoken
 * @group DocuSign Authorization
 */
public class DocuSignJwtOAuthTokenRequest implements DocuSignOAuthTokenRequest {
    
    CreateDocuSignJwtToken token;

    public DocuSignJwtOAuthTokenRequest() {
        token = new CreateDocuSignJwtToken();
    }

    public String getAccessToken() {

        DocuSignAuthProviderSetting setting  = new DocuSignAuthProviderSetting();

        //Set the token endpoint that the JWT bearer token is posted to
        String tokenEndpoint = setting.getAccessTokenUrl();
        
        //POST the JWT bearer token
        HttpRequest req = new HttpRequest();
        req.setEndpoint(tokenEndpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        string assertion= '&assertion=' +  token.createToken();
                    
        req.setBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' + assertion);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug(res.getBody());
        
        /**
        This is only used by the custom Auth Provider. It is expected 
        that an errors will be handled by the Auth Provider, e.g. the 
        Auth Provider can invoke the refresh method to regenerate 
        another access token. Therefore, no error handling is 
        implemented here.
         */  
        DocuSignTokenResponse response = (DocuSignTokenResponse) JSON.deserialize(res.getBody(), DocuSignTokenResponse.class);  
        return response.access_token;
    }

    private class DocuSignTokenResponse {
        public String access_token;
        public String token_type;
        public String expires_in;
    }

}