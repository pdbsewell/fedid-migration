trigger QuoteTrigger on SBQQ__Quote__c (before update, after update) {
    if (TriggerCommon.doNotRunTrigger('SBQQ__Quote__c')) {
            return;
        } else {
            //Initialize Triggers
            new Triggers()
            //Bind Classes that implement Triggers.Handler
            /** UPDATE */
            .bindExtended(Triggers.Evnt.afterupdate, new QuoteOfferSigningTriggerHandler())
            .bindExtended(Triggers.Evnt.afterupdate, new QuoteTriggerHandler.QuoteLineTransform())
            .bindExtended(Triggers.Evnt.beforeupdate, new QuoteTriggerHandler.QuoteStatusUpdates())
            .bindExtended(Triggers.Evnt.afterupdate, new QuoteTriggerHandler.OfferLogHandler())
            .bindExtended(Triggers.Evnt.afterupdate, new QuoteTriggerHandler.QuoteOpptySync())
            .bindExtended(Triggers.Evnt.beforeupdate, new QuoteTriggerHandler.GRScholarshipOfferResponseSync())
            .bindExtended(Triggers.Evnt.afterupdate, new QuoteTriggerHandler.GRScholarshipOfferResponseSync())
            //Calls the run method on each class
            .execute();
        }
}