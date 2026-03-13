/*******************************************************************************
* @author       Anterey Custodio
* @date         17.Nov.2016         
* @description  Batch class that adds campaign members to the campaign
* @revision     22/03/2018 - APRIVERA - BMS 1.5 Hot fix
*******************************************************************************/
global class BMSMassEmailContactBatch implements Database.Batchable<sObject> {
	
	private String query;
	private List<String> contactIdList;
	private String contactQueryStr;
	private String campaignId;
	private String crmMassEmailId;
	private Set<String> searchValueSet;
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  constructor
	* @revision     
	*******************************************************************************/
	global BMSMassEmailContactBatch() {
		
	}
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  constructor called by Bulk Messaging
	* @revision     
	*******************************************************************************/
	global BMSMassEmailContactBatch(List<String> contactToQuery, String contactSOQL, String campaignRecordId, Set<String> searchSet) {
		searchValueSet = searchSet;
		contactIdList = contactToQuery;
		contactQueryStr = contactSOQL;
		campaignId = campaignRecordId;
	}
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  Batch Start
	* @revision     
	*******************************************************************************/
	global Database.QueryLocator start(Database.BatchableContext BC) {
		if (contactQueryStr != null) {
            query = contactQueryStr; 
		} else {
		    query = 'SELECT Id FROM Contact WHERE Id IN: contactIdList';
		}
		
		system.debug('Batch Query: '+query);
		return Database.getQueryLocator(query);
	}
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  Batch Execute
	* @revision     
	*******************************************************************************/
   	global void execute(Database.BatchableContext BC, List<Contact> scope) {
		system.debug('batch size: ' + scope.size());
		system.debug('adding contacts to this CRM Mass Email Record: ' + campaignId);
		List<CampaignMember> campaignMemberToInsertList = new List<CampaignMember>();

		for (Contact contactRecord: scope) {
			CampaignMember campaignMemberRec = new CampaignMember();
			campaignMemberRec.ContactId = contactRecord.Id;
			campaignMemberRec.Status = 'Pending Approval';
			campaignMemberRec.CampaignId = campaignId;
			campaignMemberToInsertList.add(campaignMemberRec);
		}
		if (!campaignMemberToInsertList.isEmpty()) {
			insert campaignMemberToInsertList;
		}
	}
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  Batch finish - update campaign status similar to CRM Mass Email
						record
	* @revision     
	*******************************************************************************/
	global void finish(Database.BatchableContext BC) {
		List<Campaign> campaignRecord = [SELECT	Id, Status
											FROM 	Campaign
											WHERE 	Id =: campaignId];
		campaignRecord[0].Batch_Finished__c = true;
		campaignRecord[0].Status = 'On Hold';
		update campaignRecord;
	}
}