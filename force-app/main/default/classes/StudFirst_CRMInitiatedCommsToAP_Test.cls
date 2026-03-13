/*******************************************************************************
* @author       Suman Gunaganti
* @description  Test class for StudFirst_CRMInitiatedCommsToAP class
* @date         17/12/2019
* @group        Test Class
*******************************************************************************/
@isTest(isParallel=true)
private class StudFirst_CRMInitiatedCommsToAP_Test {
    private static Application__c appRecord;
    private static User communityUserRec;
    private static Contact contactRec;
    private static Application_Course_Preference__c coursePrefA;
    private static Application_Course_Preference__c coursePrefB;
    private static Course_Offering__c courseOfferingRec;
    private static Course_Offering__c courseOfferingRecNoUnit;
    
    static void createSampleData (String status, String outcome, Boolean addCourse) {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        
        //create a new draft application
        appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
        appRecord.OwnerId = communityUserRec.Id;
        appRecord.Status__c = status;
        // appRecord.Agent_Email__c = 'agentEmail@agents.com';
        appRecord.Agent_Org_Unit_Code__c = 'AGENT-X';
        appRecord.Callista_Applicant_Id__c = '53435345345';
        insert appRecord;

        contactRec = [SELECT Id FROM Contact WHERE Id =: communityUserRec.ContactId];
        contactRec.Residency_Status__c = 'DOM-AUS';
        update contactRec;

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

        if(addCourse){
            coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
            coursePrefA.Outcome_Status__c = outcome;
            coursePrefA.Offer_Response_Status__c = outcome;
            coursePrefA.Preference_Number__c = '1';
            insert coursePrefA;

            coursePrefB = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRecNoUnit, courseRec);
            coursePrefB.Outcome_Status__c = outcome;
            coursePrefB.Offer_Response_Status__c = outcome;
            coursePrefB.Preference_Number__c = '2';
            insert coursePrefB;
        }
    }
    static testMethod void test_notifyAgent() {
        //create data
        String admissionsRecType = CommonServices.recordTypeId('Case', 'Admissions');

        //create required records
        createSampleData('Draft', 'TEST-STATUS', true);
        
        Test.startTest();

        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                     'Complete',
                                                     '{"success":true,"message":"Message has been successfully submitted"}',
                                                     null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Case caseRec = new  Case(SuppliedName = 'testName',
                                SuppliedPhone = '0400000000',
                                SuppliedEmail = 'testformEmail@monash.edu',
                                ContactId = null,
                                AccountId = null,
                                RecordTypeId = admissionsRecType,
                                Notify_Agent__c = true,
                                Application_Course_Preference__c = coursePrefA.Id );
        insert caseRec;

        System.assert(caseRec.Notify_Agent__c, 'Notify Agent should be set to true');
        System.assertEquals(caseRec.RecordTypeId, admissionsRecType, 'Record Type should be Admissions');

        EmailMessage emlMsg = new EmailMessage( ParentId = caseRec.id,
                                                FromAddress = 'testfrom@testmonash.edu',
                                                FromName = 'testSender',
                                                Subject = 'testSubject',
                                                HtmlBody = '<b>test body</b>',
                                                ToAddress = 'testEndpoint@monash.edu'); 
        insert emlMsg;

        System.assertEquals(caseRec.Id, emlMsg.ParentId, 'Email Message ParentId should be the Case created');

        Task taskRec = new Task(    Description = 'Additional To: testmonash@monash.edu\nCC: \nBCC: \nAttachment: att.docx\n\nSubject: dummy email\nBody:\nsdlfkajsldfarwerwdrf\n\nref:_00D0kCnIP._5000kguvP:ref',
                                    WhatId = caseRec.Id, 
                                    Subject = 'Email: Welcome',
                                    Type = 'Internal Email' );
        insert taskRec;

        System.assertEquals(taskRec.WhatId, caseRec.Id, 'No Task created');

        //make sure there's no error on the request
        System.assertEquals(0, [SELECT  COUNT()
                                FROM    Exception_Log__c 
                                WHERE   Source_Type__c = 'StudFirst_CRMToAPQueueable' ]);
        
        Test.stopTest();
    }
}