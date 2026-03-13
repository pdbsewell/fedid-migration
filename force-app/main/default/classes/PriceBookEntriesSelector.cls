/*
* @author Mathew Jose
* @date 29/10/2019
* @group SF Offer
* @description Selector class for PricebookEntry records
*/
public inherited sharing class PriceBookEntriesSelector extends BaseSelector {
    /**
     * Constructors
     */
    public PriceBookEntriesSelector() {
        super(false);
    }
    
    /**
     * @author      Mathew Jose
     * @description Returns the object type
     * @revision    29/10/2019 - Mathew Jose - Created
     */
    public Schema.SObjectType getSObjectType() {
        return PriceBookEntry.sObjectType;
    }
    /**
     * @author      Mathew Jose
     * @description Query PricebookEntry by ids
     * @revision    29/10/2019 - Mathew Jose - Created
     */
    public List<PricebookEntry> selectById(Set<Id> idSet) {
        return (List<PricebookEntry>) selectSObjectsById(idSet);
    }
    /**
     * @author      Mathew Jose
     * @description Query PricebookEntry by Pricebook Id
     * @revision    29/10/2019 - Mathew Jose - Created
     */
    public Map<String,PricebookEntry> selectByProductId(string pbId, Set<String> productIds) {
        List<PricebookEntry> tmp =  (List<PricebookEntry>) Database.query(String.format(
                        'SELECT {0},Product2.Expiry_days__c FROM {1} WHERE IsActive = true AND Product2Id IN :productIds AND PriceBook2Id = :pbId ORDER BY {2}', 
                        new List<String>{
                                getFieldListString(),
                                getSObjectName(),
                                getOrderBy()
                        }
                    ));
       	Map <String, PricebookEntry> prices = new Map <String, PricebookEntry>();  
        for (PricebookEntry pbe : tmp){
            prices.put(pbe.Product2Id, pbe);
        } 
        return prices;        
    }
    /**
     * @author      Mathew Jose
     * @description Query PricebookEntry by Pricebook Id 
     * @revision    29/10/2019 - Mathew Jose - Created
     */
    public Map<String, PricebookEntry> selectByProduct2ExternalId(string pbId, Set<String> productIds) {
        List<PricebookEntry> tmp = (List<PricebookEntry>) Database.query(String.format(
                        'SELECT {0}, Product2.External_Id__c, Product2.Product_Bundle__c, Product2.Product_Bundle__r.ProductCode FROM {1} WHERE IsActive = true AND Product2.External_Id__c IN :productIds AND PriceBook2Id = :pbId ORDER BY {2}', 
                        new List<String>{
                                getFieldListString(),
                                getSObjectName(),
                                getOrderBy()
                        }
                    ));
       	Map <String, PricebookEntry> prices = new Map <String, PricebookEntry>();
        for (PricebookEntry pbe : tmp){
            prices.put(pbe.Product2.External_Id__c, pbe);
        }
        return prices;
    }

    /**
     * @author      David Browaeys
     * @description Query PricebookEntry by External Id's
     * @revision    29/10/2019 - Mathew Jose - Created
     */
    public Map<String, PricebookEntry> selectPricebookEntriesByExternalId(Set<String> productIds) {
        List<PricebookEntry> tmp = (List<PricebookEntry>) Database.query(String.format(
                        'SELECT {0} FROM {1} WHERE Product2.External_Id__c IN :productIds', 
                        new List<String>{
                                getFieldListString(),
                                getSObjectName()
                        }
                    ));
       	Map <String, PricebookEntry> prices = new Map <String, PricebookEntry>();
        for (PricebookEntry pbe : tmp){
            prices.put(pbe.External_Id__c, pbe);
        }
        return prices;
    }
    public static final String[] GRANT_TYPE = new String[]{'Capped Grant Scholarship','Scholarship','Grant'};
    public PricebookEntry[] selectActiveGrantsAndScholarshipsByBricebookId(String pricebookExtId){
        return (List<PricebookEntry>) Database.query(String.format(
            'SELECT {0}, Product2.Name, Product2.Keywords__c, Product2.Family, Product2.Description, Product2.SBQQ__Specifications__c, Product2.Type__c, Product2.External_Id__c, Product2.Expiry_days__c , Product2.Quota_Available__c, Product2.Value_Deductable__c FROM {1} WHERE Product2.IsActive = true AND IsActive = true AND Product2.Family IN :GRANT_TYPE AND PriceBook2.External_ID__c = :pricebookExtId', 
            new List<String>{
                    getFieldListString(),
                    getSObjectName()
            }
        ));
    }
    
    @AuraEnabled
    public static PricebookEntry[] selectActiveGrantsAndScholarships(String pricebookExtId){
        return new PriceBookEntriesSelector().selectActiveGrantsAndScholarshipsByBricebookId(pricebookExtId);
    }


    public Pricebook2 selectPricebook2ByExtid(String extId){
        return [SELECT Id FROM Pricebook2 WHERE External_ID__c = :extId];
    }
}