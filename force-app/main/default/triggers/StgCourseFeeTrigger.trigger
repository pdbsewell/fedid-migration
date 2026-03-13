trigger StgCourseFeeTrigger on Stg_Course_Fee__c (before insert, before update) {
	if (TriggerCommon.doNotRunTrigger('Stg_Course_Fee__c')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        .bindExtended(Triggers.Evnt.beforeinsert, new StgCourseFeeHandler.CourseFeeGenerator())
        .bindExtended(Triggers.Evnt.beforeupdate, new StgCourseFeeHandler.CourseFeeGenerator())
        //Calls the run method on each class
        .execute();
    }
}