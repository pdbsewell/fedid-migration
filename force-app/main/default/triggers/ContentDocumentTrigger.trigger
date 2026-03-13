trigger ContentDocumentTrigger on ContentDocument (before delete) {
    if (TriggerCommon.doNotRunTrigger('ContentDocument')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeDelete, new ContentDocumentTriggerHandler.AOupdateSubmissionResponse())
    .execute();
}