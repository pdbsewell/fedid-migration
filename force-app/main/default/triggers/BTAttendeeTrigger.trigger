/**
 * @author Nick Guia
 * @date 11-08-2020
 * @group Event Management
 * @description Trigger for conference360__Attendee__c object (Blackthorn)
 * @revision
 *   30.05.2021  Ibrahim Rumi    - EPBBS-1888 added method registrationStatusHandler to handle registration status change
 *   18.08.2021  Aref Samad      - EPBBS-2087 Number Reg - Check In - Check in Guest Attendees in attendee group when Primary attendee checked in
 *   18.10.2021  Ibrahim Rumi    - EPBBS-2183 Share newly inserted Attendee with existing event Staff
 *   17.01.2022  Ibrahim Rumi    - EPBBS-2379 ValidateRegistration method to Validate capacity and duplicates during attendee registration
 **/
trigger BTAttendeeTrigger on conference360__Attendee__c (before insert, after insert, after update, before update) {
    if (TriggerCommon.doNotRunTrigger('conference360__Attendee__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new BTAttendeeTriggerHandler.LinkContactToAttendee())
        .bindExtended(Triggers.Evnt.beforeInsert, new BTAttendeeTriggerHandler.ValidateRegistration())
        .bindExtended(Triggers.Evnt.afterInsert, new BTAttendeeTriggerHandler.LinkContactToAttendee())
        .bindExtended(Triggers.Evnt.afterInsert, new BTAttendeeTriggerHandler.SubscribeToMarketing())
        .bindExtended(Triggers.Evnt.afterInsert, new BTAttendeeTriggerHandler.ShareAttendeeToEventStaff())
        .bindExtended(Triggers.Evnt.beforeUpdate, new BTAttendeeTriggerHandler.RegistrationStatusHandler())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTAttendeeTriggerHandler.SubscribeToMarketing())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTAttendeeTriggerHandler.CheckinGroupAttendee())
    .execute();
}