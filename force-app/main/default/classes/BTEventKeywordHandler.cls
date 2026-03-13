/**
 * @author RANAND
 * @date 2022-05-10
 * @group Event Keyword Management
 * @description Handler class for Blackthorn Event Keyword Trigger
 * @revision
 *         2022-05-10 -   RANAND           -EPBBS-2629 Validate Event Keyword Selection on Events
 *         2022-06-01 -   Ibrahim Rumi     -EPBBS-2643 Manage event keywords cascading from event groups to related events
 **/
public with sharing class BTEventKeywordHandler {
    /**
     * @description EPBBS-2629 Validate the selection of Keywords against an Event
     **/
    public class ValidateCategoryonKeyword extends TriggerAbstract {

        List<conference360__Event_Keyword__c> eventKeywordList = new List<conference360__Event_Keyword__c>();
        //process all new records
        public override void process(SObject sobj) {
            conference360__Event_Keyword__c newRec = (conference360__Event_Keyword__c) sobj;
            if(newRec.conference360__Event__c != null && newRec.conference360__Keyword__c != null){
                eventKeywordList.add(newRec);
            }
        }
        //process relevant updated records
        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event_Keyword__c newObj = (conference360__Event_Keyword__c) sobj;
            conference360__Event_Keyword__c oldObj = (conference360__Event_Keyword__c) oldRec;
            if(newObj.conference360__Event__c != null && newObj.conference360__Keyword__c != null &&
                (newObj.conference360__Event__c != oldObj.conference360__Event__c || 
                newObj.conference360__Keyword__c != oldObj.conference360__Keyword__c)){
                    
                eventKeywordList.add(newObj);
            }
        }
        public override void execute(){
            try {
                new BTEventKeywordServices().validateCategory(eventKeywordList);
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
     * @description automatically create Event Keyword records whenever a new event keyword is mapped with Event Group
     */
    public class autoCreateEventKeywords extends TriggerAbstract {
        List<conference360__Event_Keyword__c> groupEvtKeywordList = new List<conference360__Event_Keyword__c>();
        Set<Id> groupIds = new Set<Id>();

        // new records always have to be processed if Event_Group__c is not null
        public override void process(SObject newRecord) {
            conference360__Event_Keyword__c objEventKeyword = (conference360__Event_Keyword__c) newRecord;
            if(String.isNotBlank(objEventKeyword.Event_Group__c)){
                groupIds.add(objEventKeyword.Event_Group__c);
            }
        }

        // records to be processed if Event_Group__c or Keyword is changed on existing record
        public override void process(SObject sobj, SObject oldRec) {
            conference360__Event_Keyword__c newEventKeyword = (conference360__Event_Keyword__c) sobj;
            conference360__Event_Keyword__c oldEventKeyword = (conference360__Event_Keyword__c) oldRec;
            if(String.isNotBlank(newEventKeyword.Event_Group__c) && (newEventKeyword.conference360__Keyword__c != oldEventKeyword.conference360__Keyword__c || newEventKeyword.Event_Group__c != oldEventKeyword.Event_Group__c)){
                groupIds.add(oldEventKeyword.Event_Group__c);
                groupIds.add(newEventKeyword.Event_Group__c);
            }
        }

        public override void execute() {
            try {
                //Manage Staff records when Event is created with Event Group 
                BTEventKeywordServices service = new BTEventKeywordServices();
                service.manageEventKeywordsForGroup(groupIds);
            } 
            catch(Exception e) {
                LogUtilityException.logException(e);
            } 
            finally {
                LogUtilityException.getLimits();
            }
        }
    }
}