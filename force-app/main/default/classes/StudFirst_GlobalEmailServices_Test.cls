/*******************************************************************************
* @author       Ant Custodio
* @date         20.Sept.2017     
* @description  test class for StudFirst_GlobalEmailServices
* @revision     Ant Custodio, 13/Apr/2018 - Updated test class to conform with
*                   standards
* 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
*******************************************************************************/
//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember
@isTest(isParallel=false)
public with sharing class StudFirst_GlobalEmailServices_Test {

    private static Application__c appRecord;
    private static User communityUserRec;
    private static Contact contactRec;
    private static Application_Course_Preference__c coursePrefA;
    private static Course_Offering__c courseOfferingRec;
    private static Course_Offering__c courseOfferingRecNoUnit;

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         3.Aug.2017        
    * @description  tests the Send Email functionality on ACP
    * @revision     
    *******************************************************************************/
    @isTest 
    static void test_resendEmail() {        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('StudFirst_SubmitEnquirySummaryMockResp');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        //check if testSetup ran
        EmailMessage emlMsg = [SELECT Id, ParentId FROM EmailMessage WHERE FromAddress = 'mc.documents@monash.edu' LIMIT 1];

        //disable attachment trigger
        TriggerCommon.disableTrigger('Attachment');
        List<Attachment> attList = new List<Attachment>();
        Attachment attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('test.txt');
        attRec.ParentId = emlMsg.Id; 
        attList.add(attRec);
        insert attList;
        //enable attachment trigger
        TriggerCommon.enableTrigger('Attachment');

        StudFirst_GlobalEmailServices.resendEmail(emlMsg.Id);
        Test.stopTest();

        List<Task> taskList = [SELECT Id FROM Task WHERE WhatId =: emlMsg.ParentId];
        System.assertNotEquals(0, taskList.size(), 'ERROR: No Task created.');
    }

    @isTest 
    static void test_resendEmail1() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('StudFirst_SubmitEnquirySummaryMockResp');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<EmailMessage> emlMsgRecList = [SELECT  Id, BccAddress, CcAddress,
                                                    FromAddress, FromName, 
                                                    Headers, HtmlBody,
                                                    Incoming, ParentId, Status,
                                                    Subject, TextBody, ToAddress,
                                                    Parent.Notify_Agent__c
                                            FROM    EmailMessage
                                            LIMIT   1   ];

        //disable attachment trigger
        TriggerCommon.disableTrigger('Attachment');
        List<Attachment> attList = new List<Attachment>();
        Attachment attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('test.txt');
        attRec.ParentId = emlMsgRecList[0].Id; 
        attList.add(attRec);
        insert attList;
        //enable attachment trigger
        TriggerCommon.enableTrigger('Attachment');
        
        if (!emlMsgRecList.isEmpty()) {
            StudFirst_GlobalEmailServices.sendToProvidedEmailAddresses( emlMsgRecList[0].Id,
                                                                        'testEndpointOverride1@monash.edu',
                                                                        'testEndpointOverride2@monash.edu; testEndpointOverride3@monash.edu',
                                                                        'testEndpointOverride4@monash.edu; testEndpointOverride5@monash.edu', 
                                                                        emlMsgRecList[0].Parent.Notify_Agent__c, 
                                                                        true);
        }
        Test.stopTest();
        List<Task> taskList = [SELECT Id FROM Task WHERE WhatId =: emlMsgRecList[0].ParentId];
        System.assertNotEquals(0, taskList.size(), 'ERROR: No Task created.');
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         20.Sept.2017        
    * @description  creates full application sample data
    * @revision     
    *******************************************************************************/
    @testSetup
    static void createSampleData() {
        contactRec = StudFirst_TestHelper.createApplicant();
        contactRec.Residency_Status__c = 'DOM-AUS';
        insert contactRec;
        
        //create a new draft application
        appRecord = StudFirst_TestHelper.createApplication(contactRec.Id);
        appRecord.Status__c = 'Submitted';
        insert appRecord;

        //Tertiary institution & qualification
        Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
        insert tertInsRec;

        Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
        insert outcomeStatus;

        Contact_Qualification__c conQualRec = new Contact_Qualification__c();
        conQualRec.Country__c = 'Australia';
        conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
        conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
        conQualRec.Other_Qualification__c = 'Certificate III';
        conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
        conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
        conQualRec.Status__c = 'CURRENTLY STUDYING';
        conQualRec.Contact__c = contactRec.Id;
        conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
        insert conQualRec;

        Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
        aqpRecord.Application__c = appRecord.Id;
        aqpRecord.Contact_Qualification__c = conQualRec.Id;
        insert aqpRecord;

        Work_Experience__c workExpRecord = new Work_Experience__c();
        workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
        workExpRecord.Contact__c = contactRec.Id;
        insert workExpRecord;

        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        insert contactDocu;

        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;

        coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
        coursePrefA.Outcome_Status__c = 'OFFER';
        coursePrefA.Offer_Response_Status__c = 'OFFER';
        coursePrefA.Preference_Number__c = '1';
        insert coursePrefA;
        
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
        
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');
        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                ContactId = contactRec.Id,
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true,
                                Application_Course_Preference__c = coursePrefA.Id );
        insert caseRec;
        
        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assert(caseRec.RecordTypeId == admissionsRecType, 'Record Type should be Admissions');
        
        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'mc.documents@monash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu',
                                                CCAddress = 'testEndpoint12@monash.edu; testEndpoint1432@monash.edu',
                                                BCCAddress = 'testEndpoint1234@monash.edu; testEndpoint178787@monash.edu',
                                                Incoming = true); 
        insert emlMsg;
        
        System.assertEquals(caseRec.Id, emlMsg.ParentId, 'Email Message ParentId should be the Case created');
        /*
        List<Attachment> attList = new List<Attachment>();

        Attachment attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('test.txt');
        attRec.ParentId = emlMsg.Id; 
        attList.add(attRec);

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('test2.doc');
        attRec2.ParentId = emlMsg.Id; 
        attList.add(attRec2);

        insert attList;
        
        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());
        */
    }
}