/**
 * @author RANAND
 * @date 2022-05-10
 * @group Event Keyword Management
 * @description Trigger for conference360__Event_Keyword__c object (Blackthorn)
 * @revision
 *         2022-05-10 -   RANAND     -EPBBS-2629 Validate Event Keyword Selection on Events
 *         2022-06-01 -   Ibrahim Rumi     -EPBBS-2643 Manage event keywords cascading from event groups to related events
 **/
trigger BTEventKeywordTrigger on conference360__Event_Keyword__c (before insert, before update, after insert, after update, after delete) {
    if (TriggerCommon.doNotRunTrigger('conference360__Event_Keyword__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeinsert, new BTEventKeywordHandler.ValidateCategoryonKeyword())
        .bindExtended(Triggers.Evnt.beforeupdate, new BTEventKeywordHandler.ValidateCategoryonKeyword())
        .bindExtended(Triggers.Evnt.afterInsert, new BTEventKeywordHandler.autoCreateEventKeywords())
        .bindExtended(Triggers.Evnt.afterUpdate, new BTEventKeywordHandler.autoCreateEventKeywords())       
        .bindExtended(Triggers.Evnt.afterDelete, new BTEventKeywordHandler.autoCreateEventKeywords())
    .execute();
}