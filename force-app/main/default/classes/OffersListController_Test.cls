/**
 * @description Test class for OffersListController
 */
@isTest(isParallel=true)
public class OffersListController_Test {

    @isTest
    static void shouldThrowExceptionOnInvalidQuote() {

        try {
            OffersListController.getSigningUrl('dne');
            System.assert(false, 'Expected Exception because quote id does not exist');
        } catch (Exception e) {
            System.assert(true, 'Expected Exception as quote cannot be updated');
        }
    }

    @isTest
    static void shouldThrowExceptionOnBadQuote() {
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        SBQQ.TriggerControl.disable();

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;

        Test.startTest();
        try {
            OffersListController.getSigningUrl(String.valueOf(quote.Id));
            System.assert(false, 'Expected AuraException because quote id does not exist');
        } catch (AuraException e) {
            System.assert(true, 'Expected AuraException');
        } catch (Exception e) {
            System.assert(false, 'Expected AuraException instead of Exception');
        }
        Test.stopTest();
    }

}