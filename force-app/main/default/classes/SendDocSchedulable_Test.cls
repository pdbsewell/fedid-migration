/**
 * @author           Majid Reisi Dehkordi
 * @description      Test class for SendDocSchedulable
 * @revision         8-01-2020 Martin Cadman. Added a File to the mix to increase code coverage.
*/
@isTest(isParallel=true)
public class SendDocSchedulable_Test {

    static testmethod void testScheduledJob() {
        // Create a Contact
        Contact contactVar = new Contact(lastName = 'lastNameExample');
        insert contactVar;

        Contact contactVar2 = new Contact(lastName = 'lastNameExample2');
        insert contactVar2;

        // Create a Contact Document
        Contact_Document__c contactDocumentVar1 = new Contact_Document__c();
        contactDocumentVar1.Contact__c = contactVar.Id;
        contactDocumentVar1.Document_Type__c = 'PRF_NAME';
        insert contactDocumentVar1;
        
        // Create a Contact Document
        Contact_Document__c contactDocumentVar2 = new Contact_Document__c();
        contactDocumentVar2.Contact__c = contactVar.Id;
        contactDocumentVar2.Document_Type__c = 'PRF_NAME';
        contactDocumentVar2.Email_Attachment_Id__c = '2222222';
        insert contactDocumentVar2;

        // Create a Contact Document
        Contact_Document__c contactDocumentVar3 = new Contact_Document__c();
        contactDocumentVar3.Contact__c = contactVar2.Id;
        contactDocumentVar3.Document_Type__c = 'PRF_NAME';
        contactDocumentVar3.Email_Attachment_Id__c = '3333333';
        insert contactDocumentVar3;
        
        // Create a file for the first contact document
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.Origin = 'H';
        cv.Title = 'title of the document';
        cv.PathOnClient ='test';

        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');

        cv.FirstPublishLocationId = contactDocumentVar1.Id;
        insert cv;
        
        // Create an attachment for the first contact document
        Attachment attachVar = new Attachment();       
        attachVar.Name = 'Unit Test Attachment';
        Blob bodyBlob1 = Blob.valueOf('Unit Test Attachment Body');
        attachVar.body = bodyBlob1;
        attachVar.parentId = contactDocumentVar1.id;
        insert attachVar;
        
        // Create an attachment for the second contact document
        Attachment attachVar2 = new Attachment();       
        attachVar2.Name = 'Unit Test Attachment';
        Blob bodyBlob2 = Blob.valueOf('Unit Test Attachment Body');
        attachVar2.body = bodyBlob2;
        attachVar2.parentId = contactDocumentVar2.id;
        insert attachVar2;

        // Create an attachment for the third contact document. This wil be converted into a file
        Attachment attachVar3 = new Attachment();       
        attachVar3.Name = 'Unit Test Attachment';
        Blob bodyBlob3 = Blob.valueOf('Unit Test Attachment Body');
        attachVar3.body = bodyBlob3;
        attachVar3.parentId = contactDocumentVar3.id;
        insert attachVar3;
        
        //Get attachment
        Attachment attach = [SELECT Id, Name, Body, ContentType, ParentId, OwnerId From Attachment where id = :attachVar3.id];
         
        //Insert ContentVersion
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = attach.Name;//File name with extention
        cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
        cVersion.OwnerId = attach.OwnerId;//Owner of the file
        cVersion.Title = attach.Name;//Name of the file
        cVersion.VersionData = attach.Body;//File content
        Insert cVersion;
         
        //After saved the Content Verison, get the ContentDocumentId
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
         
        //Insert ContentDocumentLink
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
        cDocLink.LinkedEntityId = attach.ParentId;//Add attachment parentId
        cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
        Insert cDocLink;
        
        Test.startTest();
        // Schedule the test job
        SendDocSchedulable sendDocs = new SendDocSchedulable();
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String sch = '0 0 8/12 * * ? *';
        String jobID = System.schedule('Send unsuccessful docs to Callilsta TEST', sch, sendDocs);
        
        // Stopping the test will run the job
        Test.stopTest();
        
        // Now the scheduled job has executed,
        // check that our Contact Documents were created
        List<Contact_Document__c> numberOfCDs = [SELECT Id FROM Contact_Document__c];
        System.assertEquals(numberOfCDs.size(), 3, 'Contact Documents were not created');
    }
   
}