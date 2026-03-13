/*******************************************************************************
* @author       Ant Custodio
* @date         4.Aug.2017        
* @description  test class for StudFirst_SendDocumentsService web service
* @revision     Suman Gunaganti(2019-07-05): (SF-2781) Removed Application Document provided object reference
* 15/03/2024 - Mac Domingo   - EPCP-3307 Change integration endpoint for Mule 4
*******************************************************************************/
@isTest
public with sharing class StudFirst_SendDocumentsService_Test {
    private static Application__c appRecord;
    private static User communityUserRec;
    private static Set<String> adpIds;
    private static List<Contact_Document__c> contactDocuList;


    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         3.Aug.2017        
    * @description  tests the Send Email functionality on ACP
    * @revision     
    *******************************************************************************/
    static testMethod void test_sendToCallista() {
        //create a community user
        communityUserRec = StudFirst_TestHelper.createCommunityUser();
        //create required records
        createSampleData(communityUserRec.ContactId, 'Submitted', 'TEST-STATUS', true);
        
        Test.startTest();
        
        //set mock response
        Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

        //run the web service by passing an applicant Id
        StudFirst_SendDocumentsService.sendToCallistaByAppId(appRecord.Id);

        //make sure the process builder updates the Has_API_Request__c flag
        /*for (Contact_Document__c cdRec: [ SELECT  Id, Has_API_Request__c
                                            FROM    Contact_Document__c ]) {
            System.assertEquals(true, cdRec.Has_API_Request__c, 'The Process "AA - ADP Processes" did not run. Please check if it is activated');
        }*/

        //make sure the request message contains the CNDC prefix by checking if the file name on the request message contains '_'
        /*for (Application_Document_Provided__c docProvided: [  SELECT  Id,
                                                                        API_Request_Message__c
                                                                FROM    Application_Document_Provided__c
                                                                WHERE   Contact_Document__c IN: contactDocuList]) {
            if (docProvided.API_Request_Message__c != null) {
                System.assert(docProvided.API_Request_Message__c.contains('test_'), 'The request message does not have a CNDC prefix to the filename');
            }
        }*/

        //make sure there are no errors on the queueable class
        //System.assertEquals(0, [SELECT COUNT() FROM Exception_Log__c]);
        Test.stopTest();
    }
    
    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Aug.2017        
    * @description  creates full application sample data
    * @revision     
    *******************************************************************************/
    static void createSampleData (String contactId, String status, String outcome, Boolean addCourse) {
        //create a new draft application
        appRecord = StudFirst_TestHelper.createApplication(contactId);
        appRecord.OwnerId = communityUserRec.Id;
        appRecord.Callista_Application_Id__c = '12345678';
        appRecord.Status__c = status;
        insert appRecord;

        Contact contactRec = [SELECT Id FROM Contact WHERE Id =: contactId];
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

        contactDocuList = new List<Contact_Document__c>();

        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        contactDocuList.add(contactDocu);

        Contact_Document__c contactDocu2 = new Contact_Document__c();
        contactDocu2 = StudFirst_TestHelper.createContactDocument(contactRec.Id);
        contactDocuList.add(contactDocu2);
        insert contactDocuList;

        List<Attachment> attList = new List<Attachment>();
        Attachment attRec = new Attachment();
        attRec.Body = Blob.valueOf('Sample Text String');
        attRec.Name = String.valueOf('firsttest.txt');
        attRec.ParentId = contactDocu.Id; 
        attList.add(attRec);

        Attachment attRec2 = new Attachment();
        attRec2.Body = Blob.valueOf('Sample Text String #2');
        attRec2.Name = String.valueOf('secondtest.doc');
        attRec2.ParentId = contactDocu2.Id; 
        attList.add(attRec2);
        insert attList;

        ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
        );
        insert contentVersionInsert;

        //Get Content Document
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument LIMIT 1];

        System.assertEquals(docs.size(), 1);

        ContentDocumentLink cdLink = new ContentDocumentLink();
        cdLink.ContentDocumentId = docs[0].Id;
        cdLink.LinkedEntityId = appRecord.Id;
        cdLink.ShareType = 'v';
        cdLink.Visibility = 'AllUsers';
        insert cdLink;

        /* List<Application_Document_Provided__c> adpList = new List<Application_Document_Provided__c>();

        Application_Document_Provided__c adpRecord = StudFirst_TestHelper.createApplicationDocument(appRecord.Id, contactDocu.Id);
        adpList.add(adpRecord);
        Application_Document_Provided__c adpRecord2 = StudFirst_TestHelper.createApplicationDocument(appRecord.Id, contactDocu2.Id);
        adpRecord2.Document_submitted_successfully__c = true;
        adpList.add(adpRecord2);
        Application_Document_Provided__c adpRecord3 = StudFirst_TestHelper.createApplicationDocument(appRecord.Id, contactDocu2.Id);
        adpList.add(adpRecord3);
        insert adpList;
        adpIds = new Set<String>();
        for (Application_Document_Provided__c adpRec: adpList) {
            adpIds.add(adpRec.Id);
        } */

        Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
        aweRecord.Application__c = appRecord.Id;
        aweRecord.Work_Experience__c = workExpRecord.Id;
        insert aweRecord;

        Course__c courseRec = StudFirst_TestHelper.createCourse();
        insert courseRec;

        Course_Offering__c courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
        insert courseOfferingRec;

        Course_Offering__c courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
        insert courseOfferingRecNoUnit;

        if(addCourse){
            Application_Course_Preference__c coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
            coursePrefA.Outcome_Status__c = outcome;
            coursePrefA.Offer_Response_Status__c = outcome;
            coursePrefA.Preference_Number__c = '1';
            insert coursePrefA;
        }

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
        is.Events_Path__c = '/v1/admissions/events HTTP/1.1';
        is.Mock_Endpoint_Events__c = 'http://monash.getsandbox.com/v1/events HTTP/1.1';
        insert is;
    }
}