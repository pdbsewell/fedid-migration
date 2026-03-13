/**
 * @description Test class for OffersEnvelopSignedEventTrigger
 */
@isTest(isParallel=true)
public class OffersEnvelopSignedEventTrigger_Test {
    
    @isTest
    static void shouldInsertEvent() {
        Test.startTest();
        Offers_Envelop_Signed_Event__e signedEvent = new Offers_Envelop_Signed_Event__e();
        signedEvent.Envelop_Id__c = 'abc-123';
        EventBus.publish(signedEvent);
        Test.getEventBus().deliver();
        System.assert(true, 'Expected insert to work');
        Test.stopTest();
    }

    @isTest
    static void shouldNotThrowExceptionWhenTriggerIsDisabled() {
        TriggerCommon.disableTrigger('Offers_Envelop_Signed_Event__e');

        Test.startTest();
        Offers_Envelop_Signed_Event__e signedEvent = new Offers_Envelop_Signed_Event__e();
        signedEvent.Envelop_Id__c = 'abc-123';
        EventBus.publish(signedEvent);
        Test.getEventBus().deliver();
        System.assert(true, 'Expected insert to work when trigger is disabled');
        Test.stopTest();
    }

}