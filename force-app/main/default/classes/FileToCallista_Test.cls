/*******************************************************************************
* @author		Nitin Khandelwal
* @date         18.Sept.2018     
* @description  Test Class for FileToCallistaInterface Class
                Wtitten for a single callout
* @revision     
* 08/02/2022 - Vinothraja - SFTG-2365 Added code to bulkify logging during & after callouts
*******************************************************************************/
@isTest(isParallel=false)
public class FileToCallista_Test {
    
    @isTest static void testCallistaFileCreateSuccessful() {
        
        
        
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
            PathOnClient ='/Header_Picture1.jpg',
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
        // Query Contact Document
        List<Contact_Document__c> contactPortfolio = [ SELECT Id, File_Upload_Successful__c, 
                                                                Contact__c,
                                                                Comments__c,
                                                                Contact__r.Person_id__c,
                                                                Contact_Qualification__c,
                                                                Document_Type__c,
                                                                Document_Type_Name__c,
                                                                Filename__c,
                                                                Has_API_Request__c,
                                                                Has_API_Response__c,
                                                                API_Request__c,
                                                                Submitted__c,
                                                                Type__c
                                                FROM Contact_Document__c
                                                WHERE id = :condoc.id
                                        ];
        String contactDocRec = JSON.serialize(contactPortfolio[0]);

        //Query all the ContentDocumentLink
        ContentDocumentLink cdl = [SELECT id,
                                    ContentDocumentId,
                                    ContentDocument.LatestPublishedVersionId,
                                    LinkedEntityId  
                                    FROM 
                                    ContentDocumentLink 
                                    WHERE LinkedEntityId = :contactPortfolio[0].id LIMIT 1];
        String cdlRec = JSON.serialize(cdl);

        //Query the ContentDocument
        ContentDocument cd = [SELECT
                    id,
                    Title,
                    LatestPublishedVersionId,
                    FileExtension,
                    ArchivedById,
                    ArchivedDate,
                    ContentAssetId,
                    ContentModifiedDate,
                    ContentSize,
                    Description,
                    FileType,
                    IsArchived,
                    LastReferencedDate,
                    LastViewedDate,
                    OwnerId,
                    ParentId,
                    PublishStatus,
                    SharingOption,
                    SharingPrivacy
                                  FROM
                                  ContentDocument 
                                  WHERE id = :cdl.ContentDocumentId LIMIT 1];
        String cdRec = JSON.serialize(cd);
        Test.startTest();	
        CallistaFileApiMock mock = new CallistaFileApiMock();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        List<FileToCallistaInterface> callistaRequests = new List<FileToCallistaInterface>();
        
        FileToCallistaInterface fci = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, application.id, null);
        callistaRequests.add(fci);
        fci.sendMessage();
        Test.stopTest();
        
    }
    
}