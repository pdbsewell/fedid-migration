/**
 * @File Name          : QuoteLinesSelectorTest.cls
 * @Description        : 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 12/17/2019, 10:35:47 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    12/17/2019   jasmin.rudio@monash.edu     Initial Version
**/
@isTest
public with sharing class QuoteLinesSelector_Test {
    @testSetup static void setup() {
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        TriggerCommon.disableTrigger('SBQQ__QuoteLine__c');
        QuoteTriggerHandler.lockUserCreation = true;
        SBQQ__Quote__c quote1 = (SBQQ__Quote__c)TestDataFactory.createSObject(new SBQQ__Quote__c(),true);
        
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote1.Id), true);
        TestDataFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote1.Id, Expiry_Date__c = Date.today().addDays(15)), true);
    }
    @isTest
    static void test_selectById() {
        SBQQ__QuoteLine__c ql = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        new QuoteLinesSelector().selectById(new Set<ID>{ql.Id});
    }

    @isTest
    static void test_selectByQuoteIdAndProductFamily() { 
        new QuoteLinesSelector().selectByQuoteIdAndProductFamily(new Set<ID>(), new String[]{'BLABLA'});
    }
    @isTest
    static void test_selectByIdWithQuoteLines() {
        new QuoteLinesSelector().selectByIdWithQuoteLines(new Set<ID>());
    }
    @isTest
    static void test_selectBundleByQuoteId() {
        new QuoteLinesSelector().selectBundleByQuoteId(new Set<String>());
    }
    @isTest
    static void test_selectByIdHiddenPricing() {  
        new QuoteLinesSelector().selectByIdHiddenPricing(new Set<ID>());
    }
    @isTest
    static void test_getBundlesForQuote(){
        try{
            new QuoteLinesSelector().getBundlesForQuote(null);
            Assert.isTrue(false, 'Should not come here');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('No valid quoteIds provided to getBundlesForQuote') == true);
        }
        SBQQ__Quote__c quote1 = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Assert.isTrue(new QuoteLinesSelector().getBundlesForQuote(new Set<ID>{quote1.Id}).size() > 0 ,'Retrieve quote line from quote id');
    }   

    @isTest
    static void testProductCodeQueryWithNoQuoteId() {
        QuoteLinesSelector quoteLinesSelector = new QuoteLinesSelector();
        String productCode = quoteLinesSelector.selectFirstCourseQuoteLineProductCodeByQuoteId(null);
        Assert.areEqual('', productCode, 
            'Did not expect product code because there is no quote in the first place!');
    }

    /**
     * @author          Vishal Gupta
     * @description     selecting the QuoteLine based on Quote Id  
     * @revision        14/1/2025 - Initial Version
     */
    @isTest
    static void testSelectByQuoteId() {
        //Given, there is quote exists in the system
        SBQQ__Quote__c quote1 = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        //When, we query the quote lines based on the quote id
        List<SBQQ__QuoteLine__c> lstQuoteLines = new QuoteLinesSelector().SelectByQuoteId(new Set<ID>{quote1.Id});
        //Then, it shoould return the related quote lines
        Assert.areEqual(lstQuoteLines.size() > 0 , true, 'Retrieve quote line from quote id');
    }
}