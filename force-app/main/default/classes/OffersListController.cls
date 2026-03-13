/**
 * @description Controller for OffersList component
 * @group Offers
 */
public with sharing class OffersListController {

    /**
     * @description Generates and returns a DocuSign signing URL
     * Throws an AuraException if there are any errors
     * @param quoteId Quote Id for the quote where te signing URL needs to be 
     * generated against
     * @return Return url as a string that can be used for redirection
     */
    //@AuraEnabled
    public static String getSigningUrl(String quoteId){
        QuotesSelector quotesSelector = new QuotesSelector();
        Dao quoteDao = new SObjectDao();
        try {
            OffersExistingDSEnvelopSigningUrl offersExistingDSEnvelopSigningUrl = 
            new OffersExistingDSEnvelopSigningUrl(
                quotesSelector, 
                new DocuSignGetSigningUrlRestApiRequest()
            );
            return offersExistingDSEnvelopSigningUrl.getSigningUrl(
                Id.valueOf(quoteId)
            );
        } catch (Exception e) {
            Group[] techQueue = [SELECT Id, Name, Type 
                                FROM Group 
                                WHERE Type = 'Queue'
                                AND DeveloperName =: Constants.TECHNICAL_OFFER_QUEUE
                                LIMIT 1];
            SBQQ__Quote__c quote =  quotesSelector
                .selectQuoteById(new Set<String>{quoteId})[0];
            quote.Sub_Status__c = 'DocuSign error';
            quote.Error_Log__c= 'DocuSign Signing URL for offers list failed: ' 
                + e.getMessage() + ', ' + e.getStackTraceString(); 
            quote.OwnerId = techQueue[0].Id;
            quoteDao.updateRecords(new List<SBQQ__Quote__c> {quote});
            // Temporary error message, there will be a future user story to 
            // update this
            throw new AuraException('Unable to proceed for signing, please try again.');
        }
    }

}