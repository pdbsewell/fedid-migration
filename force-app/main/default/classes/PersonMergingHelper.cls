/**
 * @description Contact Merge Helper class
 *
 * @author P.Victoriano
 * @date 02/11/19
 *
 *
 * @revision
 *
 **/
public virtual class PersonMergingHelper {
	public Boolean excludeActiveCommunitiesUser {get; set;}
	public Set<Id> skippedDuplicateRecordSet {get; set;}
	private final Map<String, Schema.SObjectField> mapConFieldUpdateAccess = Schema.SObjectType.Contact.fields.getMap();
	@TestVisible
	private Boolean hasRecordsLeft = false;
	@TestVisible
	private Map<String, Person_Merge_Mapping__mdt> mdtPersonMapping {get; set;}
	@TestVisible
	private Set<Id> contactIds {get; set;}
	@TestVisible
	private Map<Id, DuplicateRecordSetWrapper> dupRecSetWrappers {get; set;}
	@TestVisible
	private Map<Id, Id> contactIdToDupRecSetId {get; set;}
	@TestVisible
	private Map<Id, User> mapUserContactId {get; set;}
	@TestVisible
	private Map<Id, DuplicateRecordItem> mapContactDupRecordItem {get; set;}
	@TestVisible
	private List<DuplicateRecordItem> lDupRecordItemDelete {get; set;}

	public PersonMergingHelper() {
		contactIds = new Set<Id>();
		skippedDuplicateRecordSet = new Set<Id>();
		dupRecSetWrappers = new Map<Id, DuplicateRecordSetWrapper>();
		contactIdToDupRecSetId = new Map<Id, Id>();
		mapUserContactId = new Map<Id, User>();
		mapContactDupRecordItem = new Map<Id, DuplicateRecordItem>();
		lDupRecordItemDelete = new List<DuplicateRecordItem>();
	}
	/**
	 * Initialize Helper properties
	 */
	public virtual Boolean init(List<DuplicateRecordSet> records) {
		//Populate MDT Mapping
		populateMDTMergeMapping();
		for (DuplicateRecordSet record : records) {
			List<DuplicateRecordItem> items = record.DuplicateRecordItems;
			Integer iCountRecs = 0;
			//Precreate Wrapper
			DuplicateRecordSetWrapper wrap = new DuplicateRecordSetWrapper(record.Id);
			dupRecSetWrappers.put(record.Id, wrap);
			//Process Duplicate Record Items
			if (items != null) {
				for (DuplicateRecordItem oitm : items) {
					if (oitm.RecordId != null) {
						mapContactDupRecordItem.put(oitm.RecordId, oitm);
						contactIds.add(oitm.RecordId);
						//Build Map for Contact and DuplicateRecordSet
						contactIdToDupRecSetId.put(oitm.RecordId, record.Id);
						iCountRecs++;
					}
					//Break out if more than 2
					if (iCountRecs >= 2) {
						hasRecordsLeft = true;
						break;
					}
				}
			}
		}
		//Begin processing records
		retrieveUsersCommunity();
		processRecords();
		beginMerge();
		//Return Checking for Records Reporcessing
		return hasRecordsLeft;
	}
	/**
	 * Begin Processing DuplicateRecordItems
	 */
	@TestVisible
	protected virtual void processRecords() {
		if (!contactIds.isEmpty()) {
			List<Contact> conRecords = retrieveContacts();
			if (conRecords != null) {
				//Process Contact Records
				for (Contact con : conRecords) {
					Id dupRecSetId = contactIdToDupRecSetId.get(con.Id);
					if (dupRecSetId != null) {
						if (dupRecSetWrappers.containsKey(dupRecSetId)) {
							DuplicateRecordSetWrapper wrap = dupRecSetWrappers.get(dupRecSetId);
							wrap.addContact(con);
							dupRecSetWrappers.put(dupRecSetId, wrap);
						}
					}
				}//EFL
			}
		}
	}
	/**
	 * Begin Merging Contacts
	 */
	@TestVisible
	protected virtual void beginMerge() {
		if (!dupRecSetWrappers.isEmpty()) {
			for (DuplicateRecordSetWrapper oWrap : dupRecSetWrappers.values()) {
				List<ContactList> cList = oWrap.contactRecs;
				Contact masterCon;
				if (cList != null) {
					for (ContactList oRec : cList) {
						Contact rec = oRec.record;
						if (masterCon == null) {
							masterCon = rec;
						} else if (masterCon != null) {
							//Perform Database.merge
							Boolean masterHasComm = mapUserContactId.containsKey(masterCon.Id);
							Boolean childHasComm = mapUserContactId.containsKey(rec.Id);
							//Child has Community Acces make it master
							//Do not Merge if Communities User is found
							if (masterHasComm == false && childHasComm == true && excludeActiveCommunitiesUser == false) {
								//Set the Callista record from Master to Contact to make new Master callista record
								rec.Person_ID_unique__c = masterCon.Person_ID_unique__c;
								mapCompare(rec, masterCon);
							} else if (masterHasComm == true && childHasComm == true) {
								//As documented do not merge if both has community access
								skippedDuplicateRecordSet.add(oWrap.dupRecSetId);
							} else if ((excludeActiveCommunitiesUser == false && masterHasComm == true && childHasComm == false) ||
							           (masterHasComm == false && childHasComm == false)) {
								mapCompare(masterCon, rec);
							}else{
								//Do not Merge if exclude communities User is true
								skippedDuplicateRecordSet.add(oWrap.dupRecSetId);
							}
						}
					}
				}
			}
		}
	}
	@TestVisible
	protected virtual void mapCompare(Contact masterCon, Contact childCon) {
		Map<String, Object> masterFieldsToValue = masterCon.getPopulatedFieldsAsMap();
		Map<String, Object> childFieldsToValue = childCon.getPopulatedFieldsAsMap();
		//Add fields from Master and Child populated
		Set<String> strFields = new Set<String>();
		strFields.addAll(masterFieldsToValue.keySet());
		strFields.addAll(childFieldsToValue.keySet());
		//Retrieve Populated fields of contacts
		if (!strFields.isEmpty()) {
			for (String sFields : strFields) {
				//Checks if Field is Updateable from describe
				Boolean isUpdateable = mapConFieldUpdateAccess.get(sFields).getDescribe().isUpdateable();
				//Exclude Id field and non updateable
				if (mdtPersonMapping.containsKey(sFields) && isUpdateable && sFields != 'Id') {
					Person_Merge_Mapping__mdt mdtConfig = mdtPersonMapping.get(sFields);
					//Begin Compare from MDT Mapping ----
					//Replaces Master Values with Child no null checks
					if (mdtConfig.No_Null_Check_Values__c == true) {
						masterCon.put(sFields, childCon.get(sFields));
					} else {
						//Replaces Null check on Master before replacing with child
						if (masterCon.get(sFields) == null && childCon.get(sFields) != null) {
							masterCon.put(sFields, childCon.get(sFields));
						}
					}
				}
			}
			//Begin Merge
			Database.MergeResult mergeResult = Database.merge(masterCon, childCon);
			if (!mergeResult.isSuccess()) {
				for (Database.Error error : mergeResult.getErrors()) {
					ExLog.add(PersonMergingHelper.class.getName(),
					          Contact.class.getName(),
					          'Merge Result ' + error.getStatusCode(),
					          error.getMessage());
				}
			}
		}
	}
	/**
	 * Retrieves Contacts with fields configured from Custom Metadata
	 * @return Contacts
	 */
	@TestVisible
	private List<Contact> retrieveContacts() {
		String soql = 'SELECT Id';
		if (!mdtPersonMapping.isEmpty()) {
			List<String> sFields = new List<String>(mdtPersonMapping.keySet());
			if(!mdtPersonMapping.containsKey('Person_ID_unique__c')){
                sFields.add('Person_ID_unique__c');
            }
			soql += ',';
			soql += String.join( sFields, ',' );
		}
		soql += ' FROM Contact';
		soql += ' WHERE Id IN:contactIds';
		soql += ' ORDER BY Person_ID_unique__c NULLS LAST, LastModifiedDate';

		return Database.query(soql);
	}
	/**
	 * Retrieves Contacts with fields configured from Custom Metadata
	 * @return Contacts
	 */
	@TestVisible
	private void retrieveUsersCommunity() {
		mapUserContactId = new Map<Id, User>();
		List<User> users = [SELECT Id, ContactId, Username, FirstName, LastName, Email,
		                    CommunityNickname, Alias, TimeZoneSidKey, LocaleSidKey,
		                    EmailEncodingKey, LanguageLocaleKey, ProfileId
		                    FROM User WHERE ContactId IN:contactIds];
		if (users != null) {
			for (User usr : users) {
				mapUserContactId.put(usr.ContactId, usr);
			}
		}
	}
	/**
	 * Retrieves MDT data for Contact Mapping
	 * If Field is added it will override Master with child value
	 */
	@TestVisible
    private void populateMDTMergeMapping() {
        if (mdtPersonMapping == null) {
            mdtPersonMapping = new Map<String, Person_Merge_Mapping__mdt>();
            
            // get mapping definition for each field
            List<Person_Merge_Mapping__mdt> lPMM = Person_Merge_Mapping__mdt.getall().values();
            
            if (lPMM != null) {
                // get all fields from Contact Sobject
                Set<String> contactFields = Schema.SObjectType.Contact.fields.getMap().keyset();
                
                for (Person_Merge_Mapping__mdt mdt : lPMM) {
                    mdtPersonMapping.put(mdt.SObjectField__c, mdt);
                    // only add valid fields i.e. metadata entry has to refer to a valid field
                    if(contactFields.contains(mdt.SObjectField__c.toLowerCase())) {
                        mdtPersonMapping.put(mdt.SObjectField__c, mdt);
                    }
                }
            }
        }
        LogUtilityException.debug('PersonMergeMapping.populateMDTMergeMapping:' + mdtPersonMapping);
    }
	/**
	 * Inner class to encapsulate merging records
	 */
	public class DuplicateRecordSetWrapper {
		public Id dupRecSetId {get; set;}
		public List<ContactList> contactRecs {get; set;}
		//
		public DuplicateRecordSetWrapper(Id drsId) {
			dupRecSetId = drsId;
			contactRecs = new List<ContactList>();
		}
		public void addContact(Contact rec) {
			if (rec.Id != null) {
				contactRecs.add(new ContactList(rec));
				contactRecs.sort();
			}
		}
	}
	/**
	 * Inner class to List Contacts
	 */
	public class ContactList implements Comparable {
		public Contact record {get; set;}
		public ContactList(Contact con) {
			this.record = con;
		}
		/**
		* The comparator method used in sorting
		*
		* @param obj The object to compare to
		* @return the integer value of the comparison between the objects
		* 1 – The current value is greater than the compared value
		* 0 – The current value is equal to the compared value
		* -1 – The current value is less than the compared value
		*/
		public Integer compareTo(Object obj) {
			ContactList cRec = (ContactList)(obj);

			if (this.record.Person_ID_unique__c != null
			        && cRec.record.Person_ID_unique__c == null) {
				return -1;
			}
			if (this.record.Person_ID_unique__c != null
			        && cRec.record.Person_ID_unique__c != null) {
				return 0;
			}

			return 1;
		}
	}
}