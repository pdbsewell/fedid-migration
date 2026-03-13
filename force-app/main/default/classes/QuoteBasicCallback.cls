/**
* @author Richard Cook
* @description Basic class which implements SBQQ.CalculateCallback . This performs save and updates API response time only
*/ 
global class QuoteBasicCallback implements SBQQ.CalculateCallback{
    @TestVisible private CPQ_ApiDataModels.QuoteModel quoteModel;
    global void callback(String quoteJSON)
    {
        try
        {
            system.debug('## in CPQ callback');
            this.quoteModel = (CPQ_ApiDataModels.QuoteModel) JSON.deserialize(quoteJSON, CPQ_ApiDataModels.QuoteModel.class);
            this.quoteModel.record.Calculate_API_Response_Time__c = Datetime.now();
            CPQ_ApiDataModels.QuoteModel quoteModel = CPQ_APIService.save(this.quoteModel); 
            system.debug('## complete CPQ callback');


        }catch(Exception e)
        {
            LogUtilityException.logException(e);
        }
    }
}