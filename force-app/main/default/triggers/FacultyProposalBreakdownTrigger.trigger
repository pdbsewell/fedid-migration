/**
 * @author			Emily Chen
 * @description     Trigger class specific to Faculty_Proposal_Breakdown__c sObject
 */
trigger FacultyProposalBreakdownTrigger on Faculty_Proposal_Breakdown__c (after insert, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Faculty_Proposal_Breakdown__c')) { 
    	return; 
    }

    //Updated to follow UNICRM practices
    new Triggers()
            .bind(Triggers.Evnt.afterInsert, new FacultyProposalBreakdownService.UpdateFaculties())
            .bind(Triggers.Evnt.afterUpdate, new FacultyProposalBreakdownService.UpdateFaculties())
            .bind(Triggers.Evnt.afterDelete, new FacultyProposalBreakdownService.UpdateFaculties())
            .bind(Triggers.Evnt.afterUndelete, new FacultyProposalBreakdownService.UpdateFaculties())
            .execute();
}