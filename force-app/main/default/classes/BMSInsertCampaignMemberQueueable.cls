/*******************************************************************************
* @author       Anterey Custodio
* @date         17.Nov.2016         
* @description  Queueable class that adds campaign members to the campaign
* @revision     
*******************************************************************************/
public class BMSInsertCampaignMemberQueueable implements Queueable {

	private List<String> contactIdList;
	private String campaignId;
	private String crmMassEmailId;
	private String contactQueryStr;
	private Set<String> searchValueSet;

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  constructor called by Bulk Messaging
	* @revision     
	*******************************************************************************/
	public BMSInsertCampaignMemberQueueable(List<String> contactToQuery, String crmMassEmailRecordId) {
		contactIdList = contactToQuery;
		crmMassEmailId = crmMassEmailRecordId;
	}
	
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  constructor called by Bulk Messaging
	* @revision     
	*******************************************************************************/
	public BMSInsertCampaignMemberQueueable(String contactSOQL, String crmMassEmailRecordId, Set<String> searchSet) {
		searchValueSet = searchSet;
		contactQueryStr = contactSOQL;
		crmMassEmailId = crmMassEmailRecordId;
	}

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         17.Nov.2016         
	* @description  Queue Execute
	* @revision     
	*******************************************************************************/
	public void execute(QueueableContext context) {
		try {
			Id batchJobId = Database.executeBatch(new BMSMassEmailContactBatch(contactIdList, contactQueryStr, crmMassEmailId, searchValueSet), 2000);
			system.debug('@@@batchJobId'+batchJobId);
		} catch (Exception ex) {
			system.debug('@@@BMSInsertCampaignMemberQueueable ERROR: ' + ex);
		}
	}
}