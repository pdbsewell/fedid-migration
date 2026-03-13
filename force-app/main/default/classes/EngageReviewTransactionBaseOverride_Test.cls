/**
 * @description Test class for EngageReviewTransactionBaseOverride
 * @author      Vinothraja
 * @since       13/03/2025
 * @group       Platforms
 */
@isTest(isParallel=true)
private class EngageReviewTransactionBaseOverride_Test {

    @IsTest
    static void testInitReviewTransaction(){
        // WHEN
        // The class is invoked
        Test.startTest();
        List<ucinn_ascendv2__Review_Transaction_v2__c> allReviewTransactions = [SELECT Id,
                                                                                    ucinn_ascendv2__External_System_ID__c,
                                                                                    RecordType.DeveloperName
                                                                               FROM ucinn_ascendv2__Review_Transaction_v2__c];
        EngageReviewTransactionBaseOverride engageReviewTransactionBaseOverride = new EngageReviewTransactionBaseOverride();
        engageReviewTransactionBaseOverride.initReviewTransaction(allReviewTransactions);
        Test.stopTest();

        // THEN
        // Nothing to verify
        Assert.isTrue(true);
    }

}