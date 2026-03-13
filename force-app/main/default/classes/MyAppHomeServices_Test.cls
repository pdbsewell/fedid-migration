/**
 * @author      Kristian Vegerano
 * @description Test class for MyAppHomeServices class
 * @group       Test Class
 * @revision    06/02/2020 - Kristian Vegerano - Created
 * 2024-07-17   updated updated the degree selector options for my.app
 */
@isTest
public with sharing class MyAppHomeServices_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        //Disable Triggers
        TriggerCommon.disableTrigger('List_of_Values__c');
        TriggerCommon.disableTrigger('Contact_Document__c');
        TriggerCommon.disableTrigger('Work_Experience__c');
        TriggerCommon.disableTrigger('Course__c');
        TriggerCommon.disableTrigger('Course_Offering__c');
        TriggerCommon.disableTrigger('Application__c');
        TriggerCommon.disableTrigger('Qualification__c');
        TriggerCommon.disableTrigger('Contact_Qualification__c');
        TriggerCommon.disableTrigger('Application_Course_Preference__c');
        TriggerCommon.disableTrigger('Contact_Document__c');
        TriggerCommon.disableTrigger('Document_Checklist_Comment__c');
        
        //added list of values reference records
        List<List_of_Values__c> lovs = new List<List_of_Values__c>();
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'Offered', Value__c = 'OFFER', Type__c = 'ADM_OUTCOME_STATUS', System_Code__c = 'OFFER'));
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'Offered', Value__c = 'OFFER-COND', Type__c ='ADM_OUTCOME_STATUS', System_Code__c ='OFFER-COND'));
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'Offered', Value__c = 'OFFER-PROV', Type__c ='ADM_OUTCOME_STATUS', System_Code__c ='OFFER-PROV'));
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'Accepted', Value__c = 'ACCEPTED', Type__c = 'ADM_OFFER_RESP_STATUS', System_Code__c = 'ACCEPTED'));
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'Accepted', Value__c = 'ACCEPT-CND', Type__c = 'ADM_OFFER_RESP_STATUS', System_Code__c = 'ACCEPT-CND'));
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'Accepted', Value__c = 'ACCEPT-PRV', Type__c= 'ADM_OFFER_RESP_STATUS', System_Code__c = 'ACCEPT-PRV'));
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'Rejected', Value__c = 'REJECTED', Type__c = 'ADM_OFFER_RESP_STATUS', System_Code__c = 'ACCEPTED'));
        lovs.add(new List_of_Values__c(Applicant_Value__c = 'In progress', Value__c = 'PENDING', Type__c = 'ADM_OFFER_RESP_STATUS', System_Code__c = 'PENDING'));
        insert lovs;

        //Create community user
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact contactApplicant = [SELECT Id FROM Contact WHERE id =: applicant.contactId];
        
        Contact_Document__c condoc = new Contact_Document__c();
        condoc.Contact__c = contactApplicant.id;
        condoc.Document_Type__c = 'PARENT_GUARDIAN';
        condoc.Filename__c = 'testdoc';
        condoc.File_Upload_Successful__c = false;
        insert condoc;

        //Create a work experience for the previous application
        Work_Experience__c testWorkExperience = StudFirst_TestHelper.createWorkExperience(contactApplicant);
        insert testWorkExperience;

        //Course
        Course__c course = StudFirst_TestHelper.createCourse();
        insert course;

        //Offering
        Course_Offering__c offering = StudFirst_TestHelper.createCourseOffering(course);
        insert offering;

        //Create draft and submitted application
        Application__c draftApplication = StudFirst_TestHelper.createApplication(contactApplicant.Id);
        draftApplication.Status__c = 'Draft';
        draftApplication.Source_System__c = 'my.app';

        Application__c submittedApplication = StudFirst_TestHelper.createApplication(contactApplicant.Id);
        submittedApplication.Status__c = 'Submitted';
        //Insert applications
        insert new List<Application__c>{draftApplication, submittedApplication};

        // Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        // Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(contactApplicant, testQualification, 'Secondary Education');
        insert testContactQualification;
        List_of_Values__c lovoffer = [select Id from List_of_Values__c where Value__c='OFFER' limit 1];
      
        
        //create ACP
        Application_Course_Preference__c draftAcp = StudFirst_TestHelper.createCoursePreferences(draftApplication, contactApplicant, offering, course);
        
        Application_Course_Preference__c submittedAcp = StudFirst_TestHelper.createCoursePreferences(submittedApplication, contactApplicant, offering, course);
        submittedAcp.Outcome_Status_LOV__c = lovOffer.Id;
        submittedAcp.Conditional_Offer_Status_LOV__c = lovOffer.Id;
        
        //Insert application course preferences
        insert new List<Application_Course_Preference__c>{draftAcp, submittedAcp};
  
    

        //Insert test document checklists
        DocumentChecklistAssessmentServices.runRules('Application Assessment', submittedApplication.Id);
        
        //Retrieve test document checklist records
        List<Document_Checklist__c> resultApplicationDocumentChecklistList = (List<Document_Checklist__c>)DocumentChecklistAssessmentServices.retrieveChecklistItems(submittedApplication.Id);

        //Retrieve test content document
        Contact_Document__c testContactDocument = [SELECT Id, Filename__c 
                                                   FROM Contact_Document__c LIMIT 1];
        testContactDocument.Application__c = submittedApplication.Id;
        update testContactDocument;

        //Create test contact document
        List<ContentDocument> documentList = new List<ContentDocument>();        
        documentList.add(createTestDocument(true, 'gif', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'doc', testContactDocument.Id));
        documentList.add(createTestDocument(true, 'docx', testContactDocument.Id));

        String docTypeValue = getDocumentTypeValue(0);
        String docSubType = '';
        String comments = 'testing some comments ';

        for(ContentDocument loopContentDocument : documentList){
            ContactDocumentServices.saveFileAndContactDocumentChecklist(loopContentDocument.Id, contactApplicant.Id, submittedApplication.Id, 
                                                                        docTypeValue, docSubType, comments, resultApplicationDocumentChecklistList[0].Id, 
                                                                        testContactQualification.Id, null, false);
        }

        //Create test document checklist comment
        insert new Document_Checklist_Comment__c(Document_Checklist__c = resultApplicationDocumentChecklistList[0].Id,
                                                 Content__c = 'Test Comment');

    
        //Setup Environment Settings
        Environment_Settings__c env = new Environment_Settings__c();
        env.StudyType_Australia__c = 'Coursework,Study Abroad';
        env.StudyType_Malaysia__c = 'Coursework,Study Abroad';
        env.StudyType_Indonesia__c = 'Coursework';
        env.StudyType_China__c = 'Graduate Research'; 
        env.CampusLocation_Australia__c = true;
        env.CampusLocation_Malaysia__c = true;
        env.CampusLocation_Indonesia__c = true;
        insert env;
    
        //Enable Triggers
        TriggerCommon.enableTrigger('List_of_Values__c');
        TriggerCommon.enableTrigger('Contact_Document__c');
        TriggerCommon.enableTrigger('Work_Experience__c');
        TriggerCommon.enableTrigger('Course__c');
        TriggerCommon.enableTrigger('Course_Offering__c');
        TriggerCommon.enableTrigger('Application__c');
        TriggerCommon.enableTrigger('Qualification__c');
        TriggerCommon.enableTrigger('Contact_Qualification__c');
        TriggerCommon.enableTrigger('Application_Course_Preference__c');
        TriggerCommon.enableTrigger('Contact_Document__c');
        TriggerCommon.enableTrigger('Document_Checklist_Comment__c');
    }

    /**
     * @author      Kristian Vegerano
     * @description
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app
     * THEN system tests component's initialize - retrieve all necessary data
     */
	@isTest 
    static void test_RetrieveHomeDetails() {
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, Object>();

        //Query community user
        User communityApplicant = [SELECT Id FROM User WHERE Contact.Name = 'First Last' LIMIT 1];

        Test.startTest();
            System.runAs(communityApplicant) {
                resultMap = MyAppHomeServices.retrieveHomeDetails(communityApplicant.Id);
            }
        Test.stopTest();

        //Assert results
        Assert.areNotEqual(resultMap.size(), 0);
       Assert.areNotEqual(resultMap.get('CURRENT_USER_DETAILS'), null);
       Assert.areNotEqual(resultMap.get('SOURCE_SYSTEM'), null);


    }

    /**
     * @author      Kristian Vegerano 
     * @description
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app and select a location and study type
     * THEN system creates draft application 
     */
	@isTest 
    static void test_CreateApplication() {
        //Initialize variables
        String testApplicationId;

        //Create community user
        User communityApplicant = [SELECT Id, ContactId FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        Application__c draftApplication = [SELECT Id FROM Application__c WHERE Applicant__c = :communityApplicant.ContactId AND Status__c = 'Draft' LIMIT 1];
        delete [SELECT Id FROM Application__c WHERE Id = :draftApplication.Id];

        Test.startTest();
            System.runAs(communityApplicant) {
                testApplicationId = MyAppHomeServices.createApplication(communityApplicant.ContactId, 'Australia', 'coursework');
            }
        Test.stopTest();

        //Assert results
        Assert.areNotEqual(testApplicationId, null);
    }

    /**
     * @author      Kristian Vegerano
     * @description
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app and select cancel application for any existing application
     * THEN system Tests cancellation of draft applications 
     */
	@isTest 
    static void test_CancelApplication() {

        //Create community user
        User communityApplicant = [SELECT Id, ContactId FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        Application__c draftApplication = [SELECT Id FROM Application__c WHERE Applicant__c = :communityApplicant.ContactId AND Status__c = 'Draft'];

        Test.startTest();
            System.runAs(communityApplicant) {
                MyAppHomeServices.cancelApplication(draftApplication.Id);
            }
        Test.stopTest();

        //Assert results
        Assert.areEqual('Cancelled', [SELECT Id, Status__c 
                                          FROM Application__c 
                                          WHERE Id = :draftApplication.Id LIMIT 1].Status__c);
    }

    /**
     * @author      Kristian Vegerano
     * @description
     * WHEN student is logged in to my.app and see the offer
     * THEN system Tests domestic offer acceptance 
     */
	@isTest 
    static void test_acceptDomesticOfferACP() {

        //Create community user
        User communityApplicant = [SELECT Id, ContactId FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        Application_Course_Preference__c testSubmittedAcp = [SELECT Id, Offer_Response_Status_LOV__c, Conditional_Offer_Status_LOV__r.Value__c, Outcome_Status_LOV__c, Outcome_Status_LOV__r.Value__c
                                                             FROM Application_Course_Preference__c 
                                                             WHERE Application__r.Applicant__c = :communityApplicant.ContactId 
                                                                AND Application__r.Status__c = 'Submitted' LIMIT 1];

        Test.startTest();
            System.runAs(communityApplicant) {
                MyAppHomeServices.doAcceptACP(testSubmittedAcp);
            }
        Test.stopTest();

        //Assert results
        Assert.areEqual('ADM_OFFER_RESP_STATUS', [SELECT Id, Offer_Response_Status_LOV__r.Type__c 
                                                      FROM Application_Course_Preference__c 
                                                      WHERE Id = :testSubmittedAcp.Id LIMIT 1].Offer_Response_Status_LOV__r.Type__c);
    }

    /**
     * @author      Kristian Vegerano 
     * @description 
     * WHEN student is logged in to my.app and see the offer rejection
     * THEN system Tests domestic offer rejection 
     */
	@isTest 
    static void test_rejectDomesticOfferACP() {

        //Create community user
        User communityApplicant = [SELECT Id, ContactId FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        Application_Course_Preference__c testSubmittedAcp = [SELECT Id, Offer_Response_Status_LOV__c
                                                             FROM Application_Course_Preference__c 
                                                             WHERE Application__r.Applicant__c = :communityApplicant.ContactId 
                                                                AND Application__r.Status__c = 'Submitted' LIMIT 1];

        Test.startTest();
            System.runAs(communityApplicant) {
                MyAppHomeServices.doRejectACP(testSubmittedAcp);
            }
        Test.stopTest();

        //Assert results
        Assert.areEqual('ADM_OFFER_RESP_STATUS', [SELECT Id, Offer_Response_Status_LOV__r.Type__c 
                                                      FROM Application_Course_Preference__c 
                                                      WHERE Id = :testSubmittedAcp.Id LIMIT 1].Offer_Response_Status_LOV__r.Type__c);
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
    static ContentDocument createTestDocument(Boolean allAccess, String fileExtension, Id contactDocumentId) {
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
            List<ContentDocumentLink> linkList = new List<ContentDocumentLink>();
            linkList.add(new ContentDocumentLink(LinkedEntityId = UserInfo.getOrganizationId(),
                                                 ContentDocumentId = cv.ContentDocumentId,
                                                 ShareType = 'C', 
                                                 Visibility = 'AllUsers'));          
            insert linkList;
        }

        return file;
    }
 
    /**
     * @author      Shalini Mendu 
     * @description 
     * WHEN student is logged in to my.app and see the offer of Provisional offer for Domestic students
     * THEN system Tests the acceptance of Provisional offer for Domestic students 
     */
    @isTest 
    static void test_acceptDomesticFullOfferACPAccept() {
        //Create community user
        User communityApplicant = [SELECT Id, ContactId FROM User WHERE Contact.Name = 'First Last' LIMIT 1];
        Application_Course_Preference__c testSubmittedAcp = [SELECT Id, Offer_Response_Status_LOV__c, Conditional_Offer_Status_LOV__r.Value__c, Outcome_Status_LOV__c, Outcome_Status_LOV__r.Value__c
                                                             FROM Application_Course_Preference__c 
                                                             WHERE Application__r.Applicant__c = :communityApplicant.ContactId 
                                                             AND Application__r.Status__c = 'Submitted'
                                                             LIMIT 1];
       List_of_Values__c lovoffer = [select Id from List_of_Values__c where Value__c='OFFER-PROV' limit 1];

        testSubmittedAcp.Outcome_Status_LOV__c = lovOffer.Id;
        testSubmittedAcp.Conditional_Offer_Status_LOV__c = lovOffer.Id;

         Test.startTest();     
            System.runAs(communityApplicant) {
                MyAppHomeServices.doAcceptACP(testSubmittedAcp);
            }
        Test.stopTest();
        //Assert results
        Assert.areEqual('ACCEPTED', [select Offer_Response_Status_LOV__r.Value__c from Application_Course_Preference__c where id=:testSubmittedAcp.Id].Offer_Response_Status_LOV__r.Value__c);
        
    }


  
}