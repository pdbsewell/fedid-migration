/**
 * @author
 * @description     Trigger class specific to Name__c sObject
 * @revision
 *                  15.JUN.2020 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *                  12.MAY.2022 - T.Gangemi - SA-1477 - Moved primary calculations to before triggers with AllocatePrimaryRecord
 */
trigger NameTrigger on Name__c (before insert, after insert, before update, after update, after delete, after undelete, before delete) {

    if (TriggerCommon.doNotRunTrigger('Name__c')) {
        return;
    }

    //Run Triggers
    new Triggers()
    // Before Insert
    .bindExtended(Triggers.Evnt.beforeinsert, new NameTriggerHandler.DefaultStartDate())
    .bindExtended(Triggers.Evnt.beforeinsert, new NameTriggerHandler.ToggleIsActive())
    .bindExtended(Triggers.Evnt.beforeinsert, new NameTriggerHandler.CheckIsActive())
    .bindExtended(Triggers.Evnt.beforeinsert, new NameTriggerHandler.AllocatePrimaryRecord())
    .bindExtended(Triggers.Evnt.beforeinsert, new NameTriggerHandler.Mononymous())
    .bindExtended(Triggers.Evnt.beforeinsert, new NameTriggerHandler.InitialiseFields())
    .bindExtended(Triggers.Evnt.beforeinsert, new NameTriggerHandler.PopulateHash())

    // Before Update
    .bindExtended(Triggers.Evnt.beforeupdate, new NameTriggerHandler.SetIsActiveEndDate())
    .bindExtended(Triggers.Evnt.beforeupdate, new NameTriggerHandler.ToggleIsActive())
    .bindExtended(Triggers.Evnt.beforeupdate, new NameTriggerHandler.CheckIsActive())
    .bindExtended(Triggers.Evnt.beforeupdate, new NameTriggerHandler.AllocatePrimaryRecord())
    .bindExtended(Triggers.Evnt.beforeUpdate, new NameTriggerHandler.Mononymous())
    .bindExtended(Triggers.Evnt.beforeUpdate, new NameTriggerHandler.InitialiseFields())
    .bindExtended(Triggers.Evnt.beforeupdate, new NameTriggerHandler.PopulateHash())

    // After Insert
    .bindExtended(Triggers.Evnt.afterinsert, new NameTriggerHandler.UpdateSalutations())
    .bindExtended(Triggers.Evnt.afterinsert, new NameTriggerHandler.RollUpLogic())

    // After Update
    .bindExtended(Triggers.Evnt.afterupdate, new NameTriggerHandler.UpdateSalutations())
    .bindExtended(Triggers.Evnt.afterupdate, new NameTriggerHandler.RollUpLogic())

    // After Delete
    .bindExtended(Triggers.Evnt.afterdelete, new NameTriggerHandler.AllocatePrimaryRecord())
    .bindExtended(Triggers.Evnt.afterdelete, new NameTriggerHandler.RollUpLogic())
    //Execute
    .execute();
}