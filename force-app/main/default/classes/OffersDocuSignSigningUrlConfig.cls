/**
 * @description Configuration for Offer's DocuSign Get Signing URL
 * @group Offers Get Signing URL
 */
public inherited sharing class OffersDocuSignSigningUrlConfig {

    /**
     * @description Returns the DocuSign Return URL that is used for the 
     * docuSign Signer redirection back to Salesforce communities
     * @return DocuSign return URL as a string
     */
    public String getDocuSignReturnUrl() {
        Offer_Setting__c offerSetting = Offer_Setting__c.getOrgDefaults();
        // Return URL Path could be optional
        // This ensures null is not appended if the value was not set
        String returnUrlPath = String.isBlank(offerSetting.DocuSign_Return_URL_Path__c) ? '' : offerSetting.DocuSign_Return_URL_Path__c;
        return offerSetting.DocuSign_Base_Return_URL__c + '/' + returnUrlPath;
    }

}