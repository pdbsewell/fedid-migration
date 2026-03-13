/**
 * @description       : Trigger on Opportunity FoR
 * @author            : Inderpal Dhanoa
 * @group             : Trigger
 * @last modified on  : 2021-05-23
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.0   2021-05-23   Inderpal Dhanoa    Initial Version
 **/
trigger OpportunityFoRTrigger on Opportunity_FoR__c (before insert, after insert, after update, before update, before delete, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Opportunity_FoR__c')) { 
    	return; 
    }

    new Triggers()
    // insert
    .bindExtended(Triggers.Evnt.beforeInsert, new OpportunityFoRTriggerHandler.ValidateOwnership())  	
    .bindExtended(Triggers.Evnt.beforeInsert, new OpportunityFoRTriggerHandler.setupUID())

    // update
    .bindExtended(Triggers.Evnt.beforeUpdate, new OpportunityFoRTriggerHandler.ValidateOwnership())
    .bindExtended(Triggers.Evnt.beforeUpdate, new OpportunityFoRTriggerHandler.setupUID())
    
    // delete

    // let's go
    .execute();
}