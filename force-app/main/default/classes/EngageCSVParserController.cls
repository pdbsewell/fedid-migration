/**
 * Class for assignment of parsed CSV data to Campaign Members
 * 
 * @author Mark Johnson - UC Innovation
 * @date         18/02/2019    
 * @revision
 */

public class EngageCSVParserController {
	
	private static Map<String, String> eventMemberToContactIDMapping = getEventMemberToContactIDMapping();
	private static List<String> requiredFields = getRequiredFields();
	private static Map<String, String> interimFieldMap = getInterimFieldMapping();
	private static List<String> fieldsOnTemplate = getFieldsOnTemplate();

 	private static String errorMessage = '';


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  get Engage_UniqueID_Mapping__mdt custom metadata
	*******************************************************************************/  

	@TestVisible
 	private static Map<String, String> getEventMemberToContactIDMapping() {
 		Map<String, String> eventMemberToContactIDMapping = new Map<String, String>();
 		List<Engage_UniqueID_Mapping__mdt> eventMemberToContactIDMappings = [SELECT Contact_Unique_ID_Field_Name__c, Campaign_Member_Unique_ID_Field_Name__c FROM Engage_UniqueID_Mapping__mdt];

 		if (eventMemberToContactIDMappings.isEmpty()) {
 			errorMessage += 'Please contact your system administrator. Engage UniqueID Mapping Custom Metadata Type must be populated.';
 		}

 		for (Engage_UniqueID_Mapping__mdt mapping : eventMemberToContactIDMappings) {
			eventMemberToContactIDMapping.put(mapping.Campaign_Member_Unique_ID_Field_Name__c.toLowerCase().trim(), mapping.Contact_Unique_ID_Field_Name__c.toLowerCase().trim());
 		}

 		return eventMemberToContactIDMapping;
 	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  get Engage_Campaign_Member_To_Interim_Map__mdt custom metadata
	*******************************************************************************/  

	@TestVisible
  	private static Map<String, String> getInterimFieldMapping() {
 		Map<String, String> interimFieldMap = new Map<String, String>();
 		List<Engage_Campaign_Member_To_Interim_Map__mdt> interimFieldMapMetadata = [SELECT Interim_Field_API_Name__c, Campaign_Member_Field_API_Name__c FROM Engage_Campaign_Member_To_Interim_Map__mdt];

 		if (interimFieldMapMetadata.isEmpty()) {
 			errorMessage += 'Please contact your system administrator. Engage Campaign Member To Interim Map Custom Metadata Type must be populated.';
 		}

 		for (Engage_Campaign_Member_To_Interim_Map__mdt mapping : interimFieldMapMetadata) {
			interimFieldMap.put(mapping.Campaign_Member_Field_API_Name__c.toLowerCase().trim(), mapping.Interim_Field_API_Name__c.toLowerCase().trim());
 		}

 		return interimFieldMap;
 	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  get Engage_Required_Fields_CSV_Template__mdt custom metadata
	*******************************************************************************/  

	@TestVisible
  	private static List<String> getRequiredFields() {
 		List<String> requiredFields = new List<String>();
 		List<Engage_Required_Fields_CSV_Template__mdt> requiredFieldsMetadata = [SELECT Required_Field_API_Name__c FROM Engage_Required_Fields_CSV_Template__mdt];

 		if (requiredFieldsMetadata.isEmpty()) {
 			errorMessage += 'Please contact your system administrator. Engage Required Fields CSV Template Custom Metadata Type must be populated.';
 		}

 		for (Engage_Required_Fields_CSV_Template__mdt mapping : requiredFieldsMetadata) {
			requiredFields.add(mapping.Required_Field_API_Name__c.toLowerCase().trim());
 		}

 		return requiredFields;
 	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  get Engage_Fields_on_Events_CSV_Template__mdt custom metadata
	*******************************************************************************/  

	@TestVisible
  	private static List<String> getFieldsOnTemplate() {
 		List<String> fieldsOnTemplate = new List<String>();
 		List<Engage_Fields_on_Events_CSV_Template__mdt> fieldsOnTemplateMetadata = [SELECT Fields_On_Template__c FROM Engage_Fields_on_Events_CSV_Template__mdt];

 		if (fieldsOnTemplateMetadata.isEmpty()) {
 			errorMessage += 'Please contact your system administrator. Engage Required Fields CSV Template Custom Metadata Type must be populated.';
 		}

 		for (Engage_Fields_on_Events_CSV_Template__mdt mapping : fieldsOnTemplateMetadata) {
 			for (String field : mapping.Fields_On_Template__c.split(',')) {
 				fieldsOnTemplate.add(field.trim());
 			}
 		}

 		return fieldsOnTemplate;
 	}



	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Supports creation/update of campaign members and creation/update of interims representing campaign members
	* @param 		eventMemberValueList - fields and values of campaignmembers in JSON format.
	* @param 		campaignId - ID of parent ERDA campaign we are operating on.
	*******************************************************************************/  

	@AuraEnabled
	public static String createEventMembers(String eventMemberValueList, Id campaignId) {
		try {

			if (checkForError()) {
				return errorMessage;
			}

			List<CampaignMember> potentialEventMemberList = new List<CampaignMember>();
			Map<String, Set<String>> uniqueIDs = new Map<String, Set<String>>();

			populatePotentialEventMemberListAndMapIDs(eventMemberValueList, potentialEventMemberList, uniqueIDs);

			if (checkForError()) {
				return errorMessage;
			}

			List<Campaign> existingGuestLists = getExistingGuestLists(campaignId);

			potentialEventMemberList = processExistingCampaignMembers(potentialEventMemberList, existingGuestLists);

			potentialEventMemberList = processExistingInterims(potentialEventMemberList, existingGuestLists);

			if (potentialEventMemberList.isEmpty()) {
				return errorMessage;
			}

			//Create new guest list to associate new interims/event members
			Campaign guestListToAddNewMembersTo = createNewGuestList(campaignId);

			potentialEventMemberList = processNewCampaignMembers(guestListToAddNewMembersTo, potentialEventMemberList, uniqueIDs);

			processNewInterims(potentialEventMemberList, guestListToAddNewMembersTo);

		} catch (DmlException ex) {
			errorMessage += ex.getMessage();
		} catch (SObjectException ex) {
			errorMessage += ex.getMessage();
		} catch (NoAccessException ex) {
			errorMessage += 'You do not have access to perform this action. Please contact your System Administrator.';
		}

		return errorMessage;
	}



	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  If an error message exists return true
	*******************************************************************************/  

	private static Boolean checkForError() {
		if (errorMessage == '') {
			return false;
		}

		return true;
	}


 	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Iterates through all campaign members and creates data structures for easy access. 
					Populates potentialEventMemberList/uniqueIDs. Performs validations per campaign member.
	* @param 		eventMemberValueList - fields and values of campaignmembers in JSON format.
	* @param 		potentialEventMemberList - list of campaign members that we are attempting to upload into the system.
	* @param 		uniqueIDs - map of field names to sets of uniqueID values to use when querying
	*******************************************************************************/  

 	private static void populatePotentialEventMemberListAndMapIDs(String eventMemberValueList, List<CampaignMember> potentialEventMemberList, Map<String, Set<String>> uniqueIDs) {
		List<List<String>> eventMemberDataList = (List<List<String>>) JSON.deserialize(eventMemberValueList, List<List<String>>.class);
		Integer memberCount = 1;

		//Create list of potential campaign members, before checking for duplicates, or checking for corresponding contacts
		for (List<String> memberList : eventMemberDataList) {
			CampaignMember campaignMember = new CampaignMember();

			for (Integer fieldIndex = 0; fieldIndex < fieldsOnTemplate.size(); fieldIndex++) {
				String campaignMemberFieldName = fieldsOnTemplate[fieldIndex];
				String campaignMemberFieldValue = memberList[fieldIndex];

				//IF a requiired field is not present, populate error message.
				errorMessage += validateRequiredFields(campaignMemberFieldName, campaignMemberFieldValue, memberCount);

				if (campaignMemberFieldValue != null) {
					String campaignMemberFieldNameLowerCase = campaignMemberFieldName.toLowerCase();

					if (eventMemberToContactIDMapping.keySet().contains(campaignMemberFieldNameLowerCase)) {

						String correspondingContactIDFieldName = eventMemberToContactIDMapping.get(campaignMemberFieldNameLowerCase);

						if (uniqueIDs.containsKey(correspondingContactIDFieldName)) {
							if (!uniqueIDs.get(correspondingContactIDFieldName).add(campaignMemberFieldValue)) {
								//IF duplicate IDs are present within the spreadsheet, populate error message
								errorMessage += 'Row ' + memberCount + ': Duplicate ID Found (' + campaignMemberFieldNameLowerCase + ': ' + campaignMemberFieldValue +')' + '\n';
							}
						} else {
							uniqueIDs.put(correspondingContactIDFieldName, new Set<String>{campaignMemberFieldValue});
						}
					}

					//IF issues with assigning field values, populate error message 
					errorMessage += assignFieldValues(campaignMember, campaignMemberFieldName, campaignMemberFieldValue, memberCount);
				}
			}

			potentialEventMemberList.add(campaignMember);
			memberCount++;
		}
 	}


 	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Check for required fields that are not populated, populate error message we find one.
	* @param 		fieldName - name of field that we are checking is required.
	* @param 		fieldValue - value of field that we are checking is required. If null, populate error message.
	* @param 		rowNumber - number of the row that the issue is present on.
	*******************************************************************************/  

	private static String validateRequiredFields(String fieldName, String fieldValue, Integer rowNumber) {
		if (requiredFields.contains(fieldName.toLowerCase()) && fieldValue == null) {
			return 'Row ' + rowNumber + ': Missing required field ' + fieldName + '\n';
		}

		return '';
	}


 	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Perform validations, then assign values to fields
	* @param 		campaignMember - campaign member to assign field values to.
	* @param 		campaignMemberFieldName - campaign member field values to assign per field.
	* @param 		rowNumber - number of the row that the issue is present on, for error reporting.
	*******************************************************************************/  

	private static String assignFieldValues(CampaignMember campaignMember, String campaignMemberFieldName, String campaignMemberFieldValue, Integer rowNumber) {
		Map<String, Schema.SObjectField> campaignFieldDescribe = CampaignMember.getSObjectType().getDescribe().fields.getMap();
		Schema.DisplayType displayType = campaignFieldDescribe.get(campaignMemberFieldName).getDescribe().getType();

		Object newValue = campaignMemberFieldValue;

		//Perform validations before assigning.
		//Boolean values must be 'Y, N, 1, 0 or null'
		//Date values must be parseable by Date class
		//Email values must pass validateEmail() check.
		if (displayType == Schema.DisplayType.Boolean) {
			if (campaignMemberFieldValue == 'Y' || campaignMemberFieldValue == '1') {
				newValue = true;
			} else if (campaignMemberFieldValue == 'N' || campaignMemberFieldValue == null || campaignMemberFieldValue == '0') {
				newValue = false;
			} else {
				return 'Row ' + rowNumber + ': Incorrect input for boolean value. Please enter (Y/N), or leave blank. (' + campaignMemberFieldName + ')\n';
			}
		} else if (displayType == Schema.DisplayType.Date) {
			try {
				newValue = Date.parse(campaignMemberFieldValue);
			} catch(Exception ex) {
				return 'Row ' + rowNumber + ': Incorrect input for Date field. Please Enter in the following format: [dd/mm/yyyy]. (' + campaignMemberFieldName + ')\n';
			}
		} else if (displayType == Schema.DisplayType.Email) {
			if (!validateEmail(campaignMemberFieldValue)) {
				return 'Row ' + rowNumber + ': Incorrect format for Email field. (' + campaignMemberFieldName + ')\n';
			}
		}

		campaignMember.put(campaignMemberFieldName, newValue);
		return '';
	}


 	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Validate email for data integrity purposes
	* @param 		email - email to validate
	*******************************************************************************/  

	private static Boolean validateEmail(String email) {
		//SOURCE: http://www.regular-expressions.info/email.html
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
		Pattern myPattern = Pattern.compile(emailRegex);
		Matcher myMatcher = MyPattern.matcher(email);

		if (!myMatcher.matches()) {
		    return false;
		}

		return true;	
	}


 	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Gets list of existing guest lists related to parent ERDA campaign
	* @param 		campaignId - ID of parent ERDA campaign we are operating on.
	*******************************************************************************/ 

	private static List<Campaign> getExistingGuestLists(Id campaignId) {
		String guestListQuery = 'SELECT Id, Parent_ERDA_Event__r.Name, (Select ' + String.join(fieldsOnTemplate, ', ') + ' FROM CampaignMembers), ' + 
								'(Select ' + String.join(interimFieldMap.values(), ', ') + ' FROM Interims__r) FROM Campaign WHERE Parent_ERDA_Event__c =: campaignId';

		return Database.query(guestListQuery);
	}



	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Finds existing campaign members, Updates them, then returns list of campaign members that were not operated upon
	* @param 		potentialEventMemberList - list of campaign members that we are attempting to upload into the system.
	* @param 		existingGuestLists - List of existing guest lists related to the parent campaign
	*******************************************************************************/  

 	private static List<CampaignMember> processExistingCampaignMembers(List<CampaignMember> potentialEventMemberList, List<Campaign> existingGuestLists) {
 		//Check for existing campaign members with the same unique IDs. Update these.
		Map<String, Map<String, CampaignMember>> uniqueIDCampaignMemberMap = new Map<String, Map<String, CampaignMember>>();

		if (!existingGuestLists.isEmpty()) {
			uniqueIDCampaignMemberMap = getExistingCampaignMembers(existingGuestLists);
			updateExistingCampaignMembers(uniqueIDCampaignMemberMap, potentialEventMemberList);
		}
		
		List<CampaignMember> potentialEventMembersWithoutExistingMembersList = new List<CampaignMember>();

		for (CampaignMember potentialEventMember : potentialEventMemberList) {
			if (potentialEventMember.Id == null) {
				potentialEventMembersWithoutExistingMembersList.add(potentialEventMember);
			}
		}

		return potentialEventMembersWithoutExistingMembersList;
 	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Gets all existing campaign members, return a map uniqueID Field Names to Map of uniqueIDs to campaign members.
	* @param 		existingGuestLists - List of existing guest lists related to the parent campaign
	*******************************************************************************/ 

	private static Map<String, Map<String, CampaignMember>> getExistingCampaignMembers(List<Campaign> existingGuestLists) {
		Map<String, Map<String, CampaignMember>> uniqueIDMap = new Map<String, Map<String, CampaignMember>>();

		for (String uniqueIDField : eventMemberToContactIDMapping.keySet()) {
			uniqueIDMap.put(uniqueIDField, new Map<String, CampaignMember>());

			for (Campaign existingGuestList : existingGuestLists) {
				for (CampaignMember campaignMember : existingGuestList.CampaignMembers) {
					String uniqueID = (String) campaignMember.get(uniqueIDField);

					if (uniqueID != null) {
						uniqueIDMap.get(uniqueIDField).put(uniqueID, campaignMember);
					}
				}
			}
		}

		return uniqueIDMap;
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Updates any existing campaign members that were found.
	* @param 		uniqueIDMap - a map uniqueID Field Names to Map of uniqueIDs to campaign members.
	* @param 		potentialEventMemberList - list of campaign members that we are attempting to upload into the system.
	*******************************************************************************/ 

	private static void updateExistingCampaignMembers(Map<String, Map<String, CampaignMember>> uniqueIDMap, List<CampaignMember> potentialEventMemberList) {
		Set<CampaignMember> campaignMembersToUpdate = new Set<CampaignMember>();

		for (CampaignMember campaignMember : potentialEventMemberList) {
			for (String field : eventMemberToContactIDMapping.keySet()) {
				Map<String, CampaignMember> uniqueIdToCampaignMemberMap = uniqueIDMap.get(field);
				String uniqueId = (String) campaignMember.get(field);

				if (uniqueIdToCampaignMemberMap != null && uniqueId != null) {
					CampaignMember correspondingCampaignMember = uniqueIdToCampaignMemberMap.get(uniqueId);

					if (correspondingCampaignMember != null) {
						campaignMember.Id = correspondingCampaignMember.Id;
						campaignMembersToUpdate.add(campaignMember);
					}
				}
			}
		}

		update new List<CampaignMember>(campaignMembersToUpdate);
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Finds existing Interims, Updates them, then returns list of campaign members that were not operated upon
	* @param 		potentialEventMemberList - list of campaign members that we are attempting to upload into the system.
	* @param 		existingGuestLists - List of existing guest lists related to the parent campaign
	*******************************************************************************/  

 	private static List<CampaignMember> processExistingInterims(List<CampaignMember> potentialEventMemberList, List<Campaign> existingGuestLists) {
 		//Check for existing Interims with the same unique IDs. Update these.
		Map<String, Map<String, Ucinn_ascendv2__Interim__c>> uniqueIDInterimMap = new Map<String, Map<String, Ucinn_ascendv2__Interim__c>>();

		if (!existingGuestLists.isEmpty()) {
			uniqueIDInterimMap = getExistingInterims(existingGuestLists);
			potentialEventMemberList = updateExistingInterims(uniqueIDInterimMap, potentialEventMemberList);
		}

		return potentialEventMemberList;
 	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Gets all existing interims, return a map uniqueID Field Names to Map of uniqueIDs to interims.
	* @param 		existingGuestLists - List of existing guest lists related to the parent campaign
	*******************************************************************************/ 

 	private static Map<String, Map<String, Ucinn_ascendv2__Interim__c>> getExistingInterims(List<Campaign> existingGuestLists) {
		Map<String, Map<String, Ucinn_ascendv2__Interim__c>> uniqueIDMap = new Map<String, Map<String, Ucinn_ascendv2__Interim__c>>();

		for (String iDField : eventMemberToContactIDMapping.keySet()) {
			uniqueIDMap.put(iDField, new Map<String, Ucinn_ascendv2__Interim__c>());

			for (Campaign existingGuestList : existingGuestLists) {
				for (Ucinn_ascendv2__Interim__c campaignMember : existingGuestList.Interims__r) {

					if (interimFieldMap.containsKey(iDField)) {
						String uniqueID = (String) campaignMember.get(interimFieldMap.get(iDField));

						if (uniqueID != null) {
							uniqueIDMap.get(iDField).put(uniqueID, campaignMember);
						}
					}
				}
			}
		}

		return uniqueIDMap;
	}



	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Updates any existing interims that were found.
	* @param 		uniqueIDMap - a map uniqueID Field Names to Map of uniqueIDs to interims.
	* @param 		potentialEventMemberList - list of campaign members that we are attempting to upload into the system.
	*******************************************************************************/ 

	private static List<CampaignMember> updateExistingInterims(Map<String, Map<String, Ucinn_ascendv2__Interim__c>> uniqueIDMap, List<CampaignMember> potentialEventMemberList) {
		Set<Ucinn_ascendv2__Interim__c> interimsToUpdate = new Set<Ucinn_ascendv2__Interim__c>();
		List<CampaignMember> remainingCampaignMembers = new List<CampaignMember>();

		for (CampaignMember campaignMember : potentialEventMemberList) {
			Boolean correspondingInterimFound = false;

			for (String field : eventMemberToContactIDMapping.keySet()) {
				Map<String, Ucinn_ascendv2__Interim__c> uniqueIdToInterimMap = uniqueIDMap.get(field);

				String uniqueId = (String) campaignMember.get(field);

				if (uniqueIdToInterimMap != null && uniqueId != null) {
					Ucinn_ascendv2__Interim__c correspondingInterim = uniqueIdToInterimMap.get(uniqueId);

					if (correspondingInterim != null) {
						correspondingInterimFound = true;

						for (String keyCampaignMemberField : interimFieldMap.keySet()) {
							if (campaignMember.get(keyCampaignMemberField) != null) {

								correspondingInterim.put(interimFieldMap.get(keyCampaignMemberField), campaignMember.get(keyCampaignMemberField));
							}
						}

						interimsToUpdate.add(correspondingInterim);
					}
				}
			}

			if (correspondingInterimFound == false) {
				remainingCampaignMembers.add(campaignMember);
			}
		}

		update new List<Ucinn_ascendv2__Interim__c>(interimsToUpdate);

		return remainingCampaignMembers;
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Creates a new guest list so that we can add the remaining potential campaign members to the campaign
	* @param 		campaignId - ID of parent ERDA campaign we are operating on.
	*******************************************************************************/ 

	private static Campaign createNewGuestList(Id campaignId) {
		List<Campaign> campaignList = [SELECT Name FROM Campaign WHERE Id = :campaignId];

		//MARK TBD: Rename guestlist to something more specific
		Campaign newGuestList = new Campaign(Name = campaignList[0].Name + ': Guest List', Parent_ERDA_Event__c = campaignId, RecordTypeId = EngageUtils.getRecordTypeIDByDeveloperName(new Campaign(), 'ERDA_Guest_List'));

		insert newGuestList;

		return newGuestList;
	}



	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  Operates on any potential campaign members that did not have corresponding campaign members/interims in the system.
	* @param 		guestListToAddNewMembersTo - a new guest list that the new campaign members/interims will lookup to
	* @param 		potentialEventMemberList - list of campaign members that we are attempting to upload into the system.
	* @param 		uniqueIDs - Map of uniqueID Name to Set of IDs
	*******************************************************************************/ 

 	private static List<CampaignMember> processNewCampaignMembers(Campaign guestListToAddNewMembersTo, List<CampaignMember> potentialEventMemberList, Map<String, Set<String>> uniqueIDs) {
		Map<String, Map<String, Id>> uniqueIDContactMap = getRelatedContacts(uniqueIDs);
		createNewCampaignMembers(potentialEventMemberList, uniqueIDContactMap, guestListToAddNewMembersTo);

		//For any remaining, create Interims for these.
		List<CampaignMember> potentialEventMembersToCreateInterimsFor = new List<CampaignMember>();

		for (CampaignMember potentialEventMember : potentialEventMemberList) {
			if (potentialEventMember.CampaignId == null) {
				potentialEventMembersToCreateInterimsFor.add(potentialEventMember);
			}
		}

		return potentialEventMembersToCreateInterimsFor;
 	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  For getting all contacts in the system that have matching uniqueIDs to those entered on the CSV
	* @param 		uniqueIDs - Map of uniqueID Name to Set of IDs
	*******************************************************************************/ 

	private static Map<String, Map<String, Id>> getRelatedContacts(Map<String, Set<String>> uniqueIDs) {
		//NOTE: Here we dynamically construct a query and plug in sets of data. We have potential for hundreds of IDs, so we cannot manually append the sets of IDs as strings, as there are limits on query length.
		//		Therefore we must use salesforce's built in dynamic query functionality, to add sets of unique IDs as variables in the form of "IN: uniqueIDSet0".
		//		This presents us with an issue, as the is created at runtime, gathering data from each variable. Apex does not allow for "dynamic variables", and does not allow us to reference indexed data either.
		//		In conclusion, if we want to keep performance in mind, and consolidate to 1 query, we are limited to a set amount of unique IDs that we are allowed to process, based on how many variables we create here.
		//		Currently we allow for 5 different unique IDs, and have 5 variables to account for this.

		Boolean executeQuery = false;

		Set<String> uniqueIDSet0 = new Set<String>();
		Set<String> uniqueIDSet1 = new Set<String>();
		Set<String> uniqueIDSet2 = new Set<String>();
		Set<String> uniqueIDSet3 = new Set<String>();
		Set<String> uniqueIDSet4 = new Set<String>();

		Integer fieldIndex = 0;

		String queryString = 'SELECT Id, ' + String.join(new List<String>(eventMemberToContactIDMapping.values()), ', ') + ' FROM Contact WHERE';

		for (String fieldName : eventMemberToContactIDMapping.values()) {
			if (uniqueIDs.containsKey(fieldName)) {
				if (executeQuery == true) {
					queryString += ' OR ';
				}

				executeQuery = true;

				//Assign to variables above based on index of fieldName
				switch on fieldIndex {
					when 0 {
					   	uniqueIDSet0 = uniqueIDs.get(fieldName);
					} when 1 {
					   	uniqueIDSet1 = uniqueIDs.get(fieldName);
					} when 2 {
					   	uniqueIDSet2 = uniqueIDs.get(fieldName);
					} when 3 {
						uniqueIDSet3 = uniqueIDs.get(fieldName);
					} when 4 {
						uniqueIDSet4 = uniqueIDs.get(fieldName);
					}

				}

				//Reference variables above dynamically.
				queryString += ' ' + fieldName + ' IN: uniqueIDSet' + fieldIndex;
				fieldIndex++;
			}	
		}

		List<Contact> contactList = new List<Contact>();
        
		if (!uniqueIDs.isEmpty()) {
			contactList = Database.query(queryString);
		}

		Map<String, Map<String, Id>> uniqueIDMap = new Map<String, Map<String, Id>>();

		//Population of unique ID mapping in the form of unique ID Name to Map of unique IDs to Contact IDs
		for (String idField : eventMemberToContactIDMapping.keySet()) {
			String contactUniqueIDField = eventMemberToContactIDMapping.get(idField);
			uniqueIDMap.put(idField, new Map<String, Id>());

			for (Contact contact : contactList) {
				String uniqueID = (String) contact.get(contactUniqueIDField);

				if (uniqueID != null) {
					uniqueIDMap.get(idField).put(uniqueID, contact.Id);
				}
			}
		}

		return uniqueIDMap;
	}


	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  This creates campaign members for those that have existing contacts in the system.
	* @param 		potentialEventMemberList - list of remaining campaign members that have not been yet operated on.
	* @param 		uniqueIDs - unique ID mapping in the form of unique ID Name to Map of unique IDs to Contact IDs
	* @param 		guestListToAddNewMembersTo - a new guest list that the new campaign members/interims will lookup to
	*******************************************************************************/ 

	private static void createNewCampaignMembers(List<CampaignMember> potentialEventMemberList, Map<String, Map<String, Id>> uniqueIDMap, Campaign guestListToAddNewMembersTo) {
		Set<CampaignMember> campaignMembersToInsert = new Set<CampaignMember>();

		for (CampaignMember campaignMember : potentialEventMemberList) {
			for (String field : eventMemberToContactIDMapping.keySet()) {
				Map<String, Id> uniqueIdToContactIDMap = uniqueIDMap.get(field);
				String uniqueId = (String) campaignMember.get(field);

				if (uniqueIdToContactIDMap != null && uniqueId != null) {
					Id correspondingContact = uniqueIdToContactIDMap.get(uniqueId);

					if (correspondingContact != null) {
						campaignMember.ContactId = correspondingContact;
						campaignMember.CampaignId = guestListToAddNewMembersTo.Id;
						campaignMembersToInsert.add(campaignMember);
						break;
					}
				}
			}
		}

		insert new List<CampaignMember>(campaignMembersToInsert);
	}

	/*******************************************************************************
	* @author       Mark Johnson - UC Innovation
	* @date         18/02/2019    
	* @description  For all remaining CSV uploaded event members, that do not have existing contacts in the system, or existin eventmembers/interims on the campaign. Create an interim for them.
	* @param 		potentialEventMemberList - list of remaining campaign members that have not been yet operated on.
	* @param 		guestListToAddNewMembersTo - a new guest list that the new campaign members/interims will lookup to
	*******************************************************************************/ 

	private static void processNewInterims(List<CampaignMember> potentialEventMemberList, Campaign guestListToAddNewMembersTo) {

		List<ucinn_ascendv2__Interim__c> interimsToInsert = new List<ucinn_ascendv2__Interim__c>();
        Id zkipsterRecordTypeId = EngageDedupeUtils.interimNamespacedRecordTypeDevNameToRecordTypeMap.get('c.Zkipster_Interface').Id;

		for (CampaignMember campaignMemberToInsert : potentialEventMemberList) {
			Ucinn_ascendv2__Interim__c interimRecord = new Ucinn_ascendv2__Interim__c(RecordTypeId = zkipsterRecordTypeId);

			for (String keyCampaignMemberField : interimFieldMap.keySet()) {
				if (campaignMemberToInsert.get(keyCampaignMemberField) != null) {
					interimRecord.put(interimFieldMap.get(keyCampaignMemberField), campaignMemberToInsert.get(keyCampaignMemberField));
				}
			}

			interimRecord.Guest_List__c = guestListToAddNewMembersTo.Id;
			interimsToInsert.add(interimRecord);
		}

		insert interimsToInsert;
	}

}