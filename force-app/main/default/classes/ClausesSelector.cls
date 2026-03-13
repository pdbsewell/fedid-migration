/**
 * @author      Mathew Jose
 * @description Selector class for CPQ Quote line object processes
 * @group       Selectors
 * @revision    11/11/2019 - Mathew Jose - Created
 */
public inherited sharing class ClausesSelector extends BaseSelector {
    /**
     * Constructors
     */
    public ClausesSelector() {
        super(false);
    }
    
    public ClausesSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @author      Mathew Jose
     * @description Returns the object type
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public Schema.SObjectType getSObjectType() {
        return APXT_Redlining__Clause__c.sObjectType;
    }
    /**
     * @author      Mathew Jose
     * @description Query Quote by ids
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public List<APXT_Redlining__Clause__c> selectById(Set<Id> idSet) {
        return (List<APXT_Redlining__Clause__c>) selectSObjectsById(idSet);
    }
    /**
     * @author      Mathew Jose
     * @description Query clauses by ids with Quote line items
     * @revision    11/11/2019 - Mathew Jose - Created
     */
    public List<APXT_Redlining__Clause__c> selectAllWithCriteriaBySelectionType(String selectionType) {
        List<String>objectTypes = new List<String>{'SBQQ__QuoteLine__c','SBQQ__Quote__c'};
        return (List<APXT_Redlining__Clause__c>) Database.query(String.format(
            'SELECT {0}, {1} FROM {2} WHERE Active__c = true and Object_Level__c in : objectTypes and Selection_Type__c =: selectionType ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),
                    '(SELECT Field__c, Filtered_Value__c, Object_Type__c, Operator__c from Filtering_Criteria__r where Active__c = true)',
                    getSObjectName(),
                    getOrderBy()
            }
        ));
    }
}