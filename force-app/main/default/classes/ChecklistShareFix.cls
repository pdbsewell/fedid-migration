/**
 * Created by trentdelaney on 14/7/20.
 */

global class ChecklistShareFix implements Database.Batchable<sObject>{

    public void execute(Database.BatchableContext BC, List<Document_Checklist__c> items) {
        for(Document_Checklist__c doc : items){
            doc.OwnerId = doc.Application__r.OwnerId;
        }
        try{
            update items;
        }
        catch(Exception e){
            System.debug(e);
        }
    }

    public void finish(Database.BatchableContext param1) {
    }

    public Iterable<sObject> start(Database.BatchableContext param1) {
        List<User> users = [SELECT Id, Username FROM User WHERE Username LIKE 'autoproc%'];
        return Database.getQueryLocator([SELECT OwnerId, Application__r.OwnerId FROM Document_Checklist__c WHERE OwnerId = :users[0].Id]);
    }
}