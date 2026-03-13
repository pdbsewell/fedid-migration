/**
 * Created by tom on 8/9/2024.
 */

trigger GraduationApplicationTrigger on Graduation_Application__c (after insert, before update, after update) {
    new Triggers()
        .bindExtended(Triggers.Evnt.afterinsert, new GraduationApplicationTriggerHandler.DetectWriteBackRequired())
        .bindExtended(Triggers.Evnt.afterupdate, new GraduationApplicationTriggerHandler.DetectWriteBackRequired())
        .bindExtended(Triggers.Evnt.beforeupdate, new GraduationApplicationTriggerHandler.HandleNameChange())
        .bindExtended(Triggers.Evnt.beforeupdate, new GraduationApplicationTriggerHandler.HandleStatusChange())
        .execute();
}