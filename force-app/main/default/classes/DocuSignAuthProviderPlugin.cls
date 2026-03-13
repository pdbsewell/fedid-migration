/**
 * @description Custom DocuSign AuthProviderPluginClass implementation
 * This implementation should only be used for the purposes of 
 * authorizing callouts using named credentials. There are no SSO 
 * functionality related to DocuSign.
 * @group DocuSign Authorization
 */
public class DocuSignAuthProviderPlugin extends Auth.AuthProviderPluginClass {

    @testVisible
    private DocuSignOAuthTokenRequest docuSignOAuthTokenRequest;

    public DocuSignAuthProviderPlugin() {
        this.docuSignOAuthTokenRequest = new DocuSignJwtOAuthTokenRequest();
    }

    /**
     * @description Returns the custom metadata type API name for a where 
     * DocuSign OAuth authentication provider configuration is stored.
     * @return Returns the custom metadata type API name
     */
    public String getCustomMetadataType() {
        return 'DocuSign_Auth_Provider_Setting__mdt';
    }

    public Auth.UserData getUserInfo(Map<String,String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
        String id = authProviderConfiguration.get('DeveloperName'); 
        String firstName = authProviderConfiguration.get('Authorization_First_Name__c'); 
        String lastName = authProviderConfiguration.get('Authorization_Last_Name__c'); 
        String fullName = firstName + ' ' + lastName;
        String userName = authProviderConfiguration.get('Authorization_User_Name__c'); 
        String email = authProviderConfiguration.get('Authorization_User_Email__c'); 
        String locale = authProviderConfiguration.get('Authorization_Locale__c');
        Map<String,String> provMap = new Map<String,String>();
        return new Auth.UserData(id, firstName, lastName, fullName, email,'what',userName,locale,'DocuSign', null, provMap); 
    }

    /**
     * @description Returns the URL where the user is redirected for 
     * authentication.
     * This implements the "Request Application Consent" step of the 
     * DocuSign OAuth JSON Web Token (JWT) Grant
     * Reference:
     * https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-jsonwebtoken
     */
    public PageReference initiate(Map<string,string> authProviderConfiguration, String stateToPropagate) {
        String authBaseUrl = authProviderConfiguration.get('Authorization_URI__c');
        String callbackUrl = authProviderConfiguration.get('Callback_URL__c');
        String clientId = authProviderConfiguration.get('Client_Id__c');
        
        String authUrl = authBaseUrl + '?client_id=' + clientId 
            + '&response_type=code&scope=signature%20impersonation&state=' 
            + stateToPropagate + '&redirect_uri=' + callbackUrl;
        return new PageReference(authUrl);
    }

    /**
     * @description Uses the DocuSign's supported authentication protocol 
     * to return an OAuth access token, OAuth secret or refresh token, 
     * and the state passed in when the request for the current user 
     * was initiated.
     */
    public Auth.AuthProviderTokenResponse handleCallback(Map<String,String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {
        Map<String,String> queryParams = state.queryParameters;
        String sfdcState = queryParams.get('state');      
        return new Auth.AuthProviderTokenResponse('DocuSignAuthProviderPlugin', this.docuSignOAuthTokenRequest.getAccessToken(), 'noRefreshTokenProvided', sfdcState);
    }

    /**
     * @description Returns a new access token, which is used to update 
     * an expired access token.
     * DocuSign's REST API does not support refresh tokens, so the 
     * entire process for obtaining an access token is repeated.
     */
    public override Auth.OAuthRefreshResult refresh(Map<string,string> authProviderConfiguration, String refreshToken) {   
         // no refresh token but a hardcode string is still required
         // a blank value will not work
        return new Auth.OAuthRefreshResult(this.docuSignOAuthTokenRequest.getAccessToken(), 'noRefreshTokenProvided'); 
    }
}