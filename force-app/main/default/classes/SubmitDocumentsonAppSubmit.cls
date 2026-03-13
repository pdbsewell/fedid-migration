/**
 * @author       Shalini mendu
 * @date         18 Jul 2019
 * @description  Asynchronous class for Document submissions
 * @revision
 * 08/02/2022 - Vinothraja   - SFTG-2365 Added code to bulkify logging during & after callouts
 * 28/08/2024 - Kai-Fan Hsieh - DANO-31 Added code to append channel field to comments
 * 08/11/2024 - Kai-Fan Hsieh - ANO-347: Added code to prevent sending documents have owner mismatch flag checked to callista
 */
public with sharing class SubmitDocumentsonAppSubmit {

    /**
     * @description  Submits documents to Callista for the given application ID using a future callout.
     *               This method allows for asynchronous processing of document submission.
     * @param appId  The ID of the application for which the documents are being submitted.
     * @revision
     * 28/08/2024 - Kai-Fan Hsieh - DANO-31 Added code to append channel field to comments
     */
    @Future(callout=true)
    public static void submitDocumentsToCallista(String appId) {
        Application__c app = StudFirst_SubmitApplicationHelper.getApplicationById(appId);
        Contact con = StudFirst_SubmitApplicationHelper.getApplicantById(app.Applicant__c);

        String callApplicantId = app.Callista_Applicant_Id__c;
        //Call the helper method to derive alternative applicantIds if App.Callista_Applicant_Id__c is null
        if (callApplicantId == null) {
            //Pass application.Callista_Applicant_Id__c & contact.bulkapi_Applicant_Ids__c to derive applicantId
            callApplicantId = StudFirst_SubmitApplicationHelper.parseApplicantId(app.Callista_Applicant_Id__c,
                con.bulkapi_Applicant_Ids__c);
        }
        // Find the ContentDocumentLinks linked to this Application
        List<ContentDocumentLink> cdAppLinks = [
            SELECT Id,
                LinkedEntityId,
                ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :app.Id
        ];
        //no Documents for the Application, so return back
        if (cdAppLinks.size() == 0) {
            return;
        }
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink appLink : cdAppLinks) {
            // populate the Set with the ContentDocumentIds
            contentDocIds.add(appLink.ContentDocumentId);
        }
        //Query for all the ContentDocumentLink for the ContentDocumentIds
        List<ContentDocumentLink> cdDocLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocIds
        ];
        Set<Id> linkedIds = new Set<Id>();
        for (ContentDocumentLink docLink : cdDocLinks) {
            // Add the LinkedEntityId for each ContentDocumentLink
            linkedIds.add(docLink.LinkedEntityId);
        }
        //Query all the Contact_Document__c that are linked to ContentDocumentLink
        Map<Id, Contact_Document__c> conDocs = new Map<Id, Contact_Document__c> ([
            SELECT Id, File_Upload_Successful__c,
                Contact__c,
                Comments__c,
                Contact__r.Person_ID__c,
                Contact_Qualification__c,
                Document_Type__c,
                Document_Type_Name__c,
                Filename__c,
                Has_API_Request__c,
                Has_API_Response__c,
                API_Request__c,
                Submitted__c,
                Type__c,
                Channel__c
            FROM Contact_Document__c
            WHERE Id IN :linkedIds
            AND File_Upload_Successful__c != TRUE
            AND Filename__c != NULL AND Filename__c != ''
            AND Document_Type__c != NULL
            AND Document_Status__c != TRUE
            AND Document_Owner_Mismatch__c != TRUE
        ]);
        //No Documents in the right condition, so return back
        if(conDocs.size() == 0) {
            return;
        }
        //Query all the ContentDocumentLink that are linked to Contact_Document__c
        Map<Id, ContentDocumentLink> mapContentDocumentLink = new Map<Id, ContentDocumentLink> ();
        Set<Id> setContentDocIds = new Set<Id> ();
        for (ContentDocumentLink cdl : [
            SELECT
                Id,
                ContentDocumentId,
                ContentDocument.LatestPublishedVersionId,
                LinkedEntityId
            FROM
                ContentDocumentLink
            WHERE LinkedEntityId IN :conDocs.keySet()
        ]) {
            mapContentDocumentLink.put(cdl.LinkedEntityId, cdl);
            setContentDocIds.add(cdl.ContentDocumentId);
        }
        //Query all the ContentDocument
        Map<Id, ContentDocument> mapContentDocument = new Map<Id, ContentDocument> ([
            SELECT
                Id,
                Title,
                LatestPublishedVersionId,
                FileExtension,
                ArchivedById,
                ArchivedDate,
                ContentAssetId,
                ContentModifiedDate,
                ContentSize,
                Description,
                FileType,
                IsArchived,
                LastReferencedDate,
                LastViewedDate,
                OwnerId,
                ParentId,
                PublishStatus,
                SharingOption,
                SharingPrivacy
            FROM
                ContentDocument
            WHERE Id IN :setContentDocIds
        ]);
        // Create FileToCallistaInterface instance for each Contact_Document__cs
        List<FileToCallistaInterface> callistaRequests = new List<FileToCallistaInterface>();
        List<Exception_Log__c> lstLogs = new List<Exception_Log__c> ();
        List<Contact_Document__c> lstContactDocumentRec = new List<Contact_Document__c>();
        for (Contact_Document__c contactDoc : conDocs.values()) {
            String contactDocRec = JSON.serialize(contactDoc);
            ContentDocumentLink cdl = mapContentDocumentLink.get(contactDoc.Id);
            String cdlRec = JSON.serialize(cdl);
            String cdRec = JSON.serialize(mapContentDocument.get(cdl.ContentDocumentId));
            //Call out for Document submissions
            FileToCallistaInterface fci = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, callApplicantId, null);
            callistaRequests.add(fci);
            //Add Content Document instances to List, for updating later
            if (fci.jsonRequest != null) {
                lstContactDocumentRec.add(fci.contactDocumentRec);
            }
            fci.sendMessage();
        }

        // update Content Documents with the API Request
        if (!lstContactDocumentRec.isEmpty()) {
            update lstContactDocumentRec;
        }

        // Handle response for each call out
        lstContactDocumentRec.clear();
        for (FileToCallistaInterface finishedCallout : callistaRequests) {
            finishedCallout.handleResponse();
            if (finishedCallout.httpResponseCode == 200 && finishedCallout.jsonRequest != null) {
                lstContactDocumentRec.add(finishedCallout.contactDocumentRec);
            }
            // capture all the logs of the callout
            lstLogs.addAll(finishedCallout.logs);
        }

        // update Content Documents with the API Request post-processing
        if (!lstContactDocumentRec.isEmpty()) {
            update lstContactDocumentRec;
        }
        // create callout logs (incl exceptions)
        if (!lstLogs.isEmpty()) {
            insert lstLogs;
        }
    }
}