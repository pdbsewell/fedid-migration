/**
 * @File Name          : OfferWizardWrapper.cls
 * @Description        : wrapper class that holds offer wizard object values
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 5/26/2020, 8:33:08 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/26/2020   jasmin.rudio@monash.edu     Initial Version
**/
public class OfferWizardWrapper {
    public OfferWizardWrapper(){}
    public Opportunity opptyRecord;   
    public List<Application_Course_Preference__c> selectedACPList; 
    public List<PricebookEntry> additionalProducts;
    public List<MirrorClauseServices.MirrorClauseWrapper> selectedClauses;
    public Map<String, String> additionalACPClauses;
    public Map<String, String> additionalBahasaACPClauses;
    public String bahasaOfferCondition;

    
    public Map<String, Course_Offering__c> courseOfferingByAcpId;
    public Date offerLapsedDate;
    public Map<ID,Application_Course_Preference__c> updatedACPs;

}