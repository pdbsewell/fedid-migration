/*******************************************************************************
* @author		Sethu Venna
* @date         19/03/2025  
* @description  Mock API response for ATAR Score Callout Interface

* @revision     
*******************************************************************************/
@isTest(isParallel=true)
public class ATARScoreHTTPCalloutMock implements HttpCalloutMock{

    public Integer responseCode {get; set;}

    public HttpResponse respond (HttpRequest req) {

        Map<String, Object> reqBody = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
        
        // Create a fake response
        HttpResponse resp = new HttpResponse();

        resp.setHeader('Content-Type', 'application/json');
        if (responseCode == 200) {
            resp.setBody('{"qualification" : {"id": "6854327"}}');
        } else {
            resp.setBody('{"message": "A fault has occurred.","errorDetails": {"message": "Unable to process response"}}');
        }
        resp.setStatusCode(responseCode);
        return resp;
    }
    

}