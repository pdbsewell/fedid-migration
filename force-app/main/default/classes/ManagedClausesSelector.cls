/**
 * @author      Jasmin Joy Rudio
 * @description Selector class for Managed Clause object processes
 * @group       Selectors
 * @revision    12/12/2019 - Jasmin - Created
 */
public inherited sharing class ManagedClausesSelector  extends BaseSelector{
    /**
     * Constructors
     */
    public ManagedClausesSelector() {
        super(false);
    }
    
    public ManagedClausesSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }

    public override String getOrderBy() {
	    return 'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c, APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Selection_Type__c ASC';
	}
     
    /**
     * @author      Jasmin Joy Rudio
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return APXT_Redlining__Managed_Clause__c.sObjectType;
    }
    /**
     * @author      Jasmin Joy Rudio
     * @description Query Quote by ids
     * @return      List of Quote records
     */
    public List<APXT_Redlining__Managed_Clause__c> selectById(Set<Id> idSet) {
        return (List<APXT_Redlining__Managed_Clause__c>) selectSObjectsById(idSet);
    }

    /**
     * @author      Jasmin Joy Rudio
     * @description Query Managed Clauses by Quote Line id
     * @return      List of APXT_Redlining__Managed_Clause__c records
     */
    public List<APXT_Redlining__Managed_Clause__c> selectByQuoteId(Set<String> idSet) { 
        String queryString = String.format(
            'SELECT {0}, {1} FROM {2} WHERE SBQQ_Quote__c in :idSet ORDER BY {3}',
            new List<String>{
                    getFieldListString(),
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__c,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Name,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text__c,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text_Rich__c,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c',                    
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<APXT_Redlining__Managed_Clause__c>) Database.query(queryString);
    }

    /**
     * @author      Jasmin Joy Rudio
     * @description Query Managed Clauses by Quote Line id
     * @return      List of APXT_Redlining__Managed_Clause__c records
     */
    public List<APXT_Redlining__Managed_Clause__c> selectByQuoteLineLocation(Set<String> idSet, String location) { 
        String queryString = String.format(
            'SELECT {0}, {1} FROM {2} WHERE SBQQ_QuoteLine__c in :idSet'+
            ' AND APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c =: location ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__c,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Name,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text__c,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.APXT_Redlining__Text_Rich__c,'+
                    'APXT_Redlining__Clause_Revision__r.APXT_Redlining__Clause__r.Location_in_Offer__c',                         
                    getSObjectName(),
                    getOrderBy()
            }
        );
        return (List<APXT_Redlining__Managed_Clause__c>) Database.query(queryString);
    }


}