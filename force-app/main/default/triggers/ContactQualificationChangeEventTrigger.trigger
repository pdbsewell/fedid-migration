/**
 * @author          Ajitabh
 * @description     Trigger specific to Contact_Qualification__ChangeEvent sObject
 * @revision        
 */
trigger ContactQualificationChangeEventTrigger on Contact_Qualification__ChangeEvent (after insert) {
    if (TriggerCommon.doNotRunTrigger('Contact_Qualification__ChangeEvent')) {
        System.debug(LoggingLevel.DEBUG, '!!@@## TriggerCommon.doNotRunTrigger Contact: ' + Trigger.operationType.name());
        return;
    }
    new Triggers().bind(Triggers.Evnt.afterInsert, new ContactQualificationChangeEvent.enableAlumniFlagOnContact()).execute();
}