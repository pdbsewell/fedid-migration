/**
 * @author          Mark Johnson: UC Innovation
 * @description    	This override class is to test custom logic for Monash to ascend's Manual Merge Interim component.
 * 					Manual merge component is an ascend component that is configurable, and allows users to load data into the interim object, 
 * 					and manually resolve differences between the Interim and a corresponding potential duplicate contact.
 * 
 * 					The manual merge component is very configurable, but there are times when specific logic is required per client, and therefore overrides are allowed to manipulate specific logic.
 * 
 * @revision        10/09/2019 - Mark Johnson - Initial version
 * Modifications Log 
 * Ver   Date         Author          	Modification
 * 1.1   07-12-2022   Inderpal Dhanoa   PENGAGE-2597 Test class Fix  
 * 1.0   10-09-2019   Mark Johnson    	Initial Version
 * 
 */

@isTest(isParallel=true)
public class EngageManualMergeOverride_Test {
	@IsTest
	private static void EngageManualMergeOerrideTest() {

		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger(new ucinn_ascendv2__Address_Relation__c().getSObjectType().getDescribe().getName(), false);
		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger(new ucinn_ascendv2__Address__c().getSObjectType().getDescribe().getName(), false);
		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger(new Contact().getSObjectType().getDescribe().getName(), false);
		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger(new ucinn_ascendv2__Email__c().getSObjectType().getDescribe().getName(), false);
		ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger(new ucinn_ascendv2__Phone__c().getSObjectType().getDescribe().getName(), false);
        
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

		// GIVEN: interim record to process
		ucinn_ascendv2__Interim__c interim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'Hello', ucinn_ascendv2__Last_Name__c='test',
                                            ucinn_ascendv2__Address_1_Line_1__c = '123 Tmp Street1',
                                            ucinn_ascendv2__Address_1_Line_2__c = '125124',
                                            ucinn_ascendv2__Address_1_Line_3__c = '33',
                                            ucinn_ascendv2__Address_1_Type__c = 'Mailing',
                                            ucinn_ascendv2__City_1__c='Irvine',
                                            ucinn_ascendv2__State_1__c='California',
                                            ucinn_ascendv2__Country_1__c='USA',
                                            ucinn_ascendv2__Address_2_Line_1__c = '123 Tmp Street2',
                                            ucinn_ascendv2__Address_2_Line_2__c = '125213',
                                            ucinn_ascendv2__Address_2_Line_3__c = '33',
                                            ucinn_ascendv2__Address_2_Type__c = 'Other',
                                            ucinn_ascendv2__City_2__c='Irvine',
                                            ucinn_ascendv2__State_2__c='California',
                                            ucinn_ascendv2__Country_2__c='USA',
                                            ucinn_ascendv2__Phone_1__c='12345678901231',
                                            ucinn_ascendv2__Phone_2__c='1234567890',
                                            ucinn_ascendv2__Email_1__c='123@example.com',
                                            ucinn_ascendv2__Possible_Duplicate_Checked__c = true,
                                            Name='test', ucinn_ascendv2__Status__c='New',
                                            RecordTypeId = reRecordTypeID);

		// GIVEN: fields used in merging process
		Set<String> populatedFieldSet = new Set<String>{'ucinn_ascendv2__First_Name__c', 
								'ucinn_ascendv2__Last_Name__c', 
								'ucinn_ascendv2__Address_1_Line_1__c', 
								'ucinn_ascendv2__Address_1_Line_2__c', 
								'ucinn_ascendv2__Address_1_Line_3__c', 
								'ucinn_ascendv2__Address_1_Type__c', 
								'ucinn_ascendv2__City_1__c',
								'ucinn_ascendv2__State_1__c',
								'ucinn_ascendv2__Country_1__c',
								'ucinn_ascendv2__Address_2_Line_1__c',
								'ucinn_ascendv2__Address_2_Line_2__c',
								'ucinn_ascendv2__Address_2_Line_3__c',
								'ucinn_ascendv2__Address_2_Type__c',
								'ucinn_ascendv2__City_2__c',
								'ucinn_ascendv2__State_2__c',
								'ucinn_ascendv2__Country_2__c',
								'ucinn_ascendv2__Phone_1__c',
								'ucinn_ascendv2__Phone_2__c',
								'ucinn_ascendv2__Email_1__c'};

		// GIVEN: contact record used for merging
		Contact con = new Contact(LastName = 'test');

		insert interim;
		insert con;

		Set<Id> manualMergeTabIds = new Set<Id>();
		Set<Id> manualMergeCardIds = new Set<Id>();

		// WHEN: get default merge setting
        //Grab existing custom metadata from Monash's org
		List<ucinn_ascendv2__Manual_Merge_Setting__mdt> manualMergeSettingsListDefaultType = [	SELECT 	ucinn_ascendv2__Fields_to_Display__c,
																						ucinn_ascendv2__Interim_Fields_To_Display__c,
																						ucinn_ascendv2__Default_Setting__c,
																						ucinn_ascendv2__Package_Extension__r.ucinn_ascendv2__Override_Class_Name__c,
																						ucinn_ascendv2__Package_Extension__r.ucinn_ascendv2__Override_Class_Namespace__c,
																						(SELECT ucinn_ascendv2__Manual_Merge_Tab__c
																						 FROM ucinn_ascendv2__Manual_Merge_Junctions__r)
																				FROM 	ucinn_ascendv2__Manual_Merge_Setting__mdt
																				WHERE	ucinn_ascendv2__Default_Setting__c = true];

		ucinn_ascendv2__Manual_Merge_Setting__mdt manualMergeSettingToProcess;

		if (!manualMergeSettingsListDefaultType.isEmpty()) {
			manualMergeSettingToProcess = manualMergeSettingsListDefaultType[0];
		}

		if (manualMergeSettingToProcess != null) {
			for (ucinn_ascendv2__Manual_Merge_Junction__mdt manualMergeJunction : manualMergeSettingToProcess.ucinn_ascendv2__Manual_Merge_Junctions__r) {
				if (manualMergeJunction.ucinn_ascendv2__Manual_Merge_Tab__c != null) {
					manualMergeTabIds.add(manualMergeJunction.ucinn_ascendv2__Manual_Merge_Tab__c);
				}
			}
		}

		// WHEN: get manual merge tabs
		List<ucinn_ascendv2__Manual_Merge_Tab__mdt> tabList = [	SELECT  ucinn_ascendv2__Source_SObject_Name__c,
																	ucinn_ascendv2__Source_Type__c,
																	ucinn_ascendv2__Source_Lookup_API_Name__c,
																	ucinn_ascendv2__Target_SObject_Name__c,
																	ucinn_ascendv2__Target_Type__c,
																	ucinn_ascendv2__Target_Lookup_API_Name__c,
																	ucinn_ascendv2__Additional_Contact_Fields_To_Display__c,
																	ucinn_ascendv2__Additional_Interim_Fields_To_Display__c,
																	ucinn_ascendv2__Preferred_Record_Picklist_API_Name__c,
																	ucinn_ascendv2__Preferred_Field_API_Name__c,
																	ucinn_ascendv2__Parent_Object_Lookup_API_Name__c,
																	Label,
																	ucinn_ascendv2__Order__c,
																	DeveloperName,
																	Id,
																	(SELECT ucinn_ascendv2__Order__c,
																			ucinn_ascendv2__Field_API_Name__c,
																			ucinn_ascendv2__Type__c
															 		FROM ucinn_ascendv2__Manual_Merge_Fields__r),
															 		(SELECT Id,
															 				ucinn_ascendv2__Order__c
															 		FROM ucinn_ascendv2__Manual_Merge_Interim_Cards__r)
															FROM ucinn_ascendv2__Manual_Merge_Tab__mdt
															WHERE Id IN: manualMergeTabIds
															ORDER BY ucinn_ascendv2__Order__c];

		if (tabList.isEmpty()) {
			return;
		}

		for (ucinn_ascendv2__Manual_Merge_Tab__mdt manualMergeTab : tabList) {
			for(ucinn_ascendv2__Manual_Merge_Interim_Card__mdt manualMergeCard : manualMergeTab.ucinn_ascendv2__Manual_Merge_Interim_Cards__r) {
				manualMergeCardIds.add(manualMergeCard.Id);
			}
		}

		// WHEN: get manual merge cards
		List<ucinn_ascendv2__Manual_Merge_Interim_Card__mdt> manualMergeCards = [	SELECT 	Id,
																			ucinn_ascendv2__Manual_Merge_Tab__c,
																			ucinn_ascendv2__Order__c,
																			(SELECT ucinn_ascendv2__Field_API_Name__c,
																					ucinn_ascendv2__Order__c,
																					ucinn_ascendv2__Field_To_Map_To__c,
																					ucinn_ascendv2__Map_To_Parent__c,
																					ucinn_ascendv2__Combination_Field_Delimiter__c
																			FROM ucinn_ascendv2__Manual_Merge_Interim_Fields__r)
																	FROM ucinn_ascendv2__Manual_Merge_Interim_Card__mdt												
																	WHERE Id IN: manualMergeCardIds
																	ORDER BY ucinn_ascendv2__Order__c];


		List<Map<String, Object>> tabInfoList = new List<Map<String, Object>>();

        //Create tabs for processing. One tab holds information about a specific type of object related to the interim/contact.
        //For example the address tab would be for merging addresses from the interim into an existing possible duplicate contact.
		for (ucinn_ascendv2__Manual_Merge_Tab__mdt tab : tabList) {
			Map<String, Object> tabInfo = new Map<String, Object>();

			tabInfo.put('sourceSObjectName', tab.ucinn_ascendv2__Source_SObject_Name__c);
			tabInfo.put('targetSObjectName', tab.ucinn_ascendv2__Target_SObject_Name__c);
			tabInfo.put('tabDeveloperName', tab.DeveloperName);
	        tabInfo.put('sourceLookupAPIName', tab.ucinn_ascendv2__Source_Lookup_API_Name__c);
	        tabInfo.put('targetLookupAPIName', tab.ucinn_ascendv2__Target_Lookup_API_Name__c);
	        tabInfo.put('targetTabType', tab.ucinn_ascendv2__Target_Type__c);
	        tabInfo.put('sourceTabType', tab.ucinn_ascendv2__Source_Type__c);
	        tabInfo.put('preferredPicklistAPIName', tab.ucinn_ascendv2__Preferred_Record_Picklist_API_Name__c);
	        tabInfo.put('preferredFieldAPIName', tab.ucinn_ascendv2__Preferred_Field_API_Name__c);
	        tabInfo.put('parentObjectLookupAPIName', tab.ucinn_ascendv2__Parent_Object_Lookup_API_Name__c);

	        tabInfo.put('cardList', new List<ucinn_ascendv2__Manual_Merge_Interim_Card__mdt>());
	        tabInfo.put('selectedCardIds', new List<String>());
	        tabInfo.put('fieldList', new List<String>());
            
            List<ucinn_ascendv2__Manual_Merge_Interim_Card__mdt> metadataList = new List<ucinn_ascendv2__Manual_Merge_Interim_Card__mdt>();
            List<String> selectedCardIds = new List<String>();
            List<String> fieldList = new List<String>();

            //Each card holds information about an individual record to be inserted. A card can represent a phone, an address, etc. Tabs contain multiple cards.
	        for (ucinn_ascendv2__Manual_Merge_Interim_Card__mdt mergeCard : manualMergeCards) {
	        	if (mergeCard.ucinn_ascendv2__Manual_Merge_Tab__c == tab.Id) {
	        		//tabInfo.cardList.add(mergeCard);
	        		metadataList.add(mergeCard);

					// WHEN: get manual merge cards
					for (ucinn_ascendv2__Manual_Merge_Interim_Field__mdt interimField : mergeCard.ucinn_ascendv2__Manual_Merge_Interim_Fields__r) {
						if (populatedFieldSet.contains(interimField.ucinn_ascendv2__Field_API_Name__c)) {
							selectedCardIds.add(mergeCard.Id);
						}
					}
	        	}
	        }

	        for (ucinn_ascendv2__Manual_Merge_Field__mdt mergeField : tab.ucinn_ascendv2__Manual_Merge_Fields__r) {
	        	fieldList.add(mergeField.ucinn_ascendv2__Field_API_Name__c);
	        }

	        if (tab.ucinn_ascendv2__Additional_Contact_Fields_To_Display__c != null) tabInfo.put('additionalFieldsToDisplay',  tab.ucinn_ascendv2__Additional_Contact_Fields_To_Display__c.split(','));
	        if (tab.ucinn_ascendv2__Additional_Interim_Fields_To_Display__c != null) tabInfo.put('additionalInterimFieldsToDisplay',  tab.ucinn_ascendv2__Additional_Interim_Fields_To_Display__c.split(','));

            
	        tabInfo.put('cardList', metadataList);
	        tabInfo.put('selectedCardIds', selectedCardIds);
	        tabInfo.put('fieldList', fieldList);
            
            
	        tabInfoList.add(tabInfo);
		}

        
		String tabInfoString = JSON.serialize(tabInfoList);

		List<String> contactFieldsToDisplay = new List<String>();
		List<String> interimFieldsToDisplay = new List<String>();

		if (manualMergeSettingToProcess.ucinn_ascendv2__Fields_to_Display__c != null) contactFieldsToDisplay = manualMergeSettingToProcess.ucinn_ascendv2__Fields_to_Display__c.split(',');
		if (manualMergeSettingToProcess.ucinn_ascendv2__Interim_Fields_To_Display__c != null)interimFieldsToDisplay =  manualMergeSettingToProcess.ucinn_ascendv2__Interim_Fields_To_Display__c.split(',');



		Map<String, Object> parameterMap = new Map<String, Object> { 	'tabList' => tabInfoString, 
																		'conId' => con.Id,
																		'interimId' => interim.Id,
																		'targetSObjectFieldsOnOverview' => JSON.serialize(contactFieldsToDisplay),
																		'interimFieldsOnOverview' => JSON.serialize(interimFieldsToDisplay),
																		'overrideClassNamespace' => '',
																		'overrideClassString' => '',
																		'targetObjectAPIName' => 'Contact'
																	};

		EngageManualMergeOverride manualMergeOverride = new EngageManualMergeOverride();

		// WHEN: perform merge process
        manualMergeOverride.initialize(parameterMap, manualMergeOverride);
        manualMergeOverride.performMergeProcess();

	}
}