@isTest
public class SyncOfferTimelineBatch_Test {

    @TestSetup
    static void createData(){
        //Account Creation
        Account acc1 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 1'), true);

        //Contact Creation
        Contact contact1 = (Contact)TestDataFactory.createSObject(new Contact(
            AccountId = acc1.Id,
            Email='contact1@email.com',
            Firstname='firstname',
            LastName='lastname'
        ), true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id = Test.getStandardPricebookId(), CloseDate = Date.today().addDays(15)),true);
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;

        // Quote record creation
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc1.Id,SBQQ__PricebookId__c = Test.getStandardPricebookId(), SBQQ__PrimaryContact__c=contact1.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress',SBQQ__Opportunity2__c=opp.Id,SBQQ__ExpirationDate__c = opp.CloseDate, SBQQ__Primary__c = true),true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id), true);    
        // mocking history records
        SBQQ__Quote__history quoteHistory1 = new SBQQ__Quote__history(ParentId = quote.Id, Field = 'Sub_Status__c');
        insert quoteHistory1;
        SBQQ__Quote__history quoteHistory2 = new SBQQ__Quote__history(ParentId = quote.Id, Field = 'created');
        insert quoteHistory2;
    }

    @isTest
    public static void testExecute() {
        
        SBQQ__Quote__c[] quotes = [SELECT ID, SBQQ__Status__c, SBQQ__Opportunity2__c,
                                   Sub_Status__c, SBQQ__PrimaryContact__c
                                   FROM SBQQ__Quote__c];
        SBQQ__Quote__c quote = quotes[0];
        Test.startTest();

        Database.executeBatch(new SyncOfferTimelineBatch(''), 1);
        Test.stopTest();

        quotes = [SELECT Offer_Creation_TimeStamp__c, Products_Added_TimeStamp__c,
                                   (SELECT Field, NewValue, CreatedDate FROM Histories WHERE Field IN ('Sub_Status__c', 'created')) 
                                   FROM SBQQ__Quote__c WHERE id = :quote.id];
        
        SBQQ__Quote__c updatedQuote = quotes[0];
        Map<String, Datetime> mapStatusTimestamps = new Map<String, Datetime> ();
        for (SBQQ__Quote__history historyRecord : updatedQuote.Histories) {
            mapStatusTimestamps.put((String)historyRecord.Field, (Datetime)historyRecord.CreatedDate);
        }
        System.assert(updatedQuote.Offer_Creation_TimeStamp__c == mapStatusTimestamps.get('created'), 'Creation timestamps not updated properly');
        System.assert(updatedQuote.Products_Added_TimeStamp__c == mapStatusTimestamps.get('Sub_Status__c'), 'SubStatus based timestamp not updated properly');
    }
}