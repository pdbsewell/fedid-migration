/**
 * @author       P.Victoriano
 * @date         08/Aug/2023
 * @description  Test Class for Attachment to File converter
 * @revision
 *               08.Aug.23 P.Victoriano - Create Class
 **/
@isTest(isParallel=true)
public with sharing class ConvertAttachmentToFileBatch_Test {
    @isTest
    static void startTest() {
        //GIVEN - Some Context Before Tests
        ConvertAttachmentToFileBatch bch = new ConvertAttachmentToFileBatch();
        //WHEN - Behaviour to Test
        Database.QueryLocator ql = bch.start(null);
        Assert.isNotNull(ql, 'Error Database.QueryLocator');
        bch.finish(null);
        //THEN - Expected Context After Test
        Assert.areEqual('SELECT Id, Name, Body, ContentType, ParentId, Description, OwnerId, CreatedDate From Attachment', bch.soqlStr, 'Exception in SOQL String');
    }
    @isTest
    static void executeTest() {
        List<Attachment> lstAttachments = new List<Attachment>();
        //GIVEN - Some Context Before Tests
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'TestLast';
        insert con;
        //
        Attachment attach=new Attachment();
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.Description = 'Test Attachment';
        attach.body=bodyBlob;
        attach.parentId=con.Id;
        attach.OwnerId=UserInfo.getUserId();
        lstAttachments.add(attach);
        insert lstAttachments;
        //WHEN - Behaviour to Test
        Test.startTest();
        ConvertAttachmentToFileBatch bch = new ConvertAttachmentToFileBatch();
        bch.execute(null, lstAttachments);
        //
        Test.stopTest();
        //THEN - Expected Context After Test
        List<Exception_Log__c> errors = [SELECT Function_Name__c, Input__c, Message__c FROM Exception_Log__c];
        Assert.areEqual(0, errors.size(), 'Error: '+JSON.serializePretty(errors));
        Assert.areEqual(0, [SELECT count() FROM Attachment WHERE ParentId =: con.Id], 'Failed to Convert Attachments');
    }
}