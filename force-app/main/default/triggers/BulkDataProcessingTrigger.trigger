/**
* @author David Browaeys
* @group Bulk Data Processing
* @description Trigger for Bulk_Data_Processing__c
 **/
trigger BulkDataProcessingTrigger on Bulk_Data_Processing__c (before insert, before update, after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('Bulk_Data_Processing__c')) {
            return;
    } else {
        new Triggers()
            .bindExtended(Triggers.Evnt.beforeInsert, new BDPBeforeInsertHandler())
            .bindExtended(Triggers.Evnt.beforeupdate, new BDPBeforeUpdateHandler())
            .bindExtended(Triggers.Evnt.afterinsert, new BDPAfterInsertHandler())
            .bindExtended(Triggers.Evnt.afterupdate, new BDPAfterUpdateHandler())
            .execute();
    }
}