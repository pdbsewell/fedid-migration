/*******************************************************************************
* @author		Sethu Venna
* @date         05/10/2024    
* @description  Test Class for GRSendContentDocFromPlatformEvent Class
* @revision     05/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class GRSendContentDocFromPlatformEvent_Test {

    @TestSetup
    static void makeData() {
        Map<Integer,String> fileExtensionMap = new Map<Integer,String>{
            0 => '.pdf',
            1 => '.doc',
            2 => '.docx',
            3 => '.txt',
            4 => '.gif',
            5 => '.jpeg',
            6 => '.jpg',
            7 => '.png',
            8 => '.bmp',
            9 => '.tiff'
        };

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

        List<Contact_Document__c> conDocList = new List<Contact_Document__c>();
        for(Integer i=0; i < 10 ; i++) {
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = newContact.id;
            conDoc.Application__c = app.Id;
            conDoc.Document_Type__c = 'PARENT_GUARDIAN';
            conDoc.Filename__c = 'testdoc';
            conDocList.add(conDoc);
        }
        insert conDocList;

        List<ContentVersion> cvList = new List<ContentVersion>();
        for(Integer i=0; i < 10 ; i++) {
            Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
            ContentVersion contentVersionRec = new ContentVersion(
                Title='Header_Picture1', 
                PathOnClient ='/Header_Picture1'+fileExtensionMap.get(i),
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

        insert new Feature_Switch__c(Graduate_Research_Integration__c = true);

    }
    /**
     * @author          Sethu Venna
     * @description     for successful callista file creation
     * @revision        05/10/2024 - Initial Version
     */
    @isTest 
    static void testCallistaFileCreateSuccessful() {
        Test.startTest();	
        GRCallistaFileApiMock_Test mock = new GRCallistaFileApiMock_Test();
        mock.responseCode = 200;
        Test.setMock(HttpCalloutMock.class, mock);
        //GIVEN  GR Contact documents are submitted
        Map<Id, Contact_Document__c> conDocs = new Map<Id, Contact_Document__c>(
                                                        [SELECT Id FROM Contact_Document__c]
                                                    );
        //WHEN Document integration callout is successful for all the documents
        GRSendContentDocFromPlatformEvent.execute(conDocs.keyset());
        Test.stopTest();
        List<Contact_Document__c> conDocList = [SELECT Callista_Document_Id__c FROM Contact_Document__c WHERE Callista_Document_Id__c <> NULL];
        //THEN System should update Callista_Document_Id__c
        Assert.isTrue(!conDocList.isEmpty(), 'Callista_Document_Id__c is populated');
        
    }  
    
}