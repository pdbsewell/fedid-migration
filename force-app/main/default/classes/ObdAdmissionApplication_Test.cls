/**
 * @author Trent De Laney
 * @date 7 Mar 2019 at 10:45:38 am
 * @group Test Class
 * @description Used to test the outbound calls to Callista for the submission of an application
 * @revision
 * 08/02/2022 - Vinothraja - SFTG-2365 Added code to bulkify logging during & after callouts
 * 08/03/2023  SMendu: Testing for Workexperience on the payload 
 * 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4

 */
@IsTest(IsParallel=false)//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object:
public class ObdAdmissionApplication_Test {

    /**
    * @author Trent De Laney
    * @description Setup of the test method for the outbound calls
    * @date 7 Mar 2019 at 10:46:12 am
    */
    @TestSetup
    static void setup() {
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

        Contact applicant = StudFirst_TestHelper.createApplicant();
        applicant.FirstName = 'Callista';
        applicant.LastName = 'Outbound';
        applicant.Personal_Email__c = 'test@test.com';
        insert applicant;
        Application__c application = StudFirst_TestHelper.createApplication(applicant);
        //Added in fee waiver code to increase covered
        application.Fee_Waiver_Code__c = 'somecode';
        application.Fee_Payment_Mode__c = 'Application Fee Waiver Code';
        insert application;

        // Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        Qualification__c qual2 = StudFirst_TestHelper.createQualification('Tertiary');
        insert qual2;

        Qualification__c qual3 = StudFirst_TestHelper.createQualification('Other');
        insert qual3;

        Qualification__c qual4 = StudFirst_TestHelper.createQualification('English');
        qual4.Sub_score_Type__c = 'Essay Rating';
        insert qual4;

        // Create Contact Qualifications
        Contact_Qualification__c contactQualification1 = StudFirst_TestHelper.createContactQualification(applicant, qual1, 'Secondary Education');
        insert contactQualification1;

        Contact_Qualification__c contactQualification2 = StudFirst_TestHelper.createContactQualification(applicant, qual2, 'Tertiary Education');
        insert contactQualification2;

        Contact_Qualification__c contactQualification3 = StudFirst_TestHelper.createContactQualification(applicant, qual3, 'Other Qualification');
        insert contactQualification3;

        Contact_Qualification__c contactQualification4 = StudFirst_TestHelper.createContactQualification(applicant, qual4, 'English Test');
        insert contactQualification4;

        // Create Work Experience
        Work_Experience__c workExperience = StudFirst_TestHelper.createWorkExperience(applicant);
        insert workExperience;

        // Create Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        // Creare Course Offering
        Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
        insert courseOffering;

        // Create Course Preferences
        Application_Course_Preference__c coursePreference = StudFirst_TestHelper.createCoursePreferences(application, applicant, courseOffering, course);


        //DONT CHANGE THIS COURSE CODE UNLESS THE MOCK IS ALSO UPDATED
        coursePreference.Course_Code__c = '4102';
        coursePreference.Preference_Number__c = '1';
        insert coursePreference;

        Callista_Sub_Score_Type__c testSubScore = new Callista_Sub_Score_Type__c();
        testSubScore.Name = 'Essay Rating';
        testSubScore.Available_in_Portal__c = true;
        testSubScore.Code__c = 'ESS-RATING';
        insert testSubScore;

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
        aUO.Unit_Mode__c='ON';
        aUO.Offered_Ind__c=TRUE;
        aUO.Active_Ind__c=TRUE ;
        aUO.SSF_Avail_Ind__c=TRUE;
        aUO.Location__c ='CLAYTON';
        aUO.Start_Date__c = Date.today();
        insert aUO;


        Unit_preference__c up = new Unit_preference__c(  Unit_Offering__c = aUO.Id,Application_Course_Preference__c = coursePreference.Id);
        insert up;

        // insert test partner person id
        Environment_Settings__c testSettings = new Environment_Settings__c();
        testSettings.PARTNR_Agent_Person_Id__c = '0123456789';
        insert testSettings;
    }

    /**
    * @author Trent De Laney
    * @description Tests the blank string replacement for submission of nulls through the Callista submit web service
    * @date 7 Mar 2019 at 10:46:49 am
    */
    @IsTest
    static void replaceBlank() {
        String result = replaceBlankWithNull('');
        System.assertEquals(result, 'null');
    }

    /**
    * @author Trent De Laney
    * @description Tests the send application method to Callista
    * @date 7 Mar 2019 at 10:47:23 am
    */
    @IsTest
    static void sendApplication() {
        Application__c app = createCompletedApplication();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        ObdAdmissionApplication.sendApplication(app.Id);

        Test.stopTest();
        //Check for WorkExperience to appear on the Request payload
        Application__c resultApplication = [SELECT Id, API_Request_Message__c FROM Application__c WHERE Id = :app.Id];
        ObdAdmissionApplicationRequest obreq =  (ObdAdmissionApplicationRequest)System.JSON.deserialize(resultApplication.API_Request_Message__c, ObdAdmissionApplicationRequest.class);
        System.assertEquals(1, obreq.admissionApplication.applications[0].applicant.workExperience.size());
     
        Application__c application = StudFirst_SubmitApplicationHelper.getApplicationById(app.Id);
        //System.assertEquals(application.Status__c == 'Submitted', true);
        //System.assertEquals(application.Callista_Application_Id__c != null, true);
        //System.assertEquals(application.Callista_Applicant_Id__c != null, true);
         String displayMsg1 = ObdAdmissionApplication.hasSubmitApplicationBtnAccess([SELECT Callista_Applicant_Id__c, Callista_Application_Id__c,STATUS__c FROM Application__C where id=:application.Id].Id);
        System.assertEquals('The application is in Draft status.Please change the status to "Sent for submission" and submit', displayMsg1, 'check Application status');

        application.Status__c = 'Submitted';
        update application;
        String displayMsg = ObdAdmissionApplication.hasSubmitApplicationBtnAccess([SELECT Callista_Applicant_Id__c, Callista_Application_Id__c,STATUS__c FROM Application__C where id=:application.Id].Id);
        System.assertEquals('The application has already been submitted successfully to Callista, it cannot be re-submitted', displayMsg, 'check Application status');

        application.Status__c = 'Review';
        update application;
        String displayMsg2 = ObdAdmissionApplication.hasSubmitApplicationBtnAccess([SELECT Callista_Applicant_Id__c, Callista_Application_Id__c,STATUS__c FROM Application__C where id=:application.Id].Id);
        System.assertEquals('The application is in Review status.Please change the status to "Sent for submission" and submit', displayMsg2, 'check Application status');

    }

    @IsTest
    public static void sendInternationalApplicationOES(){
        Application__c application = createCompletedApplication();
        System.assert(application != null, 'Unable to get application for test case');
        application.Residency_Status__c = 'INTRNTNL';
        application.Source_System__c = 'OES';
        update application;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        ObdAdmissionApplication.sendApplication(application.Id);

        Test.stopTest();
    }

    @IsTest
    public static void sendInternationalApplicationPartner(){
        Application__c application = createCompletedApplication();
        System.assert(application != null, 'Unable to get application for test case');
        application.Type_of_Study__c = 'Exchange';
        application.Source_System__c = 'Partner';
        update application;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        ObdAdmissionApplication.sendApplication(application.Id);
        Test.stopTest();

         // then - check that the application's API Response Message contains the expected agent person id
         Application__c resultApplication = [SELECT Id, API_Request_Message__c FROM Application__c WHERE Id = :application.Id];
         System.assertEquals(true, resultApplication.API_Request_Message__c.contains(Constants.PARTNR));
    }

    /**
     * @description Tests my.app study abroad application if it has the right agent person id on submission
     */
    @isTest
    public static void sendInternationalApplicationPartnerStudyAbroad(){
        // given
        Application__c application = createCompletedApplication();
        System.assert(application != null, 'Unable to get application for test case');
        application.Type_of_Study__c = 'Study Abroad';
        application.Source_System__c = 'my.app';
        update application;
        // when
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        ObdAdmissionApplication.sendApplication(application.Id);
        Test.stopTest();
        // then - check that the application's API Response Message contains the expected agent person id
        Application__c resultApplication = [SELECT Id, API_Request_Message__c FROM Application__c WHERE Id = :application.Id];
        System.assertEquals(true, resultApplication.API_Request_Message__c.contains(Constants.PARTNR));
    }
    
    /**
    * @author Trent De Laney
    * @description Test for document submission to Callista. Ran in a seperate test method due to DML constraints.
    * @date 7 Mar 2019 at 12:08:36 pm
    */
    @IsTest
    static void document(){

        Application__c applicationId = createCompletedApplication();

        ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
        );
        insert contentVersionInsert;

        //Get Content Document
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument LIMIT 1];

        System.assertEquals(docs.size(), 1);

        ContentDocumentLink cdLink = new ContentDocumentLink();
        cdLink.ContentDocumentId = docs[0].Id;
        cdLink.LinkedEntityId = applicationId.Id;
        cdLink.ShareType = 'v';
        cdLink.Visibility = 'AllUsers';
        insert cdLink;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        SubmitRelatedContactDocuments(applicationId.Id, '111111');
        Test.stopTest();
    }

    /**
    * @author Trent De Laney
    * @description Tests a bad application being returned from Callista. Ensures that the status is chaged to Review for business processing
    * @date 7 Mar 2019 at 12:09:00 pm
    */
    @IsTest
    static void sendBadApplication()
    {
        Application__c application = createCompletedApplication();
        System.assert(application != null, 'Unable to get application for bas submission');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseError());
        ObdAdmissionApplication.send(application.Id);

        Test.stopTest();
        Application__c returnApplication = StudFirst_SubmitApplicationHelper.getApplicationById(application.Id);
        //System.assertEquals(application.Status__c == 'Review', true);
    }

    /**
    * @author Trent De Laney
    * @description Revised helper class to select from the Test Setup methods.
    * @date 7 Mar 2019 at 12:09:43 pm
    * @return String applicationId
    */
    private static Application__c createCompletedApplication() {

        Contact c = [
                SELECT Id
                FROM Contact
                WHERE FirstName = 'Callista' AND LastName = 'Outbound'
        ];

        List<Application__c> apps = [
                SELECT Id
                FROM Application__c
                WHERE Applicant__c = :c.Id
                LIMIT 1
        ];

        if (apps.size() > 0) {
            return apps[0];
        }
        return null;
    }
    
    
    /**
     * Moved from SendApplicationQueueable class
     **/
    public static void SubmitRelatedContactDocuments(Id appId, String callApplicantId)
    {
        // 1. find the CONTENTS linked to this APPLICATION
        List<ContentDocumentLink> cdAppLinks = [SELECT Id,
                LinkedEntityId,
                ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId=: appId];
        System.Debug('ObdAdmissionApplication_Test:: CD App Links:' + cdAppLinks);

        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink appLink:cdAppLinks)
        {
            // for each contentdocument
            contentDocIds.add(appLink.ContentDocumentId);
        }

        // 2. find all LINKS to this content
        if(contentDocIds.size() == 0)
        {
            // EARLY OUT 1, no new docs attached to application
            return;
        }


        List<ContentDocumentLink> cdDocLinks = [SELECT Id, LinkedEntityId, ContentDocumentId
        FROM ContentDocumentLink
        WHERE ContentDocumentId IN :contentDocIds];
        System.Debug('ObdAdmissionApplication_Test:: Doc Links:' + cdDocLinks);

        Set<Id> linkedIds = new Set<Id>();
        for(ContentDocumentLink docLink:cdDocLinks)
        {
            // for each contentdocument, get the related record
            linkedIds.add(docLink.LinkedEntityId);
        }

        if(linkedIds.size() == 0)
        {
            // EARLY OUT 2, docs attached to application
            return;
        }

        // 3. find all CONTACT DOCUMENTS related to these CONTENTS, with File Upload of FALSE
        Map<Id, Contact_Document__c> conDocs = new Map<Id, Contact_Document__c> ([
                SELECT Id, File_Upload_Successful__c, 
                                Contact__c,
                                Comments__c,
                                Contact__r.Person_id__c,
                                Contact_Qualification__c,
                                Document_Type__c,
                                Document_Type_Name__c,
                                Filename__c,
                                Has_API_Request__c,
                                Has_API_Response__c,
                                API_Request__c,
                                Submitted__c,
                                Type__c
                FROM Contact_Document__c
                WHERE Id IN:linkedIds
                AND File_Upload_Successful__c != true
                AND Filename__c != null AND Filename__c != ''
                AND Document_Type__c != null
                AND Document_Status__c != true
        ]);
        //Query all the ContentDocumentLink that are linked to Contact_Document__c
        Map<Id, ContentDocumentLink> mapContentDocumentLink = new Map<Id, ContentDocumentLink> ();
        Set<Id> setContentDocIds = new Set<Id> ();
        for (ContentDocumentLink cdl : [SELECT
                                           id,
                                           ContentDocumentId,
                                           ContentDocument.LatestPublishedVersionId,
                                           LinkedEntityId  
                                           FROM 
                                           ContentDocumentLink 
                                           WHERE LinkedEntityId = :appId
                                           ]) {
            mapContentDocumentLink.put(cdl.LinkedEntityId, cdl);
            setContentDocIds.add(cdl.ContentDocumentId);
        }
        //Query all the ContentDocument
        Map<Id, ContentDocument> mapContentDocument = new Map<Id, ContentDocument> ([SELECT
                    id,
                    Title,
                    LatestPublishedVersionId,
                    FileExtension,
                    ArchivedById,
                    ArchivedDate,
                    ContentAssetId,
                    ContentModifiedDate,
                    ContentSize,
                    Description,
                    FileType,
                    IsArchived,
                    LastReferencedDate,
                    LastViewedDate,
                    OwnerId,
                    ParentId,
                    PublishStatus,
                    SharingOption,
                    SharingPrivacy
                                  FROM
                                  ContentDocument 
                                  WHERE id IN :setContentDocIds] );

        // store all the interface requests, because we need to do the DML updates AFTER the callout
        List<FileToCallistaInterface> callistaRequests = new List<FileToCallistaInterface>();
        for(Contact_Document__c contactDoc : conDocs.values())
        {
            // Callout to SEND to CALLISTA
            System.Debug('ObdAdmissionApplication_Test::Sending to Callista, cdID = ' + contactDoc.Id);
            String contactDocRec = JSON.serialize(contactDoc);
            ContentDocumentLink cdl = mapContentDocumentLink.get(contactDoc.Id);
            String cdlRec = JSON.serialize(cdl);
            String cdRec = JSON.serialize(mapContentDocument.get(cdl.ContentDocumentId));
            // FileToCallistaInterface fci = new FileToCallistaInterface(contactDoc.Id, callApplicantId, null);
            FileToCallistaInterface fci = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, callApplicantId, null);
            callistaRequests.add(fci);
            fci.sendMessage();
        }

        System.Debug('ObdAdmissionApplication_Test:: updating DML for '+ conDocs.size() + ' contact documents');
        for(FileToCallistaInterface finishedCallout: callistaRequests)
        {
            finishedCallout.handleResponse();
        }

    }

    /**
    * Moved from SendApplicationQueueable class
    **/
    public static String replaceBlankWithNull(String strValue) {
        if (String.isBlank(strValue)) {
            strValue = 'null';
        }
        return strValue;
    }



    
}