/*******************************************************************************
* @author       Vishal Gupta
* @date         4/11/2024
* @description  invoke callista interface v1/admissions/sms/applications/{applicationId}/hdr-document-requests/{requestSequenceNumber} to patch document request
* @revision      
* 4/11/2024 - Vishal Gupta - Created
*******************************************************************************/
public without sharing class GRDocumentRequestPatchToCallistaService extends UniCRMIntegrationPoint implements Database.AllowsCallouts {

    private static final String INTERFACE_NAME = 'IP12_GR_Callista_Document_Request_Patch';
    private static final String TAG = 'Callista document request patch callout';
    private static final String GRT_SCHOLARSHIP_APPLICATION_ONLY = 'Scholarship application only';
    private static final String GRADUATE_RESEARCH = 'Graduate Research';
    private final Set<String> documentChecklistCommentsFields = new Set<String>{
        'Request_Sequence_Number__c, API_Response__c, API_Request__c, Correlation_Id__c, Notify_Email_Addresses__c, Document_Checklist__r.Checklist_Requirement__c '
    };

    private Contact_Document__c conDoc;
    private String hdrDocId;
    private Document_Checklist_Comment__c checklistComment;
    private Application_Course_Preference__c acpInfo;
    private Application__c applicationInfo;

    /**
     * @author      Vishal Gupta
     * @description Constructor
     * @revision    4/11/2024 - Initial Version
     */
    public GRDocumentRequestPatchToCallistaService (Contact_Document__c conDoc, String hdrDocId) {
        this.conDoc = conDoc;
        this.hdrDocId = hdrDocId;
        this.doInit(INTERFACE_NAME);
    }

    /**
     * @author      Vishal Gupta
     * @description creates request body for the call out
     * @revision    4/11/2024 - Initial Version
     */
    public void createRequestBody(){
      
        try {
            String applicationId;
            Integer requestSeqNumber;
            //replace the applicationId and reqSeqNumber in endpoint : admissions/sms/applications/{applicationId}/hdr-document-requests/{requestSequenceNumber}
            Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
            GRDocumentRequestPatchJSON reqJson = new GRDocumentRequestPatchJSON();
            GRDocumentRequestPatchJSON.HDRDocumentRequest hdrDocumentRequest = new GRDocumentRequestPatchJSON.HDRDocumentRequest();
            List<Application__c> applicationData = new ApplicationsSelector().selectByIdWithParentDetailsAndDocuments(new Set<Id>{conDoc.Application__c});
            if(!applicationData.isEmpty()) {
                applicationInfo = applicationData[0];
                List<Application_Course_Preference__c> lstACP = new ApplicationCoursePreferenceSelector().selectByApplicationIdWithParentDetails(new Set<Id>{conDoc.Application__c});
                     
                if(!lstACP.isEmpty() && !String.isBlank(lstACP[0].GradRes_Callista_Id__c)) {
                    acpInfo = lstACP[0];
                    hdrDocumentRequest.hdrApplicationNumber = Integer.valueOf(lstACP[0].GradRes_Callista_Id__c);
                }
                if(!String.isBlank(hdrDocId)) {
                    hdrDocumentRequest.smsDocumentId = Integer.valueOf(hdrDocId);
                }       
                hdrDocumentRequest.submittedDate = String.valueOf(Date.valueOf(conDoc.CreatedDate));
                if(applicationInfo.Type_of_Study__c == GRADUATE_RESEARCH 
                && applicationInfo.Graduate_Research_Application_Type__c == GRT_SCHOLARSHIP_APPLICATION_ONLY
                && applicationInfo.Parent_Application__c != null){
                    hdrDocumentRequest.applicantId = !String.isBlank(applicationInfo.Parent_Application__r.Callista_Applicant_Id__c) ? Integer.valueOf(applicationInfo.Parent_Application__r.Callista_Applicant_Id__c) : null;
                    applicationId = applicationInfo.Parent_Application__r.Callista_Application_Id__c;
                }else{
                    hdrDocumentRequest.applicantId = !String.isBlank(applicationInfo.Callista_Applicant_Id__c) ? Integer.valueOf(applicationInfo.Callista_Applicant_Id__c) : null;
                    applicationId = applicationInfo.Callista_Application_Id__c;
                }
                urlReplaceKeyValuePairs.put('{applicationId}', applicationId);//replacing the the value in URL

                List<Document_Checklist_Comment__c> comments = selectCommentsByChecklistId(conDoc.Document_Checklist__c);
                if(!comments.isEmpty()) {
                    checklistComment = comments[0];
                    requestSeqNumber = comments[0].Request_Sequence_Number__c != null ? Integer.valueOf(comments[0].Request_Sequence_Number__c) : null;
                }
                if(requestSeqNumber != null) {
                    hdrDocumentRequest.requestSequenceNumber = requestSeqNumber;
                    urlReplaceKeyValuePairs.put('{requestSequenceNumber}', String.valueOf(requestSeqNumber));
                }
                reqJson.hdrDocumentRequest = hdrDocumentRequest;       
            }
            this.jsonRequest = reqJson;
            this.constructEndPoint(urlReplaceKeyValuePairs);            
        }catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }

    /**
     * @author      Vishal Gupta
     * @description Read the web service call response & update fields on the Contact Document
     *              records after the call out
     * @revision    4/11/2024 - Initial Version
    */
    public void handleResponse()
    {
        try {
            String correlationId;
            if(checklistComment != null) {
                checklistComment.API_Request__c = jSON.serializePretty(jsonRequest);
                Map<String,Object> respBody = this.getResponseBody();
                checklistComment.API_Response__c = jSON.serialize(respBody);
                if (this.httpResponseCode == 200) {                    
                    if(respBody.containsKey('correlationId')) {
                        correlationId = String.valueOf(respBody.get('correlationId'));
                        checklistComment.Correlation_Id__c = correlationId;
                        Nebula.logger.info('correlationId returned from callista: ' + correlationId).addTag(TAG);

                                          
                    }                    
                } 
                else{
                    Nebula.Logger.info('Response from GRDocumentRequestPatchToCallistaService: '+string.valueOf(this.httpResponseCode)).addTag(TAG);
                }
                update checklistComment; 

                //form the email response and send to the assessor
                if(!String.isBlank(checklistComment.Notify_Email_Addresses__c) && correlationId != null) {
                    generateEmailResponse();
                }      
             }
        }catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }

    /**
     * @author      Vishal Gupta
     * @description form the email template and send it to the assessor
     * @revision    5/12/2024 - Initial Version
    */
    public void generateEmailResponse()
    {
        GRDocumentRequestEmailController emailJson = new GRDocumentRequestEmailController();
        try {
            if(checklistComment != null && applicationInfo != null && acpInfo != null) {
                List<Contact> applicantList = new ContactsSelector().selectById(new Set<Id>{applicationInfo.Applicant__c});
                if(!applicantList.isEmpty()) {
                    String title = applicantList[0].Salutation != null ?  applicantList[0].Salutation : '';
                    String firstName = applicantList[0].FirstName != null ?  applicantList[0].FirstName : '';
                    String lastName = applicantList[0].LastName;
                    emailJson.applicantName = title + ' ' + firstName + ' ' + lastName;
                    emailJson.personId = applicantList[0].Person_ID_unique__c;
                }

                emailJson.applicationId = acpInfo.GradRes_Callista_id__c;
                emailJson.applicationType = applicationInfo.Type_of_Study__c;
                emailJson.courseTitle = acpInfo.Course_Title__c;
                emailJson.documentType = checklistComment.Document_Checklist__r.Checklist_Requirement__c;
                emailJson.recipientEmail = checklistComment.Notify_Email_Addresses__c;
                String jsonRequestString = JSON.serializePretty(emailJson);
                //email will be sent via platform event flow as a workaround because with the current user execution mode, user doesnt have access to the org wide email 
                Async_Process__e event = new Async_Process__e(
                    Process_Name__c = 'GRDocumentRequestEmailController',
                    Parameter__c = jsonRequestString
                );
                // Fire the event
                Database.SaveResult result = EventBus.publish(event);
            }
        }catch (Exception ex) {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }

    /**
     * @description query Document_Checklist_Comment__c record
     * @param documentChecklistId
     * @return `List<Document_Checklist_Comment__c>`
     */
    public List<Document_Checklist_Comment__c> selectCommentsByChecklistId(Id documentChecklistId) {
        DynamicSoqlBuilder soqlBuilder = DynamicSoqlBuilder.getInstance()
                                                            .setEnforced(false) // do not enforce sharing for elevated access
                                                            .validateFields(false); // no need to validate fields, they are static.
        String whereClause = 'Document_Checklist__c = :documentChecklistId AND Cancelled__c = false AND Correlation_Id__c = null ORDER BY Request_Sequence_Number__c DESC LIMIT 1';
        String soqlStr = soqlBuilder.querySObject('Document_Checklist_Comment__c')
            .queryFields(documentChecklistCommentsFields)
            .getQuery(whereClause);
        return Database.query(soqlStr);
    }
    
}