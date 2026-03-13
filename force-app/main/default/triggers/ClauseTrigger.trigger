trigger ClauseTrigger on APXT_Redlining__Clause__c (after insert, after update, after delete, after undelete) {
    if (TriggerCommon.doNotRunTrigger('APXT_Redlining__Clause__c')) {
        return;
    }

    //Run Trigger
    new Triggers()
        .bindExtended(Triggers.Evnt.afterinsert, new ClauseTriggerHandler.ClauseUpsert())
        .bindExtended(Triggers.Evnt.afterupdate, new ClauseTriggerHandler.ClauseUpsert())
        .bindExtended(Triggers.Evnt.afterdelete, new ClauseTriggerHandler.ClauseDelete())
        .bindExtended(Triggers.Evnt.afterundelete, new ClauseTriggerHandler.ClauseUpsert())
        .execute();
}