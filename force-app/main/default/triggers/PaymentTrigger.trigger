/**
 * @author          Vineeth Batreddy
 * @description     Send email receipt to the students manually [only for Offline Registration Payments]
 * @history         22/09/2017 - Vineeth Batreddy - Original code 
 *                  22/10/2018 - Nadula Karunaratna - Added reading off BCC email from Custom Metadata Type [Multi Faculty Capability]
 *                  30/05/2019 - Nadula Karunaratna - Added method generatePaymentReceipt (dynamic contact details in the signature) [PRODEV-369]
 */
trigger PaymentTrigger on Payment__c 
    (before delete, before insert, before update, after delete, after insert, after undelete, after update) {
        
    if(Trigger.isBefore && Trigger.isUpdate) {
        PaymentServices.updatePaymentStatus(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        
        PaymentServices.generatePaymentReceipt(Trigger.new, Trigger.newMap, Trigger.oldMap);

    }
       
	new Triggers()        
	.bindExtended(Triggers.Evnt.afterUpdate, new DlrsDelegateTriggerHandler(Payment__c.SObjectType))
	.execute();
        
}