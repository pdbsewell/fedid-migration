/**
 * @File Name          : QuoteEventTrigger.trigger
 * @Description        : 
 * @Author             : David Browaeys
 * @Group              : 
 * @Last Modified By   : Mathew Jose
 * @Last Modified On   : 11/11/2019, 11:11:11 AM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    11/11/2019        Mathew Jose            Initial Version
**/
trigger QuoteEventTrigger on Quote_Event__e (after insert) {
    if (TriggerCommon.doNotRunTrigger('SBQQ__Quote__c') || TriggerCommon.doNotRunTrigger('Quote_Event__e')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        /** UPDATE */
        .bindExtended(Triggers.Evnt.afterinsert, new QuoteTriggerHandler.ClauseGeneration())
        //Calls the run method on each class
        .execute();
    }
}