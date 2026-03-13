/**
 * @author          J.Mapanao
 * @date            22/03/2019
 * @description     Trigger class specific to Social__c sObject
 * @revision
 */
trigger SocialTrigger on Social__c (before insert, after insert, before update, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Social__c')) {
        return;
    }
    //Run Triggers
    new Triggers()
    //BEFORE INSERT
    .bindExtended(Triggers.Evnt.beforeinsert, new SocialTriggerHandler.DefaultStartDate())
    .bindExtended(Triggers.Evnt.beforeinsert, new SocialTriggerHandler.ToggleIsActive())
    .bindExtended(Triggers.Evnt.beforeinsert, new SocialTriggerHandler.PopulateHash())
    //BEFORE UPDATE
    .bindExtended(Triggers.Evnt.beforeupdate, new SocialTriggerHandler.SetIsActiveEndDate())
    .bindExtended(Triggers.Evnt.beforeupdate, new SocialTriggerHandler.ToggleIsActive())
    .bindExtended(Triggers.Evnt.beforeupdate, new SocialTriggerHandler.PopulateHash())
    //AFTER INSERT
    .bindExtended(Triggers.Evnt.afterinsert, new SocialTriggerHandler.TogglePrimary())
    //AFTER UPDATE
    .bindExtended(Triggers.Evnt.afterupdate, new SocialTriggerHandler.TogglePrimary())
    .execute();

}