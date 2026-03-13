trigger AOProgramFormMapTrigger on AO_Program_Form_Map__c (after insert) {

    if (TriggerCommon.doNotRunTrigger('AO_Program_Applicant__c')) { return; }

    new Triggers()
        .bindExtended(Triggers.Evnt.afterInsert, new AOProgramFormMapTriggerHandler.CreateEncyptedText())
    .execute();
}