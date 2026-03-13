/**
 * @author                      Kristian Vegerano
 * @created                     February 02, 2018
 * @description                 Rest Service that authenticates as a salesforce user and calls the rest service for retrieving FAQ Articles
 * @revision                    20/05/2020 - APRivera - updated due to PMD error <br/>
 */
@RestResource(urlMapping='/ArticleServiceLogin')
global without sharing class ArticleServiceLogin {
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Method that runs when a GET request has been sent to ArticleServiceLogin
     *                              We authenticate as a salesforce user because the system (Squiz - funnelback) that would consume the JSON data does not support REST oauth2 authentication.
     * @return                      returns customer or public articles in JSON format attached to the response body
     */
    @HttpGet
    global static void doGet() {
        //Initialize Variables
        Environment_Settings__c environmentSettings = Environment_Settings__c.getInstance();
        ExposeFAQArticles__c exposeFaqSettings = ExposeFAQArticles__c.getInstance();
        
        //Set return type to JSON
        RestContext.response.addHeader('Content-Type', 'application/json');
        
        //Check if the expose service is available or not
        if(environmentSettings.Expose_FAQs_Active__c){
            //Get Authentication
            Authorization loginAuth = authenticateUser(exposeFaqSettings.Retrieve_From__c, 
                                                       exposeFaqSettings.Client_Id__c, 
                                                       exposeFaqSettings.Client_Secret__c, 
                                                       exposeFaqSettings.Access_Username__c, 
                                                       exposeFaqSettings.Access_Password__c,
                                                       exposeFaqSettings.Access_Token__c);
            
            //Set article json to response
            RestContext.response.responseBody = retrieveCustomerPublicArticles(exposeFaqSettings.Retrieve_From__c, loginAuth);
        }else{
            //Set response as service not available
            RestContext.response.responseBody = Blob.valueOf('Service not available');
        }
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Method that calls salesforce authentication to get access token. 
     * @params                      retrieveFromUrl - Requires domain of the environment where to get the FAQ
     *                              clientId - client id of the connected app - Web Team Expose FAQ
     *                              clientSecret - client secret of the connected app - Web Team Expose FAQ
     *                              userUsername - username of the user used to access the service
     *                              userPassword - password of the user used to access the service
     *                              userSecurityToken - security token of the user used to access the service
     * @return                      Authorization - wrapper class for the authentication details
     */
    private static Authorization authenticateUser(String retrieveFromUrl, String clientId, String clientSecret, String userUsername, String userPassword, String userSecurityToken){
        //Initialize Variables
        Http http = new Http();
        
        //Setup authenticate integration endpoint
        String authenticateEndpointURL = retrieveFromUrl;
        //Add authentication service
        authenticateEndpointURL = authenticateEndpointURL + '/services/oauth2/token';
        
        //Setup credentials for rest calls
        String authenticationBody = 'grant_type=password';
        //Add client id
        authenticationBody = authenticationBody + '&client_id=' + clientId;
        //Add client secret
        authenticationBody = authenticationBody + '&client_secret=' + clientSecret;
        //Add username
        authenticationBody = authenticationBody + '&username=' + userUsername;
        //Add password + security token
        authenticationBody = authenticationBody + '&password=' + userPassword + userSecurityToken;
        
        //Authenticate as web team user
        HttpRequest authRequest = new HttpRequest();
        authRequest.setEndpoint(authenticateEndpointURL);
        authRequest.setMethod('POST');
        authRequest.setBody(authenticationBody); //Adding authentication details as part of the request body - removed from being included on the URI
        
        //Send Request to get authentication
        HTTPResponse authResponse = http.send(authRequest);
        return (Authorization)JSON.deserializeStrict(authResponse.getBody(), Authorization.class);
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Method that calls the rest service to retrieve customer or public articles.
     * @params                      retrieveFromUrl - Requires domain of the environment where to get the FAQ
     *                              loginAuth - authorization wrapper record to use - access_token / sessionId
     * @return                      Blob - all customer or public articles in JSON format casted as Blob
     */
    private static Blob retrieveCustomerPublicArticles(String retrieveFromUrl, Authorization loginAuth){
        //Initialize Variables
        Http http = new Http();
        //Retrieve FAQ Data
        HttpRequest articleRequest = new HttpRequest();
        articleRequest.setEndpoint('callout:FAQDataService');
        articleRequest.setHeader('Authorization', 'OAuth ' + loginAuth.access_token);
        articleRequest.setHeader('Content-Type', 'application/json');
        articleRequest.setMethod('GET');
        //Send callout to FAQDataService to get articles
        HTTPResponse articleResponse = http.send(articleRequest);
        
        //Return articles in JSON format
        return Blob.valueOf(articleResponse.getBody());
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 02, 2018
     * @description                 Wrapper class to contain the authorization details returned from an authentication callout.
     */
    public class Authorization{
        public String access_token {get; set;}
        public String instance_url {get; set;}
        public String id {get; set;}
        public String token_type {get; set;}
        public String issued_at {get; set;}
        public String signature {get; set;}
    }
}