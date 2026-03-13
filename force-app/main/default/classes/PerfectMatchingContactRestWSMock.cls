/**
 * @author  Shalini Mendu
 * @date 05 Dec 2019
 * @group Test Class
 * @description Mock class for the webservice in PerfectMatchingContactRestWS
 */
@IsTest
public class PerfectMatchingContactRestWSMock implements HttpCalloutMock {

    public  Integer responseCode {get; set;}
    HttpResponse resp = new HttpResponse();

    public HttpResponse respond (HttpRequest req) {
        resp.setHeader('Content-Type', 'application/json');
        if (responseCode == 200) {
            resp.setBody('{"contactId" : "003p000000WGKfQAAX", "status" : "Success", "error":"null"}');
        } else {
            resp.setBody('{"contactId" : null, "status" : "Error", "error":"Database exception occured"}');
        }
        resp.setStatusCode(responseCode);

        return resp;
    }



}