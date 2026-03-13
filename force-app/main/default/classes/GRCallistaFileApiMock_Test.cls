/*******************************************************************************
* @author		Sethu Venna
* @date         05/10/2024    
* @description  Mock API response for FileToCallistaInterface Class
* @revision     05/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class GRCallistaFileApiMock_Test implements HttpCalloutMock{

    /**
     * @author      Sethu Venna
     * @description get/set of responseCode
     * @param       responseCode
     * @return      responseCode
     * @revision    05/10/2024 - Initial Version
     */
    public Integer responseCode {get; set;}

    /**
     * @author      Sethu Venna
     * @description Mocks HDR Document creation API for Callista integration
     * @param       req of type HttpRequest
     * @return      HttpResponse
     * @revision    05/10/2024 - Initial Version
     */
    public HttpResponse respond (HttpRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        if (responseCode == 200) {
            resp.setBody('{"document" : {"id": "6854327"}}');
        } else {
            resp.setBody('{"message": "A fault has occurred.","errorDetails": {"message": "Unable to process response"}}');
        }
        resp.setStatusCode(responseCode);
        return resp;
    }

}