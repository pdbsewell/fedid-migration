trigger AOQuestionLibraryTrigger on AO_Question_Library__c (before insert, before update) {
    if (TriggerCommon.doNotRunTrigger('AO_Question_Library__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.beforeInsert, new AOQuestionLibraryHandler.ValidateQuestionDuplication())
        .bindExtended(Triggers.Evnt.beforeUpdate, new AOQuestionLibraryHandler.ValidateQuestionDuplication())
    .execute();
}