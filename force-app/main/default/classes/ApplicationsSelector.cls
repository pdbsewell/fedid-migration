/**
 * @author      Kristian Vegerano
 * @description Selector class for application object processes
 * @group       Selectors
 * @revision    17/05/2019 - Kristian Vegerano - Created
 */
public inherited sharing class ApplicationsSelector extends BaseSelector {
    /**
     * Constructors
     */
    public ApplicationsSelector() {
        super(false);
    }

    public ApplicationsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the object type
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public Schema.SObjectType getSObjectType() {
        return Application__c.sObjectType;
    }

    /**
     * @author      Kristian Vegerano
     * @description Query applications by ids
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public List<Application__c> selectById(Set<Id> idSet) {
     return (List<Application__c>) selectSObjectsById(idSet);
    }

    /**
     * @author      Kristian Vegerano
     * @description Query applications by ids with parent details
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public List<Application__c> selectByIdWithParentDetailsAndFinalACPs(Set<Id> idSet) {
        assertIsAccessible();

        AccountsSelector accountSelector = new AccountsSelector(overrideObjectPermissions);
        accountSelector.assertIsAccessible();

        ACPSelector applicationCoursePreferenceSelector = new ACPSelector(overrideObjectPermissions);
        applicationCoursePreferenceSelector.assertIsAccessible();

        ContactsSelector contactSelector = new ContactsSelector(overrideObjectPermissions);
        contactSelector.assertIsAccessible();

        CountriesSelector countriesSelector = new CountriesSelector(overrideObjectPermissions);
        countriesSelector.assertIsAccessible();

        List<String> acpFinalStatusList = new List<String>();
        acpFinalStatusList.add(Label.ACPStatus_CondOffer);
        acpFinalStatusList.add(Label.ACPStatus_Offer);
        acpFinalStatusList.add(Label.ACPStatus_Rejected);

        String queryString = String.format('SELECT {0},{1},{2},{3},(SELECT {4} FROM Application_Course_Preferences__r WHERE Outcome_Status_LOV__r.System_Code__c IN :acpFinalStatusList) FROM {5} WHERE Id IN :idSet ORDER BY {6}', 
            new List<String>{getFieldListString(),
                accountSelector.getRelatedFieldListString('Agent__r'),
                contactSelector.getRelatedFieldListString('Applicant__r'),
                countriesSelector.getRelatedFieldListString('Submission_Location_Country__r'),
                applicationCoursePreferenceSelector.getFieldListString(),
                getSObjectName(),
                getOrderBy()});    
        
        return (List<Application__c>) Database.query(queryString);
    }

    /**
     * @author      Kristian Vegerano
     * @description Query applications by applicant ids
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public List<Application__c> selectByApplicantId(Set<Id> idSet) {
        assertIsAccessible();
        String queryString = String.format('SELECT {0} FROM {1} WHERE Applicant__c IN :idSet ORDER BY {2}', 
            new List<String>{getFieldListString(),
                getSObjectName(),
                getOrderBy()});
                
        return Database.query(queryString);
    }

    /**
     * @author      Kristian Vegerano
     * @description Query applications by agency ids
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public List<Application__c> selectByAgencyId(Set<Id> idSet) {
        assertIsAccessible();
        String queryString = String.format('SELECT {0} FROM {1} WHERE Agent__c IN :idSet ORDER BY {2}', 
            new List<String>{getFieldListString(),
                getSObjectName(),
                getOrderBy()});

        return Database.query(queryString);
    }

    /**
     * @author      Kristian Vegerano
     * @description Query applications by ids with parent details
     * @revision    17/05/2019 - Kristian Vegerano - Created
     */
    public List<Application__c> selectByIdWithFullAssessmentDetails(Set<Id> idSet) {
        assertIsAccessible();

        ContactsSelector contactSelector = new ContactsSelector(overrideObjectPermissions);
        contactSelector.assertIsAccessible();

        String queryString = String.format('SELECT {0}, {1}, (SELECT Id, Contact_Qualification__c FROM Application_Qualifications__r), (SELECT Id, Work_Experience__c FROM Application_Work_Experiences_Provided__r) FROM {2} WHERE Id IN :idSet ORDER BY {3}', 
            new List<String>{getFieldListString(),
                contactSelector.getRelatedFieldListString('Applicant__r'),
                getSObjectName(),
                getOrderBy()});

        return (List<Application__c>) Database.query(queryString);
    }

    /**
     * @author      Vishal Gupta
     * @description Query applications by ids with agent and child documents
     * @param idSet
     * @return List<Application__c>
     * @revision    4/10/2024 - Vishal gupta - Created
     */
    public List<Application__c> selectByIdWithParentDetailsAndDocuments(Set<Id> idSet) {
        assertIsAccessible();

        AccountsSelector accountSelector = new AccountsSelector(overrideObjectPermissions);
        accountSelector.assertIsAccessible();

        String queryString = String.format('SELECT {0},{1},{2},(SELECT Callista_Document_Id__c, Document_Checklist__r.Document_Request_Type__c, Contact_Qualification__c FROM Contact_Documents__r) FROM {3} WHERE Id IN :idSet ORDER BY {4}', 
            new List<String>{getFieldListString(),
                accountSelector.getRelatedFieldListString('Agent__r'),
                new ApplicationsSelector().getRelatedFieldListString('Parent_Application__r'),
                getSObjectName(),
                getOrderBy()}); 
        return (List<Application__c>) Database.query(queryString);
    }
}