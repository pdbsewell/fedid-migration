public class MoID_BackfillBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Monash_Object_Id__c 
            FROM Contact 
            WHERE Monash_Object_Id__c = null
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        MoID_Service.ensureMoIDs(scope);
        update scope;
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('MoID Backfill Batch has finished processing.');
    }
}