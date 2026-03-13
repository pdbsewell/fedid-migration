trigger OffersRecipientSignedEventTrigger on Offers_Recipient_Signed_Event__e (after insert) {
    if (TriggerCommon.doNotRunTrigger('OffersRecipientSignedEventTrigger ') || TriggerCommon.doNotRunTrigger('Offers_Recipient_Signed_Event__e')) {
        return;
    } else {
        //Initialize Triggers
        System.debug('%%% OffersRecipientSignedEventTrigger ');
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        /** UPDATE */
        .bindExtended(Triggers.Evnt.afterinsert, new OffersRecipientSignedTriggerHandler())
        //Calls the run method on each class
        .execute();
    }
}