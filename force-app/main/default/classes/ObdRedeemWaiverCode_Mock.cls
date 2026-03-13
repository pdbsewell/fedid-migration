/**
 * @author Trent De Laney
 * @date 6 Jan 2020 at 8:29:42 pm
 * @group Test Mock
 * @description Mock class for the HTTP callout
 */
@IsTest
public with sharing class ObdRedeemWaiverCode_Mock {

    public Integer responseCode {get;set;}

    public HttpResponse respond(HttpRequest param) {

    HttpResponse resp = new HttpResponse();
    resp.setHeader('Content-Type', 'application/json');

    resp.setBody('{"applications": [{"admissionApplNumber": 1,"coursePreferences":[{"courseCode": "E6001","coursePreferenceInstances":[{"sequenceNumber": 1}]}]}]}');

    resp.setStatusCode(responseCode);
    return resp;
    }
}