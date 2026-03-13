/**
 * @author      Kristian Vegerano
 * @description Selector class for application course preference object processes
 * @group       Selectors
 * @revision    31/05/2019 - Kristian Vegerano - Created
 */
public inherited sharing class ACPSelector extends BaseSelector {
    /**
     * Constructors
     */
	public ACPSelector() {
	    super(false);
	}
	
    public ACPSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Kristian Vegerano
     * @date        17/05/2019
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Application_Course_Preference__c.sObjectType;
	}
    
	/**
     * @author      Kristian Vegerano
     * @date        17/05/2019
     * @description Query application course preferences by ids
     */
    public List<Application_Course_Preference__c> selectById(Set<Id> idSet) {
		return (List<Application_Course_Preference__c>) selectSObjectsById(idSet);
	}

    /**
     * @author      Nick Guia
     * @date        18/09/2023
     * @description Query ACP specific fields based on their ID
     */
    public List<Application_Course_Preference__c> selectFieldsById(List<String> acpFields, Set<Id> idSet) {
        String queryString = String.format(
                                'SELECT {0} FROM {1} WHERE id in :idSet ORDER BY {2}', 
                                new List<String> {
                                    String.join(acpFields, ','),
                                    getSObjectName(),
                                    getOrderBy()
                                });
        return (List<Application_Course_Preference__c>) Database.query(queryString);
    }

    /**
     * selectByApplicantId description
     * @param  applicantId applicantId description
     * @return             return description
     */
    public List<Application_Course_Preference__c> selectOfferedByApplicantId(String applicantId){
        String soql = String.format('SELECT {0}, {1} FROM {2} WHERE Course_Offering__r.Override_Reviewed__c = TRUE AND Application__r.Campus_Location__c IN :ENABLED_CAMPUS AND Applicant__c = :applicantId AND Course_Offering__c <> NULL AND Course_Start_Date_Updated__c >= TODAY AND Calendar_Start_Date__c <> NULL AND Calendar_End_Date__c <> NULL AND Outcome_Status_Value__c IN :ACP_OFFER_STATUS ORDER BY Calendar_Start_Date__c', 
        new List<String>{
                getFieldListString(),
                'Course_Offering__r.Course_Duration__c, Course_Offering__r.Override_Duration__c, Course_Offering__r.Override_Duration_Unit__c, Course_Offering__r.Campus__c, Application__r.Submission_Location_Country__c, ' + 
                'Application__r.Submission_Location_Country__r.Name, Outcome_Status_LOV__r.System_Code__c, Outcome_Status_LOV__r.Value__c, Conditional_offer_Status_LOV__r.Value__c, Application__r.Type_of_Study__c, Application__r.Campus_Location__c, Application__r.Agent__c, Application__r.Agent__r.Name, Application__r.Residency_Status__c, Application__r.Transfer_Type__c, ' +
                'Bulk_Data_Processing__r.Transfer_To__c, Bulk_Data_Processing__r.Status__c, Bulk_Data_Processing__r.Student_Notes__c, Bulk_Data_Processing__r.Transfer_Course_Code__c ',
                getSObjectName()
        });
        System.debug('** soql: ' + soql);
        List<Application_Course_Preference__c> acpList = (List<Application_Course_Preference__c>) Database.query(soql);
        return acpList;
    }
    /**
     * select acp by id for bulk offer
     * @param  acpId id of the acp
     * @return Application_Course_Preference__c
     */
    public Application_Course_Preference__c selectOfferedById(String acpId){
        String soql = String.format('SELECT {0}, Course_Offering__r.Course_Duration__c, Course_Offering__r.Override_Duration__c, Course_Offering__r.Override_Duration_Unit__c, Course_Offering__r.Campus__c, Application__r.Submission_Location_Country__c, Application__r.Submission_Location_Country__r.Name, Outcome_Status_LOV__r.System_Code__c, Application__r.Campus_Location__c, Application__r.Agent__c, Application__r.Residency_Status__c FROM {1} WHERE Id = :acpId', 
        new List<String>{
                getFieldListString(),
                getSObjectName()
        });
        return (Application_Course_Preference__c) Database.query(soql);
    }
    public static final String[] ENABLED_CAMPUS = new String[]{'Australia', 'Online', 'Indonesia', 'Malaysia'}; //SFTG-1963,SFTG-2265 Added Online.Indonesia as location
    public static final String[] ACP_OFFER_STATUS =  new String[]{'OFFER','OFFER-C-E','OFFER-C-MC','OFFER-C-FY','OFFER-COND','OFFER-PROV','OFFER-G-CO'};

    /**
     * @author      Kristian Vegerano
     * @description Query acps by application ids
     * @revision    02/08/2021 - Kristian Vegerano - Created
     */
    public List<Application_Course_Preference__c> selectByApplicationId(Set<Id> applicationIds) {
        assertIsAccessible();

        String queryString = String.format('SELECT {0} FROM {1} WHERE Application__c IN :applicationIds ORDER BY {2}', 
            new List<String>{
                getFieldListString(),
                getSObjectName(),
                getOrderBy()
            });

        return (List<Application_Course_Preference__c>) Database.query(queryString);
    }
}