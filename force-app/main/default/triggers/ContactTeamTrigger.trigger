/**
 * @description       : Trigger on Contact Team
 * @author            : Inderpal Dhanoa
 * @group             : Trigger
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.0   2022-02-03   Inderpal Dhanoa    Initial Version
**/
trigger ContactTeamTrigger on ContactTeam__c (before insert, after insert, before update, after update, after delete, after undelete) {

  if (TriggerCommon.doNotRunTrigger('ContactTeam__c')) {
        return;
    }
    
    new Triggers()
    // insert
    .bindExtended(Triggers.Evnt.beforeInsert, new ContactTeamTriggerHandler.PopulateUniqueField())

    // update
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactTeamTriggerHandler.PopulateUniqueField())

    // delete

    // let's go
    .execute();

}