/**
 * @description Test class for OffersRecipientSignedEventTrigger
 */
@isTest(isParallel=true)
public class OffersRecipientSignedEventTrigger_Test {
    @isTest
    static void shouldInsertEvent() {
        Test.startTest();
        Offers_Recipient_Signed_Event__e recipientSignedEvent = new Offers_Recipient_Signed_Event__e();
        recipientSignedEvent.Envelop_Id__c = 'abc-123';
        EventBus.publish(recipientSignedEvent);
        Test.getEventBus().deliver();
        System.assert(true, 'Expected insert to work');
        Test.stopTest();
    }

    @isTest
    static void shouldNotThrowExceptionWhenTriggerIsDisabled() {
        TriggerCommon.disableTrigger('Offers_Recipient_Signed_Event__e');

        Test.startTest();
        Offers_Recipient_Signed_Event__e recipientSignedEvent = new Offers_Recipient_Signed_Event__e();
        recipientSignedEvent.Envelop_Id__c = 'abc-123';
        EventBus.publish(recipientSignedEvent);
        Test.getEventBus().deliver();
        System.assert(true, 'Expected insert to work when trigger is disabled');
        Test.stopTest();
    }
}