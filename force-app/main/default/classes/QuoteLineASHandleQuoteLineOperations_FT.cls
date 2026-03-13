/**
 * @description     :   Test class for Quote Line : AS : Handle Quote Line Operations Flow
 * @author          :   Vinothraja
 * @date            :   23-05-2025
 * @group           :   Platforms
 * @revision
 *  23-05-2025      Vinothraja    - EPCP-4537  created 
 */ 
@isTest( isParallel = false ) // Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class QuoteLineASHandleQuoteLineOperations_FT {
    @TestSetup
    static void makeData(){
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');

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
        Account acc2 = (Account)TestDataFactory.createSObject(new Account(Name='Test Accnt 2'), true);

        //Creating a product for scholarship
        Product2 product1 = (Product2)TestDataFactory.createSObject(new Product2(Name='Monash Scholarship1', Family = 'Scholarship', Description__c = 'Monash Scholarship1', Description = 'Monash Scholarship1', Type__c = 'Capped', Quota_Original__c = 5, Face_Value__c = 100, Value_Deductable__c = 50, External_Id__c='12345', Expiry_days__c=15),true);
		//product always required a standard pricebook         
        PricebookEntry pbe1 = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product1.id, unitprice=-5000),true);

        //Contact Creation
        date bday1 = date.newInstance(1983, 7, 15);
        Contact contact = (Contact)TestDataFactory.createSObject(new Contact(FirstName='Test', Lastname='Con1',AccountId = acc1.Id, Birthdate = bday1,Country_of_Residence__c='INDIA'), true);

        SBQQ.TriggerControl.disable();
        // Opportunity creation
        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId=acc1.Id,Pricebook2Id=pb.id, CloseDate = Date.today().addDays(15)),true);
        
        // Quote creation
        SBQQ__Quote__c quote = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c=acc2.Id,SBQQ__PricebookId__c=Test.getStandardPricebookId(),SBQQ__PrimaryContact__c=contact.Id,SBQQ__Status__c='Created',Sub_Status__c='In Progress', SBQQ__Opportunity2__c = opp.Id, SBQQ__ExpirationDate__c = opp.CloseDate),true);

        //QuoteLineItem Creation
        SBQQ__QuoteLine__c qli = (SBQQ__QuoteLine__c) TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.id,SBQQ__Product__c=product1.Id, Expiry_Date__c = Date.today().addDays(10), SBQQ__Quantity__c = 1, SBQQ__PricebookEntryId__c = pbe1.id), false);
        insert qli; 

		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
    }
    /**
     * Test method to verify whether an expiring Quoteline is updated with the correct status or not
     */
    @isTest
    private static void testExpiringQuoteLineUpdateProductStatus() {
        // GIVEN
        // A valid quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__Quote__c, Expiry_Date__c 
                                            FROM SBQQ__QuoteLine__c 
                                            WHERE SBQQ__Product__r.Name = 'Monash Scholarship1' LIMIT 1];

        // WHEN 
        // The Quote lines are set to Expire within 2 days
        Test.startTest();
            quoteLine.Expiry_Date__c = Date.today().addDays(1);
            update quoteLine;
        Test.stopTest();   

        // THEN
        // Quote line -> Quote -> Product Status is populated with 'Products due to expire'
        quoteLine = [SELECT SBQQ__Quote__r.Product_Status__c, SBQQ__Quote__r.Product_Status_modified__c, Expiry_Date__c FROM SBQQ__QuoteLine__c WHERE id = :quoteLine.Id LIMIT 1];
        Assert.areEqual('Products due to expire', quoteLine.SBQQ__Quote__r.Product_Status__c, 'Quote\'s Product Status is not populated properly');
    }
    /**
     * Test method to verify whether an expired Quoteline (Scholarship) is updated with the correct status or not, along with the assigned quotas
     */
    @isTest
    private static void testExpiredQuoteLineUpdateProductStatus() {
        // GIVEN
        // A valid Scholarship quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__Quote__c, Expiry_Date__c, SBQQ__Product__r.Quota_Assigned__c 
                                            FROM SBQQ__QuoteLine__c 
                                            WHERE SBQQ__Product__r.Name = 'Monash Scholarship1' LIMIT 1];
        Decimal earlierQuota = quoteLine.SBQQ__Product__r.Quota_Assigned__c;

        // WHEN 
        // The Quote lines have Expired
        Test.startTest();
            quoteLine.Expiry_Date__c = Date.today().addDays(-2);
            update quoteLine;
        Test.stopTest();   

        // THEN
        quoteLine = [SELECT SBQQ__Quote__r.Product_Status__c, SBQQ__Quote__r.Product_Status_modified__c, SBQQ__Product__r.Quota_Assigned__c, Expiry_Date__c 
                        FROM SBQQ__QuoteLine__c 
                        WHERE id = :quoteLine.Id LIMIT 1];
        // Quote line -> Quote -> Product Status is populated with 'Scholarship expired'
        Assert.areEqual('Scholarship expired', quoteLine.SBQQ__Quote__r.Product_Status__c, 'Quote\'s Product Status is not populated properly');
        // Quote line -> Quote -> Product Quota is reduced by 1
        Assert.areEqual(earlierQuota-1, quoteLine.SBQQ__Product__r.Quota_Assigned__c, 'Quote\'s Product Quota is not populated properly');
    }
    /**
     * Test method to verify whether an expired Quoteline is updated with the correct status or not, along with the assigned quotas
     */
    @isTest
    private static void testAddQuoteLine() {
        // GIVEN
        // A valid Scholarship quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__Quote__c, Expiry_Date__c, SBQQ__Product__r.Quota_Assigned__c 
                                            FROM SBQQ__QuoteLine__c 
                                            WHERE SBQQ__Product__r.Name = 'Monash Scholarship1' LIMIT 1];
        Decimal earlierQuota = quoteLine.SBQQ__Product__r.Quota_Assigned__c;
        SBQQ__QuoteLine__c clonedQuoteLine = quoteLine.clone(false, true, false, false);

        // WHEN 
        // The Quote line is added
        Test.startTest();
            insert clonedQuoteLine;
        Test.stopTest();   

        // THEN
        clonedQuoteLine = [SELECT SBQQ__Quote__r.Product_Status__c, SBQQ__Quote__r.Product_Status_modified__c, SBQQ__Product__r.Quota_Assigned__c, Expiry_Date__c, Is_Grant__c, Is_Scholarship__c 
                                FROM SBQQ__QuoteLine__c 
                                WHERE id = :clonedQuoteLine.Id LIMIT 1];

        // Quote line -> Quote -> Product Quota is increased by 1
        Assert.areEqual(earlierQuota+1, clonedQuoteLine.SBQQ__Product__r.Quota_Assigned__c, 'Quote\'s Product Quota is not populated properly');
        // Quote line -> Expiry date is set 
        Assert.areEqual(Date.today().addDays(15), clonedQuoteLine.Expiry_Date__c, 'QuoteLine\'s Expiry date is not populated properly');
        // Quote Line is identified as Scholarship correctly
        Assert.isTrue(clonedQuoteLine.Is_Scholarship__c, 'QuoteLine\'s Scholarship flag is not populated properly');
        Assert.isFalse(clonedQuoteLine.Is_Grant__c, 'QuoteLine\'s Grant flag is not populated properly');
    }

}