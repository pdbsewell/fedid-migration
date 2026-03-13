/**
 * @description Test class for QuoteExpiryQueueable
 */
@isTest(isParallel=true)
public with sharing class QuoteExpiryQueueable_Test {
    @testSetup static void setup() {
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();
        TestDataFactory.createSObject(new SBQQ__Quote__c(),'TestDataFactorySettings.PublishedQuote', true);
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
    }

    @isTest
    static void test_queue_success() {
        SBQQ__Quote__c[] quote = [SELECT ID, Primary_DocuSign_Envelop_Id__c 
            FROM SBQQ__Quote__c LIMIT 1];
        // startTest/stopTest block to force async processes to run
        Test.startTest(); 
        TriggerCommon.disableTrigger('SBQQ__Quote__c');       
        System.enqueueJob(new QuoteExpiryQueueable(new SuccessDocuSignEnvelopExpiryStub(), quote[0])); //expire offer in docusign
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
        SBQQ__Quote__c[] updatedQuote = [SELECT Id, Error_Log__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(true, 
            String.isBlank(updatedQuote[0].Error_Log__c), 'Expected no error'
        );
        Test.stopTest();  
    }

    @isTest
    static void test_queue_error() {
        SBQQ__Quote__c[] quote = [SELECT ID FROM SBQQ__Quote__c LIMIT 1];
        // startTest/stopTest block to force async processes to run
        Test.startTest();        
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        quote[0].Primary_DocuSign_Envelop_Id__c = null;
        System.enqueueJob(new QuoteExpiryQueueable(new ErrorDocuSignEnvelopExpiryStub(), quote[0])); //expire offer in docusign
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
        Test.stopTest();  
        SBQQ__Quote__c[] updatedQuote = [SELECT Id, Error_Log__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(false, 
            String.isBlank(updatedQuote[0].Error_Log__c), 'Expected error'
        );
    }

    private class SuccessDocuSignEnvelopExpiryStub implements DocuSignEnvelopExpiry {
        public void expire(String envelopId){
            System.debug('ALL GOOD!');
        }
    }

    private class ErrorDocuSignEnvelopExpiryStub implements DocuSignEnvelopExpiry {
        public void expire(String envelopId){
            throw new CalloutException('SOME ERROR HAPPENED!');
        }
    }
}