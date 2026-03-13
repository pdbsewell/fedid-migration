/**
 * @author       : Ibrahim Rumi
 * @date         : 21-06-2022
 * @group        : Event Management
 * @description  : Test class for conference360__Event__c object selector class (Blackthorn)
**/
@isTest(isParallel=true)
private class BTEventSelector_Test {

    @TestSetup
    static void makeData(){
          //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        relSetting.bt_stripe__Relationship_Rule__c = 'No Matching Or Record Creation';
        insert relSetting;

        //create event settings
        conference360__Event_Settings__c eventSettings = new conference360__Event_Settings__c(
        	Name = 'BTAttendeeContactMatcher_Test_event_settings',
            conference360__Relationship_Settings__c  = relSetting.id
        );
        insert eventSettings;

        //create blackthorn event
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.conference360__Event_Settings__c = eventSettings.id;
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        insert btEvent;


        conference360__Event_Item__c evtItem = new conference360__Event_Item__c(
            conference360__Item_Name__c = 'Primary',
            conference360__Type__c = 'Main event ticket',
            conference360__Free__c = true,
            conference360__Email__c = 'Required',
            conference360__FullName__c = 'Required',
            conference360__Quantity_Made_Available__c = 50,
            conference360__Event__c =btEvent.id
        );
        
        insert evtItem;
	}
    
    /**
    * @description test selector getSObjectType
    */
    @isTest
    static void shouldReturnEventObjectType() {

        //given
        Schema.SObjectType eventObjType;

        //when
        Test.startTest();

        eventObjType = new BTEventSelector().getSObjectType();

        Test.stopTest();

        //then
        System.assertEquals(conference360__Event__c.SObjectType, eventObjType, 'Unexpected SObjectType');
    }
    
    /**
     * @description test selector select records filtered by IDs
     */
    @isTest
    static void shouldReturnRecordsInIds() {

        //given
        Map<Id, conference360__Event__c> eventMap = new Map<Id, conference360__Event__c>([SELECT Id FROM conference360__Event__c]);
        List<conference360__Event__c> rs;

        //when
        Test.startTest();

        rs = new BTEventSelector().selectById(eventMap.keySet());

        Test.stopTest();

        //then
        System.assertEquals(eventMap.size(), rs.size(), 'Unexpected number of records from result set');
    }

    /**
     * @description test selector select records filtered by IDs
     */
    @isTest
    static void shouldReturnRecordsInIdsAsMap() {

        //given
        Map<Id, conference360__Event__c> eventMap = new Map<Id, conference360__Event__c>([SELECT Id FROM conference360__Event__c]);
        Map<Id, conference360__Event__c> rs;

        //when
        Test.startTest();

        rs = new BTEventSelector().selectMapById(eventMap.keySet());

        Test.stopTest();

        //then
        System.assertEquals(eventMap.size(), rs.size(), 'Unexpected number of records from result set');
    }
    
     /**
     * @description test selector select event and event settings records filtered by IDs
     */
    @isTest
    static void selectExistingEventSettingsByEventIdsTest() {

        //given
        Map<Id, conference360__Event__c> eventMap = new Map<Id, conference360__Event__c>([SELECT Id FROM conference360__Event__c]);
        Map<Id, conference360__Event__c> rs;

        //when
        Test.startTest();

        rs = new BTEventSelector().selectExistingEventSettingsByEventIds(eventMap.keySet());

        Test.stopTest();

        //then
        System.assertEquals(eventMap.size(), rs.size(), 'Unexpected number of records from result set');
    }
    
    /**
    * @description test selector select event item records filtered by event id
    */
    @isTest
    static void selectExistingEventItemsByEventIdsTest() {

        //given
        
        conference360__Event_Item__c evtItem = [SELECT Id,conference360__Event__c FROM conference360__Event_Item__c WHERE conference360__Event__c != null][0];
        Map<Id, conference360__Event__c> eventMap = new Map<Id, conference360__Event__c>([SELECT Id FROM conference360__Event__c WHERE id =: evtItem.conference360__Event__c]);
        Map<Id, conference360__Event__c> rs;

        //when
        Test.startTest();

        rs = new BTEventSelector().selectExistingEventItemsByEventIds(eventMap.keySet());

        Test.stopTest();
        
        conference360__Event__c eve = rs.get(evtItem.conference360__Event__c);
		list<conference360__Event_Item__c> eventItemList = eve?.conference360__Event_Items__r;
        
        //then
        System.assertEquals(eventMap.size(), rs.size(), 'Unexpected number of records from result set');
        System.assert(eventItemList.size()>0,'event item list not returned');
    }
}