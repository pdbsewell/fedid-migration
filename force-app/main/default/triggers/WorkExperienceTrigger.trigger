trigger WorkExperienceTrigger on Work_Experience__c (before insert, before update) {

    if (TriggerCommon.doNotRunTrigger('Work__Experience__c')) {
        return;
    }
 
    new Triggers()
    .bindExtended(Triggers.Evnt.beforeUpdate, new WorkExperienceServices.tidyPhone())
    .bindExtended(Triggers.Evnt.beforeInsert, new WorkExperienceServices.tidyPhone())
    
    .execute();
}