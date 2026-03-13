trigger OffersSignedDocumentAttachedTrigger on Offers_Signed_Document_Attached__e (after insert) {
    if (TriggerCommon.doNotRunTrigger('OffersSignedDocumentAttachedTrigger ') || TriggerCommon.doNotRunTrigger('Offers_Signed_Document_Attached__e ')) {
        return;
    } else {
        //Initialize Triggers
        System.debug('%%% OffersSignedDocumentAttachedTrigger ');
        System.debug(trigger.new);
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        .bindExtended(Triggers.Evnt.afterinsert, new OffersSignedDocAttachedTrigHandler())
        //Calls the run method on each class
        .execute();
    }
}