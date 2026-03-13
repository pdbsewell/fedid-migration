/**
 * @description       : Trigger for Opportunity Collaborator object.
 * @author            : Stefan Scheit
 * @group             : Trigger
 * @last modified on  : 2021-03-16
 * @last modified by  : Inderpal Dhanoa idha0002
 * Modifications Log 
 * Ver   Date         Author         	Modification
 * 1.3	 2023-11-08	  Davey Yu			ENGAGEIE-1812
 * 1.2   2022-04-15   Inderpal Dhanoa   ENGAGEIE-1371
 * 1.1   2022-04-03   Inderpal Dhanoa   ENGAGEIE-1303
 * 1.0   2020-10-01   Stefan Scheit   	Initial Version
**/
trigger OpportunityCollaboratorTrigger on Opportunity_Collaborator__c (before insert, after insert, after update, before update, before delete, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Opportunity_Collaborator__c')) { 
    	return; 
    }

    new Triggers()
		// insert
		.bindExtended(Triggers.Evnt.beforeinsert, new OpportunityCollaboratorTriggerHandler.SetOpportunityCollaboratorUniqueId()) 
		.bindExtended(Triggers.Evnt.afterInsert, new DlrsDelegateTriggerHandler(Opportunity_Collaborator__c.SObjectType))
		.bindExtended(Triggers.Evnt.afterinsert, new OpportunityCollaboratorTriggerHandler.UpdateOpportunityFaculties())
        .bindExtended(Triggers.Evnt.beforeinsert, new OpportunityCollaboratorTriggerHandler.SetLeadCollaborator()) 

		// update
		.bindExtended(Triggers.Evnt.afterUpdate, new DlrsDelegateTriggerHandler(Opportunity_Collaborator__c.SObjectType))
		.bindExtended(Triggers.Evnt.beforeUpdate, new OpportunityCollaboratorTriggerHandler.SetOpportunityCollaboratorUniqueId())
		.bindExtended(Triggers.Evnt.afterUpdate, new OpportunityCollaboratorTriggerHandler.UpdateOpportunityFaculties())
        
		// delete
		.bindExtended(Triggers.Evnt.beforeDelete, new OpportunityCollaboratorTriggerHandler.DeleteOpportunityFaculties()) 
		.bindExtended(Triggers.Evnt.afterDelete, new DlrsDelegateTriggerHandler(Opportunity_Collaborator__c.SObjectType))
		.bindExtended(Triggers.Evnt.afterUndelete, new DlrsDelegateTriggerHandler(Opportunity_Collaborator__c.SObjectType))
		// let's go
		.execute();
}