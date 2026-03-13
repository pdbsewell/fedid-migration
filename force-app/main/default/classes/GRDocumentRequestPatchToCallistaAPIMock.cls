/*******************************************************************************
* @author		Vishal Gupta
* @date         4/11/2024    
* @description  Mock API response for GRDocumentRequestPatchToCallistaService Class
* @revision     4/11/2024 - Initial Version
*******************************************************************************/
@isTest
public class GRDocumentRequestPatchToCallistaAPIMock implements HttpCalloutMock{

    /**
     * @author      Vishal Gupta
     * @description get/set of responseCode
     * @param       responseCode
     * @return      responseCode
     * @revision    4/11/2024 - Initial Version
     */
    public Integer responseCode {get; set;}

    /**
     * @author      Vishal Gupta
     * @description Mocks Document request Patch to callista
     * @param       req of type HttpRequest
     * @return      HttpResponse
     * @revision    4/11/2024 - Initial Version
     */
    public HttpResponse respond (HttpRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        if (responseCode == 200) {
            resp.setBody('{"correlationId":"cd0d8150-86bd-11ef-a2bc-02628aef5fdf"}');
        } else {
            resp.setBody('{"message": "A fault has occurred.","errorDetails": {"message": "Unable to process response"}}');
        }
        resp.setStatusCode(responseCode);
        return resp;
    }

}