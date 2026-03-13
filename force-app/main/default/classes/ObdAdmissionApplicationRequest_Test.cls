/**
 * @author Trent De Laney
 * @date 5 Dec 2019 at 10:55:39 am
 * @group Test Class
 * @description Covers the request message for the Application submission to Callista from my.app, IDP and Agent Portal. Needs to be covered line by line for Salesforce to pick up the coverage
 */
@IsTest
public with sharing class ObdAdmissionApplicationRequest_Test {
    @IsTest
    public static void test_AssignPropertyValues(){
        ObdAdmissionApplicationRequest applicationRequest = new ObdAdmissionApplicationRequest();
        applicationRequest.admissionApplication = new ObdAdmissionApplicationRequest.AdmissionApplication();

        //Agent Assignment
        applicationRequest.admissionApplication.agent = new ObdAdmissionApplicationRequest.Agent();
        applicationRequest.admissionApplication.agent.agentPersonId = '1000';
        applicationRequest.admissionApplication.applications = new List<ObdAdmissionApplicationRequest.Application>();

        //Applications
        ObdAdmissionApplicationRequest.Application application = new ObdAdmissionApplicationRequest.Application();
        application.applicant = new ObdAdmissionApplicationRequest.Applicant();
        application.applicant.externalApplicantId = '1000';
        application.applicant.surname = 'Test';
        application.applicant.firstName = 'Test';
        application.applicant.otherName = 'Test';
        application.applicant.title = 'Mr';
        application.applicant.sex = 'M';
        application.applicant.preferredGivenName = 'Tester';
        application.applicant.previousSurname = 'OldTest';
        application.applicant.previousStudentIndicator = false;
        application.applicant.previousInstitutionCode = 'CLAYTON';
        application.applicant.previousPersonId = '1000';
        application.applicant.birthDate = '01/01/2000';
        application.applicant.emailAddress = 'test@test.com';
        application.applicant.addressType = 'POSTAL';
        application.applicant.addressLine1 = '123 Test St';
        application.applicant.addressLine2 = '123 Test St';
        application.applicant.addressLine3 = '123 Test St';
        application.applicant.addressLine4 = '123 Test St';
        application.applicant.addressLine5 = '123 Test St';
        application.applicant.postcode = '3000';
        application.applicant.osCode = '3000';
        application.applicant.phone1 = '0404000000';
        application.applicant.phone2 = '0404000000';
        application.applicant.phone3 = '0404000000';
        application.applicant.addressOtherDetail = 'Test';
        application.applicant.citizenshipType = 'DOM-AUS';
        application.applicant.chessNumber = '1234567890';
        application.applicant.birthCountryCode = 'AUD';
        application.applicant.citizenCountryCode = 'AUD';
        application.applicant.passportNumber = 'M1234567890';
        application.applicant.prApplicationIndicator = true;
        application.applicant.prApplicationDate = '01/01/2000';
        application.applicant.nameFormatCode = 'OOO';
        application.applicant.addressSubmissionDate = '01/01/2000';
        application.applicant.registrationPhoneNumber = '0404000000';
        application.applicant.readOnlyAccessIndicator = false;
        application.applicant.password = '123';
        application.applicant.applicantId = '1234567890';

        application.applicant.visa = new ObdAdmissionApplicationRequest.Visa();
        application.applicant.visa.type = 'APP-PORTAL';
        application.applicant.visa.startDate = '01/01/2000';
        application.applicant.visa.endDate = '01/01/2000';
        application.applicant.visa.visanumber = '1000';

        applicationRequest.admissionApplication.applications.add(application);

        /********************************************************
        Secondary Assignment
        ********************************************************/
        ObdAdmissionApplicationRequest.Secondary secondary = new ObdAdmissionApplicationRequest.Secondary();
        secondary.countryCode = 'AUD';
        secondary.stateCode = 'VIC';
        secondary.assessmentQualificationType = 'VCE';
        secondary.otherAssessmentQualification = 'null';
        secondary.englishInstructionIndicator = false;
        secondary.schoolCode = 'Test';
        secondary.otherSchool = 'Test';
        secondary.completionYear = '2020';
        secondary.score = 'A';
        secondary.result = 'A';

        application.applicant.secondary = new List<ObdAdmissionApplicationRequest.Secondary>();
        application.applicant.secondary.add(secondary);

        /********************************************************
        Tertiary Assignment
        ********************************************************/
        ObdAdmissionApplicationRequest.Tertiary tertiary = new ObdAdmissionApplicationRequest.Tertiary();
        tertiary.countryCode = 'AUD';
        tertiary.qualificationName = 'Bachelor';
        tertiary.englishInstructionIndicator = false;
        tertiary.institutionCode = 'M';
        tertiary.otherInstitution = 'Test';
        tertiary.firstYearEnrolled = '2002';
        tertiary.lastYearEnrolled = '2005';
        tertiary.levelOfCompletion = 'Completed';

        application.applicant.tertiary = new List<ObdAdmissionApplicationRequest.Tertiary>();
        application.applicant.tertiary.add(tertiary);

        ObdAdmissionApplicationRequest.OtherQualification otherQualification = new ObdAdmissionApplicationRequest.OtherQualification();
        otherQualification.qualificationType = 'OTHER';
        otherQualification.otherQualification = 'OTHER';
        otherQualification.comments = 'Test';
        otherQualification.achievedDate = '01/01/2000';

        application.applicant.otherQualification = new List<ObdAdmissionApplicationRequest.OtherQualification>();
        application.applicant.otherQualification.add(otherQualification);

        ObdAdmissionApplicationRequest.WorkExperience workExperience = new ObdAdmissionApplicationRequest.WorkExperience();
        workExperience.position = 'Tester';
        workExperience.employer = 'Test';
        workExperience.startDate = '01/01/2000';
        workExperience.endDate = '01/01/2001';
        workExperience.contactPersonName = 'Test';
        workExperience.contactAddress = '123 Test st';

        application.applicant.workExperience = new List<ObdAdmissionApplicationRequest.WorkExperience>();
        application.applicant.workExperience.add(workExperience);

        ObdAdmissionApplicationRequest.AdmissionTest admissionTest = new ObdAdmissionApplicationRequest.AdmissionTest();
        admissionTest.admissionTestType = 'IELTS';
        admissionTest.plannedDate = '01/01/2000';
        admissionTest.achievedDate = '01/01/2001';
        admissionTest.resultType = 'Test';
        admissionTest.score = 'A';
        admissionTest.grade = 'A';

        ObdAdmissionApplicationRequest.AdmissionTestSubscore admissionTestSubscore = new ObdAdmissionApplicationRequest.AdmissionTestSubscore();
        admissionTestSubscore.referenceCode = 'Test';
        admissionTestSubscore.subscore = 'B';
        admissionTest.admissionTestSubscore = new List<ObdAdmissionApplicationRequest.AdmissionTestSubscore>();
        admissionTest.admissionTestSubscore.add(admissionTestSubscore);

        application.applicant.admissionTest = new List<ObdAdmissionApplicationRequest.AdmissionTest>();
        application.applicant.admissionTest.add(admissionTest);

        ObdAdmissionApplicationRequest.Document document = new ObdAdmissionApplicationRequest.Document();
        document.filename = 'Test.txt';
        document.binaryDocument = '1234567890';
        document.documentComments = 'Test';
        document.documentType = 'Passport';
        document.mimeContentType = 'pdf';

        application.applicant.document = document;

        ObdAdmissionApplicationRequest.CourseData courseData = new ObdAdmissionApplicationRequest.CourseData();
        courseData.courseCode = 'A2000';
        courseData.courseVersionNumber = '1';
        courseData.locationCode = 'CLAYTON';
        courseData.attendanceMode = 'Test';
        courseData.attendanceType = 'Test';
        courseData.preferenceNumber = '1';
        courseData.admissionCalendarType = 'Test';
        courseData.admissionCiSequenceNumber = 'Test';
        courseData.academicCalendarType = 'Test';
        courseData.academicCiSequenceNumber = 'Test';
        courseData.typeOfPlaceCode = 'Test';
        courseData.unitDetails = 'Test';
        courseData.unitSet = new ObdAdmissionApplicationRequest.UnitSet();
        courseData.unitSet.unitSetCode = 'Test';
        courseData.unitSet.usVersionNumber = 'Test';

        ObdAdmissionApplicationRequest.CourseApplication courseApplication = new ObdAdmissionApplicationRequest.CourseApplication();
        courseApplication.applicationNumber = '1';
        courseApplication.standardApplicationType = 'Test';
        courseApplication.accessEquityComments = 'Test';
        courseApplication.requestForAdvancedStandingIndicator = false;
        courseApplication.requestForScholarshipIndicator = false;
        courseApplication.fromPortal = true;
        courseApplication.accessEquityCategories = new List<String>();
        courseApplication.courseData = new List<ObdAdmissionApplicationRequest.CourseData>();
        courseApplication.courseData.add(courseData);
        courseApplication.marketing = new List<ObdAdmissionApplicationRequest.Marketing>();
        ObdAdmissionApplicationRequest.Marketing marketing = new ObdAdmissionApplicationRequest.Marketing();
        marketing.question = 'Test';
        marketing.applicantAnswer = 'Test';
        application.courseApplication = courseApplication;

        ObdAdmissionApplicationRequest.ServiceQuestions serviceQuestions = new ObdAdmissionApplicationRequest.ServiceQuestions();
        courseApplication.serviceQuestions = serviceQuestions;
        ObdAdmissionApplicationRequest.MultiMulti multiMulti = new ObdAdmissionApplicationRequest.MultiMulti();
        ObdAdmissionApplicationRequest.YesNo yesNo = new ObdAdmissionApplicationRequest.YesNo();
        ObdAdmissionApplicationRequest.SingleMultiChoice singleMultiChoice = new ObdAdmissionApplicationRequest.SingleMultiChoice();
        ObdAdmissionApplicationRequest.OpenResponse openResponse = new ObdAdmissionApplicationRequest.OpenResponse();

        multiMulti.serviceCode = 'Test';
        multiMulti.startDate = '01/01/2000';
        multiMulti.openQuestionResponse = 'Test';

        ObdAdmissionApplicationRequest.Answer answer = new ObdAdmissionApplicationRequest.Answer();
        answer.answerCode = 'Test';
        answer.selectAnswerIndicator = 'Test';

        multiMulti.answer = new List<ObdAdmissionApplicationRequest.Answer>();
        multiMulti.answer.add(answer);

        yesNo.startDate = '01/01/2000';
        yesNo.serviceCode = 'Test';
        yesNo.yesNoAnswer = false;

        singleMultiChoice.serviceCode = 'Test';
        singleMultiChoice.startDate = '01/01/2000';
        singleMultiChoice.openQuestionResponse = 'Test';
        singleMultiChoice.answer = new List<ObdAdmissionApplicationRequest.Answer>();
        singleMultiChoice.answer.add(answer);

        openResponse.openQuestionResponse = 'Test';
        openResponse.startDate = '01/01/2000';
        openResponse.serviceCode = 'Test';

        serviceQuestions.openResponse = new List<ObdAdmissionApplicationRequest.OpenResponse>();
        serviceQuestions.singleMultiChoice = new List<ObdAdmissionApplicationRequest.SingleMultiChoice>();
        serviceQuestions.yesNo = new List<ObdAdmissionApplicationRequest.YesNo>();
        serviceQuestions.multiMulti = new List<ObdAdmissionApplicationRequest.MultiMulti>();


    }
}