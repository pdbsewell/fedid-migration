/**
 * @author       Shalini Mendu
 * @date         31.Jul.2019
 * @description  Apex scheduler which submits documents post application submission
 * @revision
 * 19/02/2020 - updated execute block to enable sending offer related documents to callista
 * 29/08/2021 - Removed exception logging
 * 08/02/2022 - Vinothraja    - SFTG-2365 Added code to bulkify logging during & after callouts
 * 28/08/2024 - Kai-Fan Hsieh - DANO-31 Added code to append channel field to comments
 * 08/11/2024 - Kai-Fan Hsieh - DANO-347: Added code to prevent sending documents have owner mismatch flag checked to callista
*/
public class SendContentDocQueuable implements Queueable, Database.AllowsCallouts {
    private List<Id> contactDocIds;

    /**
     * @description Constructor for the SendContentDocQueuable class.
     * @param contactDocumentIds List of Contact Document record IDs to be processed.
     */
    public SendContentDocQueuable(List<Id> contactDocumentIds) {
        contactDocIds = contactDocumentIds;
    }

    /**
     * @author        Shalini Mendu
     * @date          31.Jul.2019
     * @param context The context in which the job is being executed, provided by the Queueable interface.
     * @description   Apex scheduler which submits documents post application submission
     * @revision      19/02/2020 - updated execute block to enable sending offer related documents to callista
     *                08/11/2024 - Kai-Fan Hsieh - ANO-347: Added code to prevent sending documents have owner mismatch flag checked to callista
     */
    public void execute(QueueableContext context) {
        try {
            // get the contact documents for sending
            Map<Id, Contact_Document__c> conDocs = new Map<Id, Contact_Document__c> ([
                SELECT
                    Id,
                    File_Upload_Successful__c,
                    Opportunity__c,
                    Contact__c,
                    Application__c,
                    Application__r.Status__c,
                    Application__r.Id,
                    Application__r.Callista_Application_Id__c,
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
                WHERE Id IN :contactDocIds
                AND Filename__c != null AND Filename__c != ''
                AND Document_Type__c != null
                AND Document_Status__c != true
                AND Document_Owner_Mismatch__c != true
            ]);
            Map<Id, Contact_Document__c> submittedAppConDocs = new Map<Id, Contact_Document__c>();
            // get the related Contacts to search for related Applications
            Map<id, String> cDToContactMap = new Map<id, string>();
            Map<Id, Id> contactDocumentToQueueMap = new Map<Id, Id>();
            Set<Id> uniqueAppIds = new Set<Id>();
            //Check for Contact documents with Applications in Submitted status
            for (Contact_Document__c cd : conDocs.values()) {
                cDToContactMap.put(cd.id, cd.Contact__c);
                contactDocumentToQueueMap.put(cd.Id, cd.Opportunity__c);
                if (cd.Application__c != null && cd.Application__r.Callista_Application_Id__c != null &&
                    cd.Application__r.Status__c == 'Submitted') {
                    submittedAppConDocs.put(cd.Id, cd);
                    uniqueAppIds.add(cd.Application__r.Id);
                }
            }
            Set<String> uniqueContactIds = new Set<String>(cDToContactMap.values());
            List<String> contactIds = new List<String>(uniqueContactIds);
            List<Id> appIds = new List<Id>(uniqueAppIds);
            //Query Apps/Opportunities
            if (submittedAppConDocs.size() > 0) {
                // get the related Applications
                List<Application__c> listApps = [
                    SELECT Callista_Applicant_Id__c, Applicant__c, Applicant__r.bulkapi_Applicant_Ids__c
                    FROM Application__c
                    WHERE Applicant__c IN :contactIds
                    AND Id IN :appIds
                    AND Callista_Application_Id__c != null
                    AND Callista_Application_Id__c != ''
                    AND Status__c = 'Submitted'
                ];
                //Related offer/quote records - pull all quote's line items related to acp from Application
                //add AApplication_Course_Preference__r.Application__r.Callista_Application_Id__c query match to trigger it for records 
                //after application submission.Removed Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c as this won't
                //be available for VTAC/callista created Applications
                List<Opportunity> opportunityList = [
                    SELECT Id, PrimaryContact__c, PrimaryContact__r.Person_ID__c, (
                        SELECT Id, Application_Course_Preference__r.Application__c,
                            Application_Course_Preference__r.Application__r.Callista_Application_Id__c,
                            Application_Course_Preference__c, Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c,
                            Application_Course_Preference__r.Application__r.Applicant__r.bulkapi_Applicant_Ids__c
                        FROM OpportunityLineItems
                        WHERE Application_Course_Preference__c != null
                        AND Application_Course_Preference__r.Application__c != null
                        AND Application_Course_Preference__r.Application__r.Id in :appIds
                        AND Application_Course_Preference__r.Application__r.Callista_Application_Id__c != null
                        ORDER BY LastModifiedDate ASC
                    )
                    FROM Opportunity
                    WHERE PrimaryContact__c IN :contactIds
                ];

                Map<id, String> contactToCallistaApplicantIdMap = new Map<id, string>();
                //Non-offer/quote related documents
                for (Application__c appVar : listApps) {
                    String applicantId = appVar.Callista_Applicant_Id__c != null ? appVar.Callista_Applicant_Id__c :
                        StudFirst_SubmitApplicationHelper.parseApplicantId(appVar.Callista_Applicant_Id__c, appVar.Applicant__r.bulkapi_Applicant_Ids__c);
                    contactToCallistaApplicantIdMap.put(appVar.Applicant__c, applicantId);
                }

                //Offer/quote related documents         
                for (Opportunity loopOpportunity : opportunityList) {
                    //Retrieve callista applicant id from the application record associated to the quote line's acp's application record
                    if (loopOpportunity.OpportunityLineItems != null) {
                        for (OpportunityLineItem loopOpportunityLine : loopOpportunity.OpportunityLineItems) {
                            String applicantId = loopOpportunityLine.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c != null ? loopOpportunityLine.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c :
                                StudFirst_SubmitApplicationHelper.parseApplicantId(loopOpportunityLine.Application_Course_Preference__r.Application__r.Callista_Applicant_Id__c, loopOpportunityLine.Application_Course_Preference__r.Application__r.Applicant__r.bulkapi_Applicant_Ids__c);

                            //Attach the document to be uploaded to the latest application with its callista applicant id field returned
                            contactToCallistaApplicantIdMap.put(loopOpportunity.PrimaryContact__c, applicantId);
                        }
                    }
                }

                if (listApps.size() > 0 || !opportunityList.isEmpty()) {

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
                        WHERE LinkedEntityId IN :submittedAppConDocs.keySet()
                    ]) {
                        mapContentDocumentLink.put(cdl.LinkedEntityId, cdl);
                        setContentDocIds.add(cdl.ContentDocumentId);
                    }
                    //Query all the ContentDocument
                    Map<Id, ContentDocument> mapContentDocument = new Map<Id, ContentDocument> ([
                        SELECT
                            id,
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
                        WHERE id IN :setContentDocIds
                    ]);
                    //Send the Contact documents to Callista
                    List<FileToCallistaInterface> listFCI = new List<FileToCallistaInterface>();
                    List<Contact_Document__c> lstContactDocumentRec = new List<Contact_Document__c>();
                    List<Exception_Log__c> lstLogs = new List<Exception_Log__c> ();
                    for (Contact_Document__c cd : submittedAppConDocs.values()) {
                        String contactDocRec = JSON.serialize(cd);
                        ContentDocumentLink cdl = mapContentDocumentLink.get(cd.Id);
                        String cdlRec = JSON.serialize(cdl);
                        String cdRec = JSON.serialize(mapContentDocument.get(cdl.ContentDocumentId));
                        FileToCallistaInterface fci = new FileToCallistaInterface(contactDocRec, cdlRec, cdRec, contactToCallistaApplicantIdMap.get(cDToContactMap.get(cd.id)), null);
                        //Add Content Document instances to List, for updating later
                        if (fci.jsonRequest != null) {
                            lstContactDocumentRec.add(fci.contactDocumentRec);
                        }
                        fci.sendMessage();
                        listFCI.add(fci);
                    }
                    // update Content Documents with the API Request
                    if (!lstContactDocumentRec.isEmpty()) {
                        update lstContactDocumentRec;
                    }

                    // Handle response for each call out
                    lstContactDocumentRec.clear();
                    for (FileToCallistaInterface fci : listFCI) {
                        fci.handleResponse();
                        if (fci.httpResponseCode == 200 && fci.jsonRequest != null) {
                            lstContactDocumentRec.add(fci.contactDocumentRec);
                        }
                        // capture all the logs of the callout
                        lstLogs.addAll(fci.logs);
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

                //Offer/quote related documents                
                for (Opportunity loopOpportunity : opportunityList) {
                    contactToCallistaApplicantIdMap.put(loopOpportunity.PrimaryContact__c, loopOpportunity.PrimaryContact__r.Person_ID__c);
                }
            }
        } catch (Exception ex) {
            Exlog.add('Apex Class', 'SendContentDocQueuable', 'execute', ex + ' - ' + ex.getLineNumber());
        }
    }
}