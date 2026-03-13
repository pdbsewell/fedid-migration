/*******************************************************************************
* @author       Ryan Wilson
* @date         03.04.2017         
* @description  Batch class for updating campaign member status
* @revision     
*******************************************************************************/
global class BMSUpdateCampaignMemStatusBatch implements Database.Batchable<sObject> {
	
	private String query;
	private List<String> campaignIds;
	
	global BMSUpdateCampaignMemStatusBatch(List<String> campIds) {
		campaignIds = campIds;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		query = 'SELECT CampaignId, Id, Status FROM CampaignMember WHERE CampaignId IN:campaignIds';
		return Database.getQueryLocator(query);
	}

	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         03.04.2017         
	* @description  Method for updating campaign member status in order to fire the Journey in Marketing cloud
	* @revision     
	*******************************************************************************/
   	global void execute(Database.BatchableContext BC, List<CampaignMember> scope) {
		List<CampaignMember> campaignMemberToUpdateList = new List<CampaignMember>();

		for (CampaignMember memberRecord: scope) {
			memberRecord.Status = 'Ready to Send';
			campaignMemberToUpdateList.add(memberRecord);
		}

		if(campaignMemberToUpdateList.size() >0){
			update campaignMemberToUpdateList;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		//do something with the campaign
	}
	
}