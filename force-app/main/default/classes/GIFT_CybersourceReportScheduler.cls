public class GIFT_CybersourceReportScheduler implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts {
    public void execute(SchedulableContext SC) {
        database.executeBatch(new GIFT_CybersourceReportScheduler(), 1);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) 
    { 
        // Query with date returned
        return Database.getQueryLocator(
              'select Id from Opportunity where name = \'THIS IS JUNK DONT WANT TO FIND ANYTHING HERE\' LIMIT 1'); 
    }

    public void execute(Database.BatchableContext info, List<SObject> opportunities) {}

    public void finish(Database.BatchableContext info) { 
    	// Callout
        ucinn_ascendv2.ascend_Gift_CyberSourceReportFetcher.runReportFetcher();
    }
}