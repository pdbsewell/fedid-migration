trigger OffersEnvelopSignedEventTrigger on Offers_Envelop_Signed_Event__e (after insert) {
    if (TriggerCommon.doNotRunTrigger('OffersEnvelopSignedEventTrigger ') || TriggerCommon.doNotRunTrigger('Offers_Envelop_Signed_Event__e')) {
        return;
    } else {
        //Initialize Triggers
        System.debug('%%% OffersEnvelopSignedEventTrigger ');
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        /** UPDATE */
        .bindExtended(Triggers.Evnt.afterinsert, new OffersEnvelopSignedEventTrigHandler())
        //Calls the run method on each class
        .execute();
    }
}