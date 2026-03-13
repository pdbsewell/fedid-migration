/**
 * @author      Kristian Vegerano
 * @description Test class for DocumentChecklistAssessmentServices class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 *              21/07/2023 - Peter Sewell - additional tests for document archiving support
 *              17/04/2024 - Peter Sewell - test archived flag false if document has recovered flag is true
 *              13/09/2024 - Kai-Fan Hsieh - Update to improve test coverage
 */
@isTest(isParallel=false) /*APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
private class DocumentChecklistAssessmentServices_Test {
    /**
     * @description Setup test data
     */
    @TestSetup
    static void setup() {
        //Create country record
        Country_Attribute__c countryRec = new Country_Attribute__c();
        countryRec.Name = 'AUSTRALIA';
        countryRec.Country__c = 'Australia';
        countryRec.Regional_Manager__c = UserInfo.getUserId();
        insert countryRec;

        //Create agency
        Schema.RecordTypeInfo agencyRTByName = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getRecordTypeInfosByName().get('Agency');

        //Create test agency
        Account agencyRecord = new Account();
        agencyRecord.RecordTypeId = agencyRTByName.getRecordTypeId();
        agencyRecord.Name = 'test agency 1';
        agencyRecord.Phone = '12345';
        agencyRecord.Email__c = 'test@agency.com';
        agencyRecord.Website = 'www.test-agency-1.com';
        agencyRecord.Street__c = '123 testing st';
        agencyRecord.City__c = 'Melbourne';
        agencyRecord.State__c = 'VIC';
        agencyRecord.Post_Code__c = '3000';
        agencyRecord.Country_Lookup__c = countryRec.Id;
        agencyRecord.ShippingStreet = '123 testing st';
        agencyRecord.ShippingCity = 'Melbourne';
        agencyRecord.ShippingState = 'VIC';
        agencyRecord.ShippingPostalCode = '3000';
        agencyRecord.ShippingCountry = 'Australia';
        agencyRecord.Monash_AM_Web_Status__c = true;
        agencyRecord.Callista_Org_Unit_Code__c = 'tagent1';
        agencyRecord.Monash_AM_Campus__c = 'Australia';
        agencyRecord.Status__c = 'Appointed';
        insert agencyRecord;

        //Create community user
        User communityUser = StudFirst_TestHelper.createContactAndCommunityUser();
        System.runAs(communityUser) {
            //Create test Create application
            Application__c testApplication = StudFirst_TestHelper.createApplication(communityUser.ContactId);
            insert testApplication;

            //Create test Course
            Course__c testCourse = StudFirst_TestHelper.createCourse();
            insert testCourse;

            //Create test Offering
            Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
            insert testOffering;

            //Create test ACP
            Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, new Contact(Id = communityUser.ContactId), testOffering, testCourse);
            testACP.Preference_Number__c = '1';
            insert testACP;

            //Submit the application
            testApplication.Status__c = 'Submitted';
            testApplication.Residency_Status__c = 'DOM-AUS';
            update testApplication;
        }
    }

    /**
     * @description Tests retrieveApplicantCommunityUser method
     */
    @isTest
    static void test_RetrieveApplicantCommunityUser() {
        //Initialize variables
        User applicantUser;
        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        //Start test process
        Test.startTest();
        applicantUser = (User) DocumentChecklistAssessmentServices.retrieveApplicantCommunityUser(testApplication.Id);
        Test.stopTest();
        //Start assertion
        Assert.areNotEqual(applicantUser, null);
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests retrieveApplicantCommunityUser method
     *              Tests retrieving the user record relevant to the current user viewing the assessment document checklist view
     */
    @isTest
    static void test_RetrieveApplicantCommunityPartnerUser() {
        //Initialize variables
        User applicantUser;
        //Start test process
        Test.startTest();
        applicantUser = (User) DocumentChecklistAssessmentServices.retrieveApplicantCommunityUser(UserInfo.getUserId());
        Test.stopTest();
        //Start assertion
        Assert.areNotEqual(applicantUser, null);
    }

    /**
     * @description Tests retrieveApplicationRecord method
     */
    @isTest
    static void test_RetrieveApplicationRecord() {
        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        //Start test process
        Test.startTest();
        testApplication = (Application__c) DocumentChecklistAssessmentServices.retrieveApplicationRecord(testApplication.Id);
        Test.stopTest();

        //Start assertion
        Assert.areNotEqual(testApplication.Name, null);
    }

    /**
     * @description Tests runRules method
     */
    @isTest
    static void test_RunRules() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;
        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        //Start test process
        Test.startTest();
        applicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();
        //Start assertion
        Assert.areEqual(applicationDocumentChecklistList.size(), 1);    }

    /**
     * @description Tests runRulesUpdateEmailResults method
     */
    @isTest
    static void test_RunRulesUpdateEmailResults() {
        //Initialize variables
        Map<String, Object> testResultMap;
        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        //Start test process
        Test.startTest();
        testResultMap = (Map<String, Object>) DocumentChecklistAssessmentServices.runRulesUpdateEmailResults('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Assert.areNotEqual(testResultMap, null);
        Assert.areNotEqual(testResultMap.get('PENDING'), '');
        Assert.areEqual(testResultMap.get('COMPLETED'), '');
        Assert.areEqual(testResultMap.get('HASINCOMPLETE'), true);
    }

    /**
     * @description Tests retrieveChecklistItems method
     */
    @isTest
    static void test_RetrieveChecklistItems() {
        //Initialize variables
        List<Document_Checklist__c> resultApplicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        //Start test process
        Test.startTest();
        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);
        Test.stopTest();

        //Start assertion
        Assert.areEqual(resultApplicationDocumentChecklistList.size(), 1);
    }

    /**
     * @description Tests retrieveChecklistFiles method
     */
    @isTest
    static void test_RetrieveChecklistFiles_Application() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Create test contact documents
        List<ContentDocument> documentList = createTestDocuments(new List<String>{'gif', 'doc', 'docx'});
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

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        //Start test process
        Test.startTest();
        for (ContentDocument loopContentDocument : documentList) {
            ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testApplication.Id,
                docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id,
                testContactQualification.Id, null, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
            Content__c = 'Test Comment');

        testResultMap = (Map<String, Object>) DocumentChecklistAssessmentServices.retrieveChecklistFiles(resultApplicationDocumentChecklistList[0].Id, testApplication.Applicant__c, testApplication.Id);
        Test.stopTest();

        //Start assertion
        List<DocumentChecklistAssessmentServices.ChecklistDocument> clDocs = (List<DocumentChecklistAssessmentServices.ChecklistDocument>) testResultMap.get('documents');
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual(clDocs.size(), 3);
        Assert.areEqual(((List<DocumentChecklistAssessmentServices.ChecklistNote>) testResultMap.get('notes')).size(), 1);
        for (DocumentChecklistAssessmentServices.ChecklistDocument clDoc : clDocs) {
            Assert.areEqual(clDoc.isArchived, false, 'Document should NOT have been tagged as archived');
        }
    }

    /**
     * @description Tests retrieveChecklistFiles method
     */
    @isTest
    static void test_RetrieveChecklistFiles_Application_Qualification() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Create test contact documents
        List<ContentDocument> documentList = createTestDocuments(new List<String>{'doc', 'txt', 'xls'});
        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        //Start test process
        Test.startTest();
        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

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

        testResultMap = (Map<String, Object>) DocumentChecklistAssessmentServices.retrieveChecklistFiles(resultApplicationDocumentChecklistList[0].Id, testApplication.Applicant__c, null);
        Test.stopTest();

        //Start assertion
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual(((List<DocumentChecklistAssessmentServices.ChecklistDocument>) testResultMap.get('documents')).size(), 3);
        Assert.areEqual(((List<DocumentChecklistAssessmentServices.ChecklistNote>) testResultMap.get('notes')).size(), 1);
    }

    /**
     * @description Tests retrieveLastReminderSentDateTime method with scenario that the application is sent via my.app channel
     */
    @isTest
    static void test_RetrieveLastReminderSentDateTime_MyApp() {
        //Initialize Variables
        Map<String, Object> testResultMap = new Map<String, Object>();

        //Start test process
        Test.startTest();
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        testApplication.Source_System__c = 'my.app';
        testApplication.Checklist_Ad_Hoc_Email_Status__c = 'Send to MC';
        update testApplication;

        //Simulate SFMC updating the field to Email Sent
        testApplication.Checklist_Ad_Hoc_Email_Status__c = 'Email Sent';
        update testApplication;

        //Reretrieve value
        testResultMap = DocumentChecklistAssessmentServices.retrieveLastReminderSentDateTime((String) testApplication.Id, (String) testApplication.Applicant__c, testApplication.Source_System__c);
        Test.stopTest();

        //Start post-test assertion
        Assert.areNotEqual(testResultMap.get('LastSentDateTime'), null);
    }

    /**
     * @description Tests retrieveLastReminderSentDateTime method with scenario that the application is sent via non my.app channel
     */
    @isTest
    static void test_RetrieveLastReminderSentDateTime_NonMyApp() {
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        testApplication.Source_System__c = 'Agent Portal';
        update testApplication;

        //Start test process
        Test.startTest();
        //Start pre-test assertion
        Map<String, Object> testResultMap = DocumentChecklistAssessmentServices.retrieveLastReminderSentDateTime((String) testApplication.Id, (String) testApplication.Applicant__c, testApplication.Source_System__c);
        Assert.areEqual(testResultMap.get('LastSentDateTime'), null);

        //Simulate sending emails to agents
        insert new Case(ContactId = testApplication.Applicant__c,
            Origin = 'Email - mu.documents',
            Subject = 'Monash University needs your documents!');

        //Retrieve value
        testResultMap = DocumentChecklistAssessmentServices.retrieveLastReminderSentDateTime((String) testApplication.Id, (String) testApplication.Applicant__c, testApplication.Source_System__c);
        Test.stopTest();

        //Start post-test assertion
        Assert.areNotEqual(testResultMap.get('LastSentDateTime'), null);
    }

    /**
     * @description Tests writeNotes method
     */
    @isTest
    static void test_WriteNotes() {
        //Initialize variables
        Map<String, Object> testResultMap;
        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        //Retrieve test community user
        User testCommunityUser = [SELECT Id FROM User WHERE ContactId = :testApplicant.Id];
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);
        //Start test process
        Test.startTest();
        testResultMap = DocumentChecklistAssessmentServices.writeNotes(resultApplicationDocumentChecklistList[0].Id, 'Test Comment', testCommunityUser.Id);
        Test.stopTest();
        //Start assertion
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual([SELECT Id FROM Document_Checklist_Comment__c].size(), 1);
    }

    /**
     * @description Tests retrieveChecklistFiles method
     */
    @isTest
    static void test_RetrieveContactQualificationChecklistItem() {
        //Initialize variables
        Map<String, Object> testResultMap;
        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        //Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;
        //Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        testContactQualification.Year_of_Completion__c = '2000';
        insert testContactQualification;
        //Create Application Qualification Provided
        Application_Qualification_Provided__c testACP = new Application_Qualification_Provided__c();
        testACP.Application__c = testApplication.Id;
        testACP.Contact_Qualification__c = testContactQualification.Id;
        insert testACP;
        //Insert test document checklists
        Document_Checklist__c qualificationChecklist;
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        for (Document_Checklist__c loopChecklist : resultApplicationDocumentChecklistList) {
            if (loopChecklist.Contact_Qualification__c != null) {
                qualificationChecklist = loopChecklist;
            }
        }
        //Start test process
        Test.startTest();
        testResultMap = DocumentChecklistAssessmentServices.retrieveContactQualificationChecklistItem(qualificationChecklist.Contact_Qualification__c);
        Test.stopTest();
        //Start assertion
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual(((String) testResultMap.get('Status')), 'Success');
        Assert.areEqual(((String) testResultMap.get('ChecklistId')), qualificationChecklist.Id);
        Assert.areEqual(((String) testResultMap.get('ContactId')), qualificationChecklist.Contact__c);
    }

    /**
     * @description Tests retrieveTaskTypeChecklistItem method
     */
    @isTest
    static void test_RetrieveTaskTypeChecklistItem() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Start test process
        Test.startTest();
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        testApplication.Refused_entry_visa_to_any_country__c = 'Yes';
        update testApplication;

        //Insert test document checklists
        Document_Checklist__c visaChecklist;
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        for (Document_Checklist__c loopChecklist : resultApplicationDocumentChecklistList) {
            if (loopChecklist.Type__c == 'Visa') {
                visaChecklist = loopChecklist;
            }
        }

        testResultMap = DocumentChecklistAssessmentServices.retrieveTaskTypeChecklistItem(testApplication.Id + ':::Visa');
        Test.stopTest();

        //Start assertion
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual(((String) testResultMap.get('Status')), 'Success');
        Assert.areEqual(((String) testResultMap.get('ChecklistId')), visaChecklist.Id);
        Assert.areEqual(((String) testResultMap.get('ContactId')), visaChecklist.Contact__c);
    }

    /**
     * @description Tests retrieveAssessmentAdHocEmailTemplate method
     */
    @isTest
    static void test_RetrieveAssessmentAdHocEmailTemplate() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Start test process
        Test.startTest();
        testResultMap = DocumentChecklistAssessmentServices.retrieveAssessmentAdHocEmailTemplate();
        Test.stopTest();

        //Start assertion
        Assert.areNotEqual(testResultMap, null);
        Assert.isTrue(testResultMap.containsKey('Template'));
        Assert.isTrue(testResultMap.containsKey('HeaderImage'));
        Assert.isTrue(testResultMap.containsKey('FooterImage'));
    }

    /**
     * @description Tests submitAdmissionsEnquiryEmail method
     */
    @isTest
    static void test_SubmitAdmissionsEnquiryEmail() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test agency
        Account testAgencyAccount = [SELECT Id FROM Account WHERE RecordType.Name = 'Agency'];

        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        testApplicant.Email = 'testTo@test.com';
        update testApplicant;

        //Start test process
        Test.startTest();
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        testApplication.Agent__c = testAgencyAccount.Id;
        testApplication.Sponsor_Email_Address__c = 'testsponsor@test.com';
        testApplication.Proxy_Email_Address__c = 'testproxy@test.com';
        update testApplication;

        //Retrieve Application Course Preference
        Application_Course_Preference__c testApplicationCoursePreference = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];

        //Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        //Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

        //Create test contact document
        List<ContentDocument> documentList = createTestDocuments(new List<String>{'pdf', 'png', 'jpg'});

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments';

        for (ContentDocument loopContentDocument : documentList) {
            ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testApplication.Id,
                docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id,
                testContactQualification.Id, null, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
            Content__c = 'Test Comment');

        testResultMap = DocumentChecklistAssessmentServices.submitAdmissionsEnquiryEmail(testApplication.Id, 'TestContent', 'testcc@test.com', 'Test Subject',
            'testfrom@test.com', testApplicationCoursePreference.Id, 'TestContent');
        Test.stopTest();

        //Start assertion
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual(((String) testResultMap.get('Status')), 'Success');
        Assert.isTrue(testResultMap.containsKey('Enquiry'));
    }

    /**
     * @description Tests retrieveChecklistFiles method for Proxy Document ContentVersion RT type
     */
    @isTest
    static void test_RetrieveChecklistFiles_ProxyDocs() {
        // No point testing if proxy doc RT does not exist in this rog
        if (!recordTypeExists(DocumentChecklistAssessmentServices.PROXY_DOC_RECORD_TYPE)) {
            return;
        }

        //Initialize variables
        Map<String, Object> testResultMap;
        String recordTypeDeveloperName = DocumentChecklistAssessmentServices.PROXY_DOC_RECORD_TYPE;

        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        //Start test process
        Test.startTest();
        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;
        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;
        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestProxyDocument(true, 'gif', recordTypeDeveloperName));
        documentList.add(createTestProxyDocument(true, 'doc', recordTypeDeveloperName));
        documentList.add(createTestProxyDocument(true, 'docx', recordTypeDeveloperName));
        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);

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

        testResultMap = (Map<String, Object>) DocumentChecklistAssessmentServices.retrieveChecklistFiles(
            resultApplicationDocumentChecklistList[0].Id, testApplication.Applicant__c, testApplication.Id);
        Test.stopTest();

        //Start assertion
        List<DocumentChecklistAssessmentServices.ChecklistDocument> clDocs =
            (List<DocumentChecklistAssessmentServices.ChecklistDocument>) testResultMap.get('documents');
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual(clDocs.size(), 3);
        Assert.areEqual(((List<DocumentChecklistAssessmentServices.ChecklistNote>) testResultMap.get('notes')).size(), 1);
        for (DocumentChecklistAssessmentServices.ChecklistDocument clDoc : clDocs) {
            Assert.areEqual(clDoc.isArchived, true, 'Document should have been tagged as archived');
        }
    }

    /**
     * @description Tests retrieveChecklistFiles method for Proxy Document ContentVersion RT type 
     *              where recovered flag is true
     */
    @isTest
    static void test_RetrieveChecklistFiles_ProxyDocs_Recovered_Ver() {
        // No point testing if proxy doc RT does not exist in this rog
        if (!recordTypeExists(DocumentChecklistAssessmentServices.PROXY_DOC_RECORD_TYPE)) {
            return;
        }

        //Initialize variables
        Map<String, Object> testResultMap;
        String recordTypeDeveloperName = DocumentChecklistAssessmentServices.PROXY_DOC_RECORD_TYPE;

        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];

        //Start test process
        Test.startTest();
        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestProxyDocumentRecovered(true, 'gif', recordTypeDeveloperName));
        documentList.add(createTestProxyDocumentRecovered(true, 'doc', recordTypeDeveloperName));
        documentList.add(createTestProxyDocumentRecovered(true, 'docx', recordTypeDeveloperName));

        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>) DocumentChecklistAssessmentServices.retrieveChecklistItems(testApplication.Id);
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

        testResultMap = (Map<String, Object>) DocumentChecklistAssessmentServices.retrieveChecklistFiles(resultApplicationDocumentChecklistList[0].Id, testApplication.Applicant__c, testApplication.Id);
        Test.stopTest();

        //Start assertion
        List<DocumentChecklistAssessmentServices.ChecklistDocument> clDocs = (List<DocumentChecklistAssessmentServices.ChecklistDocument>) testResultMap.get('documents');
        Assert.areNotEqual(testResultMap, null);
        Assert.areEqual(clDocs.size(), 3);
        Assert.areEqual(((List<DocumentChecklistAssessmentServices.ChecklistNote>) testResultMap.get('notes')).size(), 1);
        for (DocumentChecklistAssessmentServices.ChecklistDocument clDoc : clDocs) {
            Assert.areEqual(clDoc.isArchived, false, 'Recovered document should not have been tagged as archived');
        }
    }

    //Retrieve field's document type value
    static String getDocumentTypeValue(Integer i) {
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry pleAtI = ple[i];

        if (pleAtI != null) {
            return pleAtI.getValue();
        } else {
            return null;
        }
    }

    private static List<ContentDocument> createTestDocuments(List<String> fileExtensions) {
        List<ContentDocument> documentList = new List<ContentDocument>();
        for (String fileExtension : fileExtensions) {
            documentList.add(createTestDocument(false, fileExtension));
        }
        return documentList;
    }

    //Creating test content document
    static ContentDocument createTestDocument(Boolean allAccess, String fileExtension) {
        Id networkId = [
            SELECT NetworkId, MemberId
            FROM NetworkMember
            WHERE MemberId = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
            LIMIT 1
        ]?.NetworkId;

        // create a file
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
            Title = 'Header_Picture1',
            PathOnClient = '/Header_Picture1.' + fileExtension,
            VersionData = bodyBlob,
            Origin = 'H',
            NetworkId = networkId
        );

        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :cv.ContentDocumentId
        ];
        ContentDocument file = documents[0];

        if (allAccess) {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getUserId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'I';
            cdLink.Visibility = 'AllUsers';
            insert cdLink;
        }

        return file;
    }

    //Creating test content document with proxy document RT
    static ContentDocument createTestProxyDocument(Boolean allAccess, String fileExtension, String rtDevName) {
        Id recordTypeId = null;

        // Query the RecordType object to get the Record Type ID
        RecordType recordType = [SELECT Id FROM RecordType WHERE DeveloperName = :rtDevName];
        recordTypeId = recordType?.Id;

        // create a file
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
            Title = 'Header_Picture1',
            PathOnClient = '/Header_Picture1.' + fileExtension,
            VersionData = bodyBlob,
            Origin = 'H',
            RecordTypeId = recordTypeId
        );

        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :cv.ContentDocumentId
        ];
        ContentDocument file = documents[0];

        if (allAccess) {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getOrganizationId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'C';
            cdLink.Visibility = 'AllUsers';
            insert cdLink;
        }

        return file;
    }

    //Creating test content document with proxy document RT
    static ContentDocument createTestProxyDocumentRecovered(Boolean allAccess, String fileExtension, String rtDevName) {
        Id recordTypeId = null;

        // Query the RecordType object to get the Record Type ID
        RecordType recordType = [SELECT Id FROM RecordType WHERE DeveloperName = :rtDevName];
        recordTypeId = recordType?.Id;

        // create a file
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
            Title = 'Header_Picture1',
            PathOnClient = '/Header_Picture1.' + fileExtension,
            VersionData = bodyBlob,
            Origin = 'H',
            RecordTypeId = recordTypeId,
            Is_Recovered_Version__c = true
        );

        insert cv;

        // retrieve it again to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :cv.ContentDocumentId
        ];
        ContentDocument file = documents[0];

        if (allAccess) {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getOrganizationId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'C';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;
        }
        return file;
    }

    // Return true if RT recordTypeDevName exists
    //
    private static Boolean recordTypeExists(String recordTypeDevName) {
        // Query the RecordType object to get the Record Type ID
        String recordTypeDeveloperName = DocumentChecklistAssessmentServices.PROXY_DOC_RECORD_TYPE;
        RecordType recordType = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperName];
        if (recordType != null) {
            return true;
        } else {
            return false;
        }
    }

    private static User getCommunityUser() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        User communityUser = [SELECT Id FROM User WHERE ContactId = :testContact.Id LIMIT 1];
        return communityUser;
    }
}