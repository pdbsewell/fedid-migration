trigger CourseOffering on Course_Offering__c (before insert, before update, after insert, after update, after delete, after undelete) {
    if (TriggerCommon.doNotRunTrigger('Course_Offering__c')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        .bindExtended(Triggers.Evnt.beforeinsert, new CourseOfferingTriggerHandler.CourseOfferingInitiator())
        .bindExtended(Triggers.Evnt.beforeupdate, new CourseOfferingTriggerHandler.CourseOfferingInitiator())

        .bindExtended(Triggers.Evnt.afterUpdate, new DlrsDelegateTriggerHandler(Course_Offering__c.SObjectType))
        .bindExtended(Triggers.Evnt.afterInsert, new DlrsDelegateTriggerHandler(Course_Offering__c.SObjectType))
        .bindExtended(Triggers.Evnt.afterDelete, new DlrsDelegateTriggerHandler(Course_Offering__c.SObjectType))
        .bindExtended(Triggers.Evnt.afterUndelete, new DlrsDelegateTriggerHandler(Course_Offering__c.SObjectType))            
            
        //Calls the run method on each class
        .execute();
    }
}