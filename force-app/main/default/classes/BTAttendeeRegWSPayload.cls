/**
 * @author       : Ibrahim Rumi
 * @date         : 01-06-2022
 * @group        : Event Management
 * @description  : payload class for BTAttendeeRegWebservices
 * @revision
 * 		17-08-2025	Sachin Shetty	Added Constructor
**/
global class BTAttendeeRegWSPayload {

    global class AttendeeRegistrationPayloadRequest {
        global String contactId;
        global String eventId;
        global String registrationStatus;

        // Default constructor
        global AttendeeRegistrationPayloadRequest() {} //NOPMD
    }

    global class AttendeeWebServicesPayloadResponse {
        global String ContactId;
        global String AttendeeId;
        global String attendeelink;
        global String status;
        global String error;

        // Default constructor
        global AttendeeWebServicesPayloadResponse() {} //NOPMD
    }
}