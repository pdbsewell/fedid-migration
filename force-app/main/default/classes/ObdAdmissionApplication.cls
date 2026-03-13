/*
    AUTHOR : Vineeth Batreddy
    DESCRIPTION : This class is used to initiate the submission of admission application

    Change History:
    2019-01-22 KL:  Jira ticket SFTM-226, changes to pass country code 1603, see Jira tickets for more details
    2023-03-08 SMendu: Updated with change in building Workexperience on the payload 
    2024-21-10 DYU: MGROI-485 Scholarship application only updates
    2024-06-11 SVEN: MGROI-532 Update marekting payload
*/

global class ObdAdmissionApplication {

    private static final String AGENT_PERSON_ID = Label.CALLISTA_AGENT_PERSON_ID;
    private static final String AGENT_INTERNATIONAL = Label.CALLISTA_INTERNATIONAL_AGENT;
    private static final String OES_AGENT = Label.CALLISTA_OES_AGENT;
    private static final String DOMESTIC_COUNTRY = 'AUSTRALIA';
    private static final String DEFAULT_DOMESTIC_ADDRESS_TYPE = 'POSTAL';
    private static final String DEFAULT_INTERNATIONAL_ADDRESS_TYPE = 'OS-POSTAL';
    private static final String QUAL_TYPE_SECONDARY = 'Secondary Education';
    private static final String QUAL_TYPE_TERTIARY = 'Tertiary Education';
    private static final String QUAL_TYPE_OTHER = 'Other Qualification';
    private static final String QUAL_TYPE_ENGLISH = 'English Test';
    private static final String STANDARD_APPLICATION_TYPE = 'STANDARD';
    private static final String NON_AWARD_APPLICATION_TYPE = 'NON-AWARD';
    private static final String DEFAULT_APPLICATION_NUMBER = '123';
    private static final String APPLICATION_SUBMIT_SUCCESS = 'Submitted';
    private static final String APPLICATION_SUBMIT_UNSUCCESSFUL = 'Review';
    private static final String INDIGENOUS = 'INDIGENOUS';
    private static final String WORKAROUND_AU_CTRY_CD = '1603';
    private static final String GRT_SCHOLARSHIP_APPLICATION_ONLY = 'Scholarship application only';
    private static final String SENT_FOR_SUBMISSION = 'Sent for Submission';

    // This is invoked from Submit Application button on Application detail page
    WebService static void send(String applicationId) {

        List<String> applicationIds = new List<String>();

        if (String.isNotBlank(applicationId)) {
            applicationIds.add(applicationId);
            sendApplication(applicationIds);
        }

    }
    //AuraEnabled Method for application resubmission from Lightning experience
    @AuraEnabled
    public static void sendApplication(String ApplicationId) {
        send(ApplicationId);
    }

    // This is invoked from Submit Application flow when the application status is set to Sent for Submission
    @InvocableMethod
    public static void sendApplication(List<String> applicationIds) {
        try{
            String applicationId = applicationIds.get(0);
            // Retrieve data
            Application__c application = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
            //MGROI-485 Update the status to submitted to run the document integration for scholarship only application
            if(application.Type_of_Study__c == Constants.STUDYTYPE_GRADUATERESEARCH && 
                application.Graduate_Research_Application_Type__c == GRT_SCHOLARSHIP_APPLICATION_ONLY &&
                application.Status__c == SENT_FOR_SUBMISSION){
                    application.Status__c = APPLICATION_SUBMIT_SUCCESS;
                    update application;
            }else{
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
                    } else if (cq.Qualification_Type__c.equalsIgnoreCase(QUAL_TYPE_ENGLISH) && application.Type_of_Study__c != Constants.STUDYTYPE_GRADUATERESEARCH) {
                        english.add(cq);
                    } else {
                        other.add(cq);
                    }
                }

                //Get TapEnabled value 
                Map<String, Object> flowInputs = new Map<String, Object>();
                flowInputs.put('ApplicationId', application.Id);
                Boolean isTapEnabled = AssessmentTapService.getTapValue(flowInputs);

                //Build the request.
                String req = generateRequest(application, applicant, secondary, tertiary, other, english, workExperience, coursePreferences, isTapEnabled);
                SubmitApplicationToCallista sendAppJob = new SubmitApplicationToCallista(req, application.Id, isTapEnabled);
                Id jobID = System.enqueueJob(sendAppJob);
            }
        }catch (Exception e) {
            Nebula.Logger.error('ObdAdmissionApplication send application', e);
            Nebula.Logger.saveLog();
        }
    }

    @TestVisible
    private static String generateRequest(Application__c app, Contact applicant, List<Contact_Qualification__c> secondary, List<Contact_Qualification__c> tertiary, List<Contact_Qualification__c> other, List<Contact_Qualification__c> english, List<Work_Experience__c> wrkExp, List<Application_Course_Preference__c> coursePreferences, Boolean wrAssessment) {

        ObdAdmissionApplicationRequest aar = new ObdAdmissionApplicationRequest();
        aar.admissionApplication = new ObdAdmissionApplicationRequest.AdmissionApplication();
        aar.admissionApplication.agent = new ObdAdmissionApplicationRequest.Agent();

        if (app.Source_System__c == 'AgentPortal' || app.Source_System__c == 'IDP' ) {
            String agentPersonIdStr = getAgentPersonId(app.Agent__c);
            aar.admissionApplication.agent.agentPersonId = agentPersonIdStr != null ? agentPersonIdStr : '';
        }else if(app.Source_System__c == 'OES'){
            aar.admissionApplication.agent.agentPersonId = OES_AGENT;
        }else if(app.Source_System__c == 'Partner' || app.Type_of_Study__c == Constants.MONASH_ABROAD_EX_STUDY_TYPE || app.Type_of_Study__c == Constants.MONASH_ABROAD_SA_STUDY_TYPE){
            // assign partner agent person id when the application is initiated on partner portal or anytime an application is for Exchange or Study Abroad
            aar.admissionApplication.agent.agentPersonId = Constants.PARTNR;
        }else if(app.Type_of_Study__c == Constants.STUDYTYPE_GRADUATERESEARCH && app.Agent__c != null){
            String agentPersonIdStr = getAgentPersonId(app.Agent__c);
            aar.admissionApplication.agent.agentPersonId = agentPersonIdStr != null ? agentPersonIdStr : AGENT_INTERNATIONAL;
        }else{
            aar.admissionApplication.agent.agentPersonId = AGENT_INTERNATIONAL;
        }

        // Applications
        aar.admissionApplication.applications = new List<ObdAdmissionApplicationRequest.Application>();

        // Application
        ObdAdmissionApplicationRequest.Application application = new ObdAdmissionApplicationRequest.Application();
        // Applicant
        application.applicant = new ObdAdmissionApplicationRequest.Applicant();
        application.applicant.externalApplicantId = applicant.Id;
        application.applicant.surname = applicant.Last_Name__c;
        application.applicant.firstName = applicant.First_Name__c;
        application.applicant.otherName = applicant.Other_Given_Name__c;
        application.applicant.title = applicant.Salutation;
        application.applicant.sex = applicant.Gender__c;
        application.applicant.preferredGivenName = applicant.Preferred_Name__c;
        application.applicant.previousSurname = applicant.Previous_Surname__c;
        application.applicant.previousStudentIndicator = applicant.Previously_Studied_at_Monash__c;
        application.applicant.previousInstitutionCode = StudFirst_SubmitApplicationHelper.getInstitutionCode(applicant.Previous_Monash_Institution__c);
        application.applicant.previousPersonId = applicant.Previous_Monash_ID__c;
        application.applicant.birthDate = StudFirst_SubmitApplicationHelper.convertDate(applicant.Birthdate);

        //SFTLG-987
        if(applicant.Personal_Email__c != null){
            application.applicant.emailAddress = applicant.Personal_Email__c;
        }else{
            application.applicant.emailAddress = applicant.Email;
        }


        application.applicant.addressLine1 = applicant.MailingStreet;
        application.applicant.addressLine2 = applicant.MailingCity;
        application.applicant.addressLine3 = applicant.MailingState;
        application.applicant.addressLine4 = '';
        application.applicant.addressLine5 = '';
        application.applicant.postcode = '';
        application.applicant.osCode = '';

        if (applicant.MailingCountry != null) {
            // Domestic          
            if (applicant.MailingCountry.equalsIgnoreCase(DOMESTIC_COUNTRY)) {
                application.applicant.addressType = DEFAULT_DOMESTIC_ADDRESS_TYPE;
                application.applicant.postcode = applicant.MailingPostalCode;
            }
            // International
            if (!applicant.MailingCountry.equalsIgnoreCase(DOMESTIC_COUNTRY)) {
                application.applicant.addressLine4 = applicant.MailingCountry;
                application.applicant.osCode = applicant.MailingPostalCode;
                application.applicant.addressType = DEFAULT_INTERNATIONAL_ADDRESS_TYPE;
            }
        }

        application.applicant.phone1 = applicant.HomePhone;
        application.applicant.phone2 = ''; // SFTG-2870 Application to contain only HomePhone, and so only HomePhone is being transmitted to Callista
        application.applicant.phone3 = applicant.MobilePhone;
        //SFTLG-987
        if(applicant.Personal_Email__c != null){
            application.applicant.addressOtherDetail = applicant.Personal_Email__c;
        }else{
            application.applicant.addressOtherDetail = applicant.Email;
        }
        application.applicant.citizenshipType = app.Residency_Status__c;
        application.applicant.readOnlyAccessIndicator = false;
        application.applicant.prApplicationIndicator = false;
        application.applicant.password = 'CRM';

        application.applicant.chessNumber = '';
        application.applicant.birthCountryCode = '';

        application.applicant.prApplicationDate = '';
        application.applicant.nameFormatCode = '';
        application.applicant.addressSubmissionDate = '';
        application.applicant.registrationPhoneNumber = '';
        application.applicant.applicantId = '';

        // Visa
        application.applicant.visa = new ObdAdmissionApplicationRequest.Visa();

        /********************************************************
        Integration to handle the "International" students integration to Callista.
        This classification is ONLY to support integration and does not reflect how applications work or their business process.
        ********************************************************/

        if (MyApplicationUtilities.integrationInternational(app.Residency_Status__c)) {
            if (app.Visa_Start_Date__c == null) {
                application.applicant.visa.startDate = '01/01/2000';
            } else {
                application.applicant.visa.startDate = String.valueOf(app.Visa_Start_Date__c.format());
            }

            if (app.Visa_End_Date__c == null) {
                application.applicant.visa.endDate = '02/01/2000';
            } else {
                application.applicant.visa.endDate = String.valueOf(app.Visa_End_Date__c.format());
            }

            if (app.Visa_Type__c == null || app.Visa_Type__c == '') {
                application.applicant.visa.type = 'APP-PORTAL';

            } else {
                application.applicant.visa.type = app.Visa_Type__c;
            }

            if (app.Visa_Number__c == null || app.Visa_Number__c == '') {
                application.applicant.visa.visanumber = 'NOT KNOWN';
            } else {
                application.applicant.visa.visanumber = app.Visa_Number__c;
            }

            // Start SFTM-226
            if (app.citizenCountryCode__c == '1101') {
                application.applicant.citizenCountryCode = WORKAROUND_AU_CTRY_CD;
            } else {
                application.applicant.citizenCountryCode = app.citizenCountryCode__c;
            }
            // End SFTM-226

            if (app.Passport_Number__c != '' && app.Passport_Number__c != null) {
                application.applicant.passportNumber = app.Passport_Number__c;
            } else {
                application.applicant.passportNumber = 'NOT KNOWN';
            }
        } else {

            //SFTLG-944
            if(app.Residency_Status__c == 'DOM-AUS'){
                application.applicant.citizenCountryCode = '';
            }
            // Start SFTM-226
            else if (app.citizenCountryCode__c == BDPConstants.AUSTRALIA_CALLISTA_CODE) {
                application.applicant.citizenCountryCode = WORKAROUND_AU_CTRY_CD;
            } else {
                application.applicant.citizenCountryCode = '';
            }
            // End SFTM-226
            application.applicant.passportNumber = '';
        }

        // Secondary
        application.applicant.secondary = new List<ObdAdmissionApplicationRequest.Secondary>();
        for (Contact_Qualification__c sec : secondary) {
            application.applicant.secondary.add(StudFirst_SubmitApplicationHelper.addSecondary(sec));
        }

        // Tertiary
        application.applicant.tertiary = new List<ObdAdmissionApplicationRequest.Tertiary>();
        for (Contact_Qualification__c ter : tertiary) {
            application.applicant.tertiary.add(StudFirst_SubmitApplicationHelper.addTertiary(ter));
        }

        // Other Qualification
        if(app.Type_of_Study__c != Constants.STUDYTYPE_GRADUATERESEARCH){
        application.applicant.otherQualification = new List<ObdAdmissionApplicationRequest.OtherQualification>();
        for (Contact_Qualification__c oq : other) {
            application.applicant.otherQualification.add(StudFirst_SubmitApplicationHelper.addOther(oq));
        }
        }

        // Admission Test
        application.applicant.admissionTest = new List<ObdAdmissionApplicationRequest.AdmissionTest>();
        for (Contact_Qualification__c eng : english) {
            application.applicant.admissionTest.add(StudFirst_SubmitApplicationHelper.addAdmissionTest(eng));
        }
        //Admission Test - English Language Proficiency
        if(app.English_Language_Proficiency__c!=null)
        {
            application.applicant.admissionTest.add(StudFirst_SubmitApplicationHelper.addEnglishLanguageProficiency(app.English_Language_Proficiency__c));
        }
        
        // Query for Work Experience with a Submitted Application combination
        List<Application_work_Experience_provided__c> submittedApps = new List<Application_work_Experience_provided__c>([select Work_Experience__r.Id,application__r.Id from Application_work_Experience_provided__c where Application__r.Status__c ='Submitted' and Application__r.Applicant__c = :applicant.Id]);
        
        Set<Id> weid = new Set<Id>();
        // Collect Work Experience Id's for the Submitted Applications in a List
        for(Application_work_Experience_provided__c we:submittedApps)
        {
            weid.add(we.Work_Experience__r.Id);
        }
        // Work Experience
        application.applicant.workExperience = new List<ObdAdmissionApplicationRequest.WorkExperience>();

        for (Work_Experience__c we : wrkExp) {
            //Ant Custodio, 21.Jul.2017 - only send work experience records that are either new or not on the previous application
            //SMendu, 28.Feb.2023 - Check that the WorkExperience has not been submitted before 
            if (!weid.contains(we.Id)) {
                application.applicant.workExperience.add(StudFirst_SubmitApplicationHelper.addWorkExperience(we));
            }
            //END - Ant Custodio
        }

        // Course Application
        application.courseApplication = new ObdAdmissionApplicationRequest.CourseApplication();
        application.courseApplication.applicationNumber = DEFAULT_APPLICATION_NUMBER;
        application.courseApplication.standardApplicationType = STANDARD_APPLICATION_TYPE;
        application.courseApplication.accessEquityComments = '';
        application.courseApplication.requestForAdvancedStandingIndicator = app.Credit_Intention__c;

        // Partner logic
        // Set application type as non-award
        if(app.Type_of_Study__c == Constants.STUDYTYPE_EXCHANGE || app.Type_of_Study__c == Constants.STUDYTYPE_STUDYABROAD){
            application.courseApplication.standardApplicationType = NON_AWARD_APPLICATION_TYPE;
        }

        application.courseApplication.marketing = new List<ObdAdmissionApplicationRequest.Marketing>();

        //Assemble the throttle
        ObdAdmissionApplicationRequest.Marketing throttleQuestion = new ObdAdmissionApplicationRequest.Marketing();
        throttleQuestion.question = 'workRelayAssessment';
        throttleQuestion.applicantAnswer = String.valueOf(wrAssessment);
        application.courseApplication.marketing.add(throttleQuestion);
        
        //SFTD-521 - check if the applicant is a current or previous student. If they are don't require qualifications - add a parameter to by pass qualification validation on callista
        String applicantStudentType = 'NoMatch';
        if(app != null){
            if(app.Applicant__c != null){
                //Setup correct parameter
                String searchPersonId = applicant.Previous_Monash_ID__c;
                if(applicant.Person_ID_unique__c != null){
                    searchPersonId = applicant.Person_ID_unique__c;
                }
                //Call logic to determine applicant student type
                if(searchPersonId != null && applicant.BirthDate != null){
                    applicantStudentType = MyApplicationUtilities.findCurrentPreviousStudent(searchPersonId, applicant.BirthDate);
                }
            }
        }
        //Only require quals if the applicant is not a current nor a previous student
        ObdAdmissionApplicationRequest.Marketing qualificationByPass = new ObdAdmissionApplicationRequest.Marketing();
        qualificationByPass.question = 'bypassZeroQualValidation';
        qualificationByPass.applicantAnswer = 'false';
        if( applicantStudentType != 'NoMatch' || 
            app.Type_of_Study__c == Constants.STUDYTYPE_GRADUATERESEARCH ) 
        {
            qualificationByPass.applicantAnswer = 'true';
        }
        application.courseApplication.marketing.add(qualificationByPass);

        /*if(app.Applying_for_Credit__c != null && app.Applying_for_Credit__c.equalsIgnoreCase('yes')) {
             application.courseApplication.requestForAdvancedStandingIndicator = true;
         } else {
             application.courseApplication.requestForAdvancedStandingIndicator = false;
         }*/
        // SFTG-2870 My.App HomePhone mapping corrected. Application to contain only HomePhone and MobilePhone. So Phone2 is sent blank, to avoid duplicate entries in Callista
        application.applicant.phone1 = applicant.HomePhone;
        application.applicant.phone2 = ''; 


        application.courseApplication.requestForScholarshipIndicator = false;
        application.courseApplication.accessEquityCategories = new List<String>();
        if (applicant.Aboriginal_or_Torres_Strait_Islander__c != null && applicant.Aboriginal_or_Torres_Strait_Islander__c.equalsIgnoreCase('yes') && app.Residency_Status__c == 'DOM-AUS')
            application.courseApplication.accessEquityCategories.add(INDIGENOUS);

        if (app.HasDisabilities__c == 'Yes') {
            application.courseApplication.accessEquityCategories.add('MEDICAL');
        }

        // Partner logic
        // Collect acps unit preferences
        Map<Id, List<String>> unitPreferenceMap = new Map<Id, List<String>>();
        if(app.Type_of_Study__c == Constants.STUDYTYPE_EXCHANGE || app.Type_of_Study__c == Constants.STUDYTYPE_STUDYABROAD){
            // Add unit preference as notes/comments
            for(Unit_Preference__c loopPreference : [SELECT Id, Application_Course_Preference__c, Unit_Offering__c, Unit_Offering__r.Academic_Year__c, Unit_Offering__r.Teaching_Period__c, 
                                                    Unit_Offering__r.Unit_Version__c, Unit_Offering__r.Location__c, Unit_Offering__r.Unit_Code__c,
                                                    Unit_Offering__r.Unit_Class__c, Unit_Offering__r.UOO_ID__c,Unit_Offering__r.Title__c,Unit_Offering__r.Unit_Mode__c,Unit_Offering__r.MA_Status__c
                                                    FROM Unit_Preference__c 
                                                    WHERE Application_Course_Preference__r.Application__c = :app.Id
                                                    ORDER BY Semester__c,Preference_Number__c]){
                if(!unitPreferenceMap.containsKey(loopPreference.Application_Course_Preference__c)){
                    unitPreferenceMap.put(loopPreference.Application_Course_Preference__c, new List<String>());
                }
                unitPreferenceMap.get(loopPreference.Application_Course_Preference__c).add(loopPreference.Unit_Offering__r.Academic_Year__c + '/' + loopPreference.Unit_Offering__r.Teaching_Period__c + ' ' + loopPreference.Unit_Offering__r.Unit_Code__c + ' ' + loopPreference.Unit_Offering__r.Title__c +' '+ loopPreference.Unit_Offering__r.Location__c + ' ' + loopPreference.Unit_Offering__r.Unit_Mode__c + ' ' + loopPreference.Unit_Offering__r.MA_Status__c);
            }
        }

        // Course Data
        application.courseApplication.courseData = new List<ObdAdmissionApplicationRequest.CourseData>();
        for (Application_Course_Preference__c coursePreference : coursePreferences) {
            ObdAdmissionApplicationRequest.CourseData courseDataPayload = StudFirst_SubmitApplicationHelper.addCourseData(coursePreference);

            // Partner logic
            // Add unit preferences as notes
            if(app.Type_of_Study__c == Constants.STUDYTYPE_EXCHANGE || app.Type_of_Study__c == Constants.STUDYTYPE_STUDYABROAD){
                if(unitPreferenceMap.containsKey(coursePreference.Id)){
                    courseDataPayload.unitDetails = String.join(unitPreferenceMap.get(coursePreference.Id), '\n');
                }
            }

            application.courseApplication.courseData.add(courseDataPayload);
        }

        aar.admissionApplication.applications.add(application);
        String request = JSON.serializePretty(aar);
        request = request.replace('visanumber', 'number');
        return request;

    }

    @TestVisible
    private static String getAgentPersonId(String agencyId){
        List<Contact> contacts = [
                SELECT Person_ID__c
                FROM Contact
                WHERE AccountId = :agencyId AND Person_ID__c != NULL AND Role_Account_Flag__c = TRUE
        ];

        if(contacts.size() == 1){
            return contacts[0].Person_ID__c;
        }
            
        return null;
        
    }

    @AuraEnabled
    public static String hasSubmitApplicationBtnAccess(String applicationId)
    {
        List<APPLICATION__c> appList = [SELECT Callista_Applicant_Id__c, Callista_Application_Id__c,STATUS__c FROM APPLICATION__c WHERE ID= :applicationId ];
        Boolean perm = FeatureManagement.checkPermission('Submit_Application_Button_Permission');
        
        if(!perm && !Test.isRunningTest())
            return 'You are not authorised to re-submit the application. Please contact support-eadmissions@monash.edu';

        if(!appList.isEmpty()) {
            if(appList[0].Status__c.equalsIgnoreCase('Draft'))
                return 'The application is in Draft status.Please change the status to "Sent for submission" and submit';
            
            if(appList[0].Status__c.equalsIgnoreCase('Review'))
                return 'The application is in Review status.Please change the status to "Sent for submission" and submit';

            if(appList[0].Status__c.equalsIgnoreCase('Submitted'))
                return 'The application has already been submitted successfully to Callista, it cannot be re-submitted';
        }
        
        return 'All good';     
    }
}