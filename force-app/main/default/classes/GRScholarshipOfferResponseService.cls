/*******************************************************************************
* @author       Vishal Gupta
* @date         10/02/2025
* @description  invoke callista interface v1/admissions/sms/applications/{applicationId}/scholarship to patch scholarship response
* @revision      
* 10/02/2025 - Vishal Gupta - Created
*******************************************************************************/
public without sharing class GRScholarshipOfferResponseService extends UniCRMIntegrationPoint implements Database.AllowsCallouts {

    private static final String INTERFACE_NAME = 'IP13_GR_Scholarship_Response_Patch';
    private static final String TAG = 'GRScholarshipOfferResponseService';
    private String applicantId;
    private String hdrApplicationId;
    private String offerStatus;
    private String responseStatus;
    private Boolean proceedWithScholarship;
    private String declineReason;
    private String quoteId;

    /**
     * @author      Vishal Gupta
     * @description Constructor
     * @revision    11/2/2025 - Initial Version
     */
    public GRScholarshipOfferResponseService (String payload) {
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> requestMap = (Map<String, Object>)jsonMap.get('args');
        this.quoteId = requestMap.get('quoteId') != null ? String.valueOf(requestMap.get('quoteId')) : '';
        this.applicantId = requestMap.get('applicantId') != null ? String.valueOf(requestMap.get('applicantId')) : '';
        this.hdrApplicationId = requestMap.get('applicationId') != null ? String.valueOf(requestMap.get('applicationId')) : '';
        this.offerStatus = requestMap.get('offerStatus') != null ? String.valueOf(requestMap.get('offerStatus')) : '';
        this.responseStatus = requestMap.get('responseStatus') != null ? String.valueOf(requestMap.get('responseStatus')) : '';
        this.proceedWithScholarship = requestMap.get('continueCandidatureWithoutScholarshipFlag') != null ? Boolean.valueOf(requestMap.get('continueCandidatureWithoutScholarshipFlag')) : null;
        this.declineReason = requestMap.get('responseReason') != null ? String.valueOf(requestMap.get('responseReason')) : '';
        this.doInit(INTERFACE_NAME);
    }

    /**
     * @author      Vishal Gupta
     * @description creates request body for the call out
     * @revision    11/2/2025 - Initial Version
     */
    public void createRequestBody(){
      
        try {
            //replace the applicationId and reqSeqNumber in endpoint : admissions/sms/applications/{applicationId}/hdr-document-requests/{requestSequenceNumber}
            Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
            GRScholarshipOfferResponseJSON reqJson = new GRScholarshipOfferResponseJSON();
            GRScholarshipOfferResponseJSON.Scholarship scholarship = new GRScholarshipOfferResponseJSON.Scholarship();
            GRScholarshipOfferResponseJSON.Applicant applicant = new GRScholarshipOfferResponseJSON.Applicant();
            GRScholarshipOfferResponseJSON.Application application = new GRScholarshipOfferResponseJSON.Application();
            GRScholarshipOfferResponseJSON.ApplicationDetails applicationDetails = new GRScholarshipOfferResponseJSON.ApplicationDetails();
            GRScholarshipOfferResponseJSON.HdrApplicationDetails hdrApplicationDetails = new GRScholarshipOfferResponseJSON.HdrApplicationDetails();
            applicant.smsContactId = applicantId;
            applicationDetails.applicant = applicant;
            hdrApplicationDetails.hdrApplicationNumber = hdrApplicationId;
            application.hdrApplicationDetails = hdrApplicationDetails;
            applicationDetails.application = application;
            scholarship.applicationDetails = applicationDetails;
            scholarship.offerStatus = offerStatus;
            if(String.isNotBlank(responseStatus)) {
                scholarship.responseStatus = responseStatus;
            }
            
            if(String.isNotBlank(declineReason)) {
                scholarship.responseReason = declineReason;
            }
            
            if(proceedWithScholarship != null) {
                scholarship.continueCandidatureWithoutScholarshipFlag = proceedWithScholarship;
            }
            
            urlReplaceKeyValuePairs.put('{applicationId}', hdrApplicationId);//replacing the the value in URL
            reqJson.scholarship = scholarship; 
            String jsonCusString = JSON.serialize( reqJson, true);
            this.jsonRequest = (Object)JSON.deserializeUntyped(jsonCusString); 
            this.constructEndPoint(urlReplaceKeyValuePairs);            
        }catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex).addTag(TAG);
        }
        Nebula.Logger.saveLog();
    }

    /**
     * @author      Vishal Gupta
     * @description Read the web service call response & update fields on the quote
     *              records after the call out
     * @revision    10/2/2025 - Initial Version
    */
    public void handleResponse()
    {   
        try {
            if(quoteId != null) {
                SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteId);
                quote.API_Request__c = jSON.serializePretty(jsonRequest);
                Map<String,Object> respBody = this.getResponseBody();
                quote.API_Response__c = jSON.serialize(respBody);
                update quote;
                if (this.httpResponseCode == 200) {
                    if(respBody.containsKey('correlationId')) {
                        Nebula.logger.info('correlationId returned from callista: ' + String.valueOf(respBody.get('correlationId'))).addTag(TAG);                                          
                    }                    
                } 
                else{
                    Nebula.Logger.info('Response from GRScholarshipOfferResponseService: '+String.valueOf(this.httpResponseCode)).addTag(TAG);
                }
            }
        }catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex).addTag(TAG);
        }
        Nebula.Logger.saveLog();
    }
    /**
     * @author      Vishal Gupta
     * @description class for Async platform event to capture the event for scholarship response
     * @revision    12/2/2025 - Initial Version
     */
    public class GRScholarshipOfferResponseServiceCallout implements IPlatformEventInvocable {
        public void execute(List<AsyncProcessPayload> payloads) {
            if(payloads != null) {
                String jsonStr = JSON.serialize(payloads[0]);
                GRScholarshipOfferResponseService.scholarshipCallout(jsonStr);                
            }
        }
    }

    /**
     * @author      Vishal Gupta
     * @description scholarship service response callout
     * @revision    12/2/2025 - Initial Version
     */
    @future(callout=true)
    public static void scholarshipCallout(String asyncPayload ) {
        //Call the response web service
        GRScholarshipOfferResponseService docReqPatchService = new GRScholarshipOfferResponseService(
                            asyncPayload
                        );
                        docReqPatchService.createRequestBody();
                        docReqPatchService.sendMessage();
                        docReqPatchService.handleResponse();
    }
    
    /**
    * @description form the async process platform event. 
    * @param quoteId
    * @param applicationId
    * @param applicantId
    * @param offerStatus
    * @param responseStatus
    * @param responseReason
    * @param continueCandidatureWithoutScholarshipFlag
    * @return Async_Process__e
    */
    public static Async_Process__e formAsyncPayload(String quoteId, String applicationId, String applicantId, String offerStatus, String responseStatus, String responseReason, Boolean continueCandidatureWithoutScholarshipFlag) {
        AsyncProcessPayload payload = new AsyncProcessPayload();
        payload.put ('applicationId', applicationId);
        payload.put ('applicantId', applicantId);
        payload.put ('offerStatus', offerStatus);
        payload.put ('quoteId', quoteId);
        if(responseStatus != null) {
            payload.put ('responseStatus', responseStatus);
        }
        if(responseReason != null) {
            payload.put ('responseReason', responseReason);
        }
        if(continueCandidatureWithoutScholarshipFlag != null) {
            payload.put ('continueCandidatureWithoutScholarshipFlag', continueCandidatureWithoutScholarshipFlag);
        }
        Async_Process__e evt = new Async_Process__e (
            Process_Name__c = 'GRScholarshipOfferResponseService.GRScholarshipOfferResponseServiceCallout',
            Parameter__c = payload.serialize()
        );
        return evt;
    }
}