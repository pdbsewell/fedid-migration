/**
 * @description Trigger for Case Object
 * @revision
 *      DEC.05.2017     Kristian Vegerano - Refactored code to use straightforward Trigger - Handler - DML runtime framework
 *                                        - Refactored to fix too many SOQL errors
 *      JUL.27.2022     Sagar Johri       - Updated the trigger framework [Jira : EPCP-2155]
 **/
trigger EmailMessageTrigger on EmailMessage (before insert, after insert, before update, after update) {

    if (TriggerCommon.doNotRunTrigger('EmailMessage')) {
        return;
    }
    //Run Triggers
    new Triggers()
    
    //BEFORE INSERT
    .bindExtended(Triggers.Evnt.beforeinsert, new EmailMessageTriggerHandler.handleBeforeInsert())
    
    //AFTER INSERT
    .bindExtended(Triggers.Evnt.afterinsert, new EmailMessageTriggerHandler.handleAfterInsert())
    
    //BEFORE UPDATE
    
    
    //AFTER UPDATE
    /* deprecated - no implementation
    EmailMessageTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    */
    
    .execute();

}