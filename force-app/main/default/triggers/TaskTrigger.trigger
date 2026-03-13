/*
 * @revision:	28-09-2020 ayush.agrawal@monash.edu - RW2-477 Added rollUpCallCountToCase.
 * @revision:	29-09-2020 APRivera - RW2-473 Added UpdateRelatedCase.
 * @revision:   19-10-2021 IDhanoa - ENGAGEIE-1004 Added ValidateContactReportTask.
 */
trigger TaskTrigger on Task (after insert, before insert, before update, after update, after delete) {

    if (TriggerCommon.doNotRunTrigger('Task')) { return; }
    
    new Triggers()
    .bind(Triggers.Evnt.beforeInsert, new TaskServices.considerWrapUpTasks())
    .bind(Triggers.Evnt.beforeInsert, new TaskServices.considerTaskFieldMappings())
    .bind(Triggers.Evnt.beforeInsert, new TaskServices.considerServiceLevelAgreementTasks())
    .bind(Triggers.Evnt.beforeInsert, new TaskServices.CopyACPId())
    .bind(Triggers.Evnt.beforeUpdate, new TaskServices.CopyACPId())
    .bind(Triggers.Evnt.beforeInsert, new TaskServices.CopyTaskType())
    .bind(Triggers.Evnt.beforeUpdate, new TaskServices.CopyTaskType())
	.bindExtended(Triggers.Evnt.beforeUpdate, new TaskServices.ValidateContactReportTask())
        
    .bind(Triggers.Evnt.afterInsert, new CaseServices.clearLastEmailReceived())
    .bind(Triggers.Evnt.afterInsert, new CaseServices.LogRecordingOnActivityInsert())
    .bindExtended(Triggers.Evnt.afterInsert, new TaskServices.LinkCorrectCaseToCTICallLog())
    .bind(Triggers.Evnt.afterInsert, new TaskServices.processDuplicateWrapUpTasks())
    .bind(Triggers.Evnt.afterInsert, new TaskServices.rollUpCallCountToCase())
    .bindExtended(Triggers.Evnt.afterInsert, new TaskServices.UpdateRelatedCase())
    .bindExtended(Triggers.Evnt.afterInsert, new TaskServices.AddCaseTeam())
	
        
        
    .bind(Triggers.Evnt.afterDelete, new TaskServices.rollUpCallCountToCase())
        
    .bindExtended(Triggers.Evnt.afterupdate, new TaskServices.UpdateRelatedCase())
    .bindExtended(Triggers.Evnt.afterUpdate, new TaskServices.AddCaseTeam())
    .execute();

    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            StudFirst_CRMInitiatedCommsToAP.notifyAgentByTask((List<Task>)Trigger.new);
        } else if(Trigger.isUpdate) {
            TaskServices.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}