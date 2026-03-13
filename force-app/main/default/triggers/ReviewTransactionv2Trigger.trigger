/**
 * @author          Inderpal Dhanoa
 * @description     Trigger class specific to ReviewTransactionv2 sObject
 * @revision
 * 01/03/2023 - Inderpal Dhanoa          - Sync Designations & Appeals PENGAGE-2642
 */
trigger ReviewTransactionv2Trigger on ucinn_ascendv2__Review_Transaction_v2__c (before insert, after insert, before update, after update, after delete, after undelete) {
    if (TriggerCommon.doNotRunTrigger('ucinn_ascendv2__Review_Transaction_v2__c')) {
        return;
    }

    new Triggers()
    /** INSERT */
    .bindExtended(Triggers.Evnt.beforeInsert, new ReviewTransactionv2Service.SyncAppealDesignationInfo()) 

    /** UPDATE */
    .bindExtended(Triggers.Evnt.beforeupdate, new ReviewTransactionv2Service.SyncAppealDesignationInfo())

    /** DELETE */

    /** UNDELETE */
    .execute();
}