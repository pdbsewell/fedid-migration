/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-388 - Handle upload of "Campaign Member" records
 * @date            Apr.2024
 * @group			MOnash Connect
 * @revision
 *     2024-04 - Inderpal Dhanoa - MCT-388 - Upload Campaign member & ORC
*/
public with sharing class CampaignMemberCreator {

    public static Integer batchSize = 20;
    /**
     * All the data require to create or update a JRG Case
     */
    public class CampaignMemberOCRRequest {
        @AuraEnabled public String courseAttemptCallistaId {get;set;}
        @AuraEnabled public String personId {get;set;}
        @AuraEnabled public Integer inputCsvRow {get;set;}
    }
    
    /**
     * Represents an error when validating JrgCaseRequest
     */
    public class ValidationError {
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String reference {get;set;}
        public ValidationError(String message, String ref) {
            this.message = message; this.reference = ref;
        }
    }

    /**
     * Data to return to widget after submission
     */
    public class RequestResponse {
        @AuraEnabled public Boolean success {get;set;}
        @AuraEnabled public ValidationError[] errors {get;set;}
    }

    /**
     * Validate CampaignMemberOCRRequest objects by checking if lookup IDs exist
     */
    public static ValidationError[] validateRequests(CampaignMemberOCRRequest[] reqs) {

        // collect IDs from uploaded data
        Set<String> courseAttemptIds = new Set<String>();
        Set<String> personIds = new Set<String>();
        for(CampaignMemberOCRRequest cr :reqs) {
            courseAttemptIds.add(cr.courseAttemptCallistaId);
            personIds.add(cr.personId);
            
        }
        Set<String> existingCourseAttemptIds = new Set<String>();
        Set<String> existingPersonIds = new Set<String>();

        // query the existing IDs
        for(Course_Attempt__c c : [SELECT Callista_External_Id__c FROM Course_Attempt__c WHERE Callista_External_Id__c IN :courseAttemptIds]) {
            existingCourseAttemptIds.add(c.Callista_External_Id__c);
        }
        for(Contact c : [SELECT Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c IN :personIds]) {
            existingPersonIds.add(c.Person_ID_unique__c);
        }

        // remove all existing IDs - We are left with the missing IDs
        courseAttemptIds.removeAll(existingCourseAttemptIds);
        personIds.removeAll(existingPersonIds);

        ValidationError[] errors = new ValidationError[0];
        if(courseAttemptIds.size() > 0 || personIds.size() > 0) {
            // uploaded data has non-existent external Ids
            for(String courseAttemptId : courseAttemptIds) {
                errors.add(new ValidationError('Course Attempt Id not found', courseAttemptId));
            }
            for(String personId : personIds) {
                errors.add(new ValidationError('Person Id not found', personId));
            }
        }
        return errors;
    }

    /**
     * Validate request and submit Cases for creation by Batch class
     */
    @AuraEnabled
    public static RequestResponse submitCreationRequest(CampaignMemberOCRRequest[] requests, String engageTypeRequest, String campaignId) {
        ValidationError[] errors = validateRequests(requests);

        RequestResponse resp = new RequestResponse();
        resp.success = true;
        resp.errors = errors;

        if(errors.size() > 0) {
            resp.success = false; return resp;
        }

        // deduplicate requests (by ext id) and initialise count
        Map<String, Case> newCasesByExternalId = new Map<String, Case>();
        Map<String, CampaignMemberOCRRequest> campMembRequestsByExternalId = new Map<String, CampaignMemberOCRRequest>();
        Map<String, CampaignMemberOCRRequest> ocrRequestsByExternalId = new Map<String, CampaignMemberOCRRequest>();
        Set<String> s_allContactPersonIds = new Set<String>();
        Set<String> s_freshContactPersonIds = new Set<String>();
        Set<String> s_existCampPersonIds = new Set<String>();
        Map<String, String> m_freshCourseAttmptPersonIds = new Map<String, String>();
        Map<String, String> m_existLinkdCourseAttmptIds = new Map<String, String>();

        for(CampaignMemberOCRRequest req : requests) {
            s_allContactPersonIds.add(req.personId);
        }

        // Existing Campaign Members already linked to Contacts
        for(CampaignMember campMemb : [SELECT Contact.Person_ID_unique__c FROM CampaignMember WHERE CampaignId = :Id.valueOf(campaignId) AND Contact.Person_ID_unique__c IN :s_allContactPersonIds]){
            s_existCampPersonIds.add(campMemb.Contact.Person_ID_unique__c);
        }

        // Existing OCR's already linked to Contacts
        for(Outbound_Call_Result__c ocr : [SELECT Contact__r.Person_ID_unique__c, Course_Attempt__r.Callista_External_Id__c FROM Outbound_Call_Result__c WHERE Campaign__c = :Id.valueOf(campaignId) AND Contact__r.Person_ID_unique__c IN :s_allContactPersonIds]){
            m_existLinkdCourseAttmptIds.put(ocr.Course_Attempt__r.Callista_External_Id__c, ocr.Contact__r.Person_ID_unique__c);
        }

        for(CampaignMemberOCRRequest req : requests) {
            if(!s_existCampPersonIds.contains(req.personId)){
                s_freshContactPersonIds.add(req.personId);
                campMembRequestsByExternalId.put(createCampMemberExternalId(req), req);
            }
            // Check If the Course Attempt record already exists with the Callista and Person Id 
            if(!(m_existLinkdCourseAttmptIds.containsKey(req.courseAttemptCallistaId) && req.personId == m_existLinkdCourseAttmptIds.get(req.courseAttemptCallistaId))){
                m_freshCourseAttmptPersonIds.put(req.courseAttemptCallistaId, req.personId);
                ocrRequestsByExternalId.put(createOCRExternalId(req), req);
            }
        }

        Database.executeBatch(new MCCampMembBatch(m_freshCourseAttmptPersonIds, s_freshContactPersonIds, ocrRequestsByExternalId, campMembRequestsByExternalId, engageTypeRequest, campaignId), batchSize);
        return resp;
    }

    public static String createOCRExternalId(CampaignMemberOCRRequest req) {
        // Contact.Person_ID__c - Course_Attempt__c.Callista_External_Id__c
        return req.personId + '-' + req.courseAttemptCallistaId ;
    }

    public static String createCampMemberExternalId(CampaignMemberOCRRequest req) {
        // Contact.Person_ID__c
        return req.personId;
    }

    /*
    * Method Name: retrieveSampleFile
     * @Return String for ContentDocument
     * Description: Retrieve Sample File
    */
    @AuraEnabled
    public static String retrieveSampleFile(){
        try {
            List<ContentAsset> linkedAsset = [SELECT ContentDocumentId 
                                              FROM ContentAsset 
                                              WHERE DeveloperName = :String.valueOf(Label.CampaignMemberSampleFile)];
            return linkedAsset.isEmpty() ? '' : String.valueOf(linkedAsset[0].ContentDocumentId) ; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}