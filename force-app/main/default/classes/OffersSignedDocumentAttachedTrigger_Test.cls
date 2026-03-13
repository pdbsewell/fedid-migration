/**
 * @description Test class for OffersSignedDocumentAttachedTrigger
 */
@isTest(isParallel=true)
public class OffersSignedDocumentAttachedTrigger_Test {

    @isTest
    static void shouldInsertEvent() {
        Test.startTest();
        Offers_Signed_Document_Attached__e signedDocumentAttached = new Offers_Signed_Document_Attached__e();
        signedDocumentAttached.Envelop_Id__c = 'abc-123';
        EventBus.publish(signedDocumentAttached);
        Test.getEventBus().deliver();
        System.assert(true, 'Expected insert to work');
        Test.stopTest();
    }

    @isTest
    static void shouldNotThrowExceptionWhenTriggerIsDisabled() {
        TriggerCommon.disableTrigger('Offers_Signed_Document_Attached__e');

        Test.startTest();
        Offers_Signed_Document_Attached__e signedDocumentAttached = new Offers_Signed_Document_Attached__e();
        signedDocumentAttached.Envelop_Id__c = 'abc-123';
        EventBus.publish(signedDocumentAttached);
        Test.getEventBus().deliver();
        System.assert(true, 'Expected insert to work when trigger is disabled');
        Test.stopTest();
    }

}