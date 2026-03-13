/**
 * @author Trent De Laney
 * @date 29 Nov 2019 at 1:53:59 pm
 * @group Test Class
 * @description Covers the response message for the Application submission to Callista from my.app, IDP and Agent Portal. Needs to be covered line by line for Salesforce to pick up the coverage
 */
@IsTest
public with sharing class ObdAdmissionApplicationResponse_Test {
    @IsTest
    public static void test_AssignPropertyValues(){
        ObdAdmissionApplicationResponse request = new ObdAdmissionApplicationResponse();
        System.assertNotEquals(null, request, 'Unable to create Admission Application Request');
        request.applications = new List<ObdAdmissionApplicationResponse.Application>();

        ObdAdmissionApplicationResponse.Application application = new ObdAdmissionApplicationResponse.Application();
        application.success = false;
        application.isNewApplicant = false;
        application.externalApplicantId = '111';
        application.smsApplicantId = '111';
        application.smsApplications = new List<ObdAdmissionApplicationResponse.SmsApplication>();
        application.info = new List<String>();
        application.errors = new List<String>();

        ObdAdmissionApplicationResponse.SmsApplication smsApplication = new ObdAdmissionApplicationResponse.SmsApplication();
        smsApplication.applicationId = 1000;
        smsApplication.updatedDate = String.valueOf(Date.today());
        smsApplication.isNewApplication = false;
        smsApplication.coursePreferences = new List<ObdAdmissionApplicationResponse.CoursePreference>();

        ObdAdmissionApplicationResponse.CoursePreference preference = new ObdAdmissionApplicationResponse.CoursePreference();
        preference.transferStatus = 'false';
        preference.preferenceNumber = 1;
        preference.sequenceNumber = '1';
        preference.courseCode = 'A2000';
        preference.courseVersionNumber = 1;
        preference.locationCode = 'EX';
        preference.attendanceMode = 'FT';
        preference.attendanceType = 'EX';
        preference.academicCalendarType = 'ACAD-YR';
        preference.academicCiSequenceNumber = 8619;
        preference.admissionCalendarType = 'ADM-WNTR';
        preference.admissionCiSequenceNumber = 8701;
        preference.typeOfPlaceCode = 'A';
    }
}