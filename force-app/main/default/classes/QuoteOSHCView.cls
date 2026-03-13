/**
* @author Richard Cook
* @group SF Offer
* @description View representation of the Quote OSHC information to be presented on community portal and retrieved via FormPageService
*/
   public class QuoteOSHCView
    {
        @AuraEnabled
        public Boolean isLocked {get; set;}
        @AuraEnabled
        public string selectedProvider {get; set;}
        @AuraEnabled
        public string selectedProviderName {get; set;}
        @AuraEnabled
        public string selectedHealthOption {get; set;}
        @AuraEnabled
        public string bundleQuoteLineId {get; set;}
        @AuraEnabled
        public List<FormPageService.option> providerOptions {get; set;}
        @AuraEnabled
        public List<FormPageService.priceOption> coverOptions {get; set;}

    /**
        * @author Richard Cook
        * @description retrieve OSHC related information for quote selection on community portal
        * @param quoteId Id - record which is requested
        * @param queryForUpdate Boolean - request to update the record
        * @return QuoteOSHCView
        */ 
        public QuoteOSHCView(Id quoteId, Boolean queryForUpdate)
        {
            
            SBQQ__Quote__C q = new QuotesSelector().getHealthOptions(quoteId, queryForUpdate);
            selectedProvider = q.Health_Cover_Provider_Type__c;
            selectedProviderName = q.Health_Cover_Provider_Name__c;
            isLocked = true;

            Boolean canEdit = q.SBQQ__Status__c == Constants.QUOTE_STATUS_PUBLISHED && 
            q.SBQQ__Status__c != Constants.QUOTE_STATUS_ACCEPTED &&
            !Constants.QUOTE_OFFER_SUBSTATUSES_READONLY.contains(q.Sub_Status__c) && 
            q.Acknowledged_by_applicant__c == false;
            if(canEdit)
            {
                isLocked = false;
            }         
            setcoverOptions(q);
            setproviderOptions();
        }

        @testVisible private void setcoverOptions(SBQQ__Quote__C q)
        {
            coverOptions = new List<FormPageService.priceOption>();
            List<SBQQ__QuoteLine__c> qList = q.SBQQ__LineItems__r;
            for(SBQQ__QuoteLine__c row : qList)
            {
                if(row.SBQQ__RequiredBy__c == null)
                {
                    selectedHealthOption = row.Health_Cover_Type__c;
                    bundleQuoteLineId = row.Id;
                } else {
                    coverOptions.add(new FormPageService.priceOption(row.SBQQ__ProductName__c, row.SBQQ__Product__r.Sub_Family__c, row.SBQQ__NetTotal__c, row.SBQQ__Product__r.Description));
                }
            }            
        }
        @testVisible private void setproviderOptions()
        {
            providerOptions = new List<FormPageService.option>();

            List<Schema.Picklistentry> healthPicklistOptions =  Schema.SBQQ__Quote__C.fields.Health_Cover_Provider_Type__c.getDescribe().getPicklistValues();
            for(Schema.Picklistentry ple : healthPicklistOptions)
            {
                if(ple.isActive())
                {
                    /*Constants.OSHC_CTY_PICKLIST_PREFIX + */
                    providerOptions.add(new FormPageService.option( ple.getLabel(), ple.getValue() ));
                    if(ple.isDefaultValue() && string.isEmpty(selectedProvider))
                    {
                        selectedProvider = ple.getValue();
                    }
                }   
            } 
        }
    }