/**
* @author Nick Guia
* @date NOV.11.2017
* @description Contains handles trigger processes for ContentVersion Object
* @history
**/
public class ContentVersionTriggerHandler {

    /**
    * @author Nick Guia
    * @description handles filter criteria for before insert event
    * @history
    **/
    public static void handleBeforeInsert(List<ContentVersion> newList) {
        List<ContentVersion> updateToPrivate = new List<ContentVersion>(); //list container for records that are to be set to private
        Boolean isUserInPrivateGroup = checkUserSharingPrivacy();

        for(ContentVersion cv : newList) {
            if(isUserInPrivateGroup) updateToPrivate.add(cv);
        }

        if(!updateToPrivate.isEmpty()) {
            updateSharingPrivacy(updateToPrivate, true);
        }
    }
    
    /**
    * @author Kristian Vegerano
    * @description handles filter criteria for after insert event
    * @history
    **/
    public static void handleAfterInsert(List<ContentVersion> newList) {
        uploadProfilePicture(newList);

        List<ContentVersion> enquiryFilesList = new List<ContentVersion>();

        for(ContentVersion cv : newList) {
            if(cv.FirstPublishLocationId != null){
                if(cv.FirstPublishLocationId.getSObjectType() == Case.getSobjectType()){
                    enquiryFilesList.add(cv);
                }
            }
        }

        if(!enquiryFilesList.isEmpty()) {
            createFeedItemOnCreate(enquiryFilesList);
        }
    }

    /**
    * @author Nick Guia
    * @description Method to check if user is in public group that automatically
    *              sets all uploaded content version to private
    * @return   true - if included; otherwise - false
    **/
    private static Boolean checkUserSharingPrivacy() {
        /** get public group membership
            for now, let's check if user belongs to
            Monash Board Management System Users group.
            This filter could be moved to a custom setting if
            needs to be scaled.
        **/
        List<GroupMember> gm = [SELECT Id 
                        FROM GroupMember
                        WHERE UserOrGroupId = :UserInfo.getUserId() 
                        AND Group.DeveloperName = 'Monash_Board_Management_System_Users'
                        LIMIT 1];
        return !gm.isEmpty();
    }

    /**
    * @author Nick Guia
    * @description Updates Content Version's sharing privacy as Salesforce UI only allows you to 
    *              update the file details once it has been uploaded. In order to get around the risk of 
    *              exposing sensitive information, this method automatically updates the record's sharing.
    * @param newList : list of records to be updated
    *        isPrivate : whether to set the record to private or not
    * @history
    **/
    private static void updateSharingPrivacy(List<ContentVersion> newList, Boolean isPrivate) {

        try {
            for(ContentVersion cv : newList) {
                /** SharingPrivacy
                *   N - Public
                *   P - Private
                **/ 
                if(isPrivate) { //set content version to private
                    if(cv.SharingPrivacy != 'P') {
                        cv.SharingPrivacy = 'P';
                    }
                } 
                /**UNCOMMENT THIS SNIPPET IF WE NEED TO RE-USE THIS METHOD FOR
                SETTING CONTENT VERSION TO PUBLIC
                else { //set content version to public
                    if(cv.SharingPrivacy != 'N') {
                        System.debug('**** set content version to public');
                        cv.SharingPrivacy = 'N';
                    }
                }**/
            }
        } catch (Exception ex) {
            nebula.logger.exception(ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();
        }
    }
    
    /** 
    * @author Charlie Park
    * @description Update contact with content version id to show profile picture
    **/
    private static void uploadProfilePicture(List<ContentVersion> newList) {
        //list for contentdocumentLink
        List<ContentDocumentLink> listCDLInsert = new List<ContentDocumentLink>();

        Map<Id, Contact> contactUpdateMap = new Map<Id, Contact>();
        
        //loop trigger to build mapDocIdbyContId
        for(ContentVersion conver : newList) {
            if (conver.isProfilePhoto__c == true) {
                //create new record
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = conver.ContentDocumentId;
                cdl.LinkedEntityId = conver.Constituent__c;
                cdl.ShareType = 'V';
                cdl.Visibility = 'InternalUsers';
                listCDLInsert.add(cdl);

                if (contactUpdateMap.containsKey(conver.Constituent__c) == false) {
                    Contact c = new Contact();
                    c.Id = conver.Constituent__c;
                    c.ucinn_ascendv2__Picture_Record_ID__c = conver.Id;
                    contactUpdateMap.put(c.Id, c);
                }
            }
        }

        if (!listCDLInsert.isEmpty()) {
            insert listCDLInsert;
        }

        if (!contactUpdateMap.isEmpty()) {
            update contactUpdateMap.values();
        }
    }

    /**
    * @author Kristian Vegerano
    * @description Create document feed item on file upload
    **/
    private static void createFeedItemOnCreate(List<ContentVersion> newList) {

        try {
            Map<Id, FeedItem> feedItemMap = new Map<Id, FeedItem>();
            for(ContentVersion cv : newList) {
                FeedItem post = new FeedITem();
                post.body = 'File ' + cv.Title + ' Uploaded';
                post.ParentID = cv.FirstPublishLocationId;
                feedItemMap.put(cv.Id, post);
            }
            
            if(feedItemMap.size() > 0){
                insert feedItemMap.values();
            }
            
            List<FeedAttachment> feedAttachmentList = new List<FeedAttachment>();
            for(ContentVersion cv : newList) {
                FeedAttachment postAttachment = new FeedAttachment();
                postAttachment.FeedEntityId = feedItemMap.get(cv.Id).Id;
                postAttachment.Type = 'Content';
                postAttachment.RecordId = cv.id;
                feedAttachmentList.add(postAttachment);
            }
            
            if(feedAttachmentList.size() > 0){
                insert feedAttachmentList;
            }
        } catch (Exception ex) {
            nebula.logger.exception(ex.getMessage(), ex);
        } finally {
            nebula.logger.saveLog();
        }
        
    }
}