/**
 * @author David Browaeys
 * @group Offers
 * @description This controller sync offer extension date with offer lapse date of related acp's
 */
public with sharing class OfferExtensionController {
    /**
     * @description Invocable method to available for process builder that will kick off the offer lapse date sync 
     * @param offerIds list of opportunity id's
     */
    @InvocableMethod
    public static void updateACPOffersLapsedDate(ID[] offerIds) {
		if (offerIds != null && offerIds.isEmpty() == false) new OfferExtensionController(offerIds).execute();        
    }
    
    public OpportunitiesSelector selector;
    public Map<ID, Application_Course_Preference__c> acps;
    public Map<ID, Opportunity> offers;
    public ID[] offerIds;
    public Dao acpDao;
    /**
     * @description OfferExtensionController Constructor
     */
    public OfferExtensionController(ID[] offerIds){
		this.offerIds = offerIds;
    	this.selector = new OpportunitiesSelector();
        this.acps = new Map<ID, Application_Course_Preference__c>();
        this.acpDao = new SObjectDao();
    }
    /**
     * @description Main method that fetch the opportunities details and execute the offer lapse date sync
     */
    public void execute(){
        if (this.offerIds != null && this.offerIds.isEmpty() == false){
			this.offers = new Map<ID, Opportunity>(this.selector.selectByIdWithOpportunityLines(new Set<ID>(this.offerIds)));
            setAcps();
            finalise();
        }
    }
	/**
     * @description This method find all acp under each offer and set offer lapse date from updated offer extension date
    */
    public void setAcps(){
        for (Opportunity o : this.offers.values()){
            for (OpportunityLineItem oli : o.OpportunityLineItems){
                System.debug('@@@ Update Offer Lapsed Date : '+o.Offer_Extension_Date__c);
                if (oli.Application_Course_Preference__c != null && o.Offer_Extension_Date__c != null){
	                this.acps.put(oli.Application_Course_Preference__c, new Application_Course_Preference__c(
                    	Id = oli.Application_Course_Preference__c,
                        Offer_Response_Date__c = o.Offer_Extension_Date__c
                    ));
                }
            }
        }
    }
    /**
     * @description update all acps
     */
    public void finalise(){
        if (acps.isEmpty() == false) this.acpDao.updateRecords(acps.values());
    }
}