/**
 * @description     Trigger class specific to Payment_Request_Item__c sObject
 * 
 * @author          K. Vegerano
 * @date            17/09/2020
 * 
 * @revision
 * 
 *      17/09/2020 - K Vegerano - created
 */
trigger AgencyPaymentRequestItemTrigger on Payment_Request_Item__c (before insert, before update) {
    if (TriggerCommon.doNotRunTrigger('Payment_Request_Item__c')) { return; }
    new Triggers()
        //Before Events
        .bindExtended(Triggers.Evnt.beforeinsert, new AgencyPaymentRequestItemServices.PrepopulateFields())
        .bindExtended(Triggers.Evnt.beforeupdate, new AgencyPaymentRequestItemServices.PrepopulateFields())
        //Calls the run method on each class
        .execute();
	LogUtilityException.getLimits();
}