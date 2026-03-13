/**
 * @group Commons
 * @description Trigger for Campaign object
 * @revision	15.Apr.2020 - EPBBS-1000 (ayush.agrawal@monash.edu)
 * @revision	20.May.2020 - EPBBS-1252 (ayush.agrawal@monash.edu) - Added generateReplyToForRetentionCampaigns.
 * @revision	21.JULY.2020 - EPBBS-1330 Nick Guia - Added LinkEventCampaign and FormEventLink
 * @revision	24.AUG.2020 - EPBBS-1499 Nick Guia - Added UpdateEventMemberStatuses
 * @revision    11.02.2020  Steffi added - UpdateCompanyCampaignAppeal (PENGAGE-1710)
 * @revison     24-08-2021  Aref Samad 	 -LinkEventGroup: EPBBS-2083 Link Event Group to Parent Campaign
 * @revision    14-04-2022 - EPBBS-2554 RANAND update related Event Groups if Cascaded fields are modified on Campaign
 */
trigger CampaignTrigger on Campaign (before insert, before update, before delete, after insert, after update) {

    if (TriggerCommon.doNotRunTrigger('Campaign')) { return; }

    new Triggers()
        // Before Insert
        .bindExtended(Triggers.Evnt.beforeInsert, new CampaignTriggerHandler.alignCampainMemberRecordTypes())
        .bindExtended(Triggers.Evnt.beforeInsert, new CampaignTriggerHandler.UpdateCompanyCampaignAppeal())
        // Before Update
        .bindExtended(Triggers.Evnt.beforeUpdate, new CampaignTriggerHandler.UpdateCompanyCampaignAppeal())
        .bindExtended(Triggers.Evnt.beforeUpdate, new CampaignTriggerHandler.UpdateEventActiveFlag())
        // Before Delete
        .bindExtended(Triggers.Evnt.beforeDelete, new CampaignTriggerHandler.preventCampaignDeletion())
        // After Insert
        .bindExtended(Triggers.Evnt.afterInsert, new CampaignTriggerHandler.createCampaignMemberStatuses())
        .bindExtended(Triggers.Evnt.afterInsert, new CampaignTriggerHandler.LinkEventCampaign())
        // After Update
        .bindExtended(Triggers.Evnt.afterUpdate, new CampaignTriggerHandler.DeleteOldEventLink())
        .bindExtended(Triggers.Evnt.afterUpdate, new CampaignTriggerHandler.UpdateEventStatus())

    .execute();
}