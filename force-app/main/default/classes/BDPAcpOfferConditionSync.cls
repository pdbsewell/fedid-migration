/**
 * @description Updates the transfer tp ACP Offer Condition based on Bulk Data 
 * Processing (BDP) record
 * @revision
 *  AUG.31.2022     Nick Guia   - Renamed Promise interface to IPromise 
 */
public inherited sharing class BDPAcpOfferConditionSync implements IPromise {

    @testVisible
    private Dao acpDao;

    @testVisible
    private ACPSelector acpSelector;

	/**
     * Initialise process, act as constructor
     * @return Promise
     */
    public IPromise init(){
        this.acpDao = new SObjectDao();
        this.acpSelector = new ACPSelector();
        return this;
    }

    /**
     * @description Executes the BDP ACP Sync for Offer condition
     * This method assumes all BDP records have a transfer to ACP
     * @param records list of BDP record to fetch data
    */
    public void execute(SObject[] records){
        
        Map<Id, String> updatedOfferConditionByAcp = new Map<Id, String>();

        for (Bulk_Data_Processing__c bdp : (Bulk_Data_Processing__c[])records){
            updatedOfferConditionByAcp.put(bdp.Transfer_To__c, bdp.Offer_Condition__c);
        }

        List<Application_Course_Preference__c> acpsForUpdate = 
            this.acpSelector.selectById(updatedOfferConditionByAcp.keySet());

        for (Application_Course_Preference__c acp : acpsForUpdate) {
            acp.Offer_Condition__c = updatedOfferConditionByAcp.get(acp.Id);
        }

        acpDao.updateRecords(acpsForUpdate);
    }
}