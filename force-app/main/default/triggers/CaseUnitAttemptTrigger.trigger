/**
 * @author          Tom Gangemi
 * @description    	Trigger for Case_Unit_Attempt__c object
 * @revision        2022-09-21 - Tom Gangemi - Initial version
 */
trigger CaseUnitAttemptTrigger on Case_Unit_Attempt__c (before insert, before update, after update) {
    new Triggers()
        .bindExtended(Triggers.Evnt.beforeinsert, new CaseUnitAttemptTriggerHandler.SpecConUpdateExistingCUAs())
        .bindExtended(Triggers.Evnt.beforeupdate, new CaseUnitAttemptTriggerHandler.SpecConOnStatusChange())
        .bindExtended(Triggers.Evnt.beforeupdate, new CaseUnitAttemptTriggerHandler.SendSpecConAutoApprovalEmail())
        .bindExtended(Triggers.Evnt.afterupdate, new CaseUnitAttemptTriggerHandler.SpecConUpdateCaseOutcome())
        .execute();
}