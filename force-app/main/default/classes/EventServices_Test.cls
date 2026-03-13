/**
@author Cartick Sub
@date 25 June 2020
@description Sibling test class for EventServices
@revision Initial version dated 25 June 2020
**/

@isTest(isParallel=true)
public class EventServices_Test {

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

        Event testEvent = new Event(
            RecordTypeId = EventServices.CALENDLY_RECTYPEID,
            WhoId = testContact.Id,
            DurationInMinutes = 60,
            ActivityDateTime = Datetime.newInstance(Date.today() - 2, Time.newInstance(12, 0, 0, 0))
        );
        insert testEvent;

        List<Outbound_Call_Result__c> listTestOutboundCalls = new List<Outbound_Call_Result__c>();

        Outbound_Call_Result__c testPendingOutboundCall = new Outbound_Call_Result__c(
            Contact__c = testContact.Id,
            Event_Id__c = testEvent.Id,
            Event_Link_Status__c = 'Pending'
        );
        listTestOutboundCalls.add(testPendingOutboundCall);

        Outbound_Call_Result__c testCancelledOutboundCall = new Outbound_Call_Result__c(
            Contact__c = testContact.Id,
            Event_Id__c = testEvent.Id,
            Event_Link_Status__c = 'Cancelled'
        );
        listTestOutboundCalls.add(testCancelledOutboundCall);

        insert listTestOutboundCalls;          
    }
    
    /**
    @description Tests retrieval of the Calendly record type Id
    @revision Initial version 25 June 2020
    **/
    @isTest
    public static void validateGetCalendlyRecordTypeId() {

        Test.startTest();
        Id calendlyRecordTypeId = EventServices.CALENDLY_RECTYPEID;
        Test.stopTest();

        System.assert(calendlyRecordTypeId != null, 'Calendly Record Type Id not retrieved');
    }

    /**
    @description Tests if the getOCRS method retrieves the expected Outbound Calls
    @revision Initial version 25 June 2020
    **/
    @isTest
    public static void validateGetOCRs() {

        Test.startTest();

        List<Outbound_Call_Result__c> listPendingOutboundCallsFromDB = [SELECT Id FROM Outbound_Call_Result__c WHERE Event_Link_Status__c = 'Pending'];
        List<Outbound_Call_Result__c> listCancelledOutboundCallsFromDB = [SELECT Id FROM Outbound_Call_Result__c WHERE Event_Link_Status__c = 'Cancelled'];

        List<Outbound_Call_Result__c> listPendingOutboundCallsFromGetOCRs = new List<Outbound_Call_Result__c>();
        List<Outbound_Call_Result__c> listCancelledOutboundCallsFromGetOCRs = new List<Outbound_Call_Result__c>();

        EventServices.getOCRs(listPendingOutboundCallsFromGetOCRs, 'Pending', new Set<Id>{listPendingOutboundCallsFromDB[0].Id});
        EventServices.getOCRs(listCancelledOutboundCallsFromGetOCRs, 'Cancelled', new Set<Id>{listCancelledOutboundCallsFromDB[0].Id});

        Test.stopTest();

        System.assertEquals(1, listPendingOutboundCallsFromGetOCRs.size(), 'Did not return correct number of Pending Outbound Calls');
        System.assertEquals(1, listCancelledOutboundCallsFromGetOCRs.size(), 'Did not return correct number of Cancelled Outbound Calls');

    }

     /**
    @description Tests if the retrieveOutboundCalls method retrieves the expected Outbound Calls
    @revision Initial version 25 June 2020
    **/
    @isTest
    public static void validateRetrieveOutboundCalls() {

        Test.startTest();

        List<Outbound_Call_Result__c> listPendingOutboundCallsFromDB = [SELECT Id, Contact__c FROM Outbound_Call_Result__c WHERE Event_Link_Status__c = 'Pending'];
        List<Outbound_Call_Result__c> listCancelledOutboundCallsFromDB = [SELECT Id, Contact__c FROM Outbound_Call_Result__c WHERE Event_Link_Status__c = 'Cancelled'];

        Map<Id,Outbound_Call_Result__c> mapPendingOutboundCalls = new Map<Id,Outbound_Call_Result__c>();
        Map<Id,Outbound_Call_Result__c> mapCancelledOutboundCalls = new Map<Id,Outbound_Call_Result__c>();

        EventServices.retrieveOutboundCalls(mapPendingOutboundCalls, 'Pending', new Set<Id>{listPendingOutboundCallsFromDB[0].Contact__c});
        EventServices.retrieveOutboundCalls(mapCancelledOutboundCalls, 'Cancelled', new Set<Id>{listCancelledOutboundCallsFromDB[0].Contact__c});

        Test.stopTest();

        System.assertEquals(1, mapPendingOutboundCalls.size(), 'Did not return correct number of Pending Outbound Calls');
        System.assertEquals(1, mapCancelledOutboundCalls.size(), 'Did not return correct number of Cancelled Outbound Calls');

    }
}