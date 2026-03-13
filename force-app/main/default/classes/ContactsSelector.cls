/**
 * @author      Kristian Vegerano
 * @description Selector class for contact object processes
 * @group       Selectors
 * @revision    31/05/2019 - Kristian Vegerano - Created
 */
public inherited sharing class ContactsSelector extends BaseSelector {
    /**
     * Constructors
     */
	public ContactsSelector() {
	    super(false);
	}
	
    public ContactsSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }
	
	/**
     * @author      Kristian Vegerano
     * @date        17/05/2019
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return Contact.sObjectType;
	}
    
	/**
     * @author      Kristian Vegerano
     * @date        17/05/2019
     * @description Query contacts by ids
     */
    public List<Contact> selectById(Set<Id> idSet) {
		return (List<Contact>) selectSObjectsById(idSet);
	}
    
	/**
     * @author      Jasmin Joy Rudio
     * @date        02/07/2020
     * @description Query contacts by person id
     */
    public List<Contact> selectByPersonId(Set<String> personIdSet) {
		String soql = String.format('SELECT {0} FROM {1} WHERE Person_ID_unique__c IN: personIdSet', 
        new List<String>{
                getFieldListString(),
                getSObjectName()
        });
        return (List<Contact>) Database.query(soql);
	}
}