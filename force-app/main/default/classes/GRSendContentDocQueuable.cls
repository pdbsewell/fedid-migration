/*******************************************************************************
    * @author       Sethu Venna
    * @date         05/09/2024
    * @description  Queuable to submit contact documents to Callista
    * @revision     05/10/2024 - Initial Version
*******************************************************************************/
public class GRSendContentDocQueuable implements Queueable, Database.AllowsCallouts, finalizer
{
    private Id conDocId;
    private set<Id> totalConDocId;

    /*******************************************************************************
    * @author       Sethu Venna
    * @date         05/09/2024
    * @description  constructor for the class
    * @param        conDocIdSet
    * @revision     05/10/2024 - Initial Version
    *******************************************************************************/
    public GRSendContentDocQueuable(Set<Id> totalConDocIdSet)
    {
        for(Id conDocId : totalConDocIdSet) 
        {
            this.conDocId = conDocId; // to be processed
            totalConDocIdSet.remove(this.conDocId); // list of total, less to be processed
            this.totalConDocId = totalConDocIdSet;
            break;
        }
    }
    /*******************************************************************************
    * @author       Sethu Venna
    * @date         05/09/2024
    * @description  execute methiod to invoke callout and update doc Id from Callista on Contact document record
    * @param        context of the executable
    * @revision     05/10/2024 - Initial Version
    *******************************************************************************/
    public void execute(QueueableContext context) {
        try {
           
            Set<Id> conDocIdSet = new Set<Id>{conDocId};
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
                if(totalConDocId.isEmpty()) 
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
                else {
                    System.enqueueJob(
                        new GRSendContentDocQueuable(totalConDocId)
                    );
                }
            }
        }
        catch(Exception ex)
        {
            Nebula.Logger.error(ex.getMessage(), ex);
        }
        System.attachFinalizer(this);
    }
    /*******************************************************************************
    * @author       Sethu Venna
    * @date         28/01/2025
    * @description  execute methiod to finalize and log exceptions
    * @param        context of the executable
    * @revision     28/01/2025 - Initial Version
    *******************************************************************************/
    public void execute(FinalizerContext context) {
        Nebula.Logger.saveLog();
    }

}