/**
 * @author Nick Guia
 * @date 29-01-2021
 * @group Event Management
 * @description Test class for BTAttendeeSelector
 *   17.01.2022  Ibrahim Rumi    - EPBBS-2379 test selectExistingAttendeesByEventIds method to fetch all attendees in an event
 *   08.02.2022  Ibrahim Rumi    - EPBBS-2427 selectAttendeesByAttendeegroupIdsTest method to test fetching all attendees relating to eattendeevent groups in an event
 */
@isTest(isParallel=true)
private class BTAttendeeSelector_Test {

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

        //create attendees
        List<conference360__Attendee__c> attList = TestHelper.createBlackthornAttendee(btEvent.Id, 10);
        insert attList;
        
        //create blackthorn event attendee group
       	conference360__Attendee_Group__c attendee_Group = new conference360__Attendee_Group__c(
        	Name = 'BTAttendeeTriggerHandler_Test_Attendee_group'
        );
        insert attendee_Group;
    }

    /**
     * @description test selector getSObjectType
     */
    @isTest
    static void shouldReturnAttendeeObjectType() {

        //given
        Schema.SObjectType attendeeObjType;

        //when
        Test.startTest();

        attendeeObjType = new BTAttendeeSelector().getSObjectType();

        Test.stopTest();

        //then
        System.assertEquals(conference360__Attendee__c.SObjectType, attendeeObjType, 'Unexpected SObjectType');
    }

    /**
     * @description test selector select records filtered by IDs
     */
    @isTest
    static void shouldReturnRecordsInIds() {

        //given
        Map<Id, conference360__Attendee__c> attMap = new Map<Id, conference360__Attendee__c>([SELECT Id FROM conference360__Attendee__c]);
        List<conference360__Attendee__c> rs;

        //when
        Test.startTest();

        rs = new BTAttendeeSelector().selectById(attMap.keySet());

        Test.stopTest();

        //then
        System.assertEquals(attMap.size(), rs.size(), 'Unexpected number of records from result set');
    }

    /**
     * @description test selector select records filtered by IDs
     */
    @isTest
    static void shouldReturnRecordsInIdsAsMap() {

        //given
        Map<Id, conference360__Attendee__c> attMap = new Map<Id, conference360__Attendee__c>([SELECT Id FROM conference360__Attendee__c]);
        Map<Id, conference360__Attendee__c> rs;

        //when
        Test.startTest();

        rs = new BTAttendeeSelector().selectMapById(attMap.keySet());

        Test.stopTest();

        //then
        System.assertEquals(attMap.size(), rs.size(), 'Unexpected number of records from result set');
    }
    
    /**
     * @description test return ExistingAttendees By EventIds
     */
    @isTest
    static void selectExistingAttendeesByEventIds_Test() {

        List<conference360__Attendee__c> attList = new List<conference360__Attendee__c>();
        //given
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
		List<conference360__Attendee__c> existingAttList = [SELECT id, conference360__Event__c FROM conference360__Attendee__c 
                                                    		WHERE conference360__Event__c =: btEvent.Id];
        //when
        Test.startTest();

        attList = new BTAttendeeSelector().selectExistingAttendeesByEventIds(new set<id>{btEvent.Id});

        Test.stopTest();

        //then
        System.assertEquals(attList.size(),existingAttList.size(), 'Unexpected number of records from result set');
    }
    
    /**
     * @description test return ExistingAttendees By attendeeGroupIds
     */
    @isTest
    static void selectAttendeesByAttendeeGroupIds_test() {

        List<conference360__Attendee__c> attList = new List<conference360__Attendee__c>();
        //given
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Attendee_Group__c btAttendeeGroup = [SELECT Id FROM conference360__Attendee_Group__c LIMIT 1];
		List<conference360__Attendee__c> existingAttList = [SELECT id, conference360__Event__c,conference360__Attendee_Group__c FROM conference360__Attendee__c 
                                                    		WHERE conference360__Event__c =: btEvent.Id];
        for(conference360__Attendee__c att: existingAttList){
            att.conference360__Attendee_Group__c = btAttendeeGroup.Id;
        }
        update existingAttList;
        //when
        Test.startTest();

        attList = new BTAttendeeSelector().selectAttendeesByAttendeeGroupIds(new set<id>{btAttendeeGroup.Id});

        Test.stopTest();

        //then
        System.assertEquals(attList.size(),existingAttList.size(), 'Unexpected number of records from result set');
    }
}