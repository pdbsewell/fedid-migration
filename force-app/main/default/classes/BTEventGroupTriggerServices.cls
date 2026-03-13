/**
 * @author Aref Samad
 * @date 23-08-2021
 * @group Event Management
 * @description Service class for conference360__Event_Group__c object (Blackthorn)
 * @revision
 *         2021-08-23 -    Aref Samad     -EPBBS-2083 Link Event Group to Parent Campaign
 *         2022-04-05 -    RANAND         -EPBBS-2554 Cascade fields from Campaign to Event group and remove existing logic
 *         2022-04-05 -    RANAND         -EPBBS-3285 Updates associated Campaign field values in case Event Group is updated in order to maintain the consistency of field values
 * 		   2024-03-07 -    Rumi           -EPBBS-3456 Method to create Event Group Campaign and associate against respective Event Group
 **/
public with sharing class BTEventGroupTriggerServices {

    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String TYPE_EVENT_GROUP = 'Event Group';
    public static final String EVENT_SYNC_YES = 'Yes';
    
    /*
     * @param       Set of Id of event group Object
     * Description: Creates the Payload for ManageEventGroupCampaign method
    */
    public static Async_Process__e createPayload(Set<Id> eveGrpIdSet) {
        Async_Process__e evt;

        if(!eveGrpIdSet.isEmpty()) {
            AsyncProcessPayload payload = new AsyncProcessPayload();
            payload.put ('eveGrpIds', eveGrpIdSet);
            evt = new Async_Process__e (
                Process_Name__c = 'BTEventGroupTriggerServices.ManageEventGroupCampaign',
                Parameter__c = payload.serialize() 
                );
        }
        return evt; 
    }

    /**
    *
    * @description EPBBS-3456 Service class to create event group campaigns using platform events
    */
    public class ManageEventGroupCampaign implements IPlatformEventInvocable {
    
        private Set<Id> eveGrpIdSet = new Set<Id>();

        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, this.eveGrpIdSet);
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
                    
					//first, cast the get return of List<Object> into List<Id>
					List<Object> objList = (List<Object>) payload.get('eveGrpIds');
					//then, instantiate a Set out of it
					for(Object io : objList) {
						//parse object to ID
						this.eveGrpIdSet.add(Id.valueOf(io.toString()));
					}
				}
			}
		}

        public void run() {
            createEventGroupCampaigns(eveGrpIdSet);
        }
    }

    
    /**
     * @description Method to create Campaign and associate against respective Event Group
     */
    public static void createEventGroupCampaigns(Set<Id> eveGrpIdSet){

        if(!eveGrpIdSet.isEmpty()){

            Id eventRecType = CampaignServices.EVENT_RECTYPE;
            List<Campaign> campaignList = new List<Campaign>();
            List<conference360__Event_Group__c> groupList = new List<conference360__Event_Group__c>();

            for(conference360__Event_Group__c eveGrp: [SELECT id, Name,Parent_Campaign__c,Form_Pre_Registration__c,Form_Post_Registration__c,OwnerId,
                                                            conference360__Custom_CSS_Url__c,conference360__UI_Experience__c,conference360__Event_Settings__c
                                                    FROM conference360__Event_Group__c WHERE id IN: eveGrpIdSet])
            {

                campaignList.add(new Campaign(Name = eveGrp.Name,
                                            Status = STATUS_IN_PROGRESS,
                                            IsActive = TRUE,
                                            ParentId = eveGrp.Parent_Campaign__c,
                                            RecordTypeId = eventRecType,
                                            Type = TYPE_EVENT_GROUP,
                                            Event_Group2__c = eveGrp.Id,
                                            Form_Pre_Registration__c = eveGrp.Form_Pre_Registration__c,
                                            Form_Post_Registration__c = eveGrp.Form_Post_Registration__c,
                                            Custom_CSS_Url__c = eveGrp.conference360__Custom_CSS_Url__c,
                                            UI_Experience__c = eveGrp.conference360__UI_Experience__c,
                                            Event_Settings__c = eveGrp.conference360__Event_Settings__c,
                                            OwnerId = eveGrp.OwnerId,
                                            conference360__Event_Auto_Sync__c = EVENT_SYNC_YES));
            }
            
            if(!campaignList.isEmpty()){
                
                insert campaignList;
                //Prepare list of Event Groups to populate Campaign on the records
                for(Campaign objCamp : campaignList){
                    groupList.add(new conference360__Event_Group__c(Id=objCamp.Event_Group2__c, 
                                                                    Event_Group_Campaign__c = objCamp.Id));
                }
                update groupList;
            }
        }
    }

    /**
     * @description EPBBS-2554  Cascade fields from Campaign to Event group
     **/
    public void updateEventGroupWithCampaign(List<conference360__Event_Group__c> eventGroupList, Set<Id> campIds, Boolean campChange) {
        Map<Id, Campaign> campMap = new Map<Id, Campaign>();
        if(!eventGroupList.isEmpty()){
            Map<String, String> fieldMap = getGroupCampaignMap();
            String queryFieldVal = 'Id, ';

            for(String fieldName : fieldMap.values()){
                if(String.isNotBlank(fieldName)){
                    queryFieldVal = queryFieldVal + fieldName +',';
                }
            }

            queryFieldVal = queryFieldVal.removeEnd(',');
            String campaignSOQl = 'SELECT '+queryFieldVal+ ' FROM Campaign WHERE ID IN : campIds';

            Map<Id, Campaign> campaignMap =  new Map<Id, Campaign>((List<Campaign>)Database.query(campaignSOQl));

            for(conference360__Event_Group__c objGroup : eventGroupList){
                for(String fieldName : fieldMap.keyset()){
                    if(objGroup.get(fieldName) == null || campChange){
                        String campField = fieldMap.get(fieldName);
                        Campaign objC = campaignMap.get(objGroup.Parent_Campaign__c);
                        objGroup.put(fieldName, objC.get(campField));
                    }
                }
            }
        }
    }
    /**
     * @description Query Metadata to capture Mapping of Cascade Fields
     */
    public List<BT_Campaign_Cascade_Mapping__mdt> getFieldMappingForCascade(){
        return [SELECT Id, Event_Field__c,Event_Group_Field__c, Parent_campaign_Field__c FROM BT_Campaign_Cascade_Mapping__mdt];
    }
    /**
     * @description returns a map of cascaded fields on Event Group against Campaign
     */
    public Map<String, String> getGroupCampaignMap(){
        Map<String, String> fieldMap = new map<String, String>();
        for(BT_Campaign_Cascade_Mapping__mdt fieldObj : getFieldMappingForCascade()){
            fieldMap.put(fieldObj.Event_Group_Field__c, fieldObj.Parent_campaign_Field__c);
        }
        return fieldMap;
    }
    /**
     * @description returns a map of cascaded fields on Campaign against Event Group
     */
    public Map<String, String> getCampaignGroupMap(){
        Map<String, String> fieldMap = new map<String, String>();
        for(BT_Campaign_Cascade_Mapping__mdt fieldObj : getFieldMappingForCascade()){
            fieldMap.put(fieldObj.Parent_campaign_Field__c, fieldObj.Event_Group_Field__c);
        }
        return fieldMap;
    }
    /**
     * @description returns a map of cascaded fields on Event against Event Group
     */
    public Map<String, String> getEventGroupMap(){
        Map<String, String> fieldMap = new map<String, String>();
        for(BT_Campaign_Cascade_Mapping__mdt fieldObj : getFieldMappingForCascade()){
            fieldMap.put(fieldObj.Event_Field__c, fieldObj.Event_Group_Field__c);
        }
        return fieldMap;
    }
    
    /**
     * @description [EPBBS-3285 Updates associated Campaign field values in case Event Group is updated in order tro maintain the consistency of field values]
     */
    public void refreshCampaignInfo(List<conference360__Event_Group__c> eventGroupList) {
        List<Campaign> campList = new List<Campaign>();
        if(eventGroupList != null) {
            for(conference360__Event_Group__c iEvent : eventGroupList) {
                Campaign campRec = new Campaign(Id = iEvent.Event_Group_Campaign__c);
                campRec.Name = iEvent.Name;
                campRec.Public_Display_Name__c = iEvent.Name;
                campRec.Public_List_Description__c = iEvent.Name;
                campRec.Description = iEvent.Name;
                campRec.Form_Pre_Registration__c = iEvent.Form_Pre_Registration__c;
                campRec.Form_Post_Registration__c = iEvent.Form_Post_Registration__c;
                campRec.UI_Experience__c = iEvent.conference360__UI_Experience__c;
                campRec.Custom_CSS_Url__c = iEvent.conference360__Custom_CSS_Url__c;
                campRec.Audience_Type__c = iEvent.Audience_Type__c;
                campRec.Disable_All_Email_Sends__c = iEvent.Disable_All_Email_Sends__c;
                campRec.Event_Settings__c = iEvent.conference360__Event_Settings__c;
                campList.add(campRec);
            }
            if(!campList.isEmpty()) {
                update campList;
            }
        }
    }
}