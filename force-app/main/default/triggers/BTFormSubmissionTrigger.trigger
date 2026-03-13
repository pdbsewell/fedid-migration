/**
 * @author Nick Guia
 * @date 18-01-2021
 * @group Event Management
 * @description Trigger for conference360__Form_Submission__c object (Blackthorn)
 **/
trigger BTFormSubmissionTrigger on conference360__Form_Submission__c (after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('conference360__Attendee__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.afterInsert, new BTFormSubmissionTriggerHandler.CreateAttendeeContactPerson360())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTFormSubmissionTriggerHandler.CreateAttendeeContactPerson360())
    .execute();
}