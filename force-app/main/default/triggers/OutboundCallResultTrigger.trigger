/*
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group	SRA (Student Recruitment and Admissions) - BabyShark
 * @revision        inderpal.dhanoa@monash.edu - MCT-414 Add Logic to craete MC Campaign Members.
 * @revision        inderpal.dhanoa@monash.edu - MCT-456 Add Logic to close linked MC Enquiries.
 */

trigger OutboundCallResultTrigger on Outbound_Call_Result__c (before insert, before update, after insert, after update) {
	if(TriggerCommon.doNotRunTrigger('Outbound_Call_Result__c')) {
        return;
    }

    new Triggers()
    .bind(Triggers.Evnt.beforeInsert, new OutboundCallResultServices.unassignedQueueOwnerAssignment())
    .bind(Triggers.Evnt.beforeUpdate, new OutboundCallResultServices.linkCasesAndCloseMonConSupportOutboundCalls())
    .bind(Triggers.Evnt.beforeUpdate, new OutboundCallResultServices.trackOutboundCallsDateTimeClosed())
    .bindExtended(Triggers.Evnt.afterinsert, new OutboundCallResultServices.createMCCampaignMember())
    .bindExtended(Triggers.Evnt.afterupdate, new OutboundCallResultServices.closeLinkedMCEnquiries())
    .bindExtended(Triggers.Evnt.afterinsert, new OutboundCallResultServices.SetOutboundCallStatus())
    .bindExtended(Triggers.Evnt.afterupdate, new OutboundCallResultServices.SetOutboundCallStatus())
    .execute();
}