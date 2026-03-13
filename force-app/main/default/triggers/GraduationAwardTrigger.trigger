/**
 * Created by tom on 5/9/2024.
 */

trigger GraduationAwardTrigger on Graduation_Award__c (before insert, before update, after insert, after update) {
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeinsert, new GraduationAwardTriggerHandler.DetectWriteBackRequired())
        .bindExtended(Triggers.Evnt.beforeupdate, new GraduationAwardTriggerHandler.DetectWriteBackRequired())
        .bindExtended(Triggers.Evnt.beforeupdate, new GraduationAwardTriggerHandler.CreateExternalRefund())
        .bindExtended(Triggers.Evnt.beforeupdate, new GraduationAwardTriggerHandler.HandlePortalUncancel())
        .bindExtended(Triggers.Evnt.afterinsert, new GraduationAwardTriggerHandler.QueueSyncJob())
        .bindExtended(Triggers.Evnt.afterupdate, new GraduationAwardTriggerHandler.QueueSyncJob())
        .execute();
}