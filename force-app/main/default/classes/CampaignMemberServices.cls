/**
 * @author	        Carl Vescovi, PwC
 * @description     Services class to provide CampaignMember sObject centric logical support
 * @group           SRA (Student Recruitment and Admission) / MonTrack
 * @revision        29/07/2017	Nick Guia 		- created qualifyCreateSubscriptionMember and fieldHasChanged <br/>
 * 					27/06/2018 	Nick Guia   	- removed all reference to Subscription_List__c and Subscripton_Member__c (for deletion) <br/>
 * 					12/07/2018	Angelo Rivera 	- New Methods for MonTrack related data and events <br/>
 * 					11/12/2019 	Angelo Rivera 	- Decommissioned unused methods  from Montrack Classic App <br/>
 * 					17/03/2020	Nick Guia 		- Created unsubscribeService <br/>
 * 					11/08/2021	Aref Samad 		- Update attendee count for Group registration (EPBBS-2129)<br/>
 * 		    		SEP.13.2024 Inderpal Dhanoa - Sync TimeZone(MCT-490)
 **/

public class CampaignMemberServices {

	public static final String MONTRACK = 'MonTrack';
	public static final String COMPLETED = 'Completed';
	public static final String CALL_ATTEMPT = 'Call Attempt';
	public static final String BEFORE_DELETE_STRING = 'Before Delete';
	public static final String AFTER_UPDATE_STRING = 'After Update ';

	/*******************************************************************************
	* @description  handles fetching Rec Type Subscription Id
	* @return     Id of Recd Type
	*******************************************************************************/
	public static Id RECORDTYPE_SUBSCRIPTION_MEMBER {
		get {
			if(RECORDTYPE_SUBSCRIPTION_MEMBER == null) {
				RECORDTYPE_SUBSCRIPTION_MEMBER = Schema.SObjectType.CampaignMember
                .getRecordTypeInfosByDeveloperName()
                .get('Subscription_Member')
                .getRecordTypeId();
			}
			return RECORDTYPE_SUBSCRIPTION_MEMBER;
		}
		set;
	}

	/*******************************************************************************
	* @description  handles fetching Rec Type Id
	* @return     Id of Recd Type
	*******************************************************************************/
	public static Id RECORDTYPE_EVENT_ATTENDEE {
		get {
			if(RECORDTYPE_EVENT_ATTENDEE == null) {
				RECORDTYPE_EVENT_ATTENDEE = Schema.SObjectType.CampaignMember
                .getRecordTypeInfosByDeveloperName()
                .get('Event_Attendee')
                .getRecordTypeId();
			}
			return RECORDTYPE_EVENT_ATTENDEE;
		}
		set;
	}

	/*******************************************************************************
	* @description  handles all before delete events. Filter event criteria here
	* @param        newMap - Trigger.newMap context variable
	* @param 		oldMap - Trigger.oldMap context variable
	* @revision     10/08/2018 - APRivera - Created
	*******************************************************************************/
	public static void handleBeforeDelete(Map<Id, CampaignMember> newMap, Map<Id, CampaignMember> oldMap) {
		//filter out and process updates on campaign members
		Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembersUpdate = new Map<Id, List<CampaignMember>>();
		Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembersDelete = new Map<Id, List<CampaignMember>>();
		Set<Id> setContactIds = new Set<Id>();
		filterOutMonTrackCampaignMembers(mapCmpIdLstCmpMembersDelete, mapCmpIdLstCmpMembersUpdate, newMap, oldMap, BEFORE_DELETE_STRING, setContactIds);
		if(!mapCmpIdLstCmpMembersDelete.isEmpty()){
			deleteMonTrackTasks(mapCmpIdLstCmpMembersDelete, setContactIds);
		} 
	}

	/*******************************************************************************
     * @description  handles all after update events. Filter event criteria here
     * @param        newMap - Trigger.newMap context variable
     * @param        oldMap - Trigger.oldMap context variable
     * @revision     12/07/2018 - APRivera - Created
     *******************************************************************************/
	public static void handleAfterUpdate(Map<Id, CampaignMember> newMap, Map<Id, CampaignMember> oldMap){

		//filter out and process updates on campaign members
		Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembersUpdate = new Map<Id, List<CampaignMember>>();
		Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembersDelete = new Map<Id, List<CampaignMember>>();
		Set<Id> setContactIds = new Set<Id>();
		filterOutMonTrackCampaignMembers(mapCmpIdLstCmpMembersDelete, mapCmpIdLstCmpMembersUpdate, newMap, oldMap, AFTER_UPDATE_STRING, setContactIds);
		if(!mapCmpIdLstCmpMembersUpdate.isEmpty()){
			updateMonTrackTasksOwner(mapCmpIdLstCmpMembersUpdate);
		} 	
	}

	/*******************************************************************************
    * @description  handles all after delete events. Filter event criteria here
    * @param        newMap - Trigger.newMap context variable
	* @param        oldMap - Trigger.oldMap context variable
    * @revision     10/08/2018 - APRivera - Created
    *******************************************************************************/
	public static void handleAfterDelete(Map<Id, CampaignMember> newMap, Map<Id, CampaignMember> oldMap) {

	}

	/*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Filter out MonTrack Campaign
    * @param        mapCmpIdLstCmpMembersDelete - map CmpId Lst Cmp Members Delete
	* @param        mapCmpIdLstCmpMembersUpdate - map CmpId Lst Cmp Members Update
	* @param        newMap - Trigger.newMap context variable
	* @param        oldMap - Trigger.oldMap context variable
	* @param        triggerEvent - Trigger Event
	* @param        setContactIds - set Contact Ids
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
	public static void filterOutMonTrackCampaignMembers(Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembersDelete,
			Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembersUpdate,
			Map<Id, CampaignMember> newMap, Map<Id, CampaignMember> oldMap,
			String triggerEvent, Set<Id> setContactIds){
		Set<Id> idKeySet = getMapKeySet(triggerEvent, newMap,oldMap);
		for (CampaignMember cmpMember : [Select Id, CampaignId, Campaign.Recordtype.Name, ContactId, SSA__c
		from CampaignMember where Id in:idKeySet]){
			if(cmpMember.Campaign.Recordtype.Name == MONTRACK) {
				if (triggerEvent == AFTER_UPDATE_STRING) {
					CampaignMember oldCampaignMember = oldMap.get(cmpMember.Id);
					if (cmpMember.SSA__c != oldCampaignMember.SSA__c) {
						buildMonTrackMapOfCmpIdLstCmpMembers(mapCmpIdLstCmpMembersUpdate, cmpMember);
					}
				} else if (triggerEvent == BEFORE_DELETE_STRING) {
					buildMonTrackMapOfCmpIdLstCmpMembers(mapCmpIdLstCmpMembersDelete, cmpMember);
				}
				setContactIds.add(cmpMember.ContactId);
			}
		}
	}

/*******************************************************************************
* @author       Angelo Rivera
* @date         12/07/2018
* @description  returns the correct keyset() depending on the trigger event
* @param    	triggerEvent Event of trigger
* @param		newMap new map
* @param		oldMap old map
* @return		Set<Id> return of Set of IDs
* @revision     12/07/2018 - APRivera - Created
*******************************************************************************/
	public static Set<Id> getMapKeySet(String triggerEvent, Map<Id,CampaignMember> newMap, Map<Id,CampaignMember> oldMap){
		Set<Id> idKeySet = new Set<Id>();
		if(triggerEvent == AFTER_UPDATE_STRING){
			idKeySet = newMap.keySet();
		} else if(triggerEvent == BEFORE_DELETE_STRING){
			idKeySet = oldMap.keySet();
		}
		return idKeySet;
	}

	/*******************************************************************************
	* @author       Angelo Rivera
	* @date         12/07/2018
	* @description  build map of campaign Id and list of campaign members
	* @param	    mapCmpIdLstCmpMembers map of Cmp ids and List of Camp membs
	* @param		cmpMember cmp Member
	* @revision     12/07/2018 - APRivera - Created
	*******************************************************************************/
	public static void buildMonTrackMapOfCmpIdLstCmpMembers(Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembers,
			CampaignMember cmpMember){
		//build map of campaign ids and list of campaign member
		if(!mapCmpIdLstCmpMembers.containsKey(cmpMember.CampaignId)){
			mapCmpIdLstCmpMembers.put(cmpMember.CampaignId, new List<CampaignMember>());
		}			
		mapCmpIdLstCmpMembers.get(cmpMember.CampaignId).add(cmpMember);
	}

	/*******************************************************************************
	* @author       Angelo Rivera
	* @date         12/07/2018
	* @description  Updates MonTrack tasks
	* @param	    mapCmpIdLstCmpMembers map of Cmp Id Lst Cmp Members
	* @revision     12/07/2018 - APRivera - Created
	*******************************************************************************/
	public static void updateMonTrackTasksOwner(Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembers){
		List<Task> lstMonTrackTaskForUpdate = new List<Task>();
		Map<Id, List<Task>> mapCmpIdLstTasks = new Map<Id, List<Task>>();
		Map<Id, Map<Id,Task>> mapCmpIdMapTaskByWhoIds = new Map<Id, Map<Id,Task>>();
		retrieveMonTasks(mapCmpIdMapTaskByWhoIds, mapCmpIdLstTasks, mapCmpIdLstCmpMembers.keySet(), AFTER_UPDATE_STRING);
		if(!mapCmpIdMapTaskByWhoIds.isEmpty()){
			//updates task owner using the SSA field on Campaign members
			for(Id campaignId : mapCmpIdLstCmpMembers.keySet()){
				for(CampaignMember cmpMember : mapCmpIdLstCmpMembers.get(campaignId)){
					if(mapCmpIdMapTaskByWhoIds.get(campaignId).get(cmpMember.ContactId) != null){
						Task tsk = mapCmpIdMapTaskByWhoIds.get(campaignId).get(cmpMember.ContactId);
						tsk.OwnerId = cmpMember.SSA__c;
						lstMonTrackTaskForUpdate.add(tsk);
					}
				}
			}
			if(!lstMonTrackTaskForUpdate.isEmpty()){
				TaskServices.updateTaskRecords(lstMonTrackTaskForUpdate);
			} 
		}
	}

	/*******************************************************************************
    * @author       Angelo Rivera
    * @date         12/07/2018
    * @description  Deletes related MonTrack Tasks of Campaign Members
	* @param	    mapCmpIdLstCmpMembers map of Cmp Id Lst Cmp Members
	* @param	    setContactIds set Contact Ids
    * @revision     12/07/2018 - APRivera - Created
    *******************************************************************************/
	public static void deleteMonTrackTasks(Map<Id, List<CampaignMember>> mapCmpIdLstCmpMembers, Set<Id> setContactIds){
		Map<Id, List<Task>> mapCmpIdLstTasks = new Map<Id, List<Task>>();
		Map<Id, Map<Id,Task>> mapCmpIdMapTaskByWhoIds = new Map<Id, Map<Id,Task>>();
		retrieveMonTasks(mapCmpIdMapTaskByWhoIds, mapCmpIdLstTasks, mapCmpIdLstCmpMembers.keySet(), BEFORE_DELETE_STRING);

		if(!mapCmpIdLstTasks.isEmpty()){
			List<Task> lstMonTrackTaskToDelete = new List<Task>();
			for(Id campaignId : mapCmpIdLstCmpMembers.keySet()){
				for(Task tsk : mapCmpIdLstTasks.get(campaignId)){
					if(setContactIds.contains(tsk.WhoId)){
						lstMonTrackTaskToDelete.add(tsk);
					} 
				}
			}
			if(!lstMonTrackTaskToDelete.isEmpty()){
				TaskServices.deleteTaskRecords(lstMonTrackTaskToDelete);
			} 
		}
	}

	/*******************************************************************************
	* @author       Angelo Rivera
	* @date         12/07/2018
	* @description  Retrieves MonTrack tasks
	* @param	    mapCmpIdMapTaskByWhoIds map Cmp Id Map Task By WhoIds
	* @param	    mapCmpIdLstTasks map Cmp Id Map Task
	* @param	    setCampaignIds set Camp Ids
	* @param	    triggerEvent trigger Event
	* @revision     12/07/2018 - APRivera - Created
	*******************************************************************************/
	public static void retrieveMonTasks(Map<Id, Map<Id,Task>> mapCmpIdMapTaskByWhoIds, Map<Id, List<Task>> mapCmpIdLstTasks,
		Set<Id> setCampaignIds, String triggerEvent){
		String queryString = 'Select Id, Status, Recordtype.Name, Call_Attempt__c, OwnerId, WhatId, WhoId from Task ' +
				'where Recordtype.Name =: MONTRACK and Call_Attempt__c != null and WhatId in: setCampaignIds ';
		if(triggerEvent == AFTER_UPDATE_STRING){
			queryString += 'and Status !=: COMPLETED';
		} 
		if(triggerEvent == BEFORE_DELETE_STRING){
			queryString += 'and (Status =: COMPLETED OR Status =: CALL_ATTEMPT)';
		} 

		List<Task> lstTasks = Database.query(queryString);
		if(!lstTasks.isEmpty()){
			for(Task tsk : lstTasks){
				if(!mapCmpIdMapTaskByWhoIds.containsKey(tsk.WhatId)){
					mapCmpIdMapTaskByWhoIds.put(tsk.WhatId, new Map<Id,Task>());
				}					
				mapCmpIdMapTaskByWhoIds.get(tsk.WhatId).put(tsk.WhoId, tsk);

				if(!mapCmpIdLstTasks.containsKey(tsk.WhatId)){
					mapCmpIdLstTasks.put(tsk.WhatId, new List<Task>());
				}
				mapCmpIdLstTasks.get(tsk.WhatId).add(tsk);
			}
		}
	}

	/*******************************************************************************
    * @author       Ryan Wilson
    * @date         31.Mar.2017
    * @description  method to populate the email field being reference by the Journey Builder in Marketing cloud
    * @revision
    *******************************************************************************/
	public class populateEmailToField implements Triggers.Handler {
		/*******************************************************************************
		* @author       Ryan Wilson
		* @date         31.Mar.2017
		* @description  run method
		*******************************************************************************/
		public void run() {
			for(campaignmember cm : (List<CampaignMember>)Trigger.new){
				if(cm.Email_To__c != null){
					cm.Email_to_Send__c = cm.Email_To__c;
				}
			}
		}
	}


	/*******************************************************************************
    * @author       Mark Johnson - UC Innovation
    * @date         18/2/2019
    * @description  Populate invitee fields
    * @revision
    *******************************************************************************/

	public class populateInviteeFields implements Triggers.Handler {

		Map<Id, Campaign> campaignMap = new Map<Id, Campaign>();
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
		Set<Id> contactIds = new Set<Id>();

		Map<String, String> fieldsToSync = getContactToCampaignMemberMapping();
		/*******************************************************************************
		* @author       Mark Johnson
		* @date         18/2/2019
		* @description  run method
		*******************************************************************************/
		public void run() {
			getParentCampaignRecordTypes();
			queryForContactFields();
			populateFields();
		}

		/*******************************************************************************
		* @description  get Engage_Contact_To_Campaign_Member_Map__mdt custom metadata
		* @return Map<String, String> Map of String
		*******************************************************************************/
		private Map<String, String> getContactToCampaignMemberMapping() {
			Map<String, String> contactToCampaignMemberMapping = new Map<String, String>();
			List<Engage_Contact_To_Campaign_Member_Map__mdt> contactToCampaignMemberMappings = [SELECT Contact_Field_API_Name__c, Campaign_Member_Field_API_Name__c FROM Engage_Contact_To_Campaign_Member_Map__mdt];

			for (Engage_Contact_To_Campaign_Member_Map__mdt mapping : contactToCampaignMemberMappings) {
				contactToCampaignMemberMapping.put(mapping.Campaign_Member_Field_API_Name__c.toLowerCase().trim(), mapping.Contact_Field_API_Name__c.toLowerCase().trim());
			}

			return contactToCampaignMemberMapping;
		}


		/*******************************************************************************
		* @description  Get record type from parent campaign
		*******************************************************************************/
		private void getParentCampaignRecordTypes() {
			Set<Id> campaignIds = new Set<Id>();

			for (CampaignMember campaignMember : (List<CampaignMember>) Trigger.new) {
				campaignIds.add(campaignMember.CampaignId);
				contactIds.add(campaignMember.ContactId);
			}

			campaignMap = new Map<Id, Campaign>([SELECT RecordTypeID FROM Campaign WHERE Id IN: campaignIds]);
		}


		/*******************************************************************************
		* @description  Query for Contact Fields
		*******************************************************************************/
		private void queryForContactFields() {
			contactMap = new Map<Id, Contact>((List<Contact>) Database.query('SELECT ' + String.join(fieldsToSync.values(), ', ') + ' FROM Contact WHERE Id IN :contactIds'));
		}

		/*******************************************************************************
		* @description  Populate invitee fields on Event.
		*******************************************************************************/
		private void populateFields() {
			Id erdaGuestListRecordTypeID = EngageUtils.getRecordTypeIDByDeveloperName(new Campaign(), 'ERDA_Guest_List');

			if (erdaGuestListRecordTypeID == null) {
				return;
			}

			for (CampaignMember campaignMember : (List<CampaignMember>) Trigger.new) {

				if (campaignMap.get(campaignmember.CampaignId).RecordTypeId == erdaGuestListRecordTypeID && campaignMember.ContactId != null) {
					for (String fieldKey : fieldsToSync.keySet()) {
						String fieldValue = fieldsToSync.get(fieldKey);

						if (contactMap.get(campaignMember.ContactId).get(fieldValue) != null && campaignMember.get(fieldKey) == null) {
							campaignMember.put(fieldKey, contactMap.get(campaignMember.ContactId).get(fieldValue));
						}
					}
				}
			}
		}
	}

	/**
	 * @description populates all fields required to activate Email subscription for campaign member
	 * @param	    camp camp
	 * @param	    cm camp memb
	 * @param	    source source
	 * @return		CampaignMember Campaign Member
	 */
	public static CampaignMember subscribeToEmail(Campaign camp, CampaignMember cm, String source) {
		//first, check if the parent campaign's channel type is for Email
		if(camp.Channel_Type__c != null && camp.Channel_Type__c.containsIgnoreCase('Email')) {
			//next, check if the source is a campaign ID, or a String
			Boolean isValidCampaignId = validateCampaignId(source);
			if(isValidCampaignId) {
				cm.Email_Subscription_Source__c = 'Campaign';
				cm.Email_Subscription_Source_Campaign__c = (Id) source;
			} else {
				//if source is a String, only populate sub source
				cm.Email_Subscription_Source__c = source;
			}
			cm.ChannelEmail__c = true;
			cm.Email_Subscribed_Date__c = System.today();
			cm.Active__c = true;
		}
		return cm;
	}

	/**
	 * @description populates all fields required to activate SMS subscription for campaign member
	 * @param	    camp camp
	 * @param	    cm camp memb
	 * @param	    source source
	 * @return		CampaignMember 
	 */
	public static CampaignMember subscribeToSMS(Campaign camp, CampaignMember cm, String source) {
		//first, check if the parent campaign's channel type is for SMS
		if(camp.Channel_Type__c != null && camp.Channel_Type__c.containsIgnoreCase('SMS')) {
			//next, check if the source is a campaign ID, or a String
			Boolean isValidCampaignId = validateCampaignId(source);
			if(isValidCampaignId) {
				cm.SMS_Subscription_Source__c = 'Campaign';
				cm.SMS_Subscription_Source_Campaign__c = (Id) source;
			} else {
				//if source is a String, only populate sub source
				cm.SMS_Subscription_Source__c = source;
			}
			cm.ChannelSMS__c = true;
			cm.SMS_Subscribed_Date__c = System.today();
			cm.Active__c = true;
		}
		return cm;
	}

	/**
	 * @description for unsubscribing a campaign member from a subscription list campaign
	 * @param payloadStr : JSON serialized format of CampaignUnsubPayload class
	 **/
	@AuraEnabled
	public static void unsubscribeService(String payloadStr) {
		CampaignUnsubPayload payload = (CampaignUnsubPayload) JSON.deserialize(payloadStr, CampaignUnsubPayload.class);
		List<CampaignMember> cmList = [SELECT Id, CampaignId, ContactId, Email_Unsubscribed_Date__c,
		                               Email_Unsubscribed_Source__c, SMS_Unsubscribed_Date__c,
		                               SMS_Unsubscribed_Source__c, Last_Unsubscribed_Date__c,
									   Last_Unsubscribed_Reason__c, Last_Unsubscribed_Source__c,
									   Campaign.Name
		                               FROM CampaignMember
		                               WHERE RecordTypeId = :RECORDTYPE_SUBSCRIPTION_MEMBER
									   AND contactId = :payload.contactId
									   AND (
										   Campaign.Name = 'Monash Info and Events for Prospective Students' OR
										   Campaign.Name = 'Market research participation' OR
										   Campaign.Name LIKE '%Open Day%'
										)];
		List<CampaignMember> unsubCm = new List<CampaignMember>();

		for(CampaignMember iCm : cmList) {
			//trim name and remove spaces
			String name = iCm.Campaign.Name.trim().replaceAll(' ', '').toLowerCase();
			if(name.equalsIgnoreCase('monashinfoandeventsforprospectivestudents') && payload.isMieUnsub) {
				iCm = unsubscribeFromCampaign(iCm, payload.source, payload.reason);
				unsubCm.add(iCm);
			} else if(name.equalsIgnoreCase('marketresearchparticipation') && payload.isMrUnsub) {
				iCm = unsubscribeFromCampaign(iCm, payload.source, payload.reason);
				unsubCm.add(iCm);
			} else if(name.containsIgnoreCase('openday') && payload.isOpenDayUnsub) {
				iCm = unsubscribeFromCampaign(iCm, payload.source, payload.reason);
				unsubCm.add(iCm);
			}
		}

		if(!unsubCm.isEmpty()) {
			update unsubCm;
		}
	}

	/**
	* @description for updating unsubscribe fields
	* @param cm : Campaign Member record
	* @param source : Unsubscribe source
	* @param reason : reason for unsubscribe
	* @return CampaignMember
	**/
	private static CampaignMember unsubscribeFromCampaign(CampaignMember cm, String source, String reason) {
		//Email
		cm.Email_Unsubscribed_Date__c = Date.today();
		cm.Email_Unsubscribed_Source__c = source;

		//SMS
		cm.SMS_Unsubscribed_Date__c = Date.today();
		cm.SMS_Unsubscribed_Source__c = source;

		cm.Last_Unsubscribed_Date__c = System.now();
		//only update reason if not blank
		if(String.isNotBlank(reason)) {
			cm.Last_Unsubscribed_Reason__c = reason;
		}
		cm.Last_Unsubscribed_Source__c = source;

		cm.Active__c = false;

		return cm;
	}

	/**
	 * @description check if the object input is a valid Campaign ID
	 * @param o : object input
	 * @return Boolean returns Boolean variable
	 */
	public static Boolean validateCampaignId(Object o) {
		Boolean isValid = false;
		try {
			Id campId = (Id) o;
			if(campId.getSObjectType() == Campaign.SObjectType) {
				isValid = true;
			}
		} catch(Exception e) {
			//silent handling
			System.debug(LoggingLevel.INFO, o + 'is not a valid Campaign ID');
		}
		return isValid;
	}

	/*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         11/09/2023
    * @description  Campaign Un sub Pay load
    * @revision     Initial Version
    *******************************************************************************/
	public class CampaignUnsubPayload {
		/*******************************************************************************
		* @description  ContactId Getter/Setter method
		*******************************************************************************/
		public String contactId {get; set;}
		/*******************************************************************************
		* @description  isMieUnsub Getter/Setter method
		*******************************************************************************/
		public Boolean isMieUnsub {get; set;}
		/*******************************************************************************
		* @description  isOpenDayUnsub Getter/Setter method
		*******************************************************************************/
		public Boolean isOpenDayUnsub {get; set;}
		/*******************************************************************************
		* @description  isMrUnsub Getter/Setter method
		*******************************************************************************/
		public Boolean isMrUnsub {get; set;}
		/*******************************************************************************
		* @description  source Getter/Setter method
		*******************************************************************************/
		public String source {get; set;}
		/*******************************************************************************
		* @description  reason Getter/Setter method
		*******************************************************************************/
		public String reason {get; set;}

		public CampaignUnsubPayload(){ }
	}

	/*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         11/09/2024
    * @description  Set Time Zone
    * @revision     11/09/2024 - Initial Version
    *******************************************************************************/
    public class SetPureCloudTimeZone extends TriggerAbstract{

		Set<Id> linkedContacts = new Set<Id>();
		Id assesseRecordTypeId = Schema.SObjectType.CampaignMember.getRecordTypeInfosByName().get('Assessee').getRecordTypeId();
		Id genericRecordTypeId = Schema.SObjectType.CampaignMember.getRecordTypeInfosByName().get('Generic').getRecordTypeId();
		String defaultTimeZone = 'Australia/Sydney (+11:00)';
        public override void process(SObject record) {

            CampaignMember newCampaignMember = (CampaignMember)record;

            if(newCampaignMember.RecordTypeId==assesseRecordTypeId || newCampaignMember.RecordTypeId==genericRecordTypeId){
				linkedContacts.add(newCampaignMember.ContactId);
				records.add(record);
            }
        }

		/*******************************************************************************
		* @author       Inderpal Dhanoa
		* @date         11/09/2024
		* @description  Exec Method
		*******************************************************************************/
        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
				Map<Id, String> contactIdWithTimeZoneValue = fetchTimeZonePicklistValues(linkedContacts);
				String timeZone;
				for(CampaignMember newCampaignMember : (List<CampaignMember>)records){
					timeZone = defaultTimeZone;
					if(contactIdWithTimeZoneValue.containsKey(newCampaignMember.ContactId)){
						timeZone = contactIdWithTimeZoneValue.get(newCampaignMember.ContactId);
					}	
					newCampaignMember.purecloud__Time_Zone__c = timeZone;				
				}
            }
        }

		/**
		 * @description check if the object input is a valid Campaign ID
		 * @param linkedContacts : linked Contacts
		 * @return Map<Id, String> returns Map variable
		 */
		private Map<Id, String> fetchTimeZonePicklistValues(Set<Id> linkedContacts){
			// The Picklist names on Campaign Member's Time Zone field are different 
			// from the Picklist Names on the TIme ZOne field on the Phone Obj (Lookup Country)
			Map<String, String> timeZoneLabelWithAPI = new Map<String, String>();
			Map<Id, String> contactIdWithTimeZoneValue = new Map<Id, String>();
			String[] arrayTimeZoneLabelWithOffset;
			for(Schema.PicklistEntry pickListVal : CampaignMember.purecloud__Time_Zone__c.getDescribe().getPicklistValues()){
				arrayTimeZoneLabelWithOffset = (String.valueOf(pickListVal.getLabel())).split(' ');
				timeZoneLabelWithAPI.put(arrayTimeZoneLabelWithOffset[0], pickListVal.getValue());
			}
			for(Phone__c linkedPhoneRecd :  [SELECT Contact__c, Name, TimeZone__c 
											FROM Phone__c 
											WHERE Contact__c IN :linkedContacts AND 
											Is_Primary__c = true AND
											is_Active__c = true]){
				if(timeZoneLabelWithAPI.containsKey(linkedPhoneRecd.TimeZone__c)){
					contactIdWithTimeZoneValue.put(linkedPhoneRecd.Contact__c, timeZoneLabelWithAPI.get(linkedPhoneRecd.TimeZone__c));
				}
			}
			return contactIdWithTimeZoneValue;
		}
    }

	 /*******************************************************************************
    * @author       Aref Samad
    * @date         11/08/2021
    * @description  Update number of attendees in Campaign Member for Group Attendee
    * @revision     11/08/2021 - Initial Version
    *******************************************************************************/
    public class UpdateNumberOfAttendees extends TriggerAbstract{

		Set<Id> attendeeIdList=new Set<Id>();
        public override void process(SObject record) {

            CampaignMember newCampaignMember = (CampaignMember)record;

            if(newCampaignMember.conference360__Attendee__c!=null && newCampaignMember.RecordTypeId==RECORDTYPE_EVENT_ATTENDEE){
                records.add(newCampaignMember);
				attendeeIdList.add(newCampaignMember.conference360__Attendee__c);
            }
        }

        public override void execute() {
            //Checks if there are records to be processed
            if(!records.isEmpty()){
                updateAttendeeCountInCampaignMember(records);
            }
        }

		/**
		 * @description update Attendee Count In Campaign Member
		 * @param campaignMemberList : campaign Member List
		 */
		@TestVisible
		private void updateAttendeeCountInCampaignMember(List<CampaignMember> campaignMemberList)
		{
			try {

				Map<Id,conference360__Attendee__c> allLinkedAttendeeMap=new Map<Id,conference360__Attendee__c>(
					[Select Id,conference360__Attendee_Group__c,is_Primary_Registrant__c From conference360__Attendee__c
					where Id in :attendeeIdList]);

				Set<Id> attendeeGroupIdList=new Set<Id>();
				for(conference360__Attendee__c attendee:allLinkedAttendeeMap.values())
				{
					if (attendee.conference360__Attendee_Group__c!=null && attendee.is_Primary_Registrant__c==true)
					{
						attendeeGroupIdList.add(attendee.conference360__Attendee_Group__c);
					}
				}

				Map<Id, AggregateResult> groupCounts = new Map<Id, AggregateResult>(
					[SELECT conference360__Attendee_Group__c Id, COUNT(Id) total
					FROM conference360__Attendee__c
					WHERE conference360__Attendee_Group__c = :attendeeGroupIdList
					and (conference360__Contact__c=null or is_Primary_Registrant__c=true)
					GROUP BY conference360__Attendee_Group__c]);

				// system.debug('@@@@@ groupCounts : ' + groupCounts);

				for(CampaignMember member:campaignMemberList)
				{
					conference360__Attendee__c attendee=allLinkedAttendeeMap.get(member.conference360__Attendee__c);

					if (attendee!=null && attendee.conference360__Attendee_Group__c!=null)
					{
						if (attendee.is_Primary_Registrant__c==true)
						{
							member.Number_of_Attendees__c=(Integer)groupCounts.get(attendee.conference360__Attendee_Group__c)?.get('total');
						}
						else {
							member.Number_of_Attendees__c=1;
						}
					}
				}

			} catch(Exception e) {
				LogUtilityException.logException(e);
				System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
			}
			finally {
				LogUtilityException.getLimits();
			}

		}
    }
}