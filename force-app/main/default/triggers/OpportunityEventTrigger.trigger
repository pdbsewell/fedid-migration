/**
 * @File Name          : OpportunityChangeEventTrigger.trigger
 * @Description        : 
 * @Author             : David Browaeys
 * @Group              : 
 * @Last Modified By   : David Browaeys
 * @Last Modified On   : 10/18/2019, 9:30:38 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    10/16/2019   David Browaeys     Initial Version
**/
trigger OpportunityEventTrigger on Opportunity_Event__e (after insert) {
    if (TriggerCommon.doNotRunTrigger('Opportunity') || TriggerCommon.doNotRunTrigger('Opportunity_Event__e')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        /** UPDATE */
        .bindExtended(Triggers.Evnt.afterinsert, new OpportunityTriggerHandler.CPQQuoteGeneration())
        //Calls the run method on each class
        .execute();
    }
}