/**
 * @author Nick Guia
 * @date 07-07-2020
 * @group Event Management
 * @description Trigger for conference360__Event__c object (Blackthorn)
 * @revision rumi.rumi@monash.edu EPBBS-1551 added class ManageCampaignStatus to change campaign status when event status is updated
 *         2021-06-09 -    Aref Samad     -EPBBS-1970 added new field in Event Internal_Name__c and added handler UpdateCampusName
 *                                          to map campaign Name and campaign display name remains mapped with Event Name
 *         2021-11-10 -    Mairaj Haider  -EPBBS-2262 Store maze map details in Location object and copy it to Event object
 *         2022-02-12 -    RANAND         -EPBBS-2030 Capture Winning Affiliation on Event based upon Audience Type
 *         2022-02-12 -    Ibrahim Rumi   -EPBBS-2387 UpdateSessionStatus() to auto cancel related sessions when event is cancelled
 *         2022-03-09 -    Ibrahim Rumi   -EPBBS-2453 ValidateStreamingURL() to validate straming URL for in person events
 *         2022-03-14 -    RANAND         -EPBBS-2482 ManageStaffForEvent to automatically manage Event staff creation
 *         2022-04-12 -    RANAND         -EPBBS-2570 Cascade feilds from Event Group on Event
 *         2022-06-01 -    Ibrahim Rumi   -EPBBS-2643 ManageStaffForEvent renamed to ManageChildRecsForEventOnEvntGrpChange
 *         2022-06-21 -    Ibrahim Rumi   -EPBBS-2750 AutoCreateEventItem() to auto create event items on approval submission
 *         2023-08-03 -    RANAND         -EPBBS-3285 Populate Event Details on associated campaigns in case of Event Details update
 **/
trigger BTEventTrigger on conference360__Event__c (before insert,before update, after insert, after update) {

    if (TriggerCommon.doNotRunTrigger('conference360__Event__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new BTEventTriggerHandler.CascadeEventFields())
        .bindExtended(Triggers.Evnt.beforeUpdate, new BTEventTriggerHandler.CascadeEventFields())
        .bindExtended(Triggers.Evnt.afterInsert, new BTEventTriggerHandler.CreateCampaign())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventTriggerHandler.DeleteOldCampaignLink())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventTriggerHandler.ManageCampaignStatus())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventTriggerHandler.UpdateCampusName())
        .bindExtended(Triggers.Evnt.beforeInsert, new BTEventTriggerHandler.UpdateLocationDetails())
        .bindExtended(Triggers.Evnt.beforeUpdate, new BTEventTriggerHandler.UpdateLocationDetails())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventTriggerHandler.UpdateSessionStatus())
	    .bindExtended(Triggers.Evnt.beforeInsert, new BTEventTriggerHandler.IdentifyWinningAffiliation())
        .bindExtended(Triggers.Evnt.beforeUpdate, new BTEventTriggerHandler.IdentifyWinningAffiliation())
	    .bindExtended(Triggers.Evnt.beforeInsert, new BTEventTriggerHandler.ValidateStreamingURL())
        .bindExtended(Triggers.Evnt.beforeUpdate, new BTEventTriggerHandler.ValidateStreamingURL())
        .bindExtended(Triggers.Evnt.afterInsert, new BTEventTriggerHandler.ManageChildRecsForEventOnEvntGrpChange())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventTriggerHandler.ManageChildRecsForEventOnEvntGrpChange())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventTriggerHandler.AutoCreateEventItem())
        .bindExtended(Triggers.Evnt.beforeUpdate, new BTEventTriggerHandler.validatePermissionAndEventStatusUpdate())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventTriggerHandler.UpdateAssociatedCampaign())
    .execute();
}