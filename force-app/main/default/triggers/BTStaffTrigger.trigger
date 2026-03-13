/**
 * @author Ibrahim Rumi
 * @date 27-08-2020
 * @group Event Management
 * @description Trigger for conference360__Staff__c object (Blackthorn)
 **/
trigger BTStaffTrigger on conference360__Staff__c (before insert,before update, after insert, after update, after delete) {
if (TriggerCommon.doNotRunTrigger('conference360__Staff__c')) { return; }
    
    new Triggers()
        
        .bindExtended(Triggers.Evnt.afterInsert, new BTStaffTriggerHandler.ShareStaffRelatedRecords())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTStaffTriggerHandler.ShareStaffRelatedRecords())
        .bindExtended(Triggers.Evnt.afterDelete, new BTStaffTriggerHandler.PurgeStaffRelatedShareRecords())
        .bindExtended(Triggers.Evnt.beforeInsert,new BTStaffTriggerHandler.ValidateStaff())
        .bindExtended(Triggers.Evnt.beforeUpdate,new BTStaffTriggerHandler.ValidateStaff())
        .bindExtended(Triggers.Evnt.afterInsert,new BTStaffTriggerHandler.autoCreateEventStaff())
        .bindExtended(Triggers.Evnt.afterUpdate,new BTStaffTriggerHandler.autoCreateEventStaff())       
        .bindExtended(Triggers.Evnt.afterDelete,new BTStaffTriggerHandler.autoCreateEventStaff())
    .execute();
}