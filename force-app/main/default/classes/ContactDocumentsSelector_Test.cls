/*******************************************************************************
* @author		Sethu Venna
* @date         24/10/2024    
* @description  Test Class for GRSendContentDocFromPlatformEvent Class
* @revision     24/10/2024 - Initial Version
*******************************************************************************/
@isTest(isParallel = true)
public class ContactDocumentsSelector_Test{

    @TestSetup
    static void makeData() {
        Contact newContact = new Contact();
        newContact.FirstName = 'FN in GRSendContentDocQueuable_Test';
        newContact.LastName = 'LN in GRSendContentDocQueuable_Test';
        insert newContact;

        Application__c app = new Application__c();
        app.Applicant__c = newContact.id;
        app.Callista_Applicant_Id__c = 'testApp1';
        app.Type_Of_Study__c = Constants.STUDYTYPE_GRADUATERESEARCH;
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
     * @author          Sethu Venna
     * @description     for successful callista file creation
     * GIVEN            a list of contact documents
     * WHEN             the ask is retrive them by idset
     * THEN             System should fetch all the contact documents by Id set
     * @revision        24/10/2024 - Initial Version
     */
    @isTest 
    static void testSelectByIdWithRelatedApplicationDetails() {
        Test.startTest();	
        Contact_Document__c cd = [SELECT Id FROM Contact_Document__c LIMIT 1];
        List<Contact_Document__c> conDocList = new List<Contact_Document__c>(new ContactDocumentsSelector().selectByIdWithRelatedApplicationDetails(new Set<Id>{cd.Id}));
        Assert.isNotNull(conDocList, 'Contact documents should be retrieved');
        Test.stopTest();
    }

    /**
     * @author          Sethu Venna
     * @description     for successful callista file creation
     * GIVEN            a list of contact documents
     * WHEN             the ask is retrive them by idset
     * THEN             System should fetch all the contact documents by Id set
     * @revision        24/10/2024 - Initial Version
     */
    @isTest 
    static void testSelectByApplicationIdWithEmptyCallistaDocId() {
        Test.startTest();	
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];
        List<Contact_Document__c> conDocList = new List<Contact_Document__c>(new ContactDocumentsSelector().selectByApplicationIdWithEmptyCallistaDocId(new Set<Id>{app.Id}));
        Assert.isNotNull(conDocList, 'Contact documents should be retrieved');
        Test.stopTest();
    }

}