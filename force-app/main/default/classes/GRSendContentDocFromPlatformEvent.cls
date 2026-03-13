/*******************************************************************************
    * @author       Sethu Venna
    * @date         05/09/2024
    * @description  Queuable to submit contact documents to Callista
    * @revision     05/10/2024 - Initial Version
*******************************************************************************/
public class GRSendContentDocFromPlatformEvent
{
    
    /*******************************************************************************
     * @author       Sethu Venna
     * @date         15/10/2024
     * @param        conDocIdSet 
     * @description  execute method to run the doc integration
     * @revision     15/10/2024 - Initial Version
     *******************************************************************************/
    @future(callout=true)
    public static void execute(Set<Id> conDocIdSet ) {
        try
        {
            Map<Id, Contact_Document__c> conDocs = new Map<Id, Contact_Document__c>(
                new ContactDocumentsSelector().selectByIdWithRelatedApplicationDetails(conDocIdSet)
            );
            //populate a map of contact document ID and content documents
            Map<Id, ContentDocumentLink> mapContactDocumentContentDocumentLink = new Map<Id, ContentDocumentLink> ();
            Set<Id> contentDocumentSet = new Set<Id>();
            for (ContentDocumentLink cdl : [SELECT
                                            Id,
                                            ContentDocumentId,
                                            ContentDocument.LatestPublishedVersionId,
                                            ContentDocument.FileExtension, 
                                            LinkedEntityId  
                                            FROM 
                                            ContentDocumentLink 
                                            WHERE LinkedEntityId IN :conDocIdSet
                                            ]) {
                mapContactDocumentContentDocumentLink.put(cdl.LinkedEntityId, cdl);
                contentDocumentSet.add(cdl.ContentDocumentId);
            }
            //populate a map of contact document ID and content documents
            Map<Id, ContentVersion> mapContentDocumentContentVersion = new Map<Id, ContentVersion> ();
            for (ContentVersion cv : [SELECT
                                        Id,
                                        ContentDocumentId,
                                        VersionData
                                        FROM 
                                        ContentVersion 
                                        WHERE ContentDocumentId IN :contentDocumentSet 
                                        AND IsLatest = :true
                                    ]) {
                mapContentDocumentContentVersion.put(cv.ContentDocumentId, cv);
            }
            List<Contact_Document__c> conDocsToUpdate = new List<Contact_Document__c>();
            for(Contact_Document__c cd : conDocs.values())
            {
                ContentDocumentLink cdl = mapContactDocumentContentDocumentLink.get(cd.Id);
                ContentVersion cv = mapContentDocumentContentVersion.get(cdl.ContentDocumentId);
                    GRSendDocumentToCallistaService docSendService = new GRSendDocumentToCallistaService(
                    cd,
                    cdl,
                    cv
                );
                docSendService.createRequestBody();
                docSendService.sendMessage();
                docSendService.handleResponse();
                conDocsToUpdate.add(docSendService.contactDocumentRec);
            }
            if(conDocsToUpdate.size() > 0) 
            {
                update conDocsToUpdate;
                List<Contact_Document__c> conDocWithNoCallistaDocIdList = new ContactDocumentsSelector().selectByApplicationIdWithEmptyCallistaDocId(new Set<Id>{conDocsToUpdate[0].Application__c});
                if(conDocWithNoCallistaDocIdList.isEmpty()) 
                {
                    List<Application__c> appRecordList = new ApplicationsSelector().selectById(new Set<Id>{conDocsToUpdate[0].Application__c});
                    List<Application__c> appRecordListToUpdate = new List<Application__c>();
                    for(Application__c appRecord : appRecordList) 
                    {
                        if(appRecord.GR_Callista_Document_Submission_Date__c == null) 
                        {
                            appRecord.GR_Callista_Document_Submission_Date__c = System.now();
                            appRecordListToUpdate.add(appRecord);
                        }
                    }
                    if(appRecordListToUpdate.size() > 0) 
                    {
                        Database.SaveResult[] srList = Database.update(appRecordListToUpdate, false);
                        for (Database.SaveResult sr : srList) 
                        {
                            if (sr.isSuccess()) 
                            {
                                Nebula.Logger.info('Application Id updated with timestamp '+sr.getId());
                            }
                            else 
                            {              
                                for(Database.Error err : sr.getErrors()) 
                                {
                                    Nebula.Logger.error(err.getMessage());
                                }
                            }
                        }
                    }
                }
            }
        }
        catch(Exception ex)
        {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        Nebula.Logger.saveLog();
    }
}