/**
 * @description     FileUploader - Loads files into CRM from salesforce UI
 * @author          Smen
 * @date            27/11/2023
 * @revision
 */
public with sharing class FileUploader {

    
    /************
    * @author:		smen
    * @date:		27/11/2023
    * @description:	aura enabled method to upload file  

    *********/
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId) {
        ContentVersion cv = createContentVersion(base64, filename);
        ContentDocumentLink cdl = null;

        try {
            AgentActivation.run(cv.Id);
            cdl = createContentLink(cv.Id, recordId);
            
        } catch (Exception ee) {
            ExLog.add('FileUploader', 'N/A', 'uploadFile', 'FileUploader failed' + ee.getCause()+'::'+ee.getMessage());
            return null;
        }
        return cdl.Id;
       
    }
    
    /************
    * @author:		smen
    * @date:		27/11/2023
    * @description:	to create Contentversion from the file uploaded

    *********/
    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        insert cv;
        return cv;
       
    }


    /************
    * @author:		smen
    * @date:		27/11/2023
    * @description:	FUTURE method to process csv row by row  

    *********/
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) {
            return null;
        }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id =: contentVersionId
        ].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'V';
        insert cdl;
        return cdl;
       
    }
}