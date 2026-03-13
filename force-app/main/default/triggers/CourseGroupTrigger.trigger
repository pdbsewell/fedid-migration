trigger CourseGroupTrigger on Course_Group__c (before insert, before update) {
    if (TriggerCommon.doNotRunTrigger('Course_Group__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new CourseGroupServices.updateFields())
        .bindExtended(Triggers.Evnt.beforeUpdate, new CourseGroupServices.updateFields())
    .execute();
}