/*******************************************************************************
* @author       Anterey Custodio
* @date         17.Nov.2016         
* @description  Queueable class that adds campaign members to the campaign
* @revision     
*******************************************************************************/
public class BMSInsertCampaignMemberCSVQueueable implements Queueable {

	private Blob contentFile;
	private String campaignId;
	private List<String> contactIdList;
	private String personIds;
	private String attachmentId;
	private Boolean isPersonId;

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  constructor called by Bulk Messaging
	* @revision     
	*******************************************************************************/
	public BMSInsertCampaignMemberCSVQueueable(String attachmentRecordId, String campaignRecordId, Boolean isThisAListOfPersonIds) {
		//contentFile = contentFileBlob;
		campaignId = campaignRecordId;
		attachmentId = attachmentRecordId;
		isPersonId = isThisAListOfPersonIds;
		//personIds = personIdString;
	}
	
    /*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  Queue Execute
	* @revision     
	*******************************************************************************/
	public void execute(QueueableContext context) {
		try {
			Id batchJobId = Database.executeBatch(new BMSMassEmailContactCSVBatch(attachmentId, campaignId, isPersonId), 1000);
			system.debug('@@@batchJobId'+batchJobId);
		} catch (Exception ex) {
			system.debug('@@@BMSInsertCampaignMemberCSVQueueable ERROR: ' + ex);
		}
	}
}