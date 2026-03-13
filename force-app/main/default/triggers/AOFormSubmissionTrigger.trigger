/**
 * @author Ibrahim Rumi
 * @date 29-05-2024
 * @group Monash Abroad
 * @description Trigger for AO_Form_Submission__c object 
 **/
trigger AOFormSubmissionTrigger on AO_Form_Submission__c (after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('AO_Form_Submission__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.afterInsert, new AOFormSubmissionTriggerHandler.createProgramApplicant())
        .bindExtended(Triggers.Evnt.afterUpdate, new AOFormSubmissionTriggerHandler.createProgramApplicant())
    .execute();
}