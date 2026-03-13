/**
 * @Class              : EnquiryWebService.cls
 * @Description        : Webservice class for handling enquiries from VerifyMeWeb 
 * @Author             : Idhanoa
 * @Group              : MOnash COnnect
 * @Revision           : 2024-05-03     Idhanoa   Created 
 */
@RestResource(urlMapping='/v2/EnquiryWS')
global with sharing class EnquiryWS {
    /**
	 * @description     creates an enquiry for VerifyMe Process 
	 * @param           JSON that can be serialized into object
	 * @return          JSON that follows  object
	 */
    @HttpPost
    global static void handleEnquiry() {
        // Initialize 
        new EnquiryWSImpl.HandlePost()
                 .setPayloadType(EnquiryWSPayload.GetRequest.class, EnquiryWSPayload.GetResponse.class).execute();
    }
}