/**
 * @description Test class for QuoteOfferSigningTriggerHandler
 */
@isTest(isParallel=true)
public class QuoteOfferSigningTriggerHandler_Test {

    @isTest
    static void shouldNotProcessQuotesWithoutDocumentWithoutAcknowledgement() {

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c();
        oldQuote.Acknowledged_by_applicant__c = false;
        oldQuote.Primary_Document__c = '';
        oldQuote.Guardian_First_Name__c = 'John';

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote.Acknowledged_by_applicant__c = false;
        newQuote.Primary_Document__c = '';
        newQuote.Guardian_First_Name__c = 'Johnny';

        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote, oldQuote);
        handler.execute();

        Assert.areEqual(0, Limits.getQueueableJobs(), 
            'Did not expect any Queueable job executed as the quote did not ' 
            + 'meet conditions.');
    }

    @isTest
    static void shouldNotProcessQuotesWithDocumentWithoutAcknowledgement() {

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c();
        oldQuote.Acknowledged_by_applicant__c = false;
        oldQuote.Primary_Document__c = '';

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote.Acknowledged_by_applicant__c = false;
        newQuote.Primary_Document__c = 'somedocumentid';

        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote, oldQuote);
        handler.execute();

        Assert.areEqual(0, Limits.getQueueableJobs(), 
            'Did not expect any Queueable job executed as the quote did not ' 
            + 'meet conditions.');
    }

    @isTest
    static void shouldNotProcessQuotesWithAcknowledgementWithoutDocument() {

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c();
        oldQuote.Acknowledged_by_applicant__c = false;
        oldQuote.Primary_Document__c = '';

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote.Acknowledged_by_applicant__c = true;
        newQuote.Primary_Document__c = '';

        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote, oldQuote);
        handler.execute();

        Assert.areEqual(0, Limits.getQueueableJobs(), 
            'Did not expect any Queueable job executed as the quote did not ' 
            + 'meet conditions.');    
    }

    @isTest
    static void shouldNotProcessQuotesWithoutDocumentOrAcknowledgementChange() {

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c();
        oldQuote.Acknowledged_by_applicant__c = true;
        oldQuote.Primary_Document__c = 'xyz';

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote.Acknowledged_by_applicant__c = true;
        newQuote.Primary_Document__c = 'xyz';

        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote, oldQuote);
        handler.execute();

        Assert.areEqual(0, Limits.getQueueableJobs(), 
            'Did not expect any Queueable job executed as the quote did not ' 
            + 'meet conditions.');
    }

    @isTest
    static void shouldProcessQuotesWhenAcknowledgementChangedAndDocExists() {
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c();
        oldQuote.Acknowledged_by_applicant__c = false;
        oldQuote.Primary_Document__c = 'xyz';
        quotes.add(oldQuote);

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote.Acknowledged_by_applicant__c = true;
        newQuote.Primary_Document__c = 'xyz';
        quotes.add(newQuote);

        insert quotes;

        Test.startTest();
        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote, oldQuote);
        handler.execute();

        Assert.areEqual(1, Limits.getQueueableJobs(), 
            'Expect one Queueable job executed as the quote did meet ' 
            + 'conditions to execute.');
        Test.stopTest();
    }

    @isTest
    static void shouldProcessQuotesWhenDocChangedAndAcknowledgementExists() {
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c();
        oldQuote.Acknowledged_by_applicant__c = true;
        oldQuote.Primary_Document__c = '';
        quotes.add(oldQuote);

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote.Acknowledged_by_applicant__c = true;
        newQuote.Primary_Document__c = 'xyz';
        quotes.add(newQuote);

        insert quotes;

        Test.startTest();
        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote, oldQuote);
        handler.execute();

        Assert.areEqual(1, Limits.getQueueableJobs(), 
            'Expect one Queueable job executed as the quote did meet ' 
            + 'conditions to execute.');
        Test.stopTest();
    }

    @isTest
    static void shouldProcessQuotesWhenBothDocAndAcknowledgeChangedAndExists() {
        SBQQ.TriggerControl.disable();
        TriggerCommon.disableTrigger('SBQQ__Quote__c');

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

        SBQQ__Quote__c oldQuote = new SBQQ__Quote__c();
        oldQuote.Acknowledged_by_applicant__c = false;
        oldQuote.Primary_Document__c = '';
        quotes.add(oldQuote);

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote.Acknowledged_by_applicant__c = true;
        newQuote.Primary_Document__c = 'xyz';
        quotes.add(newQuote);

        insert quotes;

        Test.startTest();
        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote, oldQuote);
        handler.execute();
        
        Assert.areEqual(1, Limits.getQueueableJobs(), 
            'Expect one Queueable job executed as the quote did meet ' 
            + 'conditions to execute.');

        Test.stopTest();
    }

    @isTest
    static void shouldThrowUnsupportedOperationExceptionWhenMoreThanOneQuote() {
        
        SBQQ__Quote__c oldQuote1 = new SBQQ__Quote__c();
        oldQuote1.Acknowledged_by_applicant__c = false;
        oldQuote1.Primary_Document__c = '';

        SBQQ__Quote__c newQuote1 = new SBQQ__Quote__c();
        newQuote1.Acknowledged_by_applicant__c = true;
        newQuote1.Primary_Document__c = 'xyz';

        SBQQ__Quote__c oldQuote2 = new SBQQ__Quote__c();
        oldQuote2.Acknowledged_by_applicant__c = false;
        oldQuote2.Primary_Document__c = '';

        SBQQ__Quote__c newQuote2 = new SBQQ__Quote__c();
        newQuote2.Acknowledged_by_applicant__c = true;
        newQuote2.Primary_Document__c = 'xyz';

        QuoteOfferSigningTriggerHandler handler = 
            new QuoteOfferSigningTriggerHandler();
        handler.process(newQuote1, oldQuote1);
        handler.process(newQuote2, oldQuote2);

		// To do - fix these asserts to be useful        
        try {
            handler.execute();
            Assert.isFalse(false, 'Expected UnsupportedOperationException '
                + 'as more than 1 record is not supported');
        } catch (UnsupportedOperationException e) {
            Assert.istrue(true, 'Expected UnsupportedOperationException');
        } catch (Exception e) {
            Assert.isFalse(false, 'Expected UnsupportedOperationException ' 
                + 'instead of Exception');
        }
    }

}