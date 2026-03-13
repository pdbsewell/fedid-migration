/**
 * @author       Tom Gangemi
 * @group        Service
 * @testclass    CallistaExamService_Test
 * @revision
 *     2023-09-18 - SA-1923 - Tom Gangemi - Initial version
 *     2025-05-22 - RA - Updatd the Request Format as per Mulesoft changes
 * @description  Service class for updating an Exam Special Consideration request in Callista
 */

 public with sharing class CallistaExamService {

    public static final String SYS_SETTINGS_FEATURE_CALLISTA_MOCK = 'SPEC_CON_CALLISTA_MOCK';
    public static final String SYS_SETTINGS_FEATURE_CALLISTA_CAT_MAP = 'SPEC_CON_CALLISTA_CAT_MAP';

    public class CallistaExamServiceException extends Exception {}

    //   Start Request Object Definition   //
    // ----------------------------------- //
    public class ExamUpdateRequest {
        public SpecialConsiderationApplication specialConsiderationApplication;
    }
    public class SpecialConsiderationApplication {
        public ExamDetails details;
    }
    public class UnitDetails {
        public String unitCode;
        public String calType;
        public String ciSequenceNumber;
        public AssessmentDetails assessmentDetails;
    }
    public class CourseDetails {
        public String code;
        public UnitDetails unitDetails;
    }
    public class AssessmentDetails{
        public String assessmentIdOnline;
        public String creationDate;
        public String receivedDate;
        public String spconCat;
        public String soutOutcome;
        public String spconOutcome;
        public String estimatedProcDays;
        public String trackingId;
        public String comments;
    }
    public class ExamDetails {
        public String personId;
        public CourseDetails courseDetails;
    }
    // --------------------------------- //
    //   End Request Object Definition   //

    // response from Callista
    public class ExamUpdateResponse {
        public String status;
        public String message;
    }
    // response from callout method
    public class ExamUpdateResult {
        public Boolean success;
        public String message;
        public Exception ex;
        public String requestJson;
        public String responseJson;
        public Integer httpStatus;
        public String endpoint;
        public Boolean mocked;
    }

    /**
     * @return the mock response from System Settings - null if there is no active mock setting
     */
    public static String getCallistaMockResponse() {
        System_Settings__mdt[] mockSetting = SystemSettingsUtil.getInstance().getByFeature(SYS_SETTINGS_FEATURE_CALLISTA_MOCK);
        if(mockSetting.size() > 0 && String.isNotBlank(mockSetting[0].Value__c)) {
            return mockSetting[0].Value__c;
        } else {
            return null;
        }
    }

    public static Map<String,String> callistaCategoriesByCatLevel2 = null;

    /**
     * @return the corresponding Callista category for a given Category Level 2. Mapping loaded from System Settings
     * mapping is case insensitive
     */
    public static String getCallistaCategory(String catLvl2) {
        if(callistaCategoriesByCatLevel2 == null) {
            // lazy init the mapping
            System_Settings__mdt[] setting = SystemSettingsUtil.getInstance().getByFeature(SYS_SETTINGS_FEATURE_CALLISTA_CAT_MAP);
            if(setting.size() > 0 && String.isNotBlank(setting[0].Value__c)) {
                callistaCategoriesByCatLevel2 = new Map<String,String>();
                Map<String,String> origMap =  (Map<String,String>)JSON.deserialize(setting[0].Value__c, Map<String,String>.class);
                for(String key : origMap.keySet()) {
                    callistaCategoriesByCatLevel2.put(key.toLowerCase(), origMap.get(key));
                }
            } else {
                throw new CallistaExamServiceException('Callista category mapping not found');
            }
        }
        // lookup the mapping
        String val = callistaCategoriesByCatLevel2.get(catLvl2.toLowerCase());
        if(String.isBlank(val)) {
            throw new CallistaExamServiceException('Callista category not found for: ' + catLvl2);
        }
        return val;
    }

    /**
     * @return the corresponding Callista Outcome for a given Status and Category Level 1
     */
    public static String getCallistaOutcome(String status, String catLvl1) {
        if(status == 'Approved') {
            if(catLvl1 == 'Deferred Assessment') {
                return 'DEFER';
            }
            if(catLvl1.startsWithIgnoreCase('Rescheduled Deferred Assessment')) {
                return 'RDA';
            }
        }
        if(status == 'Declined') {
            return 'REJECTED';
        }
        if(status == 'Withdrawn') {
            return 'CANCELLED';
        }
        throw new CallistaExamServiceException('Invalid Status/Category Level 1: ' + status + '/' + catLvl1);
    }

    /**
     * Create a ExamUpdateRequest from a Case_Unit_Attempt__c
     */
    public static ExamUpdateRequest createExamUpdateRequest(Case_Unit_Attempt__c cua) {
        ExamDetails ed = new ExamDetails();
        ed.personId = cua.Person_ID__c;
        //Course Details
        ed.courseDetails = new CourseDetails();
        ed.courseDetails.code = cua.Unit_Attempt__r.Course_Code__c;
        //Unit Details
        ed.courseDetails.unitDetails = new UnitDetails();
        ed.courseDetails.unitDetails.unitCode = cua.Unit_Code_Formula__c;
        ed.courseDetails.unitDetails.calType = cua.Unit_Attempt__r?.Teaching_Calendar__r?.Type__c;
        ed.courseDetails.unitDetails.ciSequenceNumber = cua.CI_Sequence_Number__c;
        //Assessment Details
        ed.courseDetails.unitDetails.assessmentDetails = new AssessmentDetails();
        ed.courseDetails.unitDetails.assessmentDetails.assessmentIdOnline = cua.Callista_Assessment_ID__c;
        ed.courseDetails.unitDetails.assessmentDetails.creationDate = cua.Callista_Created_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'','Etc/UTC');
        ed.courseDetails.unitDetails.assessmentDetails.receivedDate = SpecConServices.formatDate(Date.Today(), 'yyyy-MM-dd','Australia/Melbourne');
        ed.courseDetails.unitDetails.assessmentDetails.spconCat = getCallistaCategory(cua.Enquiry__r.Category_Level_2__c);
        ed.courseDetails.unitDetails.assessmentDetails.soutOutcome = '';
        ed.courseDetails.unitDetails.assessmentDetails.spconOutcome = getCallistaOutcome(cua.Status__c, cua.Enquiry__r.Category_Level_1__c);
        ed.courseDetails.unitDetails.assessmentDetails.estimatedProcDays = '0';
        ed.courseDetails.unitDetails.assessmentDetails.trackingId = cua.Enquiry__r.CaseNumber;
        ed.courseDetails.unitDetails.assessmentDetails.comments = 'Special Consideration Application - Enquiry # '+ cua.Enquiry__r.CaseNumber;

        ExamUpdateRequest req = new ExamUpdateRequest();
        req.specialConsiderationApplication = new SpecialConsiderationApplication();
        req.specialConsiderationApplication.details = ed;

        return req;
    }

    /**
     * Update a Student's Special Consideration Exam request in Callista for a given Case_Unit_Attempt__c
     * Does the following:
     *  - Make HTTP callout to Callista to update the SC Exam request
     *  - Log callout errors via LogUtilityException
     *  - Create a Case Comment on success
     *  - Update the Case_Unit_Attempt__c.Callista_Integration_Status__c
     *
     * @return null on success otherwise an error message
     */
    @AuraEnabled(cacheable=false)
    public static String updateExamInCallista(Id cuaId) {
        Case_Unit_Attempt__c cua = [
            SELECT Name, Person_ID__c, Assessment_Name__c, Assessment_Type__c, Assessment_Due_Date_New__c,
                Assessment_Due_Date_Original__c, Assessment_Due_Date_Requested__c, Assessment_Due_Time_Original__c,
                Unit_Title__c, Unit_Code__c, Unit_Code_Formula__c, Callista_Created_Date__c, Status__c,
                Callista_Assessment_ID__c, Callista_Received_Date__c, CI_Sequence_Number__c,
                Enquiry__c, Enquiry__r.Category_Level_1__c, Enquiry__r.Category_Level_2__c, Enquiry__r.Submitted_At__c,
                Enquiry__r.CaseNumber,
                Unit_Attempt__r.Course_Code__c, Unit_Attempt__r.Teaching_Calendar__r.Type__c
            FROM Case_Unit_Attempt__c WHERE Id = :cuaId
        ];
        SObjectField[] requiredCuaFields = new SObjectField[]{
            Case_Unit_Attempt__c.Person_ID__c, Case_Unit_Attempt__c.CI_Sequence_Number__c,
            Case_Unit_Attempt__c.Callista_Received_Date__c, Case_Unit_Attempt__c.Callista_Created_Date__c,
            Case_Unit_Attempt__c.Callista_Assessment_ID__c
        };
        String[] blankFields = new String[0];
        for(SObjectField f : requiredCuaFields) {
            if(cua.get(f) == null) {
                blankFields.add(f.getDescribe().label);
            }
        }
        if(blankFields.size() > 0) {
            return 'The following required fields are missing: ' + String.join(blankFields,', ');
        }

        ExamUpdateRequest eur = createExamUpdateRequest(cua);
        ExamUpdateResult result = callistaExamUpdateCallout(eur);
        String retMsg = null;
        if(!result.success) {
            cua.Callista_Integration_Status__c = 'Failed - Logged';
            retMsg = 'Error updating Callista: ';
            String logMsg = 'HTTP Status: ' + result.httpStatus + '\nResponse body:\n' + result.responseJson;

            if(result.ex != null) {
                retMsg += result.ex.getMessage();
                logMsg += '\n\nEx Message: ' + result.ex.getMessage()+'\n\nStackTrace:\n' + result.ex.getStackTraceString();
            } else {
                retMsg += result.message;
            }
            if(result.mocked) {
                logMsg = '---- Mocked Response ----\n' + logMsg;
            }
        } else {
            cua.Callista_Integration_Status__c = 'Success';
            insert createCaseComment(cua);
        }
        if(result.mocked) {
            insert createMockComment(cua.Enquiry__c, result);
        }
        update cua;
        return retMsg;
       
    }

    /**
     * This is just the callout - No DML or SOQL.
     * Note that if the mock response is set in System Settings, this will be returned instead of making the callout.
     * @param eur request object
     * @return the result of the callout
     */
    public static ExamUpdateResult callistaExamUpdateCallout(ExamUpdateRequest eur) {

        ExamUpdateResult result = new ExamUpdateResult();
        result.mocked = false;
        result.requestJson = JSON.serializePretty(eur);

        HttpRequest req = new HttpRequest();
        HttpResponse httpRes;
        String personId = eur.specialConsiderationApplication.details.personId;
        req.setEndpoint('callout:Monash_MiX_APIs'+'/unicrm/v1/students/'+personId+'/special-consideration-application');
        req.setMethod('PUT');
              req.setHeader('client_id', '{!$Credential.Username}');
        req.setHeader('client_secret', '{!$Credential.Password}');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(result.requestJson);

        String mockResponse = getCallistaMockResponse();

        try {
            result.endpoint = req.getEndpoint();

            if(!Test.isRunningTest() && mockResponse != null) {
                // read mock response
                result.responseJson = mockResponse;
                result.httpStatus = 201;
                result.mocked = true;
            } else {
                // send request
                httpRes = new Http().send(req);
                result.responseJson = httpRes.getBody();
                result.httpStatus = httpRes.getStatusCode();
            }

            // parse response
            if(result.httpStatus >= 200 && result.httpStatus < 300) {
                Map<String,Object> respMap = (Map<String,Object>)JSON.deserializeUntyped(result.responseJson);
                Map<String,Object> scApp = (Map<String,Object>)respMap.get('specialConsiderationApplication');
                Map<String, Object> data = (Map<String, Object>) scApp.get('data');
                result.success = (String)data.get('status') == 'success';
                result.message = (String)data.get('message');
                nebula.logger.info(result.message).setHttpRequestDetails(req).setHttpResponseDetails(httpRes).addTag('CES-MIX Call');
                
            } else {
                result.success = false;
                if(String.isNotBlank(result.responseJson)) {
                    Map<String,Object> respMap = (Map<String,Object>)JSON.deserializeUntyped(result.responseJson);
                    String errorType = (String)respMap.get('errorType');
                    String description = (String)respMap.get('description');
                    String additionalDetails = (String)respMap.get('additionalDetails');
                    result.message = errorType + ': ' + description;
                    if(String.isNotBlank(additionalDetails)) {
                        result.message += '(' + additionalDetails + ')';
                    }
                }
                nebula.logger.error(result.message).setHttpRequestDetails(req).setHttpResponseDetails(httpRes).addTag('CES-MIX Call');
            }

        } catch(Exception ex) {
            nebula.logger.error(ex.getMessage(), ex).addTag('CES-MIX Call');
            // apex/req/json error
            result.success = false;
            result.ex = ex;
        }finally{
            nebula.logger.saveLog();
        }

        return result;
    }

    public static final String CASE_COMMENT_START = 'Success - Callista Exam Details Updated';

    public static CaseComment createCaseComment(Case_Unit_Attempt__c cua) {
        String origDateStr = SpecConServices.formatDate(cua.Assessment_Due_Date_Original__c,'yyyy-MM-dd');
        CaseComment cc = new CaseComment();
        cc.ParentId = cua.Enquiry__c;
        cc.CommentBody = CASE_COMMENT_START +
            '\nCase Unit Attempt: ' + cua.Name +
            '\nOriginal Assessment Date: ' + origDateStr;
        return cc;
    }

    public static CaseComment createMockComment(Id caseId, ExamUpdateResult eur) {
        CaseComment cc = new CaseComment();
        cc.ParentId = caseId;
        cc.CommentBody = '---- Mocked Callista Request ----\n' + eur.requestJson;
        cc.CommentBody += '\n\n---- Mocked Callista Response ----\n' + eur.responseJson;
        return cc;
    }
}