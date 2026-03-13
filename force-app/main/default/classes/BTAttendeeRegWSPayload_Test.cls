/**
 * @author       : Ibrahim Rumi
 * @date         : 01-06-2022
 * @group        : Event Management
 * @description  : Class to test BTAttendeeRegWSPayload
 * @revision
 * 		17-08-2025	Sachin Shetty	Formatting
**/
@IsTest(isParallel=true)
public with sharing class BTAttendeeRegWSPayload_Test {
    @IsTest
    public static void test_AssignPropertyValuesReq(){
        
        Test.startTest();
        
        BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest req = new BTAttendeeRegWSPayload.AttendeeRegistrationPayloadRequest();
            
            req.contactId = fflib_IDGenerator.generate(Contact.SObjectType);
            req.eventId = fflib_IDGenerator.generate(conference360__Event__c.SObjectType);
            req.registrationStatus = 'registered';
        
        Test.stopTest();
        Assert.isNotNull(req);
    }
    
    @IsTest
    public static void test_AssignPropertyValuesRes(){
        Test.startTest();
            
        BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse res = new BTAttendeeRegWSPayload.AttendeeWebServicesPayloadResponse();
            
            res.contactId = fflib_IDGenerator.generate(Contact.SObjectType);
            res.attendeeId = fflib_IDGenerator.generate(conference360__Attendee__c.SObjectType);
            res.attendeelink = fflib_IDGenerator.generate(conference360__Attendee__c.SObjectType);
            res.status = 'success';
            res.error = 'false';
        
        Test.stopTest();
        Assert.isNotNull(res);
    }
}