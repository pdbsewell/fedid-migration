/**
 * @author       Jitender Padda
 * @date         Jan.2025
 * @description  Handler class for CRM Notes trigger
 */
public without sharing class CRMNotesHandler {
    /**
     * @description  Pushes certain Note types to Callista
     */
    public class PushNoteToCallista extends TriggerAbstract {

        // insert
        public override void process(SObject record) {
            CRM_Notes__c crmNote = (CRM_Notes__c) record;

            if (CallistaNotesService.PUSH_PERSON_NOTE_TYPES.contains(crmNote.Type__c)
                || CallistaNotesService.PUSH_ACAI_NOTE_TYPES.contains(crmNote.Type__c)) {
                records.add(crmNote);
            }
        }

        // update - backup to fix failed records only
        public override void process(SObject record, SObject oldRec) {
            CRM_Notes__c crmNote = (CRM_Notes__c) record;

            if (CallistaNotesService.PUSH_PERSON_NOTE_TYPES.contains(crmNote.Type__c)
                || CallistaNotesService.PUSH_ACAI_NOTE_TYPES.contains(crmNote.Type__c)) {
                records.add(crmNote);
            }
        }

        public override void execute() {
            if (records.size() > 0) {
                System.enqueueJob(new CRMNotesService.SendNoteToCallista((List<CRM_Notes__c>) records));
            }
        }
    }
}