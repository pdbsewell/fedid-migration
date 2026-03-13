/**
@author Cartick Sub
@date 11 August 2020
@group Student Letters
@description Generates mock HTTP responses for use by the test class, StudentLettersHelper_Test
@revision Initial version 11 August 2020
**/

@isTest
public class StudentLettersMockResponseGenerator implements HttpCalloutMock {

    /**
    @description Implements interface method
    **/
    public HTTPResponse respond(HTTPRequest request) {
        
        HttpResponse response = new HttpResponse();
        response.setBody('{"_links": {"_self": {"href": ""}},"entitlements": []}');
        response.setStatusCode(200);
        return response;

    }
}