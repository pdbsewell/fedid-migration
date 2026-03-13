/**
 * @author      JM Mapanao
 * @description Service class for dmsFileList lwc
 * @group       Apex Class
 * @revision    17.SEP.2020 - JM Mapanao - Created
 */
public with sharing class DMSFileService {
    public DMSFileService() {}

    /**
     * @description Callout to AWS to get documents
     */
    @AuraEnabled(continuation=true cacheable=true)
    public static Object getDocuments(String contactId) {
        List<Contact> contactList = [SELECT Id, Person_ID_unique__c FROM Contact WHERE Id =: contactId];
        ContinuationService continuationItem = new ContinuationService('Monash_DMS_Documents');

        // Return error when no contact id or person id found
        if (contactList == null || contactList.isEmpty() || String.isBlank(contactList.get(0).Person_ID_unique__c)) {
            Map<String, Object> resultMap = new Map<String, Object>();
            resultMap.put('state', 'error');
            resultMap.put('statusCode', '404');
            resultMap.put('message', 'Invalid person id');
            return resultMap;
        }
        //build parameter details
        Map<String, String> parametersMap = new Map<String, String>{'{personId}' => contactList[0].Person_ID_unique__c};
        //configure continuation callout
        continuationItem.constructEndPoint(parametersMap);
        continuationItem.setupContinuation(60, '', 'processAllResponses', null);

        //Return the continuation
        return continuationItem.retrieveContinuation();
    }

    // Callback method.
    // Invoked only when responses of all callouts are returned.
    @AuraEnabled(cacheable=true)
    public static Object processAllResponses(List<String> labels, Object state) {
        //Initialize results map
        Map<String, Object> resultMap = new Map<String, Object>();
        // Get the response of the first request
        HttpResponse res = Continuation.getResponse(labels[0]);
        System.debug(LoggingLevel.DEBUG, '##### res:' + String.valueOf(res.getBody()));
        if(res.getStatusCode() == 200) {
            String jsonResponse = String.valueOf(res.getBody());
            List<DocumentDetails> documentList = (List<DocumentDetails>) JSON.deserialize(jsonResponse, List<DocumentDetails>.class);
            resultMap.put('state', 'success');
            resultMap.put('statusCode', res.getStatusCode());
            resultMap.put('docList', documentList);
        } else {
            resultMap.put('state', 'error');
            resultMap.put('statusCode', res.getStatusCode());
            resultMap.put('message', String.valueOf(res.getBody()));
        }
        return resultMap;
    }

    public class DocumentDetails {
        @AuraEnabled
        public String category {get;set;}
        @AuraEnabled
        public String subCategory {get;set;}
        @AuraEnabled
        public String personId {get;set;}
        @AuraEnabled
        public String location {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String createdDate {get;set;}
        @AuraEnabled
        public String extension {get;set;}
        @AuraEnabled
        public Integer size {get;set;}
    }
}