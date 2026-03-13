/**
 * @author       Jitender Padda
 * @date         Jan.2025
 * @description  Service class for CRM Notes
 */
public with sharing class CRMNotesService {
    public static final String LOG_TAG = 'CRM Notes';

    /**
     * @description  Pushes Notes to Callista and stores ref Ids OR errors
     */
    public class SendNoteToCallista implements Queueable, Database.AllowsCallouts {
        List<CRM_Notes__c> crmNotesList;

        public SendNoteToCallista(List<CRM_Notes__c> crmNotesList) {
            this.crmNotesList = [
                SELECT
                    Id,
                    Type__c,
                    Text__c,
                    Contact__r.Person_Id__c,
                    Application_Course_Preference__r.Admission_Application_Number__c,
                    Application_Course_Preference__r.Course_Code__c,
                    Application_Course_Preference__r.Application_Sequence_Number__c
                FROM CRM_Notes__c
                WHERE Id IN :crmNotesList
            ];
        }

        public void execute(QueueableContext context) {
            try {
                for (CRM_Notes__c crmNote : crmNotesList) {
                    CallistaNotesService.Note noteBody = new CallistaNotesService.Note();

                    try {
                        crmNote.Callista_Error__c = null;

                        // Person Note
                        if (CallistaNotesService.PUSH_PERSON_NOTE_TYPES.contains(crmNote.Type__c)) {

                            // note details
                            noteBody.noteType = crmNote.Type__c;
                            noteBody.note = crmNote.Text__c;

                            // post & store ref Id
                            crmNote.Callista_Ref_Id__c = CallistaNotesService.postCallistaPersonNotes(
                                crmNote.Contact__r.Person_Id__c,
                                JSON.serialize(noteBody, true)
                            );
                        }
                        // ACAI Note
                        else if (CallistaNotesService.PUSH_ACAI_NOTE_TYPES.contains(crmNote.Type__c)) {

                            // note details
                            noteBody.type = 'acaiNote';
                            noteBody.noteType = crmNote.Type__c;
                            noteBody.text = crmNote.Text__c;

                            // acp reference details
                            noteBody.admissionApplNumber = crmNote.Application_Course_Preference__r.Admission_Application_Number__c;
                            noteBody.courseCode = crmNote.Application_Course_Preference__r.Course_Code__c;
                            noteBody.sequenceNumber = crmNote.Application_Course_Preference__r.Application_Sequence_Number__c;
                            
                            // post & store ref Id
                            crmNote.Callista_Ref_Id__c = CallistaNotesService.postCallistaACAINotes(
                                crmNote.Contact__r.Person_Id__c,
                                JSON.serialize(noteBody, true)
                            );
                        }
                    } catch (CallistaNotesService.CallistaNotesException cne) {
                        crmNote.Callista_Error__c = cne.getMessage();
                    }
                }

                // bypass flows to allow updating Callista integration fields
                Bypass_Mute_Request__c bmr = Bypass_Mute_Request__c.getInstance();
                bmr.Bypass_All_Flows__c = true;
                upsert bmr;

                // prevent recursion
                TriggerCommon.disableTrigger('CRM_Notes__c');
                update crmNotesList;
                TriggerCommon.enableTrigger('CRM_Notes__c');

                bmr.Bypass_All_Flows__c = false;
                upsert bmr;
            } catch (Exception ex) {
                Nebula.Logger.error(ex.getMessage(), crmNotesList).addtag(CRMNotesService.LOG_TAG);
            } finally {
                Nebula.Logger.saveLog();
            }
        }
    }
}