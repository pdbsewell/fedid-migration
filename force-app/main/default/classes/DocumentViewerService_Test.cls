/**
 * @author      Kristian Vegerano
 * @description Test class for DocumentViewerService class
 * @group       Test Class
 * @revision    30/10/2019 - Kristian Vegerano - Created
 */
@isTest
public with sharing class DocumentViewerService_Test {
    /**
     * @description Setup test data
     */
    @testSetup
    static void setup() {
        //Setup test data
        Contact newContact = new Contact();
        newContact.FirstName = 'TestContact';
        newContact.LastName = 'TestContact';
        newContact.Person_Id_Unique__c = 'IDA';
        insert newContact;

        Qualification__c qual1 = (Qualification__c) TestDataFactory.createSObject(new Qualification__c (Qualification_Name__c = 'APPRENTICESHIP', Overseas__c = false, Callista_Code__c = '1234', Sub_score_Type__c = 'Listening; Reading; Speaking; Writing'), true);

        // The flow 'Contact Qual : BI : Populate ExternalId' causes this test class to fail ONLY in QA.
        // It seems to be due to duplicate external IDs populated by the flow.
        // As a result, we by pass the flow in the test class.
        Bypass_Mute_Request__c customSetting = Bypass_Mute_Request__c.getInstance();
        customSetting.Bypass_All_Flows__c = true;
        upsert customSetting;

        Contact_Qualification__c contQual1 = (Contact_Qualification__c) TestDataFactory.createSObject(
            new Contact_Qualification__c (Qualification__c = qual1.Id, Contact__c = newContact.Id, Country__c = 'Australia',
                Date_Achieved__c = System.today(), First_Year_Enrolled__c = '', Institution_Code__c = '', Institution_Name__c = 'Institution',
                Instruction_in_English__c = true,
                Last_Year_Enrolled__c = '', Other_Institution__c = '', Other_Qualification_Comments__c = '', Other_Qualification__c = ''), true);

        customSetting.Bypass_All_Flows__c = false;
        upsert customSetting;

        Application__c application = new Application__c();
        application.Applicant__c = newContact.Id;
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
        insert application;

        Document_Checklist__c docChecklist = (Document_Checklist__c) TestDataFactory.createSObject(new Document_Checklist__c (Application__c = application.Id, Checklist_Requirement__c = 'Proof of Residency',
            Unique_ID__c = application.Id + '- Proof of Residency', Contact__c = newContact.Id,
            Contact_Qualification__c = contQual1.Id, Status__c = 'Requested'), true);

        Contact_Document__c condoc = new Contact_Document__c();
        condoc.Contact__c = newContact.id;
        condoc.Document_Checklist__c = docChecklist.Id;
        condoc.Contact_Qualification__c = contQual1.Id;
        condoc.Document_Type__c = 'PARENT_GUARDIAN';
        condoc.Filename__c = 'testdoc';
        condoc.File_Upload_Successful__c = false;
        insert condoc;


        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Header_Picture1',
            PathOnClient = '/Header_Picture1.txt',
            VersionData = bodyBlob,
            origin = 'H'
        );
        insert contentVersion_1;

        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = application.id;
        contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;

        ContentDocumentLink contentlink1 = new ContentDocumentLink();
        contentlink1.LinkedEntityId = condoc.id;
        contentlink1.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink1.ShareType = 'V';
        insert contentlink1;

        /***************** OFFER ACCEPTANCE CHECKLIST ********************/
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

        //Price book Creation
        Pricebook2 pb = (Pricebook2) TestDataFactory.createSObject(new Pricebook2(), true);

        //Creating a product for scholarship
        Product2 product1 = (Product2) TestDataFactory.createSObject(new Product2(Name = 'Monash Scholarship1', External_Id__c = '12345', Expiry_days__c = 15), true);
        //product always required a standard pricebook
        TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product1.id, unitprice = -5000), true);
        //add custom pricebook entry for created product
        TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product1.id, unitprice = -5000), true);

        //start inserting quote
        String ENVELOP_ID_1 = 'e1420cb6-7172-4e39-acca-45888ad4e461';
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        //Retrieve test application
        Application__c testCreatedApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'test-opportunity-course-name',
            Offer_Type__c = 'OFFER',
            AccountId = testCreatedApplication.Applicant__r.AccountId,
            PrimaryContact__c = testCreatedApplication.Applicant__c,
            StageName = 'Processing Offer',
            NextStep = 'Generate Offer',
            CloseDate = Date.Today().addDays(1),
            Is_passport_document_provided__c = 'No',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId());
        insert testOpportunity;

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c) TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'Signed',
                Sub_Status__c = 'In QA Review',
                Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1,
                SBQQ__StartDate__c = System.TODAY().addDays(1),
                SBQQ__PrimaryContact__c = newContact.Id,
                SBQQ__Opportunity2__c = testOpportunity.Id
            ), false);
        quotes.add(quote1);
        insert quotes;
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests component's initialize - retrieve all necessary data
     */
    @isTest
    static void test_RetrieveContentDocumentData() {
        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Retrieve test content document
        Contact_Document__c testContactDocument = [
            SELECT Id, Filename__c
            FROM Contact_Document__c
            LIMIT 1
        ];
        testContactDocument.Application__c = testApplication.Id;
        update testContactDocument;

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestDocument(true, 'gif', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'doc', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'docx', testContactDocument.Id));

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        for (ContentDocument loopContentDocument : documentList) {
            ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testApplication.Id,
                docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id,
                testContactQualification.Id, null, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
            Content__c = 'Test Comment');

        //Start test process
        Map<String, Object> results;
        Test.startTest();
        results = DocumentViewerService.retrieveContentDocumentData(testContactDocument.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(null, results.get('ContactDocument'));
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns new content distribution record
     */
    @isTest
    static void test_RetrieveActiveContentDistributionNew() {
        //Retrieve test records        
        ContentDocument testDocument = [SELECT Id, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        ContentVersion testVersion = [SELECT Id FROM ContentVersion LIMIT 1];
        Contact_Document__c testContactDocument = [
            SELECT Id, Filename__c
            FROM Contact_Document__c
            LIMIT 1
        ];

        //Start test process
        Test.startTest();
        DocumentViewerService.retrieveActiveContentDistribution(testVersion.Id, testContactDocument, testDocument);
        Test.stopTest();

        //Start assertion
        System.assertEquals(1, [SELECT Id FROM ContentDistribution].size());
    }

    /**
     * @description Tests retrieveChecklistDetails method
     */
    @isTest
    static void test_RetrieveChecklistDetails_Assessment() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Retrieve test content document
        Contact_Document__c testContactDocument = [
            SELECT Id, Filename__c
            FROM Contact_Document__c
            LIMIT 1
        ];

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestDocument(true, 'gif', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'doc', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'docx', testContactDocument.Id));

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        for (ContentDocument loopContentDocument : documentList) {
            ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testApplication.Id,
                docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id,
                testContactQualification.Id, null, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
            Content__c = 'Test Comment');

        //Start test process
        Test.startTest();
        testResultMap = (Map<String, Object>) DocumentViewerService.retrieveChecklistDetails(resultApplicationDocumentChecklistList[0].Id, testApplication.Applicant__c, testApplication.Id, null, testContactDocument.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
    }

    /**
     * @description Tests retrieveChecklistDetails method
     */
    @isTest
    static void test_RetrieveChecklistDetails_OfferAcceptance() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test quote
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Retrieve test content document
        Contact_Document__c testContactDocument = [
            SELECT Id, Filename__c
            FROM Contact_Document__c
            LIMIT 1
        ];

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestDocument(true, 'gif', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'doc', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'docx', testContactDocument.Id));

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        for (ContentDocument loopContentDocument : documentList) {
            DocumentChecklistAcceptanceServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testQuote.SBQQ__Opportunity2__c,
                docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
            Content__c = 'Test Comment');

        //Start test process
        Test.startTest();
        testResultMap = (Map<String, Object>) DocumentViewerService.retrieveChecklistDetails(resultApplicationDocumentChecklistList[0].Id, testApplication.Applicant__c, null, testQuote.SBQQ__Opportunity2__c, testContactDocument.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
    }

    /**
     * @description Tests retrieveChecklistDetails method with existing gte and course requirement document checklists
     */
    @isTest
    static void test_RetrieveChecklistDetails_With_GTE_CourseRequirement() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        insert new Document_Checklist__c(Application__c = testApplication.Id,
            Contact__c = testApplication.Applicant__c,
            Allowed_Document_Type__c = 'OTHERDCTYP',
            Applicant_Instructions_Email__c = 'test',
            Applicant_Instructions_UI__c = 'test',
            Checklist_Requirement__c = 'Course Requirements',
            Sort_Order__c = 100,
            Status__c = 'Requested',
            Type__c = 'GTE',
            Unique_ID__c = testApplication.Id + '-GTE-Manual-' + System.NOW(),
            RecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId());

        insert new Document_Checklist__c(Application__c = testApplication.Id,
            Contact__c = testApplication.Applicant__c,
            Allowed_Document_Type__c = 'OTHERDCTYP',
            Applicant_Instructions_Email__c = 'test',
            Applicant_Instructions_UI__c = 'test',
            Checklist_Requirement__c = 'Course Requirements',
            Sort_Order__c = 65,
            Status__c = 'Requested',
            Type__c = 'Course',
            Unique_ID__c = testApplication.Id + '-Course-Manual-' + System.NOW(),
            RecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId());

        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Retrieve test content document
        Contact_Document__c testContactDocument = [
            SELECT Id, Filename__c
            FROM Contact_Document__c
            LIMIT 1
        ];

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestDocument(true, 'gif', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'doc', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'docx', testContactDocument.Id));

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        for (ContentDocument loopContentDocument : documentList) {
            ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testApplication.Id,
                docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id,
                testContactQualification.Id, null, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
            Content__c = 'Test Comment');

        //Start test process
        Test.startTest();
        testResultMap = (Map<String, Object>) DocumentViewerService.retrieveChecklistDetails(resultApplicationDocumentChecklistList[0].Id, testApplication.Applicant__c, testApplication.Id, null, testContactDocument.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
    }

    /**
     * @description Tests retrieveChecklistData method
     */
    @isTest
    static void test_RetrieveChecklistData() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Retrieve test content document
        Contact_Document__c testContactDocument = [
            SELECT Id, Filename__c
            FROM Contact_Document__c
            LIMIT 1
        ];

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestDocument(true, 'gif', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'doc', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'docx', testContactDocument.Id));

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        for (ContentDocument loopContentDocument : documentList) {
            ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testApplication.Id,
                docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id,
                testContactQualification.Id, null, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
            Content__c = 'Test Comment');

        //Start test process
        Test.startTest();
        testResultMap = (Map<String, Object>) DocumentViewerService.retrieveChecklistData(resultApplicationDocumentChecklistList[0].Id, testApplication.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
    }

    //Retrieve field's document type value
    static String getDocumentTypeValue(Integer i) {
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry pleAtI = ple[i];

        if (pleAtI != null)
            return pleAtI.getValue();
        return null;
    }

    //Creating test content document
    static ContentDocument createTestDocument(Boolean allAccess, String fileExtension, Id contactDocumentId) {
        // create a file
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
            Title = 'Header_Picture1',
            PathOnClient = '/Header_Picture1.' + fileExtension,
            VersionData = bodyBlob,
            origin = 'H'
        );

        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE id = :cv.Id];

        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE id = :cv.ContentDocumentId
        ];
        ContentDocument file = documents[0];

        if (allAccess) {
            List<ContentDocumentLink> linkList = new List<ContentDocumentLink>();
            linkList.add(new ContentDocumentLink(LinkedEntityId = UserInfo.getOrganizationId(),
                ContentDocumentId = cv.ContentDocumentId,
                ShareType = 'C',
                Visibility = 'AllUsers'));
            insert linkList;
        }

        return file;
    }
}