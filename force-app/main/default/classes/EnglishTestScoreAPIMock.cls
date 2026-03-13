/**
 * Created by smen0015 on 13/09/2018.
 */
@isTest
public class EnglishTestScoreAPIMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {

        Map<String, Object> reqBody = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(200);
        resp.setBody('{"sequenceNumber": 1}');

        return resp;
    }
}