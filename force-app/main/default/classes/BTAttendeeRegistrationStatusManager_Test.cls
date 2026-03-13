/**
* @author Ibrahim Rumi
* @date 11-05-2021
* @description Sibling test class for BTAttendeeRegistrationStatusManager
* revision
*   17-06-2021  Ibrahim Rumi    - EPBBS-1888 added methods testWLPendingToPendingStatusChange and testRegisteredToCanceledStatusChange
*   24-06-2021  Ibrahim Rumi    - EPBBS-2019 added method testPendingToRegisteredStatusChange
**/
@isTest(isParallel=true)
public class BTAttendeeRegistrationStatusManager_Test {

    @TestSetup
    static void makeData(){

        //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        insert relSetting;
        
        //create blackthorn settings
		conference360__Blackthorn_Events_Settings__c settings = new conference360__Blackthorn_Events_Settings__c();
        settings.Disable_Auto_Create_Campaign__c = false;
        settings.Custom_Attende_Matching_Threshold__c = 40;
        insert settings;
        
		
        //create an event setting
        conference360__Event_Settings__c eventSettings = TestHelper.createEventSettings(1)[0];
            eventSettings.waitlist_registration_expiry__c = 4.0;
        insert eventSettings;
        
        //create an event
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.conference360__Event_Settings__c = eventSettings.id;
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        insert btEvent;
        
        //create blackthorn event item
        conference360__Event_Item__c  eventItem = new conference360__Event_Item__c(
            conference360__Item_Name__c  = 'Primary Attendee',
            conference360__Type__c  = 'Main event ticket',
            conference360__Minimum_Quantity__c  = 1,
            conference360__Maximum_Quantity__c  = 1,
            conference360__Event__c = btEvent.Id
        );
        insert eventItem;
		
        //create blackthorn event attendee group
       	conference360__Attendee_Group__c attendee_Group = new conference360__Attendee_Group__c(
        	Name = 'BTAttendeeTriggerHandler_Test_Attendee_group'
        );
        insert attendee_Group;

        //create an attendee
        
        list<conference360__Attendee__c> attendeeList = TestHelper.createBlackthornAttendeeWithMatchingContacts(btEvent.Id, 2);
        
        conference360__Attendee__c attendee = attendeeList[0];
        attendee.conference360__Attendee_Group__c = attendee_Group.id;
        attendee.conference360__Event_Item__c  = eventItem.id;
        
        conference360__Attendee__c attendee2 = attendeeList[1];
        attendee2.conference360__Attendee_Group__c = attendee_Group.id;

        insert attendeeList;
    }
    
    /*Description Test if Attendee's Registration status is changed from Waitlisted - Pending to Pending
     */
    @isTest
    static void testWLPendingToPendingStatusChange(){
    	Map<Id, conference360__Attendee__c> oldAttendeeMap = new Map<Id, conference360__Attendee__c>();
        Map<Id, conference360__Attendee__c> newAttendeeMap = new Map<Id, conference360__Attendee__c>();
        conference360__Attendee__c oldAttendee = [SELECT Id,conference360__Event__c,Registration_status_reason__c 
												  FROM conference360__Attendee__c LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id,conference360__Event_Settings__c 
                                           FROM conference360__Event__c 
                                           Where Id =: oldAttendee.conference360__Event__c LIMIT 1];
        conference360__Event_Settings__c btEventSetting = [SELECT Id, Skip_Pending_for_Waitlisting__c, waitlist_registration_expiry__c
            											   FROM conference360__Event_Settings__c 
             											   WHERE Id =: btEvent.conference360__Event_Settings__c LIMIT 1];
        //Setting Event setting's Skip Pending for Waitlist to true
        btEventSetting.Skip_Pending_for_Waitlisting__c = true;
        update btEventSetting;
        
        oldAttendee.conference360__Registration_Status__c = 'Waitlisted - Pending';
        oldAttendeeMap.put(oldAttendee.Id, oldAttendee);
        conference360__Attendee__c newattendee = oldAttendee.clone(true);
        //Attendee waitslist spot opens 
        newattendee.conference360__Registration_Status__c = 'Pending';
        newAttendeeMap.put(newattendee.Id,newattendee); 
        
        //when
        Test.startTest();
        
        BTAttendeeRegistrationStatusManager helper = new BTAttendeeRegistrationStatusManager(oldAttendeeMap, newAttendeeMap);
        helper.run();
        //then
        Test.stopTest();
        
        BTEventAttendeeDAO btUpdatedattendee = helper.evntAttDAOMap.get(oldAttendee.Id);
        conference360__Attendee__c attendee = btUpdatedattendee.getAttendee();
        system.assertEquals('Registered', attendee.conference360__Registration_Status__c, 'Registration status not updated');
        
    }
    
    
    
    
    /*Description Test cancel Attendee group registration
     */
    
    @isTest
    static void testRegisteredToCanceledStatusChange(){
        Map<Id, conference360__Attendee__c> oldAttendeeMap = new Map<Id, conference360__Attendee__c>();
        Map<Id, conference360__Attendee__c> newAttendeeMap = new Map<Id, conference360__Attendee__c>();
        conference360__Attendee__c oldAttendee = [SELECT Id,conference360__Event__c,conference360__Attendee_Group__c,is_Primary_Registrant__c 
                                                  FROM conference360__Attendee__c 
                                                  Where is_Primary_Registrant__c = true
                                                  LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id,conference360__Event_Settings__c 
                                           FROM conference360__Event__c 
                                           Where Id =: oldAttendee.conference360__Event__c LIMIT 1];
        conference360__Event_Settings__c btEventSetting = [SELECT Id, Skip_Pending_for_Waitlisting__c, waitlist_registration_expiry__c
            											   FROM conference360__Event_Settings__c 
             											   WHERE Id =: btEvent.conference360__Event_Settings__c LIMIT 1];
        //btEventSetting.Skip_Pending_for_Waitlisting__c = false;
        //update btEventSetting;
        
        oldAttendee.conference360__Registration_Status__c = 'Registered';
        oldAttendeeMap.put(oldAttendee.Id, oldAttendee);
        conference360__Attendee__c newattendee = oldAttendee.clone(true);
        newattendee.conference360__Registration_Status__c = 'Canceled';
        newAttendeeMap.put(newattendee.Id,newattendee); 
        
        //when
        Test.startTest();
        
        BTAttendeeRegistrationStatusManager helper = new BTAttendeeRegistrationStatusManager(oldAttendeeMap, newAttendeeMap);
        helper.run();
        //then
        Test.stopTest();
        
        conference360__Attendee__c updatedAttendee = [SELECT id, conference360__Registration_Status__c FROM conference360__Attendee__c 
                                                      WHERE is_Primary_Registrant__c = false LIMIT 1];
        system.assertEquals('Canceled', updatedAttendee.conference360__Registration_Status__c, 'Registration status not updated');
    }

    /*Description Test if Attendee's Registration status is changed from Pending to Registered
     */
    @isTest
    static void testPendingToRegisteredStatusChange(){
    	Map<Id, conference360__Attendee__c> oldAttendeeMap = new Map<Id, conference360__Attendee__c>();
        Map<Id, conference360__Attendee__c> newAttendeeMap = new Map<Id, conference360__Attendee__c>();
        conference360__Attendee__c oldAttendee = [SELECT Id,conference360__Event__c,Registration_status_reason__c 
												  FROM conference360__Attendee__c LIMIT 1];
  
        oldAttendee.conference360__Registration_Status__c = 'Pending';
        oldAttendee.Registration_status_reason__c = 'Pending Waitlist Registration';
        oldAttendeeMap.put(oldAttendee.Id, oldAttendee);
        conference360__Attendee__c newattendee = oldAttendee.clone(true);
        //Attendee waitslist spot opens 
        newattendee.conference360__Registration_Status__c = 'Registered';
        newAttendeeMap.put(newattendee.Id,newattendee); 
        
        //when
        Test.startTest();
        
        BTAttendeeRegistrationStatusManager helper = new BTAttendeeRegistrationStatusManager(oldAttendeeMap, newAttendeeMap);
        helper.run();
        //then
        Test.stopTest();
        
        BTEventAttendeeDAO btUpdatedattendee = helper.evntAttDAOMap.get(oldAttendee.Id);
        conference360__Attendee__c attendee = btUpdatedattendee.getAttendee();
        System.assert(String.isBlank(attendee.Registration_status_reason__c), 'Registration status reason not updated');
        
    }
}