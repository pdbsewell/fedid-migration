/*
 * @see         https://api-dev.monash.edu/static/api
 * @author      PwC
 * @revision    SA-718 ayush.agrawal@monash.edu - Remove all obsolete pieces of code. Move to Named Credentials for
 *              credential storage.
 *               15.MAR.2024 VV > Update Mule4 endpoints.
*/
public class SMSServices {
    
    public static HttpResponse invokeMIXAPICallout(String personID) {
        
        try {
            HTTP h = new HTTP();
            HTTPRequest r = new HTTPRequest();
            r.setEndpoint('callout:SMSServices_Mix_API/la/student-services/v2/students/' + personID + '/personNotes');
            r.setTimeout(1000 * 20);
            r.setHeader('client_id', '{!$Credential.UserName}');
            r.setHeader('client_secret', '{!$Credential.Password}');
            r.setMethod('GET');
            HTTPResponse response = h.send(r);
            return response;
        } catch(Exception e) {
            return null;
        }
        
    }
    
    public static HttpResponse mockPersonNotesResponse() {
        return buildResponse('[{ "personId":"123445","referenceNumber":"1233","peNoteType":"notetype","noteText":"noteText"}]');
    }
    
    public static HttpResponse mockPersonNotesResponse2() {
        return buildResponse('{"_links":{"_self":{"href":"/la/student-services/v2/students/30075009/personNotes"}},"notes":[{"type":"personNote","admissionApplicationId":null,"noteType":"AUTHINFO","typeDescription":"MONASH INTERNATIONAL APPLICATION DETAILS","updateBy":"MKARIM","updateOn":"2018-11-01T13:50:40","text":"Test Notes","portalApplicationID":null}]}');
    }
    
    public static HttpResponse mockPersonCitizenshipResponse() {
        return buildResponse('{ "personId":"123445", "citizenshipType":"AUSTRALIAN" }');
    }
    
    public static HttpResponse mockEncumbranceResponse() {
        return buildResponse('{ "personId":"123445", "encumbered":"Y" }');
    }
    
    public static HttpResponse mockStudentCourseAttemptsResponse() {
        return buildResponse('[{ "personId":"123445", "courseCode":"123","versionNum":"1","courseAttemptStatus":"COMPLETED","locationCode":"lc","attendanceMode":"FT","attendanceType":"FT","courseTitle":"testCourse","courseShortTitle":"BSc","responsibleOrgUnitCode":"UC","managingFaculty":"mf","homeCampus":"Caulfield","attendanceModeDesc":"FT","attendanceTypeDesc":"FT","title":"title" }]');
    }
    
    public static HttpResponse mockApplicantCourseResponse() {
        return buildResponse('[{ "personId":"123445", "preferenceNumber":"123","nominatedCourseCd":"1","courseCd":"COMPLETED","title":"lc","versionNumber":"2"}]');
    }
    
    private static HttpResponse buildResponse(string body) {
        HttpResponse resp = new HttpResponse();
        resp.setBody(body);
        resp.setStatus('OK');
        resp.setStatusCode(200);
        return resp;
    }
    
}