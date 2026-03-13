trigger DocuSignRecipientStatusTrigger on dsfs__DocuSign_Recipient_Status__c (after insert, after update) {
    if (TriggerCommon.doNotRunTrigger('DocuSignRecipientStatusTrigger') || TriggerCommon.doNotRunTrigger('dsfs__DocuSign_Recipient_Status__c')) {
        return;
    } else {
        //Initialize Triggers
        new Triggers()
        //Bind Classes that implement Triggers.Handler
        /** UPDATE */
        .bindExtended(Triggers.Evnt.afterinsert, new OffersDocuSignRecStatusTriggerHand())
        .bindExtended(Triggers.Evnt.afterupdate, new OffersDocuSignRecStatusTriggerHand())
        //Calls the run method on each class
        .execute();
    }
}