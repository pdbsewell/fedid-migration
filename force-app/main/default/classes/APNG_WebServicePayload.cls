/**
 * @description Contains the payload (request / response) data structure of Agent Portal Webservices.
 * @author      Nick Guia
 * @date        SEPT.25.2023
 * @group       Admissions
 * @see         https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/328925218/APNG+-+Enquiry+Management+LLD
 */
global with sharing class APNG_WebServicePayload {

    /**
     * @description the base response structure 
     */
    global virtual class APNG_BaseResponse {
        global Boolean success { get; set; }
        global String description { get; set; }
        global String error { get; set; }
    }

    /**
     * @description response payload of (GET) AgentManagementWebService
     */
    global virtual class APNG_AgentManagementWebService_GetResponse extends APNG_BaseResponse {
        global User userRecord { get; set; }
        global List<UserLogin> userLoginList { get; set ;}
        global Contact contactRecord { get; set; }
        global Account accountRecord { get; set; }
        global List<AccountPartner> accountPartnerList { get; set; }
    }

    /**
     * @description response payload for APNG_EnquiryWebService.doGet()
     */
    global virtual class APNG_EnquiryWebService_GetResponse extends APNG_BaseResponse {
        global Case enquiryDetails { get; set; }
        global List<CaseFeed> caseFeedList { get; set; }

        global APNG_EnquiryWebService_GetResponse() {
            this.caseFeedList = new List<CaseFeed>();
        }
    }
}