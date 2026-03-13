@isTest(isParallel=true)
public class StudFirst_SubmitApplicationHelper_Test {

    @TestSetup 
    static void testSetup(){
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

        Callista_Country_Code__c testCallistaCountry = new Callista_Country_Code__c();
        testCallistaCountry.Name = 'AUSTRALIA';
        testCallistaCountry.Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE;
        testCallistaCountry.Country__c = 'Australia';
        testCallistaCountry.High_Risk__c = false;
        insert testCallistaCountry;

        Callista_Sub_Score_Type__c testSubScore = new Callista_Sub_Score_Type__c();
        testSubScore.Name = 'Essay Rating';
        testSubScore.Available_in_Portal__c = true;
        testSubScore.Code__c = 'ESS-RATING';
        insert testSubScore;
    }
    
    @IsTest
    static void test_GetApplication() {
        Id applicationId = [SELECT Id FROM Application__c].Id;

        Application__c testApplication;
        Test.startTest();
            testApplication = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
        Test.stopTest();
        System.assertNotEquals(testApplication, null);
    }

    @IsTest
    static void test_GetApplications() {
        List<String> applicationIds = new List<String>();
        for(Application__c loopApplication : [SELECT Id FROM Application__c]){
            applicationIds.add(loopApplication.Id);
        }

        Map<String, Application__c> applicationMap;
        Test.startTest();
            applicationMap = StudFirst_SubmitApplicationHelper.getApplicationsByIds(applicationIds);
        Test.stopTest();
        System.assertNotEquals(applicationMap, null);
    }

    @IsTest
    static void test_GetApplicant() {
        Id applicantId = [SELECT Id FROM Contact].Id;

        Contact testApplicant;
        Test.startTest();
            testApplicant = StudFirst_SubmitApplicationHelper.getApplicantById(applicantId);
        Test.stopTest();
        System.assertNotEquals(testApplicant, null);
    }
    
    @IsTest
    static void test_GetContactQualifications(){
        Id applicantId = [SELECT Id FROM Contact].Id;
        
        List<Contact_Qualification__c> contactQualList = new List<Contact_Qualification__c>();
        Test.startTest();
            contactQualList = StudFirst_SubmitApplicationHelper.getContactQualifications(applicantId);
        Test.stopTest();
        System.assertNotEquals(contactQualList, null);
    }
    
    @IsTest
    static void test_GetWorkExperience() {
        Id applicantId = [SELECT Id FROM Contact].Id;
        
        List<Work_Experience__c> workExpList = new List<Work_Experience__c>();
        Test.startTest();
            workExpList = StudFirst_SubmitApplicationHelper.getWorkExperience(applicantId);
        Test.stopTest();
        System.assertNotEquals(workExpList, null);
    }

    @IsTest
    static void test_GetACP() {
        Id applicationId = [SELECT Id FROM Application__c].Id;

        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        Test.startTest();
            acpList = StudFirst_SubmitApplicationHelper.getCoursePreferences(applicationId);
        Test.stopTest();
        System.assertNotEquals(acpList, null);
    }
    
    @IsTest
    static void test_GetContactDocument() {
        Id contactDocumentId = [SELECT Id FROM Contact_Document__c].Id;

        Contact_Document__c testContactDocument = new Contact_Document__c();
        Test.startTest();
            testContactDocument = StudFirst_SubmitApplicationHelper.getContactDocument(contactDocumentId);
        Test.stopTest();
        System.assertNotEquals(testContactDocument, null);
    }
    
    @IsTest
    static void test_GetUser() {
        Id userId = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()].Id;

        User testUser = new User();
        Test.startTest();
            testUser = StudFirst_SubmitApplicationHelper.getUser(userId);
        Test.stopTest();
        System.assertNotEquals(testUser, null);
    }

    @IsTest
    static void test_GetCountryCode() {
        String testCountryCode;
        Test.startTest();
            testCountryCode = StudFirst_SubmitApplicationHelper.getCountryCode('Australia');
        Test.stopTest();
        System.assertNotEquals(testCountryCode, null);
    }

    @IsTest
    static void test_GetSubScoreCode() {
        String testScore;
        Test.startTest();
            testScore = StudFirst_SubmitApplicationHelper.getSubScoreCode('Essay Rating');
        Test.stopTest();
        System.assertNotEquals(testScore, null);
    }

    @IsTest
    static void test_AddSecondary() {
        Id applicantId = [SELECT Id FROM Contact].Id;
        
        List<Contact_Qualification__c> contactQualList = new List<Contact_Qualification__c>();
        contactQualList = StudFirst_SubmitApplicationHelper.getContactQualifications(applicantId);
        ObdAdmissionApplicationRequest.Secondary testSecondary;
        Test.startTest();
            testSecondary = StudFirst_SubmitApplicationHelper.addSecondary(contactQualList[0]);
        Test.stopTest();
        System.assertNotEquals(testSecondary, null);
    }

    @IsTest
    static void test_AddTertiary() {
        Id applicantId = [SELECT Id FROM Contact].Id;
        
        List<Contact_Qualification__c> contactQualList = new List<Contact_Qualification__c>();
        contactQualList = StudFirst_SubmitApplicationHelper.getContactQualifications(applicantId);
        ObdAdmissionApplicationRequest.Tertiary testTertiary;
        Test.startTest();
            testTertiary = StudFirst_SubmitApplicationHelper.addTertiary(contactQualList[0]);
        Test.stopTest();
        System.assertNotEquals(testTertiary, null);
    }

    @IsTest
    static void test_AddOther() {
        Id applicantId = [SELECT Id FROM Contact].Id;
        
        List<Contact_Qualification__c> contactQualList = new List<Contact_Qualification__c>();
        contactQualList = StudFirst_SubmitApplicationHelper.getContactQualifications(applicantId);
        ObdAdmissionApplicationRequest.OtherQualification testOther;
        Test.startTest();
            testOther = StudFirst_SubmitApplicationHelper.addOther(contactQualList[0]);
        Test.stopTest();
        System.assertNotEquals(testOther, null);
    }

    @IsTest
    static void test_AddAdmissionTest() {
        Id applicantId = [SELECT Id FROM Contact].Id;
        
        List<Contact_Qualification__c> contactQualList = new List<Contact_Qualification__c>();
        contactQualList = StudFirst_SubmitApplicationHelper.getContactQualifications(applicantId);
        ObdAdmissionApplicationRequest.AdmissionTest testAdmission;
        Test.startTest();
            testAdmission = StudFirst_SubmitApplicationHelper.addAdmissionTest(contactQualList[0]);
        Test.stopTest();
        System.assertNotEquals(testAdmission, null);
    }

    @IsTest
    static void test_AddSubScore() {
        ObdAdmissionApplicationRequest.AdmissionTestSubscore testAdmissionSubscore;
        Test.startTest();
            testAdmissionSubscore = StudFirst_SubmitApplicationHelper.addSubScore('value', 'Essay Rating');
        Test.stopTest();
        System.assertNotEquals(testAdmissionSubscore, null);
    }
    
    @IsTest
    static void test_addEnglishLanguageProficiency() {
        ObdAdmissionApplicationRequest.AdmissionTest testAdmission;
        Test.startTest();
        testAdmission = StudFirst_SubmitApplicationHelper.addEnglishLanguageProficiency('Yes');
        Test.stopTest();
        System.assertNotEquals(testAdmission, null);
    }

    @IsTest
    static void test_AddWorkExperience() {
        Id applicantId = [SELECT Id FROM Contact].Id;
        
        List<Work_Experience__c> workExpList = new List<Work_Experience__c>();
        workExpList = StudFirst_SubmitApplicationHelper.getWorkExperience(applicantId);
        ObdAdmissionApplicationRequest.WorkExperience testWorkExperience;
        Test.startTest();
            testWorkExperience = StudFirst_SubmitApplicationHelper.addWorkExperience(workExpList[0]);
        Test.stopTest();
        System.assertNotEquals(testWorkExperience, null);
    }

    @IsTest
    static void test_AddCourseData() {
        Id applicationId = [SELECT Id FROM Application__c].Id;

        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        acpList = StudFirst_SubmitApplicationHelper.getCoursePreferences(applicationId);
        ObdAdmissionApplicationRequest.CourseData testCourseData;
        Test.startTest();
            testCourseData = StudFirst_SubmitApplicationHelper.addCourseData(acpList[0]);
        Test.stopTest();
        System.assertNotEquals(testCourseData, null);
    }

    @IsTest
    static void test_GetInstitutionCodeCaulfield() {
        String institutionCode;
        Test.startTest();
            institutionCode = StudFirst_SubmitApplicationHelper.getInstitutionCode('Caulfield/Chisholm Institute of Technology (before 1990)');
        Test.stopTest();
        System.assertEquals(institutionCode, '2160');
    }

    @IsTest
    static void test_GetInstitutionCodeGippsland() {
        String institutionCode;
        Test.startTest();
            institutionCode = StudFirst_SubmitApplicationHelper.getInstitutionCode('Gippsland Institute of Advanced Education(before 1991)');
        Test.stopTest();
        System.assertEquals(institutionCode, '2165');
    }

    @IsTest
    static void test_GetInstitutionCodeMonash() {
        String institutionCode;
        Test.startTest();
            institutionCode = StudFirst_SubmitApplicationHelper.getInstitutionCode('Monash University');
        Test.stopTest();
        System.assertEquals(institutionCode, '3035');
    }

    @IsTest
    static void test_GetInstitutionCodeVictorian() {
        String institutionCode;
        Test.startTest();
            institutionCode = StudFirst_SubmitApplicationHelper.getInstitutionCode('Victorian College of Pharmacy (before 1992)');
        Test.stopTest();
        System.assertEquals(institutionCode, '2181');
    }

    @IsTest
    static void test_GetInstitutionCodeATTEMPTED() {
        String levelOfCompletionStatus;
        Test.startTest();
            levelOfCompletionStatus = StudFirst_SubmitApplicationHelper.getLevelOfCompletion('ATTEMPTED BUT WAS NOT COMPLETED');
        Test.stopTest();
        System.assertEquals(levelOfCompletionStatus, 'ATTEMPTED');
    }

    @IsTest
    static void test_GetInstitutionCodeCURRENTLY() {
        String levelOfCompletionStatus;
        Test.startTest();
            levelOfCompletionStatus = StudFirst_SubmitApplicationHelper.getLevelOfCompletion('CURRENTLY STUDYING');
        Test.stopTest();
        System.assertEquals(levelOfCompletionStatus, 'CURRENT');
    }

    @IsTest
    static void test_GetInstitutionCodeDISCONTINUED() {
        String levelOfCompletionStatus;
        Test.startTest();
            levelOfCompletionStatus = StudFirst_SubmitApplicationHelper.getLevelOfCompletion('DISCONTINUED');
        Test.stopTest();
        System.assertEquals(levelOfCompletionStatus, 'DISCONT');
    }

    @IsTest
    static void test_GetInstitutionCodeSUCCESSFULLY() {
        String levelOfCompletionStatus;
        Test.startTest();
            levelOfCompletionStatus = StudFirst_SubmitApplicationHelper.getLevelOfCompletion('SUCCESSFULLY COMPLETED AND OBTAINED');
        Test.stopTest();
        System.assertEquals(levelOfCompletionStatus, 'SUCCESSFUL');
    }

    @IsTest
    static void test_Sleep() {
        //No assertions required
        Test.startTest();
            StudFirst_SubmitApplicationHelper.sleep(1000);
        Test.stopTest();
    }

     /**
     * @description Test that the parseApplicantId method returns Applicantid from Application 
        as Callista_Applicant_Id__c is present on the Application
     */
    @isTest
    static void test_shouldParseApplicantIdFromApplication() {
        Id applicationId = [SELECT Id FROM Application__c].Id;
        Application__c testApplication = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
        testApplication.Callista_Applicant_Id__c = '1754847';
        String bulkApplicantIds = [Select bulkapi_Applicant_Ids__c from Contact where Id=:testApplication.Applicant__c].bulkapi_Applicant_Ids__c;
        update testApplication;
        Test.startTest();
        String retAPPiD = StudFirst_SubmitApplicationHelper.parseApplicantId(testApplication.Callista_Applicant_Id__c , bulkApplicantIds);
        Test.stopTest();
        Assert.areEqual('1754847', retAPPiD, 'The returned ApplicantID must be 1754847');
    }

     /**
     * @description Test that the parseApplicantId method returns one 
     * of the largest values from bulkapi_Applicant_Ids__c on the  Contact 
     */
    @isTest
    static void test_shouldParseApplicantIdFromApplicant() {
        Id applicationId = [SELECT Id FROM Application__c].Id;
        Test.startTest();
            Application__c testApplication = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
            Id applicantId = testApplication.Applicant__c;
            Contact con = [SELECT Id,bulkapi_Applicant_Ids__c FROM Contact where id=:applicantId];
            con.bulkapi_Applicant_Ids__c = '982482;708231;609479';
            update con;
            String retAPPiD = StudFirst_SubmitApplicationHelper.parseApplicantId(testApplication.Callista_Applicant_Id__c , con.bulkapi_Applicant_Ids__c);
            Test.stopTest();
            Assert.areEqual('982482', retAPPiD, 'The returned ApplicantID must be 982482');
    }

     /**
     * @description Test that the parseApplicantId method returns null 
     * as Callista_Applicant_Id__c on Application is empty and 
     * bulkapi_Applicant_Ids__c on the  Contact is also empty
     */
    @isTest
    static void test_shouldParseNullApplicantId() {
        Id applicationId = [SELECT Id FROM Application__c].Id;
        Test.startTest();
            Application__c testApplication = StudFirst_SubmitApplicationHelper.getApplicationById(applicationId);
            Id applicantId = testApplication.Applicant__c;
            Contact con = [SELECT Id,bulkapi_Applicant_Ids__c FROM Contact where id=:applicantId];
            String retAPPiD = StudFirst_SubmitApplicationHelper.parseApplicantId(testApplication.Callista_Applicant_Id__c , con.bulkapi_Applicant_Ids__c);
            Test.stopTest();
            Assert.areEqual(null, retAPPiD, 'The returned ApplicantID must be null');
    }
}