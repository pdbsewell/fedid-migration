/**
 * @author Charlie Park, UC Innovation
 * @date 10/1/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description Controller for uploading profile picture
 */
public without sharing class PORTAL_UCIN_ProfilePictureUploadCC {
    /**
    * Get portal profile picture based on passed in contact Id. Portal_Picture_ID__c holds ID of the file attached under the contact.
    *
    * @return:			Map of picture ID and base64 data.
    * @since: 			1.0
    */
    @AuraEnabled
    public static Map<String, Object> getProfilePictureFromConstituent(Id contactId) {

        Map<String, Object> profilePictureInfoMap = new Map<String, Object>();
        String profilePictureId = [SELECT Portal_Picture_ID__c FROM Contact WHERE Id =: contactId LIMIT 1].Portal_Picture_ID__c;
        if (String.isBlank(profilePictureId)) {
            return null;
        }
        List<ContentVersion> contentVersionList = [SELECT VersionData FROM ContentVersion WHERE Id = :profilePictureId];
        if (contentVersionLIst.isEmpty()) {
            return null;
        }
        String profilePictureVersionDataBase64 = EncodingUtil.base64Encode(contentVersionList[0].VersionData);

        profilePictureInfoMap.put('profilePictureId', contentVersionList[0].Id);
        profilePictureInfoMap.put('profilePictureVersionDataBase64', profilePictureVersionDataBase64);
        return profilePictureInfoMap;
    }
    
    /**
    * Get portal profile picture based on passed in parentId
    *
    * @return:			Map of picture ID and base64 data.
    * @since: 			1.0
    */
    @AuraEnabled
    public static Map<String, String> getProfilePictureFromContentVersion(Id parentId) {
        Map<String, String> profilePictureMap = new Map<String, String>();
        
        List<ContentDocumentLink> contentLinkList = [Select Id, ContentDocumentId, LinkedEntityId From ContentDocumentLink
                                                     Where LinkedEntityId =: parentId AND 
                                                     (ContentDocument.FileExtension = 'png' OR ContentDocument.FileExtension = 'jpg') 
                                                      ORDER BY ContentDocument.CreatedDate DESC Nulls Last];
        if (!contentLinkList.isEmpty()) {
            ContentDocumentLink link = contentLinkList[0];
            List<ContentVersion> contentVersionList = [Select Id, VersionData From ContentVersion Where ContentDocumentId =: link.ContentDocumentId];
            
            if (!contentVersionList.isEmpty()) {
                
                String profilePictureVersionDataBase64 = EncodingUtil.base64Encode(contentVersionList[0].VersionData);
                
                profilePictureMap.put('profilePictureId', contentVersionList[0].Id);
                profilePictureMap.put('profilePictureVersionDataBase64', profilePictureVersionDataBase64);
                
                return profilePictureMap;
            } else {
                return null;
            }
        } else {
            return null;
        }
    }
    
    /**
    * Upload a new file record under the contact
    *
    * @return:			N/A
    * @since: 			1.0
    */
    @AuraEnabled
    public static void updateProfilePicture(Id contactId, String profilePictureId, List<Id> uploadedPhotoIds) {
        // Check if portal profile picture record already exists for this contact
        Contact thisContact = [SELECT ID,Portal_Profile_Picture__c, Portal_Profile_Picture__r.Id FROM Contact WHERE Id =: contactId];
        // Create portal profile picture object
        Portal_Profile_Picture__c publicPictureObj = new Portal_Profile_Picture__c();
        if (thisContact.Portal_Profile_Picture__c != null) {
            publicPictureObj = thisContact.Portal_Profile_Picture__r;
        } else {
            insert publicPictureObj;
        }
        
        List<ContentDocumentLink> links = [SELECT ID, ShareType, Visibility, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:contactId AND 
                                           ContentDocumentId IN (SELECT ContentDocumentId 
                                                                FROM ContentVersion WHERE Id = :profilePictureId)];
        // For each link found, create a new link to the public profile picture object
        List<ContentDocumentLink> publicLinkList = new List<ContentDocumentLink>();

        for (ContentDocumentLink link : links) {
            link.Visibility = 'AllUsers';

            ContentDocumentLink publicLink = new ContentDocumentLink();
            publicLink.Visibility = 'AllUsers';
            publicLink.LinkedEntityId = publicPictureObj.Id;
            publicLink.ContentDocumentId = link.ContentDocumentId;
            publicLink.ShareType = link.ShareType;
            publicLinkList.add(publicLink);
        }

        update links;
        insert publicLinkList;

        deleteProfilePicture(contactId);
        update new Contact(Id=contactId, Portal_Picture_ID__c=profilePictureId, Portal_Profile_Picture__c = publicPictureObj.Id);
        if (uploadedPhotoIds.size() > 1) {
            uploadedPhotoIds.remove(uploadedPhotoIds.size()-1);
        	deleteUnusedPhotos(contactId, uploadedPhotoIds);
        }
    }
    
    /**
    * Delete profile picture of this contact
    *
    * @return:			N/A
    * @since: 			1.0
    */
    @AuraEnabled
    public static void deleteProfilePicture(Id contactId) {
        String profilePictureId = [SELECT Portal_Picture_ID__c FROM Contact WHERE Id =: contactId LIMIT 1].Portal_Picture_ID__c;
        List<ContentDocumentLink> links = [SELECT ID FROM ContentDocumentLink WHERE LinkedEntityId =:contactId AND 
                                           ContentDocumentId IN (SELECT ContentDocumentId 
                                                                FROM ContentVersion WHERE Id = :profilePictureId)];
        delete links;
        List<ContentDocument> documents = [SELECT ID FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId 
                                                                FROM ContentVersion WHERE Id = :profilePictureId)];
        delete documents;
    }
    
    /**
    * If a new profile picture is uploaded, delete the old one.
    *
    * @return:			N/A
    * @since: 			1.0
    */
    @AuraEnabled
    public static void deleteUnusedPhotos(Id contactId, List<Id> uploadedPhotoIds) {
        List<ContentDocumentLink> links = [SELECT ID FROM ContentDocumentLink WHERE LinkedEntityId =:contactId AND 
                                           ContentDocumentId IN (SELECT ContentDocumentId 
                                                                FROM ContentVersion WHERE Id IN :uploadedPhotoIds)];
       delete links;
       List<ContentDocument> documents = [SELECT ID FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId 
                                                                FROM ContentVersion WHERE Id IN :uploadedPhotoIds)];
        delete documents;
    }
    
}