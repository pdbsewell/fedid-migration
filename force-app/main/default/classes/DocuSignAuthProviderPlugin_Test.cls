/**
 * @dsecription Test class for DocuSignAuthProviderPlugin
 */
@isTest(isParallel=true)
public class DocuSignAuthProviderPlugin_Test {

    private static final string ACCESS_TOKEN = 'eyJ0eXAiOiJNVCIsImFsZyI6IlJTMjU2Iiwia2lkIjoiNjgxODVmZjEtNGU1MS00Y2U5LWFmMWMtNjg5ODEyMjAzMzE3In0.AQoAAAABAAUABwAA-UAagZXXSAgAAGEFfImV10gCAI-38Nr0jqtIiVLylJ0biEMVAAEAAAAYAAIAAAAFAAAAHQAAAA0AJAAAADQzMjBlNDJlLTI4OWEtNDc4NC04NzAwLTZiMjY4YTYxYzkzYyIAJAAAADQzMjBlNDJlLTI4OWEtNDc4NC04NzAwLTZiMjY4YTYxYzkzYxIAAQAAAAYAAABqd3RfYnIjACQAAAA0MzIwZTQyZS0yODlhLTQ3ODQtODcwMC02YjI2OGE2MWM5M2M.lJBwTThqWQaqwWqvCNX8Km0_loCsDY8pQikCrTGSHfwCmslCcvwRDC65vw_RD-xBAxbVntntbP3e0McDBbiK0kOOJnZz5TAk-4gEFOVQPg__t5rR5ooKcDjwOC2QasAd7IVDoX1Qj-yPCoK_FaGsBJy0tW7_FQgfspgXGmdzpxq6E7s-ifiTHhp-COmnw0MKau8YkF0gFU5IGJXpkk0FAsjtYN-Q_uteAXuiIFPwX4pWVNTR7eFDtFGvBpWoGR9ePrH5MzgNGtX60uvvbyRTJcjZfvzf6TkjiUywEUOVS37R3TgaIcGRcJnLFRXyeQ3wIIlrGK8Do9xVj7uMO4bZig';

    @isTest
    static void shouldReturnCustomMetadataTypeName() {
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        String customMetadataTypeName = docuSignAuthProviderPlugin.getCustomMetadataType();
        System.assertNotEquals(null, customMetadataTypeName, 'Expected a customMetadataType name to be returned.');
    }

    @isTest
    static void shouldReturnGetUserInfoWithData() {
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();

        Map<String, String> authProviderConfiguration = new Map<String, String>();
        authProviderConfiguration.put('Authorization_First_Name__c', 'Integration');
        authProviderConfiguration.put('Authorization_Last_Name__c', 'Integration');
        authProviderConfiguration.put('Authorization_Locale__c', 'Australia');
        authProviderConfiguration.put('Authorization_User_Email__c	', 'integration.538972904304892329382@monash.edu.test');
        authProviderConfiguration.put('Authorization_User_Name__c', 'Integration.538972904304892329382@monash.edu.test');

        Auth.UserData userData = docuSignAuthProviderPlugin
            .getUserInfo(authProviderConfiguration, null);
        System.assertNotEquals(null, userData.username, 'Expected username to be set.');
    }

    @isTest
    static void shouldInitiateWithCallbackUrl() {

        String callbackUrl = 'https://unicrm--sfcpq2dev.my.salesforce.com/services/authcallback/DocuSign';

        Map<String, String> authProviderConfiguration = new Map<String, String>();
        authProviderConfiguration.put('Callback_URL__c', callbackUrl);

        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        PageReference redirectedPage = docuSignAuthProviderPlugin.initiate(
            authProviderConfiguration, 'state');
        System.assertEquals(true, redirectedPage.getUrl()
            .contains('redirect_uri=' +  EncodingUtil.urlEncode(callbackUrl, 'UTF-8')), 
            'Expected the callback url to be part of the URL returned in initiate. URL returned: ' 
            + redirectedPage.getUrl());
    }

    @isTest
    static void shouldInitiateWithResponseTypeCode() {
        Map<String, String> authProviderConfiguration = new Map<String, String>();
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        PageReference redirectedPage = docuSignAuthProviderPlugin.initiate(
            authProviderConfiguration, 'state');
        System.assertEquals(true, redirectedPage.getUrl()
            .contains('response_type=code'), 'Expected response_type=code');
    }

    @isTest
    static void shouldInitiateWithScopeSignatureImpersonation() {
        Map<String, String> authProviderConfiguration = new Map<String, String>();
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        PageReference redirectedPage = docuSignAuthProviderPlugin.initiate(
            authProviderConfiguration, 'state');
        System.assertEquals(true, redirectedPage.getUrl()
            .contains('scope=signature+impersonation')
            , 'Expected scope to be set to signature impersonation, URL returned: ' 
            + redirectedPage.getUrl());
    }

    @isTest
    static void shouldInitiateWithClientId() {
        Map<String, String> authProviderConfiguration = new Map<String, String>();
        String clientId = '4320e42e-289a-4784-8700-6b268a61c93c';
        authProviderConfiguration.put('Client_Id__c', clientId);
        
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        PageReference redirectedPage = docuSignAuthProviderPlugin.initiate(
            authProviderConfiguration, 'state');
        System.assertEquals(true, redirectedPage.getUrl()
            .contains('client_id=' + clientId), 
            'Expected client id to be set in the initiate URL.');
    }

    @isTest
    static void shouldInitiateWithAuthorizationUrl() {
        Map<String, String> authProviderConfiguration = new Map<String, String>();
        String authUrl = 'https://account-d.docusign.com/oauth/auth';

        authProviderConfiguration.put('Authorization_URI__c', authUrl);
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        PageReference redirectedPage = docuSignAuthProviderPlugin.initiate(
            authProviderConfiguration, 'state');
        
        System.assertEquals(true, redirectedPage.getUrl()
            .contains(authUrl + '?'), 
            'Expected Authorization URI in the initiate URL, got instead' 
            + redirectedPage.getUrl());
    }

    @isTest
    static void shouldReturnAccessTokenOnHandleCallback() {
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        docuSignAuthProviderPlugin.docuSignOAuthTokenRequest = 
            new DocuSignAuthProviderPlugin_Test.DocuSignOAuthTokenRequestStub();

        Map<String, String> queryParams = new Map<String, String>();
        queryParams.put('state', 'state');

        Auth.AuthProviderCallbackState callbackState = new Auth.AuthProviderCallbackState(
            new Map<String, String>(), 'http body', queryParams);

        Auth.AuthProviderTokenResponse tokenResponse = docuSignAuthProviderPlugin
            .handleCallback(new Map<String, String>(), callbackState);
        System.assertEquals(ACCESS_TOKEN, tokenResponse.oauthToken, 
            'Expected handleCallback to return matching access token');
    }

    @isTest
    static void shouldReturnAccessTokenOnRefresh() {
        DocuSignAuthProviderPlugin docuSignAuthProviderPlugin = new DocuSignAuthProviderPlugin();
        docuSignAuthProviderPlugin.docuSignOAuthTokenRequest = 
            new DocuSignAuthProviderPlugin_Test.DocuSignOAuthTokenRequestStub();

        Auth.OAuthRefreshResult refreshResult = docuSignAuthProviderPlugin
            .refresh(new Map<String, String>(), 'noRefreshTokenProvided');

        System.assertEquals(ACCESS_TOKEN, refreshResult.accessToken, 
            'Expected refresh token to match stubbed access token');
    }


    private class DocuSignOAuthTokenRequestStub implements DocuSignOAuthTokenRequest {

        public String getAccessToken() {
            return ACCESS_TOKEN;
        }

    }
}