/**
 * @author      Kristian Vegerano
 * @description Test class for DocumentChecklistsSelector class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest/*(isParallel=true) System.TypeException: Test.getStandardPricebookId() cannot be called from parallel Apex tests*/
public with sharing class DocumentChecklistsSelector_Test {
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
        String ENVELOP_ID_1 = 'e1420cb6-7172-4e39-acca-45888ad4e461';
        String ENVELOP_ID_2 = 'e1420cb6-7172-4e39-acca-45888ad4e462';
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'Signed',
                Sub_Status__c = 'In QA Review',
                Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1
            ), false);
        quotes.add(quote1);
        insert quotes;
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
    }

    /**
     * @description Test select document checklist by Id
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        //Create test document checklist records
        Set<Id> documentChecklistId = new Set<Id>();
        for(Document_Checklist__c loopChecklist : (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id)){
            documentChecklistId.add(loopChecklist.Id);
        }

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = new DocumentChecklistsSelector().selectById(documentChecklistId);
        Test.stopTest();

        //Start assertion
        System.assertEquals(applicationDocumentChecklistList.size(), 1);
    }

    /**
     * @description Test select document checklist by application id
     */
    @isTest 
    static void test_SelectApplicationAssessmentByApplicationIds() {
        // Given
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        //Create test document checklist records
        DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        
        // When
        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = new DocumentChecklistsSelector().selectApplicationAssessmentByApplicationIds(new Set<Id>{testApplication.Id});
        Test.stopTest();

        // Then
        //Start assertion
        System.assertEquals(applicationDocumentChecklistList.size(), 1);
    }

    /**
     * @description Test select document checklist with application details
     */
    @isTest 
    static void test_SelectByIdWithApplicationDetails() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        //Create test document checklist records
        Set<Id> documentChecklistId = new Set<Id>();
        for(Document_Checklist__c loopChecklist : (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id)){
            documentChecklistId.add(loopChecklist.Id);
        }

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = new DocumentChecklistsSelector(true).selectByIdWithApplicationDetails(documentChecklistId);
        Test.stopTest();

        //Start assertion
        System.assertEquals(applicationDocumentChecklistList.size(), 1);
    }

    /**
     * @description Test select document checklist with application details
     */
    @isTest 
    static void test_selectOfferAcceptanceByQuoteIds() {
        //Initialize variables
        List<Document_Checklist__c> quoteDocumentChecklistList;

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

        //Query quote offer record
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, SBQQ__Opportunity2__c, SBQQ__Account__c, SBQQ__Partner__c, SBQQ__ExpirationDate__c, SBQQ__EndDate__c, 
                                       SBQQ__StartDate__c, Offer_Type__c, SBQQ__PrimaryContact__c, Visa_Start_Date__c, Visa_End_Date__c,
                                       (SELECT Id, SBQQ__ProductFamily__c FROM SBQQ__LineItems__r) 
                                FROM SBQQ__Quote__c
                                LIMIT 1];
        quote.SBQQ__Opportunity2__c = testOpportunity.Id;
        update quote;
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote .Id;
        update testOpportunity;

        //Create test document checklist records
        DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});

        //Start test process        
        Test.startTest();
            quoteDocumentChecklistList = new DocumentChecklistsSelector(true).selectOfferAcceptanceByQuoteIds(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(quoteDocumentChecklistList.size(), 0);
    }

    /**
     * @description Test select document checklist with application details
     */
    @isTest 
    static void test_selectByApplicationIdAndSequenceNumber() {
        List<Document_Checklist__c> checklist;
        Contact con = [SELECT Id FROM Contact limit 1];
        Application__c app = [SELECT Id FROM Application__c WHERE Applicant__c = :con.Id limit 1];
        //create Contact_Qualification__c
        Map<Id, RecordType> qualifficationType = new Map<Id, RecordType>([SELECT Id FROM RecordType WHERE sObjectType = 'Contact_Qualification__c']);
        List<Contact_Qualification__c> lstCQ = new List<Contact_Qualification__c>();
        for(Id recordTypeId : qualifficationType.keyset()) {
            Contact_Qualification__c cq = new Contact_Qualification__c();
            cq.Contact__c = con.Id;
            cq.RecordTypeId = recordTypeId;
            lstCQ.add(cq);
        }
                
        insert lstCQ;

        // create the apq
        List<Application_Qualification_Provided__c> lstAqp = new List<Application_Qualification_Provided__c>();
        for(Contact_Qualification__c contQual : lstCQ) {
            Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
            aqp.Contact_Qualification__c = contQual.Id;
            aqp.Application__c = app.Id;
            aqp.Sequence_Number__c = 1;
            lstAqp.add(aqp);
        }
        
        insert lstAqp;

        // Create application checklist for visa
        Document_Checklist__c testChecklist = new Document_Checklist__c(
            Application__c = app.Id,
            RecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId(),
            Rule_DeveloperName__c = 'V2_Complete_Tertiary_Education_Check',
            Status__c = 'Requested',
            Unique_ID__c = String.valueOf(Date.today()),
            Document_Request_Type__c = 'MISC-DOC',
            Type__c = 'Qualification'
        );
        insert testChecklist;

        //Start test process        
        Test.startTest();
        checklist = new DocumentChecklistsSelector(true).selectApplicationAssessmentByApplicationIdAndSequenceNumber(app.Id, 'MISC-DOC', null);
        Test.stopTest();

        //Start assertion
        Assert.areNotEqual(checklist.size(), 0, 'there are checklist queried for MISC-DOC');
    }
}