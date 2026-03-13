/**
 * @author      David Browaeys
 * @description Selector class for course object processes
 * @group       Selectors
 * @revision    28/10/2019 - David Browaeys - Created
 */
public inherited sharing class CoursesSelector extends BaseSelector {
    /**
     * Constructors
     */
	public CoursesSelector() {
	    super(false);
	}
	
    public CoursesSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      David Browaeys
     * @date        28/10/2019
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Course__c.sObjectType;
	}
	/**
     * @author      David Browaeys
     * @date        28/10/2019
     * @description 
     */
    public List<Course__c> selectById(Set<Id> idSet) {
		return (List<Course__c>) selectSObjectsById(idSet);
	}
	/**
     * @author      David Browaeys
     * @date        28/10/2019
     * @description 
     */
    public Map<ID,Course__c> selectMapById(Set<Id> idSet) {
		return new Map<ID, Course__c>(selectById(idSet));
	}
    public Map<String,Course__c> selectCourseByExternalId(Set<String> idSet, Schema.SObjectField externIdField) {
        assertIsAccessible();
		String fieldName = externIdField.getDescribe().getName();
        Course__c[] records = Database.query(String.format('SELECT {0} FROM {1} WHERE {3} IN :idSet ORDER BY {2}', new List<String>{getFieldListString(),
		                                                                                                             getSObjectName(),
		                                                                                                             getOrderBy(),
																										             fieldName}));
		Map<String,Course__c> tmp = new Map<String,Course__c>();
		for (Course__c record : (Course__c[])records){
			tmp.put(String.valueOf(record.get(externIdField.getDescribe().getName())),record);
		}
		return tmp;
    }
}