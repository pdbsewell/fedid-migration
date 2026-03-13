/**
 * @author      Kristian Vegerano
 * @description Test class for DocumentChecklistAcceptanceServices class
 * @group       Test Class
 * @revision    20/02/2020 - Kristian Vegerano - Created
 */
@isTest
public with sharing class DocumentChecklistAcceptanceServices_Test {
    /**
     * @description Setup test data
     */
    @testSetup
    static void setup() {
        //Create country record
        Country_Attribute__c countryRec = new Country_Attribute__c ();
        countryRec.Name = 'AUSTRALIA';
        countryRec.Country__c = 'Australia';
        countryRec.Regional_Manager__c = UserInfo.getUserId();
        insert countryRec;

        //Create agency
        Schema.RecordTypeInfo agencyRTByName = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Agency');

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
        User testApplicant = StudFirst_TestHelper.createCommunityUser();
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];

        //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        insert testApplication;

        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        insert testACP;

        //Submit the application
        testApplication.Status__c = 'Submitted';
        testApplication.Residency_Status__c = 'DOM-AUS';
        update testApplication;

        /***************** OFFER ACCEPTANCE CHECKLIST ********************/
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);

        //Creating a product for scholarship
        Product2 product1 = (Product2)TestDataFactory.createSObject(new Product2(Name='Monash Scholarship1', External_Id__c='12345', Expiry_days__c=15),true);
        //product always required a standard pricebook         
        PricebookEntry pbe1 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product1.id, unitprice=-5000),true);
        //add custom pricebook entry for created product
        PricebookEntry pbe2 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product1.id, unitprice=-5000), true);

        //start inserting quote
        String ENVELOP_ID_1 = 'e1420cb6-7172-4e39-acca-45888ad4e461';
        String ENVELOP_ID_2 = 'e1420cb6-7172-4e39-acca-45888ad4e462';
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        //Retrieve test application
        Application__c testCreatedApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name='test-opportunity-course-name', 
                                                      Offer_Type__c = 'OFFER', 
                                                      AccountId = testCreatedApplication.Applicant__r.AccountId,
                                                      PrimaryContact__c = testCreatedApplication.Applicant__c,
                                                      StageName = 'Signed',
                                                      NextStep = 'Generate Offer',
                                                      CloseDate = Date.Today().addDays(1),
                                                      Is_passport_document_provided__c = 'No',
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId());
        insert testOpportunity;

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'Signed',
                Sub_Status__c = 'In QA Review',
                Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1,
                SBQQ__StartDate__c = System.TODAY().addDays(1),
                SBQQ__PrimaryContact__c = testContact.Id,
                SBQQ__Opportunity2__c = testOpportunity.Id
            ), false);
        quotes.add(quote1);
        insert quotes;
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
        
        testOpportunity.SBQQ__PrimaryQuote__c = quotes[0].Id;
        update testOpportunity;
    }

    /**
     * @description Tests retrieveApplicantCommunityUser method
     */
    @isTest
    static void test_RetrieveApplicantCommunityUser() {
        //Initialize variables
        User applicantUser;

        //Retrieve test opportunity
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        //Start test process
        Test.startTest();
            applicantUser = (User)DocumentChecklistAcceptanceServices.retrieveApplicantCommunityUser(testOpportunity.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(applicantUser, null);
    }

    /**
     * @description Tests retrieveOffer method
     */
    @isTest
    static void test_RetrieveOffer() {
        //Retrieve test opportunity
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        //Start test process
        Test.startTest();
        Map<String, Object> resultMap = new Map<String, Object>();
        resultMap = (Map<String, Object>)DocumentChecklistAcceptanceServices.retrieveOffer(testOpportunity.Id);
        testOpportunity = (Opportunity)resultMap.get('Opportunity');
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testOpportunity, null);
    }

    /**
     * @description Tests retrieveChecklistItems method
     */
    @isTest
    static void test_RetrieveChecklistItems() {
        //Retrieve test opportunity
        Object result;
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        //Start test process
        Test.startTest();
            result = (Object)DocumentChecklistAcceptanceServices.retrieveChecklistItems(testOpportunity.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(result, null);
    }

    /**
     * @description Tests runRules method
     */
    @isTest
    static void test_RunRules() {
        //Retrieve test opportunity
        Object result;
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        //Start test process
        Test.startTest();
            result = (Object)DocumentChecklistAcceptanceServices.runRules('Offer Acceptance', testOpportunity.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(result, null);
    }

    /**
     * @description Tests retrieveChecklistFiles method
     */
    @isTest
    static void test_RetrieveChecklistFiles_Quote() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test applicant
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test opportunity
        Opportunity testOpportunity = [SELECT Id, PrimaryContact__c FROM Opportunity LIMIT 1];

        //Start test process
        Test.startTest();
            //Insert test document checklists
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});

            //Retrieve test document checklist records
            List<Document_Checklist__c> resultOfferDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAcceptanceServices.retrieveChecklistItems(testOpportunity.Id);

            //Create test contact document
            List<ContentDocument> documentList = new List<ContentDocument>();
            documentList.add(createTestDocument(true, 'gif'));

            String docTypeValue = getDocumentTypeValue(0);
            String docSubType = '';
            String comments = 'testing some comments ';

            for(ContentDocument loopContentDocument : documentList) {
                DocumentChecklistAcceptanceServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testOpportunity.PrimaryContact__c, testOpportunity.Id,
                        docTypeValue, docSubType, comments, resultOfferDocumentChecklistList[0].Id,
                        false);
            }

            //Create test document checklist comment
            insert new Document_Checklist_Comment__c(Document_Checklist__c = resultOfferDocumentChecklistList[0].Id,
                    Content__c = 'Test Comment');

            testResultMap = (Map<String, Object>)DocumentChecklistAcceptanceServices.retrieveChecklistFiles(resultOfferDocumentChecklistList[0].Id, testOpportunity.PrimaryContact__c, testOpportunity.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
        System.assertEquals(((List<DocumentChecklistAcceptanceServices.ChecklistDocument>)testResultMap.get('documents')).size(), 1);
        System.assertEquals(((List<DocumentChecklistAcceptanceServices.ChecklistNote>)testResultMap.get('notes')).size(), 1);
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

        //Retrieve test opportunity
        Opportunity testOpportunity = [SELECT Id, PrimaryContact__c FROM Opportunity LIMIT 1];

        //Start test process
        Test.startTest();
            //Insert test document checklists
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});

            //Retrieve test document checklist records
            List<Document_Checklist__c> resultQuoteDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAcceptanceServices.retrieveChecklistItems(testOpportunity.Id);

            testResultMap = (Map<String, Object>)DocumentChecklistAcceptanceServices.writeNotes(resultQuoteDocumentChecklistList[0].Id, 'Test Comment', testCommunityUser.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
        System.assertEquals([SELECT Id FROM Document_Checklist_Comment__c].size(), 1);
    }

    /**
     * @description Tests runAcceptanceChecklistRules method
     */
    @isTest
    static void test_RunAcceptanceChecklistRules() {
        //Retrieve test opportunity
        Opportunity testOpportunity = [SELECT Id, PrimaryContact__c FROM Opportunity LIMIT 1];

        //Start test process
        Test.startTest();
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testOpportunity, null);
    }

    //Retrieve field's document type value
    static String getDocumentTypeValue(Integer i) {
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        Schema.PicklistEntry pleAtI = ple[i];

        if(pleAtI != null)
            return pleAtI.getValue();
        return null;
    }

    //Creating test content document
    static ContentDocument createTestDocument(Boolean allAccess, String fileExtension) {
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
            Title='Header_Picture1',
            PathOnClient ='/Header_Picture1.' + fileExtension,
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

        if(allAccess) {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = UserInfo.getOrganizationId();
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'C';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;
        }

        return file;
    }
}