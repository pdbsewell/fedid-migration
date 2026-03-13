/**
 * @author Nick Guia
 * @date 15-10-2020
 * @group Event Management
 * @description test class for BTAttendeeContactMatcher
 **/
@isTest(isParallel=true)
private class BTAttendeeContactMatcher_Test {

    @TestSetup
    static void makeData(){
        Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
		insert envSettings;

		Contact con  = TestHelper.createProspectiveStudentContact(1)[0];
        con.FirstName = 'BTAttendeeContactMatcher_Test';
        con.LastName = 'BTAttendeeContactMatcher_Test';
        con.Email = 'Test@test.org';
        insert con;

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

        //create blackthorn settings
		conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
		settings.Disable_Auto_Create_Campaign__c = false;
        insert settings;

        //create blackthorn event
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.conference360__Event_Settings__c = eventSettings.id;
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        insert btEvent;
        System.assert(btEvent.Id != null, 'Unable to setup Blackthorn Event');
    }

    /**
     * @description should be able to link new Attendees against existing Contact
     * using their key details : FN, LN, Email. If no match is found, Create a new
     * Contact record and link it back to the attendee
     */
    @isTest
    static void shouldSetMatchedContactOnSingleAttendee() {
        //given
        conference360__Event__c btEvent = [SELECT Id
                                        FROM conference360__Event__c
                                        LIMIT 1];
        Contact existingCon = [SELECT Id FROM Contact LIMIT 1];

        conference360__Attendee__c att = TestHelper.createBlackthornAttendee(btEvent.Id, 1)[0];
        att.conference360__First_Name2__c = 'BTAttendeeContactMatcher_Test';
        att.conference360__Last_Name2__c = 'BTAttendeeContactMatcher_Test';
        att.conference360__Email2__c = 'Test@test.org';

        Test.startTest();

        //when
        BTAttendeeContactMatcher matcher = new BTAttendeeContactMatcher(att);
        matcher.findAllEmailFields();
        matcher.run();

        Test.stopTest();

        //then
        System.assertEquals(existingCon.Id, att.conference360__Contact__c, 'attendee unable to match against existing contact');
    }

    /**
     * @description should be able to link new Attendees against existing Contact
     * using their key details : FN, LN, Email. If no match is found, Create a new
     * Contact record and link it back to the attendee
     */
    @isTest
    static void shouldSetMatchedContactOnMultipleAttendees() {
        //given
        conference360__Event__c btEvent = [SELECT Id
                                        FROM conference360__Event__c
                                        LIMIT 1];
        Contact existingCon = [SELECT Id FROM Contact LIMIT 1];

        //create two attendee records 
        List<conference360__Attendee__c> attList = TestHelper.createBlackthornAttendee(btEvent.Id, 2);

        // set the first one to match the existing contact
        conference360__Attendee__c attendee1 = attList[0];
        attendee1.conference360__First_Name2__c = 'BTAttendeeContactMatcher_Test';
        attendee1.conference360__Last_Name2__c = 'BTAttendeeContactMatcher_Test';
        attendee1.conference360__Email2__c = 'Test@test.org';

        //set the second attendee record to create a new contact
        conference360__Attendee__c attendee2 = attList[1];
        attendee2.conference360__First_Name2__c = 'new_contact';
        attendee2.conference360__Last_Name2__c = 'not_existing';
        attendee2.conference360__Email2__c = 'different.email@test.org';

        Test.startTest();

        //when
        BTAttendeeContactMatcher matcher = new BTAttendeeContactMatcher(attList);
        matcher.findAllEmailFields();
        matcher.run();

        Test.stopTest();

        //then
        System.assertEquals(existingCon.Id, attList[0].conference360__Contact__c, 'first attendee unable to match against existing contact');
        System.assertnotEquals(existingCon.Id, attList[1].conference360__Contact__c, 'second attendee unexpectedly matched against existing contact');
        System.assert(attList[1].conference360__Contact__c != null, 'Unable to create a new Contact for the third attendee');
    }

    /**
     * @description should be able to link new Attendees against existing Contact
     * using their key details : FN, LN, Email. If no match is found, Create a new
     * Contact record and link it back to the attendee
     */
    @isTest
    static void shouldMatchForMultipleDuplicateContacts() {
        //given
        conference360__Event__c btEvent = [SELECT Id
                                        FROM conference360__Event__c
                                        LIMIT 1];
        List<Contact> conList = new List<Contact>();
        for(Contact con : TestHelper.createProspectiveStudentContact(2)) {
            con.FirstName = 'mBTAttendeeContactMatcher_Test';
            con.LastName = 'mBTAttendeeContactMatcher_Test';
            con.Email = 'Test@test.org';
            conList.add(con);
        }
        insert conList;
        Set<Id> conIds = (new Map<Id, Contact>(conList)).keySet();

        conference360__Attendee__c att = TestHelper.createBlackthornAttendee(btEvent.Id, 1)[0];
        att.conference360__First_Name2__c = 'mBTAttendeeContactMatcher_Test';
        att.conference360__Last_Name2__c = 'mBTAttendeeContactMatcher_Test';
        att.conference360__Email2__c = 'Test@test.org';

        Test.startTest();

        //when
        BTAttendeeContactMatcher matcher = new BTAttendeeContactMatcher(att);
        matcher.findAllEmailFields();
        matcher.run();

        Test.stopTest();

        //then
        System.assert(conIds.contains(att.conference360__Contact__c), 'attendee unable to match against existing contacts');
    }
}