/*******************************************************************************
 * @author       Trent Delaney
 * @date         03 Sep 2018
 * @description  Class containing methods during Application Navigation
 * @revision
 * 05/03/2019 - Shalini Mendu - SFTDC-239
 * 18/09/2019 - Shalini Mendu - SFTN-260
 * 08/02/2022 - Vinothraja    - SFTG-2477 Added validations while uploading documents
 * 04/07/2024 - Vishal Gupta - Feature Toggle
*******************************************************************************/

@IsTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
private class ApplicationNavigationController_Test {

    /*
    * Data Setup
    */
    @testSetup static void testSetUp()
    {
        //Create community user
        User testApplicant = StudFirst_TestHelper.createCommunityUser();
    
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];
        testContact.Person_ID_unique__c = '12345678SA';
        update testContact;
        //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Type_of_Study__c ='Study Abroad';
        testApplication.Duration_of_Study__c ='1';
        testApplication.Applicant__c = testContact.Id;
        insert testApplication;



        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        testOffering.Start_date__C = Date.today();
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        insert testACP;
    }

    
	/*******************************************************************************
	* @author  		Shalini Mendu
	* @date         11.Mar.2021       
	* @description  Tests study duration/Plan validations for Monash Abroad applications
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and added Unit offering
    * THEN system shoud check if its not partner and the validation should fail
	*******************************************************************************/
    @isTest
    public static void testStudyAbroadImplementation()
    {
        User usr = [select id,name from User where LastName = 'TestingUser' limit 1];
        System.runAs(usr){
            Unit_Offering__c aUO = new Unit_Offering__c();
        
        aUO.Academic_Year__c = '2021';
		aUO.Active_Ind__c = true;
		aUO.Location__c = 'Clayton';
        aUO.Unit_Version__c = '1';
        aUO.Unit_Code__c = 'UnitXYZ';
        aUO.Calendar_Type__c = 'S0-1';
        aUO.Teaching_Period__c = 'S0-1';
        aUO.CI_Sequence_Number__c = '10001';
        aUO.Unit_Class__c = 'ON-CAMPUS';
        aUO.MA_Status__c='green';
        aUO.Start_date__c= Date.today();
        insert aUO;
        application_course_preference__c testACP =    [Select id from application_course_preference__c limit 1];

        Unit_preference__c up = new Unit_preference__c(Unit_Offering__c = aUO.Id,Application_Course_Preference__c = testACP.Id, Semester__c=1);
        insert up;
        Application__c app = [Select Id,Type_of_Study__c,Duration_of_Study__c from Application__c where Applicant__r.Person_ID_unique__c='12345678SA' limit 1];
        app.Campus_Location__c = 'Australia';
        update app;
        Boolean isPartnerCreated = ApplicationNavigationController.isValidDurationStudy(app.Id);
        Assert.isTrue(isPartnerCreated==true, 'This is not partner created');
        Map<String, String> retMap = ApplicationNavigationController.validateStudyPlans(app.Id);
        Assert.isTrue(retMap.size()==1, 'This should fail validation');
        }
    }

    /*
    * Testing Application Processing Navigation - for Australia
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application
    * THEN system shoud test Application Processing Navigation - for Australia
    */
    @IsTest
    static void test_ProcessStatusAustralia()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        String[] options = MyApplicationUtilities.getPicklistOptions('Submission_Progress__c', 'Application__c');
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Submission_Progress__c = options[1];
        app.Campus_Location__c = 'Australia';
        app.Residency_Status__c = 'DOM-AUS';
        app.HasDisabilities__c = 'Yes';
        app.Existing_Aus_disability_support__c ='Yes';
 		app.Disability_Opt_In__c =  'Yes';
        app.Criminal_History_Opt_In__c  =  'Yes';
        insert app;
        
        System.runAs(u){
            Map<String, Object> mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Forward');
            
             String result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Success');

            mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Backward');
            result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Success');

            mapResult = ApplicationNavigationController.ProcessStatus(null, null);            
             result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Error');

            mapResult = ApplicationNavigationController.ProcessStatus('BadId', 'BadInfo');
             result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Error');
        }

    }

    /*
    * Testing Application Processing Navigation - for Malaysia
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application
    * THEN system shoud test Application Processing Navigation - for Malaysia
    */
    @IsTest
    static void test_ProcessStatusMalaysia()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        String[] options = MyApplicationUtilities.getPicklistOptions('Submission_Progress__c', 'Application__c');
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Submission_Progress__c = options[1];
        app.Campus_Location__c = 'Malaysia';
        app.HasDisabilities__c = 'Yes';
        app.Existing_Aus_disability_support__c ='Yes';
	    app.Disability_Opt_In__c =  'Yes';
        app.Criminal_History_Opt_In__c  =  'Yes';
        insert app;

        System.runAs(u){
            Map<String, Object> mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Forward');

             String result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Error');

            mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Backward');
            result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Success');

        }

    }
    /*
    * Testing Application Processing Navigation - Negative scenario
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application
    * THEN system shoud test Application Processing Navigation - Negative scenario
    */
    @IsTest
    static void test_ProcessStatusError()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        String[] options = MyApplicationUtilities.getPicklistOptions('Submission_Progress__c', 'Application__c');
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Submission_Progress__c = options[1];
        app.Campus_Location__c = 'Australia';
        app.HasDisabilities__c = 'Yes';
        app.Existing_Aus_disability_support__c ='Yes';
	    app.Disability_Opt_In__c =  'Yes';
        app.Criminal_History_Opt_In__c  =  'Yes';
        insert app;
        Test.startTest();
        System.runAs(u){
            Map<String, Object> mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Forward');

            String result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Error');

            mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Backward');
            result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Success');

        }

        app.Campus_Location__c = null;
        update app;
        System.runAs(u){
            Map<String, Object> mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Forward');

            String result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Error');

            mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Backward');
            result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Success');

        }
        app.Campus_Location__c = 'Malaysia';
        update app;
        System.runAs(u){
            
            Map<String, Object> mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Forward');

            String result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Error');

            mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Backward');
            result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'Success');
            
        }
        Test.stopTest();
    }

    /*
    * Testing Application Creation
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application
    * THEN system shoud test the Application Creation
    */
    @IsTest
    static void test_CreateApplication()
    {
        User u = StudFirst_TestHelper.createCommunityUser();

        System.runAs(u){
            String appId = ApplicationNavigationController.CreateApplication();
            Assert.areNotEqual(appId, null);
            Assert.areNotEqual(appId, '');
        }
    }

    /*
    * Testing Validations for Disability during Application creation - No Disbilites
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application
    * THEN system shoud test the validations for Disability during Application creation - No Disbilites
    */
    @IsTest
    static void test_NoDisability_Validation(){
        User u = StudFirst_TestHelper.createCommunityUser();

        String[] options = MyApplicationUtilities.getPicklistOptions('Submission_Progress__c', 'Application__c');
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Submission_Progress__c = options[1];
        app.Campus_Location__c = 'Australia';
        app.Residency_Status__c = 'DOM-AUS';
        app.Disability_Opt_In__c =  'Yes';
        insert app;
        
        System.runAs(u){
            Map<String, Object> mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Forward');
            
            String result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'ValidationError');
        }
    }

    /*
    * Testing Validations for Disability during Application creation - Existing Disabilities
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application
    * THEN system shoud test the validations for Disability during Application creation - Existing Disabilities
    */
    @IsTest
    static void test_NoExistingDisabilitySupport_Validation(){
        User u = StudFirst_TestHelper.createCommunityUser();

        String[] options = MyApplicationUtilities.getPicklistOptions('Submission_Progress__c', 'Application__c');
        Application__c app = StudFirst_TestHelper.createApplication(u.ContactId);
        app.Submission_Progress__c = options[1];
        app.Campus_Location__c = 'Australia';
        app.Residency_Status__c = 'DOM-AUS';
        app.HasDisabilities__c = 'Yes';
        app.Disability_Opt_In__c =  'Yes';
        insert app;
        
        System.runAs(u){
            Map<String, Object> mapResult = ApplicationNavigationController.ProcessStatus(app.Id, 'Forward');
            
            String result = (String) mapResult.get(ApplicationNavigationController.FIELD_STATUS);
            Assert.areEqual(result, 'ValidationError');
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests creating the applicant user and resetting the progress of the application
     * @revision    03/02/2021 - Kristian Vegerano - Created
     *
     * GIVEN the student has applied for the my application from student portal
     * WHEN they are logged in and applied for a course application
     * THEN system shoud test creating the applicant user and resetting the progress of the application
     */
    @isTest
    public static void testGenerateUserResetApplicationProgressStatus() {
        User u = StudFirst_TestHelper.createCommunityUser();

        Application__c app = [SELECT Id, Type_of_Study__c, Duration_of_Study__c 
                              FROM Application__c 
                              WHERE Applicant__r.Person_ID_unique__c = '12345678SA' LIMIT 1];
        app.Applicant__c = [SELECT Id, ContactId FROM User WHERE Id = :u.Id].ContactId;
        update app;

        //Start test
        Test.startTest();
        System.runAs(u){
            ApplicationNavigationController.generateUserResetApplicationProgressStatus(app.Id);
        }
        Test.stopTest();

        Assert.areEqual('Declaration', [SELECT Id, Furthest_Progress__c FROM Application__c WHERE Id = :app.Id].Furthest_Progress__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests updating the Application JSON
     * @revision    03/02/2021 - Kristian Vegerano - Created
     * 
     * GIVEN the student has applied for the my application from student portal
     * WHEN they are logged in and applied for a course application and application is created
     * THEN system shoud tests updating the Application JSON
     */
    @isTest
    public static void testUpdateApplicationRecord() {
        User u = StudFirst_TestHelper.createCommunityUser();

        Application__c app = [SELECT Id, Type_of_Study__c, Duration_of_Study__c 
                              FROM Application__c 
                              WHERE Applicant__r.Person_ID_unique__c = '12345678SA' LIMIT 1];
        app.Furthest_Progress__c = 'Declaration';
        app.Applicant__c = [SELECT Id, ContactId FROM User WHERE Id = :u.Id].ContactId;
        update app;

        //Start test
        Map<String, Object> resultMap;
        Test.startTest();
        System.runAs(u){
            resultMap = ApplicationNavigationController.updateApplicationRecord(JSON.serialize(app));
        }
        Test.stopTest();

        Assert.areNotEqual(null, resultMap);
    }

    /*
    * Testing Validations for Study Plans - ACP & Unit Preferences
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application and application is created
    * THEN system shoud test the validations for Study Plans - ACP & Unit Preferences
    */
    @isTest
    public static void testValidateStudyPlansWithoutACP() {
        User u = StudFirst_TestHelper.createCommunityUser();
        Id contactId = [SELECT Id, ContactId FROM User WHERE Id = :u.Id].ContactId;
        
        Application__c testApplication = StudFirst_TestHelper.createApplication(contactId);
        testApplication.Type_of_Study__c ='Study Abroad';
        testApplication.Duration_of_Study__c ='1';
        testApplication.Applicant__c = contactId;
        insert testApplication;
        
        //Start test
        Map<String, String> resultMap;
        Test.startTest();
        System.runAs(u){
            resultMap = ApplicationNavigationController.validateStudyPlans(testApplication.id);
        }
        Test.stopTest();

        Assert.areEqual('You should choose a valid Course', resultMap.get('ACPSelection'), 'Applications without ACP are not validated');
    }

    /*
    * Testing Validations for Duration
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application and application is created
    * THEN system shoud test the validations for Duration
    */
    @isTest
    public static void testIsValidDurationStudyCoursework() {
        User usr = [select id,name from User where LastName = 'TestingUser' limit 1];
        System.runAs(usr){
            Unit_Offering__c aUO = new Unit_Offering__c();
            
            aUO.Academic_Year__c = '2021';
            aUO.Active_Ind__c = true;
            aUO.Location__c = 'Clayton';
            aUO.Unit_Version__c = '1';
            aUO.Unit_Code__c = 'UnitXYZ';
            aUO.Calendar_Type__c = 'S0-1';
            aUO.Teaching_Period__c = 'S0-1';
            aUO.CI_Sequence_Number__c = '10001';
            aUO.Unit_Class__c = 'ON-CAMPUS';
            aUO.MA_Status__c='green';
            aUO.Start_date__c= Date.today();
            insert aUO;
            application_course_preference__c testACP =    [Select id from application_course_preference__c limit 1];

            Unit_preference__c up = new Unit_preference__c(  Unit_Offering__c = aUO.Id,Application_Course_Preference__c = testACP.Id);
            insert up;
            Application__c app = [Select Id,Type_of_Study__c,Duration_of_Study__c from Application__c where Applicant__r.Person_ID_unique__c='12345678SA' limit 1];
            app.Type_of_Study__c = 'Coursework';
            update app;
            Boolean isPartnerCreated = ApplicationNavigationController.isValidDurationStudy(app.Id);
            Assert.isTrue(isPartnerCreated==true, 'This is not partner created');
        }        
    }
    /*
    * Testing Validations for Application records
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application and application is created
    * THEN system shoud test the validations for Application records
    */
    @isTest
    public static void testUpdateApplicationRecordError() {
        User u = StudFirst_TestHelper.createCommunityUser();

        String jsonRecord = null;
        Map<String, Object> resultMap;
        Test.startTest();
        System.runAs(u){
            resultMap = ApplicationNavigationController.updateApplicationRecord(jsonRecord);
        }
        Assert.areEqual('ERROR', (String)resultMap.get('RESULT'), 'Nulls are not handled');
    }

    /*
    * @author      Vinothraja
    * @description Tests Requested Documents are submitted or not
    * @revision    09/03/2022 - Vinothraja - Created
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application and application is created
    * THEN system shoud test requested Documents are submitted or not
    */
    @isTest
    public static void testValidateApplicantDocuments_Requested(){
        User usr = [select id,name,contactId from User where LastName = 'TestingUser' limit 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: usr.contactId];

        //Start test
        Map<String, String> resultMap;
        Test.startTest();
        System.runAs(usr){
            Application__c testApplication = [SELECT id FROM Application__c WHERE Type_of_Study__c ='Study Abroad'];

            Document_Checklist__c dc = StudFirst_TestHelper.createDocumentChecklist(testApplication, testContact, null, 'Residency');
            insert dc; 
            resultMap = ApplicationNavigationController.validateApplicantDocuments(testApplication.id);
        }
        Test.stopTest();

        Assert.isTrue(resultMap.get('message').contains('Proof of Residency'), 'Applications without Mandatory documents are not validated');
    }
    /*
    * @author      Vinothraja
    * @description Tests Mandatory Documents are submitted or not, and if they are Specific
    * @revision    09/03/2022 - Vinothraja - Created
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application and application is created
    * THEN system shoud test mandatory Documents are submitted or not, and if they are Specific
    */
    @isTest
    public static void testValidateApplicantDocuments_Submitted(){
        User usr = [select id,name,contactId from User where LastName = 'TestingUser' limit 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: usr.contactId];
        Application__c retrieveApp = null;
        //Start test
        Map<String, String> resultMap;
        Test.startTest();
        System.runAs(usr){
            Application__c testApplication = [SELECT id FROM Application__c WHERE Type_of_Study__c ='Study Abroad'];
            Qualification__c qual = StudFirst_TestHelper.createQualification('SecQual');
            insert qual;
            Contact_Qualification__c cq = StudFirst_TestHelper.createContactQualification(testContact, qual, 'Secondary Education');
            insert cq;
            Contact_Document__c cd = StudFirst_TestHelper.createContactDocument(testContact.Id, cq.Id);
            cd.Application__c = testApplication.id;
            insert cd;
            Document_Checklist__c dc = StudFirst_TestHelper.createDocumentChecklist(testApplication, testContact, cq, 'Qualification');
            dc.Checklist_Requirement__c = 'Secondary Education Results required';
            dc.Status__c = 'Submitted'; 
            dc.Unique_ID__c = dc.Application__c + '-' + dc.Type__c ;
            insert dc; 
            resultMap = ApplicationNavigationController.validateApplicantDocuments(testApplication.id);
            retrieveApp = ApplicationNavigationController.retrieveApplication([SELECT id FROM Application__c WHERE Type_of_Study__c ='Study Abroad'].Id);

        }
        Test.stopTest();
        Assert.isTrue(retrieveApp!=null, 'Application should be retrieved');
        Assert.isTrue(resultMap.get('message').contains('Secondary Education Results required'), 'Applications without Mandatory documents are not validated');
    }
    
    /*
    * @author      Visal gupta
    * @description Tests Mandatory Documents are submitted or not, and if they are Specific
    * @revision    07/07/2024 - Vishal - Created
    *
    * GIVEN the student has applied for the my application from student portal
    * WHEN they are logged in and applied for a course application and application is created
    * THEN system shoud get the feature toggle for the application screen to render on the UI
    */
    @IsTest
    static void test_fetchFeatureToggle() {
        User u = StudFirst_TestHelper.createCommunityUser();

        System.runAs(u) {
            Feature_Switch__c data = ApplicationNavigationController.fetchMyAppFeatureToggle(); 
            Assert.areNotEqual(null, data, 'Feature switch is not null');
        }

    }
}