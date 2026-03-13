@IsTest
public class ObdACPImplementation_Mock implements HttpCalloutMock{

    public Integer responseCode {get;set;}

    public HttpResponse respond(HttpRequest param) {

        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');

        resp.setBody('{"applications": [{"admissionApplNumber": 1,"coursePreferences":[{"courseCode": "E6001","coursePreferenceInstances":[{"sequenceNumber": 1}]}]}]}');
        
        resp.setStatusCode(responseCode);
        return resp;
    }
}