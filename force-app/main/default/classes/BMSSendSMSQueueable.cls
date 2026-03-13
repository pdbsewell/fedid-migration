/*******************************************************************************
* @author       Ryan Wilson
* @date         15.Mar.2017         
* @description  Queueable class that process the sending of SMS batch
* @revision     
*******************************************************************************/
public class BMSSendSMSQueueable implements Queueable, Database.AllowsCallouts {
	private Blob contentFile;
	private String campaignId;
	private List<String> contactIdList;
	private String personIds;
	private String attachmentId;
	private Boolean isPersonId;

	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         15.Mar.2017         
	* @description  constructor called by Bulk Messaging
	* @revision     
	*******************************************************************************/
	public BMSSendSMSQueueable(String attachmentRecordId, String campaignRecordId) {
		campaignId = campaignRecordId;
		attachmentId = attachmentRecordId;
	}

	/*******************************************************************************
	* @author       Ryan Wilson
	* @date         15.Mar.2017         
	* @description  Queue Execute
	* @revision     
	*******************************************************************************/
	public void execute(QueueableContext context) {
        //Do some action here
        try {
			Id batchJobId = Database.executeBatch(new BMSMassSMSSendBatch(attachmentId, campaignId), 200);
			system.debug('@@@batchJobId'+batchJobId);
		} catch (Exception ex) {
			system.debug('@@@BMSSendSMSQueueable ERROR: ' + ex);
		}
	}
}