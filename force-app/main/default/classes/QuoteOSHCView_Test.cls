@isTest
private class QuoteOSHCView_Test
{

    @isTest
    private static void shouldBeLockedWhenStatusIsNotPublished()
    {
        SBQQ__Quote__c qq = QuoteService_Test.constructQuoteWithHealthData();
        qq.SBQQ__Status__c = Constants.QUOTE_STATUS_ACCEPTED;
        qq.Acknowledged_by_applicant__c = true;
        update qq;
        QuoteOSHCView qView = new QuoteOSHCView(qq.Id, false);
        system.assertEquals(true, qView.isLocked, 'it should set the status of isLocked to true when status is not published');
    }
    @isTest
    private static void shouldNotBeLockedWhenStatusIsPublished()
    {
        SBQQ__Quote__c qq = QuoteService_Test.constructQuoteWithHealthData();

        qq.Sub_Status__c = 'Details Changed';
        update qq;

        QuoteOSHCView qView = new QuoteOSHCView(qq.Id, false);
        system.assertEquals(false, qView.isLocked, 'it should NOT set the status of isLocked to true when status is not published');
    }

}