trigger InstitutionTrigger on Institution__c (before insert, before update) {
    if (TriggerCommon.doNotRunTrigger('Institution__c')) {
        return;
    }
    
    new Triggers()
    .bindExtended(Triggers.Evnt.beforeinsert, new InstitutionTriggerHandler.countryLookup())
    .bindExtended(Triggers.Evnt.beforeupdate, new InstitutionTriggerHandler.countryLookup())
    .execute();
}