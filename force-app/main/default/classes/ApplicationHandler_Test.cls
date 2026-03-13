/*
 * @description  test class for ApplicationHandler
 * @author      Ant Custodio
 * @date        JUN.19.2017   
 * @deprecated  Sibling class deprecated. Use ApplicationTriggerHandler instead 
 * @revision
 *  JUL.10.2019    Shalini Mendu   - Removed test method "populateAgentByOrgUnitCode" as part of LG-824
 *  MAY.12.2020    Shalini Mendu   - SFTD-573
 *  SEP.11.2024    Martin Cadman   - Moved to Assert class
 *  NOV.08.2024    Kai-Fan Hsieh   - DANO-347: Use mock callout for document submission
 * 
 * NG TODO: this class requires major changes. Most test methods create their own setup data, with
 * loose / zero criteria against SOQL filter when running asserts, therefore fails when adding new
 * records within the test setup
 * 
 */
@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION : DML operations aren't permitted on this type of object: User
public with sharing class ApplicationHandler_Test {

    @TestSetup
    static void setup() {

        Feature_Switch__c fs = new Feature_Switch__c();
        fs.Align_Application_Owner__c = true;
        fs.Align_ACP_Owner__c = true;
        insert fs;

        Country_Attribute__c country = new Country_Attribute__c(Name = 'INDIA', Callista_Code__c = '7103', Country__c = 'INDIA');
        insert country;

        country = new Country_Attribute__c(Name = 'AUSTRALIA',
                                           Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                           Country__c = 'Australia');
        insert country;  
        
        Account agency = new Account();
        agency.Name = 'Kangaroo Education';
        agency.Callista_Org_Unit_Code__c = 'KANGA-ED';
        agency.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId();
        agency.Monash_AM_Campus__c = 'Australia';
        agency.City__c = 'Bangalore';
        agency.Post_Code__c = '400028';
        agency.Email__c = 'Kangaroo@Education.com';
        agency.Country_Lookup__c = country.id;
        agency.Status__c = 'Appointed';
        insert agency;
    }
    
    /**
    * @author       Ant Custodio
    * @date         19.Jun.2017
    * @description  try and insert 2 draft applications
    * @revision
    */
    @isTest
    static void test_InsertingTwoDrafts() {

        //create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();
        System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;
        //only run if there is a Domestic Applicant Profile User
        System.assertEquals(profileId, communityUserRec.ProfileId);

        Test.startTest();

        System.runAs(communityUserRec) {
            //create a new draft application
            Application__c appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
            appRecord.Status__c = 'Draft';
            appRecord.Agent_Org_Unit_Code__c = 'KANGA-ED';
            appRecord.Source_System__c = 'my.app';
            insert appRecord;
            Assert.isNotNull(appRecord.Id, 'No application created');
            
            // Test added to ensure the application is correctly linked to an agency
            appRecord = [select id, agent__r.Callista_Org_Unit_Code__c, Agent_Org_Unit_Code__c from application__c where id = :appRecord.id limit 1];
            Assert.areNotEqual(appRecord.Agent_Org_Unit_Code__c, appRecord.agent__r.Callista_Org_Unit_Code__c, 'Application has not been linked to the correct Agency account');
            
            Boolean exceptionCaught = false;
            try {
                Application__c appRecord2 = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
                appRecord2.Status__c = 'Draft';
                
                insert appRecord2;
            } catch (Exception ex) {
                exceptionCaught = true;
            }
            Assert.isTrue(exceptionCaught, 'Another draft application has been inserted');
        }
        
        Test.stopTest();
    }
    
    /*
    * @author       Shalini Mendu
    * @date         10.Jul.2019
    * @description  Test method for validating data
    * @revision
    */
    @isTest
    static void test_PositiveValidateDataFromExternalApps() {
        Country_Attribute__c indiaCtry = [select id from country_attribute__c where name = 'INDIA'];
        
        Contact con = StudFirst_TestHelper.createInternationalApplicant();
        insert con;
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;
        // Create Contact Qualifications
        Contact_Qualification__c contactQualification1 = StudFirst_TestHelper.createContactQualification(con, qual1, 'Secondary Education');
        insert contactQualification1;

        Application__c app = StudFirst_TestHelper.createInternationalApplication(con, indiaCtry);
        insert app;

        Calendar__c cal = new Calendar__c(name = 'Cal 1', Sequence_Number__c = 8789, Sequence_Number_Year__c = 1998);
        insert cal;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;
        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        insert off;
        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, con, off, crs);
        insert acp;

        app.Status__c = 'Data Validation Ready';
        app.Source_System__c = 'AgentPortal';
        update app;
        Application__c retApp = [Select Status__c from Application__c where id = :app.Id];
        // SFTLG-802 start ----------------------------------------------------------------------------------------------------
        //System.assertEquals('Sent for Submission', retApp.Status__c);
        Assert.areEqual('Submission on Hold (Duplicate Contact)', retApp.Status__c);
        // SFTLG-802 end ------------------------------------------------------------------------------------------------------
    }

    /*
     * @author       Shalini Mendu
     * @date         10.Jul.2019
     * @description  Test method for validating data in a negative scenario
     * @revision
     */
    @isTest
    static void test_NegativeValidateDataFromExternalApps() {

        Country_Attribute__c indiaCtry = [select id from country_attribute__c where name = 'INDIA'];

        Contact con = StudFirst_TestHelper.createInternationalApplicant();
        insert con;

        Application__c app = StudFirst_TestHelper.createInternationalApplication(con, indiaCtry);
        insert app;

        Calendar__c cal = new Calendar__c(name = 'Cal 1', Sequence_Number__c = 8789, Sequence_Number_Year__c = 1998);
        insert cal;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;
        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        insert off;

        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, con, off, crs);
        insert acp;

        app.Status__c = 'Data Validation Ready';
        app.Source_System__c = 'AgentPortal';
        app.Submission_Progress__c = 'Study Preferences';
        update app;
        Application__c retApp = [Select Status__c, Submission_Progress__c from Application__c where id = :app.Id];
        Assert.areEqual('Failed Data validation', retApp.Status__c);
        //SFTG-2063 Check only if Partner's send to student sets the Application submission_progress to Declaration
        Assert.areNotEqual('Declaration', retApp.Submission_Progress__c, 'Submission Progress is reset to Declaration for non-partners');

    }
    
    /*
     * @author       Shalini Mendu
     * @date         10.Jul.2019
     * @description  Test method for factory testing
     * @revision
     */
    @isTest
    static void test_DataValidatorFactory() {
        IDataValidator iData = DataValidatorFactory.getValidator('AgentPortal');
        System.assertEquals(true, (iData != null));
        IDataValidator iData2 = DataValidatorFactory.getValidator('Abc');
        Assert.isNull(iData2);
    }

    /*
     * @description  Test method waiver code
     */
    @isTest
    public static void test_RedeemWaiverCode() {
        Contact con = new Contact();
        con.Person_Id_unique__c = 'IdAA';
        con.LastName = 'LastnameAA';
        con.FirstName = 'FirstnameAA';
        con.Previous_Monash_ID__c = '1000234567';
        insert con;


        MIX_API_Config__c mc = new MIX_API_Config__c();
        mc.Base_Url__c = 'https://mix.dev';
        mc.Client_Id__c = 'abcdef';
        mc.Client_Secret__c = 'ghijkl';
        insert mc;

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            Application__c application = new Application__c();
            application.Applicant__c = con.Id;
            application.Passport_Number__c = 'A1234567';
            application.Campus_Location__c = null;
            application.Visa_Type__c = null;
            application.Australian_Immigration_Office_Issued__c = null;
            application.Visa_Number__c = null;
            application.Passport_Number__c = null;
            application.Visa_Start_Date__c = null;
            application.Visa_End_Date__c = null;
            application.Refused_entry_visa_to_any_country__c = null;
            application.Breached_visa_condition__c = null;
            application.Medical_health_prevent_visa__c = null;
            application.Protection_visa_in_any_country__c = null;
            application.Convicted_of_crime_offence__c = null;
            application.Status__c = 'Sent for Submission';
            application.From_Portal__c = true;
            application.Fee_Amount__c = 100;
            application.Fee_Payment_Mode__c = 'Application Fee Waiver Code';
            application.Fee_Waiver_Code__c = '1234567SD';
            application.Fee_Payment__c = false;
            application.Residency_Status__c = 'INTRNTNL';
            application.Source_System__c = 'AgentPortal';
            insert application;

            application.Status__c = 'Submitted';
            application.Callista_Application_Id__c = '123456';
            application.Callista_Applicant_Id__c = '2343434';
            update application;

            Test.startTest();
            ObdRedeemWaiverCode.redeemCode(application.Id);
            Test.stopTest();
            Assert.areEqual('1234567SD', [
                    SELECT Fee_Waiver_Redeemed__c
                    FROM APPLICATION__c
                    WHERE ID = :application.Id
            ].Fee_Waiver_Redeemed__c);

        }

    }

    /*
     * @description  Test document submission to Callista
     */
    @isTest
    private static void  testDocumentSubmission()
    {
        // Given: An application with a contact document
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT Id FROM Contact WHERE Id =: applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c);
        app.Status__c = 'Sent for Submission';
        insert app;

        createTestDocument(true, app , c);
        Test.startTest();
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        // When: The application is submitted
     	app.Status__c = 'Submitted';
        update app;
        Test.stopTest();
        // Then: The document is sent to Callista
        List<Contact_Document__c> contactDocuments = [
            SELECT Id, Application__c
            FROM Contact_Document__c
            WHERE File_Upload_Successful__c = TRUE
        ];
        Assert.areEqual(
            1, contactDocuments.size(),
            'Expected 1 contact document to be sent to Callista'
        );
    }
    
    static ContentDocument createTestDocument(Boolean allAccess, Application__c app, Contact c)
    {
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
                Title='Test File',
                PathOnClient ='/Test File.jpg',
                VersionData = bodyBlob,
                origin = 'H'
        );


        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id =: cv.Id];

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId
        FROM ContentDocument
        WHERE id=:cv.ContentDocumentId];
        ContentDocument file = documents[0];

        if(allAccess)
        {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = app.Id;
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'v';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;

        }
        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(c.Id);
        contactDocu.Document_Type__c = 'PARENT_GUARDIAN';
        contactDocu.Submitted__c = true;
        insert contactDocu;


        ContentDocumentLink cdLink1 = new ContentDocumentLink();
        cdLink1.LinkedEntityId = contactDocu.Id;
        cdLink1.ContentDocumentId = cv.ContentDocumentId;
        cdLink1.ShareType = 'v';
        cdLink1.Visibility = 'AllUsers';
        insert cdLink1;

        return file;
    }

    /*
     * @description Test 
     */
    @isTest
    static void test_SendLOI() {
        Country_Attribute__c indiaCtry = [select id from country_attribute__c where name = 'INDIA'];

        Contact con = StudFirst_TestHelper.createInternationalApplicant();
        insert con;

        Application__c app = StudFirst_TestHelper.createInternationalApplication(con, indiaCtry);
        app.Callista_Applicant_Id__c = '0030k000001tbfEAAQ';
        app.English_Entry_Mode__c ='Country of secondary schooling / graduation';
        app.Meets_Minimum_English__c = 'Yes';
        insert app;

        Course__c crs = StudFirst_TestHelper.createCourse();
        insert crs;
        Course_Offering__c off = StudFirst_TestHelper.createCourseOffering(crs);
        insert off;

        Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(app, con, off, crs);
        insert acp;

        app.Meets_Minimum_English__c = 'No';
        update app;
    }

    /*
     * @description Test a campus change changes the location
     */
    @isTest
    public static void test_UpdateCampusInformation(){
        Contact con = StudFirst_TestHelper.createInternationalApplicant();
        insert con;
        Application__c app = StudFirst_TestHelper.createApplication(con);
        app.Campus__c = 'CLAYTON';
        insert app;

        List<Application__c> applications = [SELECT Campus_Location__c FROM Application__c WHERE Id = :app.Id];
        Assert.isTrue(applications.size() > 0, 'No applications returned');
        Assert.areEqual('Australia', applications[0].Campus_Location__c, 'Unable to convert Campus to Location');

    }

    /*
     * @description Test a deletion
     */
    @isTest
    public static void test_ValidateDelete() {                
        Test.startTest();
            // CREATE A PARTNER USER
            User testPartnerUser = StudFirst_TestHelper.createContactAndPartnerPortalUser();
            Account testAccount = [SELECT id FROM Account WHERE Name like '%TestAccount%'];
            Contact testContact = new Contact(FirstName = 'TestApplicantFirstName', LastName = 'TestApplicantLastName', AccountId = testAccount.Id, Email = 'TestApplicantEmail@testemail.com');
            Partner_Agreement__c pa = new Partner_Agreement__c(Quota__C=10, Expiry_date__c= Date.today(), Remaining_quota__C=0,Partner_Account__c=testAccount.Id);
            insert pa; 
            
            Application__c app = null;
            // run as partner user
            System.runAs(testPartnerUser) { 
                // CREATE AN APPLICATION
                Map<String, Object> resultsMap = PartnerApplicationService.createApplication(JSON.serialize(testContact),
                                                                        testAccount.Id,
                                                                        'Exchange',
                                                                        '1', 
                                                                        'Australia',
                                                                        'DOM-AUS');
                app = (Application__c) JSON.deserialize('' + resultsMap.get('APPLICATION'), Application__c.class);
                delete app;
            }
        Test.stopTest();
        List<Application__c> applications = [SELECT id FROM Application__c WHERE id = :app.id];
        Assert.isTrue(applications.size() == 0, 'Application NOT deleted in spite of being Partner Controlled/Draft');
    }

   /*
    * @author       Shalini Mendu
    * @date         28.MAR.2023
    * @description  Test method for verifying affiliation rules on applicant contact- create
    * @revision     03.MAY.2023 - Use Toggle to allow Affiliations for Agentportal applications
    */
    @isTest
    public static void test_AffiliationonPartnerContact() {                
        Test.startTest();
            // CREATE A PARTNER USER
            User testPartnerUser = StudFirst_TestHelper.createContactAndPartnerPortalUser();
            Account testAccount = [SELECT id FROM Account WHERE Name like '%TestAccount%'];
            Contact testContact = new Contact(FirstName = 'TestApplicantFirstName', LastName = 'TestApplicantLastName', AccountId = testAccount.Id, Email = 'TestApplicantEmail@testemail.com');
            Partner_Agreement__c pa = new Partner_Agreement__c(Quota__C=10, Expiry_date__c= Date.today(), Remaining_quota__C=0,Partner_Account__c=testAccount.Id);
            insert pa; 
            Application__c app = null;
            // run as partner user
            System.runAs(testPartnerUser) { 
                // CREATE AN APPLICATION
                Map<String, Object> resultsMap = PartnerApplicationService.createApplication(JSON.serialize(testContact),
                                                                        testAccount.Id,
                                                                        'Exchange',
                                                                        '1', 
                                                                        'Australia',
                                                                        'DOM-AUS');
                app = (Application__c) JSON.deserialize('' + resultsMap.get('APPLICATION'), Application__c.class);
            }
            System.runAs(testPartnerUser) { 
            Contact con =  ([SELECT Id FROM Contact WHERE FirstName = :testContact.FirstName AND LastName = :testContact.LastName]);
            con.Email ='abc@def.com';
            update con;
            Assert.isNotNUll( con,'ERROR: Applicant contact record should  be accessible to partner user');
        }
        Test.stopTest();
    }
    
    /*
    * @author       Shalini Mendu
    * @date         28.MAR.2023
    * @description  Test method for verifying affiliation rules on applicant contact
    * @revision
    */
    @isTest
    public static void test_AffiliationonPartnerContactUpdate() {                
        Test.startTest();
            // CREATE A PARTNER USER
            User testPartnerUser = StudFirst_TestHelper.createContactAndPartnerPortalUser();
            Account testAccount = [SELECT id FROM Account WHERE Name like '%TestAccount%'];
            Contact testContact = new Contact(FirstName = 'TestApplicantFirstName', LastName = 'TestApplicantLastName', AccountId = testAccount.Id, Email = 'TestApplicantEmail@testemail.com');
            Partner_Agreement__c pa = new Partner_Agreement__c(Quota__C=10, Expiry_date__c= Date.today(), Remaining_quota__C=0,Partner_Account__c=testAccount.Id);
            insert pa; 
            Application__c app = null;
            // run as partner user
            System.runAs(testPartnerUser) { 
                // CREATE AN APPLICATION
                Map<String, Object> resultsMap = PartnerApplicationService.createApplication(JSON.serialize(testContact),
                                                                        testAccount.Id,
                                                                        'Exchange',
                                                                        '1', 
                                                                        'Australia',
                                                                        'DOM-AUS');
                app = (Application__c) JSON.deserialize('' + resultsMap.get('APPLICATION'), Application__c.class);
            }
            app.Status__c = 'Submitted';
            update app;
        System.runAs(testPartnerUser) { 
            Contact con =  ([SELECT Id FROM Contact WHERE FirstName = :testContact.FirstName AND LastName = :testContact.LastName]);
            Assert.isNotNull( con,'ERROR: Applicant contact record should  be accessible to partner user');
        }
        Test.stopTest();
       
    }
 
    /*
    * @author       Shalini Mendu
    * @date         03.MAY.2023
    * @description  Test method for Agent portal does not create Affiliations on toggle on of AgentPortal_Affiliation__c field
    * @revision
    */
    @isTest
    static void test_AffiliationsNotCreatedForAgentPortal() {
        Environment_Settings__c environmentSettings = new Environment_Settings__c();
        environmentSettings.AgentPortal_Affiliation__c = false;
        insert environmentSettings;
        Contact testContact = StudFirst_TestHelper.createApplicant();
        testContact.Person_ID_unique__c = '1111111';
        insert testContact;

        //Create agency record
        Account testAgency = new Account(Name = 'TestAgency', Callista_Org_Unit_Code__c = 'TESTAU');
        insert testAgency;

        //Create payment record
        Payment_Request__c testPaymentRequest = new Payment_Request__c(Account__c = testAgency.Id, Invoice_No__c = '12345678');
        insert testPaymentRequest;

        //Create course record
        Course__c testCourse = new Course__c();
        testCourse.Name = 'CrsNme-1';
        testCourse.Course_Description__c = 'CourseDescription-1';
        testCourse.Course_Code__c = 'CourseCode-1';
        testCourse.Version__c = '1';
        testCourse.Faculty_Description__c = 'FacultyDescription-1';
        testCourse.Sub_Level__c = '41';
        testCourse.Title__c = 'Course Title';
        testCourse.Managing_Faculty__c = 'Faculty of Engineering';
        testCourse.Faculty_Code__c = 'FacCode';
        testCourse.Type__c = 'Course-All';
        insert testCourse;
        Test.startTest();
        //Create application
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
		//testApplication.Agent_Org_Unit_Code__c = 'TESTAU'; // This should now be populated when an agency is linked and the field is empty
        testApplication.Agent__c = testAgency.Id;
        testApplication.Applicant__c = testContact.Id;
        testApplication.Source_System__c = 'AgentPortal';
        insert testApplication;
        Test.stopTest();
        
        // This also tests that the org unit code is populated when the agency is directly linked
        Assert.isTrue( [select id from Affiliation__c where Account__r.Callista_Org_Unit_Code__c= 'TESTAU'].size()==0, 'Agentportal should not create affiliations');
    }
    
    /**
     * @description Verify Affiliation inserts/updates on Application Agent update
     */
    @isTest
    public static void shouldUpsertAffiliationsOnApplicationUpdate() {

      
        // STEP 1 - Create Agent Onboarding Settings
        insert AgentPortalTestDataBuilder.factory.createAgentOnboardingSettings();
 
        // STEP 2 - Create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
 
        // STEP 3 - create a test Application as the portal user
       new AgentPortalTestDataBuilder.Application().withAgent(portalUser).build();
          
        // GIVEN - There is an Application linked to  'TSTAG' agency
        Application__C app = [SELECT Id, Agent__c, Agent__r.Callista_Org_Unit_Code__c 
                            FROM Application__C 
                            WHERE  Source_System__c = 'AgentPortal' 
                            AND Agent__c = :portalUser.acc.Id];

        //Query 'KANGA-ED' Org unit code account                     
        Account kangaAccount = [SELECT Id FROM Account WHERE Callista_Org_Unit_Code__c= 'KANGA-ED'];

        // WHEN - The Application is updated to link to a new agency 'KANGA-ED'
        Test.startTest();

        //Update Agent fields on the Application__c
        app.Agent__C = kangaAccount.Id;
        app.Agent_Org_Unit_Code__c = 'KANGA-ED';
        update app;

        Test.stopTest();

        // THEN

        // map out affiliations by agency
        Map<Id, Affiliation__c> affByAccountId = new Map<Id, Affiliation__c>();
        for(Affiliation__c iAff : [SELECT Share_Contact_to_Account_Role__c, Account__c
                                    FROM Affiliation__c 
                                    WHERE Account__c = :portalUser.acc.Id
                                    OR Account__c = :kangaAccount.Id])
        {
            affByAccountId.put(iAff.Account__c, iAff);
        }

        Assert.areEqual('Read', affByAccountId.get(kangaAccount.Id).Share_Contact_to_Account_Role__c, 'The affiliation must have No Sharing access');
        Assert.areEqual('No Sharing', affByAccountId.get(portalUser.acc.Id).Share_Contact_to_Account_Role__c, 'The affiliation must have No Sharing access');
    }

   /**
    * @description To verify OES user can create Affiliations on Application creation 
    */
    @isTest
    public static void test_AffiliationonCreationForOES() {     
         //GIVEN
        Environment_Settings__c environmentSettings = new Environment_Settings__c();
        environmentSettings.AgentPortal_Affiliation__c = true;
        insert environmentSettings;           
        // STEP 1 - Create a test Agent Portal User
        AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
        
        User userx = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        // STEP 2 - Assign OES permissions to make it OES user
      
        System.runAs(userx)
        {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OES_Permission_Set'];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=portalUser.testUser.Id, PermissionSetId=ps.Id);
            insert psa;
        }

        //WHEN
        Test.startTest();
        // STEP 3 - Create Application as a OES user
        System.runAs(portalUser.testUser)
        {
            Contact testContact =  new AgentPortalTestDataFactory().createApplicantContact();
            insert testContact;
            Application__c app =  new AgentPortalTestDataFactory().createApplication(testContact.Id);
            app.Agent_Org_Unit_Code__c = portalUser.acc.Callista_Org_Unit_Code__c;
            app.Agent__c = portalUser.acc.Id;
            app.Source_System__c =  'OES';
            insert app;
        }
        Test.stopTest();
   
        //THEN
        Assert.isTrue( [select id from Affiliation__c].size()>0, 'OES user should create affiliations');
       
    }
}