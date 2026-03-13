/**
 * @author      Vishal Gupta
 * @description Selector class for application course preference processes
 * @group       Selectors
 * @revision    9/10/2024 - Vishal Gupta - Created
 */
public inherited sharing class ApplicationCoursePreferenceSelector extends BaseSelector {
    /**
     * Constructors
     */
    public ApplicationCoursePreferenceSelector() {
        super(false);
    }

    public ApplicationCoursePreferenceSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }

    /**
     * @author      Vishal Gupta
     * @description Returns the object type
     * @revision    9/10/2024 - Vishal Gupta - Created
     */
    public Schema.SObjectType getSObjectType() {
        return Application_Course_Preference__c.sObjectType;
    }

    /**
     * @author      Vishal Gupta
     * @description Query application course preference by ids with Course offering details
     * @param idSet
     * @return List<Application_Course_Preference__c>
     * @revision    4/10/2024 - Vishal gupta - Created
     */
    public List<Application_Course_Preference__c> selectByApplicationIdWithParentDetails(Set<Id> idSet) {
        assertIsAccessible();

        CourseOfferingSelector coursefferingSelector = new CourseOfferingSelector(overrideObjectPermissions);
        coursefferingSelector.assertIsAccessible();

        CalendarSelector calendarSelector = new CalendarSelector(overrideObjectPermissions);
        calendarSelector.assertIsAccessible();

        AccountsSelector accountSelector = new AccountsSelector(overrideObjectPermissions);
        accountSelector.assertIsAccessible();

        String queryString = String.format('SELECT {0},{1},{2},{3},{4}, Application__r.Name, Application__r.Submitted_Date_Time__c, Applicant__r.First_Name__c, Applicant__r.Full_Name__c, Applicant__r.Email, Course__r.Faculty_Code__c, Course__r.Faculty__r.Monash_AM_Start_Date__c FROM {5} WHERE Application__c IN :idSet ORDER BY {6}', 
            new List<String>{getFieldListString(),
                coursefferingSelector.getRelatedFieldListString('Course_Offering__r'),
                calendarSelector.getRelatedFieldListString('Course_Offering__r.Calendar__r'),
                calendarSelector.getRelatedFieldListString('Scholarship_Calendar__r'),
                accountSelector.getRelatedFieldListString('Academic_Org_Unit__r'),
                getSObjectName(),
                getOrderBy()}); 
        return (List<Application_Course_Preference__c>) Database.query(queryString);
    }

    /**
     * @author      Vishal Gupta
     * @description Query application course preference by HDRApplicationId and callista applicantId
     * @param hdrApplicationId
     * @param applicantId
     * @return List<Application_Course_Preference__c>
     * @revision    22/10/2024 - Vishal gupta - Created
     */
    public List<Application_Course_Preference__c> selectByHDRApplicationAndApplicantId(String hdrApplicationId, String applicantId) {
        assertIsAccessible();

        String queryString = String.format('SELECT {0} FROM {1} WHERE GradRes_Callista_Id__c = :hdrApplicationId AND Application__r.Callista_Applicant_Id__c =:applicantId ORDER BY {2}', 
            new List<String>{getFieldListString(),
                getSObjectName(),
                getOrderBy()}); 
        return (List<Application_Course_Preference__c>) Database.query(queryString);
    }

    /**
     * @author      Vishal Gupta
     * @description Query application course preference by applicantId with calendar details
     * @param callistaApplicantId
     * @param hdrAppId
     * @return List<Application_Course_Preference__c>
     * @revision    9/1/2025 - Vishal gupta - Created
     */
    public List<Application_Course_Preference__c> selectByApplicantIdWithCalendarDetails(Set<String> callistaApplicantId, Set<String> hdrAppId) {
        assertIsAccessible();

        CalendarSelector calendarSelector = new CalendarSelector(overrideObjectPermissions);
        calendarSelector.assertIsAccessible();

        String queryString = String.format('SELECT {0},{1}, Applicant__r.FirstName, Applicant__r.LastName, Applicant__r.AccountId FROM {2} WHERE Callista_Applicant_Id__c IN :callistaApplicantId AND GradRes_Callista_Id__c IN :hdrAppId ORDER BY {3}', 
            new List<String>{getFieldListString(),
                calendarSelector.getRelatedFieldListString('Scholarship_Calendar__r'),
                getSObjectName(),
                getOrderBy()}); 
        return (List<Application_Course_Preference__c>) Database.query(queryString);
    }
}