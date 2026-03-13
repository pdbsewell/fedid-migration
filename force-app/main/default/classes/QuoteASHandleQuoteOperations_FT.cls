/**
 * @description     :   Test class for Quote : AS : Handle Quote Operations Flow
 * @author          :   Vinothraja
 * @date            :   14-04-2025
 * @group           :   Platforms
 * @revision
 *  14-04-2025      Vinothraja    - EPCP-4536  created test class to test the Quote : AS : Handle Quote Operations Flow
 */ 
@isTest( isParallel = false ) // Test.getStandardPricebookId() cannot be called from parallel Apex tests
public with sharing class QuoteASHandleQuoteOperations_FT {
    /**
     * Test method to verify whether the Error Logging node in the Flow is working as expected.
     */
    @isTest
    private static void testErrorLogging() {
        // GIVEN
        // A Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Sub_Status__c = 'Preview Requested');

        // WHEN
        // Create a new Quote
        Test.startTest();
            insert quote;
        Test.stopTest();

        // THEN
        // Verify that the Quote was created successfully and the Error_Tracking_Start_Date_Time__c field is set
        SBQQ__Quote__c insertedQuote = [SELECT Id, Sub_Status__c, Error_Tracking_Start_Date_Time__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.isNotNull(insertedQuote.Error_Tracking_Start_Date_Time__c, 'The Quote\'s Error_Tracking_Start_Date_Time__c should be set.');
    }

    /**
     * Test method to verify whether the Outbound message node in the Flow are reachable
     * NOTE: The actual Outbound messages cannot be tested. So if it takes the outbound message path, then we assume that the outbound message is sent successfully.
     */
    @isTest 
    private static void testISCAContractUpdateReqDate() {
        // GIVEN
        // A Product
        Product2 product = (Product2)TestDataFactory.createSObject(new Product2(), 'TestDataFactorySettings.MonashGrantScholarshipDefaults', false);
        insert product;
        // Price book 
        Pricebook2 pb = (Pricebook2) TestDataFactory.createSObject(new Pricebook2(), true);
        PricebookEntry pbe = (PricebookEntry)TestDataFactory.createSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.id),true);
        // Opportunity 
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', 
                                                    Pricebook2Id = pb.id, 
                                                    CloseDate = Date.today(), 
                                                    Offer_Category__c = 'Online Offer');
        insert opp;
        // A valid Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Sub_Status__c = 'Details completed',
                                                    SBQQ__Status__c = 'Published',
                                                    SBQQ__Opportunity2__c = opp.Id);

        // WHEN
        // Quote is created
        Test.startTest();
            insert quote;
        Test.stopTest();

        // THEN
        // Verify that the Contract_Generation_Requested_Date__c was set  
        SBQQ__Quote__c insertedQuote = [SELECT Id, Sub_Status__c, Contract_Generation_Requested_Date__c, Offer_Category__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.isNotNull(insertedQuote.Contract_Generation_Requested_Date__c, 'The Quote\'s Contract_Generation_Requested_Date__c should be set.');
    }
}