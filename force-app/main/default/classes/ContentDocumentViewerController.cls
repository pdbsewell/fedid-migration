/**
 * @author          Kristian Vegerano
 * @description     Apex controller class for actions required on contentDocumentViewer aura component
 * @group           Controllers
 * @history         24/07/2018
 */
public with sharing class ContentDocumentViewerController {
    @AuraEnabled 
    public static Map<String, Object> retrieveContentDocumentData(String contactDocumentId) {
        Map<String, Object> resultMap = new Map<String, Object>();

        //Retrieve contact document details
        Contact_Document__c contactDocumentRecord = [SELECT Id, Filename__c 
                                                     FROM Contact_Document__c
                                                     WHERE Id = :contactDocumentId
                                                     LIMIT 1];
        resultMap.put('ContactDocument', contactDocumentRecord);

        //Retrieve link details
        ContentDocumentLink contentLinkRecord = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :contactDocumentRecord.Id];

        //Retrieve content document details
        ContentDocument contentDocumentRecord = [SELECT Id, FileExtension, LatestPublishedVersionId
                                                 FROM ContentDocument 
                                                 WHERE Id = :contentLinkRecord.ContentDocumentId 
                                                 LIMIT 1];
        resultMap.put('ContentDocument', contentDocumentRecord);

        //Get file name without the extension
        if(contactDocumentRecord.Filename__c != null){
            List<String> fileNameComponents = contactDocumentRecord.Filename__c.split('\\.');
            resultMap.put('DocumentName', fileNameComponents[0]);
        }

        //Set file extension
        String fileExtension = contentDocumentRecord.FileExtension;
        switch on fileExtension {
            when 'pdf' {
                fileExtension = 'pdf';
            }
            when 'png' {
                fileExtension = 'image';
            }
            when 'jpg' {
                fileExtension = 'image';
            }
            when 'gif' {
                fileExtension = 'image';
            }
            when 'doc' {
                fileExtension = 'word';
            }
            when 'docx' {
                fileExtension = 'word';
            }
            when 'rtf' {
                fileExtension = 'rtf';
            }
            when 'txt' {
                fileExtension = 'txt';
            }
            when else {
                fileExtension = 'unknown';
            }
        }
        resultMap.put('DocumentFileType', 'doctype:' + fileExtension);
        
        //Retrieve content distribution
        ContentDistribution contentLink = ContentDocumentViewerController.retrieveActiveContentDistribution(contentDocumentRecord.LatestPublishedVersionId, 
                                                                                                            contactDocumentRecord, 
                                                                                                            contentDocumentRecord);
        resultMap.put('ContentDistribution', contentLink);

        //Return result map
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @date        05/08/2019
     * @description Returns the relevant content distribution record of the content version
     */
    public static ContentDistribution retrieveActiveContentDistribution(Id contentVersionId, Contact_Document__c relatedContactDocument, ContentDocument relatedContentDocument) {
        //Retrieve content distribution
        ContentDistribution contentLink;
        for(ContentDistribution loopDistribution : [SELECT Id, DistributionPublicUrl, ExpiryDate, PreferencesExpires  
                                                    FROM ContentDistribution 
                                                    WHERE ContentVersionId = :contentVersionId
                                                        AND CreatedById = :UserInfo.getUserId()
                                                    ORDER BY CreatedDate DESC
                                                    LIMIT 1]){
            contentLink = loopDistribution;
        }

        //Create contentdistribution if doesnt exist
        if(contentLink == null){
            contentLink = new ContentDistribution(Name = relatedContactDocument.Filename__c,
                                                  ContentVersionId = relatedContentDocument.LatestPublishedVersionId,
                                                  PreferencesAllowViewInBrowser = true,
                                                  PreferencesLinkLatestVersion = true,
                                                  PreferencesNotifyOnVisit = false,
                                                  PreferencesPasswordRequired = false,
                                                  PreferencesAllowOriginalDownload = false,
                                                  PreferencesAllowPDFDownload = false,
                                                  PreferencesExpires = true,
                                                  ExpiryDate = System.NOW().addDays(1));
            insert contentLink;

            //Query url
            for(ContentDistribution loopDistribution : [SELECT Id, DistributionPublicUrl, ExpiryDate, PreferencesExpires 
                                                        FROM ContentDistribution 
                                                        WHERE ContentVersionId = :contentVersionId 
                                                            AND CreatedById = :UserInfo.getUserId()
                                                        ORDER BY CreatedDate DESC
                                                        LIMIT 1]){
                contentLink = loopDistribution;
            }
        }

        //Extend expiry if already expired
        if(contentLink.ExpiryDate < System.NOW()){
            contentLink.ExpiryDate = System.NOW().addDays(1);
            update contentLink;
        }

        return contentLink;
    }
}