@isTest
public with sharing class ContentDocumentLinkTriggerHandler_Test {
    @isTest
    private static void test_handler(){ 
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(),true);
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.enable();
        ContentVersion contentVersion = (contentVersion)TestDataFactory.createSObject(
            new ContentVersion(
                FirstPublishLocationId = quote.Id,
                Title = 'Preview_Test'+quote.Name,
                PathOnClient = 'Preview_Test.pdf',
                VersionData = Blob.valueOf('Test Preview ISCA Content'),
                IsMajorVersion = true
        ),true);
    }   
}