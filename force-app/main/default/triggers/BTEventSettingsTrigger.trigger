/**
 * @author Nick Guia
 * @date 15-10-2020
 * @group Event Management
 * @description Trigger for conference360__Event_Settings__c object (Blackthorn)
 **/
trigger BTEventSettingsTrigger on conference360__Event_Settings__c (before insert) {

    if (TriggerCommon.doNotRunTrigger('conference360__Event_Settings__c')) { return; }
	
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new BTEventSettingsTriggerHandler.ManageRelationshipSettings())
    .execute();
}