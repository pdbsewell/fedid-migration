/*
 * @description Trigger for Case Comment Object
 */
trigger CaseCommentTrigger on CaseComment (after insert, after update) {
    new Triggers()
    //After Insert Events
    .bindExtended(Triggers.Evnt.afterinsert, new CaseCommentTriggerHandler.SyncEnquiryWithLatestComment())

    //After Update Events
    .bindExtended(Triggers.Evnt.afterupdate, new CaseCommentTriggerHandler.SyncEnquiryWithLatestComment())
   
    .execute();

    LogUtilityException.getLimits();
}