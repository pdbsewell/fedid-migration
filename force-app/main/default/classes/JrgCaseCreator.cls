/**
 * @author          tom.gangemi@monash.edu
 * @description		SA-1629 JRG - Handle upload of "JRG Case" records
 * @date            Jul.2022
 * @group			Student Administration
 * @revision
 *     2022-08 - Tom Gangemi - SA-1806 - Add Risk Category > Priority mapping
 *     2024-06   Idhanoa     Enhancement to create OCR & Campaign Member (MCT-404)
 *     2024-07   Idhanoa     Enhancement to change OCR creation (MCT-414)
*/
public with sharing class JrgCaseCreator {

    /**
     * @author          tom.gangemi@monash.edu
     * @description All the data require to create or update a JRG Case
     */
    public class JrgCaseRequest {
        @AuraEnabled public Integer inputCsvRow {get;set;} // input Csv Row
        @AuraEnabled public String personId {get;set;} // Person Id
        @AuraEnabled public String courseAttemptCallistaId {get;set;} // course Attempt Callista Id 
        @AuraEnabled public String calendarCode {get;set;} // calendar Code
        @AuraEnabled public String outreachCategory {get;set;} // Case.Risk_Category__c
        @AuraEnabled public String outreachPriority {get;set;} // Case.Priority
        @AuraEnabled public String suppliedState {get;set;} // supplied State
        @AuraEnabled public String unitCode {get;set;} // unit Code
    }

    /**
     * @author      tom.gangemi@monash.edu
     * @description Represents an error when validating JrgCaseRequest
     */
    public class ValidationError {
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String reference {get;set;}
        /**
         * @description Consolidate the Error message 
         * @param message Error message 
         * @param ref reference 
         */
        public ValidationError(String message, String ref) {
            this.message = message;
            this.reference = ref;
        }
    }

    /**
     * @author      tom.gangemi@monash.edu
     * @description Data to return to widget after submission
     */
    public class RequestResponse {
        @AuraEnabled public Boolean success {get;set;}
        @AuraEnabled public ValidationError[] errors {get;set;}
    }

    static Campaign[] campaignResult = new Campaign[0]; // New Campaign

    /**
     * @description Validate JrgCaseRequest objects by checking if lookup IDs exist
     * @param reqs Array of JRG requests
     * @param campaignResult Array of Campaign Result
     * @return Array of the Wrapper Error 
     */
    public static ValidationError[] validateRequests(JrgCaseRequest[] reqs, Campaign[] campaignResult) {

        // collect IDs from uploaded data
        Set<String> courseAttemptIds = new Set<String>();
        Set<String> calendarCodes = new Set<String>();
        Set<String> personIds = new Set<String>();
        for(JrgCaseRequest cr :reqs) {
            courseAttemptIds.add(cr.courseAttemptCallistaId);
            calendarCodes.add(cr.calendarCode);
            personIds.add(cr.personId);
        }
        Set<String> existingCourseAttemptIds = new Set<String>();
        Set<String> existingCalendarCodes = new Set<String>();
        Set<String> existingPersonIds = new Set<String>();

        // query the existing IDs
        for(Course_Attempt__c c :[
            SELECT Callista_External_Id__c FROM Course_Attempt__c WHERE Callista_External_Id__c IN :courseAttemptIds
        ]) {
            existingCourseAttemptIds.add(c.Callista_External_Id__c);
        }
        for(Calendar__c c :[
            SELECT Calendar_Code__c FROM Calendar__c WHERE Calendar_Code__c IN :calendarCodes
        ]) {
            existingCalendarCodes.add(c.Calendar_Code__c);
        }
        for(Contact c :[
            SELECT Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c IN :personIds
        ]) {
            existingPersonIds.add(c.Person_ID_unique__c);
        }

        // remove all existing IDs - We are left with the missing IDs
        courseAttemptIds.removeAll(existingCourseAttemptIds);
        calendarCodes.removeAll(existingCalendarCodes);
        personIds.removeAll(existingPersonIds);

        ValidationError[] errors = new ValidationError[0];
        if(campaignResult.isEmpty()) {
            errors.add(new ValidationError('JRG Campaign not found', ''));
        }
        // Check if the Campaign is EndDated
        if(campaignResult[0].EndDate < Date.today() ){
            errors.add(new ValidationError(String.valueOf(Label.MC_Campaign_End_Date), ''));
        }
        if(courseAttemptIds.size() > 0 || calendarCodes.size() > 0 || personIds.size() > 0) {
            // uploaded data has non-existent external Ids
            for(String courseAttemptId :courseAttemptIds) {
                errors.add(new ValidationError('Course Attempt Id not found', courseAttemptId));
            }
            for(String calendarCode :calendarCodes) {
                errors.add(new ValidationError('Calendar Code not found', calendarCode));
            }
            for(String personId :personIds) {
                errors.add(new ValidationError('Person Id not found', personId));
            }
        }
        return errors;
    }

    final static Id RTID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Support').getRecordTypeId();
    final static Id OWNERID = [SELECT Id FROM Group WHERE DeveloperName = 'Intermission' AND Type = 'Queue' LIMIT 1].Id;

    /**
     * @description Create Case sobject from given JrgCaseRequest object
     * @param req Wrapper class for JRG Case request
     * @return Case object record
     */
    public static Case createCase(JrgCaseRequest req) {

        Case c = new Case(
            Contact = new Contact(Person_ID_unique__c = req.personId),
            Course_Attempt__r = new Course_Attempt__c(Callista_External_Id__c = req.courseAttemptCallistaId),
            Calendar__r = new Calendar__c(Calendar_Code__c = req.calendarCode),
            OwnerId = OWNERID,
            RecordTypeId = RTID,
            Enquiry_Type__c = 'JRG',
            Category_Level_1__c = 'Engagement',
            Origin = 'Retention - System Generated',
            Risk_Category__c = req.outreachCategory,
            Alias__c = createExternalId(req), // alias field used for ext id
            Number_Of_Occurrences__c = 1,
            Subject = req.personId + ' - JRG - ' + req.calendarCode,
            Priority = req.outreachPriority,
            Supplied_State__c = req.suppliedState,
            Unit_Code__c = req.unitCode
        );

        if(campaignResult.size() > 0) {
            c.Campaign__c = campaignResult[0].Id;
        }

        if(new Set<String>{'WCI_MO','WCI_MC','MO'}.contains(req.suppliedState)) {
            c.Status = 'Solved';
            c.Case_Outcome__c = 'No Action';
        }

        return c;
    }

    /**
     * @description Create External Id
     * @param req class for JRG Case request
     * @return String for result
     */
    public static String createExternalId(JrgCaseRequest req) {
        // Contact.Person_ID__c - Course_Attempt__c.Callista_External_Id__c - Calendar__c.Calendar_Code__c
        return req.personId + '-' + req.courseAttemptCallistaId + '-' + req.calendarCode;
    }

    public static Integer batchSize = 20;

    /**
     * @description Validate request and submit JRG Cases for creation by Batch class
     * @param requests Aray of Wrapper class for JRG Case request
     * @param campaignId String for campaign Id
     * @return Wrapper for response
     */
    @AuraEnabled
    public static RequestResponse submitCreationRequest(JrgCaseRequest[] requests, String campaignId) {
        campaignResult = [SELECT Id, EndDate FROM Campaign WHERE Id = :Id.valueOf(campaignId) ORDER BY CreatedDate DESC LIMIT 1];
        ValidationError[] errors = validateRequests(requests, campaignResult);

        RequestResponse resp = new RequestResponse();
        resp.success = true;
        resp.errors = errors;

        if(errors.size() > 0) {
            resp.success = false;
            return resp;
        }

        // deduplicate requests (by ext id) and initialise count
        Map<String, Case> newCasesByExternalId = new Map<String, Case>();
        Map<Id, String> personIdByContactId = new Map<Id, String>();
        Map<Id, String> callistaIdBycourseAttmptId = new Map<Id, String>();
        Map<String, JrgCaseRequest> requestsByExternalId = new Map<String, JrgCaseRequest>();
        Map<String, JrgCaseRequest> ocrRequestsByExternalId = new Map<String, JrgCaseRequest>();
        Set<String> campMembContactPersonIds = new Set<String>();
        Set<String> linkedCourseAttemptCallistaId = new Set<String>();
        for(JrgCaseRequest req :requests) {
            Case c = createCase(req);
            newCasesByExternalId.put(c.Alias__c, c);
            requestsByExternalId.put(c.Alias__c, req);
            ocrRequestsByExternalId.put(req.personId+'-'+req.courseAttemptCallistaId, req);
            linkedCourseAttemptCallistaId.add(req.courseAttemptCallistaId);
            campMembContactPersonIds.add(req.personId);
        }

        // Get a Map for COurse Attempt Ids
        for(Course_Attempt__c c : [SELECT Id, Callista_External_Id__c FROM Course_Attempt__c WHERE Callista_External_Id__c IN :linkedCourseAttemptCallistaId]) {
            callistaIdBycourseAttmptId.put(c.Id, c.Callista_External_Id__c);
        }

        // Get a Map for COntact Ids
        for(Contact con : [SELECT Id, Person_ID_unique__c FROM Contact WHERE Person_ID_unique__c IN :campMembContactPersonIds]){
            personIdByContactId.put(con.Id, con.Person_ID_unique__c);
        }        

        // retrieve existing records
        Case[] casesForUpsert = [
            SELECT Number_Of_Occurrences__c, Alias__c FROM Case
            WHERE Alias__c IN :requestsByExternalId.keySet()
        ];

        // remove matching newly created case and increment existing cases
        for(Case existingCase :casesForUpsert) {
            Case newCase = newCasesByExternalId.remove(existingCase.Alias__c);
            if(newCase != null) {
                existingCase.Number_Of_Occurrences__c += newCase.Number_Of_Occurrences__c;
            }
        }

        // add the new cases into the cases for upsert list
        for(Case c :newCasesByExternalId.values()) {
            casesForUpsert.add(c);
        }

        Database.executeBatch(new JrgCaseCreatorBatch(casesForUpsert, requestsByExternalId, ocrRequestsByExternalId, personIdByContactId, callistaIdBycourseAttmptId), batchSize);

        return resp;
    }

    /**
     * @description Load the default CSV mapping JSON from Custom Metadata and returns
     * @return String for response
     */
    @AuraEnabled
    public static String getDefaultCsvMappingJSON() {
        // SF field -> CSV column
        System_Settings__mdt[] settings = SystemSettingsUtil.getInstance().getByFeature('JRG_DEFAULT_CSV_MAPPING');
        if (settings.size() > 0 && String.isNotBlank(settings[0].Value__c)) {
            return settings[0].Value__c;
        }
        return null;
    }

}