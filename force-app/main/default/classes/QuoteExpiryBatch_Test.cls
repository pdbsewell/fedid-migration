/***************************************************************************************************
* @author:		Deloitte
* @date:		Unknown
* @description:	Test class for Quote Expiring scheduled apex.
* @revision:
*				17.March.2022   Kristian Vegerano - set isParallel to false + updated cron job timing
***************************************************************************************************/

@isTest(isParallel=false) //false due to System.UnexpectedException: In parallel Apex tests, DML operations aren't permitted on this type of object: CronJobDetail
public with sharing class QuoteExpiryBatch_Test {
    //scheduled to run 2 minutes from now
    public static String CRON_EXP = String.valueOf(DateTime.now().addMinutes(2).format('s m H d M ? y'));
    
    @testSetup static void setup() {
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();
        TestDataFactory.createSObjectList(new SBQQ__Quote__c(), 50, 'TestDataFactorySettings.PublishedQuote', true);
        SBQQ.TriggerControl.enable();
        TriggerCommon.enableTrigger('SBQQ__Quote__c');
    }
    @isTest 
    static void test_batch(){
        Test.startTest();

        Database.executeBatch(new QuoteExpiryBatch(new OffersDocuSignEnvelopExpiry(new DocuSignUpdateEnvelopRestApiRequest())), 50);
        Integer nbOfQuotes = [SELECT COUNT() FROM SBQQ__Quote__c];
        System.assert(nbOfQuotes == 50, 'Quotes must be all expired.');
        Test.stopTest();
    }

    @isTest 
    static void test_scheduleable(){
        String jobId = System.schedule('ScheduledApexTest',
        CRON_EXP, 
        new QuoteExpiryBatch());
    }

    @isTest 
    static void test_error1(){
        SBQQ__Quote__c[] t = [SELECT Id, Error_Log__c, SBQQ__Status__c, Docusign_Expiry_Time__c, Primary_DocuSign_Envelop_Id__c FROM SBQQ__Quote__c LIMIT 10];
        QuoteExpiryBatch batch = new QuoteExpiryBatch();
        for (SBQQ__Quote__c q : t){
            q.Primary_DocuSign_Envelop_Id__c = null;
        }
        batch.execute(null, t);
    }

    @isTest 
    static void test_error2(){
        QuoteExpiryBatch batch = new QuoteExpiryBatch();
        batch.commitAll(new SBQQ__Quote__c[]{
            new SBQQ__Quote__c()
        });
    }
}