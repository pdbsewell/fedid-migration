/**
 * @author      Kristian Vegerano
 * @description Selector class for course specific document object processes
 * @group       Selectors
 * @revision    02/08/2021 - Kristian Vegerano - Created
 */
public with sharing class CourseSpecificDocumentSelector extends BaseSelector {
    /**
     * Constructors
     */
    public CourseSpecificDocumentSelector() {
        super(false);
    }
    
    public CourseSpecificDocumentSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
    
    /**
     * @author      Kristian Vegerano
     * @date        02/08/2021
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return Course_Specific_Document__c.sObjectType;
    }
    
    /**
     * @author      Kristian Vegerano
     * @description Return ORDER BY clause for the query
     * @revision    02/08/2021 - Kristian Vegerano - Created
     */
    public override String getOrderBy() {
        return 'Name ASC';
    }

    /**
     * @author      Kristian Vegerano
     * @date        02/08/2021
     * @description Query document checklists by ids
     */
    public List<Course_Specific_Document__c> selectById(Set<Id> idSet) {
        return (List<Course_Specific_Document__c>) selectSObjectsById(idSet);
    }
    
    /**
     * @author      Kristian Vegerano
     * @date        02/08/2021
     * @description Query document checklists by parent application's ids
     */
    public List<Course_Specific_Document__c> selectCoursePrerequisiteByCourseOrFaculty(Set<String> courseCodes, Set<String> facultyName) {
        assertIsAccessible();

        String queryString = String.format('SELECT {0} FROM {1} WHERE (Course_Code__c IN :courseCodes OR Faculty_Name__c = :facultyName) AND IsActive__c = true ORDER BY {2}', 
                                           new List<String>{getFieldListString(),
                                                            getSObjectName(),
                                                            getOrderBy()});
        return Database.query(queryString);
    }
}