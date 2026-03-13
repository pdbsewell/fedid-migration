/**
 * @author      Kristian Vegerano
 * @description Test class for OfferInternalEmailServices class
 * @group       Test Class
 * @revision    25/05/2020 - Kristian Vegerano - Created
 */
@isTest/*(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests*/
public with sharing class OfferInternalEmailServices_Test {
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
        testContact.Person_ID_unique__c = '11111111';
        update testContact;

        //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        //Ensure that this is stamped with the latest default document checklist rule version
        //Additionally, stamp the rules with the previous latest document checklist rule version if you're deprecating rules
        // - see age check as an example. only active on version 1
        testApplication.Assessment_Checklist_Version__c = 'Assessment Version 2';
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

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'Signed',
                Sub_Status__c = 'In QA Review',
                Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1,
                SBQQ__StartDate__c = System.TODAY().addDays(1),
                SBQQ__PrimaryContact__c = testContact.Id,
                SBQQ__ExpirationDate__c = System.TODAY().addDays(10)
            ), false);
        quotes.add(quote1);
        insert quotes;
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
    }
    
    /**
     * @description Tests retrieveOpportunityDetails method
     */
    @isTest
    static void test_RetrieveOpportunityDetails() {
        //Initialize variables
        Object testResult;

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name='test-opportunity-course-name', 
                                                      Offer_Type__c = 'OFFER', 
                                                      AccountId = testApplication.Applicant__r.AccountId,
                                                      PrimaryContact__c = testApplication.Applicant__c,
                                                      StageName = 'Signed',
                                                      NextStep = 'Generate Offer',
                                                      CloseDate = Date.Today().addDays(1),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId());
        insert testOpportunity;

        //Start test process
        Test.startTest();
            //Create test contact document
            List<ContentDocument> documentList = new List<ContentDocument>();
            documentList.add(createTestDocument(true, 'pdf'));

            testResult = (Object)OfferInternalEmailServices.retrieveOpportunityDetails(testOpportunity.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResult, null);
    }

    /**
     * @description Tests retrieveOfferEmailTemplate method
     */
    @isTest
    static void test_RetrieveOfferEmailTemplate() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Retrieve test application
        Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        testACP.Offer_Condition__c = 'test Condition';
        update testACP;
        
        //Query quote offer record
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c, SBQQ__ExpirationDate__c, SBQQ__EndDate__c, 
                                       SBQQ__StartDate__c, Offer_Type__c, SBQQ__PrimaryContact__c, Visa_Start_Date__c, Visa_End_Date__c,
                                       (SELECT Id, SBQQ__ProductFamily__c FROM SBQQ__LineItems__r) 
                                FROM SBQQ__Quote__c
                                LIMIT 1];
        
        Product2 productItem = new Product2(Family = 'Course', Name = 'TestProduct');
        insert productItem;

        //QuoteLineItem Creation
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.id,
                                                                                     Application_Course_Preference__c = testACP.Id, 
                                                                                     Expiry_Date__c = Date.today().addDays(15), 
                                                                                     SBQQ__Product__c = productItem.Id), 
                                                              true)
        }; 

        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name='test-opportunity-course-name', 
                                                      Offer_Type__c = 'OFFER', 
                                                      AccountId = testApplication.Applicant__r.AccountId,
                                                      PrimaryContact__c = testApplication.Applicant__c,
                                                      StageName = 'Signed',
                                                      NextStep = 'Generate Offer',
                                                      CloseDate = Date.Today().addDays(1),
                                                      SBQQ__PrimaryQuote__c = quote.Id,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId());
        insert testOpportunity;
        
        quote.SBQQ__Opportunity2__c = testOpportunity.Id;
        update quote;

        //Start test process
        Test.startTest();
            //Create test contact document
            List<ContentDocument> documentList = new List<ContentDocument>();
            documentList.add(createTestDocument(true, 'pdf'));

            testResultMap = (Map<String, Object>)OfferInternalEmailServices.retrieveOfferEmailTemplate(testOpportunity.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
    }

    @isTest
    static void test_RetrieveOfferEmailTemplateForMUM() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name='test-opportunity-course-name', 
                                                      Offer_Type__c = 'OFFER', 
                                                      AccountId = testApplication.Applicant__r.AccountId,
                                                      PrimaryContact__c = testApplication.Applicant__c,
                                                      StageName = 'Signed',
                                                      NextStep = 'Generate Offer',
                                                      Admission_office_location__c = 'Malaysia',
                                                      CloseDate = Date.Today().addDays(1),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId());
        insert testOpportunity;

        //Start test process
        Test.startTest();
            //Create test contact document
            List<ContentDocument> documentList = new List<ContentDocument>();
            documentList.add(createTestDocument(true, 'pdf'));

            testResultMap = (Map<String, Object>)OfferInternalEmailServices.retrieveOfferEmailTemplate(testOpportunity.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
    }
    
    
    /**
     * @description Tests submitOfferTemplateEmail method
     */
    @isTest
    static void test_SubmitOfferTemplateEmail() {
        //Initialize variables
        Map<String, Object> testResultMap;

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name='test-opportunity-course-name', 
                                                      Offer_Type__c = 'OFFER', 
                                                      AccountId = testApplication.Applicant__r.AccountId,
                                                      PrimaryContact__c = testApplication.Applicant__c,
                                                      StageName = 'Signed',
                                                      NextStep = 'Generate Offer',
                                                      CloseDate = Date.Today().addDays(1),
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId());
        insert testOpportunity;

        //Start test process
        Test.startTest();
            //Create test contact document
            List<ContentDocument> documentList = new List<ContentDocument>();
            documentList.add(createTestDocument(true, 'pdf'));

            testResultMap = (Map<String, Object>)OfferInternalEmailServices.submitOfferTemplateEmail(testOpportunity.Id, 'emailContent', 'testcc@test.com', 'Test Subject',
                            'test text content', 'testfrom@test.com', documentList[0].Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(testResultMap, null);
        System.assertEquals(((String)testResultMap.get('Status')), 'Success');
    }

    /**
     * @description Tests checkSendOfferEmailPermission method
     */
    @isTest
    static void test_CheckSendOfferEmailPermission() {
        Boolean hasAccess = false;
        //Start test process
        Test.startTest();
            hasAccess = (Boolean)OfferInternalEmailServices.checkSendOfferEmailPermission();
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(hasAccess, null);
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

    /**
     * @description Tests sendGCOOfferEmail method
     */
    @isTest
    static void test_sendGCOOfferEmail() {
        //Initialize variables
        Map<String, Object> testResultMap;
		//GIVEN - All the cpq data is set up
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Retrieve test application
        Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        testACP.Offer_Condition__c = 'test Condition';
        update testACP;
        
        //Query quote offer record
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c, SBQQ__ExpirationDate__c, SBQQ__EndDate__c, 
                                       SBQQ__StartDate__c, Offer_Type__c, SBQQ__PrimaryContact__c, Visa_Start_Date__c, Visa_End_Date__c,
                                       (SELECT Id, SBQQ__ProductFamily__c FROM SBQQ__LineItems__r) 
                                FROM SBQQ__Quote__c
                                LIMIT 1];
        
        Product2 productItem = new Product2(Family = 'Course', Name = 'TestProduct');
        insert productItem;

        //QuoteLineItem Creation
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.id,
                                                                                     Application_Course_Preference__c = testACP.Id, 
                                                                                     Expiry_Date__c = Date.today().addDays(15), 
                                                                                     SBQQ__Product__c = productItem.Id), 
                                                              true)
        }; 

        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name='test-opportunity-course-name', 
                                                      Offer_Type__c = 'OFFER', 
                                                      AccountId = testApplication.Applicant__r.AccountId,
                                                      PrimaryContact__c = testApplication.Applicant__c,
                                                      StageName = 'Signed',
                                                      NextStep = 'Generate Offer',
                                                      CloseDate = Date.Today().addDays(1),
                                                      SBQQ__PrimaryQuote__c = quote.Id,
                                                      RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Applicant_Enrolment').getRecordTypeId());
        insert testOpportunity;
        
        quote.SBQQ__Opportunity2__c = testOpportunity.Id;
        update quote;

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();
        documentList.add(createTestDocument(true, 'pdf'));
        
        ContentDocumentLink cdLink = new ContentDocumentLink();
        cdLink.LinkedEntityId = quote.Id;
        cdLink.ContentDocumentId = documentList[0].Id;
        cdLink.ShareType = 'V';
        cdLink.Visibility = 'AllUsers';
        insert cdLink;
		//WHEN - OfferInternalEmailServices.sendGCOOfferEmail is invoke with the quote id
	    Test.startTest();
        OfferInternalEmailServices.sendGCOOfferEmail( new List<String> {quote.Id} );
        Test.stopTest();
        
		//THEN - Verify the process completed successfully
        Assert.areEqual ('Success', +OfferInternalEmailServices.gcoOfferEmaiSendStatus);

    }

    
}