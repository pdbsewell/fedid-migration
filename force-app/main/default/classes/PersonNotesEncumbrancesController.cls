/*
 * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group			Retention (Monash Connect) - BabyShark
 * @description		RW2-371 Handler for component to show person notes, encumbrances, and callista notes.
 * @revision		RW2-427 Refactor VisualEditor into ContactDataSourceController and integration of "View Study Statement".
 * @revision		RW2-470 Support for the Contact Object itself. See ContactDataSourceController.
 * @revision		SA-6 Support for private cases.
 * @revision		SA-2 Support for private cases - Complaint ERT.
 * @revision		SA-255 Support for open cases.
 * @revision		SA-293 Exclude expired person notes.
 * @revision        SA-1454 Decommission embedded support tiles view for AP.
 * @revision        MCT-341 Add Last Modified Field for Private Cases.
 * @revision - 21-MAR-2024 - EPCP-3327 Control access to Open and Private Case button
 */

public with sharing class PersonNotesEncumbrancesController {

    @AuraEnabled
    public static String getPersonNotesAndEncumbrances(Id recordId, String contactField, Boolean queryCallista) {
        try {
            // Get ContactId from dynamic references.
            String currentObjectName = recordId.getSObjectType().getDescribe().getName();

            SObject currentObject = Database.query('SELECT ' + contactField + ' FROM ' + currentObjectName + ' WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1');

            if(currentObject == null || currentObject.get(contactField) == null) {
                return null;
            }

            String contactId = (String)currentObject.get(contactField);

            // Load person notes and encumbrances.
            Contact c = [SELECT
                         Id,
                         Age__c,
                         toLabel(Citizenship_Code__c),
                         Citizenship_Type_Description__c,
                         ESOS__c,
                         FirstName,
                         Name,
                         Person_Id__c,
                         Preferred_Name__c,
                         toLabel(Pronouns_V2__c),
                         (
                             SELECT
                             Id,
                             Notes__c
                             FROM Person_Notes__r
                             WHERE
                             Expires__c >= :System.today() OR Expires__c = NULL
                         ),
                         (
                             SELECT
                             Id,
                             enc_category__c,
                             enc_comments__c,
                             enc_description__c
                             FROM Encumbrance__r
                             WHERE
                             (enc_expiry_date__c >= :System.today() OR enc_expiry_date__c = NULL) and Deleted_In_Source__c = false
                         )
                         FROM Contact
                         WHERE Id = :contactId
                         LIMIT 1];

            // Prepare response structure.
            Data d = new Data();
            d.contactRecord = c;
            d.callistaNotes = new List<String>();
            CasesController cc = new CasesController();
            d.openCases = cc.getOpenCases(contactId);
            d.privateCases = cc.getPrivateCases(contactId);
            d.viewStudyStatementURL = URLs__c.getOrgDefaults().View_Study_Statement__c + c.Person_Id__c;

            if(c.Person_Id__c == null) {
                d.callistaNotes.add('Not checking for notes in Callista as there is no Person Id.');
            }

            if(queryCallista && c.Person_Id__c != null) {
                // Query Callista for person notes.
                HttpResponse response;
                if(Test.isRunningTest()) {
                    response = SMSServices.mockPersonNotesResponse2();
                } else {
                    response = SMSServices.invokeMIXAPICallout(c.Person_Id__c);
                }
                MIXAPI_StudentPersonNote notesResult = new MIXAPI_StudentPersonNote();
                notesResult.notes = new List<MIXAPI_StudentPersonNote.cls_notes>();

                Boolean hasPersonNote = false;

                if(response?.getStatusCode() == 200) {
                    notesResult = (MIXAPI_StudentPersonNote) System.JSON.deserialize(response.getBody(), MIXAPI_StudentPersonNote.class);
                } else {
                    d.callistaNotes.add('Error checking notes from Callista.');
                }

                for(MIXAPI_StudentPersonNote.cls_notes pNote: notesResult.notes) {
                    if(pNote.noteType == 'AUTHINFO' || pNote.noteType == 'SECRTY_CHK') {
                        d.callistaNotes.add(pNote.text);
                        hasPersonNote = true;
                    }
                }

                if((notesResult.notes.isEmpty() && response?.getStatusCode() == 200) || (!notesResult.notes.isEmpty() && !hasPersonNote)) {
                    d.callistaNotes.add('No notes found in Callista.');
                }
            }

            return JSON.serialize(d);
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }

    /**
    * @description Control access of the Open Cases and Private Cases button
    * @author Mac Domingo 
    * @return Boolean 
    **/
    @AuraEnabled
    public static Boolean hasCustomPermission() {        
        return [SELECT Id FROM PermissionSet WHERE Name = 'PrivateCase' AND Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()) LIMIT 1].size() > 0;
    }

    public class Data {
        public Contact contactRecord;
        public List<String> callistaNotes;
        public List<Case> openCases;
        public List<Case> privateCases;
        public String viewStudyStatementURL;
    }

    private without sharing class CasesController {
        private List<Case> getOpenCases(Id contactId) {
            try {
                List<Case> cases = [SELECT
                                    Id,
                                    CaseNumber,
                                    Case_Owner_String__c,
                                    CreatedDate,
                                    Enquiry_Type__c,
                                    RecordType.Name,
                                    Status,
                                    Subject
                            FROM Case
                            WHERE
                            ContactId = :contactId
                            AND
                            IsClosed = false
                            ORDER BY CreatedDate DESC
                            ];

                return cases;
            } catch(Exception e) {
                throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
            }
        }
        
        private List<Case> getPrivateCases(Id contactId) {
            try {
                Id monConPrivateCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MonCon_Private').getRecordTypeId();
                Id specialConsiderationCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Special_Consideration').getRecordTypeId();
                Id complaintCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Complaint').getRecordTypeId();
                Id internationalSECaseRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SS_InternationalStudentEngagement').getRecordTypeId();

                List<Case> cases = [SELECT
                                    Id,
                                    Private_Enquiry__c,
                                    CaseNumber,
                                    Case_Owner_String__c,
                                    ClosedDate,
                                    CreatedDate,
                                    LastModifiedDate,
                                    Enquiry_Type__c,
                                    RecordType.Name,
                                    Status,
                                    Subject
                            FROM Case
                            WHERE
                            ContactId = :contactId
                            AND
                            (
                                RecordTypeId = :monConPrivateCaseRecordTypeId OR RecordTypeId = :specialConsiderationCaseRecordTypeId 
                                    OR RecordTypeId =: complaintCaseRecordTypeId OR RecordTypeId =: internationalSECaseRTypeId
                                    OR Private_Enquiry__c = true
                            )
                            ORDER BY CreatedDate DESC
                            ];

                return cases;
            } catch(Exception e) {
                throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
            }
        }
    }
}