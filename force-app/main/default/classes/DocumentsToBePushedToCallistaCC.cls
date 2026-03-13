public with sharing class DocumentsToBePushedToCallistaCC {


    @AuraEnabled
    public static void sendEmailAttachments(List<string> attachmentsIds, id caseId)
    {
        Case caseWithACPAndApplicaton = [SELECT Id, Application_Course_Preference__c, 
                             Application_Course_Preference__r.Application__c
                            FROM Case 
                            WHERE id = :caseId];
        

        List<Contact_Document__c> listOfContactDocuments = [    SELECT  Email_Attachment_Id__c, LastModifiedDate 
                                                                FROM    Contact_Document__c 
                                                                WHERE   Email_Attachment_Id__c IN :attachmentsIds ];

        List<String> attachmentsIdsThatAreNotFailed = new List<String>();
        List<String> attachmentsIdsThatAreFailed = new List<String>();
        List<Contact_Document__c> listOfFailedContactDocuments = new List<Contact_Document__c>();
        
        for(Contact_Document__c contactDocumentObj: listOfContactDocuments)
        {
            // To find the failed
            String emailAttachmentId = String.valueOf(contactDocumentObj.Email_Attachment_Id__c);
            if(attachmentsIds.contains(emailAttachmentId))
            {
                // remove the failed ones from the list
                // the remaining will be the ones that have not failed
                attachmentsIds.remove(attachmentsIds.indexOf(emailAttachmentId));
                attachmentsIdsThatAreFailed.add(emailAttachmentId);
                listOfFailedContactDocuments.add(contactDocumentObj);

            }
        }
        update listOfFailedContactDocuments;

        attachmentsIdsThatAreNotFailed = attachmentsIds;  

        // // // // //Send the documents that are not failed
        Map<String, String> caseApplicationCoursePreferenceMap = new Map<String, String>();
        caseApplicationCoursePreferenceMap.put(caseId, caseWithACPAndApplicaton.Application_Course_Preference__c);

        List<Attachment> attachmentsThatAreNotFailed = new List<Attachment>();
        attachmentsThatAreNotFailed = [SELECT Id, Name, Body, ContentType, ParentId, OwnerId, BodyLength FROM Attachment WHERE id IN :attachmentsIdsThatAreNotFailed];

        if(!attachmentsThatAreNotFailed.isEmpty())
        {
        AttachmentServices.cloneEmailAttachmentsToContactDocument(attachmentsThatAreNotFailed,
                                                                     caseApplicationCoursePreferenceMap,
                                                                     false,
                                                                     true,
                                                                     false);
        }

        // // // // // End of "Send the documents that are not failed"
        // // // // //Send the documents that are failed
        if(!listOfFailedContactDocuments.isEmpty())
        {
            ContactDocumentPostAppPB.QueueFileToSend(new List<id>((new Map<id, Contact_Document__c>(listOfFailedContactDocuments)).keySet()));
        }
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         13/12/2017  
    * @description  reutrns a message to show if the enquiry is valid or not
    *******************************************************************************/
    @AuraEnabled
    public static string isEnquiryValid(id caseId)
    {
        Case caseWithACP = [SELECT  Id, ContactId, 
                                    Application_Course_Preference__c,
                                    Application_Course_preference__r.Application__c,
                                    Application_Course_preference__r.Application__r.Callista_Applicant_Id__c
                            FROM    Case 
                            WHERE   Id = :caseId
                            LIMIT   1 ];

        String result = 'This case is valid.';

        if(caseWithACP == null)
            result = 'No Case';
        else if(caseWithACP.Application_Course_Preference__c == null)
            result = 'No ACP';
        else if(caseWithACP.ContactId == null)
            result = 'No Contact';
        else if(caseWithACP.Application_Course_preference__r.Application__c == null)
            result = 'No Application';
        else if(caseWithACP.Application_Course_preference__r.Application__r.Callista_Applicant_Id__c == null)
            result = 'No Callista Applicant Id';
        
        return result;
    }
    
    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         20/10/2017  
    * @description  gets all the case attachments and match it against the corresponding
                        contact document
    * @revision     28.Nov.2017, Anterey Custodio - filtered attachments so that it only
                        shows those that were inserted after it was reopened (SF-726)
                        - formatted the code to align with best practices
    *******************************************************************************/
    @AuraEnabled
    public static List<wrapperClass> getTheCaseAttachmentsWithMatchtingContactDocumentFields(String caseId, Boolean showAllAttachments) {
        Case caseWithACP = [SELECT  Id, ContactId, 
                                    Application_Course_Preference__c, 
                                    Enquiry_Reopened__c,
                                    ClosedDate
                            FROM    Case 
                            WHERE   Id = :caseId
                            LIMIT   1 ];

        List<wrapperClass> wrapperClassObjList;

        wrapperClassObjList = new List<wrapperClass> ();
        
        List<Attachment> listOfAttachments; 
        if(showAllAttachments == true) {
        listOfAttachments = [  SELECT      id, Name, Body, BodyLength, 
                                                            ContentType, ParentId, CreatedDate 
                                                FROM        Attachment 
                                                WHERE       ParentId IN (   SELECT  Id 
                                                                            FROM    EmailMessage 
                                                                            WHERE   ParentId = :caseId 
                                                                                    AND Incoming = true )
                                                ORDER BY    CreatedDate DESC ];
        } else
        {
            listOfAttachments = [  SELECT      id, Name, Body, BodyLength, 
                                                            ContentType, ParentId, CreatedDate 
                                                FROM        Attachment 
                                                WHERE       ParentId IN (   SELECT  Id 
                                                                            FROM    EmailMessage 
                                                                            WHERE   ParentId = :caseId 
                                                                                    AND Incoming = true )
                                                            AND CreatedDate >=: caseWithACP.Enquiry_Reopened__c
                                                            AND CreatedDate >=: caseWithACP.ClosedDate
                                                ORDER BY    CreatedDate DESC ];
        }


        List<String> attachmentIds = new List<String>();
        // Revision by Majid 02/01/2018 To get create a list of the attachments ids
        for(Attachment attachmentObj: listOfAttachments) {
            attachmentIds.add(attachmentObj.Id);
        }

        List<Contact_Document__c> listOfContactDocuments = [    SELECT  Document_Status__c,
                                                                        Email_Attachment_Id__c, LastModifiedDate 
                                                                FROM    Contact_Document__c 
                                                                WHERE   Email_Attachment_Id__c IN :attachmentIds ];

        for(Integer i = (listOfAttachments.size()-1); i >=0 ; i--){
            Attachment attachmentTempObj = listOfAttachments[i];
            if(!listOfContactDocuments.isEmpty())
            {
                for(Contact_Document__c contactDocumentObj: listOfContactDocuments)
                {
                    if(attachmentTempObj.id == contactDocumentObj.Email_Attachment_Id__c)
                    {
                        // to determin if an attachment submission has failed
                        // Then in progress should be changed to failed
                        boolean withinTwoMinutes = false;

                        // Number of seconds since an attachment has been modified
                        long secondsSinceModification = (datetime.now().getTime() - contactDocumentObj.LastModifiedDate.getTime())/1000;
                        // If an attachment has been sent more than two mintues ago
                        if(secondsSinceModification < 120)
                            withinTwoMinutes = true;

                        String determinedFileType = AttachmentServices.getFileType(attachmentTempObj.Name, attachmentTempObj.ContentType);
                        AvailableOptions availableOptionsObj = getAvailableOptions(
                            attachmentTempObj.BodyLength, 
                            determinedFileType, 
                            contactDocumentObj.Document_Status__c,
                            withinTwoMinutes);

                        wrapperClass wrapperClassTempObj = new wrapperClass();

                        wrapperClassTempObj.attachment = attachmentTempObj;
                        wrapperClassTempObj.attachmentBody = EncodingUtil.base64Encode(attachmentTempObj.Body);
                        wrapperClassTempObj.status = availableOptionsObj.status;
                        wrapperClassTempObj.statusIcon = availableOptionsObj.statusIcon;
                        wrapperClassTempObj.statusIconColor = availableOptionsObj.statusIconColor;
                        wrapperClassTempObj.fileType = determinedFileType;
                        wrapperClassTempObj.showDownloadCheckBox = availableOptionsObj.downloadOption;
                        wrapperClassTempObj.showSendToCallistaCheckBox = availableOptionsObj.sendToCallistaOption;
                        wrapperClassTempObj.defaultSelectionOfDownloadCheckBox = availableOptionsObj.downloadOptionSelected;
                        wrapperClassTempObj.defaultSelectionOfSendToCallistaCheckBox = availableOptionsObj.sendToCallistaOptionSelected;
                        
                        wrapperClassObjList.add(wrapperClassTempObj);
                        listOfAttachments.remove(i);
                    }
                }
            }
        }

        for(Attachment attachmentTempObj: listOfAttachments) {
            String determinedFileType = AttachmentServices.getFileType(attachmentTempObj.Name, attachmentTempObj.ContentType);
            AvailableOptions availableOptionsObj = getAvailableOptions(
                            attachmentTempObj.BodyLength, 
                            determinedFileType, 
                            false,
                            false);
                        wrapperClass wrapperClassTempObj = new wrapperClass();
                        wrapperClassTempObj.attachment = attachmentTempObj;
                        wrapperClassTempObj.attachmentBody = EncodingUtil.base64Encode(attachmentTempObj.Body);
                        wrapperClassTempObj.fileType = determinedFileType;
                        wrapperClassTempObj.status = availableOptionsObj.status;
                        wrapperClassTempObj.statusIcon = availableOptionsObj.statusIcon;
                        wrapperClassTempObj.statusIconColor = availableOptionsObj.statusIconColor;
                        wrapperClassTempObj.showDownloadCheckBox = availableOptionsObj.downloadOption;
                        wrapperClassTempObj.showSendToCallistaCheckBox = availableOptionsObj.sendToCallistaOption;
                        wrapperClassTempObj.defaultSelectionOfDownloadCheckBox = availableOptionsObj.downloadOptionSelected;
                        wrapperClassTempObj.defaultSelectionOfSendToCallistaCheckBox = availableOptionsObj.sendToCallistaOptionSelected;

                        wrapperClassObjList.add(wrapperClassTempObj);
        }

        wrapperClassObjList.sort();

        return wrapperClassObjList; 
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         15/01/2017  
    * @description  Get the reopned date and closed date of the enquiry and return
                    them. This function is called when there is no attachment on the 
                    enquiry, thus it will return the mentioned dates in order to show
                    a message to the user. The message will be either there is no attachemnt
                    after the reopend date or the enquiry is closed so there is no new attachment
                    since then.

    * @revision
    *******************************************************************************/
    @AuraEnabled
    public static String getTheCaseDates(String caseId) {
        Case caseObj = [SELECT      Id,
                                    Enquiry_Reopened__c,
                                    ClosedDate
                            FROM    Case 
                            WHERE   Id = :caseId
                            LIMIT   1 ];

        String theCaseDate = null;
        if (caseObj.Enquiry_Reopened__c != null)
            theCaseDate = 'Reopend,' + caseObj.Enquiry_Reopened__c;
        if(caseObj.Enquiry_Reopened__c == null && caseObj.ClosedDate != null)
            theCaseDate = 'Closed,' + caseObj.ClosedDate;
        if(caseObj.Enquiry_Reopened__c != null && caseObj.ClosedDate != null)
            theCaseDate = caseObj.Enquiry_Reopened__c > caseObj.ClosedDate ? 'Reopend,' + caseObj.Enquiry_Reopened__c : 'Closed,' + caseObj.ClosedDate;
        return theCaseDate;
    }

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         20/10/2017  
    * @description  gets all the case attachments and match it against the corresponding
                        contact document
    * @revision     28.Nov.2017, Anterey Custodio - formatted the code to align with best practices
    *******************************************************************************/
    public static AvailableOptions getAvailableOptions(Integer bodySize, String fileType, Boolean isSubmitted, Boolean withinTwoMinutes)
    {
        AvailableOptions availableOptionsObj;
        if (isSubmitted) {
            availableOptionsObj = new AvailableOptions('Success', 'action:approval', 'greenIconStatus',true, false, false, false);

        } else if (!isSubmitted && bodySize > Integer.valueOf(System.Label.App_MaxFileSizeInBytes)) {
            availableOptionsObj = new AvailableOptions('Large Doc', 'action:priority', 'redIconStatus', true, true, false, false);

        } else if (!isSubmitted && !AttachmentServices.theFileIsQualifiedToBeSentToCallista(bodySize, fileType)) {
            availableOptionsObj = new AvailableOptions('Small Image', 'action:priority', 'yellowIconStatus', true, false, true, false);
        } 
        else if (!isSubmitted && !withinTwoMinutes) {
            availableOptionsObj = new AvailableOptions('Failed', 'action:close', 'redIconStatus', true, true, true, false);

        } 
        else if (!isSubmitted && withinTwoMinutes) {
            availableOptionsObj = new AvailableOptions('In Progress', 'action:user_activation', 'blueIconStatus', true, false, false, false);

        } 
        else if (!isSubmitted) {
            availableOptionsObj = new AvailableOptions('Not Yet Sent', 'action:refresh', 'yellowIconStatus', true, false, true, false);
        } 
        else {
            availableOptionsObj = new AvailableOptions('Error. Contact Support', 'action:question_post_action', 'redIconStatus', true, true, false, false);
        }
        return availableOptionsObj;
    }

    public class wrapperClass implements Comparable{
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String statusIcon {get;set;}
        @AuraEnabled public String statusIconColor {get;set;}

        @AuraEnabled public String fileType {get;set;}

        @AuraEnabled public Attachment attachment {get;set;}
        @AuraEnabled public String attachmentBody {get;set;}

        @AuraEnabled public Boolean showDownloadCheckBox {get;set;}
        @AuraEnabled public Boolean showSendToCallistaCheckBox {get;set;}
        @AuraEnabled public Boolean defaultSelectionOfDownloadCheckBox {get;set;}
        @AuraEnabled public Boolean defaultSelectionOfSendToCallistaCheckBox {get;set;}

        // Compare wrapperClass based on the attachment CreatedDate.
        public Integer compareTo(Object compareTo) {
            // Cast argument to wrapperClass
            wrapperClass compareToWrapperClassObj = (wrapperClass)compareTo;

            Integer returnValue = 0;

            if (attachment.CreatedDate > compareToWrapperClassObj.attachment.CreatedDate)
            {
                returnValue = -1;
            }
            else if (attachment.CreatedDate < compareToWrapperClassObj.attachment.CreatedDate)
            {
                returnValue = 1;
            }

            if (returnValue == 0)
            {
                if (attachment.Name.compareTo(compareToWrapperClassObj.attachment.Name) < 0)
                {
                    returnValue = -1;
                }
                else if (attachment.Name.compareTo(compareToWrapperClassObj.attachment.Name) > 0)
                {
                    returnValue = 1;
                }
            }
            
            return returnValue;
        }
    }

    public class AvailableOptions{

        public AvailableOptions(string statusArg,
                                String statusIconArg,
                                String statusIconColorArg,
                                Boolean downloadOptionArg,
                                Boolean downloadOptionSelectedArg,
                                Boolean sendToCallistaOptionArg,
                                Boolean sendToCallistaOptionSelectedArg){
         this.status = statusArg;
         this.statusIcon = statusIconArg;
         this.statusIconColor = statusIconColorArg;
         this.downloadOption = downloadOptionArg;
         this.downloadOptionSelected = downloadOptionSelectedArg;
         this.sendToCallistaOption = sendToCallistaOptionArg;
         this.sendToCallistaOptionSelected = sendToCallistaOptionSelectedArg;
        }

        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String statusIcon {get;set;}
        @AuraEnabled public String statusIconColor {get;set;}

        @AuraEnabled public Boolean downloadOption {get;set;}
        @AuraEnabled public Boolean downloadOptionSelected {get;set;}
        @AuraEnabled public Boolean sendToCallistaOption {get;set;}
        @AuraEnabled public Boolean sendToCallistaOptionSelected {get;set;}
    }
}