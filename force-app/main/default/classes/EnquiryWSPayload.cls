/**
 * @Class              : EnquiryWSPayload.cls
 * @Description        : Webservice class for handling enquiries from VerifyMeWeb 
 * @Author             : Idhanoa
 * @Group              : MOnash COnnect
 * @Revision           : 2024-05-03     Idhanoa   Created 
 */
public inherited sharing class EnquiryWSPayload {
    /**
     * @description request payload of (POST) Endpoint '/v2/EnquiryWS'
     */
    public virtual class GetRequest extends RESTlib_Payload.Request {
        public CDM_Enquiry enquiry { get; set; }
    }
    /**
     * @description response payload of (POST) Endpoint '/v2/EnquiryWS'
     */
    public virtual class GetResponse extends RESTlib_Payload.Response {
        public String responseType { get; set; }
        public String outcome { get; set; }
    }
    /**
     * @description request payload sub-wrapper of (POST) Endpoint '/v2/EnquiryWS'
     */
    public class CDM_Enquiry {
        public string operationName { get; set; }
        public string categoryLevel1 { get; set; }
        public string categoryLevel2 { get; set; }
        public string subject { get; set; }
        public string content { get; set; }
        public string origin { get; set; }
        public string recordtypeDeveloperName { get; set; }
        public string type{ get; set; }
        public List<CDM_Reference> references{ get; set; }
    }
    /**
     * @description request payload sub-wrapper of (POST) Endpoint '/v2/EnquiryWS'
     */
    public class CDM_Reference {
        public String key { get; set; }
        public List<CDM_Value> value{ get; set; }
    }
    /**
     * @description request payload sub-wrapper of (POST)  Endpoint '/v2/EnquiryWS'
     */
    public class CDM_Value {
        public String id { get; set; }
        public String description { get; set; }
    }
}