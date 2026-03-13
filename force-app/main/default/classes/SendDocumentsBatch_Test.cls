/**
 * @author      Kristian Vegerano
 * @description Test class for SendDocumentsBatch batch class
 * @group       Test Class
 * @revision    08/01/2020 - Kristian Vegerano - Created
 * @revision    15.MAR.2024 Ven Vairavan > Update Mule4 endpoints.
 */
@isTest(isParallel=true)
private class SendDocumentsBatch_Test {
    @testSetup
    static void setup() {
        //Create a community user
        User communityUserRec = StudFirst_TestHelper.createCommunityUser();

        //create a new draft application
        Application__c appRecord = new Application__c();
        appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
        appRecord.Callista_Application_Id__c = '12345678';
        appRecord.Status__c = 'Submitted';
        insert appRecord;

        Contact contactRec = [SELECT Id FROM Contact WHERE Id =: communityUserRec.ContactId];
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

        List<Contact_Document__c> contactDocuList = new List<Contact_Document__c>();

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

        Application_Course_Preference__c coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
        coursePrefA.Outcome_Status__c = 'TEST-STATUS';
        coursePrefA.Offer_Response_Status__c = 'TEST-STATUS';
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
        is.Events_Path__c = '/v1/admissions/events HTTP/1.1';
        is.Mock_Endpoint_Events__c = 'http://monash.getsandbox.com/la/admissions/v1/events HTTP/1.1';
        insert is;
    }

    @isTest
    static public void testExecuteBatch() {
        //Initialize variables
        Set<String> applicationIds = new Set<String>();
        for(Application__c loopApplication : [SELECT Id FROM Application__c]){
            applicationIds.add(loopApplication.Id);
        }

        //Start test
        Test.startTest();
        
            //Set mock response
            Test.setMock(HttpCalloutMock.class, new StudFirst_MockHttpResponseGenerator());

            SendDocumentsBatch testBatchProcess = new SendDocumentsBatch(applicationIds);
            Database.executeBatch(testBatchProcess);

        //Stop test
        Test.stopTest();
    }
}