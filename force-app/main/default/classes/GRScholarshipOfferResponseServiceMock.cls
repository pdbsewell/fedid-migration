/*******************************************************************************
* @author		Vishal Gupta
* @date         12/02/2025    
* @description  Mock API response for GRScholarshipOfferResponseServic Class
* @revision     12/02/2025 - Initial Version
*******************************************************************************/
@isTest
public class GRScholarshipOfferResponseServiceMock implements HttpCalloutMock{
    public Integer responseCode {get; set;}

    /**
     * @author      Vishal Gupta
     * @description Mocks GR Scgolarship API for Callista integration
     * @param       req of type HttpRequest
     * @return      HttpResponse
     * @revision    12/02/2024 - Initial Version
     */
    public HttpResponse respond (HttpRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setHeader('Content-Type', 'application/json');
        if (responseCode == 200) {
            resp.setBody('{"correlationId": "cd0d8150-86bd-11ef-a2bc-02628aef5fdf","success": true}');
        } else {
            resp.setBody('{"message": "A fault has occurred.","errorDetails": {"message": "Unable to process response"}}');
        }
        resp.setStatusCode(responseCode);
        return resp;
    }

}