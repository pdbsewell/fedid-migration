/**
* @author Mathew Jose
* @description Apex test class for ContentDocumentLinksService class
* @group SF Offers
*
**/
@isTest
public with sharing class ContentDocumentLinksService_Test {

    @testSetup static void setup() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            External_ID__c = 'STD'
        );
        update standardPricebook;

        //Price book Creation
        Pricebook2 pb = (Pricebook2)TestDataFactory.createSObject(new Pricebook2(),true);
        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(FirstName='Test', Lastname='Con1',AccountId = acc1.Id, Country_of_Residence__c='INDIA'), true);
        Date myDate = Date.today();
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2=pb,PrimaryContact__c=contact1.Id,closedate=myDate,StageName='Processing Offer'),true);
        SBQQ.TriggerControl.disable();
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='In Review',Sub_Status__c='Preview Requested',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c=myDate,SBQQ__Primary__c=true),true);
        SBQQ.TriggerControl.enable();
    }

    @isTest
    private static void linkPreviewTest(){ 
        SBQQ__Quote__c quote = [SELECT Id,Name,SBQQ__Status__c, Sub_Status__c, SBQQ__PrimaryContact__c,SBQQ__PrimaryContact__r.Country_of_Residence__c,SBQQ__PrimaryContact__r.Under_18__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c where SBQQ__PrimaryContact__r.Lastname='Con1' limit 1];
        TriggerCommon.disableTrigger('ContentDocumentLink');
        ContentVersion contentVersion = (contentVersion)TestDataFactory.createSObject(
            new ContentVersion(
                FirstPublishLocationId = quote.Id,
                Title = 'Preview_Preview_Test_'+quote.Name,
                PathOnClient = 'Preview_Preview_Test_'+quote.Name+'.pdf',
                VersionData = Blob.valueOf('Test Preview ISCA Content'),
                IsMajorVersion = true
        ),true);

        Test.startTest();  
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        QuoteTriggerHandler.lockUserCreation = true;
        ContentDocumentLink[] quoteDoc = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :quote.Id];
        ContentDocumentLinksService.testRequireReview = true;
        new ContentDocumentLinksService.QuoteToOppContentLinkGenerator(new Set<ID>{quoteDoc[0].Id},new Set<String>{quote.Id}).execute();
        Test.stopTest();
        ContentDocumentLink[] opptyDoc = [Select Id, LinkedEntityId, ContentDocumentId, ContentDocument.title from ContentDocumentLink where LinkedEntityId = :quote.SBQQ__Opportunity2__c];
        System.assertEquals(opptyDoc[0].LinkedEntityId,quote.SBQQ__Opportunity2__c);
    } 

     @isTest
    private static void linkPublishedContractTest(){ 
        SBQQ__Quote__c quote = [SELECT Id,Name,SBQQ__Status__c,Sub_Status__c,SBQQ__PrimaryContact__c,SBQQ__PrimaryContact__r.Country_of_Residence__c,SBQQ__PrimaryContact__r.Under_18__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c where SBQQ__PrimaryContact__r.Lastname='Con1' limit 1];
        TriggerCommon.disableTrigger('ContentDocumentLink');
        ContentVersion contentVersion = (contentVersion)TestDataFactory.createSObject(
            new ContentVersion(
                FirstPublishLocationId = quote.Id,
                Title = 'Final_Test_'+quote.Name,
                PathOnClient = 'Final_Test_'+quote.Name+'.pdf',
                VersionData = Blob.valueOf('Test Preview ISCA Content'),
                IsMajorVersion = true
        ),true);
        Test.startTest();      
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        QuoteTriggerHandler.lockUserCreation = true;
        quote.SBQQ__Status__c = 'Published';
        quote.Sub_Status__c = 'Details completed';
        update quote;
        ContentDocumentLink[] quoteDoc = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :quote.Id];
        new ContentDocumentLinksService.QuoteToOppContentLinkGenerator(new Set<ID>{quoteDoc[0].Id},new Set<String>{quote.Id}).execute();
        Test.stopTest();
        ContentDocumentLink[] cdls = [Select Id, LinkedEntityId, ContentDocumentId, ContentDocument.title from ContentDocumentLink where LinkedEntityId = :quote.SBQQ__Opportunity2__c];
        System.assertEquals(cdls[0].LinkedEntityId,quote.SBQQ__Opportunity2__c);
    }   
    @isTest
    private static void test_error(){ 
        ContentDocumentLinksService.QuoteToOppContentLinkGenerator handler = new ContentDocumentLinksService.QuoteToOppContentLinkGenerator(null,null);
        handler.execute();
        handler.commitAll(
            new ContentDocumentLink[]{new ContentDocumentLink(ShareType='V')},
            new Opportunity[]{new Opportunity()},
            new SBQQ__Quote__c[]{new SBQQ__Quote__c()}
        );
    }

}