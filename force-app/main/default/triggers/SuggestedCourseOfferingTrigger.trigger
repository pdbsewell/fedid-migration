trigger SuggestedCourseOfferingTrigger on Suggested_Course_Offering__c (after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('Suggested_Course_Offering__c')) {
            return;
        } else {
            new Triggers()
            .bindExtended(Triggers.Evnt.afterinsert, new SuggestedCourseOfferingHandler())
            .bindExtended(Triggers.Evnt.afterupdate, new SuggestedCourseOfferingHandler())
            .execute();
        }
}