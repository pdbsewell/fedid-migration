/*
 * Platform Event subscriber
 * 
 */
trigger IbdUnitAttemptTrigger on IbdUnitAttempt__e (after insert) {
    new Triggers()
        .bindExtended(Triggers.Evnt.afterInsert, new IbdUnitAttemptServices.EventHandler())
        .execute();
}