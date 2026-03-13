/**
 * @description Handles all process from contactDocTaggingManager.html (lwc)
 * @revisions    created - J.Mapanao - 28/07/2019
 * 08/10/2024 Kai-Fan Hsieh - DANO-230 - Added overload to saveFileAndContactDocumentChecklist to include document owner mismatch
 */
public with sharing class ContactDocumentManager {

    public static final String RESULT_KEY_FILENAME = 'FILENAME';
    public static final String RESULT_KEY_UPLOADEDDATE = 'UPLOADEDDATE';
    public static final String RESULT_KEY_CURRENTCHECKLISTITEM = 'CURRENTCHECKLISTITEM';
    public static final String RESULT_KEY_CHECKLISTITEM = 'CHECKLISTITEM';
    public static final String RESULT_KEY_CURRENTDOCUMENTTYPE = 'CURRENTDOCUMENTTYPE';
    public static final String RESULT_KEY_DOCTYPECHECKLISTITEMMAP = 'DOCTYPECHECKLISTITEMMAP';
    public static final String RESULT_KEY_CURRENTDOCASSESSMENTSTATUS = 'CURRENTDOCASSESSMENTSTATUS';
    public static final String RESULT_KEY_DOCASSESSMENTSTATUSOPTIONS = 'DOCASSESSMENTSTATUSOPTIONS';
    public static final String RESULT_KEY_DOCASSESSMENTSTATUSHELPTEXT = 'DOCASSESSMENTSTATUSHELPTEXT';

    public static final String RESULT_KEY_ERROR = 'ERROR';
    public static final String RESULT_KEY_SUCCESS = 'SUCCESS';

    public static String CHECKLIST_STATUS_REQUESTED = 'Requested';
    public static String CHECKLIST_STATUS_SUBMITTED = 'Submitted';
    public static String CHECKLIST_STATUS_INSUFFICIENT = 'Insufficient';
    public static String CHECKLIST_STATUS_NOT_REQUIRED = 'Not Required';

    public static String CHECKLIST_OTHER_VALUE = 'Other';
    public static String CHECKLIST_OTHER_LABEL = 'Other Documents';

    /**
     * @description init logic, getting all required information for contactDocTaggingManager.html (lwc)
     * @param       String contactDocumentId
     
    @AuraEnabled(cacheable=true)
    public static Object retrieveData(String contactDocumentId) {
        Object result;
        try {
            Map<String,Object> data = new Map<String,Object>();
            // Get contact document details
            List<Contact_Document__c> contactDocuments = getContactDocumentDetails(contactDocumentId);
            Contact_Document__c contactDocument = contactDocuments.get(0);
            
            // Get Help Text for Document Assessment Status field
            String documentAssessmentStatusHelpText = Contact_Document__c.Document_Assessment_Status__c.getDescribe().getInlineHelpText();
            data.put(RESULT_KEY_DOCASSESSMENTSTATUSHELPTEXT,documentAssessmentStatusHelpText);

            // Get all checklist items related to application
            List<Document_Checklist__c> applicationChecklists = getApplicationChecklist(contactDocument.Application__c);

            // Create File Name
            List<ContentDocumentLink> contentDocumentLinks = getContentDocumentLinks(getIds(contactDocuments));
            List<ContentDocument> contentDocuments = getContentDocuments(getIds(contentDocumentLinks));
            data.put(RESULT_KEY_FILENAME,contactDocument.Filename__c);
            data.put(RESULT_KEY_UPLOADEDDATE,contactDocument.LastModifiedDate);
            
            // Get current document assessment status
            Map<String,String> currentDocumentAssessmentStatus = getCurrentDocumentAssessmentStatus(contactDocument);
            data.put(RESULT_KEY_CURRENTDOCASSESSMENTSTATUS,currentDocumentAssessmentStatus);
            
            // Create document assessment status options
            Map<String,String> documentAssessmentStatusMap = getDocumentAssessmentStatusFieldMapping();
            data.put(RESULT_KEY_DOCASSESSMENTSTATUSOPTIONS,documentAssessmentStatusMap);
            
            // Get current checklist
            Map<String,String> currentChecklist = new Map<String,String>();
            currentChecklist = getCurrentApplicationChecklist(contactDocument);
            data.put(RESULT_KEY_CURRENTCHECKLISTITEM,currentChecklist);

            // Create checklist item picklist options
            Map<String,Object> checklistItemOptions = new Map<String,Object>();
            Map<String,String> checklistItemMap = createChecklistItemMap(applicationChecklists);
            checklistItemOptions.put(RESULT_KEY_CHECKLISTITEM,checklistItemMap);
            data.put(RESULT_KEY_CHECKLISTITEM,checklistItemMap);

            // Get current document type
            Map<String,String> currentDocumentType = new Map<String,String>();
            currentDocumentType = getCurrentDocumentType(contactDocument);
            data.put(RESULT_KEY_CURRENTDOCUMENTTYPE,currentDocumentType);

            // Create document type options
            Map<String,Object> documentTypeOptions = new Map<String,Object>();
            Map<String,Map<String,String>> documentTypeChecklistItemMap = createDocumentTypeChecklistItemMap(applicationChecklists);
            documentTypeOptions.put(RESULT_KEY_DOCTYPECHECKLISTITEMMAP,documentTypeChecklistItemMap);
            data.put(RESULT_KEY_DOCTYPECHECKLISTITEMMAP,documentTypeChecklistItemMap);

            result = data;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, '###' + ex.getMessage());
            Map<String,Object> errorMap = new Map<String,Object>();
            errorMap.put(RESULT_KEY_ERROR, 'Something went wrong getting information. Please contact your administrator.');
            result = errorMap;
        }
        return result;
    }*/
    
    /**
     * @description init logic, getting all required information for contactDocTaggingManager.html (lwc)
     * @param       String contactDocumentId
     */
    @AuraEnabled(cacheable=true)
    public static Object retrieveDataDocumentChecklist(String contactDocumentId) {
        Object result;
        try {
            Map<String,Object> data = new Map<String,Object>();
            // Get contact document details
            List<Contact_Document__c> contactDocuments = getContactDocumentDetails(contactDocumentId);
            Contact_Document__c contactDocument = contactDocuments.get(0);
            data.put('IsInternalOnly', contactDocument.Internal_Only__c);
            
            // Get Help Text for Document Assessment Status field
            String documentAssessmentStatusHelpText = Contact_Document__c.Document_Assessment_Status__c.getDescribe().getInlineHelpText();
            data.put(RESULT_KEY_DOCASSESSMENTSTATUSHELPTEXT,documentAssessmentStatusHelpText);

            // Get all checklist items related to application
            List<Document_Checklist__c> applicationChecklists = getDocumentChecklist(contactDocument.Application__c);

            // Create File Name
            data.put(RESULT_KEY_FILENAME,contactDocument.Filename__c);
            data.put(RESULT_KEY_UPLOADEDDATE,contactDocument.LastModifiedDate);
            
            // Get current document assessment status
            Map<String,String> currentDocumentAssessmentStatus = getCurrentDocumentAssessmentStatus(contactDocument);
            data.put(RESULT_KEY_CURRENTDOCASSESSMENTSTATUS,currentDocumentAssessmentStatus);
            
            // Create document assessment status options
            Map<String,String> documentAssessmentStatusMap = getDocumentAssessmentStatusFieldMapping();
            data.put(RESULT_KEY_DOCASSESSMENTSTATUSOPTIONS,documentAssessmentStatusMap);
            
            // Get current checklist
            Map<String,String> currentChecklist = new Map<String,String>();
            currentChecklist = getCurrentApplicationChecklist(contactDocument);
            data.put(RESULT_KEY_CURRENTCHECKLISTITEM,currentChecklist);

            // Create checklist item picklist options
            Map<String,Object> checklistItemOptions = new Map<String,Object>();
            Map<String,String> checklistItemMap = createChecklistItemMap(applicationChecklists);
            checklistItemOptions.put(RESULT_KEY_CHECKLISTITEM,checklistItemMap);
            data.put(RESULT_KEY_CHECKLISTITEM,checklistItemMap);

            // Get current document type
            Map<String,String> currentDocumentType = new Map<String,String>();
            currentDocumentType = getCurrentDocumentType(contactDocument);
            data.put(RESULT_KEY_CURRENTDOCUMENTTYPE,currentDocumentType);

            // Create document type options
            Map<String,Object> documentTypeOptions = new Map<String,Object>();
            Map<String,Map<String,String>> documentTypeChecklistItemMap = createDocumentTypeChecklistItemMap(applicationChecklists);
            documentTypeOptions.put(RESULT_KEY_DOCTYPECHECKLISTITEMMAP,documentTypeChecklistItemMap);
            data.put(RESULT_KEY_DOCTYPECHECKLISTITEMMAP,documentTypeChecklistItemMap);

            result = data;
        } catch (Exception ex) {
            nebula.Logger.error(ex.getMessage(), ex);
            nebula.Logger.saveLog();
            Map<String,Object> errorMap = new Map<String,Object>();
            errorMap.put(RESULT_KEY_ERROR, 'Something went wrong getting information. Please contact your administrator.');
            result = errorMap;
        }
        return result;
    }

    private static List<Contact_Document__c> getContactDocumentDetails(String contactDocumentId) {
        return
        [
            SELECT  Id,
                    Application__c,
                    Document_Assessment_Status__c,
                    Document_Checklist__c,
                    Document_Checklist__r.Checklist_Requirement__c,
                    Document_Type__c,
                    Filename__c,
                    LastModifiedDate,
                    Internal_Only__c
            FROM    Contact_Document__c
            WHERE   Id =: contactDocumentId
        ];
    }
    
    private static List<Document_Checklist__c> getApplicationChecklist(String applicationId) {
        return
        [
            SELECT
                    Id,
                    Allowed_Document_Type__c,
                    Application__c,
                    Checklist_Requirement__c,
                    Task_Type__c
            FROM    Document_Checklist__c
            WHERE   Application__c =: applicationId
        ];
    }

    private static List<Document_Checklist__c> getDocumentChecklist(String applicationId) {
        return
        [
            SELECT
                    Id,
                    Allowed_Document_Type__c,
                    Application__c,
                    Checklist_Requirement__c,
                    Task_Type__c
            FROM    Document_Checklist__c
            WHERE   Application__c =: applicationId
        ];
    }
    
    private static List<Document_Checklist__c> getApplicationChecklist(Set<String> appChecklistItemIds) {
        return
        [
            SELECT
                    Id,
                    Allowed_Document_Type__c,
                    Application__c,
                    Checklist_Requirement__c,
                    Task_Type__c,
                    Status__c,
                    (SELECT Id, Name FROM Contact_Documents__r)
            FROM    Document_Checklist__c
            WHERE   Id =: appChecklistItemIds
        ];
    }

    private static List<Document_Checklist__c> getDocumentChecklist(Set<String> documentChecklistItemIds) {
        return
        [
            SELECT
                    Id,
                    Allowed_Document_Type__c,
                    Application__c,
                    Checklist_Requirement__c,
                    Type__c,
                    Task_Type__c,
                    Status__c,
                    (SELECT Id, Name FROM Contact_Documents__r WHERE Internal_Only__c = false)
            FROM    Document_Checklist__c
            WHERE   Id =: documentChecklistItemIds
        ];
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Set<String> contactDocumentIds) {
        return
        [
            SELECT
                    Id,
                    ContentDocumentId,
                    LinkedEntityId
            FROM    ContentDocumentLink
            WHERE   LinkedEntityId IN: contactDocumentIds
        ];
    }

    private static List<ContentDocument> getContentDocuments(Set<String> contentDocumentIds) {
        return
        [
            SELECT
                    Id,
                    Description,
                    FileExtension,
                    FileType,
                    Title,
                    LastModifiedDate
            FROM    ContentDocument
            WHERE   Id IN: contentDocumentIds
        ];
    }

    /**
     * @description Handles logic to create checklist item options
     * @param       List<Document_Checklist__c> applicationChecklists
     */
    private static Map<String,String> createChecklistItemMap(List<Document_Checklist__c> applicationChecklists) {
        Map<String,String> checklistItemMap = new Map<String,String>();
        for (Document_Checklist__c checklist : applicationChecklists) {
            checklistItemMap.put(checklist.Id,checklist.Checklist_Requirement__c);
        }
        checklistItemMap.put(CHECKLIST_OTHER_VALUE,CHECKLIST_OTHER_LABEL);
        return checklistItemMap;
    }
    
    /**
     * @description Handles logic to create document type options
     * @param       List<Document_Checklist__c> applicationChecklists
     */
    private static Map<String,Map<String,String>> createDocumentTypeChecklistItemMap(List<Document_Checklist__c> applicationChecklists) {
        Map<String,Map<String,String>> docTypeChecklistItemMap = new Map<String,Map<String,String>>();
        Map<String,String> contactDocumentTypeFieldMap = getContactDocumentTypeFieldMapping();
        for (Document_Checklist__c checklist : applicationChecklists) {
            List<String> allowedDocTypes = new List<String>();
            if (String.isNotBlank(checklist.Allowed_Document_Type__c)) {
                allowedDocTypes = checklist.Allowed_Document_Type__c.split(';');
            }
            Map<String,String> allowedDocTypesMap = new Map<String,String>();
            for (String adt : allowedDocTypes) {
                allowedDocTypesMap.put(adt, contactDocumentTypeFieldMap.get(adt));
            }
            docTypeChecklistItemMap.put(checklist.Id,allowedDocTypesMap);
        }
        

        return docTypeChecklistItemMap;
    }
    
    /**
     * @description Handles logic to get current application checklist from contact document
     * @param       Contact_Document__c contactDocument
     */
    private static Map<String,String> getCurrentApplicationChecklist(Contact_Document__c contactDocument) {
        Map<String,String> currentChecklistMap = new Map<String,String>();
        if (contactDocument.Document_Checklist__c != null) {
            currentChecklistMap.put(contactDocument.Document_Checklist__c,contactDocument.Document_Checklist__r.Checklist_Requirement__c);
        } else {
            currentChecklistMap.put(CHECKLIST_OTHER_VALUE,CHECKLIST_OTHER_LABEL);
        }
        return currentChecklistMap;
    }

    /**
     * @description Handles logic to get current document type from contact document
     * @param       Contact_Document__c contactDocument
     */
    private static Map<String,String> getCurrentDocumentType(Contact_Document__c contactDocument) {
        Map<String,String> currentDocumentTypeMap = new Map<String,String>();
        Map<String,String> contactDocumentTypeFieldMap = getContactDocumentTypeFieldMapping();
        if (String.isNotBlank(contactDocument.Document_Type__c)) {
            currentDocumentTypeMap.put(contactDocument.Document_Type__c,contactDocumentTypeFieldMap.get(contactDocument.Document_Type__c));
        }
        return currentDocumentTypeMap;
    }

    /**
     * @description Handles logic to get the current document assessment status
     * @param       Contact_Document__c contactDocument
     */
    private static Map<String,String> getCurrentDocumentAssessmentStatus(Contact_Document__c contactDocument) {
        Map<String,String> currentDocumentAssessmentStatusMap = new Map<String,String>();
        Map<String,String> documentAssessmentStatusFieldMap = getDocumentAssessmentStatusFieldMapping();
        if (String.isNotBlank(contactDocument.Document_Assessment_Status__c)) {
            currentDocumentAssessmentStatusMap.put(contactDocument.Document_Assessment_Status__c,documentAssessmentStatusFieldMap.get(contactDocument.Document_Assessment_Status__c));
        }
        return currentDocumentAssessmentStatusMap;
    }

    /**
     * @description Handles logic to create mapping of Contact_Document__c.Document_Type__c
     *              key = api value, value = label
     */
    private static Map<String,String> getContactDocumentTypeFieldMapping() {
        Map<String,String> contactDocumentTypeFieldMap = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple) {
            contactDocumentTypeFieldMap.put(f.getValue(),f.getLabel());
        }
        return contactDocumentTypeFieldMap;
    }

    /**
     * @description Handles logic to create mapping of Contact_Document__c.Document_Assessment_Status__c
     *              key = api value, value = label
     */
    private static Map<String,String> getDocumentAssessmentStatusFieldMapping() {
        Map<String,String> documentAssessmentStatusFieldMap = new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Assessment_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple) {
            documentAssessmentStatusFieldMap.put(f.getValue(),f.getLabel());
        }
        return documentAssessmentStatusFieldMap;
    }

    /**
     * @description Handles logic dynamic creation of Set<String> for Ids
     * @param       List<sObject> sObjects
     */
    private static Set<String> getIds(List<sObject> sObjects) {
        Set<String> ids = new Set<String>();
        for (sObject sObj : sObjects) {
            ids.add((String)sObj.get('Id'));
        }
        return ids;
    }

    /**
     * @description Handles logic for DML
     * @param       String contactDocumentId
     * @param       String newChecklistItem
     * @param       String newDocumentType
     
    @AuraEnabled
    public static Object saveDocument(String contactDocumentId, String newChecklistItem, String newDocumentType, String contentDocuId, String documentAssessmentStatus) {
        Object result;
        Map<String,String> resultMap = new Map<String,String>();
        Savepoint sp = Database.setSavepoint();
        try {

            // Query details of contact document
            List<Contact_Document__c> contactDocuments = getContactDocumentDetails(contactDocumentId);
            
            // Get and store the current application checklist and document type (consider as old value)
            String oldChecklistItem = contactDocuments.get(0).Document_Checklist__c;
            String oldDocumentType = contactDocuments.get(0).Document_Type__c;

            // Set the new application checklist and document type and update
            contactDocuments.get(0).Document_Checklist__c = (newChecklistItem != CHECKLIST_OTHER_VALUE) ? newChecklistItem : null;
            contactDocuments.get(0).Document_Type__c = newDocumentType;
            contactDocuments.get(0).Document_Assessment_Status__c = (String.isNotBlank(documentAssessmentStatus)) ? documentAssessmentStatus : null;
            update contactDocuments;

            // Get the latest status of the application checklist
            Set<String> appChecklistItemIds = new Set<String>();
            if (newChecklistItem != CHECKLIST_OTHER_VALUE) {
                appChecklistItemIds.add(newChecklistItem);
            }
            
            if (String.isNotBlank(oldChecklistItem)) {
                appChecklistItemIds.add(oldChecklistItem);
            }
            List<Document_Checklist__c> applicationChecklists = getApplicationChecklist(appChecklistItemIds);

            Map<Id,Document_Checklist__c> appCheckToUpdateMap = new Map<Id,Document_Checklist__c>();
            for (Document_Checklist__c appCheckItem : applicationChecklists) {
                if (appCheckItem.Id == oldChecklistItem) {
                    if (appCheckItem.Status__c == CHECKLIST_STATUS_SUBMITTED && appCheckItem.Contact_Documents__r.size() == 0) {
                        appCheckItem.Status__c = CHECKLIST_STATUS_REQUESTED;
                        appCheckToUpdateMap.put(appCheckItem.Id,appCheckItem);
                    }
                }

                if (newChecklistItem != CHECKLIST_OTHER_VALUE && appCheckItem.Id == newChecklistItem) {
                    if ((appCheckItem.Status__c == CHECKLIST_STATUS_REQUESTED || appCheckItem.Status__c == CHECKLIST_STATUS_INSUFFICIENT) && appCheckItem.Contact_Documents__r.size() > 0) {
                        appCheckItem.Status__c = CHECKLIST_STATUS_SUBMITTED;
                        appCheckToUpdateMap.put(appCheckItem.Id,appCheckItem);
                    }
                }
            }

            // Update application checklist
            if (appCheckToUpdateMap.size() > 0) {
                update appCheckToUpdateMap.values();
            }
            
            // Remove Content Document Link from previous application checklist if not blank
            if (String.isNotBlank(oldChecklistItem)) {
                List<ContentDocumentLink> conDocLinks = getContentDocumentLinks(new Set<String>{oldChecklistItem});
                if (!conDocLinks.isEmpty()) {
                    delete conDocLinks;
                }
            }
            
            if (newChecklistItem != CHECKLIST_OTHER_VALUE) {
                ContentDocumentLink conDocLinkToInsert = new ContentDocumentLink(
                    ContentDocumentId = contentDocuId,
                    LinkedEntityId = newChecklistItem,
                    ShareType = 'I',
                    Visibility = 'AllUsers'
                );
                insert conDocLinkToInsert;
            }
            
            resultMap.put(RESULT_KEY_SUCCESS,'Record successfully updated.');
            result = resultMap;
        } catch (Exception ex) {
            System.debug('### ERROR:' + ex.getMessage());
            resultMap.put(RESULT_KEY_ERROR,'Something went wrong. Please contact your administrator.' + ex.getMessage() + '--' + ex.getStackTraceString());
            result = resultMap;
            Database.rollback(sp);
            return result;
        }
        return result;
    }*/

    /**
     * @description Saves the document with the new checklist
     * @param contactDocumentId - The ID of the contact document
     * @param newChecklistItem - The new checklist item
     * @param newDocumentType - The new document type
     * @param contentDocuId - The ID of the content document
     * @param documentAssessmentStatus - The status of the document assessment
     * @param isInternalOnly - Whether the document is internal only
     * @return  The result of the save operation
     */
    @AuraEnabled
    public static Object saveDocumentDocumentChecklist(String contactDocumentId, String newChecklistItem,
        String newDocumentType, String contentDocuId, String documentAssessmentStatus, Boolean isInternalOnly) {
        return saveDocumentDocumentChecklist(contactDocumentId, newChecklistItem, newDocumentType, contentDocuId, documentAssessmentStatus, isInternalOnly, null);
    }

    /**
     * @description Saves the document with the new checklist and document owner mismatch field
     * @param contactDocumentId - The ID of the contact document
     * @param newChecklistItem - The new checklist item
     * @param newDocumentType - The new document type
     * @param contentDocuId - The ID of the content document
     * @param documentAssessmentStatus - The status of the document assessment
     * @param isInternalOnly - Whether the document is internal only
     * @param documentOwnerMismatch - Whether the document owner is mismatch
     * @return  The result of the save operation
     */
    @AuraEnabled
    public static Object saveDocumentDocumentChecklistWithDocumentOwnerMismatch(String contactDocumentId, String newChecklistItem,
        String newDocumentType, String contentDocuId, String documentAssessmentStatus, Boolean isInternalOnly, Boolean documentOwnerMismatch) {
        return saveDocumentDocumentChecklist(contactDocumentId, newChecklistItem, newDocumentType, contentDocuId, documentAssessmentStatus, isInternalOnly, documentOwnerMismatch);
    }

    private static Object saveDocumentDocumentChecklist(String contactDocumentId, String newChecklistItem, String newDocumentType,
        String contentDocuId, String documentAssessmentStatus, Boolean isInternalOnly, Boolean documentOwnerMismatch) {
        Object result;
        Map<String,String> resultMap = new Map<String,String>();
        Savepoint sp = Database.setSavepoint();
        try {

            // Query details of contact document
            List<Contact_Document__c> contactDocuments = getContactDocumentDetails(contactDocumentId);
            
            // Get and store the current application checklist and document type (consider as old value)
            String oldChecklistItem = contactDocuments.get(0).Document_Checklist__c;

            // Set the new application checklist and document type and update
            contactDocuments.get(0).Document_Checklist__c = (newChecklistItem != CHECKLIST_OTHER_VALUE) ? newChecklistItem : null;
            contactDocuments.get(0).Document_Type__c = newDocumentType;
            contactDocuments.get(0).Document_Assessment_Status__c = (String.isNotBlank(documentAssessmentStatus)) ? documentAssessmentStatus : null;

            contactDocuments.get(0).Internal_Only__c = isInternalOnly;
            if(documentOwnerMismatch != null) {
                contactDocuments.get(0).Document_Owner_Mismatch__c = documentOwnerMismatch;
            }
            update contactDocuments;

            // Get the latest status of the application checklist
            Set<String> appChecklistItemIds = new Set<String>();
            if (newChecklistItem != CHECKLIST_OTHER_VALUE) {
                appChecklistItemIds.add(newChecklistItem);
            }
            
            if (String.isNotBlank(oldChecklistItem)) {
                appChecklistItemIds.add(oldChecklistItem);
            }
            List<Document_Checklist__c> applicationChecklists = getDocumentChecklist(appChecklistItemIds);

            Map<Id,Document_Checklist__c> appCheckToUpdateMap = new Map<Id,Document_Checklist__c>();
            for (Document_Checklist__c appCheckItem : applicationChecklists) {
                if (appCheckItem.Id == oldChecklistItem) {
                    if (appCheckItem.Status__c == CHECKLIST_STATUS_SUBMITTED && appCheckItem.Contact_Documents__r.size() == 0) {
                        appCheckItem.Status__c = CHECKLIST_STATUS_REQUESTED;
                        appCheckToUpdateMap.put(appCheckItem.Id,appCheckItem);
                    }
                }

                if (newChecklistItem != CHECKLIST_OTHER_VALUE && appCheckItem.Id == newChecklistItem) {
                    if ((appCheckItem.Status__c == CHECKLIST_STATUS_REQUESTED || appCheckItem.Status__c == CHECKLIST_STATUS_INSUFFICIENT) && appCheckItem.Contact_Documents__r.size() > 0) {
                        appCheckItem.Status__c = CHECKLIST_STATUS_SUBMITTED;
                        appCheckToUpdateMap.put(appCheckItem.Id,appCheckItem);
                    }
                }
            }

            // Update application checklist
            if (appCheckToUpdateMap.size() > 0) {
                update appCheckToUpdateMap.values();
            }
            
            // Remove Content Document Link from previous application checklist if not blank
            if (String.isNotBlank(oldChecklistItem)) {
                //Only delete links of the checklist is changed
                if(newChecklistItem != oldChecklistItem){
                    List<ContentDocumentLink> conDocLinks = new List<ContentDocumentLink>();
                    //Query link for the checklist and the current content document
                    for(ContentDocumentLink loopLink : [SELECT Id, ContentDocumentId, LinkedEntityId
                                                        FROM ContentDocumentLink 
                                                        WHERE LinkedEntityId = :oldChecklistItem
                                                            AND ContentDocumentId = :contentDocuId]){
                        conDocLinks.add(loopLink);
                    }
                    //delete outdated link records
                    if (!conDocLinks.isEmpty()) {
                        delete conDocLinks;
                    }
                }
            }
            
            //Check if checklist is changed and not equal to OTHER
            if (newChecklistItem != oldChecklistItem && newChecklistItem != CHECKLIST_OTHER_VALUE) {
                ContentDocumentLink conDocLinkToInsert = new ContentDocumentLink(
                    ContentDocumentId = contentDocuId,
                    LinkedEntityId = newChecklistItem,
                    ShareType = 'I',
                    Visibility = 'AllUsers'
                );
                insert conDocLinkToInsert;
            }
            
            resultMap.put(RESULT_KEY_SUCCESS,'Record successfully updated.');
            result = resultMap;
        } catch (Exception ex) {
            nebula.Logger.error(ex.getMessage(), ex);
            nebula.Logger.saveLog();
            resultMap.put(RESULT_KEY_ERROR,'Something went wrong. Please contact your administrator.' + ex.getMessage() + '--' + ex.getStackTraceString());
            result = resultMap;
            Database.rollback(sp);
            return result;
        }
        return result;
    }
}