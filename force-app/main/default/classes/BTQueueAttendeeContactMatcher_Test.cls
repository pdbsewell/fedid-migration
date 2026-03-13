/**
 * @author Nick Guia
 * @date 15-10-2020
 * @group Event Management
 * @description test class for BTQueueAttendeeContactMatcher 
 **/
@isTest(isParallel=true)
private class BTQueueAttendeeContactMatcher_Test {

    private static final Integer BULK_ATTENDEE_COUNT = 40;

    @TestSetup
    static void makeData(){
        Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
        insert envSettings;
        
        //create blackthorn settings
		conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
        settings.Disable_Custom_Matching_Rules__c = false;
        settings.Custom_Attende_Matching_Threshold__c = 40;
        insert settings;

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
        insert btEvent;
        System.assert(btEvent.Id != null, 'Unable to setup Blackthorn Event');

        //create contact
        Contact con = new Contact(
            FirstName = 'BTQueueAttendeeContactMatcher_Test',
            LastName = 'BTQueueAttendeeContactMatcher_Test',
            Email = 'test@test.org'
        );
        insert con;
        System.assert(con.Id != null, 'Unable to setup Contact record');
    }

    /**
     * @description bulk insert attendees without a related contact.
     * 1 of the records should at least match with the setup contact, the rest
     * should create new contacts. At the end of the process, the created contacts
     * should match BULK_ATTENDEE_COUNT
     */
    @isTest
    static void shouldProcessBulkAttendeeContactMatch() {
        //given
        conference360__Event__c btEvent = [SELECT Id 
                                        FROM conference360__Event__c
                                        LIMIT 1];
        //bulk create attendees
        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEvent.Id, BULK_ATTENDEE_COUNT-1);
        
        //at least one attendee should match details with existing contact
        conference360__Attendee__c att = new conference360__Attendee__c();
        att.conference360__First_Name2__c = 'BTQueueAttendeeContactMatcher_Test';
        att.conference360__Last_Name2__c = 'BTQueueAttendeeContactMatcher_Test';
        att.conference360__Email2__c = 'test@test.org';
        att.conference360__Event__c = btEvent.Id;
        attendeeList.add(att);
        TriggerCommon.disableTrigger('conference360__Attendee__c');
        insert attendeeList;
        TriggerCommon.enableTrigger('conference360__Attendee__c');

        Test.startTest();

        //when
        BTQueueAttendeeContactMatcher asyncMatcher = new BTQueueAttendeeContactMatcher(attendeeList);
        System.enqueueJob(asyncMatcher);

        Test.stopTest();

        Set<Id> attendeeIds = (new Map<Id, conference360__Attendee__c>(attendeeList)).keySet();
        List<Contact> conList = [SELECT Id FROM Contact LIMIT 100];
        attendeeList = [SELECT Id, conference360__Contact__c 
                        FROM conference360__Attendee__c 
                        WHERE Id IN :attendeeIds];
        System.assert(attendeeList != null, 'Unable to insert Attendee records');
        for(conference360__Attendee__c iAtt : attendeeList) {
            System.assert(iAtt.conference360__Contact__c != null, 'Unable to match / create a Contact for Attendee');
        }
        System.assertEquals(BULK_ATTENDEE_COUNT, conList.size(), 'Unexpected number of Contact records created');
    }
}