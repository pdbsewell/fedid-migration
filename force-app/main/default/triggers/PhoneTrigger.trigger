/**
 * @author
 * @description     Trigger class specific to Phone__c sObject
 * @revision
 * 					15.JUN.2020 - J.Mapanao - Added EvaluateIfCanSetPrimary
 */
trigger PhoneTrigger on Phone__c (before insert, after insert, before update, after update, after delete, after undelete, before delete) {

	if (TriggerCommon.doNotRunTrigger('Phone__c')) {
		return;
	}
	//Run Trigger
	new Triggers()
	//BEFORE INSERT
	.bindExtended(Triggers.Evnt.beforeinsert, new PhoneTriggerHandler.DefaultStartDate())
	.bindExtended(Triggers.Evnt.beforeinsert, new PhoneTriggerHandler.ToggleIsActive())
	.bindExtended(Triggers.Evnt.beforeinsert, new PhoneTriggerHandler.CheckIsActive())
	.bindExtended(Triggers.Evnt.beforeinsert, new PhoneTriggerHandler.EvaluateIfCanSetPrimary())
	.bindExtended(Triggers.Evnt.beforeinsert, new PhoneTriggerHandler.formatMobile())
	.bindExtended(Triggers.Evnt.beforeinsert, new PhoneTriggerHandler.PopulateHash())
	//BEFORE UPDATE
	.bindExtended(Triggers.Evnt.beforeupdate, new PhoneTriggerHandler.SetIsActiveEndDate())
	.bindExtended(Triggers.Evnt.beforeupdate, new PhoneTriggerHandler.ToggleIsActive())
	.bindExtended(Triggers.Evnt.beforeupdate, new PhoneTriggerHandler.CheckIsActive())
	.bindExtended(Triggers.Evnt.beforeupdate, new PhoneTriggerHandler.EvaluateIfCanSetPrimary())
	.bindExtended(Triggers.Evnt.beforeupdate, new PhoneTriggerHandler.formatMobile())
	.bindExtended(Triggers.Evnt.beforeupdate, new PhoneTriggerHandler.PopulateHash())
	//AFTER INSERT
	.bindExtended(Triggers.Evnt.afterinsert, new PhoneTriggerHandler.TogglePrimary())
	.bindExtended(Triggers.Evnt.afterinsert, new PhoneTriggerHandler.FindNewPrimary())
	.bindExtended(Triggers.Evnt.afterinsert, new PhoneTriggerHandler.RollUpLogic())
	.bindExtended(Triggers.Evnt.afterinsert, new PhoneTriggerHandler.FindNewParentChannel())
	//AFTER UPDATE
	.bindExtended(Triggers.Evnt.afterupdate, new PhoneTriggerHandler.TogglePrimary())
	.bindExtended(Triggers.Evnt.afterupdate, new PhoneTriggerHandler.FindNewPrimary())
	.bindExtended(Triggers.Evnt.afterupdate, new PhoneTriggerHandler.RollUpLogic())
	.bindExtended(Triggers.Evnt.afterupdate, new PhoneTriggerHandler.FindNewParentChannel())
	//AFTER DELETE
	.bindExtended(Triggers.Evnt.afterdelete, new PhoneTriggerHandler.FindNewPrimary())
	.bindExtended(Triggers.Evnt.afterdelete, new PhoneTriggerHandler.RollUpLogic())
	.execute();

}