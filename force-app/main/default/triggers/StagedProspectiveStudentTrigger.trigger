/**
 * @Description Trigger for Staged Prospective Student Object
 * @Author Nick Guia
 * @Group Lead Management
 **/
trigger StagedProspectiveStudentTrigger on Staged_Prospective_Student__c (before insert, before update, after insert, after update) {

	if (TriggerCommon.doNotRunTrigger('Staged_Prospective_Student__c')) { return; }
	
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new SpsTriggerHandler.IdentifyAcquisitionSourceCampaign())
        .bindExtended(Triggers.Evnt.beforeInsert, new SpsTriggerHandler.ExplodeContact())
        .bindExtended(Triggers.Evnt.beforeUpdate, new SpsTriggerHandler.ExplodeContact())
        .bindExtended(Triggers.Evnt.afterInsert, new SpsTriggerHandler.ExplodeLeadsToObjects())
        .bindExtended(Triggers.Evnt.afterUpdate, new SpsTriggerHandler.ExplodeLeadsToObjects())
    .execute();
}