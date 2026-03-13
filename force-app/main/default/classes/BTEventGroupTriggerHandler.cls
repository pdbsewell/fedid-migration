/**
 * @author Aref Samad
 * @date 23-08-2021
 * @group Event Management
 * @description Trigger handler for conference360__Event_Group__c object (Blackthorn)
 * @revision
 *         2021-08-23 -    Aref Samad     -EPBBS-2083 Link Event Group to Parent Campaign
 *         2022-04-14 -    RANAND         -EPBBS-2554 Copy Cascaded fields from Campaign to Event Group, Removed Existing code to link Campaign
 *         2023-08-05 -    RANAND         EPBBS-3285 Updates associated Campaign field values in case Event Group is updated in order to maintain the consistency of field values
 *         2023-08-05 -    Rumi           EPBBS-3456 Method to create Campaign and associate against respective Event Group
 **/
public with sharing class BTEventGroupTriggerHandler {

    /**
     * @description EPBBS-2554 Copy values from Parent Campaign if populated and not explicitly provided on Event Group
     **/
    public class CaptureCascadedFieldFromCampaign extends TriggerAbstract {

        List<conference360__Event_Group__c> eventGroupList = new List<conference360__Event_Group__c>();
        Set<Id> campaignIds = new Set<Id>();
        Boolean campChange = false;

        public override void process(SObject sobj) {
            conference360__Event_Group__c eventGroupRec = (conference360__Event_Group__c) sobj;
            if(eventGroupRec.Parent_Campaign__c!=null) {
                eventGroupList.add(eventGroupRec);
                campaignIds.add(eventGroupRec.Parent_Campaign__c);
            }
        }
        
        public override void execute(){
            try {
                if (!eventGroupList.isEmpty()){
                    BTEventGroupTriggerServices service = new BTEventGroupTriggerServices();
                    service.updateEventGroupWithCampaign(eventGroupList, campaignIds, campChange);
                }
            } 
            catch(Exception e){
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } 
            finally{
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @description [EPBBS-3285 Updates associated Campaign field values in case Event Group is updated in order to maintain the consistency of field values]
     */
    public class UpdateAssociatedCampaign extends TriggerAbstract {

        List<conference360__Event_Group__c> eventGroupList = new List<conference360__Event_Group__c>();

        // conditional processing on updated records
        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event_Group__c newEvent = (conference360__Event_Group__c) sobj;
            conference360__Event_Group__c oldEvent = (conference360__Event_Group__c) oldRec;
            if(newEvent.Event_Group_Campaign__c != null 
                && ( newEvent.Event_Group_Campaign__c != oldEvent.Event_Group_Campaign__c 
                || newEvent.Name != oldEvent.Name 
                || newEvent.Form_Pre_Registration__c != oldEvent.Form_Pre_Registration__c 
                || newEvent.Form_Post_Registration__c != oldEvent.Form_Post_Registration__c 
                || newEvent.conference360__UI_Experience__c != oldEvent.conference360__UI_Experience__c 
                || newEvent.Audience_Type__c != oldEvent.Audience_Type__c 
                || newEvent.Disable_All_Email_Sends__c != oldEvent.Disable_All_Email_Sends__c 
                || newEvent.conference360__Event_Settings__c != oldEvent.conference360__Event_Settings__c 
                || newEvent.conference360__Custom_CSS_Url__c != oldEvent.conference360__Custom_CSS_Url__c
                )){
                    eventGroupList.add(newEvent);
            }
        }

        public override void execute() {
            try {
                if(!eventGroupList.isEmpty()) {
                    new BTEventGroupTriggerServices().refreshCampaignInfo(eventGroupList);
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @description [EPBBS-3456] Method to create Campaign and associate against respective Event Group using Platform Events
     */

    public class ManageEventGroupCampaign extends TriggerAbstract {
        Map<Id,conference360__Event_Group__c> eventGroupMap = new Map<Id,conference360__Event_Group__c>();
        /**
         * @description process all records on insertion where Parent Campaign is not blank
         */
        public override void process(SObject sobj) {
            conference360__Event_Group__c eventGroupRec = (conference360__Event_Group__c) sobj;
            if(eventGroupRec.Event_Group_Campaign__c == null){
                eventGroupMap.put(eventGroupRec.Id,eventGroupRec);
            }
        }
        /**
         * @description execute method to create and associate Campaigns against Group
         */ 
        public override void execute() {
            try {
                
                //Checks if there are records to be processed
                 if(!eventGroupMap.isEmpty()){
                    List<Async_Process__e> eventsToPublish = new List<Async_Process__e>();
                    
                        Async_Process__e evt = BTEventGroupTriggerServices.createPayload(eventGroupMap.keyset());
                        
                     eventsToPublish.add(evt);
                    
                    if(!eventsToPublish.isEmpty()) {
                        
                        EventBus.publish(eventsToPublish);
                    }
                }
            } 
            catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } 
            finally {
                LogUtilityException.getLimits();
            }
        }
    }
}