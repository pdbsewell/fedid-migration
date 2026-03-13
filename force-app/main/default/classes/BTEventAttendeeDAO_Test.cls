/**
* @author Nick Guia
* @date 01.02.2021
* @group Event Management
* @description Test class for BTEventAttendeeDAO
* @revision 
*   11.05.2021  Ibrahim Rumi    - EPBBS-1888 added method shouldReturnGetWithEventSettings to handle getter of event settings
*/
@isTest(isParallel=true)
private class BTEventAttendeeDAO_Test {

    /**
     * @description test getter methods
     */
    @isTest
    static void shouldReturnGet() {
        
        //given
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(null, 1)[0];
        BTEventAttendeeDAO dao;

        conference360__Event__c daoEvent;
        conference360__Attendee__c daoAttendee;
        String daoAffiliation;

        Test.startTest();

        //when
        dao = new BTEventAttendeeDAO(btEvent, attendee);
        daoEvent = dao.getEvent();
        daoAttendee = dao.getAttendee();

        Test.stopTest();

        //then
        System.assert(daoEvent != null, 'Unable to get Event from DAO class');
        System.assert(daoEvent != null, 'Unable to get Attendee from DAO class');
    }

    /**
     * @description test getter methods to handle getter of event settings 
     */
    @isTest
    static void shouldReturnGetWithEventSettings() {
        //given
        conference360__Event__c btEvent = TestHelper.createBlackthornEvents(1)[0];
        btEvent.Audience_Type__c = BTAudienceTypeAnalyser.EVENT_AUDIENCE_PROSPECTIVE_STUDENT;
        conference360__Attendee__c attendee = TestHelper.createBlackthornAttendee(null, 1)[0];
        conference360__Event_Settings__c btEventSetting = new conference360__Event_Settings__c(
        	Name = 'BT_Test_event_settings'
        );
        BTEventAttendeeDAO dao;

        conference360__Event__c daoEvent;
        conference360__Attendee__c daoAttendee;
        conference360__Event_Settings__c daoEventSetting;

        Test.startTest();

        //when
        dao = new BTEventAttendeeDAO(btEvent, attendee,btEventSetting);
        daoEvent = dao.getEvent();
        daoAttendee = dao.getAttendee();
        daoEventSetting = dao.getEventSetting();

        Test.stopTest();

        //then
        System.assert(daoEvent != null, 'Unable to get Event from DAO class');
        System.assert(daoAttendee != null, 'Unable to get Attendee from DAO class');
        System.assert(daoEventSetting != null, 'Unable to get Event Settings from DAO class');
    }    
}