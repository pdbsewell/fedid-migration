/*******************************************************************************
* @author       Sethu Venna
* @date         05/10/2024
* @description  test class for GRSendDocumentToCallistaService
* @revision      
* 05/10/2024 - Sethu Venna - Initial version
*******************************************************************************/
@IsTest(isParallel = true)
public class GRSendDocumentToCallistaService_Test {

    @TestSetup
    static void makeData() {
        Contact newContact = new Contact();
        newContact.FirstName = 'FN in GRSendContentDocQueuable_Test';
        newContact.LastName = 'LN in GRSendContentDocQueuable_Test';
        insert newContact;

        Application__c app = new Application__c();
        app.Applicant__c = newContact.id;
        app.Callista_Applicant_Id__c = 'testApp1';
        app.Type_Of_Study__c = 'Graduate Research';
        app.Status__c = 'Sent for Submission';
        insert app;

        Contact_Document__c conDoc = new Contact_Document__c();
        conDoc.Contact__c = newContact.id;
        conDoc.Application__c = app.Id;
        conDoc.Document_Type__c = 'PARENT_GUARDIAN';
        conDoc.Filename__c = 'testdoc';
        insert conDoc;

        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
        ContentVersion contentVersionRec = new ContentVersion(
            Title='Header_Picture1', 
            PathOnClient ='/Header_Picture1'+'.pdf',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersionRec;
        
        contentVersionRec = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = conDoc.Id;
        cdl.ContentDocumentId = contentVersionRec.ContentDocumentId;
        cdl.ShareType = 'V';
        insert cdl;
    }

    /**
     * @author       Sethu Venna
     * @GIVEN        GRSendDocumentToCallistaService object is invoked with valid Contact Document object
     * @WHEN         System triggers the class
     * @THEN         Test to ensure request body is not null
     * @revision     05/10/2024 - Initial Version - could move to custom metadata
     */
    static testMethod void testCreateRequestBody() {
        Contact_Document__c cdRec = [SELECT Id FROM Contact_Document__c LIMIT 1];
        ContentDocumentLink cdl = [SELECT
                                    Id,
                                    ContentDocumentId,
                                    ContentDocument.LatestPublishedVersionId,
                                    ContentDocument.FileExtension, 
                                    LinkedEntityId  
                                    FROM 
                                    ContentDocumentLink 
                                    WHERE LinkedEntityId = :cdRec.Id
                                    LIMIT 1];
        List<Contact_Document__c> condocList = new ContactDocumentsSelector().selectByIdWithRelatedApplicationDetails(new Set<Id>{cdRec.Id});
        GRSendDocumentToCallistaService obj = new GRSendDocumentToCallistaService(
            condocList[0],
            cdl,
            [SELECT
            Id,
            ContentDocumentId,
            VersionData
            FROM 
            ContentVersion 
            WHERE ContentDocumentId = :cdl.ContentDocumentId
            AND IsLatest = :true
            LIMIT 1]
        );
        obj.createRequestBody();
        Assert.isNotNull(obj.jsonRequest, 'JSON request has to be created');
	}

    /**
     * @author       Sethu Venna
     * @GIVEN        GRSendDocumentToCallistaService object is invoked with valid Contact Document object
     * @WHEN         System triggers the handle response class
     * @THEN         Test to ensure response body is not null
     * @revision     05/10/2024 - Initial Version - could move to custom metadata
     */
    static testMethod void testHandleResponse() {
        Test.startTest();	
        GRCallistaFileApiMock_Test mock = new GRCallistaFileApiMock_Test();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        Contact_Document__c cdRec = [SELECT Id FROM Contact_Document__c LIMIT 1];
        ContentDocumentLink cdl = [SELECT
                                    Id,
                                    ContentDocumentId,
                                    ContentDocument.LatestPublishedVersionId,
                                    ContentDocument.FileExtension, 
                                    LinkedEntityId  
                                    FROM 
                                    ContentDocumentLink 
                                    WHERE LinkedEntityId = :cdRec.Id
                                    LIMIT 1];
        List<Contact_Document__c> condocList = new ContactDocumentsSelector().selectByIdWithRelatedApplicationDetails(new Set<Id>{cdRec.Id});
        GRSendDocumentToCallistaService obj = new GRSendDocumentToCallistaService(
            condocList[0],
            cdl,
            [SELECT
            Id,
            ContentDocumentId,
            VersionData
            FROM 
            ContentVersion 
            WHERE ContentDocumentId = :cdl.ContentDocumentId
            AND IsLatest = :true
            LIMIT 1]
        );
        obj.createRequestBody();
        obj.sendMessage();
        obj.handleResponse();
        Test.stopTest();
        Assert.isNotNull(obj.contactDocumentRec.Callista_Document_Id__c, 'Callista doc Id needs to be populated');
	}
    /**
     * @author       Vishal Gupta
     * @GIVEN        GRSendDocumentToCallistaService is invoked post application submission
     * @WHEN         System triggers the handle response class
     * @THEN         Test to ensure response body is not null
     * @revision     4/11/2024 - Initial Version
     */
    static testMethod void testPostApplicationSubmission() {
        Map<Integer,String> fileExtensionMap = new Map<Integer,String>{
            0 => 'pdf',
            1 => 'doc',
            2 => 'docx',
            3 => 'txt',
            4 => 'gif',
            5 => 'jpeg',
            6 => 'jpg',
            7 => 'png',
            8 => 'bmp',
            9 => 'tiff'
        };

        Contact newContact = new Contact();
        newContact.FirstName = 'FN in GRSendContentDocQueuable_Test';
        newContact.LastName = 'LN in GRSendContentDocQueuable_Test';
        insert newContact;

        Application__c app = new Application__c();
        app.Applicant__c = newContact.id;
        app.Callista_Applicant_Id__c = 'testApp1';
        app.Type_Of_Study__c = 'Graduate Research';
        app.Status__c = 'Submitted';
        insert app;

        List<Contact_Document__c> conDocList = new List<Contact_Document__c>();
        for(Integer i=0; i < 10 ; i++) {
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = newContact.id;
            conDoc.Application__c = app.Id;
            conDoc.Document_Type__c = 'PARENT_GUARDIAN';
            conDoc.Filename__c = 'testdoc';
            conDoc.Post_Submission__c = true;
            conDocList.add(conDoc);
        }
        insert conDocList;

        List<ContentVersion> cvList = new List<ContentVersion>();
        for(Integer i=0; i < 10 ; i++) {
            Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
            ContentVersion contentVersionRec = new ContentVersion(
                Title='Header_Picture1', 
                PathOnClient ='/Header_Picture1.'+fileExtensionMap.get(i),
                VersionData = bodyBlob, 
                origin = 'H'
            );
            cvList.add(contentVersionRec);
        }
        Database.SaveResult[] saveCVList = Database.insert(cvList, false);
        Set<Id> cvIdSet = new Set<Id>();
        for (Database.SaveResult sr : saveCVList) {
            if (sr.isSuccess()) {
                cvIdSet.add(sr.getId());
            }
        }
        
        List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
        Integer i = 0;
        for(ContentVersion contentVersionRec : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIdSet]) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = conDocList.get(i).Id;
            cdl.ContentDocumentId = contentVersionRec.ContentDocumentId;
            cdl.ShareType = 'V';
            cdLinkList.add(cdl);
            i++;
        }
        insert cdLinkList;

        Test.startTest();	
        GRCallistaFileApiMock_Test mock = new GRCallistaFileApiMock_Test();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        Contact_Document__c cdRec = [SELECT Id FROM Contact_Document__c LIMIT 1];
        ContentDocumentLink cdl = [SELECT
                                    Id,
                                    ContentDocumentId,
                                    ContentDocument.LatestPublishedVersionId,
                                    ContentDocument.FileExtension, 
                                    LinkedEntityId  
                                    FROM 
                                    ContentDocumentLink 
                                    WHERE LinkedEntityId = :cdRec.Id
                                    LIMIT 1];
        ContentVersion cv = [SELECT
                                Id,
                                ContentDocumentId,
                                VersionData
                                FROM 
                                ContentVersion 
                                WHERE ContentDocumentId = :cdl.ContentDocumentId
                                AND IsLatest = :true
                                LIMIT 1];              
        for(Integer count=0; count < 10 ; count++) {
            GRSendDocumentToCallistaService obj = new GRSendDocumentToCallistaService(
                condocList[0],
                cdl,
                cv
            );
            obj.createRequestBody();
            obj.sendMessage();
            obj.handleResponse();
            obj.mapContentType(fileExtensionMap.get(count));
            Assert.isNotNull(obj.contactDocumentRec.Callista_Document_Id__c, 'Callista doc Id needs to be populated');
        }
        Test.stopTest();
        
	}
}