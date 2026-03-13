/**
* @author Ibrahim Rumi
* @date 11-05-2021
* @description Sibling test class for BTEventAttendeeDAOHelper
*   17.01.2022  Ibrahim Rumi    - EPBBS-2379 test GetExistingContactsforEvents method to fetch all attendees in an event
**/
@isTest(isParallel=true)
public class BTEventAttendeeDAOHelper_Test {

    @TestSetup
    static void makeData(){
		
        //create an event setting
        //create event settings
        conference360__Event_Settings__c btEventSettings = TestHelper.createEventSettings(1)[0];
            btEventSettings.waitlist_registration_expiry__c = 4.0;
        insert btEventSettings;
        
        //create an event
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.conference360__Event_Settings__c = btEventSettings.id;
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        insert btEvent;

        //create an attendee
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendeeWithMatchingContacts(btEvent.id, 1)[0];
        insert attendee;
    }
    
    /**
     * @description collect attendee details and store it within helper class 
    */
    @isTest
    static void generateEventAttendeeDAO_Test(){
        List<conference360__Attendee__c> attlist = [Select id, conference360__Event__c from conference360__Attendee__c limit 1];
        
        Test.startTest();

        //when
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
        helper.generateEventAttendeeDAO();
        
        Test.stopTest();
        
        //then
        System.assert(!helper.attendeList.isEmpty(), 'Unable to collect form submission details');
        System.assert(!helper.eventMap.isEmpty(), 'Unable to collect form submission details');
        System.assert(!helper.eventSettingMap.isEmpty(), 'Unable to collect form submission details');
        
    }

    
    /**
     * @description test query event records
     */
    @isTest
    static void shouldSelectEvents() {

        //given
        List<conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c FROM conference360__Attendee__c LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
        helper.eventIdSet.add(btEvent.Id);

        Test.startTest();

        //when
        helper.selectEvents();

        Test.stopTest();

        //then
        System.assert(!helper.eventMap.isEmpty(), 'Unable to query Event records');
        System.assert(!helper.eventsByEventSettingIds.isEmpty(), 'Unable to query corresponding Event Setting');
        
    }
    
    /**
     * @description test query eventSetting records
     */
    @isTest
    static void shouldSelectEventSetting() {

        //given
        List<conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c FROM conference360__Attendee__c LIMIT 1];
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        conference360__Event_Settings__c btEventSetting = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
        helper.eventsByEventSettingIds.put(btEvent.Id, btEventSetting.Id);

        Test.startTest();

        //when
        helper.selectEventSettings();

        Test.stopTest();

        //then
        System.assert(!helper.eventSettingMap.isEmpty(), 'Unable to query EventSetting records');
        
    }
    
    /**
     * @description test event attendee gen
     */
    @isTest
    static void EventAttendeeGen_Test() {
		List<BTEventAttendeeDAO> eventAttendeeDAOList = new List<BTEventAttendeeDAO>();
        
        //given
        List <conference360__Attendee__c> attlist = [SELECT Id,conference360__Event__c FROM conference360__Attendee__c LIMIT 1];
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);

        Test.startTest();
		
        //when
        eventAttendeeDAOList = helper.generateEventAttendeeDAO();

        Test.stopTest();

        //then
        System.assert(!eventAttendeeDAOList.isEmpty(), 'eventAttendeeDAOList is not generated');        
        
    }    
        
    /**
     * @description test if eventAttendeeDAO is collected as a map 
    */
    @isTest
    static void generateEventAttendeeDAOMap_Test(){
        Map<Id, BTEventAttendeeDAO> eventAttendeeDAOMap = new Map<Id, BTEventAttendeeDAO>();
        List<conference360__Attendee__c> attlist = [Select id, conference360__Event__c from conference360__Attendee__c limit 1];
        
        Test.startTest();

        //when
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
        eventAttendeeDAOMap = helper.generateEventAttendeeDAOMap();
        
        Test.stopTest();
        
        //then
        System.assert(!eventAttendeeDAOMap.isEmpty(), 'eventAttendeeDAOMap is not generated');
        
    }
    
    /**
     * @description test by passing null attendee list
    */
    @isTest
    static void EventAttendeeDAOHelperException_Test(){
        List <conference360__Attendee__c> attlist = new List<conference360__Attendee__c>();
        String Message;
        Test.startTest();
        Try{
        //when
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
        } catch(Exception e){
            Message = e.getMessage();
        }
        Test.stopTest();
        
        //then
        system.assertEquals(Message, 'Invalid null or empty parameter','unknown exception');
        
    }
    
    /*
     * description test fetching attendees for an event
     */
    @isTest
    static void GetExistingContactsforEvents_Test(){
        Map<Id, Set<Id>> attendeeMap = new Map<Id, Set<Id>>();
        conference360__Event__c btEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        List<conference360__Attendee__c> attlist = [SELECT id, conference360__Event__c,conference360__Registration_Status__c 
                                                    FROM conference360__Attendee__c 
                                                    WHERE conference360__Event__c =: btEvent.Id];
        for(conference360__Attendee__c att: attlist){
            att.conference360__Registration_Status__c = BTAttendeeServices.REG_STATUS_REGISTERED;
        }
        update attlist;
        
        Test.startTest();

        //when
        BTEventAttendeeDAOHelper helper = new BTEventAttendeeDAOHelper(attlist);
        attendeeMap = helper.getExistingRegisteredContactsforEvents();
        
        Test.stopTest();
        
        //then
        System.assert(!attendeeMap.isEmpty(), 'attendeeMap is not generated');
    }
    
}