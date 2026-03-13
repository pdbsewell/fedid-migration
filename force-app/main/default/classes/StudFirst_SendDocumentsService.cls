/*******************************************************************************
 * @author      Ant Custodio
 * @date         12.Sept.2017     
 * @description  Web service for sending a notification to MIX to send a new
  document to Callista
 * @revision     Suman Gunaganti(2019-07-05): (SF-2781) Removed Application Document provided object reference 
 *******************************************************************************/
global class StudFirst_SendDocumentsService {

    private static final String AGENT_PERSON_ID = Label.CALLISTA_AGENT_PERSON_ID;
    private static final String API_SOURCE = 'unicrm';
    private static final String API_TYPE = 'document';

    /*******************************************************************************
     * @author      Ant Custodio
     * @date         13.Sept.2017     
     * @description  Method that accepts a single Application Id that can be called
      if we want to submit documents to Callista (Through MIX)
     * @revision     
     *******************************************************************************/
    WebService static void sendToCallistaByAppId(String appId) {
    System.debug('Sending documents initiated');
        if (appId != '') {
            sendToCallistaByAppIds(new Set<String> { appId });
        }
    }

    /*******************************************************************************
     * @author      Majid Reisi Dehkordi
     * @date         20.Nov.2018
     * @description  Method that accepts a set of application Ids that can be called
      if we want to submit documents to Callista (Through MIX)
     * @revision
     *******************************************************************************/
    public static void sendToCallistaByAppIds(Set<String> appIds) {
        List<ContentDocumentLink> cdlsThatAreLinkedToApps = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :appIds];
        List<id> fileIds = new List<id> ();

        for (ContentDocumentLink cdlVar: cdlsThatAreLinkedToApps)
            fileIds.add(cdlVar.ContentDocumentId);
        
        List<ContentDocumentLink> cdlsThatAreLinkedToContactDocuments = new List<ContentDocumentLink>();
        if(!fileIds.isEmpty())
        {
            cdlsThatAreLinkedToContactDocuments = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :fileIds];
            System.debug('cdlsThatAreLinkedToContactDocuments');
            System.debug(cdlsThatAreLinkedToContactDocuments);
        }

        List<id> contactDocumentsIds = new List<id> ();
        for (ContentDocumentLink cdlVar: cdlsThatAreLinkedToContactDocuments)
        {
            contactDocumentsIds.add(cdlVar.LinkedEntityId);
        }

        System.debug('contactDocumentsIds');
        System.debug(contactDocumentsIds);
            
        if(!contactDocumentsIds.isEmpty())
        {
            System.debug('There are some contact documents that are linked to this application.');
            List<Contact_Document__c> listOfNotTransferredContactDocuments = [SELECT Id FROM Contact_Document__c WHERE Id IN :contactDocumentsIds and Document_Status__c = false];
            System.debug('listOfNotTransferredContactDocuments');
            System.debug(listOfNotTransferredContactDocuments);
            if(!listOfNotTransferredContactDocuments.isEmpty())
            {
                ContactDocumentPostAppPB.QueueFileToSend(new List<id>((new Map<id, Contact_Document__c>(listOfNotTransferredContactDocuments)).keySet()));
                System.debug('Send the following documents');
                System.debug(new List<id>((new Map<id, Contact_Document__c>(listOfNotTransferredContactDocuments)).keySet()));
            }
        }
    }
}