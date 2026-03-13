/**
 * @File Name          : ContentDocumentLinkTrigger.trigger
 * @Description        : 
 * @Author             : Mathew Jose
 * @Group              : 
 * @Last Modified By   : Mathew Jose
 * @Last Modified On   : 12/12/2019, 9:30:38 AM
 * @Modification Log   : 
 * Ver       Date        Author      		    Modification
 * 1.0    12/12/2019   Mathew Jose            Initial Version
**/
trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    if (TriggerCommon.doNotRunTrigger('ContentDocumentLink')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        /** UPDATE */
        .bindExtended(Triggers.Evnt.afterinsert, new OffersCompletedDocumentHandler())
        .bindExtended(Triggers.Evnt.afterinsert, new ContentDocumentLinkTriggerHandler.OpportunityLinkGeneratorForQuoteFiles())
        //Calls the run method on each class
        .execute();
    }
}