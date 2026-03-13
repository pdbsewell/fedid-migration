trigger DocuSignStatusTrigger on dsfs__DocuSign_Status__c (after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('DocuSignStatusTrigger') || TriggerCommon.doNotRunTrigger('dsfs__DocuSign_Status__c')) {
        return;
    } else {
        //Initialize Triggers
        System.debug('%%% DocuSignEnvelopSignedEventTrigger ');
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        /** UPDATE */
        .bindExtended(Triggers.Evnt.afterinsert, new OffersDocuSignStatusTriggerHandler())
        .bindExtended(Triggers.Evnt.afterupdate, new OffersDocuSignStatusTriggerHandler())
        //Calls the run method on each class
        .execute();
    }
}