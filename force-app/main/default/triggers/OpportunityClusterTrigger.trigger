/**
 * @description       : Trigger on Opportunity Cluster
 * @author            : Inderpal Dhanoa
 * @group             : Enterprise Engage
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.0   2021-09-08   Inderpal Dhanoa    Initial Version
**/
trigger OpportunityClusterTrigger on Opportunity_Cluster__c (before insert, after insert, after update, before update, before delete, after delete, after undelete) {
    if (TriggerCommon.doNotRunTrigger('Opportunity_Cluster__c')) { 
    	return; 
    }
    new Triggers()
    // insert
    .bindExtended(Triggers.Evnt.afterInsert, new OpportunityClusterTriggerHandler.SyncPureIdWithOpportunity())

    // update
    .bindExtended(Triggers.Evnt.afterUpdate, new OpportunityClusterTriggerHandler.SyncPureIdWithOpportunity())

    // delete

    // let's go
    .execute();
}