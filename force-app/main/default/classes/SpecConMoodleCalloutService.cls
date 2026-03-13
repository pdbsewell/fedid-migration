/**
 * @description Spec Con Moodle callouts
 * @group       SpecCon
 * @author      tom.gangemi@monash.edu
 * @revision    2025-02-10 - Initial version
 */
public with sharing class SpecConMoodleCalloutService {

    public static final String NAMED_CRED = 'MIX_UniCRM_Student_Admin_Experience_API';

    // Wrapper class for QuizAttempts response
    public class QuizAttemptsWrapper {
        public List<QuizAttempt> attempts;
        public Integer noOfAllowableUserOverriddenAttempts;
        public List<String> warnings;
    }

    public class QuizAttempt {
        public Integer id;
        public String assessmentType;
        public Integer assessmentId;
        public Integer quizId;
        public Integer attempt;
        public Integer uniqueId;
        public String status;
        public Datetime timeStart;
        public Datetime timeFinish;
        public Datetime timeModified;
        public Datetime timeModifiedOffline;
        public Decimal sumGrades;
        public Datetime gradedNotificationSentTime;
    }

    // Wrapper class for Assessments response
    public class Assessment {
        public String id;
        public String cmid;
        public String unitOfferingId;
        public String unitCode;
        public String description;
        public String type;
        public String name;
        public String weight;
        public Datetime submissionStartDate;
        public Datetime dueDate;
        public Datetime extensionDueDate;
        public Datetime cutOffDate;
        public Datetime dueDateOverride;
        public Datetime effectiveDueDate;
        public Datetime effectiveExtensionDueDate;
        public Integer numberOfAllowedAttempts;
    }

    // Start - Callout Result Classes //
    public abstract class CalloutResult {
        public Boolean success;
        public String errorMessage;
        public Exception ex;
        public HttpRequest request;
        public HttpResponse response;
        public Id cuaId;

        public void logToNebula() {
            String resType = getResultType();
            String msg = 'Moodle Get ' + resType + (success ? ' successful' : ' failed');

            Nebula.Logger.newEntry(success ? LoggingLevel.DEBUG : LoggingLevel.ERROR, msg)
                .setRecord(cuaId)
                .setExceptionDetails(ex)
                .setHttpRequestDetails(request)
                .setHttpResponseDetails(response);
        }
        protected abstract String getResultType();
    }

    public class QuizAttemptsResult extends CalloutResult {
        public QuizAttemptsWrapper quizAttempts;
        protected override String getResultType() { return 'Quiz Attempts'; }
    }

    public class AssessmentsResults extends CalloutResult {
        public List<Assessment> assessments;
        protected override String getResultType() { return 'Assessments'; }
    }

    public class QuizExtensionResult extends CalloutResult {
        protected override String getResultType() { return 'Quiz Extension'; }
    }
    // End - Callout Result Classes //

    /**
     * @description Generic method to make HTTP callouts
     * @param endpoint The endpoint URL
     * @param method The HTTP method (GET, POST, PATCH, PUT)
     * @param body The request body (for POST, PATCH, PUT)
     * @param timeoutSeconds The timeout in seconds
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

    public static String getErrorMessage(CalloutResult cr) {
        Map<String,Object> errorBody = (Map<String,Object>)JSON.deserializeUntyped(cr.response.getBody());
        if(errorBody.containsKey('description')) {
            return String.valueOf(errorBody.get('description'));
        } else {
            return 'An error occurred';
        }
    }

    /**
     * https://anypoint.mulesoft.com/exchange/19264166-80b8-442c-a114-7a87c0d04e1c/unicrm-student-admin-experience-api/minor/1.0/console/method/%238800/
     * @description Callout to get quiz attempts for a student
     * @param studentId
     * @param quizId
     * @return QuizAttemptsResult
     */
    public static QuizAttemptsResult getQuizAttempts(String studentId, String quizId) {
        String endpoint = '/students/'+studentId+'/quizzes/'+quizId+'/attempts?status=all';

        QuizAttemptsResult cr = new QuizAttemptsResult();
        cr.success = false;
        cr.request = makeRequest(endpoint, 'GET', null, 12);

        try {
            cr.response = new Http().send(cr.request);
            if(cr.response.getStatusCode() == 200) {
                QuizAttemptsWrapper quizAttemptsWrapper =
                    (QuizAttemptsWrapper)JSON.deserialize(cr.response.getBody(), QuizAttemptsWrapper.class);
                cr.quizAttempts = quizAttemptsWrapper;
                cr.success = true;
            } else {
                cr.errorMessage = getErrorMessage(cr);
            }
        } catch (Exception e) {
            cr.ex = e;
            cr.errorMessage = e.getMessage();
        }

        return cr;
    }

    /**
     * https://anypoint.mulesoft.com/exchange/19264166-80b8-442c-a114-7a87c0d04e1c/unicrm-student-admin-experience-api/minor/1.0/console/method/%238291/
     * @description Callout to get assessments for a student
     * @param studentId
     * @param unitOfferingId
     * @return AssessmentsResults
     */
    public static AssessmentsResults getAssessments(String studentId, String unitOfferingId) {
        String endpoint = '/students/'+studentId+'/assessments?unitOfferingId='+unitOfferingId;

        AssessmentsResults cr = new AssessmentsResults();
        cr.success = false;
        cr.request = makeRequest(endpoint, 'GET', null, 20);

        try {
            cr.response = new Http().send(cr.request);
            if(cr.response.getStatusCode() == 200) {
                Assessment[] assessments =
                    (Assessment[])JSON.deserialize(cr.response.getBody(), List<Assessment>.class);
                cr.assessments = assessments;
                cr.success = true;
            } else {
                cr.errorMessage = getErrorMessage(cr);
            }
        } catch (Exception e) {
            cr.ex = e;
            cr.errorMessage = e.getMessage();
        }

        return cr;
    }

    /**
     * https://anypoint.mulesoft.com/exchange/19264166-80b8-442c-a114-7a87c0d04e1c/unicrm-student-admin-experience-api/minor/1.0/console/method/%238768/
     * @description Callout to set a quiz extension
     * @param studentId
     * @param quizId
     * @param numAttempts  Null value = No change to noOfAllowableAttempts
     * @param closingDate
     * @param location (Unit Attempt location) used to determine timezone
     * @return
     */
    public static QuizExtensionResult postQuizExtension(String studentId, String quizId, Integer numAttempts, Date closingDate, String location) {
        String endpoint = '/students/'+studentId+'/quizzes/'+quizId+'/extensions';

        Datetime closingDatetime = createNewLocalDueDatetime(closingDate, location);
        Map<String,Object> body = new Map<String,Object>{
            'closingDateTime' => closingDatetime
        };
        if(numAttempts != null) {
            // not setting property = no change to noOfAllowableAttempts
            body.put('noOfAllowableAttempts', numAttempts);
            // If override value is same as original value, no noOfAllowableUserOverriddenAttempts will be returned
        }

        QuizExtensionResult cr = new QuizExtensionResult();
        cr.success = false;
        cr.request = makeRequest(endpoint, 'POST', JSON.serialize(body), 20);

        try {
            cr.response = new Http().send(cr.request);
            if(cr.response.getStatusCode() == 200) {
                cr.success = true;
            } else {
                cr.errorMessage = getErrorMessage(cr);
            }
        } catch (Exception e) {
            cr.ex = e;
            cr.errorMessage = e.getMessage();
        }

        return cr;
    }

    /**
     * For a given date and location, create a datetime that is 23:55 local time of location
     */
    public static Datetime createNewLocalDueDatetime(Date newDueDate, String location) {
        // offset newDueDate so that it's 23:55 local time of location
        Datetime dt = Datetime.newInstanceGmt(newDueDate, Time.newInstance(23, 55, 0, 0));
        Map<String,String> timeZonesByLocation = new Map<String,String>{
            'MALAYSIA' => 'Asia/Kuala_Lumpur',
            'MUFY-SUN' => 'Asia/Kuala_Lumpur',
            'INDONESIA' => 'Asia/Jakarta',
            'PRATO' => 'Europe/Rome',
            'SUZHOU' => 'Asia/Shanghai',
            'OS-SGP' => 'Asia/Singapore',
            'OS-HKG' => 'Asia/Hong_Kong'
        };
        // default to Melbourne
        String timeZoneName = timeZonesByLocation.get(location?.toUpperCase()) ?? 'Australia/Melbourne';
        TimeZone timeZone = TimeZone.getTimeZone(timeZoneName);
        Integer offsetSeconds =  timeZone.getOffset(dt) / 1000;
        return dt.addSeconds(-offsetSeconds);
    }
}