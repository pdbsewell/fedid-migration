/**
 * @author                      Kristian Vegerano
 * @created                     February 09, 2018
 * @description                 Test class for ArticleServiceLogin class
 */
@isTest (SeeAllData=false)
private class ArticleServiceLogin_Test {
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 09, 2018
     * @description                 Test Mock for ArticleServiceLogin authentication
     */
    private class AuthenticateArticleServiceLogin implements HttpCalloutMock {
       
        /**
         * @author                      Kristian Vegerano
         * @created                     February 09, 2018
         * @description                 Test Response when ArticleServiceLogin service has been called
         */
        public HTTPResponse respond(HTTPRequest req) {
            ArticleServiceLogin.Authorization testAuth = new ArticleServiceLogin.Authorization();
            testAuth.access_token = 'a';
            testAuth.instance_url = 'b';
            testAuth.id = 'c';
            testAuth.token_type = 'd';
            testAuth.issued_at = 'e';
            testAuth.signature = 'f';
            
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(JSON.serialize(testAuth));
            res.setStatusCode(200);
            return res;
        }
    }

	/**
     * @author                      Kristian Vegerano
     * @created                     February 09, 2018
     * @description                 Method that sets up data to be used on all test methods in this class
     */
    @testSetup 
    static void setupArticles() {
        //Initialize Variables
        Environment_Settings__c environmentSettings = new Environment_Settings__c();
        environmentSettings.Expose_FAQs_Active__c = true;
        insert environmentSettings;
    }
    
    /**
     * @author                      Kristian Vegerano
     * @created                     February 09, 2018
     * @description                 Test for retrieving authentication details for preparation to call the rest service for retrieving FAQs
     */
    @isTest 
	private static void testGetCallout() {
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        //Setup endpoint
        req.requestURI = '/services/apexrest/ArticleServiceLogin';
        
        //Setup action
        req.httpMethod = 'GET';
        
        //Setup callout
        RestContext.request = req;
        RestContext.response = res;
        
        //Start Test
        Test.setMock(HttpCalloutMock.class, new AuthenticateArticleServiceLogin());
        Test.startTest();
        
        ArticleServiceLogin.doGet();
        
        Test.stopTest();
        
        //Set response for assertion
        Blob responseJSON = res.responseBody;
        
        ArticleServiceLogin.Authorization testAuth = new ArticleServiceLogin.Authorization();
        testAuth.access_token = 'a';
        testAuth.instance_url = 'b';
        testAuth.id = 'c';
        testAuth.token_type = 'd';
        testAuth.issued_at = 'e';
        testAuth.signature = 'f';
            
        //Test response
        System.assertEquals(JSON.serialize(testAuth), 
                            responseJSON.toString());
	}
	
	/**
     * @author                      Kristian Vegerano
     * @created                     February 09, 2018
     * @description                 Test for the fail behavior when the environment settings is turned off
     */
    @isTest 
	private static void testFailGetCallout() {
        //Initialize Variables
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        //Get existing environment settings and update it to false
        Environment_Settings__c environmentSettings = [SELECT Id FROM Environment_Settings__c LIMIT 1];
        environmentSettings.Expose_FAQs_Active__c = false;
        update environmentSettings;
        
        //Setup endpoint
        req.requestURI = '/services/apexrest/ArticleServiceLogin';
        
        //Setup action
        req.httpMethod = 'GET';
        
        //Setup callout
        RestContext.request = req;
        RestContext.response = res;
        
        //Start Test
        Test.setMock(HttpCalloutMock.class, new AuthenticateArticleServiceLogin());
        Test.startTest();
        
        ArticleServiceLogin.doGet();
        
        Test.stopTest();
        
        //Set response for assertion
        Blob responseJSON = res.responseBody;
            
        //Test response
        System.assertEquals('Service not available', 
                            responseJSON.toString());
	}
}