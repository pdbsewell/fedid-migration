public without sharing class FileUploadController {

    public static String FIELD_CONTACT_ID = 'contactId';
    public static String FIELD_USER = 'user';
    public static String FIELD_CONTACT_DOCUMENTS = 'contactDocuments';
    public static String FIELD_DOCUMENT_TYPES = 'documentTypes';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';


    public static String FIELD_DELETE_STATUS = 'deleteStatus';
    public static String FIELD_SAVE_STATUS = 'saveStatus';
    public static String FIELD_MESSAGE = 'message';
    public static String SUCCESS = 'success';
    public static String FAILED = 'failed';

    private static User getCurrentUser()
    {
        List<User> listUsers = [SELECT ProfileId, ContactId, App_Previously_Studied_at_Monash__c
                                       FROM User
                                       WHERE Id = :UserInfo.getUserId()];

        System.Debug('FileUploadController::getCurrentUser:' + listUsers);
        return listUsers[0];
    }


    @AuraEnabled
    public static Map<String, Object> getInitLoad(Id appId)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // user
        User currUser = getCurrentUser();
        mapResults.put(FIELD_USER, currUser);

        // contact
        Id contactId = currUser.ContactId;
        mapResults.put(FIELD_CONTACT_ID, contactId);

        // existing documents
        List<Contact_Document__c> listDocs = GetContactDocuments(appId);
        mapResults.put(FIELD_CONTACT_DOCUMENTS, listDocs);

        // document type options
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Map<String, String>> docTypeOptions = populatePicklistAsOptions(fieldResult);
        mapResults.put(FIELD_DOCUMENT_TYPES, docTypeOptions);

        return mapResults;
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

    /**
     * Delete any previous file which has been uploaded but not linked yet
     *
     * @param oldFileId
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> deleteUploadedFile(Id fileId)
    {
        Map<String, Object> mapResult = new Map<String, Object>();

        if(null != fileId) {

            System.debug('FileUploadController::deleteUploadedFile: file Id ' + fileId);
            // check permissions
            User currUser = getCurrentUser();
            UserRecordAccess ura = MyApplicationUtilities.getRecordAccessForUserByIds(fileId, currUser.Id);
            if (ura.HasDeleteAccess || Test.isRunningTest())
            {
                List<ContentDocument> oldFiles = [SELECT Id, Title FROM ContentDocument WHERE Id = :fileId];

                System.debug('FileUploadController::deleteUploadedFile: oldFiles ' + oldFiles);
                if (oldFiles.size() > 0) {
                    delete oldFiles;
                    mapResult.put(FIELD_DELETE_STATUS, SUCCESS);
                }
            }
        }
        else
        {
            mapResult.put(FIELD_DELETE_STATUS, FAILED);
            mapResult.put(FIELD_MESSAGE, 'No file Id');
        }

        return mapResult;
    }

    @AuraEnabled
    public static Map<String, Object> saveFileAndContactDocument(Id fileId,
            Id contactId,
            Id appId,
            String docTypeValue,
            String docSubTypeValue,
            String docComments)
    {
        Map<String, Object> mapResult = new Map<String, Object>();

        if(fileId != null && contactId != null && appId != null) {

            // get the file to update the Title
            List<ContentDocument> listFiles = [SELECT Id, Title, FileExtension FROM ContentDocument WHERE Id=:fileId];
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
            insert conDoc;

            List<ContentDocumentLink> listLinks = new List<ContentDocumentLink>();
            // create CD link
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.ContentDocumentId = fileId;
            cdLink.LinkedEntityId = conDoc.Id;
            cdLink.ShareType = 'v';
            cdLink.Visibility = 'AllUsers';
            listLinks.add(cdLink);

            // create app-link
            ContentDocumentLink appLink = new ContentDocumentLink();
            appLink.ContentDocumentId = fileId;
            appLink.LinkedEntityId = appId;
            appLink.ShareType = 'v';
            appLink.Visibility = 'AllUsers';
            listLinks.add(appLink);
            insert listLinks;

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
    public static Boolean SubmitDocuments(String appId, Boolean saveSubmitted)
    {
        //Get the Documents new to this application
        Application__c app = [
                                 SELECT a.Id, a.Applicant__c
                                 FROM Application__c a
                                 WHERE a.Id = :appId
                             ];
        Contact_Document__c[] documents = [
                                              SELECT d.Id, d.Document_Type__c, d.LastModifiedDate, d.Contact__c, d.Type__c, d.Comments__c, d.Filename__c, d.Submitted__c, d.Post_Submission__c
                                              FROM Contact_Document__c d
                                              WHERE d.Contact__c = :app.Applicant__c AND d.Post_Submission__c = FALSE
                                                      ORDER BY d.Submitted__c DESC
                                          ];

        for (Contact_Document__c doc : documents) {
            doc.Post_Submission__c = true;
            doc.Submitted__c = true;
        }
        try {
            upsert documents;
        }
        catch(Exception e ) {
            ExLog.add('Apex Class', 'FileUploadController', 'Submit Documents', e.getMessage());
            return false;
        }

        return true;
    }

    /*
    @AuraEnabled
    public static Contact_Document__c CreateContactDocument(String type, String subType, String appId) {
        Contact_Document__c cd = new Contact_Document__c();
        try {
            Application__c app = [
                    SELECT a.Id, a.Applicant__c
                    FROM Application__c a
                    WHERE a.Id = :appId
            ];
            cd.Contact__c = app.Applicant__c;
            cd.Document_Type__c = MyApplicationUtitiles.TranslatePicklistOption(type, 'Document_Type__c', 'Contact_Document__c');
            cd.Type__c = MyApplicationUtitiles.TranslatePicklistOption(subType, 'Type__c', 'Contact_Document__c');
            insert cd;
        } catch (Exception e) {
            ExLog.add('FileUploadController', 'Contact_Document__c', 'CreateContactDocument', e.getMessage());
        }
        //Convert to user friendly information

        List<Contact_Document__c> docs = [
                SELECT d.Id, toLabel(d.Document_Type__c), d.LastModifiedDate, d.Contact__c, d.Type__c, d.Comments__c, d.Filename__c, d.Submitted__c
                FROM Contact_Document__c d
                WHERE d.Id = :cd.Id
        ];

        if (docs.size() > 0) {
            return docs[0];
        }

        return null;

    }
    */

    /*
    @AuraEnabled
    public static Contact_Document__c UpdateContactDocument(String documentId, String type, String subType, String comments, String filename) {
        Contact_Document__c doc = [
                SELECT d.Id, d.Document_Type__c, d.Contact__c, d.Type__c, d.Comments__c, d.Filename__c
                FROM Contact_Document__c d
                WHERE d.Id = :documentId
        ];
        doc.Document_Type__c = MyApplicationUtitiles.TranslatePicklistOption(type, 'Document_Type__c', 'Contact_Document__c');
        doc.Type__c = MyApplicationUtitiles.TranslatePicklistOption(subType, 'Type__c', 'Contact_Document__c');
        doc.Comments__c = comments;
        doc.Filename__c = filename;

        try {
            //Rename the Filename to include type
            List<ContentDocumentLink> links = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :documentId
            ];

            for (ContentDocumentLink link : links) {
                List<ContentDocument> condocs = [SELECT Title, FileExtension FROM ContentDocument WHERE Id = :link.ContentDocumentId];
                for (ContentDocument condoc : condocs) {
                    condoc.Title = type + '_' + condoc.Title;
                }
                upsert condocs;
            }
            update doc;
        } catch (Exception e) {
            ExLog.add('FileUploadController', 'Contact_Document__c', 'UpdateContactDocument', e.getMessage());
        }


        List<Contact_Document__c> docs = [
                SELECT d.Id, toLabel(d.Document_Type__c), d.LastModifiedDate, d.Contact__c, d.Type__c, d.Comments__c, d.Filename__c, d.Submitted__c
                FROM Contact_Document__c d
                WHERE d.Id = :doc.Id
        ];

        if (docs.size() > 0) {
            return docs[0];
        }

        return null;
    }
    */

    /*
    @AuraEnabled
    public static Map<String,Object> AddApplicationFile(Id appId, Id fileId, Id contactDocumentId)
    {
        Map<String ,Object> mapResults = new Map<String, Object>();

        String sMessage = '';

        // remove any existing files
        List<ContentDocumentLink> linksToDelete = [SELECT Id
        , ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId =: contactDocumentId
        AND ContentDocumentId !=: fileId];
        if(linksToDelete .size() > 0)
        {
            List<Id> delFileIds = new List<Id>();
            sMessage += ' Files to DELETE [';
            for(ContentDocumentLink delLink:linksToDelete)
            {
                sMessage += delLink.Id + ',';
                delFileIds.add(delLink.ContentDocumentId);
            }
            sMessage += ']';

            List<ContentDocument> filesToDelete = [ SELECT Id, Title FROM ContentDocument WHERE Id IN: delFileIds];
            if(filesToDelete.size() > 0)
            {
                delete filesToDelete;
            }
        }
        else
        {
            sMessage += 'No existing Content Documents to Delete. ';
        }


        try {
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = fileId;
            link.LinkedEntityId = appId;
            link.ShareType = 'v';
            link.Visibility = 'AllUsers';

            insert link;

            mapResults.put(FIELD_SAVE_STATUS, SUCCESS);
            sMessage += 'Contact Document Link + ' + link.Id + ',';
        } catch (Exception e) {
            mapResults.put(FIELD_SAVE_STATUS, FAILED);
            sMessage += 'Exception : ' + e.getMessage();

            ExLog.add('FileUploadController', 'ContentDocumentLink', 'AddApplicationFile', e.getMessage());
        }

        mapResults.put(FIELD_MESSAGE, sMessage);

        return mapResults;
    }
    */

    @AuraEnabled
    public static Map<String, Object> RemoveContactDocument(Id conDocId, Id appId) {

        Map<String, Object> mapResults = new Map<String, Object> ();

        //Remove Contact Document First
        List<Contact_Document__c> docs = [
                                             SELECT d.Id
                                             FROM Contact_Document__c d
                                             WHERE d.Id = :conDocId
                                         ];

        if (docs.size() == 0) {
            // EARLY ERROR OUT
            mapResults.put(FIELD_DELETE_STATUS, FAILED);
            mapResults.put(FIELD_MESSAGE, 'No Contact Document found for Id ' + conDocId);
            return mapResults;
        }

        //Get all of the files related to this Contact Document
        List<ContentDocumentLink> links = [
                                              SELECT ContentDocumentId, LinkedEntityId
                                              FROM ContentDocumentLink
                                              WHERE LinkedEntityId = :docs[0].Id
                                          ];

        try {
            List<ContentDocument> contentDoc = null;
            Set<Id> cdlIds = new Set<Id>();
            for (ContentDocumentLink l : links) {
                cdlIds.add(l.ContentDocumentId);
            }
            if(!cdlIds.isEmpty()) {
                contentDoc = [
                                 SELECT Id
                                 FROM ContentDocument
                                 WHERE Id = :cdlIds
                             ];
            } 
            if(contentDoc != null && contentDoc.size() > 0) {
                delete contentDoc;
            }
            delete docs[0];

            mapResults.put(FIELD_DELETE_STATUS, SUCCESS);

        } catch (Exception e) {
            ExLog.add('FileUploadController', 'Contact_Document__c', 'RemoveDocument', e.getMessage());
            mapResults.put(FIELD_DELETE_STATUS, FAILED);
            mapResults.put(FIELD_MESSAGE, 'Exception ' + e.getMessage());
        }

        // retrieve the latest list of documents again
        List<Contact_Document__c> listDocs = GetContactDocuments(appId);
        mapResults.put(FIELD_CONTACT_DOCUMENTS, listDocs);


        return mapResults;
    }

    /*
    @AuraEnabled
    public static List<String> GetPicklistValues(String fieldName, String objectName) {
        return MyApplicationUtitiles.GetPicklistOptions(fieldName, objectName);
    }
    */

    private static List<Map<String,String>> populatePicklistAsOptions(Schema.DescribeFieldResult fieldResult)
    {
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String,String>> options = new List<Map<String,String>> ();
        for( Schema.PicklistEntry f : ple)
        {
            Map<String,String> mapOption = new Map<String, String>();
            mapOption.put(FIELD_VALUE, f.getValue());
            mapOption.put(FIELD_LABEL, f.getLabel());

            options.add(mapOption);
        }
        return options;
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

}