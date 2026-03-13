trigger AOProgramTrigger on AO_Program__c (before insert, before update) {
    if (TriggerCommon.doNotRunTrigger('AO_Program__c')) { 
        return; 
    }
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new AOProgramTriggerHandler.CheckDuplicateName())
        .bindExtended(Triggers.Evnt.beforeUpdate, new AOProgramTriggerHandler.CheckDuplicateName())
    .execute();
}