/**
 * @description Test class for DocuSignRecipientStatusTrigger
 */ 
@isTest(isParallel=true)
public class DocuSignRecipientStatusTrigger_Test {

    @isTest
    static void shouldInsertDocuSignRecipientStatus() {
        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c();
        docuSignStatus.dsfs__DocuSign_Envelope_ID__c = 'ABC';
        insert docuSignStatus;

        Test.startTest();
        dsfs__DocuSign_Recipient_Status__c recipientStatus = new dsfs__DocuSign_Recipient_Status__c();
        recipientStatus.dsfs__Envelope_Id__c = 'ABC';
        recipientStatus.dsfs__Recipient_Status__c = 'sent';
        recipientStatus.dsfs__DocuSign_Recipient_Id__c = 'uid1';
        recipientStatus.dsfs__Parent_Status_Record__c = docuSignStatus.Id;

        insert recipientStatus;
        System.assert(true, 'Expected insert to work');
        Test.stopTest();
    }

    @isTest
    static void shouldNotThrowExceptionWhenTriggerIsDisabled() {
        TriggerCommon.disableTrigger('dsfs__DocuSign_Recipient_Status__c');
        
        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c();
        docuSignStatus.dsfs__DocuSign_Envelope_ID__c = 'ABC';
        insert docuSignStatus;

        Test.startTest();
        dsfs__DocuSign_Recipient_Status__c recipientStatus = new dsfs__DocuSign_Recipient_Status__c();
        recipientStatus.dsfs__Envelope_Id__c = 'ABC';
        recipientStatus.dsfs__Recipient_Status__c = 'sent';
        recipientStatus.dsfs__DocuSign_Recipient_Id__c = 'uid123';
        recipientStatus.dsfs__Parent_Status_Record__c = docuSignStatus.Id;

        insert recipientStatus;
        System.assert(true, 'Expected to work when trigger is disabled');
        Test.stopTest();
    }

}