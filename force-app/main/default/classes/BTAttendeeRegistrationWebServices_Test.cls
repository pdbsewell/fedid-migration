/**
 * @author       : Ibrahim Rumi
 * @date         : 01-06-2022
 * @group        : Event Management
 * @description  : Class to Attendee registration Webservice
**/
@IsTest
public class BTAttendeeRegistrationWebServices_Test {

     /**
     * @description: Inserts records required for test methods
     */
    @testSetup
    static void setup(){

        //create Relationship Settings
        bt_stripe__Relationship_Settings__c relSetting = TestHelper.createBTRelationshipSetting();
        insert relSetting;
        
        //create event settings
        conference360__Event_Settings__c eventSettings = TestHelper.createEventSettings(1)[0];
            eventSettings.conference360__Relationship_Settings__c  = relSetting.id;
        insert eventSettings;
        
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(1);
        for(conference360__Event__c event:btEventList){
            event.conference360__Event_Settings__c = eventSettings.id;
        }
        insert btEventList;
        
        //create contact
        List<contact> conList = TestHelper.createProspectiveStudentContact(1);
        insert conList;
    }
    
    /*
     * @description: Tests successful registration of attendee via webservice
     */
    @isTest
    static void testAttendeeRegistration() {
        
        //given
    	List<conference360__Event__c> btEventList = [SELECT id FROM conference360__Event__c];
        
        List<contact> conList = [SELECT id FROM contact];
        
        BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest req = new BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest();
        
        req.contactId = conList[0].Id;
        req.eventId = btEventList[0].Id;
        req.registrationStatus = 'registered';
        
        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = rReq;
        
        BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse resp = new BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse();
        
        Test.startTest();
        
        //when
        resp = BTAttendeeRegistrationWebServices.handleAttendeeRegistration();
        Test.stopTest();

        //then
		List<conference360__Attendee__c> attList = [select id FROM conference360__Attendee__c WHERE conference360__Event__c =: btEventList[0].Id];
            
        System.assertEquals(resp.status, 'success');
        System.assertEquals(resp.contactId , conList[0].id, 'Attendee is not created');
    }
    
    /*
    * @description: Tests registration of attendee during incorrect payload
    */
    @isTest
    static void testNegativeAttendeeRegTest() {
        BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest req = new BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest();
        
        //given 
        req.contactId = 'test';
        req.eventId = 'test';
        req.registrationStatus = 'registered';
        
        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = rReq;
        
        BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse resp = new BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse();
        
        Test.startTest();
        
        //when
        resp = BTAttendeeRegistrationWebServices.handleAttendeeRegistration();
        Test.stopTest();
        
        //then
        System.assertEquals(resp.status, 'error');
        
    }
    
   	/*
    * @description: Tests validation of duplicate attendee registration via webservice
    */
    @isTest
    static void duplicateAttendeeTest(){
          
        //given
        conference360__Event_Settings__c eventSettings = [SELECT Id FROM conference360__Event_Settings__c LIMIT 1];
        eventSettings.Validate_Attendee_Registration__c = true;
        update eventSettings;
        
        List<conference360__Event__c> btEventList = [SELECT id FROM conference360__Event__c];
        
        List<contact> conList = [SELECT id FROM contact];
        
        conference360__Attendee__c newAttendee = new conference360__Attendee__c();
        newattendee.conference360__Event__c = btEventList[0].Id;
        newattendee.conference360__Contact__c = conList[0].Id;
        newattendee.conference360__Registration_Status__c = 'Registered';
        
        insert newattendee;
        
        BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest req = new BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest();
        
        req.contactId = conList[0].Id;
        req.eventId = btEventList[0].Id;
        req.registrationStatus = 'registered';
        
        RestRequest rReq = new RestRequest();
        rReq.httpMethod = 'POST';
        rReq.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = rReq;
        
        BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse resp = new BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse();
        
        Test.startTest();
        
        //when
        resp = BTAttendeeRegistrationWebServices.handleAttendeeRegistration();
        Test.stopTest();
    
        //then
        System.assertEquals(resp.status, 'error');
        
    }

}