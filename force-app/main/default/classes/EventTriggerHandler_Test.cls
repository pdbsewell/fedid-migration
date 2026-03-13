/**
@author Cartick Sub
@date 25 June 2020
@description Sibling test class for EventTriggerHandler
@revision Initial version dated 25 June 2020
**/

@isTest(isParallel=true)
public class EventTriggerHandler_Test {

    /**
    @description Inserts records required for test methods
    @revision Initial version 25 June 2020
    **/
    @testSetup
    static void addTestData(){
        
        Contact testContact = new Contact(
            LastName='Test'
        );
        insert testContact;

        Outbound_Call_Result__c testOutboundCall = new Outbound_Call_Result__c(
            Contact__c = testContact.Id,
            Event_Link_Status__c = 'Pending'
        );
        insert testOutboundCall;

        Event testEvent = new Event(
            RecordTypeId = EventServices.CALENDLY_RECTYPEID,
            WhoId = testContact.Id,
            DurationInMinutes = 60,
            ActivityDateTime = Datetime.newInstance(Date.today() - 2, Time.newInstance(12, 0, 0, 0))
        );
        insert testEvent;
     
    }
    
    /**
    @description Tests if an Event, after insert, is correctly linked to an Outbound Call and has its Event Status set to Assigned
    @revision Initial version 25 June 2020
    **/
    @isTest
    public static void validateLinkEventToOutboundCall() {

        Test.startTest();

        List<Event> listTestEvents = [SELECT WhatId, Event_Status__c FROM Event];
        Event testEvent = listTestEvents[0];

        List<Outbound_Call_Result__c> listOutboundCalls = [SELECT Id FROM Outbound_Call_Result__c];
        Outbound_Call_Result__c testOutboundCall = listOutboundCalls[0];

        Test.stopTest();

        System.assertEquals(testEvent.WhatId, testOutboundCall.Id, 'Event not correctly linked to Outbound Call');
        System.assertEquals('Assigned', testEvent.Event_Status__c, 'Event Status not set to \'Assigned\'');
    }

    /**
    @description Tests if an Event, after insert, results in the related Outbound Call being linked to the Event and
    the having its Event Link Status set to Session Booked.
    @revision Initial version 25 June 2020
    **/
    @isTest
    public static void validateUpdateOutboundCallOnEventInsert() {

        Test.startTest();

        List<Event> listTestEvents = [SELECT Id FROM Event];
        Event testEvent = listTestEvents[0];

        List<Outbound_Call_Result__c> listOutboundCalls = [SELECT Event_Link_Status__c, Event_Id__c FROM Outbound_Call_Result__c];
        Outbound_Call_Result__c testOutboundCall = listOutboundCalls[0];

        Test.stopTest();

        System.assertEquals('Session Booked', testOutboundCall.Event_Link_Status__c, 'Outbound Call Event Link Status not set to \'Session Booked\'');
        System.assertEquals(testEvent.Id, testOutboundCall.Event_Id__c, 'Outbound Call not correctly linked to Event');

    }

    /**
    @description Tests if an Event, after update of its Event Status to Cancelled, results in the related Outbound Call Event Link Status also being Cancelled
    @revision Initial version 25 June 2020
    **/
    @isTest
    public static void validateUpdateOutboundCallOnEventUpdate() {

        Test.startTest();

        List<Event> listTestEvents = [SELECT Id, Event_Status__c FROM Event];
        Event testEvent = listTestEvents[0];
        testEvent.Event_Status__c = 'Cancelled';
        update testEvent;

        List<Outbound_Call_Result__c> listOutboundCalls = [SELECT Event_Link_Status__c FROM Outbound_Call_Result__c];
        Outbound_Call_Result__c testOutboundCall = listOutboundCalls[0];

        Test.stopTest();

        System.assertEquals('Cancelled', testOutboundCall.Event_Link_Status__c, 'Outbound Call Event Link Status not set to \'Cancelled\'');

    }
}