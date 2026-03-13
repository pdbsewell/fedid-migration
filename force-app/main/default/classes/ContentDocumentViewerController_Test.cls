/**
 * @author      Kristian Vegerano
 * @description Test class for ContentDocumentViewerController class
 * @group       Test Class
 * @revision    06/08/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
private class ContentDocumentViewerController_Test {
    /**
     * @description Setup test data
     */
    @testSetup
    static void setup() {
        //Setup test data
        Contact newContact = new Contact();
        newContact.FirstName = 'TestContact';
        newContact.LastName = 'TestContact';
        newContact.Person_Id_Unique__c = 'IDA';
        insert newContact;

        Contact_Document__c condoc = new Contact_Document__c();
        condoc.Contact__c = newContact.id;
        condoc.Document_Type__c = 'PARENT_GUARDIAN';
        condoc.Filename__c = 'testdoc';
        condoc.File_Upload_Successful__c = false;
        insert condoc;

        Application__c application = new Application__c();
        application.Applicant__c = newContact.Id;
        application.Campus_Location__c = null;
        application.Visa_Type__c = null;
        application.Australian_Immigration_Office_Issued__c = null;
        application.Visa_Number__c = null;
        application.Passport_Number__c = null;
        application.Visa_Start_Date__c = null;
        application.Visa_End_Date__c = null;
        application.Refused_entry_visa_to_any_country__c = null;
        application.Breached_visa_condition__c = null;
        application.Medical_health_prevent_visa__c = null;
        application.Protection_visa_in_any_country__c = null;
        application.Convicted_of_crime_offence__c = null;
        insert application;

        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='Header_Picture1',
            PathOnClient ='/Header_Picture1.txt',
            VersionData = bodyBlob,
            origin = 'H'
        );
        insert contentVersion_1;

        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = application.id;
        contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;

        ContentDocumentLink contentlink1 = new ContentDocumentLink();
        contentlink1.LinkedEntityId = condoc.id;
        contentlink1.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink1.ShareType = 'V';
        insert contentlink1;
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests component's initialize - retrieve all necessary data
     */
    @isTest
    static void test_retrieveContentDocumentData() {
        //Retrieve test content document
        Contact_Document__c testContactDocument = [SELECT Id, Filename__c
                       FROM Contact_Document__c LIMIT 1];

        //Start test process
        Map<String, Object> results;
        Test.startTest();
        results = ContentDocumentViewerController.retrieveContentDocumentData(testContactDocument.Id);
        Test.stopTest();

        //Start assertion
        System.assertNotEquals(null, results.get('ContactDocument'));
        System.assertNotEquals(null, results.get('ContentDocument'));
        System.assertNotEquals(null, results.get('DocumentName'));
        System.assertNotEquals(null, results.get('DocumentFileType'));
        System.assertNotEquals(null, results.get('ContentDistribution'));
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns new content distribution record
     */
    @isTest
    static void retrieveActiveContentDistributionNew() {
        //Retrieve test records
        ContentDocument testDocument = [SELECT Id, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        ContentVersion testVersion = [SELECT Id FROM ContentVersion LIMIT 1];
        Contact_Document__c testContactDocument = [SELECT Id, Filename__c
                       FROM Contact_Document__c LIMIT 1];

        //Start test process
        Test.startTest();
        ContentDocumentViewerController.retrieveActiveContentDistribution(testVersion.Id, testContactDocument, testDocument);
        Test.stopTest();

        //Start assertion
        System.assertEquals(1, [SELECT Id FROM ContentDistribution].size());
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns new/extended content distribution record
     */
    @isTest
    static void retrieveActiveContentDistributionExtended() {
        //Retrieve test records
        ContentDocument testDocument = [SELECT Id, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        ContentVersion testVersion = [SELECT Id FROM ContentVersion LIMIT 1];
        Contact_Document__c testContactDocument = [SELECT Id, Filename__c
                       FROM Contact_Document__c LIMIT 1];

        //Create expired content distribution
        ContentDistribution contentLink = new ContentDistribution(Name = testContactDocument.Filename__c,
                ContentVersionId = testDocument.LatestPublishedVersionId,
                PreferencesAllowViewInBrowser = true,
                PreferencesLinkLatestVersion = true,
                PreferencesNotifyOnVisit = false,
                PreferencesPasswordRequired = false,
                PreferencesAllowOriginalDownload = false,
                PreferencesAllowPDFDownload = false,
                PreferencesExpires = true,
                ExpiryDate = System.NOW().addDays(-1));
        insert contentLink;

        //Start test process
        Test.startTest();
        ContentDocumentViewerController.retrieveActiveContentDistribution(testVersion.Id, testContactDocument, testDocument);
        Test.stopTest();

        //Start assertion
        System.assertEquals(1, [SELECT Id FROM ContentDistribution].size());
    }
}