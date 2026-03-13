/**
 * @author          Peter Sewell, Salesforce
 * @group           Test Class
 * @description     Class to mock BreakGlassAlert callout
 * @revision        
 *  20/09/2021    - Peter Sewell - initial version
 */
@isTest
public class BreakGlassAlertCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{}');
        response.setStatusCode(200);
        return response; 
    }
}