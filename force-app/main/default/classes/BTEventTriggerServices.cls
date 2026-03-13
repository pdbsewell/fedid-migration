/**
 * @author Nick Guia
 * @date 07-07-2020
 * @group Event Management
 * @description Service class for conference360__Event__c object (Blackthorn)
 * @revision rumi.rumi@monash.edu EPBBS-1551 added methods manageCampaignStatus,activeCampaignStatus,cancelCampaignStatus to update campaign status when event status is modified
 *          2021-06-09 -    Aref Samad     -EPBBS-1970 added new field in Event Internal_Name__c and added method updateCampusName
 *                                          to map campaign Name and campaign display name remains mapped with Event Name
 *          2021-06-11 -    Aref Samad     -EPBBS-1985 modified createCampaign to enable Event Auto Sync as default
 *          2021-11-10 -    Mairaj Haider  -EPBBS-2262 Store maze map details in Location object and copy it to Event object
 *          2022-02-14 -    RANAND         -EPBBS-2030 Added method (populateWinningAffiliation) to calculate Winnig affiliation from analyzer
 *          2022-02-11 -    Ibrahim Rumi   -EPBBS-2387 UpdateSessionStatus() to auto cancel related sessions when event is cancelled
 *          2022-03-07 -    RANAND         -EPBBS-2495 Default the Type value on Campaign to Sibling
 *          2022-04-12 -    RANAND         -EPBBS-2570 Cascade fields from Event Group on Event
 * 			2022-05-17 -	RANAND		   -EPBBS-2680 Populate Event Group Campaign as Parent in CreateCampaign method
 *          2022-06-21 -    Ibrahim Rumi   -EPBBS-2750 createEventItemOnApprovalSubmission() to auto create event items on approval submission
 *          2022-06-21 -    Ibrahim Rumi   -EPBBS-2750 neweventItem() to create an instance of an event item based on event
 *          2023-08-05 -    RANAND         -EPBBS-3285 UpdateAssociatedCampaign() to update associated Campaigns from Event in case of Event update
 **/
public with sharing class BTEventTriggerServices {

    @TestVisible
    private List<conference360__Event__c> recList;
    private final String TYPE_SIBLING = 'Sibling';
    @TestVisible 
    private BTEventSelector eventSelector;
    
    public BTEventTriggerServices(List<conference360__Event__c> recs) {
        this.recList = recs;
    }

    /**
    * @description create campaign record based on Event details
    **/
    public void createCampaign() {
        if(this.recList != null) {
            Id eventRecType = CampaignServices.EVENT_RECTYPE;
            List<Campaign> campList = new List<Campaign>();
            Set<Id> evGroupIds = new Set<Id>();
            Map<Id,Id> eventCampMap = new Map<Id,Id>();
            for(conference360__Event__c iEvent : this.recList) {
                if(iEvent.conference360__Event_Group__c != null){
                    evGroupIds.add(iEvent.conference360__Event_Group__c);
                }
            }
            for(conference360__Event_Group__c objEG : [SELECT Id, Event_Group_Campaign__c 
                                                        FROM conference360__Event_Group__c
                                                        WHERE Id IN: evGroupIds]){
                if(objEG.Event_Group_Campaign__c != null){
                    eventCampMap.put(objEG.Id, objEG.Event_Group_Campaign__c);
                }
            }
            for(conference360__Event__c iEvent : this.recList) {
                Campaign campRec = new Campaign();
                if (String.isNotBlank(iEvent.Internal_Name__c))
                {
                    campRec.Name = iEvent.Internal_Name__c;
                }
                else {
                    campRec.Name = iEvent.Name;
                }
                campRec.RecordTypeId = eventRecType;
                campRec.Type = TYPE_SIBLING; //[EPBBS-2495]- Default Type to Sibling for auto created campaigns against an Event
                campRec.conference360__Event__c = iEvent.Id;
                campRec.Public_Display_Name__c = iEvent.Name;
                campRec.Public_List_Description__c = iEvent.Name;
                campRec.Description = iEvent.Name;
                campRec.StartDate = iEvent.conference360__Event_Start_Date__c;
                campRec.EndDate = iEvent.conference360__Event_End_Date__c;
                campRec.Status = '	In Progress';
                campRec.IsActive = true;
                campRec.Channel_Type__c = 'Email';
				campRec.conference360__Event_Auto_Sync__c = 'Yes';
                campRec.Event_URL__c = iEvent.conference360__Event_Page_URL__c;
                campRec.CampaignMemberRecordTypeId = CampaignMemberServices.RECORDTYPE_EVENT_ATTENDEE;
                //Update Parent Campaign if created from Event Group
                if(iEvent.conference360__Event_Group__c != null && 
                    eventCampMap.containsKey(iEvent.conference360__Event_Group__c)){
                        campRec.ParentId = eventCampMap.get(iEvent.conference360__Event_Group__c);
                }
                //Update Parent Campaign if created without Event Group
                else if(iEvent.Parent_Campaign__c != null){
                    campRec.ParentId = iEvent.Parent_Campaign__c;
                }
                campList.add(campRec);
            }
            if(!campList.isEmpty()) {
                insert campList;
            }
        }
    }
    /**
    * @author Ibrahim Rumi
    * @description update campaign record status and isactive flag when event status is changed
    **/
    public void manageCampaignStatus(){
        if(this.recList != null) {
            List<Campaign> campaignList = new List<Campaign>();
            Map<String, BT_Event_To_Campaign_Status_Mapping__mdt> eventStatusMap = new Map<String, BT_Event_To_Campaign_Status_Mapping__mdt>();
            eventStatusMap = retrieveStatusMapping();
            for(conference360__Event__c iEvent : this.recList) {
                Campaign campRec = new Campaign();
                if(eventStatusMap.containskey(iEvent.conference360__Status__c)){
                    campRec = getCampaignMappingRecord(iEvent,eventStatusMap.get(iEvent.conference360__Status__c));
                    campaignList.add(campRec);
                }

            }
            if(!campaignList.isEmpty()) {
                Database.update(campaignList);
            }
        }
    }

    /**
    * @author Ibrahim Rumi
    * @description return the campaign and event status mapping from BT_Event_To_Campaign_Status_Mapping__mdt metadata
    **/
    public static Map<String, BT_Event_To_Campaign_Status_Mapping__mdt> retrieveStatusMapping() {
		Map<String, BT_Event_To_Campaign_Status_Mapping__mdt> eventStatusMap = new Map<String, BT_Event_To_Campaign_Status_Mapping__mdt>();
		for(BT_Event_To_Campaign_Status_Mapping__mdt iMap : [SELECT Campaign_Status__c,Event_Status__c,Campaign_Active__c
		                                        FROM BT_Event_To_Campaign_Status_Mapping__mdt])
		{
			BT_Event_To_Campaign_Status_Mapping__mdt statusMapping = eventStatusMap.get(iMap.Event_Status__c);
			if(statusMapping == null) {
				statusMapping = iMap;
			}
			eventStatusMap.put(iMap.Event_Status__c, statusMapping);
		}
        system.debug(eventStatusMap);
		return eventStatusMap;
	}
    /**
    * @author Ibrahim Rumi
    * @description update campaign record status based on the mapping available in BT_Event_To_Campaign_Status_Mapping__mdt metadata
    **/
    public Campaign getCampaignMappingRecord(conference360__Event__c iEvent,BT_Event_To_Campaign_Status_Mapping__mdt iStatusMapping){
        campaign campRec = new campaign();
        campRec.id = iEvent.conference360__Campaign__c;
        campRec.Status = iStatusMapping.Campaign_Status__c;
        return campRec;
    }

     /**
    * @author Aref Samad
    * @description update campaign name if event Internal name is changed
    **/
    public void updateCampusName() {
        if(this.recList != null) {
            List<Campaign> campaignList = new List<Campaign>();
            for(conference360__Event__c iEvent : this.recList) {
                campaign campRec = new campaign();
                campRec.id = iEvent.conference360__Campaign__c;
                if (String.isNotBlank(iEvent.Internal_Name__c))
                {
                    campRec.Name = iEvent.Internal_Name__c;
                }
                else {
                    campRec.Name = iEvent.Name;
                }
                campaignList.add(campRec);
            }
            if(!campaignList.isEmpty()) {
                Database.update(campaignList);
            }
        }
    }

    /**
    * @author Mairaj Haider
    * @description Copy location data from Location object to Event object
    **/
    public void copyLocationDetailsToEvent() {
        if(!reclist.isEmpty()) {
            //When referencing the Location object in Apex code, always use Schema.Location instead of Location to 
            //prevent confusion with the standard Location compound field
            Set<String> locationsIds = new Set<String>();
            for(conference360__Event__c event : this.recList) {
                locationsIds.add(event.Location__c);
            }
            
            //SOQL to get all location details using set of ids
            Map<Id, Schema.Location> locationMap = new Map<Id, Schema.Location>(
                [SELECT Id, Name, Street__c, City__c, Postal_Code__c, State_Province__c, Country__c
                FROM location
                WHERE Id IN :locationsIds]);

            for(conference360__Event__c event : reclist){
                if(event.Location__c != null){
                    Schema.Location location = locationMap.get(event.Location__c);
                    //Update location details on Event
                    if(location != null){
                        event.conference360__Venue_Name__c = location.Name;
                        event.conference360__Venue_Street__c = location.Street__c;
                        event.conference360__Venue_City__c = location.City__c;
                        event.conference360__Venue_Postal_Code__c = location.Postal_Code__c;
                        event.conference360__Venue_State_Province__c = location.State_Province__c;
                        event.conference360__Venue_Country__c = location.Country__c;
                    }
                } else {
                    //Remove field values if Location is deleted from Event
                    event.conference360__Venue_Name__c = '';
                    event.conference360__Venue_Street__c = '';
                    event.conference360__Venue_City__c = '';
                    event.conference360__Venue_Postal_Code__c = '';
                    event.conference360__Venue_State_Province__c = '';
                    event.conference360__Venue_Country__c = '';
                }
            }
        }
    }

    /**
    * @author Mairaj Haider
    * @description Update Event Attendee Status to Attendee when Session Attendee status is updated to Attended
    **/
    public void updateSessionStatus() {
        if(this.recList != null) {
            Set<Id> eventIds = new Set<Id>();

            //Create SET of Event ID's from Events records
            for(conference360__Event__c event : this.recList) {
                eventIds.add(event.Id);
            }

            BTSessionSelector selector = new BTSessionSelector();
            List<conference360__Session__c> sessionList = selector.selectById(eventIds);

            for(conference360__Session__c session : sessionList) {
                session.conference360__Status__c = 'Canceled';
            }
            if(!sessionList.isEmpty()) {
                Database.update(sessionList);
            }
        }
    }
    
    /**
    * @description process and evaluate the winning affiliation to populate it in Winning Affilioation field on Event
    **/
    public void populateWinningAffiliation() {
        if(this.recList != null) {
            
            for(conference360__Event__c objEvent : this.recList) {
                objEvent.Winning_Affiliation__c = new BTAudienceTypeAnalyser(objEvent.Audience_Type__c)
                                                    .runAnalyser()
                                                    .getAffiliationString();
            }
        }
    }

    /**
    * @description update campaign record status and isactive flag when event status is changed
    **/
    public void manageCascadeFieldsonEvent(Set<Id> groupIds){
        BTEventGroupTriggerServices groupService =  new BTEventGroupTriggerServices();
        if(!recList.isEmpty()){

            Map<String, String> fieldMap = groupService.getEventGroupMap();
            String queryFieldVal = 'Id, ';
            //Form a query from field names available in Metadata
            for(String fieldName : fieldMap.values()){
                queryFieldVal = queryFieldVal + fieldName +',';
            }

            queryFieldVal = queryFieldVal.removeEnd(',');
            String groupSOQl = 'SELECT '+queryFieldVal+ ' FROM conference360__Event_Group__c WHERE ID IN : groupIds';
            
            Map<Id, conference360__Event_Group__c> groupMap =  new Map<Id, conference360__Event_Group__c>((List<conference360__Event_Group__c>)Database.query(groupSOQl));
            
            for(conference360__Event__c objEvent : recList){
                for(String fieldName : fieldMap.keyset()){
                    String groupField = fieldMap.get(fieldName);
                    conference360__Event_Group__c objG = groupMap.get(objEvent.conference360__Event_Group__c);
                    objEvent.put(fieldName, objG.get(groupField));
                }
            }
        }
    }
    
    /**
    * @description creates an event item when an approval is submitted from event
    **/
    public void createEventItemOnApprovalSubmission(){
        Map<Id,conference360__Event__c> eventSettingsMap = new Map<Id,conference360__Event__c>();
        Map<Id,conference360__Event__c> eventItemsMap = new Map<Id,conference360__Event__c>();

        List<conference360__Event_Item__c> neweventItemsList = new List<conference360__Event_Item__c>();

        eventSelector = new BTEventSelector();

        if(!this.recList.isEmpty()){
            Set<Id> eventidSet = (new Map<Id,conference360__Event__c>(this.recList)).keyset();
            eventSettingsMap = eventSelector.selectExistingEventSettingsByEventIds(eventidSet);
            eventItemsMap = eventSelector.selectExistingEventItemsByEventIds(eventidSet);

            for(conference360__Event__c event: this.recList){
                if(eventSettingsMap.containskey(event.id) ){
                    
                    //verify if automate event itemm creation flag is true on event setting
                    conference360__Event__c eventsetting = eventSettingsMap.get(event.id);
                    boolean autoCreateEventItem = eventsetting?.conference360__Event_Settings__r.Automate_Event_Item_Creation__c;
                    
                    if(autoCreateEventItem != null && autoCreateEventItem && eventItemsMap.containskey(event.id)){

                        conference360__Event__c itemsRelatedEvent = eventItemsMap.get(event.id);
                        Boolean eventitemExists = false;

                        //verify if event items previously exist
                        if(itemsRelatedEvent.conference360__Event_Items__r.size()>0){
                            
                            List<conference360__Event_Item__c> itemList = itemsRelatedEvent.conference360__Event_Items__r;

                            for(conference360__Event_Item__c eventItem: itemList){
                                //verify if existing event items has a primary event item type
                                if(eventItem.conference360__Type__c == 'Main event ticket'){
                                    eventitemExists = true;
                                }
                            }
                        }

                        if(!eventitemExists){
							neweventItemsList.add(createNeweventItem(event));
                        }
                    }
            	}
        	}
            //process new event items
            if(!neweventItemsList.isEmpty()){
                
                List<Database.SaveResult> srList = Database.insert(neweventItemsList, false);
                for(Database.SaveResult iRes : srList) {
                    for(Database.Error iError : iRes.getErrors()) {
                        // log exceptions on creating event items
                        LogUtilityException.addLogEvent(
                            'Blackthorn',
                            iRes.getId(),
                            iError,
                            'BTEventTriggerServices.createEventItem'
                        );
                    }
                }
                LogUtilityException.publishAll();
            }
    	}
    }

    /**
    * @description creates an instance of an event item based on event
    * @param conference360__event__c- accepts an instance of event
    **/
    public conference360__Event_Item__c createNeweventItem(conference360__event__c evt){
        conference360__Event_Item__c evtItem = new conference360__Event_Item__c(
            conference360__Item_Name__c = 'Primary',
            conference360__Type__c = 'Main event ticket',
            conference360__Free__c = true,
            conference360__Email__c = 'Required',
            conference360__FullName__c = 'Required',
            conference360__Quantity_Made_Available__c = evt?.conference360__Attendee_Limit__c,
            conference360__Event__c = evt?.id 
        );
        
        return evtItem;
    }

    /**
     * @description [EPBBS-3285 Updates associated Campaign field values in case Event is updated in order tro maintain the consistency of field values]
     */
    public void refreshCampaignInfo() {
        List<Campaign> campList = new List<Campaign>();
        if(this.recList != null) {
            for(conference360__Event__c iEvent : this.recList) {
                Campaign campRec = new Campaign(Id = iEvent.conference360__Campaign__c);
                campRec.Name = String.isNotBlank(iEvent.Internal_Name__c) ? iEvent.Internal_Name__c : iEvent.Name;
                campRec.conference360__Event__c = iEvent.Id;
                campRec.Public_Display_Name__c = iEvent.Name;
                campRec.Public_List_Description__c = iEvent.Name;
                campRec.Description = iEvent.Name;
                campRec.StartDate = iEvent.conference360__Event_Start_Date__c;
                campRec.EndDate = iEvent.conference360__Event_End_Date__c;
                campRec.Event_URL__c = iEvent.conference360__Event_Page_URL__c;
                campRec.Form_Pre_Registration__c = iEvent.conference360__Form2__c;
                campRec.Form_Post_Registration__c = iEvent.conference360__Form_Post_Registration__c;
                campRec.Custom_CSS_Url__c = iEvent.conference360__Custom_CSS_Url__c;
                campRec.Audience_Type__c = iEvent.Audience_Type__c;
                campRec.Event_Settings__c = iEvent.conference360__Event_Settings__c;
                campRec.Disable_All_Email_Sends__c = iEvent.Disable_All_Email_Sends__c;
                campList.add(campRec);
            }
            if(!campList.isEmpty()) {
                update campList;
            }
        }
    }
}