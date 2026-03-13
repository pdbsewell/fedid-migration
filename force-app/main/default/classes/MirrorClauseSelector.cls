/**
 * @author      Jasmin Joy Rudio
 * @description Selector class for Mirror Clause object processes
 * @group       Selectors
 * @revision    05/18/2020 - Jasmin - Created
 */
public inherited sharing class MirrorClauseSelector  extends BaseSelector{
    /**
     * Constructors
     */
    public MirrorClauseSelector() {
        super(false);
    }
    
    public MirrorClauseSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
     
    /**
     * @author      Jasmin Joy Rudio
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return Mirror_Clause__c.sObjectType;
    }
    /**
     * @author      Jasmin Joy Rudio
     * @description Query Mirror Clause by ids
     * @return      List of Mirror Clause records
     */
    public List<Mirror_Clause__c> selectById(Set<Id> idSet) {
        return (List<Mirror_Clause__c>) selectSObjectsById(idSet);
    }

    /**
     * @author      Jasmin Joy Rudio
     * @description Query active Mirror Clause
     * @return      List of Mirror_Clause__c records
     */
    public List<Mirror_Clause__c> selectActiveClauses() { 
        String queryString = String.format(
            'SELECT {0}, {1} FROM {2} WHERE Active__c = true ORDER BY {3}', 
            new List<String>{
                    getFieldListString(),   
                    'Clause__r.Selection_Type__c',                
                    getSObjectName(),
                    getOrderBy()
            }
        );
        System.debug('** queryString: ' + queryString);
        return (List<Mirror_Clause__c>) Database.query(queryString);
    }


}