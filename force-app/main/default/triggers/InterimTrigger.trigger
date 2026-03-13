/**
 * @description       : Trigger class specific to Interim sObject. 
 * @author            : Mark Johnson: UC Innovation
 * @group             : Trigger
 * @last modified on  : 22/02/2023
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2019-10-09   Mark Johnson   Initial Version, Interim SObject is used to stage, dedupe, and validate contacts that are loaded from external sources.
 * 1.1   2023-02-22   Inderpal Dhan   PENGAGE-2658 Format the Phone number to prevent KeyUID Error on Phone Object.
**/
trigger InterimTrigger on ucinn_ascendv2__Interim__c (before insert, before update, after insert) {
    
    if (TriggerCommon.doNotRunTrigger('ucinn_ascendv2__Interim__c')) {
        return;
    }
    
    new Triggers()
            .bind(Triggers.Evnt.beforeInsert, new EngageInterimService.populateInterimForProcessing())
            .bindExtended(Triggers.Evnt.beforeInsert, new EngageInterimService.formatMobile()) 
            .bind(Triggers.Evnt.afterInsert, new EngageInterimService.blankUpdateOnInterim())
            .bind(Triggers.Evnt.beforeUpdate, new EngageInterimService.updateReviewTransactionwithContact())
            .bindExtended(Triggers.Evnt.beforeUpdate, new EngageInterimService.formatMobile()) 
            .execute();
}