/**
 * @author       Jitender Padda
 * @date         Jan.2025
 * @description  Trigger for CRM notes object
 */
trigger CRMNotesTrigger on CRM_Notes__c (before insert, after insert, before update, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('CRM_Notes__c')) {
        return;
    }
    
    new Triggers()
    // insert
    .bindExtended(Triggers.Evnt.afterInsert, new CRMNotesHandler.PushNoteToCallista())
    // update
    .bindExtended(Triggers.Evnt.afterUpdate, new CRMNotesHandler.PushNoteToCallista())

    .execute();
}