/**
 * @author Ibrahim Rumi
 * @date 19-10-2020
 * @group Event Management
 * @description Test class for BTEventSettingsTriggerHandler.
 **/
@IsTest(isParallel=true)
private class BTEventSettingsTriggerHandler_Test {

    @TestSetup
    static void setup() {
        //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        relSetting.bt_stripe__Default__c = true;
        insert relSetting;
        
	}
     /**
     * @Author Ibrahim Rumi
     * @description appends a default relationship setting when event settings is created without one.
     */
    @isTest
    static void ManageRelationshipSettingsTest() {
    	conference360__Event_Settings__c eventSettings = new conference360__Event_Settings__c(
        	Name = 'BTAttendeeTriggerHandler_Test_event_settings'
        );
        
        Test.startTest();
        
        insert eventSettings;
        
        Test.stopTest();
        
        conference360__Event_Settings__c eventSettingRec = [select id,conference360__Relationship_Settings__c FROM
                                                         conference360__Event_Settings__c where name = 'BTAttendeeTriggerHandler_Test_event_settings'][0];
        system.assertNotEquals(null, eventSettingRec.conference360__Relationship_Settings__c, 'unable to append relationship setting');
    }
    
}