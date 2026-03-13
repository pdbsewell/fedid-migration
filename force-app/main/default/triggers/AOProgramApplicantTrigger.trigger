/**
 * @author : [Babyshark]
 * @description : Trigger for (AO_Program_Applicant__c)Program Applicant
 *  - Handles generation of subsequent form automatically on change of status on Primary
 *  - Handles auatomated emails from SF to Students
 * @group : Abroad Outbound
 * @date : 23/07/2025
 * @rev
 *         2025-07-23 -    Ibrahim Rumi   - modified CreateAutomatedEmails to run on insert too
 */ 
trigger AOProgramApplicantTrigger on AO_Program_Applicant__c (before insert, after update, after insert) {

if (TriggerCommon.doNotRunTrigger('AO_Program_Applicant__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.afterUpdate, new AOProgramApplicantTriggerHandler.CreateAutomatedForms())
        .bindExtended(Triggers.Evnt.afterUpdate, new AOProgramApplicantTriggerHandler.CreateAutomatedEmails())
        .bindExtended(Triggers.Evnt.afterInsert, new AOProgramApplicantTriggerHandler.CreateAutomatedEmails())
    .execute();
}