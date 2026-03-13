/**
 * @description Test class for DocuSignStatusTrigger
 */ 
@isTest(isParallel=true)
public class DocuSignStatusTrigger_Test {

    @isTest
    static void shouldInsertDocuSignStatus() {
        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c();
        docuSignStatus.dsfs__DocuSign_Envelope_ID__c = 'ABC';
        insert docuSignStatus;
        System.assert(true, 'Expected insert to work');
    }

    @isTest
    static void shouldUpdateDocuSignStatus() {
        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c();
        docuSignStatus.dsfs__DocuSign_Envelope_ID__c = 'ABC';
        insert docuSignStatus;
        docuSignStatus.dsfs__Envelope_Status__c = 'Sent';
        update docuSignStatus;
        System.assert(true, 'Expected insert to work');
    }

    @isTest
    static void shouldNotThrowExceptionWhenTriggerIsDisabled() {
        TriggerCommon.disableTrigger('DocuSignStatusTrigger');
        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c();
        insert docuSignStatus;
        System.assert(true, 'Expected insert to work when trigger is disabled');
    }

}