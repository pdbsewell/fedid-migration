/**
 * @description     Trigger class specific to Payment_Request__c sObject
 * 
 * @author          K. Vegerano
 * @date            02/09/2020
 * 
 * @revision
 * 
 *      02/09/2020 - K Vegerano - created
 */
trigger AgencyPaymentRequestTrigger on Payment_Request__c (before insert, before update) {
	if (TriggerCommon.doNotRunTrigger('Payment_Request__c')) { return; }
    new Triggers()
        //Before Events
        .bindExtended(Triggers.Evnt.beforeinsert, new AgencyPaymentRequestServices.AgencyUniqueInvoiceNumber())
        .bindExtended(Triggers.Evnt.beforeupdate, new AgencyPaymentRequestServices.AgencyUniqueInvoiceNumber())
        .bindExtended(Triggers.Evnt.beforeupdate, new AgencyPaymentRequestServices.SetSubmissionDate())
        //Calls the run method on each class
        .execute();
	LogUtilityException.getLimits();
}