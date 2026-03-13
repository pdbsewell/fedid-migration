/**
* @author David Browaeys
* @group Offer
* @description This queueable job is mean to handle cancellation/rejection/expired of single offer to docusign
*/
public without sharing class QuoteExpiryQueueable implements Queueable , Database.AllowsCallouts{
    private SBQQ__Quote__c quote;
    public DocuSignEnvelopExpiry envelopExpiry;

    public QuoteExpiryQueueable(DocuSignEnvelopExpiry envelopExpiry, SBQQ__Quote__c quote){
        this.envelopExpiry = envelopExpiry;
        this.quote = new SBQQ__Quote__c(
            id = quote.Id, 
            Primary_DocuSign_Envelop_Id__c= quote.Primary_DocuSign_Envelop_Id__c
        );
    }
    
    public void execute(QueueableContext context) {
        Dao quoteDao = new SObjectDao();
        Boolean inError = false;
        try{    //assuming the quote passed is already expired manually by the end user we only want to expire in docusign
            // DocusignVoidEnvelop(quote.Primary_DocuSign_Envelop_Id__c)
            this.envelopExpiry.expire(quote.Primary_DocuSign_Envelop_Id__c);  
        }catch(Exception e){
            inError = true;
            this.quote.Error_Log__c = 'Technical Error - Expired quote failed :\n' + e.getMessage();
        }finally{
            if (inError == false) {
                quote.Status_When_Offer_Expired__c = quote.SBQQ__Status__c;
                quote.Docusign_Expiry_Time__c = Datetime.now();
            }
            SBQQ.TriggerControl.disable();
            quoteDao.updateRecords(new SObject[]{this.quote});
            SBQQ.TriggerControl.enable();
        }
    }
}