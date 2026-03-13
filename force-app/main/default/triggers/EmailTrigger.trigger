/**
 * @author
 * @description     Trigger class specific to Email__c sObject
 * @revision
 * 	2020-06-15 - J.Mapanao - Added EvaluateIfCanSetPrimary
 *  2022-05-20 - Stefan Scheit - Added BlankoutUnreachableReason handler
 */
trigger EmailTrigger on Email__c (before insert, after insert, before update, before delete, after update, after delete, after undelete) {

	if (TriggerCommon.doNotRunTrigger('Email__c')) {
		return;
	}
	//Run Triggers
	new Triggers()
	//BEFORE INSERT
	.bindExtended(Triggers.Evnt.beforeinsert, new EmailTriggerHandler.BlankoutUnreachableReason())
    .bindExtended(Triggers.Evnt.beforeinsert, new EmailTriggerHandler.CheckMonashEmail())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmailTriggerHandler.DefaultStartDate())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmailTriggerHandler.ToggleIsActive())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmailTriggerHandler.CheckIsActive())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmailTriggerHandler.EvaluateIfCanSetPrimary())
	.bindExtended(Triggers.Evnt.beforeinsert, new EmailTriggerHandler.PopulateHash())
	//BEFORE UPDATE
	.bindExtended(Triggers.Evnt.beforeupdate, new EmailTriggerHandler.BlankoutUnreachableReason())
    .bindExtended(Triggers.Evnt.beforeupdate, new EmailTriggerHandler.CheckMonashEmail())
	.bindExtended(Triggers.Evnt.beforeupdate, new EmailTriggerHandler.SetIsActiveEndDate())
	.bindExtended(Triggers.Evnt.beforeupdate, new EmailTriggerHandler.ToggleIsActive())
	.bindExtended(Triggers.Evnt.beforeupdate, new EmailTriggerHandler.CheckIsActive())
	.bindExtended(Triggers.Evnt.beforeupdate, new EmailTriggerHandler.EvaluateIfCanSetPrimary())
	.bindExtended(Triggers.Evnt.beforeupdate, new EmailTriggerHandler.PopulateHash())
	//AFTER INSERT
	.bindExtended(Triggers.Evnt.afterinsert, new EmailTriggerHandler.TogglePrimary())
	.bindExtended(Triggers.Evnt.afterinsert, new EmailTriggerHandler.FindNewPrimary())
	.bindExtended(Triggers.Evnt.afterinsert, new EmailTriggerHandler.RollUpLogic())
	.bindExtended(Triggers.Evnt.afterinsert, new EmailTriggerHandler.FindNewParentChannel())
	//AFTER UPDATE
	.bindExtended(Triggers.Evnt.afterupdate, new EmailTriggerHandler.TogglePrimary())
	.bindExtended(Triggers.Evnt.afterupdate, new EmailTriggerHandler.FindNewPrimary())
	.bindExtended(Triggers.Evnt.afterupdate, new EmailTriggerHandler.RollUpLogic())
	.bindExtended(Triggers.Evnt.afterupdate, new EmailTriggerHandler.FindNewParentChannel())
	//AFTER DELETE
	.bindExtended(Triggers.Evnt.afterdelete, new EmailTriggerHandler.FindNewPrimary())
	.bindExtended(Triggers.Evnt.afterdelete, new EmailTriggerHandler.RollUpLogic())
	.execute();

}