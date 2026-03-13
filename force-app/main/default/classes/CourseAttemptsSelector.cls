/**
 * @author      David Browaeys
 * @description Selector class for course attempt attribute object processes
 * @group       Selectors
 */
public inherited sharing class CourseAttemptsSelector extends BaseSelector {
    /**
     * Constructors
     */
	public CourseAttemptsSelector() {
	    super(false);
	}
	
    public CourseAttemptsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      David Browaeys
     * @date        06/07/2020
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Course_Attempt__c.sObjectType;
	}
    
	/**
     * @author      David Browaeys
     * @date        06/07/2020
     * @description Query course attempt by ids
     * @param idSet list of course attempt ids 
     * @return list of course attempt found
     */
    public List<Course_Attempt__c> selectById(Set<Id> idSet) {
		return (List<Course_Attempt__c>) selectSObjectsById(idSet);
    }
    /**
     * @author      David Browaeys
     * @date        06/07/2020
     * @description Query course attempt by contact ids and by course code
     * @param contactIds list of contact id
     * @param courseCodes list of course code
     * @return list of course attempt found
     */
	public List<Course_Attempt__c> selectActiveByContactIdAndCourseCode(Set<String> contactIds, Set<String> courseCodes){
        return [    SELECT Id, Application_Course_Preference__c, Application_Course_Preference__r.Id, Application_Course_Preference__r.Course_Offering__r.Admission_Category__c, Application_Course_Preference__r.Admission_Category__c, Contact__c, Course__r.Name, Application_Course_Preference__r.Application__r.Citizenship_Country__c
                    FROM Course_Attempt__c 
                    WHERE Contact__c IN: contactIds
                    AND Course__r.Name IN: courseCodes
                    AND Course_Attempt_Status__c IN ('Enrolled','Inactive','Intermit')];
    }
}