/**
 * @author Ibrahim Rumi
 * @date 15-10-2020
 * @group Event Management
 * @description Trigger handler for conference360__Event_Settings__c object (Blackthorn)
 **/
public without sharing class BTEventSettingsTriggerServices {

    @TestVisible
    private List<conference360__Event_Settings__c> recList;
    
    @TestVisible
	private BTRelationshipSettingSelector selector;

    public BTEventSettingsTriggerServices(List<conference360__Event_Settings__c> recs) {
        this.recList = recs;
    }
    
    public void assignDefaultRelationshipSetting(){
        this.selector = new BTRelationshipSettingSelector();
        if(this.recList != null) {
            bt_stripe__Relationship_Settings__c setting = selector.getDefaultRelationshipSetting();
            if(setting.id != null){
                for(conference360__Event_Settings__c iEventSettings: recList){
                    iEventSettings.conference360__Relationship_Settings__c = setting.id;
                }
            }
        }
    }
}