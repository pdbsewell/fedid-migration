/**
 * @author Nick Guia
 * @date 07-07-2020
 * @group Event Management
 * @description Trigger handler for conference360__Event__c object (Blackthorn)
 * @revision rumi.rumi@monash.edu EPBBS-1551 added class ManageCampaignStatus to update campaign status when event status is updated
 *         2021-06-09 -    Aref Samad     -EPBBS-1970 added new field in Event Internal_Name__c and added handler UpdateCampusName
 *                                          to map campaign Name and campaign display name remains mapped with Event Name
 * 		   12-10-2021 -    Ibrahim Rumi   -EPBBS-2243 added campaign field null check before creating new campaign on CreateCampaign class
 * 		   12-10-2021 -    Ibrahim Rumi   -EPBBS-2243 modified query on FormCampaignLink class
 *         2021-11-10 -    Mairaj Haider  -EPBBS-2262 Store maze map details in Location object and copy it to Event object
 *         2022-02-11 -    RANAND         -EPBBS-2030 Store the winning affiliation on Event record
 *         2022-02-11 -    Ibrahim Rumi   -EPBBS-2387 UpdateSessionStatus() to auto cancel related sessions when event is cancelled
 *         2022-03-09 -    Ibrahim Rumi   -EPBBS-2453 ValidateStreamingURL() to validate straming URL for in person events
 *         2022-03-14 -    RANAND         -EPBBS-2482 ManageStaffForEvent to automatically manage Event staff creation
 *         2022-04-14 -    RANAND         -EPBBS-2570 CascadeEventFields to automatically copy cascaded field info from Group
 *         2022-06-01 -    Ibrahim Rumi   -EPBBS-2643 ManageStaffForEvent to automatically manage Event keyword creation
 *         2022-06-21 -    Ibrahim Rumi   -EPBBS-2750 AutoCreateEventItem() to auto create event items on approval submission
 *         2023-08-05 -    RANAND         -EPBBS-3285 UpdateAssociatedCampaign() to update associated Campaigns from Event in case of Event update
 **/
public with sharing class BTEventTriggerHandler {
	public static final String ACTIVE = 'Active';
    public static final String CANCELLED = 'Canceled';
    public static final String DRAFT = 'Draft';
    public static final String PENDING_APPROVAL = 'Pending Approval';
    /**
     * @author Nick Guia
     * @description Each time a new Event is created,
     *  auto create a new Campaign record based on the Event details.
     *  Mutable via conference360__Blackthorn_Events_Settings__c.Disable_Auto_Create_Campaign__c
     **/
    public class CreateCampaign extends TriggerAbstract {

        List<conference360__Event__c> recList = new List<conference360__Event__c>();
        conference360__Blackthorn_Events_Settings__c settings = conference360__Blackthorn_Events_Settings__c.getOrgDefaults();

        public override void process(SObject sobj) {
            if(!settings.Disable_Auto_Create_Campaign__c) {
                conference360__Event__c evRec = (conference360__Event__c) sobj;

                if(String.isNotBlank(evRec.Name) && evRec.conference360__Campaign__c == null) {
                    recList.add(evRec);
                }
            }
        }

        public override void execute() {
            try {
                if(!recList.isEmpty()) {
                    BTEventTriggerServices service = new BTEventTriggerServices(recList);
                    service.createCampaign();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @description forces a 1-1 record relationship between Blackthorn Events
     * and Campaigns
     */
    public class DeleteOldCampaignLink extends TriggerAbstract {
        Map<Id, Id> eventsByOldCampaign = new Map<Id, Id>();

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newObj = (conference360__Event__c) sobj;
            conference360__Event__c oldObj = (conference360__Event__c) oldRec;

            //if campaign lookup was updated
            if(newObj.conference360__Campaign__c != oldObj.conference360__Campaign__c)
            {
                //if there was previous Campaign value
                if(oldObj.conference360__Campaign__c != null) {
                    eventsByOldCampaign.put(oldObj.conference360__Campaign__c, oldObj.Id);
                }
            }
        }

        public override void execute() {
            try {
                List<Campaign> campUpdate = new List<Campaign>();
                for(Campaign iCamp : [SELECT Id, conference360__Event__c
                                    FROM Campaign
                                    WHERE
                                         Id IN :eventsByOldCampaign.keySet()
                                    AND RecordTypeId = :CampaignServices.EVENT_RECTYPE])
                {
                    if(eventsByOldCampaign.containsKey(iCamp.Id) &&
                            iCamp.conference360__Event__c == eventsByOldCampaign.get(iCamp.Id))
                    {
                        //if this was the old Campaign linked to the Event, unlink
                        iCamp.conference360__Event__c = NULL;
                    }
                    campUpdate.add(iCamp);
                }
                if(!campUpdate.isEmpty()) {
                    update campUpdate;
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @author Ibrahim Rumi
     * @description updates campaign status when event status is updated
     */
    public class ManageCampaignStatus extends TriggerAbstract {

        List<conference360__Event__c> recList = new List<conference360__Event__c>();

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newObj = (conference360__Event__c) sobj;
            conference360__Event__c oldObj = (conference360__Event__c) oldRec;

            if (newObj.conference360__Status__c != oldObj.conference360__Status__c){
                    recList.add(newObj);
                }

        }

        public override void execute() {
            try {
                if(!recList.isEmpty()) {
                    BTEventTriggerServices service = new BTEventTriggerServices(recList);
                    service.manageCampaignStatus();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

     /**
     * @author Aref Samad
     * @description updates campaign Name when event Internal Name is updated
     */
    public class UpdateCampusName extends TriggerAbstract {

        List<conference360__Event__c> recList = new List<conference360__Event__c>();

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newObj = (conference360__Event__c) sobj;
            conference360__Event__c oldObj = (conference360__Event__c) oldRec;

            if (newObj.Internal_Name__c!= oldObj.Internal_Name__c){
                    recList.add(newObj);
                }

        }

        public override void execute() {
            try {
                if(!recList.isEmpty()) {
                    BTEventTriggerServices service = new BTEventTriggerServices(recList);
                    service.updateCampusName();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @author Mairaj Haider
     * @description Copy location details to an Event from Location object
     */
    public class UpdateLocationDetails extends TriggerAbstract {

        List<conference360__Event__c> recList = new List<conference360__Event__c>();

        public override void process(SObject newRecord) {
            // new records always have to be processed 
            conference360__Event__c newObj = (conference360__Event__c) newRecord;
            if(newObj.Location__c != null){
                recList.add(newObj);
            }
        }

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newObj = (conference360__Event__c) sobj;
            conference360__Event__c oldObj = (conference360__Event__c) oldRec;

            //PROCESS IF: Location is changed
            if(newObj.Location__c != oldObj.Location__c){
                recList.add(newObj);
            }
        }

        public override void execute() {
            try {
                if(!recList.isEmpty()) {
                    BTEventTriggerServices service = new BTEventTriggerServices(recList);
                    service.copyLocationDetailsToEvent();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

     /**
     * @author Mairaj Haider
     * @description Update session status to cancelled if event is cancelled
     */
    public class UpdateSessionStatus extends TriggerAbstract {
        List<conference360__Event__c> recList = new List<conference360__Event__c>();

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newObj = (conference360__Event__c) sobj;
            conference360__Event__c oldObj = (conference360__Event__c) oldRec;

            //PROCESS IF: Status updated to Canceled
            if(newObj.conference360__Status__c == 'Canceled' && oldObj.conference360__Status__c != 'Canceled'){
                recList.add(newObj);
            }
        }

        public override void execute() {
            try {
                BTEventTriggerServices service = new BTEventTriggerServices(recList);
                service.updateSessionStatus();
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }
    /**
     * @description capture winning affiliation based upon Audience Type selected and store it in a field on Event
     */
    public class IdentifyWinningAffiliation extends TriggerAbstract {

        List<conference360__Event__c> eventList = new List<conference360__Event__c>();

        public override void process(SObject newRecord) {
            // new records always have to be processed 
            conference360__Event__c objEvent = (conference360__Event__c) newRecord;
            if(String.isNotBlank(objEvent.Audience_Type__c)){
                eventList.add(objEvent);
            }
        }

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newEvent = (conference360__Event__c) sobj;
            conference360__Event__c oldEvent = (conference360__Event__c) oldRec;

            //Whether Audience Type is modified on an existing event
            if(newEvent.Audience_Type__c != oldEvent.Audience_Type__c){
                eventList.add(newEvent);
            }
        }

        public override void execute() {
            try {
                if(!eventList.isEmpty()) {
                    BTEventTriggerServices service = new BTEventTriggerServices(eventList);
                    service.populateWinningAffiliation();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * description Validate If streaming URL is set for In Person events
     */
    public class ValidateStreamingURL extends TriggerAbstract{

        public override void process(sObject sobj){
            conference360__Event__c newObj = (conference360__Event__c) sobj;
            
            if(newObj.conference360__Category__c =='In-person' && 
            newObj.conference360__Streaming_Service_URL__c != null){
                newObj.addError('Streaming URL should be null for In-person Events. Choose hybrid or virtual as category instead');
            }
        }

        public override void process(sObject sobj, sObject oldRec){

            conference360__Event__c newObj = (conference360__Event__c) sobj;
            conference360__Event__c oldObj = (conference360__Event__c) oldRec;

            if(newObj.conference360__Category__c =='In-person' && 
            newObj.conference360__Streaming_Service_URL__c != null){
                newObj.addError('Streaming URL should be null for In-person Events. Choose hybrid or virtual as category instead');
            }
        }

    }
    /**
     * @description create/Update the below mentioned related child records for event automatically if an Event Group is Upserted
     * * Staff/Event Keywords
     */
    public class ManageChildRecsForEventOnEvntGrpChange extends TriggerAbstract {

        Set<Id> eventGroupIds = new Set<Id>();
        public override void process(SObject newRecord) {
            // new records always have to be processed 
            conference360__Event__c objEvent = (conference360__Event__c) newRecord;
            if(String.isNotBlank(objEvent.conference360__Event_Group__c)){
                eventGroupIds.add(objEvent.conference360__Event_Group__c);
            }
        }

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newEvent = (conference360__Event__c) sobj;
            conference360__Event__c oldEvent = (conference360__Event__c) oldRec;

            //Whether Event group on Event is changed
            if(newEvent.conference360__Event_Group__c != oldEvent.conference360__Event_Group__c){
                eventGroupIds.add(newEvent.conference360__Event_Group__c);
            }
        }

        public override void execute() {
            try {
                if(!eventGroupIds.isEmpty()) {
                    new BTStaffServices().manageEventStaffForGroup(eventGroupIds);
                    new BTEventKeywordServices().manageEventKeywordsForGroup(eventGroupIds);
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }
    /**
     * @description Cascade fields from Event Group if Event Group is populated on Events
     */
    public class CascadeEventFields extends TriggerAbstract {

        Set<Id> eventGroupIds = new Set<Id>();
        List<conference360__Event__c> eventList = new List<conference360__Event__c>();
        public override void process(SObject newRecord) {
            // new records always have to be processed 
            conference360__Event__c objEvent = (conference360__Event__c) newRecord;
            if(String.isNotBlank(objEvent.conference360__Event_Group__c)){
                eventGroupIds.add(objEvent.conference360__Event_Group__c);
                eventList.add(objEvent);
            }
        }

        // conditional processing on updated records
        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newEvent = (conference360__Event__c) sobj;
            conference360__Event__c oldEvent = (conference360__Event__c) oldRec;
            //Whether Event group on Event is changed - Included not blank check for new Event Group
            if(newEvent.conference360__Event_Group__c != oldEvent.conference360__Event_Group__c && 
              String.isNotBlank(newEvent.conference360__Event_Group__c)){
                eventGroupIds.add(newEvent.conference360__Event_Group__c);
                eventList.add(newEvent);
            }
        }

        public override void execute() {
            try {
                if(!eventGroupIds.isEmpty()) {
                    new BTEventTriggerServices(eventList).manageCascadeFieldsonEvent(eventGroupIds);
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @description Auto Creates Event Item when below conditions are satisfied
     * 1) Approval Stage is updated from "Draft" to "Pending for Approval" 
     * 2) no Event Item with Type = "Main event ticket" already exists for the Event
     * 3) Event > Event Setting > "Automate Event Item Creation" = TRUE
     */
    public class AutoCreateEventItem extends TriggerAbstract {

        List<conference360__Event__c> eventList = new List<conference360__Event__c>();

        // conditional processing on updated records
        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newEvent = (conference360__Event__c) sobj;
            conference360__Event__c oldEvent = (conference360__Event__c) oldRec;

            if(newEvent.Approval_Stage__c == PENDING_APPROVAL && 
                oldEvent.Approval_Stage__c == DRAFT
                ){
                    eventList.add(newEvent);
            }
        }

        public override void execute() {
            try {
                if(!eventList.isEmpty()) {
                    new BTEventTriggerServices(eventList).createEventItemOnApprovalSubmission();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }

    /**
     * @description EPBBS-3125 : Allow Status to be completed after Event is Approved
     */
    public class validatePermissionAndEventStatusUpdate extends TriggerAbstract {

        List<conference360__Event__c> eventList = new List<conference360__Event__c>();

        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newEvent = (conference360__Event__c) sobj;
            conference360__Event__c oldEvent = (conference360__Event__c) oldRec;
            boolean editPermissionAssigned = FeatureManagement.checkPermission('BT_Can_Edit_Approved_Events');
            
            if(newEvent.Approval_Stage__c == 'Approved'){
                if(newEvent.conference360__Status__c == 'Completed'){
                    //Allow status to be completed without custom permission
                }else if(!editPermissionAssigned){
                    newEvent.addError('Only users with the custom permission "BT | Can edit approved events" should be able to modify an approved Event');
                }
            }
        }
        public override void execute() {
            
        }
    }

    /**
     * @description [EPBBS-3285 Updates associated Campaign field values in case Event is updated in order tro maintain the consistency of field values]
     */
    public class UpdateAssociatedCampaign extends TriggerAbstract {

        List<conference360__Event__c> eventList = new List<conference360__Event__c>();

        // conditional processing on updated records
        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event__c newEvent = (conference360__Event__c) sobj;
            conference360__Event__c oldEvent = (conference360__Event__c) oldRec;

            if(newEvent.conference360__Campaign__c != null 
                && ( newEvent.conference360__Campaign__c != oldEvent.conference360__Campaign__c 
                || newEvent.Internal_Name__c != oldEvent.Internal_Name__c 
                || newEvent.Name != oldEvent.Name 
                || newEvent.conference360__Event_Start_Date__c != oldEvent.conference360__Event_Start_Date__c 
                || newEvent.conference360__Event_End_Date__c != oldEvent.conference360__Event_End_Date__c 
                || newEvent.conference360__Event_Page_URL__c != oldEvent.conference360__Event_Page_URL__c 
                || newEvent.conference360__Form2__c != oldEvent.conference360__Form2__c 
                || newEvent.conference360__Form_Post_Registration__c != oldEvent.conference360__Form_Post_Registration__c 
                || newEvent.conference360__Event_Settings__c != oldEvent.conference360__Event_Settings__c 
                || newEvent.conference360__Custom_CSS_Url__c != oldEvent.conference360__Custom_CSS_Url__c 
                || newEvent.Audience_Type__c != oldEvent.Audience_Type__c 
                || newEvent.Disable_All_Email_Sends__c != oldEvent.Disable_All_Email_Sends__c 
                )){
                    eventList.add(newEvent);
            }
        }

        public override void execute() {
            try {
                if(!eventList.isEmpty()) {
                    new BTEventTriggerServices(eventList).refreshCampaignInfo();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }
}