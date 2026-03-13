/*******************************************************************************
* @author		Vishal Gupta
* @date         14/10/2024    
* @description  Mock API response for GRSendApplicationToCallistaService Class
* @revision     14/10/2024 - Initial Version
*******************************************************************************/
@isTest
public class GRSendApplicationToCallistaAPIMock implements HttpCalloutMock{

    /**
     * @author      Vishal Gupta
     * @description get/set of responseCode
     * @param       responseCode
     * @return      responseCode
     * @revision    14/10/2024 - Initial Version
     */
    public Integer responseCode {get; set;}

    /**
     * @author      Vishal Gupta
     * @description Mocks HDR Document creation API for Callista integration
     * @param       req of type HttpRequest
     * @return      HttpResponse
     * @revision    14/10/2024 - Initial Version
     */
    public HttpResponse respond (HttpRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        if (responseCode == 200) {
            resp.setBody('{"application":{"hdrApplicationNumber":"5239007"}}');
        } else {
            resp.setBody('{"message": "A fault has occurred.","errorDetails": {"message": "Unable to process response"}}');
        }
        resp.setStatusCode(responseCode);
        return resp;
    }

}