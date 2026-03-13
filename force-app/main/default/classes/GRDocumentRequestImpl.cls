/**
 * @description Implementation class for GRDocumentRequestImplFactory
 * @author      Vishal Gupta
 * @since       21.10.2024
 * @revision
 */
public with sharing class GRDocumentRequestImpl implements RESTlib_IClientImpl {
    private static List<Application_Course_Preference__c> lstACP = new List<Application_Course_Preference__c>();
    private static List<Document_Checklist__c> lstDocChecklist = new List<Document_Checklist__c>();
    private static Id applicationId;
    private static Integer claimSeqNumber;
    private static final String DOC_REQUEST_TYPE_ENGLISH = 'ENG-TEST';
    private static final String RECORD_TYPE_ENG = 'English_Test';
    private static final String DOC_REQUEST_TYPE_MISC = 'MISC-DOC';
    private static final String RECORD_TYPE_MISC = 'Other_Qualification';
    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandleGet() {
        return null; // Not implemented yet
    }

    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePost() {
        return new HandlePost();
    }

    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePut() {
        return null; // Not implemented yet
    }

    /**
     * @description Should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePatch() {
        return null; // Not implemented yet
    }

    /**
     * @description Processes POST requests for document request,
     *              handling validation, processing request.
     * @author      Vishal Gupta
     * @since       21/10/2024
     */
    public with sharing virtual class HandlePost extends RESTlib_ClientImplHandler {
        private final Utils utils = new Utils();
        /**
         * @description Set request type
         * @return `Type`
         */
        public override Type getRequestType() {
            return GRDocumentRequestPayload.PostRequest.class;
        }

        /**
         * @description Set response type
         * @return `Type`
         */
        public override Type getResponseType() {
            return GRDocumentRequestPayload.PostResponse.class;
        }

        /**
         * @description Validation rules
         * @param reqObj Request
         * @throws RESTlib_Ex.InvalidRequestException Custom exception
         */
        public override void validate(RESTlib_Payload.Request reqObj) {
            String msg = '';
            try {
                GRDocumentRequestPayload.PostRequest req = (GRDocumentRequestPayload.PostRequest) reqObj;
                if(String.isBlank(req.applicantId)) {
                    msg = 'The applicant Id cannot be blank';
                    utils.logErrorWithRequest(msg);
                    throw new RESTlib_Ex.InvalidRequestException(msg);
                } 
    
                if(String.isBlank(req.hdrApplicationNumber)) {
                    msg = 'The HDR Application Number cannot be blank';
                    utils.logErrorWithRequest(msg);
                    throw new RESTlib_Ex.InvalidRequestException(msg);
                }
    
                if(String.isBlank(req.requestType)) {
                    msg = 'The Document request type cannot be blank';
                    utils.logErrorWithRequest(msg);
                    throw new RESTlib_Ex.InvalidRequestException(msg);
                }
    
                //get the ApplicationCoursePreference from HDR Application Id
                lstACP = new ApplicationCoursePreferenceSelector().selectByHDRApplicationAndApplicantId(req.hdrApplicationNumber, req.applicantId);
    
                if(lstACP.isEmpty()) {
                    msg = 'Application not found';
                    utils.logErrorWithRequest(msg);
                    throw new RESTlib_Ex.InvalidRequestException(msg);
                } else {
                    applicationId = lstACP[0].Application__c;
                    claimSeqNumber = req.claimSequenceNumber;
                    //get the Document checklist from Application Id and document type
                    lstDocChecklist = new DocumentChecklistsSelector().selectApplicationAssessmentByApplicationIdAndSequenceNumber(applicationId, req.requestType, req.claimSequenceNumber);
                }
    
                if(lstDocChecklist.isEmpty() && req.claimSequenceNumber != null && req.requestType != DOC_REQUEST_TYPE_ENGLISH && req.requestType != DOC_REQUEST_TYPE_MISC) {
                    msg = 'Document not found';
                    utils.logErrorWithRequest(msg);
                    throw new RESTlib_Ex.InvalidRequestException(msg);
                }

                if(lstDocChecklist.isEmpty() && req.requestType != DOC_REQUEST_TYPE_ENGLISH && req.requestType != DOC_REQUEST_TYPE_MISC) {
                    msg = 'Document not found';
                    utils.logErrorWithRequest(msg);
                    throw new RESTlib_Ex.InvalidRequestException(msg);
                }
            } catch (Exception ex) {
                Nebula.Logger.error(ex.getMessage(), ex);
                throw new RESTlib_Ex.InvalidRequestException(ex.getMessage());
            }
        }

        /**
         * @description Creates a Content Document based on the payload request
         * @param reqObj Request
         * @param responseObj Response
         * @return RESTlib_Payload.Response
         * @throws RESTlib_Ex.InvalidRequestException Custom exception
         */
        public override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            nebula.Logger.finest('process').setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI);
            GRDocumentRequestPayload.PostRequest req = (GRDocumentRequestPayload.PostRequest) reqObj;
            Datetime requestDate = req.requestDate != null ? Datetime.valueOfGmt(req.requestDate.replace('T',' ')) : null;
            GRDocumentRequestPayload.PostResponse resp = (GRDocumentRequestPayload.PostResponse) responseObj;
            //if there is cancelled date in the request then we have to find the existing comment and cancel it
            List<Document_Checklist_Comment__c> lstComments = new List<Document_Checklist_Comment__c>();
            try {
                if(!lstDocChecklist.isEmpty()) {
                    // if there is a cancelled date in the payload then cancel the checklist comment
                    if(req.cancelledDate != null && !lstDocChecklist[0].Document_Checklist_Comments__r.isEmpty()) {
                        for(Document_Checklist_Comment__c dcComment : lstDocChecklist[0].Document_Checklist_Comments__r) {
                            if(dcComment.Content__c == req.requestReason && !dcComment.Cancelled__c) {
                                dcComment.Cancelled__c = true;
                                dcComment.Cancelled_Date__c = Datetime.valueOfGmt(req.cancelledDate.replace('T',' '));
                                lstComments.add(dcComment);
                            }
                        }
                        update lstComments;
                        updateChecklist(lstDocChecklist[0], 'Submitted');
                        return resp;
                    }
                    //else insert the document checklist comment
                    insertDocChecklistComment(lstDocChecklist[0].Id, req.requestReason, requestDate, req.requestSequenceNumber, req.notifyEmailAddresses);
                    updateChecklist(lstDocChecklist[0], 'Insufficient');
                } else if(req.requestType == DOC_REQUEST_TYPE_ENGLISH || req.requestType == DOC_REQUEST_TYPE_MISC) {//if there is no checklist and the request type is either english/misc doc
                    List<Contact_Qualification__c> lstQual = getContactQualifications(RECORD_TYPE_ENG);//get the english contact qualification 
                    Contact_Qualification__c cq = new Contact_Qualification__c();
                    Id docChecklistId;
                    if(req.requestType == DOC_REQUEST_TYPE_ENGLISH) { 
                        //for english type of document request, we need to update the existing contact qualification                   
                        cq.Id = lstQual[0].Id;
                        cq.English_doc_required_during_assessment__c = true;
                        upsertContactQual(cq, lstQual[0].Contact__c, RECORD_TYPE_ENG);                    
                    } else if(req.requestType == DOC_REQUEST_TYPE_MISC) {
                        //create new misc doc    
                        cq.Title_of_Publication_Work_Chapter_Paper__c = String.isNotBlank(req.description) ? req.description.replaceFirst('MISC-DOC', '').replaceFirst('/','').trim() : req.requestReason;
                        cq.Other_Qualification__c = 'MISC-DOC';
                        upsertContactQual(cq, lstQual[0].Contact__c, RECORD_TYPE_MISC);
                    }
                    //run the checklist rules to create the doc checklist for eng/misc doc requirement
                    DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{applicationId});
                    rulesDocChecklistEngine.evaluateRules('Application Assessment');
                    List<Document_Checklist__c> resultChecklistItemsList = rulesDocChecklistEngine.resultChecklistItemsMap.get(applicationId).values();
                    upsert resultChecklistItemsList;
                    
                    //inserting the checklist comment
                    for(Document_Checklist__c dc : resultChecklistItemsList) {
                        if(dc.Contact_Qualification__c == cq.Id) {
                            docChecklistId = dc.Id;
                        }
                    }
                    if(docChecklistId != null) {
                        //insert the document checklist comment for english qualification only
                        insertDocChecklistComment(docChecklistId, req.requestReason, requestDate, req.requestSequenceNumber, req.notifyEmailAddresses);
                    }
                }
            } catch (Exception ex) {
                Nebula.Logger.error(ex.getMessage(), ex);
                throw new RESTlib_Ex.DeveloperException(ex.getMessage());
            }
            
            return resp;
        }

        /**
         * @description function to insert the checklist comments
         * @param checklistId
         * @param content
         * @param requestDate
         * @param reqSeqNum
         * @param notifyEmailAddresses
         */
        private void insertDocChecklistComment(Id checklistId, String content, DateTime requestDate, Integer reqSeqNum, String notifyEmailAddresses) {
            insert new Document_Checklist_Comment__c(
                Document_Checklist__c = checklistId,
                Content__c = content,
                Request_Date__c = requestDate,
                Request_Sequence_Number__c = reqSeqNum,
                Notify_Email_Addresses__c = notifyEmailAddresses
            );
        }

        /**
         * @description function to update the checklist
         * @param checklist
         * @param status
         */
        private void updateChecklist(Document_Checklist__c checklist, String status) {
            checklist.status__c = status;
            update checklist;
        }

        /**
         * @description function to upsert the Contact Qualifications options for Graduate Research
         * @param cq
         * @param contactId
         * @param recordTypeName
         */
        private void upsertContactQual(Contact_Qualification__c cq, Id contactId, String recordTypeName) {
            Boolean isExisting = false;
            if(cq.Id != null) {
                isExisting = true;
            }
            cq.recordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
            cq.Contact__c = contactId;
                        
            Database.UpsertResult upr = Database.upsert(cq);
            if(!isExisting) {
                // new qualification, attach to current application
                Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
                aqp.Contact_Qualification__c = cq.Id;
                aqp.Sequence_Number__c = claimSeqNumber;
                aqp.Application__c = applicationId;
                Database.SaveResult sr = Database.insert(aqp);
            }
        }

        /**
         * @description function to retrieve the Contact Qualifications by recordTypeName
         * @param recordTypeName
         */
        public List<Contact_Qualification__c> getContactQualifications(String recordTypeName){
            Id recordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
            List<Contact_Qualification__c> qualifications = new List<Contact_Qualification__c>();
            for(Contact_Qualification__c cq : new ContactQualificationsSelector().selectByApplicationId(new Set<Id>{applicationId})){
                if(cq.RecordTypeId == recordTypeId) {
                    qualifications.add(cq);
                }
            }
            
            return qualifications;
        }
    }

    /**
     * @description Classes for helper methods.
     */
    private with sharing class Utils {
        /**
        * @description  log error with request
        * @param message error message
        */
        private void logErrorWithRequest(String message) {
            nebula.Logger.error(message).setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI);
        }
    } 
}