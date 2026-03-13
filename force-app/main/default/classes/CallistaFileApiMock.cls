/*******************************************************************************
* @author		Nitin Khandelwal
* @date         18.Sept.2018     
* @description  Mock API response for FileToCallistaInterface Class

* @revision     
*******************************************************************************/
@isTest
public class CallistaFileApiMock implements HttpCalloutMock{

    public Integer responseCode {get; set;}

    public HttpResponse respond (HttpRequest req) {

        Map<String, Object> reqBody = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
        
        // Create a fake response
        HttpResponse resp = new HttpResponse();

        resp.setHeader('Content-Type', 'application/json');
        if (responseCode == 200) {
            resp.setBody('{"type" : "document","sourceTime" : "2018-09-16 09:24:23","source" : "unicrm","events" : [ {"id" : "0690l000001IktWAAS","filename" : "Secondary Transcript Test",'+
                         '"externalApplicantId" : "0030l00000NDHL1AAP","documentType" : null,"contentType" : "pdf","contactDocumentId" : null,"comments" : null,"applicationDocumentId" : null,'+
                         '"applicantId" : "asdasdad","agentPersonId" : "29160278"} ]}');
        } else {
            resp.setBody('{"message": "A fault has occurred.","errorDetails": {"message": "Unable to process response"}}');
        }
        resp.setStatusCode(responseCode);
        

        return resp;

    }
    

}