/**
 * @description     Trigger class specific to Conga_Bulk_Processing__c sObject
 * 
 * @author          K. Vegerano
 * @date            26/08/2020
 * 
 * @revision
 * 
 *      26/08/2020 - K Vegerano - created
 *      26/08/2020 - K Vegerano - added logic on before insert and before update to build the conga parameters field
 */
trigger BulkPermitTrigger on Conga_Bulk_Processing__c (before insert, before update) {
    if (TriggerCommon.doNotRunTrigger('Conga_Bulk_Processing__c')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler

        /** UPDATE */
        .bindExtended(Triggers.Evnt.beforeinsert, new BulkPermitServices.BuildCongaParameters())
        .bindExtended(Triggers.Evnt.beforeupdate, new BulkPermitServices.BuildCongaParameters())

        //Calls the run method on each class
        .execute();
    }
}