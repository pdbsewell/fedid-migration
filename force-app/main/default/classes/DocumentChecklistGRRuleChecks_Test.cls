/**
 * @author      Vishal Gupta
 * @description Test class for DocumentChecklistRuleChecks class for Graduate Research document checklist
 * @group       Test Class
 * @revision    25/10/2024 - Vishal Gupta - Modified - added the code for existing scholarship
 */
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
public with sharing class DocumentChecklistGRRuleChecks_Test {
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
        
        //start inserting quote
        String envlopId = 'e1420cb6-7172-4e39-acca-45888ad4e461';
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(
            new SBQQ__Quote__c(
                SBQQ__Status__c = 'Signed',
                Sub_Status__c = 'In QA Review',
                Primary_DocuSign_Envelop_Id__c = envlopId,
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
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Awards if added
     */
    @isTest 
    static void testRunEvaluationAwardsCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Awards, Prizes and Scholarships');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchAwardCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchAwardCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();
    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Past experiences
     */
    @isTest 
    static void testRunEvaluationExperienceCheck() {
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Employment and Research Experience');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchExperienceCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchExperienceCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Referees 
     */
    @isTest 
    static void testRunEvaluationRefereeCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Referees');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchRefereeCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchRefereeCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Music 
     */
    @isTest 
    static void testRunEvaluationMusicCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Music');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchMusicCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchMusicCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Publications 
     */
    @isTest 
    static void testRunEvaluationPublicationsCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Publications');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchPublicationCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchPublicationCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Theatre 
     */
    @isTest 
    static void testRunEvaluationTheatreCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Theatre Performance');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchTheatrePerformanceCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchTheatrePerformanceCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Creative Writing 
     */
    @isTest 
    static void testRunEvaluationCreativeWorkCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Creative Works');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchCreativeWorkCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchCreativeWorkCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Exhibition 
     */
    @isTest 
    static void testRunEvaluationExhibitionCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Exhibitions');
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchExhibitionCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchExhibitionCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for CV 
     */
    @isTest 
    static void testRunEvaluationCVCheck() {
        
        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        update testApplication;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.CurriculumVitaeCheck evaluatorInstance = new DocumentChecklistRuleChecks.CurriculumVitaeCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Equity Scholarship 
     */
    @isTest 
    static void testRunEquityScholarshipCheck() {
        
        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        testApplication.Apply_for_Equity_Scholarship__c = true;
        update testApplication;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.EquityScholarshipCheck evaluatorInstance = new DocumentChecklistRuleChecks.EquityScholarshipCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Agent 
     */
    @isTest 
    static void testRunEvaluationAgentCheck() {
        AgentPortalTestDataFactory apFactory = new AgentPortalTestDataFactory();
        Country_Attribute__c cAttr = apFactory.createCountryAttribute(BDPConstants.AUSTRALIA_CALLISTA_CODE, 'AUSTRALIA');
        insert cAttr;

        Account agency = apFactory.createAgencyAccount(cAttr);
        agency.Name = 'Test Agent';
        insert agency;
        
        //Retrieve test application
        Application__c testApplication = [SELECT Id, AgentName__c, Agent__c, Applicant_Agent__c FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        testApplication.Agent__c = agency.Id;
        testApplication.Applicant_Agent__c = 'Yes';
        update testApplication;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.AgentCheck evaluatorInstance = new DocumentChecklistRuleChecks.AgentCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for English test 
     */
    @isTest 
    static void testRunEvaluationEnglistTestCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'English Test');
        contactQualification.English_Proficiency__c = 'ENG-STUDY';
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.EnglishEvidenceTestCheck evaluatorInstance = new DocumentChecklistRuleChecks.EnglishEvidenceTestCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

   /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Miscl Docs 
     */
    @isTest 
    static void testRunEvaluationMiscTestCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Other Qualification');
        contactQualification.Title_of_Publication_Work_Chapter_Paper__c = 'Test';
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GraduateResearchMiscCheck evaluatorInstance = new DocumentChecklistRuleChecks.GraduateResearchMiscCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    } 

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Research Invitation 
     */
    @isTest 
    static void testRunEvaluationResearchInvitationCheck() {
                
        //Retrieve test application
        Application__c testApplication = [SELECT Id, AgentName__c, Agent__c FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        update testApplication ;
        //updating ACP
        Application_Course_Preference__c acp = [SELECT Research_Title__c, Graduate_Research_Application_Type__c FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        acp.Research_Title__c = 'Test';
        acp.Graduate_Research_Application_Type__c = 'Admission';
        update acp;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.ResearchProgramInvitationDetails evaluatorInstance = new DocumentChecklistRuleChecks.ResearchProgramInvitationDetails();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Research Proposal 
     */
    @isTest 
    static void testRunEvaluationResearchProposalCheck() {
                
        //Retrieve test application
        Application__c testApplication = [SELECT Id, AgentName__c, Agent__c FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        update testApplication;

        //updating ACP
        Application_Course_Preference__c acp = [SELECT Research_Title__c, Graduate_Research_Application_Type__c FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        acp.Research_Title__c = 'Test';
        acp.Graduate_Research_Application_Type__c = 'Admission';
        update acp;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.ResearchProgramResearchProposal evaluatorInstance = new DocumentChecklistRuleChecks.ResearchProgramResearchProposal();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Research Supervisor Form 
     */
    @isTest 
    static void testRunEvaluationResearchSupervisorFormCheck() {
                
        //Retrieve test application
        Application__c testApplication = [SELECT Id, AgentName__c, Agent__c FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        update testApplication;

        //update ACP
        Application_Course_Preference__c acp = [SELECT External_Supervisor__c, Graduate_Research_Application_Type__c FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        acp.External_Supervisor__c = true;
        acp.Graduate_Research_Application_Type__c = 'Admission';
        update acp;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.ResearchProgramSupervisorForm evaluatorInstance = new DocumentChecklistRuleChecks.ResearchProgramSupervisorForm();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Research Sponsorship Letter 
     */
    @isTest 
    static void testRunEvaluationResearchSposorshipLetterCheck() {
                
        //Retrieve test application
        Application__c testApplication = [SELECT Id, AgentName__c, Agent__c FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        update testApplication;
        //update ACP
        Application_Course_Preference__c acp = [SELECT External_Funding__c, Graduate_Research_Application_Type__c FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        acp.External_Funding__c = true;
        acp.Graduate_Research_Application_Type__c = 'Admission';
        update acp;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.ResearchProgramSponsorshipLetter evaluatorInstance = new DocumentChecklistRuleChecks.ResearchProgramSponsorshipLetter();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Research Attendance Commitments 
     */
    @isTest 
    static void testRunEvaluationResearchAppointmentCheck() {
                
        //Retrieve test application
        Application__c testApplication = [SELECT Id, AgentName__c, Agent__c FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        update testApplication;
        //update ACP
        Application_Course_Preference__c acp = [SELECT Employment_During_Research__c, Graduate_Research_Application_Type__c FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        acp.Employment_During_Research__c = true;
        acp.Graduate_Research_Application_Type__c = 'Admission';
        update acp;
        
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.ResearchProgramAppointmentCommitments evaluatorInstance = new DocumentChecklistRuleChecks.ResearchProgramAppointmentCommitments();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Sethu Venna
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Previous Research Degree or Scholarship
     */
    @isTest 
    static void testPreviousResearchDegreeOrScholarshipCheck() {

        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        Application_Course_Preference__c acp = [SELECT Id, Has_Previous_Res_Degree_or_Scholarship__c 
                                                FROM Application_Course_Preference__c 
                                                WHERE Application__c = :testApplication.Id LIMIT 1];
        acp.Has_Previous_Res_Degree_or_Scholarship__c = true;
        update acp;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.PreviousResearchDegreeOrScholarshipCheck evaluatorInstance = new DocumentChecklistRuleChecks.PreviousResearchDegreeOrScholarshipCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(acp);
            Assert.areEqual(ruleResult, true, 'evaluation criteria should pass for the checklist rule');
        }
        Test.stopTest();
    }

    /**
     * @author      Vishal Gupta
     * @description
     * GIVEN a new graduate research student is registered for my.app
     * WHEN student is logging an application on my.app
     * THEN system tests the document checklist for Existing Research Sponsorship Letter 
     */
    @isTest 
    static void testRunEvaluationExistingSposorshipCheck() {
                
        //Retrieve test application
        Application__c testApplication = [SELECT Id, AgentName__c, Agent__c FROM Application__c LIMIT 1];
        testApplication.Type_Of_Study__c = 'Graduate Research';
        update testApplication;
        //update ACP
        Application_Course_Preference__c acp = [SELECT Applied_for_External_Scholarship_Name__c, Graduate_Research_Application_Type__c FROM Application_Course_Preference__c WHERE Application__c = :testApplication.Id LIMIT 1];
        acp.Applied_for_External_Scholarship_Name__c = 'test';
        acp.Graduate_Research_Application_Type__c = 'Admission';
        update acp;
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.ResearchProgramExistingSponsorshipLetter evaluatorInstance = new DocumentChecklistRuleChecks.ResearchProgramExistingSponsorshipLetter();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(testApplication);
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description graduate research application completed english test checklist check 
     */
    @isTest 
    static void testRunEvaluationCompletedEnglistTestCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //GIVEN a new graduate research student is registered for my.app
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'English Test');
        contactQualification.English_Proficiency__c = 'ENG-STUDY';
        contactQualification.Date_Achieved__c = Date.Today().addDays(-10);
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;
        
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();

        //WHEN student is logging an application on my.app
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GRCompleteEnglishTestCheck evaluatorInstance = new DocumentChecklistRuleChecks.GRCompleteEnglishTestCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            //THEN system tests the document checklist for completed English test
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    }

    /**
     * @author      Vishal Gupta
     * @description graduate research application qualification checklist check
     */
    @isTest 
    static void testRunEvaluationTertiaryEducationTestCheck() {
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //GIVEN a new graduate research student is registered for my.app
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Qualification__c testQual = StudFirst_TestHelper.createQualification('test');
        insert testQual;
        Contact_Qualification__c contactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQual, 'Tertiary Education');
        contactQualification.Evidence_Type__c = 'POST-DIP';
        insert contactQualification;

        Application_Qualification_Provided__c testAppQualification = new Application_Qualification_Provided__c();
        testAppQualification.Application__c = testApplication.Id;
        testAppQualification.Contact_Qualification__c = contactQualification.Id;
        insert testAppQualification;

        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        //Start test process        
        Test.startTest();

        //WHEN student is logging an application on my.app
        System.runAs(communityApplicant) {
            DocumentChecklistRuleChecks.GRTertiaryQualificationCheck evaluatorInstance = new DocumentChecklistRuleChecks.GRTertiaryQualificationCheck();
            Boolean ruleResult = evaluatorInstance.evaluateCriteria(contactQualification);
            //THEN system tests the document checklist for Tertiary Education
            Assert.areEqual(ruleResult, true, 'evaluation criteria is passed for the checklist rule');
        }
        Test.stopTest();

    } 
}