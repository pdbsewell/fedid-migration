/**
 * @author      Jasmin Joy Rudio
 * @description Selector class for associated clause (child manual clause) object processes
 * @group       Selectors
 * @revision    20/07/2020 - Jasmin Joy Rudio - Created
 */
public inherited sharing class AssociatedClauseSelector extends BaseSelector {
    /**
     * Constructors
     */
	public AssociatedClauseSelector() {
	    super(false);
	}
	
    public AssociatedClauseSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Jasmin Joy Rudio
     * @date        20/07/2020
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Associated_Clause__c.sObjectType;
	}
    
	/**
     * @author      Jasmin Joy Rudio
     * @date        20/07/2020
     * @description Query associated clauses by ids
     */
    public List<Associated_Clause__c> selectById(Set<Id> idSet) {
		return (List<Associated_Clause__c>) selectSObjectsById(idSet);
	}

    /**
     * @author Jasmin Joy Rudio
     * @date   20/07/2020
     * Revision Shalini Mendu - 20/07/2022 - Uses Checkmarx DynamicSoqlBuilder
     * @param  parentField API name of a parent object (e.g. Opportunity__c)
     * @param  parentId record id of a parent object
     * @description  return list of associated clause filtered by parent lookup field
     */
    public List<Associated_Clause__c> selectClausesByParentId(String parentField, String parentId){
        String soql = String.format('SELECT {0} FROM {1} WHERE ' + parentField + ' =: parentId',
        new List<String>{
                getFieldListString(),
                getSObjectName()
        });
        String strWhereClause = parentField +' = :parentId';
        strWhereClause =  String.escapeSingleQuotes(strWhereClause);
        Set<String> fieldsSet = new Set<String>(getFieldListString().split(','));
        String dynamicTotSearchQuery = DynamicSoqlBuilder.getInstance()
        .showSOQLStatement(true)
        .setEnforced(false)
        .querySObject(getSObjectName())
        .queryFields( fieldsSet)
        .getQuery(strWhereClause);

        System.debug('** dynamicTotSearchQuery:= ' + dynamicTotSearchQuery);
        return (List<Associated_Clause__c>) Database.query(dynamicTotSearchQuery);
    }
   
}