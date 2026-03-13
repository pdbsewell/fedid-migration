/**
 * @author      Kristian Vegerano
 * @description Test class for DocumentChecklistRuleServices class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
public with sharing class DocumentChecklistRuleServices_Test {
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

        /* Configure complete secondary qualification rule */
        Qualification__c testCompleteSecondaryQualification = StudFirst_TestHelper.createQualification('Complete Secondary');
        insert testCompleteSecondaryQualification;
        
        Contact_Qualification__c testContactCompleteSecondaryQualification = StudFirst_TestHelper.createContactQualification(testContact, testCompleteSecondaryQualification, 'Secondary Education');
        testContactCompleteSecondaryQualification.Year_of_Completion__c = '2000';
        insert testContactCompleteSecondaryQualification;

        Application_Qualification_Provided__c testContactCompleteSecondaryQualificationProvided = new Application_Qualification_Provided__c();
        testContactCompleteSecondaryQualificationProvided.Application__c = testApplication.Id;
        testContactCompleteSecondaryQualificationProvided.Contact_Qualification__c = testContactCompleteSecondaryQualification.Id;
        insert testContactCompleteSecondaryQualificationProvided;

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
     * @description Tests document checklist's evaluate rules
     */
    @isTest 
    static void test_EvaluateRules() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        
        //Start test process        
	 	Test.startTest();
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{testApplication.Id});
            rulesDocChecklistEngine.evaluateRules('Application Assessment');

            //Retrieve checklist items
            applicationDocumentChecklistList = rulesDocChecklistEngine.resultChecklistItemsMap.get(testApplication.Id).values();
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(applicationDocumentChecklistList.size(), 2);
    }

    /**
     * @description Tests document checklist's evaluate rules
     */
    @isTest 
    static void test_EvaluateOfferAcceptanceRules() {
        //Initialize variables
        List<Document_Checklist__c> quoteDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c, Applicant__r.AccountId FROM Application__c LIMIT 1];
        
        //Start test process        
        Test.startTest();
         
            //Create test opportunity
            Opportunity testOpportunity = new Opportunity(Name = 'test-opportunity-course-name', 
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
        
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{testOpportunity.Id});
            rulesDocChecklistEngine.evaluateRules('Offer Acceptance');

            //Retrieve checklist items
            quoteDocumentChecklistList = rulesDocChecklistEngine.resultChecklistItemsMap.get(testOpportunity.Id).values();
	 	Test.stopTest();

        //Start assertion
        System.assertNotEquals(quoteDocumentChecklistList.size(), 0);
    }

    /**
     * @description Tests document checklist's evaluate rules
     */
    @isTest 
    static void test_EvaluateRulesCancelIrrelevant() {
        //Initialize variables
        List<Document_Checklist__c> applicationDocumentChecklistList;

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        
        //Start test process        
        Test.startTest();         
            insert new Document_Checklist__c(Application__c = testApplication.Id,
                                            Contact__c = testApplication.Applicant__c,
                                            Allowed_Document_Type__c = 'OTHERDCTYP',
                                            Applicant_Instructions_Email__c = 'test',
                                            Applicant_Instructions_UI__c = 'test',
                                            Checklist_Requirement__c = 'Course Requirements',
                                            Sort_Order__c = 65,
                                            Status__c = 'Requested',
                                            Type__c = 'Course',
                                            Unique_ID__c =  testApplication.Id + '-Course-Manual',
                                            RecordTypeId = Schema.SObjectType.Document_Checklist__c.getRecordTypeInfosByDeveloperName().get('Application_Assessment').getRecordTypeId());

            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{testApplication.Id});
            rulesDocChecklistEngine.evaluateRules('Application Assessment');

            //Retrieve checklist items
            applicationDocumentChecklistList = rulesDocChecklistEngine.resultChecklistItemsMap.get(testApplication.Id).values();
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(applicationDocumentChecklistList.size(), 3);
    }

    /**
     * @description Tests retrieveChecklistItemsEmailInstructions method for retrieving document checklist email details
     */
    @isTest 
    static void test_RetrieveChecklistItemsEmailInstructions() {
        //Initialize variables
        List<String> emailInstructions;

        //Retrieve test application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        
        //Start test process        
	 	Test.startTest();
            //Retrieve checklist items        
            List<Document_Checklist__c> applicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
            //Create test document checklist comment
            insert new Document_Checklist_Comment__c(Document_Checklist__c = applicationDocumentChecklistList[0].Id,
                                                     Content__c = 'Test Comment');
        
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{testApplication.Id});
            rulesDocChecklistEngine.evaluateRules('Application Assessment');
            emailInstructions = rulesDocChecklistEngine.retrieveChecklistItemsEmailInstructions(testApplication.Id);
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(emailInstructions.size(), 4);
    }

    /**
     * @description Tests retrieveCompleteChecklistItemsEmailInstructions method for retrieving completed document checklist email details
     */
    @isTest 
    static void test_RetrieveCompleteChecklistItemsEmailInstructions() {
        //Initialize variables
        List<String> emailInstructions;

        //Start test process        
	 	Test.startTest();
            //Retrieve test application
            Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
            testApplication.Status__c = 'Submitted';
            update testApplication;
            
            //Run checklist rules
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{testApplication.Id});
            rulesDocChecklistEngine.evaluateRules('Application Assessment');

            //Retrieve checklist items        
            List<Document_Checklist__c> applicationDocumentChecklistList = rulesDocChecklistEngine.resultChecklistItemsMap.get(testApplication.Id).values();
            //Submit document checklist record
            applicationDocumentChecklistList[1].Status__c = 'Submitted';
            upsert applicationDocumentChecklistList[1];
        
            emailInstructions = rulesDocChecklistEngine.retrieveCompleteChecklistItemsEmailInstructions(testApplication.Id);
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(emailInstructions.size(), 1);
    }

    /**
     * @description Tests cancelIrrelevantChecklistItems method for cancelling checklist items
     */
    @isTest 
    static void test_CancelIrrelevantChecklistItems() {
        //Initialize variables
        List<Document_Checklist__c> cancelledDocumentChecklistList;
        List<Document_Checklist__c> resultApplicationDocumentChecklistList;
        
        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        
        //Start test process        
	 	Test.startTest();
            //Create Qualifications
            Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
            insert testQualification;

            //Create Contact Qualifications
            Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
            insert testContactQualification;

            /* Configure visa rule - generate visa checklist */
            testApplication.Refused_entry_visa_to_any_country__c = 'Yes';
            testApplication.Breached_visa_condition__c = 'Yes';
            testApplication.Medical_health_prevent_visa__c = 'Yes';
            testApplication.Protection_visa_in_any_country__c = 'Yes';
            testApplication.Convicted_of_crime_offence__c = 'Yes';      
            update testApplication;
            
            //Run checklist rules
            Document_Checklist__c visaChecklist;
            resultApplicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
            for(Document_Checklist__c loopChecklist : resultApplicationDocumentChecklistList){
                if(loopChecklist.Type__c == 'Visa'){
                    visaChecklist = loopChecklist;
                }
            }

            /* Configure visa rule - auto cancel visa checklist */
            testApplication.Refused_entry_visa_to_any_country__c = 'No';
            testApplication.Breached_visa_condition__c = 'No';
            testApplication.Medical_health_prevent_visa__c = 'No';
            testApplication.Protection_visa_in_any_country__c = 'No';
            testApplication.Convicted_of_crime_offence__c = 'No';    
            update testApplication;
            
            //Insert contact documents
            //Create test contact document
            List<ContentDocument> documentList = new List<ContentDocument>();        
            documentList.add(createTestDocument(true, 'gif'));

            String docTypeValue = getDocumentTypeValue(0);
            String docSubType = '';
            String comments = 'testing some comments ';

            for(ContentDocument loopContentDocument : documentList){
                ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, testApplication.Applicant__c, testApplication.Id, 
                                                                            docTypeValue, docSubType, comments, visaChecklist.Id, 
                                                                            testContactQualification.Id, null, false);
            }
        
            //Run checklist rules
            DocumentChecklistAssessmentServices.runRules('Application Assessment', testApplication.Id);
	 	Test.stopTest();

        cancelledDocumentChecklistList = [SELECT Id FROM Document_Checklist__c WHERE Status__c = 'AutoCancelled'];
        
        //Start assertion
        System.assertEquals(cancelledDocumentChecklistList.size(), 1);
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