/**
 * @description     :   Test class for Quote : AS : Error Handler Flow
 * @author          :   Vinothraja
 * @date            :   01-08-2025
 * @group           :   Platforms
 * @revision
 *  01-08-2025      Vinothraja    - EPCP-4536  created test class to test the Quote : AS : Error Handler Flow
 */ 
@isTest( isParallel = true )
public with sharing class QuoteASErrorHandler_FT {
    /**
     * Test method to verify whether the Error Logging node in the Flow is working as expected.
     */
    @isTest
    private static void testErrorLogging() {
        // GIVEN
        // A Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Sub_Status__c = 'In Review');
        insert quote;

        // WHEN
        // Create a new Quote
        Test.startTest();
            quote.Sub_Status__c = 'Preview Requested';
            update quote;
        Test.stopTest();

        // THEN
        // Verify that the Quote was created successfully and the Error_Tracking_Start_Date_Time__c field is set
        SBQQ__Quote__c insertedQuote = [SELECT Id, Sub_Status__c, Error_Tracking_Start_Date_Time__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        Assert.isNotNull(insertedQuote.Error_Tracking_Start_Date_Time__c, 'The Quote\'s Error_Tracking_Start_Date_Time__c should be set.');
    }
}