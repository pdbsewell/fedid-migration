/**
* @author David Browaeys
* @date 21/05/2020
* @group SF Offer
* @description This class handle callback for cpq calculate api
*/
global class QuoteCreationCallback implements SBQQ.CalculateCallback{
    @TestVisible private CPQ_ApiDataModels.QuoteModel quoteModel;
    @TestVisible private Opportunity opp;
    @TestVisible private List<String> results;
    global void callback(String quoteJSON){
        try{
            this.quoteModel = (CPQ_ApiDataModels.QuoteModel) JSON.deserialize(quoteJSON, CPQ_ApiDataModels.QuoteModel.class);
            this.results = CPQ_APIService.validate(this.quoteModel);
            handleValidateResponse();
            commitAll();
        }catch(Exception e){
            LogUtilityException.logException(e);
            if (this.quoteModel != null){
                handleError(e.getTypeName() + ' - ' + e.getCause() + ' - ' + e.getLineNumber() + '\n\n' + e.getMessage() +'\n\n'+ e.getStackTraceString());
                this.quoteModel.record.OwnerId = QuoteService.techQueue[0].Id;
                update this.quoteModel.record;
                if (opp.Id != null) update opp;
            }
        }
    }
    global void handleValidateResponse(){
        //To do check if this is first quote generated.
        this.quoteModel.record.SBQQ__Primary__c = true;
        this.quoteModel.record.Calculate_API_Response_Time__c = Datetime.now();
        if (this.results == null || this.results.isEmpty() == true){
            handleSuccess();
        }else{                 
            handleError(String.join(this.results,'\n'));
        }
    }
    global void handleSuccess(){
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        this.quoteModel = CPQ_APIService.save(this.quoteModel); 
        TriggerCommon.enableTrigger('SBQQ__Quote__c');

        this.quoteModel.record.Sub_Status__c = 'Pricing Completed'; 
        this.opp =  new Opportunity(
            Id = this.quoteModel.record.SBQQ__Opportunity2__c, 
            SBQQ__PrimaryQuote__c = this.quoteModel.record.Id,
            NextStep = this.quoteModel.record.Sub_Status__c
        );
    }
    global void handleError(String errorMessage){
        // Update Quote substatus, Error log and assign the quote to the technical error queue                  
        this.quoteModel.record.Sub_Status__c='Offer creation/update error'; 
        this.quoteModel.record.Sub_status_changed_on__c = system.now();
        this.quoteModel.record.Error_Log__c = 'Technical error during pricing calculation : \n\n' + errorMessage; 
        QuoteService.assignQuoteToBusinessQueue(this.quoteModel.record);

        this.opp = new Opportunity();
        opp.Id = this.quoteModel.record.SBQQ__Opportunity2__c;
        opp.SBQQ__PrimaryQuote__c = this.quoteModel.record.Id;
        opp.StageName = 'Specialist Review';
        opp.NextStep = '';
    }
    public void commitAll(){
        SBQQ.TriggerControl.disable();
        update this.quoteModel.record;
        update opp;
        SBQQ.TriggerControl.enable();
    }
}