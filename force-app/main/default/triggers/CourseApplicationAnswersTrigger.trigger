trigger CourseApplicationAnswersTrigger on Course_Application_Answers__c (after insert) {
    if (TriggerCommon.doNotRunTrigger('Course_Application_Answers__c')) { return; }

        new Triggers()
        .bind(Triggers.Evnt.afterInsert, new CourseApplicationAnswersServices.addFieldLabels())
        .execute();
}