/**
 * @author Ibrahim Rumi
 * @date 15-10-2020
 * @group Event Management
 * @description Trigger handler for conference360__Event_Settings__c object (Blackthorn)
 * this pattern will allow us to move to test mocking framework in the future
 **/
public without sharing class BTRelationshipSettingSelector {
    /**
     * @author Ibrahim Rumi
     * @description returns the oldest default relationship setting
     **/
    public bt_stripe__Relationship_Settings__c getDefaultRelationshipSetting(){
            bt_stripe__Relationship_Settings__c relaltionshipSettings;
            try{
                relaltionshipSettings = new bt_stripe__Relationship_Settings__c();
                relaltionshipSettings = [SELECT id FROM bt_stripe__Relationship_Settings__c 
                                                              WHERE bt_stripe__Default__c = true
                                                              ORDER BY CreatedDate ASC LIMIT 1][0];
                
            }catch(Exception e) {
                    LogUtilityException.logException(e);
                    System.debug(LoggingLevel.ERROR, e.getStackTraceString() + '\n ' + e.getMessage());
                }
            return relaltionshipSettings;
        }
}