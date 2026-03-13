/**
 * @description Interface for DocuSign Oauth Token Requests
 * @group DocuSign Authorization
 */
public interface DocuSignOAuthTokenRequest {

    /**
     * @description Fetches the access token for OAuth Authentication
     * @return Returns access token as a string
     */
    String getAccessToken();
}