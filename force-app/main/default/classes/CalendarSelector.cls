/**
 * @author      Jasmin Joy Rudio
 * @description Selector class for calendar__c object processes
 * @group       Selectors
 * @revision    02/07/2020 - Jasmin Joy Rudio - Created
 */
public with sharing class CalendarSelector extends BaseSelector {
     /**
     * Constructors
     */
	public CalendarSelector() {
	    super(false);
	}
	
    public CalendarSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	public Schema.SObjectType getSObjectType() {
		return Calendar__c.sObjectType;
	}
    
	/**
     * @author      Jasmin Joy Rudio
     * @date        02/07/2020
     * @description Query calendars by ids
     */
    public List<Calendar__c> selectById(Set<Id> idSet) {
		return (List<Calendar__c>) selectSObjectsById(idSet);
    }
    
	/**
     * @author      Jasmin Joy Rudio
     * @date        02/07/2020
     * @description Query calendars by person id
     */
    public List<Calendar__c> selectByAlternateNameCategory(Set<String> alternateNames, String category) {
		String soql = String.format('SELECT {0} FROM {1} WHERE Calendar_Name_Alternate__c IN: alternateNames AND Category__c =: category', 
        new List<String>{
                getFieldListString(),
                getSObjectName()
        });
        return (List<Calendar__c>) Database.query(soql);
	}
}