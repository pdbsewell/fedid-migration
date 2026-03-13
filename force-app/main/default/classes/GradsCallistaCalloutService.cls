/**
 * @description Grads Callista callouts. There is intentionally no SObjects or DML in here
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 */
public with sharing class GradsCallistaCalloutService {

    public static final String NAMED_CRED = GradsUtils.getSyncConfig().namedCredential;
    public static Integer DEFAULT_TIMEOUT_SECS = 20;

    // Start - Application Request Body Classes //
    public class AppReqBody {
        public AppReqCourseAttempts courseAttempts;
        public AppReqGraduationApplication graduationApplication;
    }

    public class AppReqCourseAttempts {
        public String courseCode;
        public Integer courseVersionNumber;
    }
    
    @SuppressWarnings('PMD.TooManyFields') // necessary API fields
    public class AppReqGraduationApplication {
        public AppReqAwardDetails awardDetails;
        public String alternateExit;
        public Integer amountPaid;
        public String alternateExitCourseTitle;
        public String graduationCalendarType;
        public Integer graduationCiSequenceNumber;
        public String nameChangeRequest;
        public String graduationName;
        public AppReqGraduationCalendar graduationCalendar;
        public String ceremonyLocation;
        public String alternateEmailAddr;
        public String transactionCode;
        public String transactionNo;
        public String receiptNumber;
        public String graduandType;
        public String specialRequirement;
        public String authcateIndicator;
        public String nameChangedStatus;
        public String comment;
    }

    public class AppReqAwardDetails {
        public String awardCourseCode1;
        public String awardTitle1;
        public String awardCode1;
        public Integer awardCourseCode1Version;
        public String awardCourseCode2;
        public String awardTitle2;
        public String awardCode2;
        public Integer awardCourseCode2Version;
    }

    public class AppReqGraduationCalendar {
        public String graduationStartDate;
        public String graduationEndDate;
        public String graduationLocation;
        public String graduationLocationType;
        public String graduationLocationSemester;
    }
    // End - Application Request Body Classes //

    // Start - Eligibility Response Classes //
    public class EligibilityResponse {
        public EligibilityDetails graduationEligibilityDetails;
    }
    public class EligibilityDetails {
        public List<EligibilityCourseAttempt> courseAttempts;
    }

    public class EligibilityCourseAttempt {
        public String courseCode;
        public Integer courseVersionNumber;
        public String courseTitle;
        public String meetCPRequirement;
        public String encumbered;
        public String wesBarred;
        public String meetCourseStatusRequirement;
        public String graduateStudentIndicator;
        public String graduateModuleEnabled;
        public String haveGraduated;
        public List<EligibilityGraduationAvailableSelection> graduationAvailableSelections;
        public List<EligibilityGraduationApplication> graduationApplications;
    }

    public class EligibilityGraduationApplication {
        public String transactionNo;
        public EligibilityAppAward awardDetails;
        public String submissionDate;
        public String applicationStatus;
        public String graduationCiSequenceNumber;
        public String alternateExit;
    }

    public class EligibilityGraduationAvailableSelection {
        public EligibilityAward awardDetails;
    }

    // Award details for existing applications
    public class EligibilityAppAward {
        public String awardCourseCode1;
        public String awardCourseCode1Version;
        public String awardCode1;
        public String awardCourseCode2;
        public String awardCourseCode2Version;
        public String awardCode2;
    }

    // Award details for available selections
    public class EligibilityAward {
        public String awardTypeIndicator;
        public String awardCourseCode;
        public Integer awardCourseVersionNumber;
        public String awardCourseTitle;
        public String awardCode1;
        public String awardTitle1;
        public String awardCode2;
        public String awardTitle2;
    }
    // End - Eligibility Response Classes //

    // Document Request Body Class //
    public class DocumentReqBody {
        public String id;
        public String filename;
        public String binaryString;
    }

    // Start - Callout Result Classes //
    public abstract class CalloutResult {
        public Boolean success;
        public String errorMessage;
        public Exception ex;
        public HttpRequest request;
        public HttpResponse response;
        public Id awardId;

        public void logToNebula() {
            String resType = getResultType();
            String msg = 'Callista ' + resType + (success ? ' successful' : ' failed');

            Nebula.Logger.newEntry(success ? LoggingLevel.INFO : LoggingLevel.ERROR, msg)
                .setRecord(awardId)
                .setExceptionDetails(ex)
                .setHttpRequestDetails(request)
                .setHttpResponseDetails(response);
        }
        protected abstract String getResultType();
    }

    public class ApplicationCalloutResult extends CalloutResult {
        public String transactionNo;
        protected override String getResultType() { return 'Application Submission'; }
    }

    public class DocumentCalloutResult extends CalloutResult {
        public String documentId;
        protected override String getResultType() { return 'Document Submission'; }
    }

    public class EligibilityCalloutResult extends CalloutResult {
        public EligibilityDetails eligibilityDetails;
        protected override String getResultType() { return 'Eligibility Check'; }
    }
    // End - Callout Result Classes //

    /**
     * @description Generic method to make HTTP callouts
     * @param endpoint The endpoint URL
     * @param method The HTTP method (GET, POST, PATCH, PUT)
     * @param body The request body (for POST, PATCH, PUT)
     * @return HttpResponse The response from the callout
     */
    private static HttpRequest makeRequest(String endpoint, String method, String body, Integer timeoutSeconds) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CRED + endpoint);
        req.setMethod(method);
        req.setTimeout(timeoutSeconds * 1000);
        req.setHeader('Content-Type', 'application/json');

        if (String.isNotBlank(body)) {
            req.setBody(body);
        }

        return req;
    }

    /**
     * @description Callout to create or update a graduation application
     * @return ApplicationCalloutResult
     */
    public static ApplicationCalloutResult submitApplication(AppReqBody body, String studentId, Id awardId) {
        String endpoint = '/students/' + studentId + '/graduation-applications';
        if (String.isNotBlank(body.graduationApplication.transactionNo)) {
            endpoint += '/' + body.graduationApplication.transactionNo;
        }
        String method = String.isBlank(body.graduationApplication.transactionNo) ? 'POST' : 'PATCH';
        String reqJson = JSON.serializePretty(body, true);

        ApplicationCalloutResult result = new ApplicationCalloutResult();
        result.awardId = awardId;
        result.success = false;
        result.request = makeRequest(endpoint, method, reqJson, DEFAULT_TIMEOUT_SECS);

        try {
            result.response = new Http().send(result.request);
            if (result.response.getStatusCode() == 200) {
                Map<String, Object> resultJson = (Map<String, Object>) JSON.deserializeUntyped(result.response.getBody());
                result.transactionNo = (String) resultJson.get('transactionNo');
                result.success = true;
            } else {
                Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(result.response.getBody());
                result.errorMessage = String.valueOf(errorBody.get('description'));
            }
        } catch (Exception ex) {
            result.ex = ex;
            result.errorMessage = ex.getMessage();
        }

        return result;
    }

    /**
     * @description Callout to upload a document to a graduation application
     * @param studentId
     * @param applicationId
     * @param docId
     * @param cv
     * @return DocumentCalloutResult
     */
    public static DocumentCalloutResult submitDocument(String studentId, String applicationId, String docId, ContentVersion cv) {
        String endpoint = '/students/' + studentId + '/graduation-applications/' + applicationId + '/documents';

        DocumentReqBody reqDoc = new DocumentReqBody();
        reqDoc.id = docId;
        reqDoc.filename = cv.Title;
        reqDoc.binaryString = EncodingUtil.base64Encode(cv.VersionData);
        Map<String, DocumentReqBody> reqBody = new Map<String, DocumentReqBody>{
            'document' => reqDoc
        };

        DocumentCalloutResult dcr = new DocumentCalloutResult();

        dcr.success = false;
        dcr.request = makeRequest(endpoint, 'PUT', JSON.serializePretty(reqBody, true), DEFAULT_TIMEOUT_SECS);

        try {
            dcr.response = new Http().send(dcr.request);
            if(dcr.response.getStatusCode() == 200) {
                Map<String,Object> resultJson = (Map<String,Object>) JSON.deserializeUntyped(dcr.response.getBody());
                Map<String,Object> docJson = (Map<String,Object>) resultJson.get('document');
                dcr.documentId = (String) docJson.get('id');
                dcr.success = true;
            } else {
                Map<String,Object> errorBody = (Map<String,Object>) JSON.deserializeUntyped(dcr.response.getBody());
                dcr.errorMessage = String.valueOf(errorBody.get('description'));
            }
        } catch(Exception ex) {
            dcr.ex = ex;
        }
        return dcr;
    }

    /**
     * @description Callout to get graduation eligibility details for a student
     * @param studentId
     * @return EligibilityCalloutResult
     */
    public static EligibilityCalloutResult getEligibility(String studentId) {
        String endpoint = '/students/'+studentId+'/graduation-eligibility';

        EligibilityCalloutResult cr = new EligibilityCalloutResult();
        cr.success = false;
        cr.request = makeRequest(endpoint, 'GET', null, DEFAULT_TIMEOUT_SECS);

        try {
            cr.response = new Http().send(cr.request);
            if(cr.response.getStatusCode() == 200) {
                EligibilityResponse eligibilityResponse =
                    (EligibilityResponse)JSON.deserialize(cr.response.getBody(), EligibilityResponse.class);
                cr.eligibilityDetails = eligibilityResponse.graduationEligibilityDetails;
                cr.success = true;
            } else {
                Map<String,Object> errorBody = (Map<String,Object>)JSON.deserializeUntyped(cr.response.getBody());
                cr.errorMessage = String.valueOf(errorBody.get('description'));
            }
        } catch (Exception e) {
            cr.ex = e;
            cr.errorMessage = e.getMessage();
        }

        return cr;
    }
}