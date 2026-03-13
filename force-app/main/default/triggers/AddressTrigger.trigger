/**
 * @author
 * @description     Trigger class specific to Address__c sObject
 * @revision        2019-03-19 - J.Mapanao - Added logic for formatting Address__c.Name on before insert event
 *                  2020-05-15 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *                  2020-06-25 - Stefan Scheit - Removed Name population handler for address (it's been auto number for a while)
 */
trigger AddressTrigger on Address__c (before insert, after insert, before update, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Address__c')) {
        return;
    } 
    //Run Triggers
    new Triggers()
    // BEFORE INSERT
    .bindExtended(Triggers.Evnt.beforeinsert, new AddressTriggerHandler.DefaultStartDate())
    .bindExtended(Triggers.Evnt.beforeinsert, new AddressTriggerHandler.ToggleIsActive())
    .bindExtended(Triggers.Evnt.beforeinsert, new AddressTriggerHandler.CheckIsActive())
    .bindExtended(Triggers.Evnt.beforeinsert, new AddressTriggerHandler.EvaluateIfCanSetPrimary())
    .bindExtended(Triggers.Evnt.beforeinsert, new AddressTriggerHandler.PopulateHash())
    // BEFORE UPDATE
    .bindExtended(Triggers.Evnt.beforeupdate, new AddressTriggerHandler.SetIsActiveEndDate())
    .bindExtended(Triggers.Evnt.beforeupdate, new AddressTriggerHandler.ToggleIsActive())
    .bindExtended(Triggers.Evnt.beforeupdate, new AddressTriggerHandler.CheckIsActive())
    .bindExtended(Triggers.Evnt.beforeupdate, new AddressTriggerHandler.EvaluateIfCanSetPrimary())
    .bindExtended(Triggers.Evnt.beforeupdate, new AddressTriggerHandler.PopulateHash())
    // AFTER INSERT
    .bindExtended(Triggers.Evnt.afterinsert, new AddressTriggerHandler.TogglePrimary())
    .bindExtended(Triggers.Evnt.afterinsert, new AddressTriggerHandler.FindNewPrimary())
    .bindExtended(Triggers.Evnt.afterinsert, new AddressTriggerHandler.RollUpLogic())
    .bindExtended(Triggers.Evnt.afterinsert, new AddressTriggerHandler.FindNewParentChannel())
    //AFTER UPDATE
    .bindExtended(Triggers.Evnt.afterupdate, new AddressTriggerHandler.TogglePrimary())
    .bindExtended(Triggers.Evnt.afterupdate, new AddressTriggerHandler.FindNewPrimary())
    .bindExtended(Triggers.Evnt.afterupdate, new AddressTriggerHandler.RollUpLogic())
    .bindExtended(Triggers.Evnt.afterupdate, new AddressTriggerHandler.FindNewParentChannel())
    //After DELETE
    .bindExtended(Triggers.Evnt.afterdelete, new AddressTriggerHandler.FindNewPrimary())
    .bindExtended(Triggers.Evnt.afterdelete, new AddressTriggerHandler.RollUpLogic())
    .execute();

}