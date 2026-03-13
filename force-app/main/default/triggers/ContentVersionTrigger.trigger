/**
* @author Nick Guia
* @date NOV.11.2017
* @description Contains all triggers for ContentVersion object.
* @history
**/
trigger ContentVersionTrigger on ContentVersion (before insert, after insert) {
    if (TriggerCommon.doNotRunTrigger('ContentVersion')) { return; }

    //insert events
    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            ContentVersionTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        if(Trigger.isAfter) {
            ContentVersionTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
    //add other DML events here
}