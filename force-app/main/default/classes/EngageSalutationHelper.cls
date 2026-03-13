/**
 * Class for updating Salutations based on name changes.
 * 
 * @author 		Mark Johnson - UC Innovation
 * @date        01/05/2019    
 * @revision
 */
public class EngageSalutationHelper {


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Starting point for creating/updating salutation records
	*******************************************************************************/  

	public void createOrUpdateSalutationRecords(Set<Id> contactIdSet) {
	    		//List of contacts to process
    		List<Contact> contactList = queryForContactsAndSalutations(contactIdSet).values();

    		//List of all spouses related to contacts above
    		Set<Id> spouseIdSet = populateSpouseIdSet(contactList);

    		//Map of spouse IDs to spouse contact records
    		Map<Id, Contact> spouseMap = queryForContactsAndSalutations(spouseIdSet);

    		//Map of contact ID to Contact and Spouse pairing.
    		Map<Id, EngageSalutationHelper.ContactPair> contactIdToContactPair = createContactPairMap(contactList, spouseMap);

    		updateSalutations(contactIdToContactPair);
    }


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  CLASS: 	Contains a contact and their spouse, and a container for
							salutations.
	*******************************************************************************/  

	public class ContactPair {
    	public Contact contact;
    	public Contact spouse;

    	public List<Ucinn_ascendv2__Salutation__c> salutations;

    	public ContactPair(Contact contact, Contact spouse) {
    		this.contact = contact;
    		this.spouse = spouse;

    		salutations = new List<Ucinn_ascendv2__Salutation__c>();
    	}

    	public ContactPair() {
    		salutations = new List<Ucinn_ascendv2__Salutation__c>();
    	}
    }


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  checks specific fields for change to determine if we should
					update salutations
	*******************************************************************************/  

	public Boolean shouldProcessNameRecord(Name__c newName, Name__c oldName) {

		Boolean process = (	newName.First_Name__c != oldName.First_Name__c ||
							newName.Preferred_First_Name__c != oldName.Preferred_First_Name__c ||
                            newName.Is_Primary__c != oldName.Is_Primary__c ||
							newName.Is_Active__c != oldName.Is_Active__c ||
							newName.Last_Name__c != oldName.Last_Name__c ||
							newName.Middle_Name__c != oldName.Middle_Name__c ||
							newName.Name != oldName.Name ||
							newName.Prefix__c != oldName.Prefix__c ||
							newName.Suffix__c != oldName.Suffix__c ||
							newName.Salutation__c != oldName.Salutation__c);

		return process;
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  query for fields necessary to construct salutations
	*******************************************************************************/  

	public Map<Id, Contact> queryForContactsAndSalutations(Set<Id> contactIdSet) {
		Map<Id, Contact> contactMap = new Map<Id, Contact>();

		if (!contactIdSet.isEmpty()) {
	        contactMap = new Map<Id, Contact>([SELECT 	Id,
							            				Name,
								                        Ucinn_ascendv2__Gender__c,
								                        Ucinn_ascendv2__Preferred_Spouse__c,
								                        Ucinn_ascendv2__Recognition_Name__c,
								                        Ucinn_ascendv2__Salutation_Preference__c,
								                        Ucinn_ascendv2__Is_Recognition_Name_Overridden__c,
								                        Account.Ucinn_ascendv2__Primary_Contact__c,
								                        (SELECT Id,
								                                Ucinn_ascendv2__Salutation_Type__c,
								                                Ucinn_ascendv2__Contact__c,
								                                RecordTypeId
								                        FROM Ucinn_ascendv2__Salutations_Contact__r
								                        WHERE Ucinn_ascendv2__Salutation_Author__c = 'Standard'),
								                        (SELECT Id,
								                        		Name,
								                        		Contact__c,
								                        		Prefix__c,
								                        		Salutation__c,
								                        		First_Name__c,
                                                         		Preferred_First_Name__c,
								                        		Last_Name__c, 
								                        		Middle_Name__c,
								                        		Type__c,
								                        		Suffix__c
								                        FROM Names__r
								                        WHERE Is_Primary__c = true AND Is_Active__c = true)

								                        FROM Contact WHERE Id IN :contactIdSet]);
    	}

    	return contactMap;
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Find all spouse ids from contacts whose names have changed
	*******************************************************************************/

	public Set<Id> populateSpouseIdSet(List<Contact> contactList) {
		Set<Id> preferredSpouseIdSet = new Set<Id>();

		for (Contact contact : contactList) {
			if (contact.Ucinn_ascendv2__Preferred_Spouse__c != null) {
				preferredSpouseIdSet.add(contact.Ucinn_ascendv2__Preferred_Spouse__c);
			}
		}

		return preferredSpouseIdSet;
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Construct ContactPair objects for use in salutation generation
	*******************************************************************************/

	public Map<Id, ContactPair> createContactPairMap(List<Contact> contactList, Map<Id, Contact> spouseMap) {
		Map<Id, ContactPair> contactPairMap = new Map<Id, ContactPair>();

		for (Contact contact : contactList) {
			ContactPair contactPair;
			Contact spouse;

			if (contact.Ucinn_ascendv2__Preferred_Spouse__c != null) {
				spouse = spouseMap.get(contact.Ucinn_ascendv2__Preferred_Spouse__c);

				if (contactPairMap.containsKey(spouse.Id)) continue;

				contactPair = new ContactPair(contact, spouse);
			} else {
				contactPair = new ContactPair(contact, null);
			}

			contactPairMap.put(contact.Id, contactPair);
		}

		return contactPairMap;
	}

	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Perform creation and update of salutations
	*******************************************************************************/

	public void updateSalutations(Map<Id, ContactPair> contactPairMap) {
		EngageSalutationGenerator salutationGenerator;
		List<Ucinn_ascendv2__Salutation__c> salutationList = new List<Ucinn_ascendv2__Salutation__c>();
		List<Contact> contactList = new List<Contact>();

		for (ContactPair contactPair : contactPairMap.values()) {
			salutationGenerator = new EngageSalutationGenerator(contactPair);

			ContactPair updatedContactPair = salutationGenerator.generateNewSalutations(); 

			salutationList.addAll(updatedContactPair.salutations);
			if (updatedContactPair.contact != null) contactList.add(updatedContactPair.contact);
			if (updatedContactPair.spouse != null) contactList.add(updatedContactPair.spouse);
		}

		performDMLOnContacts(contactList);
		performDMLOnSalutations(salutationList);
	}

	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Perform DML on Contact object
	*******************************************************************************/

	private void performDMLOnContacts(List<Contact> contactList) {

		//Disable to prevent unecessary trigger execution
		TriggerCommon.disableTrigger('Contact');
		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', false);

		update contactList;

		TriggerCommon.enableTrigger('Contact');
		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', true);
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Perform DML on Salutation object
	*******************************************************************************/

	private void performDMLOnSalutations(List<Ucinn_ascendv2__Salutation__c> salutationList) {

		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', false);
        upsert salutationList;

        salutationList = [SELECT Id, ucinn_ascendv2__Salutation_Name_Auto_Number__c, Name from ucinn_ascendv2__Salutation__c where ID in :salutationList];
        // For the time being, the UCI trigger is not correctly formatting the salutation name correctly.
        for (Ucinn_ascendv2__Salutation__c sal : salutationList) {
            sal.name = sal.ucinn_ascendv2__Salutation_Name_Auto_Number__c;
        }
        upsert salutationList;
		
        /*
        ucinn_ascendv2.ascend_TRIG_RecordNameUpdate recordNameUpdater = new ucinn_ascendv2.ascend_TRIG_RecordNameUpdate();
        
		recordNameUpdater.updateName(	new ucinn_ascendv2__Salutation__c().getSObjectType().getDescribe().getName(), 
                                        null,
                                        'ucinn_ascendv2__Salutation_Name_Auto_Number__c',
                                        '',
                                        '',
                                        null,
                                        salutationList);
		*/
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Salutation__c', true);
	}

}