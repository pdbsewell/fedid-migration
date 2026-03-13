/*******************************************************************************
 * @author       Shalini mendu
 * @date         02 Dec 2019
 * @group        Wrapper class
 * @description  SFTN-364-CRM Applications from channels: Match Duplicate-Wrapper class to capture payloads to support Perfect Matching Contact Rest Web service
 * @revision
*		2025-17-08	-	Sachin Shetty	-	Added Constructor
 *******************************************************************************/

global class PerfectMatchingContactPayload {
    public static final String NO_MATCH = 'ERROR: There are no matching contact record.';
    public static final String MULTIPLE_MATCH = 'ERROR: There are multiple matching contact records.';

    // Default constructor
    global PerfectMatchingContactPayload(){} //NOPMD
    
    //Payload Request wrapper for the webservice
    global class PerfectMatchingContactPayloadRequest
    {
        global String sourceId;
        global String firstName;
        global String lastName;
        global String salutation;
        global String gender;
        global Boolean previousStudentIndicator;
        global String previousMonashId;
        global String mailingStreet;
        global String mailingCity;
        global String mailingCountry;
        global String mailingState;
        global String mailingPostalCode;
        global String homePhone;
        global String phone;
        global String residencyStatus;
        global Boolean hasDisabilities;
        global String mobilePhone;
        global String birthDate;
        global String email;
        //new mapping fields on Contact
        global String preferredName;
        global String countryOfBirth;
        global String pronouns;
        global String previousName;
        
        // Default constructor
        global PerfectMatchingContactPayloadRequest(){} //NOPMD

    }

    //Payload Response wrapper for the webservice
    global class PerfectMatchingContactPayloadResponse
    {
        global String contactId;
        global String status;
        global String error;
        
        // Default constructor
        global PerfectMatchingContactPayloadResponse(){} //NOPMD
    }

    //Payload Request wrapper for the webservice
    global class FindPerfectMatchContactRequest {
        global String firstName;
        global String lastName;
        global String birthDate;
        global String email;
        global String mobilePhone;
        global String previousMonashId;
        
        // Default constructor
        global FindPerfectMatchContactRequest(){} //NOPMD
    }

    //Payload Response wrapper for the webservice
    global class FindPerfectMatchContactResponse {
        global String personId;
        global String unicrmContactId;
        global String crmId;
        global String applicantId;

        global String status;
        global String errorMessage;
        global String warningMessage;
        
        // Default constructor
        global FindPerfectMatchContactResponse(){} //NOPMD
    }
}