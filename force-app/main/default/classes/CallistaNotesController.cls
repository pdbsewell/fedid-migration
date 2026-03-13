/**
 * @author       Jitender Padda
 * @date         Dec.2024
 * @description  Controller for Callista Notes lwc
 *               Fetches notes from Callista in real time
 *               -> Contact - Person Notes
 *               -> ACP - Person Notes + ACAI Notes
 */
public without sharing class CallistaNotesController {
    public class CallistaNotesDataException extends Exception {}

    /**
     * @description Data provider for Apex Related list lwc
     */
    public class CallistaNotesDataProvider implements ApexRelatedListController.DataProvider {
        String personId;
        List<CallistaNotesService.Note> allNotesResponse = new List<CallistaNotesService.Note>();

        /**
         * @description  Calls out to Callista for Person / ACAI Notes
         * @param        ref Contact or ACP Id
         * @return       List<ApexRelatedListController.Record>
         */
        public List<ApexRelatedListController.Record> getRecords(String ref) {
            try {
                Id refId = (Id) ref;
                if (refId.getSobjectType() == Contact.SObjectType) {
                    getNotesForContact(refId);
                }else if (refId.getSobjectType() == Application_Course_Preference__c.SObjectType){
                    getNotesForACP(refId, Application_Course_Preference__c.SObjectType);
                }else if (refId.getSobjectType() == Task.SObjectType){
                    getNotesForACP(refId, Task.SObjectType);
                }


                allNotesResponse.sort();

                return createDataProviderWrapper(ref);
            } 
            catch(CallistaNotesDataException ex){
                throw ex;
            }
            catch (Exception ex) {
                Nebula.Logger.error(ex.getMessage(), ex).addtag(CallistaNotesService.LOG_TAG);
                throw ex;
            } 
            finally {
                Nebula.Logger.saveLog();
            }
        }

        private void getNotesForContact(Id conId) {
            personId = [SELECT Person_Id__c FROM Contact WHERE Id = :conId].Person_Id__c;
            validatePersonId(personId);

            // person notes
            CallistaNotesService.PersonNote personNotesResponse = CallistaNotesService.getCallistaPersonNotes(personId);

            allNotesResponse.addAll(personNotesResponse.notes);
        }

        private void getNotesForACP(Id recId, Schema.SObjectType objectType) {
        	Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
			String objectLabel = describeResult.getLabel();
            Task admissionsTask = null;
            if(objectLabel == 'Task'){
              	admissionsTask = new Task();
            	admissionsTask = [Select Application_Course_Preference__c, Application_Course_Preference__r.Applicant__r.Person_ID__c, 
                              Application_Course_Preference__r.Callista_Unique_Key_ADM__c
                              FROM Task
                              WHERE Id =: recId];
              
            }
            String acpId = '';
            if(admissionsTask != null && admissionsTask.Application_Course_Preference__c != null){
                acpId = admissionsTask.Application_Course_Preference__c;
                personId = admissionsTask.Application_Course_Preference__r.Applicant__r.Person_Id__c;

            }else{
                acpId = recId;
            }
            Application_Course_Preference__c acp = [
                SELECT Applicant__r.Person_Id__c, Callista_Unique_Key_ADM__c
                FROM Application_Course_Preference__c
                WHERE Id = :acpId
            ];
            if(admissionsTask == null){
            	personId = acp.Applicant__r.Person_Id__c;
            }
            validatePersonId(personId);

            // acai notes
            CallistaNotesService.ACAINote acaiNotesResponse = CallistaNotesService.getCallistaACAINotes(personId);
            // filter acai notes for ACP
            acaiNotesResponse = CallistaNotesService.filterACAINotesForACP(acaiNotesResponse, acp);

            // person notes
            CallistaNotesService.PersonNote personNotesResponse = CallistaNotesService.getCallistaPersonNotes(personId);

            allNotesResponse.addAll(acaiNotesResponse.acaiNotes);
            allNotesResponse.addAll(personNotesResponse.notes);
        }
        

        private void validatePersonId(String personId) {
            if (String.isBlank(personId)) {
                throw new CallistaNotesDataException('Callista Person Id not found');
            }
        }

        private List<ApexRelatedListController.Record> createDataProviderWrapper(String ref) {
            List<ApexRelatedListController.Record> notesList = new List<ApexRelatedListController.Record>();

            for (CallistaNotesService.Note pNote : allNotesResponse) {
                // filter only assessment relevant notes
                if (
                    CallistaNotesService.ASSESSMENT_PERSON_NOTE_TYPES.contains(pNote.noteType) ||
                    CallistaNotesService.ASSESSMENT_ACAI_NOTE_TYPES.contains(pNote.noteType)
                ) {
                    // filter notes pushed from CRM Notes
                    if (pNote.updateBy != 'STUDENTFIRST_CONNECT') {
                        List<ApexRelatedListController.RecordValue> recordValues = new List<ApexRelatedListController.RecordValue>{
                            new ApexRelatedListController.RecordValue('Text', pNote.text?.replace('\n', '</br>')),
                            new ApexRelatedListController.RecordValue(
                                'Last Modified By',
                                '<p style="color: var(--lwc-brandTextLink">' + pNote.updateBy + '</a>'
                            ),
                            new ApexRelatedListController.RecordValue(
                                'Last Modified Date',
                                String.valueOf(DateTime.valueOf(pNote.updateOn.replace('T', ' ')).format())
                            )
                        };

                        notesList.add(
                            new ApexRelatedListController.Record(
                                fflib_IDGenerator.generate(Note.SObjectType),
                                pNote.noteType,
                                recordValues
                            )
                        );
                    }
                }
            }

            if (notesList.size() == 0) {
                throw new CallistaNotesDataException('No previous assessment notes available');
            }

            return notesList;
        }
    }
}