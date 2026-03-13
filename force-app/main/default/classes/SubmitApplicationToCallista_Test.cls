/**
 * @author      Kristian Vegerano
 * @description Test class for SubmitApplicationToCallista batch class
 * @group       Test Class
 * @revision    08/01/2020 - Kristian Vegerano - Created
 *              14/07/2020 - Martin Cadman
 * @revision    15.MAR.2024 Ven Vairavan > Update Mule4 endpoints.
 */
@isTest(isParallel=true)
private class SubmitApplicationToCallista_Test {
    @testSetup
    static void setup() {      
        //Create featureSwitch
        Feature_Switch__c featureSwitch = AssessmentsTestDataFactory.createFeatureSwitch();
        insert featureSwitch;
        
        //Create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();

        //create a new draft application
        Application__c appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
        appRecord.Status__c = 'Submitted';
        insert appRecord;

        Contact contactRec = [SELECT Id FROM Contact WHERE Id =: communityUserRec.ContactId];
        contactRec.Residency_Status__c = 'DOM-AUS';
        update contactRec;

        //Tertiary institution & qualification
        Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertInsRec;

        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        Contact_Qualification__c conQualRec = new Contact_Qualification__c();
        conQualRec.Country__c = 'Australia';
        conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
        conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
        conQualRec.Other_Qualification__c = 'Certificate III';
        conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
        conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
        conQualRec.Status__c = 'CURRENTLY STUDYING';
        conQualRec.Contact__c = contactRec.Id;
        conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert conQualRec;

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = conQualRec.Id;
        insert aqpRecord;

        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = contactRec.Id;
        insert workExpRecord;

        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        insert contactDocu;

        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        Course_Offering__c courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        Course_Offering__c courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;

        Application_Course_Preference__c coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
        coursePrefA.Outcome_Status__c = 'TEST-STATUS';
        coursePrefA.Offer_Response_Status__c = 'TEST-STATUS';
        coursePrefA.Preference_Number__c = '1';
        insert coursePrefA;

        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/admissions/v1/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/admissions/v1/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';

        insert is;
    }

    @IsTest
    static void testResubmitApplications() {
        //Initialize test variables
        String QUAL_TYPE_SECONDARY = 'Secondary Education';
        String QUAL_TYPE_TERTIARY = 'Tertiary Education';
        String QUAL_TYPE_ENGLISH = 'English Test';
        String applicationId = [SELECT Id FROM Application__c LIMIT 1].Id;

        // Retrieve data
        Application__c application = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
        Contact applicant = StudFirst_SubmitApplicationHelper.getApplicantById(application.Applicant__c);
        List<Contact_Qualification__c> contactQualifications = StudFirst_SubmitApplicationHelper.getContactQualifications(applicant.Id);
        List<Work_Experience__c> workExperience = StudFirst_SubmitApplicationHelper.getWorkExperience(applicant.Id);
        List<Application_Course_Preference__c> coursePreferences = StudFirst_SubmitApplicationHelper.getCoursePreferences(applicationId);

        // Split qualifications by qualification types
        List<Contact_Qualification__c> secondary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> tertiary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> other = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> english = new List<Contact_Qualification__c>();

        for (Contact_Qualification__c cq : contactQualifications) {
            if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_SECONDARY)) {
                secondary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_TERTIARY)) {
                tertiary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_ENGLISH)) {
                english.add(cq);
            } else {
                other.add(cq);
            }
        }

        //Evaluate tap value
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('ApplicationId', application.Id);
        Boolean throttle = AssessmentTapService.getTapValue(flowInputs);

        //Build the request
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
            String req = ObdAdmissionApplication.generateRequest(application, applicant, secondary, tertiary, other, english, workExperience, coursePreferences, throttle);
            SubmitApplicationToCallista sendAppJob = new SubmitApplicationToCallista(req, application.Id, throttle);
            System.enqueueJob(sendAppJob);
        Test.stopTest();

        //Check application status
        System.assertEquals('Submitted', [SELECT Id, Status__c FROM Application__c LIMIT 1].Status__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description Opted to call the parseResponse directly because of - System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out error in test class
     */
    @IsTest
    static void testResubmitApplicationsParseResponseSuccess() {
        //Initialize test variables=
        String QUAL_TYPE_SECONDARY = 'Secondary Education';
        String QUAL_TYPE_TERTIARY = 'Tertiary Education';
        String QUAL_TYPE_ENGLISH = 'English Test';
        String applicationId = [SELECT Id FROM Application__c LIMIT 1].Id;

        // Retrieve data
        Application__c application = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
        Contact applicant = StudFirst_SubmitApplicationHelper.getApplicantById(application.Applicant__c);
        List<Contact_Qualification__c> contactQualifications = StudFirst_SubmitApplicationHelper.getContactQualifications(applicant.Id);
        List<Work_Experience__c> workExperience = StudFirst_SubmitApplicationHelper.getWorkExperience(applicant.Id);
        List<Application_Course_Preference__c> coursePreferences = StudFirst_SubmitApplicationHelper.getCoursePreferences(applicationId);

        // Split qualifications by qualification types
        List<Contact_Qualification__c> secondary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> tertiary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> other = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> english = new List<Contact_Qualification__c>();

        for (Contact_Qualification__c cq : contactQualifications) {
            if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_SECONDARY)) {
                secondary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_TERTIARY)) {
                tertiary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_ENGLISH)) {
                english.add(cq);
            } else {
                other.add(cq);
            }
        }

        //Evaluate tap value
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('ApplicationId', application.Id);
        Boolean throttle = AssessmentTapService.getTapValue(flowInputs);

        //Build the request
        String requestStr = StudFirst_Utilities.convertTo7BitAcceptedString(ObdAdmissionApplication.generateRequest(application, applicant, secondary, tertiary, other, english, workExperience, coursePreferences, throttle) ,
                                                                            '?');
        
        //Build mock response
        ObdAdmissionApplicationResponse testBody = buildMockResponseWithApplication();
        HttpResponse response = new HttpResponse();
        response.setBody(JSON.serialize(testBody));
        response.setStatus('OK');
        response.setStatusCode(199);

        //Build the request
        Test.startTest();
            SubmitApplicationToCallista.parseResponse(requestStr, response, applicationId, throttle);
        Test.stopTest();

        //Check application status
        System.assertEquals('Review', [SELECT Id, Status__c FROM Application__c LIMIT 1].Status__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description Opted to call the parseResponse directly because of - System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out error in test class
     */
    @IsTest
    static void testResubmitApplicationsParseResponseSuccessNoApplication() {
        //Initialize test variables=
        String QUAL_TYPE_SECONDARY = 'Secondary Education';
        String QUAL_TYPE_TERTIARY = 'Tertiary Education';
        String QUAL_TYPE_ENGLISH = 'English Test';
        String applicationId = [SELECT Id FROM Application__c LIMIT 1].Id;

        // Retrieve data
        Application__c application = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
        Contact applicant = StudFirst_SubmitApplicationHelper.getApplicantById(application.Applicant__c);
        List<Contact_Qualification__c> contactQualifications = StudFirst_SubmitApplicationHelper.getContactQualifications(applicant.Id);
        List<Work_Experience__c> workExperience = StudFirst_SubmitApplicationHelper.getWorkExperience(applicant.Id);
        List<Application_Course_Preference__c> coursePreferences = StudFirst_SubmitApplicationHelper.getCoursePreferences(applicationId);

        // Split qualifications by qualification types
        List<Contact_Qualification__c> secondary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> tertiary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> other = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> english = new List<Contact_Qualification__c>();

        for (Contact_Qualification__c cq : contactQualifications) {
            if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_SECONDARY)) {
                secondary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_TERTIARY)) {
                tertiary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_ENGLISH)) {
                english.add(cq);
            } else {
                other.add(cq);
            }
        }

        //Evaluate tap value
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('ApplicationId', application.Id);
        Boolean throttle = AssessmentTapService.getTapValue(flowInputs);

        //Build the request
        String requestStr = StudFirst_Utilities.convertTo7BitAcceptedString(ObdAdmissionApplication.generateRequest(application, applicant, secondary, tertiary, other, english, workExperience, coursePreferences, throttle) ,
                                                                            '?');
        
        //Build mock response
        ObdAdmissionApplicationResponse testBody = buildMockResponseWithApplication();
        HttpResponse response = new HttpResponse();
        response.setBody(JSON.serialize(testBody));
        response.setStatus('OK');
        response.setStatusCode(199);

        //Build the request
        Test.startTest();
            SubmitApplicationToCallista.parseResponse(requestStr, response, '00000000000000000', throttle);
        Test.stopTest();

        //Check application status
        System.assertEquals('Submitted', [SELECT Id, Status__c FROM Application__c LIMIT 1].Status__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description Opted to call the parseResponse directly because of - System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out error in test class
     */
    @IsTest
    static void testResubmitApplicationsParseResponseFail() {
        //Initialize test variables=
        String QUAL_TYPE_SECONDARY = 'Secondary Education';
        String QUAL_TYPE_TERTIARY = 'Tertiary Education';
        String QUAL_TYPE_ENGLISH = 'English Test';
        String applicationId = [SELECT Id FROM Application__c LIMIT 1].Id;

        // Retrieve data
        Application__c application = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
        Contact applicant = StudFirst_SubmitApplicationHelper.getApplicantById(application.Applicant__c);
        List<Contact_Qualification__c> contactQualifications = StudFirst_SubmitApplicationHelper.getContactQualifications(applicant.Id);
        List<Work_Experience__c> workExperience = StudFirst_SubmitApplicationHelper.getWorkExperience(applicant.Id);
        List<Application_Course_Preference__c> coursePreferences = StudFirst_SubmitApplicationHelper.getCoursePreferences(applicationId);

        // Split qualifications by qualification types
        List<Contact_Qualification__c> secondary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> tertiary = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> other = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> english = new List<Contact_Qualification__c>();

        for (Contact_Qualification__c cq : contactQualifications) {
            if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_SECONDARY)) {
                secondary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_TERTIARY)) {
                tertiary.add(cq);
            } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_ENGLISH)) {
                english.add(cq);
            } else {
                other.add(cq);
            }
        }

        //Evaluate tap value
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('ApplicationId', application.Id);
        Boolean throttle = AssessmentTapService.getTapValue(flowInputs);

        //Build the request
        String requestStr = StudFirst_Utilities.convertTo7BitAcceptedString(ObdAdmissionApplication.generateRequest(application, applicant, secondary, tertiary, other, english, workExperience, coursePreferences, throttle) ,
                                                                            '?');
        
        //Build mock response
        HttpResponse response = new HttpResponse();
        response.setBody(JSON.serialize(buildMockResponseWithApplication()));
        response.setStatus('OK');
        response.setStatusCode(200);

        //Build the request
        Test.startTest();
            SubmitApplicationToCallista.parseResponse(requestStr, response, applicationId, throttle);
        Test.stopTest();

        //Check application status
        System.assertEquals('Submitted', [SELECT Id, Status__c FROM Application__c LIMIT 1].Status__c);
    }
    
    private static ObdAdmissionApplicationResponse buildMockResponseWithApplication(){    
        ObdAdmissionApplicationResponse request = new ObdAdmissionApplicationResponse();
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
        preference.courseCode = 'M00001';
        preference.courseVersionNumber = 1;
        preference.locationCode = 'EX';
        preference.attendanceMode = 'FT';
        preference.attendanceType = 'EX';
        preference.academicCalendarType = 'ACAD-YR';
        preference.academicCiSequenceNumber = 8619;
        preference.admissionCalendarType = 'ADM-WNTR';
        preference.admissionCiSequenceNumber = 8701;
        preference.typeOfPlaceCode = 'A';

        //Add coursePreference to the sms application
        smsApplication.coursePreferences.add(preference);
        //Add smsApplication to the application
        application.smsApplications.add(smsApplication);
        //Add application
        request.applications.add(application);

        return request;
    }
}