/**
 *  Test coverage written for the FileviewerCC
    @author  Shalini Mendu
 */
@isTest
public with sharing class FileViewerCC_Test {
    @isTest
    public static void testSomething()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        Application__c app = StudFirst_TestHelper.createApplication(c);
        insert app;

        Contact_Document__c contactDocu = new Contact_Document__c();
        contactDocu = StudFirst_TestHelper.createContactDocument(c.Id);
        contactDocu.Document_Type__c = 'PARENT_GUARDIAN';
        contactDocu.Submitted__c = true;
        insert contactDocu;
        ContentDocument file = createTestDocument(true, app, contactDocu);

        Map<String, Object>  cDocMap =  FileViewerCC.getContactDocuments(app.Id, 'PARENT_GUARDIAN');

        System.assertEquals( cDocMap.size() , 2);
    }
    static ContentDocument createTestDocument(Boolean allAccess, Application__c app, Contact_Document__c cdoc)
    {
        // create a file
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        ContentVersion cv = new ContentVersion(
                Title='Test File',
                PathOnClient ='/Test File.jpg',
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

        if(allAccess)
        {
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.LinkedEntityId = app.Id;
            cdLink.ContentDocumentId = cv.ContentDocumentId;
            cdLink.ShareType = 'v';
            cdLink.Visibility = 'AllUsers';

            insert cdLink;
            
            ContentDocumentLink cdLink2 = new ContentDocumentLink();
            cdLink2.LinkedEntityId = cdoc.Id;
            cdLink2.ContentDocumentId = cv.ContentDocumentId;
            cdLink2.ShareType = 'v';
            cdLink2.Visibility = 'AllUsers';

            insert cdLink2;
            


        }

        return file;
    }
}