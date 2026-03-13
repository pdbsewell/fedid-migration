/**
* @author Mathew Jose
* @description Apex test class for ContentDocumentLinksService class
* @group SF Offers
*
**/
@isTest
public with sharing class ContentDocumentLinksSelector_Test {

    @testSetup static void setup() {
        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        ContentVersion contentVersion = (contentVersion)TestDataFactory.createSObject(
            new ContentVersion(
                FirstPublishLocationId = acc1.Id,
                Title = 'Preview_Test',PathOnClient = 'Preview_Test.pdf',
                VersionData = Blob.valueOf('Test Preview ISCA Content'),
                IsMajorVersion = true),
            true);
    }

    @isTest
    private static void selectByIdWithEntityTypeTest(){   
        Account acc = [Select Id from Account where Name = 'Test Accnt 1' limit 1];
        List<ContentDocumentLink> cdlList = [Select Id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where linkedentityid = : acc.Id];
        Test.startTest();      
        new ContentDocumentLinksSelector(false);
        Map<Id, ContentDocumentLink> cdlByIdWithEntityTypeMap = new ContentDocumentLinksSelector().selectByIdWithEntityType(new Map<Id,ContentDocumentLink>(cdlList).keySet());
        Test.stopTest();
        System.AssertEquals(cdlByIdWithEntityTypeMap.get(cdlList[0].Id).ContentDocumentId,cdlList[0].ContentDocumentId);
    }
}