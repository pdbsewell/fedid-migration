/**
* @author Davey Yu
* @date 10-01-2025
* @group Test Class for Flows
* @description  Test Class for ACP: AU : Email Applicant : Application Submission flow
* @history     10/01/2025 - Davey Yu - Initial Creation
*
**/

@isTest(isParallel=false) // Set isParallel to false to overcome mixed DML operation exception on parallel Apex test
private class ACPEmailApplicationSubmission_FT {
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
    }

    
    /**
     * @author      Davey Yu
     * @description Tests submitting an application and application email sent
     * @revision    26/9/18 created
     *
     * GIVEN the student has applied for the my application from student portal
     * WHEN they submitted their application and hdr integration is done
     * THEN the students should received an email notification
     */
    @isTest
    static void test_ApplicationSubmissionEmail()
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
            
            System.assertEquals('Submission on Hold (Duplicate Contact)', appResult.Status__c, 'AppDeclarationFormCC_Test::test_ValidateAndSubmit: Submitted');
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
        application.Type_Of_Study__c = 'Graduate Research';
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
        Contact_Document__c contactDoc = StudFirst_TestHelper.createContactDocument(c.id, cq2.Id);

        // Create Course Preferences
        if(isComplete){
            Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(application, c, courseOffering, course);
            coursePreference.GradRes_Callista_Id__c = '1234';
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

}