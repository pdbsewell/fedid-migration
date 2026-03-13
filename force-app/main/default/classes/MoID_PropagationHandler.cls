public without sharing class MoID_PropagationHandler implements Queueable, Database.AllowsCallouts {

    private List<Id> contactIds;
    private Integer retryCount;
    
    // Limits
    private static final Integer CHUNK_SIZE = 50; 
    private static final Integer MAX_RETRIES = 3;

    // Inner class to pass back both the status and the specific error message
    private class CalloutResult {
        public Boolean isSuccess;
        public String errorMessage;
        
        public CalloutResult(Boolean isSuccess, String errorMessage) {
            this.isSuccess = isSuccess;
            this.errorMessage = errorMessage;
        }
    }

    // 1. Initial Constructor
    public MoID_PropagationHandler(Set<Id> ids) {
        this.contactIds = new List<Id>(ids);
        this.retryCount = 0; 
    }

    // 2. Internal Constructor for Chaining and Retrying
    public MoID_PropagationHandler(List<Id> ids, Integer currentRetryCount) {
        this.contactIds = ids;
        this.retryCount = currentRetryCount;
    }

    public static void propagateAsync(Set<Id> ids) {
        if (ids != null && !ids.isEmpty()) {
            System.enqueueJob(new MoID_PropagationHandler(ids));
        }
    }

    public void execute(QueueableContext context) {
        if (contactIds == null || contactIds.isEmpty()) return;

        List<Id> chunkToProcess = new List<Id>();
        List<Id> remainingIds = new List<Id>();
        List<Id> failedIds = new List<Id>(); 
        Map<Id, String> errorDetailsMap = new Map<Id, String>(); 

        // Split the list into the current chunk and the remainder
        for (Integer i = 0; i < contactIds.size(); i++) {
            if (i < CHUNK_SIZE) {
                chunkToProcess.add(contactIds[i]);
            } else {
                remainingIds.add(contactIds[i]);
            }
        }

        // Query and process only the current chunk
        List<Contact> contacts = [
            SELECT Id, Person_ID_unique__c, Monash_Object_Id__c
            FROM Contact 
            WHERE Id IN :chunkToProcess
        ];

        for (Contact c : contacts) {
            if (String.isBlank(c.Person_ID_unique__c) || String.isBlank(c.Monash_Object_Id__c)) continue;
            
            CalloutResult result = sendToMiX(c.Person_ID_unique__c, c.Monash_Object_Id__c);
            
            if (!result.isSuccess) {
                failedIds.add(c.Id); 
                errorDetailsMap.put(c.Id, result.errorMessage); 
            }
        }

        // Evaluate Retries & Logging
        if (!failedIds.isEmpty()) {
            if (retryCount < MAX_RETRIES) {
                remainingIds.addAll(failedIds);
                retryCount++; 
            } else {
                // Max retries hit. Pass to Nebula Logger.
                logPermanentFailures(failedIds, errorDetailsMap);
            }
        }

        // Commit any logs generated during this transaction before chaining
        Nebula.Logger.saveLog();

        // Chain the next job with the remaining IDs and the updated retry count
        if (!remainingIds.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new MoID_PropagationHandler(remainingIds, retryCount));
        }
    }

    private CalloutResult sendToMiX(String bannerId, String moid) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setTimeout(10000); 
        req.setEndpoint('callout:MiX_Experience_API/admissions/sms/persons/' + bannerId + '/monash-object-id');        
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, String>{ 'monashObjectID' => moid }));

        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                return new CalloutResult(true, 'Success'); 
            } else {
                String errorMsg = 'HTTP ' + res.getStatusCode() + ' Error: ' + res.getBody();
                return new CalloutResult(false, errorMsg); 
            }
        } catch (Exception e) {
            String errorMsg = 'Apex Callout Exception: ' + e.getMessage();
            return new CalloutResult(false, errorMsg); 
        }
    }

// Updated to use Nebula Logger with namespace
    private void logPermanentFailures(List<Id> failedContactIds, Map<Id, String> errorDetailsMap) {
        for (Id contactId : failedContactIds) {
            String specificError = errorDetailsMap.containsKey(contactId) ? errorDetailsMap.get(contactId) : 'Unknown Error';
            
            String logMessage = 'MoID Propagation via MiX permanently failed after ' + MAX_RETRIES + ' retries. Latest Error: ' + specificError;
            
            // Log the error and associate it directly with the Contact record
            Nebula.Logger.error(logMessage, contactId);
        }
    }
}