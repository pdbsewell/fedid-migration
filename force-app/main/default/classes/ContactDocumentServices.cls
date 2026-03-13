/**
 * @author      Kristian Vegerano
 * @description Class that handles contact document interaction of front-end components
 * @group       Services
 * @revision    26/08/2019 - Kristian Vegerano - Created
 * 19/07/2023 Ken McGuire enhanced security around deletion of documents
 */
public with sharing class ContactDocumentServices {
    
    public static String FIELD_CONTACT_ID = 'contactId';
    public static String FIELD_USER = 'user';
    public static String FIELD_CONTACT_DOCUMENTS = 'contactDocuments';
    public static String FIELD_DOCUMENT_TYPES = 'documentTypes';
    public static String FIELD_MAP_DOCUMENT_TYPES = 'documentMapOfTypes';
    public static String FIELD_APPLICATION_CHECKLIST = 'applicationChecklist';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';


    public static String FIELD_DELETE_STATUS = 'deleteStatus';
    public static String FIELD_SAVE_STATUS = 'saveStatus';
    public static String FIELD_MESSAGE = 'message';
    public static String SUCCESS = 'success';
    public static String FAILED = 'failed';

    public static String CHECKLIST_STATUS_REQUESTED = 'Requested';
    public static String CHECKLIST_STATUS_SUBMITTED = 'Submitted';
    public static String CHECKLIST_STATUS_INSUFFICIENT = 'Insufficient';
    public static String CHECKLIST_STATUS_NOT_REQUIRED = 'Not Required';


    @AuraEnabled
    public static Map<String, Object> saveFileAndContactDocumentChecklist(Id fileId, Id contactId, Id appId, String docTypeValue, String docSubTypeValue, String docComments,
                                                                          Id checklistId, Id checklistQualId, Id checklistWexId, Boolean internalOnly) {
                                
        Map<String, Object> mapResult = new Map<String, Object>();

        if(fileId != null && contactId != null && appId != null) {

            // get the file to update the Title
            List<ContentDocument> listFiles = [SELECT Id, Title, FileExtension FROM ContentDocument WHERE Id = :fileId];
            
            if(listFiles.size() < 1)
            {
                // EARLY OUT
                mapResult.put(FIELD_SAVE_STATUS, FAILED);
                mapResult.put(FIELD_MESSAGE, 'File not found for Id = ' + fileId);
                return mapResult;
            }
			
            for(ContentDocument cdVar: listFiles)
            {
				if(cdVar.Title.length() + cdVar.FileExtension.length() > 100)
                {
                    mapResult.put(FIELD_SAVE_STATUS, FAILED);
                    mapResult.put(FIELD_MESSAGE, 'Filename is too long for Id = ' + cdVar.Title.length());
                    return mapResult;
                }    
            }
            
            ContentDocument file = listFiles[0];
            String fileNameNoPrefix = file.Title;
            String docTypeLabel = getDocTypeLabel(docTypeValue);
            file.Title = docTypeLabel + '_' + file.Title;
            update file;
            
            // create contact document
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = contactId;
            conDoc.Document_Type__c = docTypeValue;
            conDoc.Type__c = docSubTypeValue;
            conDoc.Comments__c = docComments;
            conDoc.Filename__c = fileNameNoPrefix + '.' + file.FileExtension;
            conDoc.Application__c = appId;
            conDoc.Internal_Only__c = internalOnly;

            Application__c applicationRecordItem = [SELECT Id, Status__c FROM Application__c WHERE Id = :appId LIMIT 1];
            if(applicationRecordItem.Status__c == 'Submitted' || applicationRecordItem.Status__c == 'Sent for Submission'){
                conDoc.Submitted__c = true;
                conDoc.Post_Submission__c = true;
            }

            if(!string.isBlank(checklistId)) conDoc.Document_Checklist__c = checklistId;
            if(!string.isblank(checklistQualId)) conDoc.Contact_Qualification__c  = checklistQualId;
            if(!string.isblank(checklistWexId)) conDoc.Work_Experience__c = checklistWexId;
            insert conDoc;

            List<ContentDocumentLink> listLinks = new List<ContentDocumentLink>();
            
            // create checklist link
            if(!string.isBlank(checklistId)){
                ContentDocumentLink checklistLink = new ContentDocumentLink();
                checklistLink.ContentDocumentId = fileId;
                checklistLink.LinkedEntityId = checklistId;
                checklistLink.ShareType = 'I';
                checklistLink.Visibility = 'AllUsers';
                listLinks.add(checklistLink);
                
                Document_Checklist__c[] Checklist = [Select Id, Status__c from Document_Checklist__c
                                                         where Id = :checklistId];
                
                if (Checklist.size() > 0){
                    if(!internalOnly){
                        if (Checklist[0].Status__c == CHECKLIST_STATUS_REQUESTED || Checklist[0].Status__c == CHECKLIST_STATUS_INSUFFICIENT){
                            Checklist[0].Status__c = CHECKLIST_STATUS_SUBMITTED;

                            try{
                                update Checklist;
                            }catch(Exception e){
                                ExLog.add('Apex Class', 'ContactDocumentServices', 'saveFileAndContactDocumentChecklist', e.getMessage());
                                return null;
                            }

                        }
                    }
                }
                
            }

            // create Qualification link
            if(!string.isBlank(checklistQualId)){
                ContentDocumentLink qualLink = new ContentDocumentLink();
                qualLink.ContentDocumentId = fileId;
                qualLink.LinkedEntityId = checklistQualId;
                qualLink.ShareType = 'I';
                qualLink.Visibility = 'AllUsers';
                listLinks.add(qualLink);
            }


            // create CD link
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.ContentDocumentId = fileId;
            cdLink.LinkedEntityId = conDoc.Id;
            cdLink.ShareType = 'I';
            cdLink.Visibility = 'AllUsers';
            listLinks.add(cdLink);

            // create app-link
            ContentDocumentLink appLink = new ContentDocumentLink();
            appLink.ContentDocumentId = fileId;
            appLink.LinkedEntityId = appId;
            appLink.ShareType = 'I';
            appLink.Visibility = 'AllUsers';
            listLinks.add(appLink);

            try{
                insert listLinks;
            }catch(Exception e ){
                ExLog.add('Apex Class', 'ContactDocumentServices', 'saveFileAndContactDocumentChecklist', e.getMessage());
                return null;
            }           

            mapResult.put(FIELD_SAVE_STATUS, SUCCESS);
            String sMessage = '';
            sMessage += 'contact document ' + conDoc.Id;
            sMessage += ', cdlink ' + cdLink.Id;
            sMessage += ', appLink ' + appLink.Id;
            mapResult.put(FIELD_MESSAGE, sMessage);
        }
        else
        {
            mapResult.put(FIELD_SAVE_STATUS, FAILED);
            mapResult.put(FIELD_MESSAGE, 'Error in arguments: fileId = ' + fileId + ', contactId = '+contactId + ', appId = ' + appId);
        }


        // retrieve the latest list of documents again
        List<Contact_Document__c> listDocs = GetContactDocuments(appId);
        mapResult.put(FIELD_CONTACT_DOCUMENTS, listDocs);

        return mapResult;
    }

    @AuraEnabled
    public static Map<String, Object> removeContactDocumentChecklist(Id conDocId, Id appId) {
        Map<String, Object> mapResult = new Map<String, Object>();
        mapResult =  new DeleteDocumentWrapper().removeContactDocCheckList(conDocId,appId);
        if( mapResult.get(FIELD_DELETE_STATUS) == SUCCESS)
        {
            // retrieve the latest list of documents again
            List<Contact_Document__c> listDocs = GetContactDocuments(appId);
            mapResult.put(FIELD_CONTACT_DOCUMENTS, listDocs);
        }
        return mapResult;
    }

    @TestVisible
    private static String getDocTypeLabel(String docTypeValue)
    {
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String,String>> options = new List<Map<String,String>> ();
        for( Schema.PicklistEntry f : ple)
        {
            if(f.getValue() == docTypeValue)
            {
                return f.getLabel();
            }
        }
        return '';
    }

    private static Contact_Document__c[] GetContactDocuments(Id appId) {

        List<Application__c> listApps = [
                SELECT a.Id, a.Applicant__c
                FROM Application__c a
                WHERE a.Id = :appId
        ];

        if(listApps.size() > 0) {
            Application__c app = listApps[0];
            Contact_Document__c[] documents = [
                    SELECT d.Id, toLabel(d.Document_Type__c), d.LastModifiedDate, d.Contact__c, d.Type__c, d.Comments__c, d.Filename__c, d.Submitted__c
                    FROM Contact_Document__c d
                    WHERE d.Contact__c = :app.Applicant__c
                    ORDER BY d.Submitted__c DESC
            ];

            return documents;
        }
        return new List<Contact_Document__c>();
    }


    public without sharing class DeleteDocumentWrapper {


        public Map<String, Object> removeContactDocCheckList(Id conDocId, Id appId )
        {
            Map<String, Object> mapResults = new Map<String, Object> ();
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId, Profile.Name FROM User WHERE Id = :currentUserId];
            Boolean isCommunityUser = currentUser.Profile.Name == 'Customer Community General User';
            //Remove Contact Document First
            List<Contact_Document__c> docs = isCommunityUser ? getContactDocuments(conDocId,appId,currentUser.contactId) : getContactDocuments(conDocId,appId); 

            if (docs.size() == 0) {
                // EARLY ERROR OUT
                mapResults.put(FIELD_DELETE_STATUS, FAILED);
                mapResults.put(FIELD_MESSAGE, 'No Contact Document found for Id ' + conDocId);
                return mapResults;
            }

            //Get all of the checklist records Associated with Contact Documents.
            
            List<ID> checklistID = new List<ID>();
            for (Contact_Document__c cid : docs)
                checklistID.add(cid.Document_Checklist__c);
                    
            //If only 1 checklist record is associated with the Contact Documents, then revert the status of the checklist to Requested.
            List<Document_Checklist__c> updatedChecklist = new List<Document_Checklist__c>();
            if(checklistID.size() > 0) {
                Document_Checklist__c[] checklist = [
                        SELECT Id, Status__c,
                        (Select Id, Submitted__c from Contact_Documents__r WHERE Internal_Only__c = false)
                        FROM Document_Checklist__c ac
                        WHERE ac.Id in :checklistID
                        ORDER BY Unique_ID__c DESC
                ];
                System.debug('### Remove Contact Document - Checklist : '+ checklist);
                for (Document_Checklist__c acl : checklist){
                    if (acl.Contact_Documents__r.size() == 1){
                        if(acl.Status__c != CHECKLIST_STATUS_NOT_REQUIRED){
                            acl.Status__c = CHECKLIST_STATUS_REQUESTED;
                            updatedChecklist.add(acl);    
                        }                
                    }
                }
            }
            
        //Get all of the files related to this Contact Document
            List<ContentDocumentLink> links = [
                    SELECT ContentDocumentId, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :docs[0].Id
            ];

            try {
                List<ContentDocument> contentDoc = null;
                set<ID> contentId = new set<ID>();
                for (ContentDocumentLink l : links) {
                contentId.add(l.ContentDocumentId);     
                }
                contentDoc = [SELECT Id FROM ContentDocument WHERE Id IN: contentId];
                if (contentDoc.size() > 0) {
                        delete contentDoc;
                }
                if (updatedChecklist.size() > 0) {
                        update updatedChecklist;
                }
                delete docs[0];            

                mapResults.put(FIELD_DELETE_STATUS, SUCCESS);

            } catch (Exception e) {
                ExLog.add('FileUploadController', 'Contact_Document__c', 'RemoveDocument', e.getMessage());
                mapResults.put(FIELD_DELETE_STATUS, FAILED);
                mapResults.put(FIELD_MESSAGE, 'Exception ' + e.getMessage());
            }
        return mapResults;
        }

        /**
         * Author  Ken McGuire
         * Date 24/7/2023
        Retrieves a list of Contact_Documents__c records based on the provided parameters.
        @param conDocId (Id) The unique identifier of the Contact_Document__c record to retrieve.
        @param appId (Id) The unique identifier of the Application__c associated with the Contact_Document__c records.
        @return List<Contact_Document__c> A list of Contact_Document__c records containing the single record that 
        matches the provided parameters. Returns an empty list if no matching records are found.
        */

        private List<Contact_Document__c> getContactDocuments(Id conDocId, Id appId) {
            return [
                SELECT Id, Document_Checklist__c
                FROM Contact_Document__c
                WHERE Id = :conDocId
                AND  Application__c = :appId
                LIMIT 1
                ];
        }

        /**
         * Author  Ken McGuire
         * Date 24/7/2023
        Retrieves a list of Contact_Documents__c records based on the provided parameters.
        @param conDocId (Id) The unique identifier of the Contact_Document__c record to retrieve.
        @param appId (Id) The unique identifier of the Application__c associated with the Contact_Document__c records.
        @param conId (Id) The unique identifier of the Contact__c associated with the Contact_Document__c records.
        @return List<Contact_Document__c> A list of Contact_Document__c records containing the single record that 
        matches the provided parameters. Returns an empty list if no matching records are found.
        */

        private List<Contact_Document__c> getContactDocuments(Id conDocId, Id appId, Id conId) {
            return [
                SELECT Id, Document_Checklist__c
                FROM Contact_Document__c
                WHERE  Id = :conDocId
                AND  Application__c = :appId
                AND  Contact__c = :conId
                LIMIT 1
                ];
        }
    }
}