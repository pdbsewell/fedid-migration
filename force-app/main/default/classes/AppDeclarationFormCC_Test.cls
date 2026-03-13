/*******************************************************************************
* @author       Ryan Wilson
* @date         03.May.2017         
* @description  Test class for AppDeclarationFormCC
* @revision     
* 09/03/2022 - Vinothraja   - SFTG-2477 Added Validations for My.App applications
* 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
* 06/08/2024 - Ben Greenland - SFTG-3888 additional test for validation bypass for OES scenarios
* 11/10/2024 - Vishal Gupta - added test method for updating the sequence number in Application_Qualification_Provided__c for Graduate Research applications
* 22/10/2024 - Girish P - DANO-281 additional test for validation bypass for Fee waiver codes during callista downtime
*******************************************************************************/
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
private class AppDeclarationFormCC_Test {
    private static Contact contactRecord;
    /* 
    * Data setup
    */
    @testSetup static void setup() {
        IntegrationSettings_SubmitApplication__c is = new IntegrationSettings_SubmitApplication__c();
        is.Base_Url__c = 'https://mix-dev.monash.edu';
        is.Path__c = '/la/v1/admissions/applications';
        is.Method__c = 'POST';
        is.Header_ClientId__c = 'c8411f0ca73a4ae6a0c7081a1336630f';
        is.Header_ClientSecret__c = 'cd2d5b9e26fa4999A33FF6A7F12D65AD';
        is.Header_ContentType__c = 'application/json';
        is.Mock_Endpoint_Applications__c = 'http://monash.getsandbox.com/la/v1/admissions/applications';
        is.Enable_Mock__c = false;
        is.Timeout__c = '12000';

        insert is;

        MIX_API_Config__c mc = new MIX_API_Config__c();
        mc.Base_Url__c = 'https://mix.dev';
        mc.Client_Id__c = 'abcdef';
        mc.Client_Secret__c = 'ghijkl';
        insert mc;

        Country_Attribute__c country = new Country_Attribute__c(Name = 'Australia', Callista_Code__c = '7103', Country__c = 'Australia');
        insert country;
    }

    /*
    * Testing Valdiation and Submission of Application
    */
    
    @isTest
    static void test_validateAndSubmitApplication()
    {
        //create a community user
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'DOM-AUS';
        contactRecord.HasDisabilities__c = 'No';
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.Birthdate = System.today().addYears(-15);
        contactRecord.Personal_Email__c = 'applicant@mailinator.com';
        contactRecord.MailingStreet = '1 smile street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MobilePhone = '0411111111';
        contactRecord.Gender__c = 'M';
        contactRecord.Salutation = 'Mr';
        contactRecord.Title = 'Mr';
        insert contactRecord;

        Integer rnd = Integer.valueOf(Math.random()*9999);
        User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-AUS',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'No',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant;

        /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
         * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
            insert psa;
        }
        
        //contactRecord = [SELECT id FROM CONTACT WHERE id=: applicant.ContactId];

        //create a new draft application
        Application__c appRecord = createCompletedApplication(true, applicant.ContactId);
        appRecord.OwnerId = applicant.Id;
        appRecord.Disability_Opt_In__c =  'Yes';
        appRecord.Criminal_History_Opt_In__c  =  'Yes';
        update appRecord;

        test.startTest();
        System.runAs(applicant) {
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

            Map<String, Object> mapResults = AppDeclarationFormCC.validateAndSubmitApplication(appRecord.Id);
            List<Map<String, Object>> errors = (List<Map<String, Object>>) mapResults.get(AppDeclarationFormCC.FIELD_ERRORS);
            System.assertEquals(null, errors, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: No submission Errors');
            
            Application__c appResult = [SELECT id, Status__C FROM Application__C WHERE id=: appRecord.Id];
            
            // SFTLG-802 start ----------------------------------------------------------------------------------------------------
            // System.assertEquals('Sent for Submission', appResult.Status__c, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: Submitted');
            System.assertEquals('Submission on Hold (Duplicate Contact)', appResult.Status__c, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: Submitted');
            // SFTLG-802 end ------------------------------------------------------------------------------------------------------
        }
        test.stopTest();
    }
    /*
    * Testing Valdiation and Submission of Application when callista is down
    */
    @isTest
    static void test_validateAndSubmitApplicationCallistaDown()
    {
        List<Map<String, Object>> errors;
        Map<String, Object> mapResults;
        // GIVEN community user
		User applicant = AppDeclarationFormCC_Test.createCommunityUserAndContactNoErrors();
        //creates a new draft application
        Application__c appRecord = createCompletedApplication(true, applicant.ContactId);
        appRecord.OwnerId = applicant.Id;
        appRecord.Disability_Opt_In__c =  'Yes';
        appRecord.Criminal_History_Opt_In__c  =  'Yes';
        // If callista is Down and Feewaiver is populated, there should not be any validation errors and application should still proceed
        appRecord.Fee_Payment_Mode__c = 'Application Fee Waiver Code';
        appRecord.Fee_Waiver_Code__c = '123';
        update appRecord;
        Test.startTest();
		// Setting the Custom metadata for Callista Down.
        Admissions_Settings__mdt callistaFeewaiverMaintenanceConfig = (Admissions_Settings__mdt)JSON.deserialize(
            '{' +
                '"DeveloperName": "CallistaFeeWaiverNotAvailable",' +
                '"Status__c": "Under Maintenance",' +
                '"Messages__c": "{\\"feeWaiverMessaging\\": \\"<b>PLEASE BE ADVISED:</b> The fee waiver code payment option is temporarily unavailable due to system maintenance.<br>If you wish to use the Fee Waiver Code, please save your application and return to submit it once maintenance is complete.\\"}",' +
                '"Configs__c": "{\\"myAppPaymentOptions\\": [{ \\"label\\": \\"Credit Card\\", \\"value\\": \\"Credit Card\\", \\"isDisabled\\": false }, { \\"label\\": \\"Convera (Previously Western Union)\\", \\"value\\": \\"Western Union\\", \\"isDisabled\\": false }, { \\"label\\": \\"Application Processing Fee Waiver Code\\", \\"value\\": \\"Application Fee Waiver Code\\", \\"isDisabled\\": true }]}"' +
            '}',
            Admissions_Settings__mdt.class
        );
        // WHEN Callisata is under maintenance
        // Set the config as system is down
        PaymentUtils.admissionsMaintenanceMDT = callistaFeewaiverMaintenanceConfig;
        // AND Application is submitted
        System.runAs(applicant) {
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
            mapResults = AppDeclarationFormCC.validateAndSubmitApplication(appRecord.Id);
            errors = (List<Map<String, Object>>) mapResults.get(AppDeclarationFormCC.FIELD_ERRORS);
            // THEN no errors are expected
            // If callista is Down and even if Fee waiver is populated, there should not be any validation errors as Callista validation is bypassed and application should still proceed
            Assert.isNull(errors, 'Fee waiver validation call occured, even after setting Custom metadata Fee waiver is NOT bypassed');
            Application__c appResult = [SELECT id,Fee_Waiver_Code__c, Status__C FROM Application__C WHERE id=: appRecord.Id];
            Assert.areEqual('Submission on Hold (Duplicate Contact)', appResult.Status__c, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: Submitted');
        }
        Test.stopTest();
        Application__c appResult = [SELECT id, Fee_Waiver_Code__c,Status__C FROM Application__C WHERE id=: appRecord.Id];
        Assert.areEqual('Sent for Submission', appResult.Status__c, 'Application failed to submit even during callista down');
    }    
    @isTest
	/**
	 * set a community user and contact and test when Callista is back online
	 */
    static void test_validateAndSubmitApplicationCallistaOnline()
    {
        List<Map<String, Object>> errors;
        Map<String, Object> mapResults;
        // GIVEN a community user
		User applicant = AppDeclarationFormCC_Test.createCommunityUserAndContactNoErrors();
        // WHEN a new draft application is created
		Application__c appRecord = createCompletedApplication(true, applicant.ContactId);
        appRecord.OwnerId = applicant.Id;
        appRecord.Disability_Opt_In__c =  'Yes';
        appRecord.Criminal_History_Opt_In__c  =  'Yes';
        // Test the Fee waiver is not bypassed when Callista is online
        appRecord.Fee_Payment_Mode__c = 'Application Fee Waiver Code';
        // for test simulation setting the Fee waiver code as 124
        appRecord.Fee_Waiver_Code__c = '124';
        update appRecord;
        Test.startTest();
        Admissions_Settings__mdt callistaFeewaiverMaintenanceConfig = (Admissions_Settings__mdt)JSON.deserialize(
            '{' +
                '"DeveloperName": "'+PaymentUtils.CALLISTA_FEE_WAIVER_MAINTENANCE_CONFIG+'",' +
                '"Status__c": "Online",' +
                '"Messages__c": "{\\"feeWaiverMessaging\\": \\"<b>PLEASE BE ADVISED:</b> The fee waiver code payment option is temporarily unavailable due to system maintenance.<br>If you wish to use the Fee Waiver Code, please save your application and return to submit it once maintenance is complete.\\"}",' +
                '"Configs__c": "{\\"myAppPaymentOptions\\": [{ \\"label\\": \\"Credit Card\\", \\"value\\": \\"Credit Card\\", \\"isDisabled\\": false }, { \\"label\\": \\"Convera (Previously Western Union)\\", \\"value\\": \\"Western Union\\", \\"isDisabled\\": false }, { \\"label\\": \\"Application Processing Fee Waiver Code\\", \\"value\\": \\"Application Fee Waiver Code\\", \\"isDisabled\\": true }]}"' +
            '}',
            Admissions_Settings__mdt.class
        );
        // Set the config as system is up
        PaymentUtils.admissionsMaintenanceMDT = callistaFeewaiverMaintenanceConfig;
        System.runAs(applicant) {
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
            mapResults = AppDeclarationFormCC.validateAndSubmitApplication(appRecord.Id);
            // THEN the application should be submittedwith no errors
            errors = (List<Map<String, Object>>) mapResults.get(AppDeclarationFormCC.FIELD_ERRORS);
            // NO Fee waiver error messages should appear as Callista is Online
            Assert.isNull(errors, 'AppDeclarationFormCC_Test::test_validateAndSubmitApplicationCallistaOnline: No submission Errors');
            Application__c appResult = [SELECT id, Fee_Waiver_Code__c,Status__C FROM Application__C WHERE id=: appRecord.Id];
            Assert.areEqual('Submission on Hold (Duplicate Contact)', appResult.Status__c, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: Submitted');
            // Fee waiver code should have been set as 123, as a Mock response from HTTP callout, in the PaymentUtils validateFeeWaiverCodeEntry method
            Assert.areEqual('123', appResult.Fee_Waiver_Code__c, 'Fee waiver is not NOT populated, Callista is Online, it should have populated.');
        }
        Test.stopTest();
        Application__c appResult = [SELECT id, Fee_Waiver_Code__c,Status__C FROM Application__C WHERE id=: appRecord.Id];
        Assert.areEqual('Sent for Submission', appResult.Status__c, 'Application failed to submit even though Callista is online');
    }
    /*
    * Testing Valdiation and Submission of Application - negative scenario
    */    
    @isTest
    static void test_validateAndSubmitApplicationWithErrors()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();         
        contactRecord = [SELECT id FROM CONTACT WHERE id=: applicant.ContactId];
        contactRecord.Birthdate = Date.today().addYears(-10);
        contactRecord.Residency_Status__c = 'INT-TEP';
        update contactRecord;

        //create a new draft application        
        Application__c appRecord = StudFirst_TestHelper.createApplication(contactRecord);        
        appRecord.Status__c = 'Draft';
        appRecord.Type_of_Study__c = 'Coursework';
        appRecord.Is_Sponsored__c = true;
        appRecord.Sponsor_Name__c = null;
        appRecord.Disability_Opt_In__c = 'No';
        insert appRecord;       

        test.startTest();
        System.runAs(applicant) {
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

            Map<String, Object> mapResults = AppDeclarationFormCC.validateAndSubmitApplication(appRecord.Id);
            List<Map<String, Object>> errors = (List<Map<String, Object>>) mapResults.get(AppDeclarationFormCC.FIELD_ERRORS);
                        
            Boolean citizenshipErrors = false;
            Boolean coursePreferenceErrors = false;
            Boolean qualificationsErrors = false;
            Boolean under18Errors = false;
            Boolean sponsorshipErrors = false;
            Boolean disabilityOptInError = false;

            for(Map<String, Object> sectionError:errors)
            {
                String sectionName = (String) sectionError.get('section');

                if(AppDeclarationFormCC.FIELD_CITIZENSHIP == sectionName)
                {
                    String label = (String) sectionError.get('label');
                    if(label == 'Access and Equity')
                    {
                       disabilityOptInError = true;

                    }
                    citizenshipErrors = true;
                }
                if(AppDeclarationFormCC.FIELD_COURSE_PREFERENCE == sectionName)
                    coursePreferenceErrors = true;
                if(AppDeclarationFormCC.FIELD_QUALIFICATIONS == sectionName)
                    qualificationsErrors = true;
                if(AppDeclarationFormCC.FIELD_UNDER_18 == sectionName)
                    under18Errors = true;
                if(AppDeclarationFormCC.FIELD_SPONSORSHIP == sectionName)
                    sponsorshipErrors = true;
                if(AppDeclarationFormCC.FIELD_SPONSORSHIP == sectionName)
                    sponsorshipErrors = true;
            }
            
            System.assertEquals(true, citizenshipErrors, 'There should be citizenship errors');
            System.assertEquals(true, disabilityOptInError, 'There should be Disability opt in errors');

            //System.assertEquals(false, onlineCreditErrors, 'There should not be online credit errors');
            System.assertEquals(true, coursePreferenceErrors, 'There should be course preference errors');
            System.assertEquals(true, qualificationsErrors, 'There should be qualifications/work exp errors');
            //Change to fix the Domestic issue
            System.assertEquals(false, under18Errors, 'There should be under 18 errors');
            System.assertEquals(true, sponsorshipErrors, 'There should be sponsorship errors');
                                   
            
            //System.assertEquals(null, errors, 'AppDeclarationFormCC_Test::test_validateAndSubmitApplicationAllErrors: No submission Errors');
            
            System.assertEquals('Draft', appRecord.Status__c, 'AppDeclarationFormCC_Test::test_validateAndSubmitApplicationAllErrors: Submitted');
        }
        test.stopTest();
    }
    /*
    * Testing Submission of Application - Acceptance of Declaration
    */      
    @isTest
    static void test_acceptDeclarationForm() {
        //create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();
        System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');

        //create a new draft application
        Application__c appRecord = createCompletedApplication(true, communityUserRec.ContactId);
        appRecord.OwnerId = communityUserRec.Id;
        update appRecord;

        test.startTest();
        if (communityUserRec != null) {
            System.runAs(communityUserRec) {
                Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

                System.assertNotEquals(null, appRecord.Id, 'No application created');
                AppDeclarationFormCC.retrieveApplication(appRecord.Id);
                AppDeclarationFormCC.acceptDeclaration(appRecord.Id);
            }
        }
        test.stopTest();
    }
    /*
    * Testing Submission of Application - Acceptance of Declaration - negative scenario
    */      
    @isTest
    static void test_acceptDeclarationFormError() {
        //create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();
        System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');

        //create a new draft application
        Application__c appRecord = createCompletedApplication(false, communityUserRec.ContactId);
        appRecord.Applicant__c = null;
        appRecord.OwnerId = communityUserRec.Id;
        update appRecord;

        test.startTest();
        if (communityUserRec != null) {
            System.runAs(communityUserRec) {
                Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

                Boolean hasError = false;
                try {
                    AppDeclarationFormCC.acceptDeclaration(appRecord.Id);
                } catch (Exception ex) {
                    hasError = true;
                }
            }
        }
        test.stopTest();
    }
    /*
    * Helper method to create application
    */      
    private static Application__c createCompletedApplication(Boolean isComplete, String contactId) {
        // Create application
        Contact c = [SELECT Id FROM Contact WHERE Id = :contactId];


        Application__c application = StudFirst_TestHelper.createApplication(c);
        application.Source_System__c = 'My.App';
        completeCitizenshipQuestions(application);
        application.Status__c = 'Draft';
        insert application;  

        // Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        Qualification__c qual2 = StudFirst_TestHelper.createQualification('Tertiary');
        insert qual2;

        Qualification__c qual3 = StudFirst_TestHelper.createQualification('Other');
        insert qual3;

        Qualification__c qual4 = StudFirst_TestHelper.createQualification('English');
        insert qual4;

        // Create Contact Qualifications
        Contact_Qualification__c cq1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        insert cq1;

        Contact_Qualification__c cq2 = StudFirst_TestHelper.createContactQualification(c, qual2, 'Tertiary Education');
        insert cq2;

        Contact_Qualification__c cq3 = StudFirst_TestHelper.createContactQualification(c, qual3, 'Other Qualification');
        insert cq3;

        // Create Work Experience
        Work_Experience__c workExperience = StudFirst_TestHelper.createWorkExperience(c);
        insert workExperience;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        //SFTG-2477 Added to pass Document check Validation
        // Contact Document 
        StudFirst_TestHelper.createContactDocument(c.id, cq2.Id);

        // Create Course Preferences
        if(isComplete){
            Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(application, c, courseOffering, course);
            insert coursePreference;
        }
        

        return application;
    }
    /*
    * Helper method for completing citizenship questions
    */      
    static void completeCitizenshipQuestions(Application__c application)
    {
        // get a valid visa type
        Schema.DescribeFieldResult fieldResult = Application__c.Visa_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry f = ple[0];
        
        application.Visa_Type__c = f.getValue();
        application.Australian_Immigration_Office_Issued__c = 'TEST';
        
        application.Visa_Number__c = '1234';
            
        application.Passport_Number__c = '1234A';
            
        application.Visa_Start_Date__c = Date.today().addYears(-1);
            
        application.Visa_End_Date__c = Date.today().addYears(2);
            
        application.Refused_entry_visa_to_any_country__c = 'No';
            
        application.Breached_visa_condition__c = 'No';
            
        application.Medical_health_prevent_visa__c = 'No';
            
        application.Protection_visa_in_any_country__c = 'No';
            
        application.Convicted_of_crime_offence__c = 'No';

        application.Access_and_Equity_Question__c = 'Yes';
    }

    /**
     * @description Tests validating application progress
     */
    @isTest 
    static void test_validateApplication() {
        //create a community user
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        // create a qualification
        Qualification__c qualTertiary = StudFirst_TestHelper.createQualification('Test Tertiary');
        insert qualTertiary;

        contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'DOM-AUS';
        contactRecord.HasDisabilities__c = 'No';
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.Birthdate = System.today().addYears(-15);
        contactRecord.Email = 'applicant@mailinator.com';
        contactRecord.MailingStreet = '1 smile street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MobilePhone = '0411111111';   
        contactRecord.Gender__c = 'M';
        contactRecord.Salutation = 'Mr';
        contactRecord.Title = 'Mr';
        insert contactRecord;

        Integer rnd = Integer.valueOf(Math.random()*9999);
        User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-AUS',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'No',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant;

        /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
         * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
            insert psa;
        }

        
        //create a new draft application
        Application__c appRecord = createCompletedApplication(true, applicant.ContactId);
        appRecord.OwnerId = applicant.Id;
        appRecord.Campus_Location__c = 'Australia';
        appRecord.Residency_Status__c = 'INTRNTNL';
        appRecord.Fee_Payment_Mode__c = 'Application Fee Waiver Code';
        appRecord.Disability_Opt_In__c =  'Yes';
        appRecord.Criminal_History_Opt_In__c  =  'Yes';
        update appRecord;

        Contact_Qualification__c cq = StudFirst_TestHelper.createContactQualification(contactRecord, qualTertiary, 'Tertiary Education');
        insert cq;
        
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
        aqp.Application__c = appRecord.Id;
        aqp.Contact_Qualification__c = cq.Id;
        insert aqp;

        Test.startTest();
        System.runAs(applicant) {
            AppDeclarationFormCC.validateApplication(appRecord.Id);            
            AppDeclarationFormCC.validateFeeWaiverCodeEntry(appRecord);
            AppDeclarationFormCC.validateFeeWaiverBeforeSubmit(appRecord);         
            AppDeclarationFormCC.under18(appRecord.Id);
        }
        Test.stopTest();
    }

   
    /*
    * Testing Submission of Application - Malaysia
    */      
    @isTest
    static void test_validateAndSubmitApplicationForMUM()
    {
        //create a community user
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'DOM-SUN';
        contactRecord.HasDisabilities__c = 'No';
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.Birthdate = System.today().addYears(-15);
        contactRecord.Personal_Email__c = 'applicant@mailinator.com';
        contactRecord.MailingStreet = '1 smile street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MobilePhone = '0411111111';
        contactRecord.Gender__c = 'M';
        contactRecord.Salutation = 'Mr';
        contactRecord.Title = 'Mr';
        insert contactRecord;

        Integer rnd = Integer.valueOf(Math.random()*9999);
        User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Asia/Kuala_Lumpur',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-SUN',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'No',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant;

        /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
         * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
            insert psa;
        }
        
        //contactRecord = [SELECT id FROM CONTACT WHERE id=: applicant.ContactId];

        //create a new draft application
        Application__c appRecord = createCompletedApplication(true, applicant.ContactId);
        appRecord.OwnerId = applicant.Id;
        appRecord.Disability_Opt_In__c =  'Yes';
        appRecord.Criminal_History_Opt_In__c  =  'Yes';
        update appRecord;

        test.startTest();
        System.runAs(applicant) {
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

            Map<String, Object> mapResults = AppDeclarationFormCC.validateAndSubmitApplication(appRecord.Id);
            List<Map<String, Object>> errors = (List<Map<String, Object>>) mapResults.get(AppDeclarationFormCC.FIELD_ERRORS);
            System.assertEquals(null, errors, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: No submission Errors');
            
            Application__c appResult = [SELECT id, Status__C FROM Application__C WHERE id=: appRecord.Id];
            // SFTLG-802 start ----------------------------------------------------------------------------------------------------
            System.assertEquals('Submission on Hold (Duplicate Contact)', appResult.Status__c, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: Submitted');
            // SFTLG-802 end ------------------------------------------------------------------------------------------------------
        }
        test.stopTest();
    }
    
    /*
    * Testing Valdiation and Submission of Application 
    */
    @isTest
    static void test_validateAndSubmitApplicationForPartnerAccountCreation()
    {
        //create a community user
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'DOM-AUS';
        contactRecord.HasDisabilities__c = 'No';
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.Birthdate = System.today().addYears(-15);
        contactRecord.Personal_Email__c = 'applicant@mailinator.com';
        contactRecord.MailingStreet = '1 smile street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MobilePhone = '0411111111';
        contactRecord.Gender__c = 'M';
        contactRecord.Salutation = 'Mr';
        contactRecord.Title = 'Mr';
        insert contactRecord;

        Integer rnd = Integer.valueOf(Math.random()*9999);
        User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-AUS',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'No',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
            insert psa;
        }
        
        //create a new draft application
        Application__c appRecord = createCompletedApplication(true, applicant.ContactId);
        appRecord.OwnerId = applicant.Id;
        appRecord.Partner_Name__c = 'Test University';
        appRecord.Type_of_Study__c = 'Study Abroad';
        update appRecord;

        test.startTest();
        Application__c applicationResult;
        System.runAs(applicant) {
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
            applicationResult = AppDeclarationFormCC.acceptDeclaration(appRecord.Id);
            AppDeclarationFormCC.updateApplicationWithStudentDeclarationAccepted(appRecord.Id);
        }
        test.stopTest();

        System.assertEquals('Test University', [SELECT Id, Agent__r.Name FROM Application__c WHERE Id = :applicationResult.Id][0].Agent__r.Name);
    }


    /**
    * @description Test for Residency_Sub_Status__c = 'INTRNTNL.O' validation bypass also verify when value not INTRNTNL.O'
    * @author Ben Greenland | 2024-08-06 
    **/
    @isTest
    static void testValidateCitizenshipSection() {
           //create a community user
           String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

           Account accountRecord = new Account(name ='AccountTest') ;
           insert accountRecord;
   
           // create a qualification
           Qualification__c qualTertiary = StudFirst_TestHelper.createQualification('Test Tertiary');
           insert qualTertiary;
   
           contactRecord = new Contact();
           contactRecord.FirstName = 'First';
           contactRecord.LastName = 'Last';
           contactRecord.AccountId = accountRecord.Id;
           contactRecord.Residency_Status__c = 'DOM-AUS';
           contactRecord.HasDisabilities__c = 'No';
           contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
           contactRecord.Birthdate = System.today().addYears(-15);
           contactRecord.Email = 'applicant@mailinator.com';
           contactRecord.MailingStreet = '1 smile street';
           contactRecord.MailingCity = 'Melbourne';
           contactRecord.MailingState = 'Victoria';
           contactRecord.MailingCountry = 'Australia';
           contactRecord.MailingPostalCode = '3000';
           contactRecord.MobilePhone = '0411111111';   
           contactRecord.Gender__c = 'M';
           contactRecord.Salutation = 'Mr';
           contactRecord.Title = 'Mr';
           insert contactRecord;
   
           Integer rnd = Integer.valueOf(Math.random()*9999);
           User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                   Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                   EmailEncodingKey = 'UTF-8',
                   LastName = 'TestingUser',
                   LanguageLocaleKey = 'en_US',
                   LocaleSidKey = 'en_GB',
                   ProfileId = profileId,
                   TimeZoneSidKey = 'Australia/Sydney',
                   UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                   ContactId = contactRecord.Id,
                   App_Salutation__c = '',
                   App_Gender__c = '',
                   App_Birthdate__c = null,
                   App_Residency_Status__c = 'DOM-AUS',
                   App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                   App_HasDisabilities__c = 'No',
                   Street = '',
                   App_Address_Type__c = 'POSTAL');
           insert applicant;
   
           User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
           System.runAs(thisUser) {
               PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
               insert psa;
           }
   
           
           //create a new draft application
           Application__c appRecord = createCompletedApplication(true, applicant.ContactId);
           appRecord.OwnerId = applicant.Id;
           appRecord.Residency_Status__c = 'International Student';
           appRecord.Campus_Location__c = 'Australia';
           appRecord.Australian_Immigration_Office_Issued__c = '';
           appRecord.Visa_Number__c = '';
           appRecord.Passport_Number__c = '';
           appRecord.Residency_Status__c = 'INTRNTNL';
           appRecord.Visa_Start_Date__c = null;
           appRecord.Visa_End_Date__c = null;
           appRecord.Student_Pass_Availability__c = null;
           appRecord.Criminal_History_Opt_In__c = 'No';
           appRecord.Refused_entry_visa_to_any_country__c = null;
           appRecord.Breached_visa_condition__c = null;
           appRecord.Medical_health_prevent_visa__c = null;
           appRecord.Protection_visa_in_any_country__c = null;
           appRecord.Convicted_of_crime_offence__c = null;
           update appRecord;

           
            Test.startTest();
            System.runAs(applicant) {
            List<String> errors = AppDeclarationFormCC.validateCitizenshipSection(appRecord);
            System.assertEquals(12, errors.size(), 'Expected 12 errors' + JSON.serializePretty(errors));
            System.assertEquals('Country of Citizenship is missing', errors[0], 'Error message should be "Country of Citizenship is missing"');
            //Test bypass for  Residency_Sub_Status__c = 'INTRNTNL.O';
            appRecord.Residency_Sub_Status__c = 'INTRNTNL.O';
            errors = AppDeclarationFormCC.validateCitizenshipSection(appRecord);
            System.assertEquals(0, errors.size(), 'Expected 0 errors' + JSON.serializePretty(errors));
            Test.stopTest();
           }
    }
	/**
	 * @description create community user and contact and applicant	
	 */
	private static User createCommunityUserAndContactNoErrors(){
		//create a community user
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'DOM-AUS';
        contactRecord.HasDisabilities__c = 'No';
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.Birthdate = System.today().addYears(-15);
        contactRecord.Personal_Email__c = 'applicant@mailinator.com';
        contactRecord.MailingStreet = '1 smile street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MobilePhone = '0411111111';
        contactRecord.Gender__c = 'M';
        contactRecord.Salutation = 'Mr';
        contactRecord.Title = 'Mr';
        insert contactRecord;

        Integer rnd = Integer.valueOf(Math.random()*9999);
        User applicant = new User( Alias = String.valueOf(rnd)+ 'usr',
                Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestingUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_GB',
                ProfileId = profileId,
                TimeZoneSidKey = 'Australia/Sydney',
                UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                ContactId = contactRecord.Id,
                App_Salutation__c = '',
                App_Gender__c = '',
                App_Birthdate__c = null,
                App_Residency_Status__c = 'DOM-AUS',
                App_Aboriginal_or_Torres_Strait_Islander__c = 'No',
                App_HasDisabilities__c = 'No',
                Street = '',
                App_Address_Type__c = 'POSTAL');
        insert applicant;

        /* EPCP-79 (22/02/2019, Stefan Scheit): the permission set is automatically assigned in UserServices.AssignPermissionSets.run()
         * EPCP-102 (18/03/2019, Stefan Scheit: re-instated as quick fix for My.App welcome emails automatically sent) */
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id, AssigneeId = applicant.Id);
            insert psa;
        }
        return applicant;
    }

    /**
     * @author      vishal gupta
     * @description Tests updating the Application_Qualification_Provided__c for Graduate Research
     *
     * GIVEN there are existing contact qualifications for Graduate Research
     * WHEN the application is submitted
     * THEN system should update the sequence number in Application_Qualification_Provided__c for Graduate Research application
     */
    @isTest 
    static void test_updateAQForGradResearch() {

        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];
        Test.startTest();
        System.runAs(applicant) {
            List<RecordType> recTypes = [SELECT Id, Name, sObjectType
            FROM        RecordType
            WHERE       sObjectType = 'Contact_Qualification__c'
            AND Name = 'Tertiary Education'
            ];

            RecordType rt = recTypes[0];
            
            Application__c app = StudFirst_TestHelper.createApplication(c.Id);
            app.Type_Of_Study__c = 'Graduate Research';
            insert app;

            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = applicant.ContactId;
            cq.RecordTypeId = rt.Id;
            
            insert cq;

            // create the apq
            Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
            aqp.Contact_Qualification__c = cq.Id;
            aqp.Application__c = app.Id;
            insert aqp;

            List<Application_Qualification_Provided__c> lstAQP = [SELECT Qualification_Type__c, Sequence_Number__c FROM Application_Qualification_Provided__c WHERE Application__c = :app.Id];
            AppDeclarationFormCC.populateApplicationQualificationSequenceNumber(lstAQP); 
            List<Application_Qualification_Provided__c> afterUpdateAQP = [SELECT Sequence_Number__c FROM Application_Qualification_Provided__c WHERE Application__c = :app.Id];
            Assert.areEqual(1, afterUpdateAQP[0].Sequence_Number__c, 'returned Sequence_Number__c');
        }
        Test.stopTest();
	} 
}