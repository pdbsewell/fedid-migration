/**
 * @description       : Trigger on Opportunity
 * @author            : Mark Johnson (UC - Innovation)
 * @group             : Trigger
 * @last modified on  : 2020-09-17
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2020-09-17   Stefan Scheit   Added DlrsDelegateTriggerHandler (for DLRS (declrarative lookup rollup summaries))
 * 1.0   2019-08-29   Mark Johnson    Initial Version
 * 1.2   2021-08-30   Indrpal Dhanoa  ENGAGEIE-456 Opportunity Access Control
 * 1.3   2021-09-08   Inderpal Dhanoa ENGAGEIE-1019 Opportunity Pure Id Sync
 * 1.4   2024-01-10   Davey yu		  ENGAGEIE-1841 Throw an error for potential enterprise duplicate based on Monash System Id
 * 1.5   2024-06-24   Inderpal Dhanoa PENGAGE-2758 Sync COntact for Bequestor Oppty
**/
trigger OpportunityTrigger on Opportunity (before insert, after insert, after update, before update, before delete, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Opportunity')) { 
    	return; 
    }

    new Triggers()
		// insert
		.bind(Triggers.Evnt.beforeInsert, new EngageOpportunityService.validateThatUserHasAssignment())
		.bind(Triggers.Evnt.beforeInsert, new EngageOpportunityService.validateDuplicateMonashSystemId())
        .bind(Triggers.Evnt.beforeInsert, new EngageOpportunityService.prepopulateFields())
		.bind(Triggers.Evnt.afterInsert, new EngageOpportunityService.ReassociateOpportunityTeams())
		.bind(Triggers.Evnt.afterInsert, new EngageOpportunityService.processMajorGifts())
		.bindExtended(Triggers.Evnt.afterInsert, new OpportunityTriggerHandler.SyncContactForBequestOppty())	
		.bindExtended(Triggers.Evnt.afterInsert, new DlrsDelegateTriggerHandler(Opportunity.SObjectType))
		.bindExtended(Triggers.Evnt.beforeInsert, new OpportunityTriggerHandler.SyncVisibilityCategoryAndIsPrivate())
		.bindExtended(Triggers.Evnt.beforeInsert, new OpportunityTriggerHandler.SyncPureId()) 	
		// update
		.bind(Triggers.Evnt.beforeUpdate, new EngageOpportunityService.setAuthorizeAndCharge())
		.bindExtended(Triggers.Evnt.beforeUpdate, new OpportunityTriggerHandler.SyncVisibilityCategoryAndIsPrivate()) 
		.bindExtended(Triggers.Evnt.beforeUpdate, new OpportunityTriggerHandler.SyncPureId()) 
		.bindExtended(Triggers.Evnt.beforeUpdate, new OpportunityTriggerHandler.ValidateStageChange())  
		.bind(Triggers.Evnt.beforeUpdate, new EngageOpportunityService.validateDuplicateMonashSystemId())  
        .bind(Triggers.Evnt.beforeUpdate, new EngageOpportunityService.prepopulateFields())
		.bind(Triggers.Evnt.afterUpdate, new EngageOpportunityService.processMajorGifts())
		.bind(Triggers.Evnt.afterUpdate, new EngageOpportunityService.ReassociateOpportunityTeams())
		.bindExtended(Triggers.Evnt.afterUpdate, new DlrsDelegateTriggerHandler(Opportunity.SObjectType))
		.bindExtended(Triggers.Evnt.afterUpdate, new OpportunityTriggerHandler.NominateOfferHealthCover())  
		.bindExtended(Triggers.Evnt.afterUpdate, new OpportunityTriggerHandler.SyncContactForBequestOppty())  
		// delete
		.bindExtended(Triggers.Evnt.beforeDelete, new OpportunityTriggerHandler.SyncContactForBequestOppty())
		.bind(Triggers.Evnt.afterDelete, new EngageOpportunityService.processMajorGifts())
		.bindExtended(Triggers.Evnt.afterDelete, new DlrsDelegateTriggerHandler(Opportunity.SObjectType))
		.bind(Triggers.Evnt.afterUndelete, new EngageOpportunityService.processMajorGifts())
		.bindExtended(Triggers.Evnt.afterUndelete, new DlrsDelegateTriggerHandler(Opportunity.SObjectType))
		// let's go
		.execute();
}