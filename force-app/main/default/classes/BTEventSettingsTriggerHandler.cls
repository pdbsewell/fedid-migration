/**
 * @author Ibrahim Rumi
 * @date 15-10-2020
 * @group Event Management
 * @description Trigger handler for conference360__Event_Settings__c object (Blackthorn)
 **/
public without sharing class BTEventSettingsTriggerHandler {
    /**
     * @author Ibrahim Rumi
     * @description Each time a new Event Settings is created, 
     *  auto populate the oldest default relationship setting if one is not linked to the event settings.
     **/
    public without sharing class ManageRelationshipSettings extends TriggerAbstract {

        List<conference360__Event_Settings__c> recList = new List<conference360__Event_Settings__c>();

        public override void process(SObject sobj) {
            conference360__Event_Settings__c newObj = (conference360__Event_Settings__c) sobj;
            if(newObj.conference360__Relationship_Settings__c == null) {
                recList.add(newObj);
            }
        }

        public override void execute() {
            try {
                if(!recList.isEmpty()) {
                    BTEventSettingsTriggerServices EventSettingsServices = new BTEventSettingsTriggerServices(recList);
                    EventSettingsServices.assignDefaultRelationshipSetting();
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
            } finally {
                LogUtilityException.getLimits();
            }
        }
    }
}