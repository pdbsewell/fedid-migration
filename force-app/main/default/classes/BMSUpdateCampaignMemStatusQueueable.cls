/*******************************************************************************
* @author       Ryan Wilson
* @date         03.04.2017         
* @description  Queueable class for updating campaign member status
* @revision     
*******************************************************************************/
public class BMSUpdateCampaignMemStatusQueueable implements Queueable {
	private List<String> campaignIds;

	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         03.04.2017         
	* @description  constructor called when updating the camapign member status
	* @revision     
	*******************************************************************************/
	public BMSUpdateCampaignMemStatusQueueable(List<String> campaigns) {
		campaignIds = campaigns;
	}

	public void execute(QueueableContext context) {
        try {
			Id batchJobId = Database.executeBatch(new BMSUpdateCampaignMemStatusBatch(campaignIds), 200);
			system.debug('@@@batchJobId'+batchJobId);
		} catch (Exception ex) {
			system.debug('@@@BMSUpdateCampaignMemStatusQueueable ERROR: ' + ex);
		}
	}
}