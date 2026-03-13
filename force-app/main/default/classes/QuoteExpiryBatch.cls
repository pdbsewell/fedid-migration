/**
* @author David Browaeys
* @group Offer
* @description This batch make a callout to docusign for all quote that need to expire today 
*/
public class QuoteExpiryBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts{
    public OffersDocuSignEnvelopExpiry envelopExpiry;
    
    public QuoteExpiryBatch(){}
    
    public QuoteExpiryBatch(OffersDocuSignEnvelopExpiry envelopExpiry) {
        this.envelopExpiry = envelopExpiry;
    }

    public void execute(SchedulableContext ctx){
        Database.executeBatch(new QuoteExpiryBatch(new OffersDocuSignEnvelopExpiry(new DocuSignUpdateEnvelopRestApiRequest())) , 50);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Error_Log__c, SBQQ__Status__c, Docusign_Expiry_Time__c, Primary_DocuSign_Envelop_Id__c FROM SBQQ__Quote__c WHERE Docusign_Expiry_Time__c = NULL AND SBQQ__ExpirationDate__c <= YESTERDAY AND SBQQ__Status__c = \'Published\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> scope) {
        for (SBQQ__Quote__c quote : scope) {
            Boolean inError = false;
            try{    //expire quote through docusign
                if (quote.Primary_DocuSign_Envelop_Id__c != null) this.envelopExpiry.expire(quote.Primary_DocuSign_Envelop_Id__c);
            }catch(Exception e){    //something went wrong
                quote.Error_Log__c = 'Tehnical Error - Expired quote failed :\n' + e.getMessage();
                inError = true;
            }finally{
                if(inError == false){
                    QuoteService.updateQuoteForExpiry(quote);
                    quote.SBQQ__Status__c = 'Expired';
                    quote.Sub_Status__c = 'Total offer expired';
                }
            }
        }
        commitAll(scope);
    }

    @testVisible private void commitAll(SBQQ__Quote__c[] scope){
        SBQQ.TriggerControl.disable();
        Database.SaveResult[] results = Database.update(scope,false);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess() == false){
                LogUtilityException.addLogEvent('SBQQ__Quote__c',scope[i],results[i].getErrors(),'Quote Batch Expiry');
            }
        }
        SBQQ.TriggerControl.enable();
    }

    @testVisible private void updateQuoteForExpiry(SBQQ__Quote__c quote){
        quote.Status_When_Offer_Expired__c = quote.SBQQ__Status__c;
        quote.Expiry_Status_Date__c = Date.today();
        quote.SBQQ__Status__c = 'Expired';
        quote.Docusign_Expiry_Time__c = Datetime.now();
    }

    public void finish(Database.BatchableContext BC) {
        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID =: BC.getJobId()];

        Exception_Log__c sobj = new Exception_Log__c(
            Exception_Type__c = 'BATCH INFO',     // Exception Type
            Function_Name__c = 'QuoteExpiryBatch',  // Function Name
            Object_Name__c = 'SBQQ__Quote__c',      // Object Name
            Message__c = 
                '--Batch Resutls\n'+
                'Status = '+ job.Status +'\n'+
                'Total Job Items = ' + job.TotalJobItems + '\n'+
                'Job Items Processed = ' + job.JobItemsProcessed + '\n'+
                'Number Of Errors = '+ job.NumberOfErrors + '\n'
        );
        insert sobj;
    }
}