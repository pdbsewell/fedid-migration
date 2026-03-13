public without sharing class MonashCollegeFileUploadService {
    
    /**
     * @description     Method for retrieving content documents related to the parent record
     * @history         12/31/2018
     */
    @AuraEnabled 
    public static List<ContentVersion> getAttachments(String parentId) {
        //Initialize Variables
        Set<Id> contentDocumentIds = new Set<Id>();
        List<ContentDocument> documentsList = new List<ContentDocument>();
        List<ContentVersion> documentVersionsList = new List<ContentVersion>();
        
        //Retrieve ContentDocumentLinks related to the application
        for(ContentVersion loopDocumentVersion : [SELECT Id, ContentDocumentId, Title, FileExtension 
                                                  FROM ContentVersion 
                                                  WHERE FirstPublishLocationId = :parentId]){
            documentVersionsList.add(loopDocumentVersion);                                          
            contentDocumentIds.add(loopDocumentVersion.ContentDocumentId);
        }
        
        //Retrieve content documents related to the attachment via content document links
        for(ContentDocument loopContentDocument : [SELECT Id, Title, FileExtension
                                                   FROM ContentDocument
                                                   WHERE Id IN :contentDocumentIds]){
            documentsList.add(loopContentDocument);
        }
        
        //Retrieve relevant application
        return documentVersionsList;
    }

    /**
     * @description     Method called to upload the document - insert if new / update
     * @history         12/31/2018
     */
    @AuraEnabled
    public static Id saveChunk(String parentId, String fileName, String base64Data, String contentType, String fileId) {
        //Insert the content document when the file is blank
        //Update the inserted content document to append consecutive file chunks
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }

        return Id.valueOf(fileId);
    }

    /**
     * @description     Insert the document for the first chunk
     * @history         12/31/2018
     */
    public static Id saveTheFile(String parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        //Create content version for the document - FirstPublishLocationId related record
        ContentVersion cv = new ContentVersion();
        cv.title = fileName;      
        cv.PathOnClient = fileName;   
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.IsMajorVersion = false;
        cv.FirstPublishLocationId = parentId;
        insert cv;     
        
        //Retrieve content version id
        return cv.Id;
    }

    /**
     * @description     Update the document for the next chunks
     * @history         12/31/2018
     */
    public static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        ContentVersion content = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion where Id = :fileId];
        String existingBody = EncodingUtil.base64Encode(content.VersionData);
        content.VersionData = EncodingUtil.base64Decode(existingBody + base64Data);

        update content;
    }
    
    /**
     * @description     Delete the document 
     * @history         12/31/2018
     */
    @AuraEnabled
    public static String deleteFile(String documentId){
        try{
            ContentDocument deleteContentDocument = new ContentDocument(Id = documentId);
            delete deleteContentDocument;
            return 'SUCCESS';
        }catch(Exception ex){
            System.debug('Error: ' + ex);
            return 'ERROR';
        }
    }
}