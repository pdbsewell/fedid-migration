/**
 * @author Aref Samad
 * @date 23-08-2021
 * @group Event Management
 * @description Trigger for conference360__Event_Group__c object (Blackthorn)
 * @revision
 *         2021-08-23 -    Aref Samad     -EPBBS-2083 Link Event Group to Parent Campaign
 *         2022-04-14 -    RANAND         -EPBBS-2554 Copy Cascaded fields from Campaign to Event Group 
 *         2023-08-03 -    RANAND         -EPBBS-3285 Populate Event Group Details on associated campaigns
 **/
trigger BTEventGroupTrigger on conference360__Event_Group__c (before insert, before update, after update, after insert) {

    if (TriggerCommon.doNotRunTrigger('conference360__Event_Group__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeinsert, new BTEventGroupTriggerHandler.CaptureCascadedFieldFromCampaign())
        .bindExtended(Triggers.Evnt.afterupdate, new BTEventGroupTriggerHandler.UpdateAssociatedCampaign())
        .bindExtended(Triggers.Evnt.afterInsert, new BTEventGroupTriggerHandler.ManageEventGroupCampaign())
    .execute();
}