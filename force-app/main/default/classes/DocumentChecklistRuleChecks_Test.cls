/**
 * @author      Kristian Vegerano
 * @description Test class for DocumentChecklistRuleChecks class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
public with sharing class DocumentChecklistRuleChecks_Test {
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

        //Create test agency
        Account agencyRecord = new Account();
        agencyRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency').getRecordTypeId();
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
        //Ensure that this is stamped with the latest default document checklist rule version
        //Additionally, stamp the rules with the previous latest document checklist rule version if you're deprecating rules
        // - see age check as an example. only active on version 1
        testApplication.Assessment_Checklist_Version__c = 'Assessment Version 2';
        insert testApplication;

        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        testCourse.Faculty_Description__c = 'Faculty of Art, Design and Architecture';
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
        String env1 = 'e1420cb6-7172-4e39-acca-45888ad4e461';
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'Signed',
                Sub_Status__c = 'In QA Review',
                Primary_DocuSign_Envelop_Id__c = env1,
                SBQQ__StartDate__c = System.TODAY().addDays(1),
                SBQQ__PrimaryContact__c = testContact.Id
            ), false);
        quotes.add(quote1);
        insert quotes;
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');

        //Create test course prerequisite
        List<Course_Specific_Document__c> courseSpecificDocumentList = new List<Course_Specific_Document__c>();
        // add course related prerequisite
        courseSpecificDocumentList.add(new Course_Specific_Document__c(Name = 'Course Prerequisite',
                                                              IsActive__c = true,
                                                              Course__c = testCourse.Id,
                                                              Instruction__c = 'Test Course Instruction'));
        // add faculty related prerequisite
        courseSpecificDocumentList.add(new Course_Specific_Document__c(Name = 'Faculty Prerequisite',
                                                              IsActive__c = true,
                                                              Faculty_Name__c = 'Faculty of Art, Design and Architecture',
                                                              Instruction__c = 'Test Faculty Instruction'));
        insert courseSpecificDocumentList;
    }

    /**
     * @description Test running document checklist satisfying previous name rule check
     */
    @isTest 
    static void test_RunEvaluation_PreviousName() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure previous name and age check rules */
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        testApplicant.Previous_Surname__c = 'OldName';
        update testApplicant;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Name Change' 
                                                        AND Active__c = true
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer nameChangeDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Name Change' 
                                                        AND Application__c = :testApplication.Id]){
            nameChangeDocumentChecklistCount = nameChangeDocumentChecklistCount + 1;
        }
        Assert.areEqual(nameChangeDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying age rule check
     */
    @isTest 
    static void test_RunEvaluation_AgeCheck_Draft() {
        //Initialize variables
        String ruleVersion = 'Assessment Version 1';
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        testApplication.Residency_Status__c = 'INTRNTNL';
        testApplication.Assessment_Checklist_Version__c = ruleVersion;
        update testApplication;
        
        /* Configure previous name and age check rules */
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        testApplicant.Birthdate = System.TODAY().addYears(-17);
        update testApplicant;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Age' 
                                                        AND Active__c = true
                                                        AND Version__r.MasterLabel = :ruleVersion]){
            ruleCount = ruleCount + 1;
        }
        Integer ageDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Age' 
                                                        AND Application__c = :testApplication.Id]){
            ageDocumentChecklistCount = ageDocumentChecklistCount + 1;
        }
        Assert.areEqual(ageDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying age rule check
     */
    @isTest 
    static void test_RunEvaluation_AgeCheck_Submitted() {
        //Initialize variables
        String ruleVersion = 'Assessment Version 1';
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        testApplication.Residency_Status__c = 'INTRNTNL';
        testApplication.Submitted_Date__c = System.TODAY().addYears(-17);
        testApplication.Assessment_Checklist_Version__c = ruleVersion;
        update testApplication;

        /* Configure previous name and age check rules */
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];
        testApplicant.Birthdate = System.TODAY().addYears(-17);
        update testApplicant;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Age' 
                                                        AND Active__c = true
                                                        AND Version__r.MasterLabel = :ruleVersion]){
            ruleCount = ruleCount + 1;
        }
        Integer ageDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Age' 
                                                        AND Application__c = :testApplication.Id]){
            ageDocumentChecklistCount = ageDocumentChecklistCount + 1;
        }
        Assert.areEqual(ageDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying credit intention rule check
     */
    @isTest 
    static void test_RunEvaluation_CreditCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        
        /* Configure credit check rule */
        testApplication.Credit_Intention__c = true;

        //Commit test applications
        update testApplication;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Credit' 
                                                        AND Active__c = true
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer creditCheckDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Credit' 
                                                        AND Application__c = :testApplication.Id]){
            creditCheckDocumentChecklistCount = creditCheckDocumentChecklistCount + 1;
        }
        Assert.areEqual(creditCheckDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying visa rule check
     */
    @isTest 
    static void test_RunEvaluation_VisaCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure visa rule */
        testApplication.Refused_entry_visa_to_any_country__c = 'Yes';
        testApplication.Breached_visa_condition__c = 'Yes';
        testApplication.Medical_health_prevent_visa__c = 'Yes';
        testApplication.Protection_visa_in_any_country__c = 'Yes';
        testApplication.Convicted_of_crime_offence__c = 'Yes';

        //Commit test applications
        update testApplication;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id, Version__r.Category__c  
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Visa' 
                                                        AND Active__c = true
                                                        AND Version__r.Default__c = true
                                                        AND Criteria__c = 'VisaCheck']){
            if(loopRule.Version__r.Category__c == 'Application Assessment'){
                ruleCount = ruleCount + 1;
            }
        }
        Integer visaDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Visa' 
                                                        AND Application__c = :testApplication.Id
                                                        AND Opportunity__c = null]){
            visaDocumentChecklistCount = visaDocumentChecklistCount + 1;
        }
        Assert.areEqual(visaDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying complete secondary qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_CompleteSecondaryCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure complete secondary qualification rule */
        Qualification__c testCompleteSecondaryQualification = StudFirst_TestHelper.createQualification('Complete Secondary');
        insert testCompleteSecondaryQualification;
        
        Contact_Qualification__c testContactCompleteSecondaryQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testCompleteSecondaryQualification, 'Secondary Education');
        testContactCompleteSecondaryQualification.Year_of_Completion__c = '2000';
        insert testContactCompleteSecondaryQualification;

        Application_Qualification_Provided__c testContactCompleteSecondaryQualificationProvided = new Application_Qualification_Provided__c();
        testContactCompleteSecondaryQualificationProvided.Application__c = testApplication.Id;
        testContactCompleteSecondaryQualificationProvided.Contact_Qualification__c = testContactCompleteSecondaryQualification.Id;
        insert testContactCompleteSecondaryQualificationProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Qualification' 
                                                        AND Active__c = true
                                                        AND Criteria__c = 'CompleteSecondaryQualificationCheck'
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer completeSecondaryDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Qualification' 
                                                        AND Contact_Qualification__c = :testContactCompleteSecondaryQualification.Id]){
            completeSecondaryDocumentChecklistCount = completeSecondaryDocumentChecklistCount + 1;
        }
        Assert.areEqual(completeSecondaryDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying complete secondary qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_IncompleteSecondaryCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure incomplete secondary qualification rule */
        Qualification__c testIncompleteSecondaryQualification = StudFirst_TestHelper.createQualification('Incomplete Secondary');
        insert testIncompleteSecondaryQualification;
        
        Contact_Qualification__c testContactIncompleteSecondaryQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testIncompleteSecondaryQualification, 'Secondary Education');
        insert testContactIncompleteSecondaryQualification;

        Application_Qualification_Provided__c testContactIncompleteSecondaryQualificationProvided = new Application_Qualification_Provided__c();
        testContactIncompleteSecondaryQualificationProvided.Application__c = testApplication.Id;
        testContactIncompleteSecondaryQualificationProvided.Contact_Qualification__c = testContactIncompleteSecondaryQualification.Id;
        insert testContactIncompleteSecondaryQualificationProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Qualification' 
                                                        AND Active__c = true
                                                        AND Criteria__c = 'IncompleteSecondaryQualificationCheck'
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer incompleteSecondaryDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Qualification' 
                                                        AND Contact_Qualification__c = :testContactIncompleteSecondaryQualification.Id]){
            incompleteSecondaryDocumentChecklistCount = incompleteSecondaryDocumentChecklistCount + 1;
        }
        Assert.areEqual(incompleteSecondaryDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying complete english qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_CompleteEnglishCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure complete english qualification rule */
        Qualification__c testCompleteEnglishQualification = StudFirst_TestHelper.createQualification('Complete English');
        insert testCompleteEnglishQualification;
        
        Contact_Qualification__c testContactCompleteEnglishQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testCompleteEnglishQualification, 'English Test');
        testContactCompleteEnglishQualification.Date_Achieved__c = System.TODAY().addYears(-4);
        insert testContactCompleteEnglishQualification;

        Application_Qualification_Provided__c testContactCompleteEnglishQualificationProvided = new Application_Qualification_Provided__c();
        testContactCompleteEnglishQualificationProvided.Application__c = testApplication.Id;
        testContactCompleteEnglishQualificationProvided.Contact_Qualification__c = testContactCompleteEnglishQualification.Id;
        insert testContactCompleteEnglishQualificationProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Qualification' 
                                                        AND Active__c = true
                                                        AND Criteria__c = 'CompleteEnglishTestCheck'
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer completeEnglishDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Qualification' 
                                                        AND Contact_Qualification__c = :testContactCompleteEnglishQualification.Id]){
            completeEnglishDocumentChecklistCount = completeEnglishDocumentChecklistCount + 1;
        }
        Assert.areEqual(completeEnglishDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying incomplete english qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_IncompleteEnglishCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure incomplete english qualification rule */
        Qualification__c testIncompleteEnglishQualification = StudFirst_TestHelper.createQualification('Incomplete English');
        insert testIncompleteEnglishQualification;
        
        Contact_Qualification__c testContactIncompleteEnglishQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testIncompleteEnglishQualification, 'English Test');
        testContactIncompleteEnglishQualification.Expected_date_of_completion__c = System.TODAY().addYears(1);
        insert testContactIncompleteEnglishQualification;

        Application_Qualification_Provided__c testContactIncompleteEnglishQualificationProvided = new Application_Qualification_Provided__c();
        testContactIncompleteEnglishQualificationProvided.Application__c = testApplication.Id;
        testContactIncompleteEnglishQualificationProvided.Contact_Qualification__c = testContactIncompleteEnglishQualification.Id;
        insert testContactIncompleteEnglishQualificationProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Qualification' 
                                                        AND Active__c = true
                                                        AND Criteria__c = 'IncompleteEnglishTestCheck'
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer incompleteEnglishDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Qualification' 
                                                        AND Contact_Qualification__c = :testContactIncompleteEnglishQualification.Id]){
            incompleteEnglishDocumentChecklistCount = incompleteEnglishDocumentChecklistCount + 1;
        }
        Assert.areEqual(incompleteEnglishDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying tertiary non-monash qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_TertiaryCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure tertiary qualification rule */
        Qualification__c testTertiaryQualification = StudFirst_TestHelper.createQualification('Tertiary');
        insert testTertiaryQualification;
        
        Contact_Qualification__c testContactTertiaryQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testTertiaryQualification, 'Tertiary Education');
        insert testContactTertiaryQualification;

        Application_Qualification_Provided__c testContactTertiaryQualificationProvided = new Application_Qualification_Provided__c();
        testContactTertiaryQualificationProvided.Application__c = testApplication.Id;
        testContactTertiaryQualificationProvided.Contact_Qualification__c = testContactTertiaryQualification.Id;
        insert testContactTertiaryQualificationProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Qualification' 
                                                        AND Active__c = true
                                                        AND Criteria__c = 'CompleteTertiaryQualificationCheck'
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer tertiaryDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Qualification' 
                                                        AND Contact_Qualification__c = :testContactTertiaryQualification.Id]){
            tertiaryDocumentChecklistCount = tertiaryDocumentChecklistCount + 1;
        }
        Assert.areEqual(tertiaryDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying tertiary monash qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_MonashTertiaryCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure monash tertiary qualification rule */
        Qualification__c testMonashTertiaryQualification = StudFirst_TestHelper.createQualification('Monash Tertiary');
        insert testMonashTertiaryQualification;
        
        Contact_Qualification__c testContactMonashTertiaryQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testMonashTertiaryQualification, 'Tertiary Education');
        testContactMonashTertiaryQualification.Institution_Name__c = 'Monash Tertiary';
        insert testContactMonashTertiaryQualification;

        Application_Qualification_Provided__c testContactMonashTertiaryQualificationProvided = new Application_Qualification_Provided__c();
        testContactMonashTertiaryQualificationProvided.Application__c = testApplication.Id;
        testContactMonashTertiaryQualificationProvided.Contact_Qualification__c = testContactMonashTertiaryQualification.Id;
        insert testContactMonashTertiaryQualificationProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer monashTertiaryDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Qualification' 
                                                        AND Contact_Qualification__c = :testContactMonashTertiaryQualification.Id]){
            monashTertiaryDocumentChecklistCount = monashTertiaryDocumentChecklistCount + 1;
        }
        //Expect no tertiary education document checklist created because the qualification is a Monash Tertiary Qualification
        Assert.areEqual(monashTertiaryDocumentChecklistCount, 0);
    }

    /**
     * @description Test running document checklist satisfying other qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_OtherCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        /* Configure tertiary qualification rule */
        Qualification__c testOtherQualification = StudFirst_TestHelper.createQualification('Other');
        insert testOtherQualification;
        
        Contact_Qualification__c testContactOtherQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testOtherQualification, 'Other Qualification');
        insert testContactOtherQualification;

        Application_Qualification_Provided__c testContactOtherQualificationProvided = new Application_Qualification_Provided__c();
        testContactOtherQualificationProvided.Application__c = testApplication.Id;
        testContactOtherQualificationProvided.Contact_Qualification__c = testContactOtherQualification.Id;
        insert testContactOtherQualificationProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();

        //Start assertion
        Integer ruleCount = 0;
        for(Document_Checklist_Rule__mdt loopRule : [SELECT Id 
                                                     FROM Document_Checklist_Rule__mdt 
                                                     WHERE Type__c = 'Qualification' 
                                                        AND Active__c = true
                                                        AND Criteria__c = 'OtherQualificationCheck'
                                                        AND Version__r.Default__c = true]){
            ruleCount = ruleCount + 1;
        }
        Integer otherDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Qualification' 
                                                        AND Contact_Qualification__c = :testContactOtherQualification.Id]){
            otherDocumentChecklistCount = otherDocumentChecklistCount + 1;
        }
        Assert.areEqual(otherDocumentChecklistCount, ruleCount);
    }

    /**
     * @description Test running document checklist satisfying other qualification rule check
     */
    @isTest 
    static void test_RunEvaluation_WorkExperienceCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        //Create a work experience for the test application
        Work_Experience__c testWorkExperience = StudFirst_TestHelper.createWorkExperience(testApplicant);
        insert testWorkExperience;
        Application_Work_Experience_Provided__c testApplicationWorkExperienceProvided = StudFirst_TestHelper.createAppWorkExpProvided(testApplication.Id, testWorkExperience.Id);
        insert testApplicationWorkExperienceProvided;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();
         
        //Start assertion
        Integer workExperienceDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Work Experience' 
                                                        AND Work_Experience__c = :testWorkExperience.Id]){
            workExperienceDocumentChecklistCount = workExperienceDocumentChecklistCount + 1;
        }
        Assert.areEqual(workExperienceDocumentChecklistCount, 0);
    }

     /**
     * @description Test running document checklist satisfying unit prerequisite rule check
     */
    @isTest 
    static void test_RunEvaluation_UnitPrerequisiteCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        testApplication.Has_Unit_Prerequisite__c = true;
        update testApplication;

        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();
         
        //Start assertion
        Integer unitPrerequisiteDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Unit Prerequisite']){
            unitPrerequisiteDocumentChecklistCount = unitPrerequisiteDocumentChecklistCount + 1;
        }
        Assert.areEqual(unitPrerequisiteDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist satisfying course prerequisite rule check
     */
    @isTest 
    static void test_RunEvaluation_CoursePrerequisiteCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        update testApplication;
        
        //Start test process        
        Test.startTest();        
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();
         
        //Start assertion
        Integer coursePrerequisiteDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Residency']){
            coursePrerequisiteDocumentChecklistCount = coursePrerequisiteDocumentChecklistCount + 1;
        }
        Assert.areEqual(1, coursePrerequisiteDocumentChecklistCount);
    }

    /**
     * @description Test running document checklist satisfying course prerequisite rule check
     */
    @isTest 
    static void test_RunEvaluation_FacultyPrerequisiteCheck() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        update testApplication;
        
        //Start test process        
        Test.startTest();
            applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
        Test.stopTest();
         
        //Start assertion
        Integer facultyPrerequisiteDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Residency']){
            facultyPrerequisiteDocumentChecklistCount = facultyPrerequisiteDocumentChecklistCount + 1;
        }
        Assert.areEqual(1, facultyPrerequisiteDocumentChecklistCount);
    }

    /**
     * @description Test running document checklist offer acceptance payment rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_AcceptancePaymentProofCheck() {
        //Initialize variables
        
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
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity;
        
        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer paymentProofDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Payment' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            paymentProofDocumentChecklistCount = paymentProofDocumentChecklistCount  + 1;
        }
        //Expect a single acceptance payment proof check has been created
        Assert.areEqual(paymentProofDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist guardian signature rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_GuardianSignatureCheck() {
        //Initialize variables
        
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        /* Configure previous name and age check rules */
        Contact testApplicant = [SELECT Id FROM Contact WHERE Id = :testApplication.Applicant__c LIMIT 1];
        testApplicant.Birthdate = System.TODAY().addYears(-1);
        update testApplicant;

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
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity; 

        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer guardianSignatureDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Contract' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            guardianSignatureDocumentChecklistCount = guardianSignatureDocumentChecklistCount  + 1;
        }
        //Expect a single guardian signature check has been created
        Assert.areEqual(guardianSignatureDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist meeting condition rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_MeetingConditionCheck() {
        //Initialize variables
        List<Document_Checklist__c> quoteDocumentChecklistList;
        Pricebook2 pb = [SELECT Id, External_ID__c FROM Pricebook2 WHERE isStandard = FALSE LIMIT 1];
        PriceBookEntry[] pbes = [SELECT Id, External_ID__c, Product2.Name FROM PriceBookEntry WHERE Pricebook2Id =: pb.id ORDER BY Product2.Course__r.Name];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        //Retrieve test application
        Application_Course_Preference__c testACP = [SELECT Id FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        testACP.Offer_Condition__c = 'test Condition';
        update testACP;
        //Start test process        
        Test.startTest();
        
        //Create test opportunity
        Opportunity testOpportunity = new Opportunity(Name='test-opportunity-course-name', 
                                                      Offer_Type__c = 'COND-OFFER', 
                                                      AccountId = testApplication.Applicant__r.AccountId,
                                                      PrimaryContact__c = testApplication.Applicant__c,
                                                      StageName = 'Signed',
                                                      NextStep = 'Generate Offer',
                                                      CloseDate = Date.Today().addDays(1),
                                                      Pricebook2Id = pb.Id,
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
        
        Product2[] bundles = new Product2[0];
        bundles.add((Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashUniBundleDefaults', false));
        insert bundles;
        
        //QuoteLineItem Creation
        SBQQ__QuoteLine__c[] qlis = new SBQQ__QuoteLine__c[]{
            (SBQQ__QuoteLine__c)TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.id,
                                                                                     Application_Course_Preference__c = testACP.Id, 
                                                                                     Expiry_Date__c = Date.today().addDays(15), 
                                                                                     SBQQ__Product__c = bundles[0].Id), 
                                                              true)
        }; 

        //OpportunityLineItem Creation
        List<OpportunityLineItem> oppList = new List<OpportunityLineItem>{
            (OpportunityLineItem)TestDataFactory.createSObject(new OpportunityLineItem(OpportunityId = testOpportunity.id,  
                                                                                       PricebookEntryId= pbes[0].id,
                                                                                       Application_Course_Preference__c = testACP.Id, 
                                                                                       Expiry_Date__c = Date.today().addDays(15), 
                                                                                       Product2Id = bundles[0].Id), 
                                                              true)
        }; 

        
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer meetingConditionDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Offer Conditions' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            meetingConditionDocumentChecklistCount = meetingConditionDocumentChecklistCount  + 1;
        }
        //Expect a single meeting condition check has been created
        Assert.areEqual(meetingConditionDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist Underage Welfare Accomodation rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_UnderageWelfareAccomodationCheck() {
        //Initialize variables
        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];

        /* Configure previous name and age check rules */
        Contact testApplicant = [SELECT Id FROM Contact WHERE Id = :testApplication.Applicant__c LIMIT 1];
        testApplicant.Birthdate = System.TODAY().addYears(-1);
        update testApplicant;

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
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity;

        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer underageWelfareDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Under 18' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            underageWelfareDocumentChecklistCount = underageWelfareDocumentChecklistCount  + 1;
        }
        //Expect a single guardian signature check has been created
        Assert.areEqual(underageWelfareDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist OHSC Health Cover rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_OhscHealthCoverCheck() {
        //Initialize variables
        
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
        quote.Health_Cover_Provider_Type__c = 'Student Nominated';
        update quote; 
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity;     

        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer ohscHealthCoverDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'OSHC' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            ohscHealthCoverDocumentChecklistCount = ohscHealthCoverDocumentChecklistCount  + 1;
        }
        //Expect a single guardian signature check has been created
        Assert.areEqual(ohscHealthCoverDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist Visa Additional Info rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_VisaAdditionalInfoCheck() {
        //Initialize variables
        
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
                                                      Is_Visa_document_provided__c = 'Yes - Additional information required',
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
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity;   

        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer visaAdditionalDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Visa' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            visaAdditionalDocumentChecklistCount = visaAdditionalDocumentChecklistCount  + 1;
        }
        //Expect a single visa additional details check has been created
        Assert.areEqual(visaAdditionalDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist Visa Confirm Info rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_VisaConfirmCheck() {
        //Initialize variables
        
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
                                                      Is_Visa_document_provided__c = 'No',
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
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity;    

        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer visaConfirmDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Visa' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            visaConfirmDocumentChecklistCount = visaConfirmDocumentChecklistCount  + 1;
        }
        //Expect a single visa confirmation check has been created
        Assert.areEqual(visaConfirmDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist Passport Additional Info rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_PassportAdditionalInfoCheck() {
        //Initialize variables
        
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
                                                      Is_passport_document_provided__c = 'Yes - Additional information required',
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
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity;

        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer passportAdditionalDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Residency' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            passportAdditionalDocumentChecklistCount = passportAdditionalDocumentChecklistCount  + 1;
        }
        //Expect a single passport additional details check has been created
        Assert.areEqual(passportAdditionalDocumentChecklistCount, 1);
    }

    /**
     * @description Test running document checklist Passport Confirm Info rule check
     */
    @isTest 
    static void test_RunEvaluation_OfferAcceptance_PassportConfirmCheck() {
        //Initialize variables
        
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
                                                      Is_passport_document_provided__c = 'No',
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
        
        testOpportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update testOpportunity;    

        //Start test process        
        Test.startTest();
            //Create test document checklist records
            DocumentChecklistAcceptanceServices.runAcceptanceChecklistRules(new Set<Id>{testOpportunity.Id});
        Test.stopTest();

        //Start assertion
        Integer passportConfirmDocumentChecklistCount = 0;
        for(Document_Checklist__c loopChecklist : [SELECT Id 
                                                   FROM Document_Checklist__c 
                                                   WHERE Type__c = 'Residency' 
                                                        AND Opportunity__c = :testOpportunity.Id]){
            passportConfirmDocumentChecklistCount = passportConfirmDocumentChecklistCount  + 1;
        }
        //Expect a single passport confirmation check has been created
        Assert.areEqual(passportConfirmDocumentChecklistCount, 1);
    }
}