/**
 * @File Name          : OfferLightningEnabledClass.cls
 * @Description        : 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 3/16/2020, 10:58:56 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/27/2020   jasmin.rudio@monash.edu     Initial Version
**/
public with sharing class OfferLightningEnabledClass {
    public OfferLightningEnabledClass() {}

    @AuraEnabled(cacheable=true)
    public static String fetchAttachment(String attachmentId) {
        return FilesServiceClass.fetchAttachment(attachmentId);
    }

    @AuraEnabled(cacheable = true)
    public static List<FormPageService.FormPage> getFormPage(){
        return FormPageService.getFormPage();
    }
    
    @AuraEnabled(cacheable = true)
    public static List<FormPageService.FormPage> getFormPageList(String apiName){
        return FormPageService.getFormPageList(apiName);
    }

    @AuraEnabled(cacheable = true)
    public static List<FormPageService.FormElement> getChildFormElement(String parentElementId){
        return FormPageService.getChildFormElement(parentElementId);
    }
    
    @AuraEnabled(cacheable = true)
    public static List<Contact> getPrimaryContact(String contactId){
        return FormPageService.getPrimaryContact(contactId);
    }
    
    @AuraEnabled(cacheable = true)
    public static String getBundlePageMap(String parentElementId, String offerId){
        return FormPageService.getBundlePageMap(parentElementId, offerId);
    }

    @AuraEnabled(cacheable = false)
    public static String getProductByIdHiddenPricing(String parentElementId, String offerId){
        return FormPageService.getProductByIdHiddenPricing(parentElementId, offerId);
    }

    @AuraEnabled(cacheable=true)
    public static String getManagedClauseByQuoteId(String quoteId){
        return ManagedClauseService.getManagedClauseByQuoteId(quoteId);
    }
     
    /*@AuraEnabled(cacheable=true)
    public static String getManagedClauseByQuoteLineLocation(String quoteLineId, String location){
        return ManagedClauseService.getManagedClauseByQuoteLineLocation(quoteLineId, location);
    }*/

    @AuraEnabled
    public static String getSigningUrl(String quoteId){
        return OffersListController.getSigningUrl(quoteId);
    }

    @AuraEnabled
    public static SBQQ__Quote__c getOfferDetails(String offerId){   
        return QuoteService.getOfferDetails(offerId);
    }

    @AuraEnabled(cacheable=true)
    public static List<SBQQ__Quote__c> getOfferList(String contactId, String ownerId){
        return QuoteService.getOfferList(contactId, ownerId);
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteService.OfferListWrapper> getCurrentOfferList(String contactId, String ownerId, Integer limitNum, Integer offset){
        return QuoteService.getCurrentOfferList(contactId, ownerId, limitNum, offset);
    }

    @AuraEnabled
    public static Boolean quoteCalculationComplete(Id quoteId){
        return QuoteService.quoteCalculationComplete(quoteId);
    }
    @AuraEnabled
    public static QuoteOSHCView setQuoteOSHCView(FormPageService.HeathQuoteRequest hqr){
        return QuoteService.setQuoteOSHCView(hqr);
    }

    @AuraEnabled
    public static QuoteOSHCView getQuoteOSHCView(Id quoteId, Boolean requestUpdate){
        return QuoteService.getQuoteOSHCView(quoteId, requestUpdate);
    }

    @AuraEnabled(cacheable=true)
    public static List<SBQQ__QuoteLine__c> getQuoteLineList(String offerId){
        return QuoteLineService.getQuoteLineList(offerId);
    }

    @AuraEnabled(cacheable=true)
    public static List<SBQQ__QuoteLine__c> getQuoteLineBundles(String offerId){
        return QuoteLineService.getQuoteLineBundles(offerId);
    }

    @AuraEnabled(cacheable=true)
    public static List<SBQQ__QuoteLine__c> selectByIdHiddenPricing(String offerId){
        return QuoteLineService.selectByIdHiddenPricing(offerId);
    }

    /**
     * AuraEnabled method without cacheable=true can only be used in Imperative callouts in lightning components
     */
    @AuraEnabled//(cacheable=true)
    public static List<SBQQ__QuoteLine__c> selectByQuoteIdAndProductFamily(String offerId, String productFamily){
        String[] familyList = new String[]{productFamily};
        if(productFamily == 'Grant' || productFamily == 'Scholarship'){
            familyList = new String[]{'Grant', 'Scholarship'};
        }
        return new QuoteLinesSelector().selectByQuoteIdAndProductFamily(new Set<Id>{offerId}, familyList);
    }

    @AuraEnabled
    public static String getFirstCourseQuoteLineProductCode(String quoteId) {
        QuoteLinesSelector quoteLinesSelector = new QuoteLinesSelector();
        return quoteLinesSelector.selectFirstCourseQuoteLineProductCodeByQuoteId(Id.valueOf(quoteId));
    }

}