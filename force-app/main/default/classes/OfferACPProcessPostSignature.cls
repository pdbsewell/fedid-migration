/**
 * This class handle Deferral ACP Update Post Offer Singature
 * @author David Browaeys
 */
public inherited sharing class OfferACPProcessPostSignature {
    
    /**
     * This invocable method is available for opportunity process builder context to kick off acp post offer signat
     * @param  opptyIds list of opportunity ids
     */
    @InvocableMethod(label='Update ACP Post Offer Signature' description='This method update acp once opportunity is set to signed')
    public static void postOfferSignatureACPUpdates(List<ID> opptyIds){
        if (opptyIds != null && opptyIds.isEmpty() == false) new OfferACPProcessPostSignatureService(new OpportunitiesSelector().selectByIdWithOpportunityLines(new Set<ID>(opptyIds))).execute().commitAll();
    } 
    /**
     * @description This inner class update acp deferment status to approved once opportunity is set to signed. 
     */
    public inherited sharing class OfferACPProcessPostSignatureService{
        Opportunity[] oppties;
        Dao acpDao;
        @TestVisible Map<ID, Application_Course_Preference__c> acps;
        /**
         * Constructor for OfferACPProcessPostSignatureService
         * @param  oppties list of signed opportunities
         */
        public OfferACPProcessPostSignatureService(Opportunity[] oppties){
            this.oppties = oppties;
            this.acpDao = new SObjectDao();
            this.acps = new Map<ID, Application_Course_Preference__c>();
        }
        /**
         * This execute method loop through the list of opportunity, and pick all the deferred acp that have status of pending to update to approved. 
         * @param  oppties list of signed opportunities
         */
        public OfferACPProcessPostSignatureService execute(){
            for (Opportunity o : this.oppties){
                for (OpportunityLineItem oli : o.OpportunityLineItems){
                    if (oli.Application_Course_Preference__c != null && o.Original_Offer__c != null && oli.Application_Course_Preference__r.Deferred_Course_Offering__c != null && oli.Application_Course_Preference__r.Deferment_Status_LoV__r.Unique_Key__c == 'PENDING-ADM_OFFER_DFRMNT_STATUS') {
                        this.acps.put(oli.Application_Course_Preference__c, 
                            new Application_Course_Preference__c(
                                Id = oli.Application_Course_Preference__c, 
                                Deferment_Status_LoV__r = new List_of_Values__c(Unique_Key__c = 'APPROVED-ADM_OFFER_DFRMNT_STATUS')));
                    }
                }
            }
            return this;
        }
        /**
         * Upsert all acps to DB. 
         */
        public void commitAll(){
            this.acpDao.upsertRecords(this.acps.values());
        }
    }
}