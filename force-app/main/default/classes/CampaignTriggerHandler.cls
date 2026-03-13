/**
 * @description  : Handler class for Campaign Trigger
 * @author       : Ibrahim Rumi
 * @group        : Commons
 * @date         : 24-03-2022
 * @revision     :  
 * Modifications Log
 * Date         Author         	Modification
 * 07-07-2020 	Nick Guia		added LinkEventCampaign and FormEventLink (EPBBS-1330)
 * 24-07-2020 	Nick Guia		added UpdateEventMemberStatuses (EPBBS-1499)
 * 20.10.2020  	Ibrahim Rumi	Added UpdateEventStatus and UpdateEventActiveFlag (EPBBS-1551)
 * 22-03-2021  	Steffi			Added UpdateCompanyCampaignAppeal (PENGAGE-1710)
 * 24-08-2021  	Aref Samad		EPBBS-2083 Link Event Group to Parent Campaign
 * 24-03-2022   Ibrahim Rumi	EPBBS-2121 Intorduction of campaignTriggerHandler(Moved Handler logic too handler class)
 * 12-04-2022   RANAND      	EPBBS-2554 updateCascadedGroups-Cascade Fields from Campaign on Event Group
 * 
**/
public with sharing class CampaignTriggerHandler {


     
	/**
	 * prevents deletion of campaigns that have been specifically opted in 'not for deletion' via admin only field.
	 * in particular, this will prevent deletion of MonTrack campaign, which must not be deleted in production
	 */
    public class preventCampaignDeletion extends TriggerAbstract {
    	
        public override void process(SObject sobj){
            Campaign oldObj = (Campaign)sobj;
            if(oldObj.Prevent_Deletion__c){
                oldObj.addError('This record is not permitted to be deleted. Contact System Administrator for assistance.');
            }
        }
        
    }
    
     /*
     * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
     * @description		EPBBS-1000
     */
    public class alignCampainMemberRecordTypes extends TriggerAbstract {
        
        public override void execute(){
            new CampaignServices().alignCampainMemberRecordTypes((List<Campaign>) records);
        }
    }
    
    
    /*
     * @author			Ibrahim Rumi
     * @description		Assigns expected campaign member statuses based on mapping available in Campaign_Member_Status__mdt
     */
    public class createCampaignMemberStatuses extends TriggerAbstract{
        List<Campaign> campaignsToProcess = new list<Campaign>();
        
        public override void process(SObject sobj) {

            Campaign newCampaignRec = (Campaign) sobj;
            
            if (CampaignMemberStatusManager.campMemStatusesByCampRecType.keySet().contains(newCampaignRec.RecordTypeId) 
                || CampaignMemberStatusManager.campMemStatusesByCampType.keySet().contains(newCampaignRec.Type)) {
                    campaignsToProcess.add(newCampaignRec);
            }

        }

		public override void execute() {
             try {
                if(!campaignsToProcess.isEmpty()){
                    new CampaignMemberStatusManager.Builder(campaignsToProcess)
                                .getExistingStatuses()
                                .build()
                                .deletePreviousStatuses();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }
    
    /**
     * @author Nick Guia
     * @description populates the related Event with the Campaign ID
     **/
    public class LinkEventCampaign extends TriggerAbstract {

		Map<Id, conference360__Event__c> recMap = new Map<Id, conference360__Event__c>();
        
		id eventRecType = CampaignServices.EVENT_RECTYPE;
		/**
		 * @description
		 * 	on insert: If Campaign Event is not null, link the related event to the campaign
		 */
		public override void process(SObject sobj) {
			Campaign rec = (Campaign) sobj;
			if(rec.conference360__Event__c != null  &&
				rec.RecordTypeId == eventRecType)
			{
				this.recMap.put(
					rec.conference360__Event__c,
					new conference360__Event__c(
						Id = rec.conference360__Event__c,
						conference360__Campaign__c = rec.Id
				));
			}
		}

		public override void execute() {
            try {
                if(!recMap.isEmpty()) {
                    update recMap.values();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
	}
    
    
    /**
	* @description forces a 1-1 record relationship between Blackthorn Events
     * and Campaigns
	*/
	public class DeleteOldEventLink extends TriggerAbstract {

        Map<Id, Id> campaignByOldEvents = new Map<Id, Id>();
		id eventRecType = CampaignServices.EVENT_RECTYPE;
        
		public override void process(SObject sobj, SObject oldRec) {
			Campaign newRecord = (Campaign) sobj;
			Campaign oldRecord = (Campaign) oldRec;

			if(newRecord.conference360__Event__c != oldRecord.conference360__Event__c &&
				newRecord.RecordTypeId == eventRecType)
			{
				//if there was a previous Event value
				if(oldRecord.conference360__Event__c != null) {
					campaignByOldEvents.put(oldRecord.conference360__Event__c, oldRecord.Id);
				}
			}
		}

		public override void execute() {
			try {
                //set debugs within execute 
                List<conference360__Event__c> evUpdate = new List<conference360__Event__c>();
                
                if(campaignByOldEvents.size() > 0){
                    for(conference360__Event__c iEvent : [SELECT Id, conference360__Campaign__c
                                                          FROM conference360__Event__c
                                                          WHERE
                                                          Id IN :campaignByOldEvents.keySet()
                                                          AND
                                                          conference360__Campaign__c IN :campaignByOldEvents.values()])
                    {
                        if(campaignByOldEvents.containsKey(iEvent.Id) &&
                                  iEvent.conference360__Campaign__c == campaignByOldEvents.get(iEvent.Id))
                        {
                            //if this was the old Event linked to the Campaign, unlink
                            iEvent.conference360__Campaign__c = NULL;
                        }
                        evUpdate.add(iEvent);
                    }
                    
                    if(!evUpdate.isEmpty()) {
						update evUpdate;
					}
                }
                    
				
			} catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
		}
	}
    
    /**
	 *  update Company field in Campaign when record type is Appeal
	 *
	 **/
    public class UpdateCompanyCampaignAppeal extends TriggerAbstract {
        
        Alumni_Community_User_Access__c Alumni_Community  = Alumni_Community_User_Access__c.getInstance();
		id appealRecType = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Appeal')?.getRecordTypeId();
        
        public override void process(SObject sobj){
        	Campaign newRecord = (Campaign) sobj;
            if(newRecord.RecordTypeId == appealRecType) {
            	newRecord.Company__c = Alumni_Community.Id__c;
            }
        }
        
        public override void process(SObject sobj, SObject oldRec) {
			Campaign newRecord = (Campaign) sobj;
        	
            if(newRecord.RecordTypeId == appealRecType) {
            	newRecord.Company__c = Alumni_Community.Id__c;
            }
        }
    }
    
    /**
    * @description autopopulate active flag based on the mapping available in the BT_Event_To_Campaign_Status_Mapping__mdt metadata
    */
    public class UpdateEventActiveFlag extends TriggerAbstract{

        List<Campaign> recList = new List<Campaign>();
		id eventRecType = CampaignServices.EVENT_RECTYPE;
        
        public override void process(SObject sobj,SObject oldRec) {
            Campaign newRecord = (Campaign) sobj;

            if(newRecord.RecordTypeId == eventRecType){
                recList.add(newRecord);
            }
        }

        public override void execute(){
            try {
                
                if(!recList.isEmpty()){
                    Map<String, BT_Event_To_Campaign_Status_Mapping__mdt> eventStatusMap = new Map<String, BT_Event_To_Campaign_Status_Mapping__mdt>();
                    eventStatusMap = new CampaignServices().retrieveStatusMapping();
                    for(Campaign iCamp : this.recList) {
                        if(eventStatusMap.containskey(iCamp.Status)){
                            iCamp.isactive = eventStatusMap.get(iCamp.Status).Campaign_Active__c;
                        }
            		}
                }
            } catch(exception e){
               LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }

    }
    
    /**
	 * @description if Campaign status is changed update event registration status
	 */
    public class UpdateEventStatus extends TriggerAbstract {

		List<Campaign> recList = new List<Campaign>();
		id eventRecType = CampaignServices.EVENT_RECTYPE;
        
		public override void process(SObject sobj, SObject oldRec) {
			Campaign newRecord = (Campaign) sobj;
			Campaign oldRecord = (Campaign) oldRec;
			if(newRecord.Status != oldRecord.Status &&
				newRecord.RecordTypeId == eventRecType) {
				recList.add(newRecord);
			}
		}

		public override void execute() {
			try {
                
                if(!recList.isEmpty()){
                    List<conference360__Event__c> eventList = new List<conference360__Event__c>();
            		Map<String, BT_Event_To_Campaign_Status_Mapping__mdt> eventStatusMap = new Map<String, BT_Event_To_Campaign_Status_Mapping__mdt>();
                    
                    eventStatusMap = new CampaignServices().retrieveStatusMapping();
                    for(Campaign iCamp : this.recList) {
                        if(eventStatusMap.containskey(iCamp.Status)){
                            conference360__Event__c eventRec = new conference360__Event__c();
                            eventRec.id = iCamp.conference360__Event__c;
                            eventRec.conference360__Status__c = eventStatusMap.get(iCamp.Status).Event_Status__c;
                            eventList.add(eventRec);
                        }

            		}
                    
                    if(!eventList.isEmpty()) {
                        Database.update(eventList);
                    }
                }
                
			} catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
		}

	}
    
}