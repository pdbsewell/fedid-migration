/**
 * @author      Kristian Vegerano
 * @description Selector class for contact qualification object processes
 * @group       Selectors
 * @revision    31/05/2019 - Kristian Vegerano - Created
 * 28/05/2023 - Vinothraja - Added method to Query Qualifications by Application Id
 */
public inherited sharing class ContactQualificationsSelector extends BaseSelector {
    /**
     * Constructors
     */
	public ContactQualificationsSelector() {
	    super(false);
	}
	
    public ContactQualificationsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Kristian Vegerano
     * @description Returns the object type
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
	public Schema.SObjectType getSObjectType() {
		return Contact_Qualification__c.sObjectType;
	}
    
	/**
     * @author      Kristian Vegerano
     * @description Query contact qualifications by ids
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    public List<Contact_Qualification__c> selectById(Set<Id> idSet) {
		return (List<Contact_Qualification__c>) selectSObjectsById(idSet);
	}

    /**
     * @author      Kristian Vegerano
     * @description Query contact qualifications by contact id
     * @revision    31/05/2019 - Kristian Vegerano - Created
     */
    public List<Contact_Qualification__c> selectByContactId(Set<Id> idSet) {
        assertIsAccessible();
        String queryString = String.format('SELECT {0}, {1} FROM {2} WHERE Contact__c IN :idSet ORDER BY {3}', 
            new List<String>{getFieldListString(),
                new CountriesSelector().getRelatedFieldListString('Qualification_Country__r'),
                getSObjectName(),
                getOrderBy()});

        return Database.query(queryString);
	}
    /**
     * @author      Vinothraja
     * @description Query contact qualifications by application id
     * @revision    25/04/2023 - Vinothraja - Created
     */
    public List<Contact_Qualification__c> selectByApplicationId(Set<Id> idSet) {
        assertIsAccessible();
        String queryString = String.format('SELECT {0}, toLabel(Evidence_Type__c) Evidence_Type_Value FROM {1} WHERE id IN (SELECT Contact_Qualification__c FROM Application_Qualification_Provided__c WHERE Application__c IN :idSet) ORDER BY {2}', 
            new List<String>{getFieldListString(),
                getSObjectName(),
                getOrderBy()});

        return Database.query(queryString);
	}

    /**
     * @author      Vishal Gupta
     * @description Query contact qualifications, application qualifications and contact document by application id 
     * @param idSet
     * @return List<Contact_Qualification__c>
     * @revision    04/10/2024 - Vishal Gupta - Created
     */
    public List<Contact_Qualification__c> selectQualificationsWithDocumentsByApplicationId(Set<Id> idSet) {
        assertIsAccessible();

        CountriesSelector countriesSelector = new CountriesSelector(overrideObjectPermissions);
        countriesSelector.assertIsAccessible();

        String queryString = String.format('SELECT {0}, {1}, {2},(SELECT Sequence_Number__c from Application_Qualifications__r), '+
                                            '(SELECT Callista_Document_Id__c from Contact_Documents__r) '+
                                            ' FROM {3} WHERE id IN (SELECT Contact_Qualification__c FROM Application_Qualification_Provided__c WHERE Application__c IN :idSet) ORDER BY {4}', 
            new List<String>{getFieldListString(),
                countriesSelector.getRelatedFieldListString('Qualification_Country__r'),
                'Qualification__r.Callista_Code__c',
                getSObjectName(),
                getOrderBy()});
        
        return Database.query(queryString);
	}
}