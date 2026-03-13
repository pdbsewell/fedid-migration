/**
 * @author Aref Samad
 * @date 18-08-2021
 * @group Event Management
 * @description Test class for BTCheckinService
 * @revision
 * 18.08.2021  Aref Samad    - EPBBS-2087 Number Reg - Check In - add test mothod checkInAttendeeGroup_Test for Check in Guest Attendees in attendee group when Primary attendee checked in
 **/
@IsTest(isParallel=true)
public without sharing class BTCheckinService_Test {

    @TestSetup
    static void setup() {
        //create environment settings
        Environment_Settings__c envSettings = new Environment_Settings__c();
		envSettings.Contact_Loose_Match_Duplicate_Rule_Name__c = 'Contact_Loose_Match';
        insert envSettings;

        //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        insert relSetting;

        //create event settings
        conference360__Event_Settings__c eventSettings = new conference360__Event_Settings__c(
        	Name = 'BTAttendeeTriggerHandler_Test_event_settings',
            conference360__Relationship_Settings__c  = relSetting.id
        );
        insert eventSettings;

        //create blackthorn settings
		conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
        settings.Disable_Auto_Create_Campaign__c = false;
        settings.Custom_Attende_Matching_Threshold__c = 40;
        insert settings;

        //create contact
        Contact con = new Contact(
            FirstName = 'BTAttendeeTriggerHandler_Test',
            LastName = 'test1',
            Email = 'test@test.org'
        );
        insert con;

        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        for(conference360__Event__c event:btEventList){
            event.conference360__Event_Settings__c = eventSettings.id;
        }
        insert btEventList;

        //create blackthorn event item
        conference360__Event_Item__c  eventItem = new conference360__Event_Item__c(
        	conference360__Item_Name__c  = 'Primary Attendee',
            conference360__Type__c  = 'Main event ticket',
            conference360__Minimum_Quantity__c  = 1,
            conference360__Maximum_Quantity__c  = 1,
            conference360__Event__c = btEventList[0].Id
        );
        insert eventItem;

           //create blackthorn event item
        conference360__Event_Item__c  eventItemGuest = new conference360__Event_Item__c(
            conference360__Item_Name__c  = 'Guest Attendee',
            conference360__Type__c  = 'Guest',
            conference360__Minimum_Quantity__c  = 0,
            conference360__Maximum_Quantity__c  = 10,
            conference360__Event__c = btEventList[0].Id
        );
        insert eventItemGuest;

        //create blackthorn event attendee group
       	conference360__Attendee_Group__c attendee_Group = new conference360__Attendee_Group__c(
        	Name = 'BTAttendeeTriggerHandler_Test_Attendee_group'
        );
        insert attendee_Group;

    }

     /**
     * @Author Aref Samad
     * @description EPBBS-2087 Number Reg - Check In - Check in Guest Attendees in attendee group when Primary attendee checked in
     */
    @isTest
    static void checkInAttendeeGroup_Test() {

        //given
        TriggerCommon.disableTrigger('conference360__Attendee__c');

        List<conference360__Event__c> btEventList=[Select Id from conference360__Event__c];

        List<conference360__Attendee_Group__c> btEventGroupList=[Select Id from conference360__Attendee_Group__c];

        List<conference360__Event_Item__c> primaryEventItemList=[Select Id from conference360__Event_Item__c where conference360__Event__c=:btEventList[0].Id and conference360__Type__c  = 'Main event ticket'];
        List<conference360__Event_Item__c> guestEventItemList=[Select Id from conference360__Event_Item__c where conference360__Event__c=:btEventList[0].Id and conference360__Type__c  = 'Guest'];

        List<Contact> conList = [SELECT Id FROM Contact];

        List<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendee(btEventList[0].Id, 10);

        for(conference360__Attendee__c attendee:attendeeList)
        {
            attendee.conference360__Attendee_Group__c=btEventGroupList[0].Id;
            attendee.conference360__Contact__c=null;
            attendee.conference360__Attendance_Status__c='Pending';
            attendee.conference360__Event_Item__c=guestEventItemList[0].Id;
            attendee.conference360__Registration_Status__c=BTAttendeeServices.REG_STATUS_REGISTERED;
        }

        attendeeList[0].conference360__Contact__c=conList[0].Id;
        attendeeList[0].conference360__Event_Item__c=primaryEventItemList[0].Id;
        insert attendeeList;

        attendeeList[0].conference360__Attendance_Status__c=BTAttendeeServices.ATTN_STATUS_ATTENDED;
        update attendeeList[0];

        List<SObject> records=new List<SObject>();
        records.add(attendeeList[0]);

        Test.startTest();

        //when
        BTCheckinService btCheckInService=new BTCheckinService(records);
        btCheckInService.checkInAttendeeGroup();

        Test.stopTest();

        //then
        List<conference360__Attendee__c> attendUpdatedList=[SELECT Id From conference360__Attendee__c
        WHERE conference360__Attendee_Group__c =:btEventGroupList[0].Id
        AND conference360__Attendance_Status__c=:BTAttendeeServices.ATTN_STATUS_ATTENDED];

        System.assertEquals(10,attendUpdatedList.size());

        TriggerCommon.enableTrigger('conference360__Attendee__c');
    }

}