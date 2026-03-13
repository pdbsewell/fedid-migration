/*******************************************************************************
* @author       Anterey Custodio
* @date         3.Aug.2017
* @description  Contains all triggers on Attachment Object
* @revision     
*******************************************************************************/
trigger AttachmentTrigger on Attachment (before insert, after insert, after delete) {
    if (TriggerCommon.doNotRunTrigger('Attachment')) { return; }

    // * Commented by Majid Reisi Dehkordi on 13/04/2018
    // Is commented out as there is no need for it now
    // It seems it doesn't offer any value
    // new Triggers()
    // .bind(Triggers.Evnt.beforeInsert, new AttachmentServices.updateTheContentType())
    // .execute();
    
    new Triggers()
    .bind(Triggers.Evnt.afterInsert, new AttachmentServices.cloneEmailAttachmentToContactDocument())
    .execute();

    // Code to update has attachment flag
    if(Trigger.isAfter && Trigger.isInsert) {
        AttachmentTriggerHandler.handleAfterInsert(Trigger.new);
    } else if(Trigger.isAfter && Trigger.isDelete) {
        AttachmentTriggerHandler.handleAfterDelete(Trigger.old);
    }
}