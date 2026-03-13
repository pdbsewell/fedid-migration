trigger CourseFeeTrigger on Course_Fee__c (before insert, before update, after insert, after update) {
	if (TriggerCommon.doNotRunTrigger('Course_Fee__c')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        .bindExtended(Triggers.Evnt.beforeinsert, new CourseFeeTriggerHandler.ProductSync())
        .bindExtended(Triggers.Evnt.beforeupdate, new CourseFeeTriggerHandler.ProductSync())
        .bindExtended(Triggers.Evnt.afterinsert, new CourseFeeTriggerHandler.ProductOptionCreate())
        .bindExtended(Triggers.Evnt.afterupdate, new CourseFeeTriggerHandler.ProductOptionCreate())

        //Calls the run method on each class
        .execute();
    }
}