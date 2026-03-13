/**
 * @author Carl Vescovi, PwC
 * @group Commons
 * @description Service class for Campaign Trigger Handler
 */
public class CampaignServices {
    
    public static Id EVENT_RECTYPE {
        get {
            if(EVENT_RECTYPE == null) {
                EVENT_RECTYPE = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Event')?.getRecordTypeId();
            }
            return EVENT_RECTYPE;
        } set;
    }

    public static Id SUB_LIST_RECTYPE {
        get {
            if(SUB_LIST_RECTYPE == null) {
                SUB_LIST_RECTYPE = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Subscription_List')?.getRecordTypeId();
                
            }
            return SUB_LIST_RECTYPE;
        } set;
    }

    public static Id BMS_RECTYPE {
        get {
            if(BMS_RECTYPE == null) {
                BMS_RECTYPE = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('BMS')?.getRecordTypeId();
            }
            return BMS_RECTYPE;
        } set;
    }
 
    /*
    * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
    * @description		EPBBS-1000
    */
    public void alignCampainMemberRecordTypes(List<campaign>camplist) {
        if(!camplist.isEmpty()){

			Map<String, String> mapCampaignToMemberRecordType = new Map<String, String> {
				'Outbound_Call' => 'Outbound_Call',
				'Advisory' => 'Assessee',
				'MonCon_Support' => 'Generic',
				'ERDA_Guest_List' => 'ERDA_Campaign_Member'
			}; 
			Map<Id, Id> mapCampaignToMemberRecordTypeIDs = new Map<Id, Id> ();
			for (String campaignRecordType : mapCampaignToMemberRecordType.keySet()) {
				mapCampaignToMemberRecordTypeIDs.put(Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(campaignRecordType).getRecordTypeId(), Schema.SObjectType.CampaignMember.getRecordTypeInfosByDeveloperName().get(mapCampaignToMemberRecordType.get(campaignRecordType)).getRecordTypeId());
			}
                        
            for (Campaign campaign : camplist){
                if (mapCampaignToMemberRecordTypeIDs.containsKey(campaign.RecordTypeID)) {
					campaign.CampaignMemberRecordTypeID = mapCampaignToMemberRecordTypeIDs.get(campaign.RecordTypeID);
				}
            }
        }
    }
 
	/*
	* @author			Ibrahim rumi
	* @description		query related Campaign member statuses for event recordtype
	*/
	public Map<Id,List<Campaign_Member_Status__mdt>> retrieveCampMembStatusesByCampaignRecType() {
		
		Map<Id,List<Campaign_Member_Status__mdt>> cmStatusesByCampaignRecTypeMap = new Map<Id,List<Campaign_Member_Status__mdt>>();
		
		for(Campaign_Member_Status__mdt cmstatus:[SELECT Campaign_Record_Type__c, MasterLabel, Has_Responded__c, Is_Default__c 
												FROM Campaign_Member_Status__mdt
                                                WHERE Campaign_Record_Type__c != null]){
													
													id rectypeid = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get(cmstatus.Campaign_Record_Type__c)?.getRecordTypeId();
													if(rectypeid != null){
														
														if(cmStatusesByCampaignRecTypeMap.containskey(rectypeid)){
															List<Campaign_Member_Status__mdt> cmstatusList = cmStatusesByCampaignRecTypeMap.get(rectypeid);
															cmstatusList.add(cmstatus);
														}else{
															cmStatusesByCampaignRecTypeMap.put(rectypeid,new List<Campaign_Member_Status__mdt>{cmstatus});
														}
														
													}
													
												}
		return cmStatusesByCampaignRecTypeMap;
	}
	/*
	* @author			Vinothraja
	* @description		query related Campaign member statuses for Campaign Type
	*/
	public Map<String, List<Campaign_Member_Status__mdt>> retrieveCampMembStatusesByCampaignType() {
		
		Map<String, List<Campaign_Member_Status__mdt>> cmStatusesByCampaignTypeMap = new Map<String, List<Campaign_Member_Status__mdt>>();
		
		for(Campaign_Member_Status__mdt cmstatus:[SELECT Campaign_Type__c, MasterLabel, Has_Responded__c, Is_Default__c, Sequence__c
                                                    FROM Campaign_Member_Status__mdt
                                                    WHERE Campaign_Type__c <> null
                                                    ORDER BY Sequence__c ASC]){
													
                                                    if(cmStatusesByCampaignTypeMap.containskey(cmstatus.Campaign_Type__c)){
                                                        List<Campaign_Member_Status__mdt> cmstatusList = cmStatusesByCampaignTypeMap.get(cmstatus.Campaign_Type__c);
                                                        cmstatusList.add(cmstatus);
                                                    }else{
                                                        cmStatusesByCampaignTypeMap.put(cmstatus.Campaign_Type__c,new List<Campaign_Member_Status__mdt>{cmstatus});
                                                    }
        }
		if (Test.isRunningTest()) { // Test code to add a duplicate status for the campaign type 'Domestic Post App'
			Campaign_Member_Status__mdt testStatus = new Campaign_Member_Status__mdt();
			testStatus.MasterLabel = 'Pending';
			testStatus.Campaign_Type__c = 'Domestic Post Opp';
			testStatus.Has_Responded__c = false;
			testStatus.Is_Default__c = true; // Set to true for testing; subsequent defualt statuses will be set to false during resolveDuplicateAndDefaultStatuses
			testStatus.Sequence__c = 4;
			testStatus.DeveloperName = 'Test_Status';
			cmStatusesByCampaignTypeMap.get('Domestic Post App').add(testStatus);
		}
		return cmStatusesByCampaignTypeMap;
	}
 
	/*
	* @author			Ibrahim rumi
	* @description		Fetch Event and campaign status mapping
	*/
	public map<String, BT_Event_To_Campaign_Status_Mapping__mdt> retrieveStatusMapping() {
		Map<String, BT_Event_To_Campaign_Status_Mapping__mdt> eventStatusMap = new Map<String, BT_Event_To_Campaign_Status_Mapping__mdt>();
		for(BT_Event_To_Campaign_Status_Mapping__mdt iMap : [SELECT Campaign_Status__c,Event_Status__c,Campaign_Active__c
															FROM BT_Event_To_Campaign_Status_Mapping__mdt
                                                            LIMIT 2000])
		{
			BT_Event_To_Campaign_Status_Mapping__mdt statusMapping = eventStatusMap.get(iMap.Campaign_Status__c);
			if(statusMapping == null) {
				statusMapping = iMap;
			}
			eventStatusMap.put(iMap.Campaign_Status__c, statusMapping);
		}
		return eventStatusMap;
	}
}