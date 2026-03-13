/**
 * This service class updates acp's in the context of the offer wizard
 * @author David Browaeys
 */
public inherited sharing class OfferACPUpdateService{
    @TestVisible private Map<ID, Application_Course_Preference__c> acps;
    @TestVisible private List<Application_Course_Preference__c> sourceAcps;
    @TestVisible private OfferWizardWrapper wrapper;
    @TestVisible private Dao acpDao;
    @TestVisible private OpportunitiesSelector opportunitiesSelector;

    public OfferACPUpdateService(OfferWizardWrapper wrapper){
        this.acpDao = new SObjectDao();
        this.wrapper = wrapper;
        this.sourceAcps = this.wrapper.selectedACPList;
        if (this.wrapper.updatedACPs != null) this.acps = this.wrapper.updatedACPs;
        this.opportunitiesSelector = new OpportunitiesSelector();

    }
    public OfferACPUpdateService execute(){
        for (Application_Course_Preference__c oldACP : this.sourceAcps){
            //only for deferral
            Application_Course_Preference__c acp = acps.get(oldACP.Id);
            System.debug(oldACP.Course_Offering__c + '==' + this.wrapper.courseOfferingByAcpId.get(oldACP.Id).Id);
            if (this.wrapper.courseOfferingByAcpId != null && this.wrapper.courseOfferingByAcpId.get(acp.Id) != null && oldACP.Course_Offering__c != this.wrapper.courseOfferingByAcpId.get(acp.Id).Id){
                acp.Deferred_Course_Offering__c = this.wrapper.courseOfferingByAcpId.get(acp.Id).Id;
                
                Id originalOfferOpportunityId = this.wrapper.opptyRecord.Original_Offer__c;
                if (originalOfferOpportunityId != null) {
                    String originalOppStage = this.opportunitiesSelector.selectById(
                        new Set<Id>{originalOfferOpportunityId}
                    )[0].StageName;
                    acp.Deferment_Status_LOV__r = this.determineAcpDefermentStatus(originalOppStage);
                    acp.Actual_Offer_Response_Date__c = System.today();
                }
                acp.Offer_Response_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'DEFERRAL-ADM_OFFER_RESP_STATUS');
                acp.Deferred_Admission_Calendar_Type__c = this.wrapper.courseOfferingByAcpId.get(acp.Id).Admission_Calendar_Type__c;
                acp.Deferred_Admission_Ci_Sequence__c = this.wrapper.courseOfferingByAcpId.get(acp.Id).Admission_CI_Sequence_Number__c;
                acp.Deferred_Commencement_Period__c = this.wrapper.courseOfferingByAcpId.get(acp.Id).Commencement_Period__c;
                acp.Deferred_Academic_Alternate_Code__c = this.wrapper.courseOfferingByAcpId.get(acp.Id).Admission_Alternate_Code__c;
            }
            acp.Offer_Response_Date__c = this.wrapper.offerLapsedDate;

        }
        return this;
    }
    /**
     * Commit all work to DB
     * @return   list of updated acp's
     */
    public List<Application_Course_Preference__c> commitAll(){
        List<Application_Course_Preference__c> updatedACPs = acps.values();
        acpDao.upsertRecords(updatedACPs);
        return updatedACPs;
    }


    /**
     * @description Returns a List of Values record based on the original 
     * oppportunity stage name
     */
    private List_of_Values__c determineAcpDefermentStatus(String originalOpportunityStage) {
        if ('Review Offer'.equals(originalOpportunityStage) 
                || 'Publish'.equals(originalOpportunityStage)) {
            return new List_of_Values__c(Unique_Key__c = 'APPROVED-ADM_OFFER_DFRMNT_STATUS');
        } else {
            return new List_of_Values__c(Unique_Key__c = 'PENDING-ADM_OFFER_DFRMNT_STATUS');
        }
    }
}