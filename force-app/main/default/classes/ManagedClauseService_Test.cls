/**
* @author Jasmin Joy Rudio
* @description Apex test class for ManagedClauseService class
* @group SF Offers
*
**/
@isTest
private class ManagedClauseService_Test {
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
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c=pb.id,SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='In Review',Sub_Status__c='Preview Requested',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c=myDate,SBQQ__Primary__c=true),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);
        SBQQ.TriggerControl.enable();
    }
	@isTest static void selectByQuoteLocation() { 
        SBQQ__Quote__c[] quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        String clauseJson = ManagedClauseService.getManagedClauseByQuoteId(quote[0].Id); 
        System.assert(clauseJson <> null);
    }
    @isTest static void selectByQuoteLineLocation() { 
        SBQQ__QuoteLine__c[] quote = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        String clauseJson = ManagedClauseService.getManagedClauseByQuoteLineLocation(quote[0].Id,'Australia');
        System.assert(clauseJson <> null);
    }
}