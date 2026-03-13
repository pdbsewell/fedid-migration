/**
 * @author  Shalini Mendu
 * @date 03 Dec 2019
 * @group Test Class
 * @description Covers the PerfectMatchingContactPayload class
 * @revision
 * 		17-08-2025	Sachin Shetty	Formatting updates
**/
@IsTest(isParallel=true)
public with sharing class PerfectMatchingContactPayload_Test {
    @IsTest
    static void testConstructorsAndAssignments() {
        // GIVEN - A new instance of the outer class
        PerfectMatchingContactPayload payload = new PerfectMatchingContactPayload();
        Assert.isNotNull(payload);

        // WHEN - Instantiate and assign values for Request wrapper
        PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest request =
            new PerfectMatchingContactPayload.PerfectMatchingContactPayloadRequest();
        request.sourceId = 'SRC123';
        request.firstName = 'John';
        request.lastName = 'Doe';
        request.salutation = 'Mr';
        request.gender = 'Male';
        request.previousStudentIndicator = true;
        request.previousMonashId = 'M12345';
        request.mailingStreet = '123 Main St';
        request.mailingCity = 'Melbourne';
        request.mailingCountry = 'Australia';
        request.mailingState = 'VIC';
        request.mailingPostalCode = '3000';
        request.homePhone = '0399998888';
        request.phone = '0388887777';
        request.residencyStatus = 'Citizen';
        request.hasDisabilities = false;
        request.mobilePhone = '0412345678';
        request.birthDate = '1990-01-01';
        request.email = 'john.doe@example.com';
        request.preferredName = 'Johnny';
        request.countryOfBirth = 'Australia';
        request.pronouns = 'He/Him';
        request.previousName = 'Jonathan';

        // THEN - Verify values
        Assert.areEqual('John', request.firstName);
        Assert.areEqual('0412345678', request.mobilePhone);
        Assert.areEqual('john.doe@example.com', request.email);

        // GIVEN - Response wrapper instantiation
        PerfectMatchingContactPayload.PerfectMatchingContactPayloadResponse response =
            new PerfectMatchingContactPayload.PerfectMatchingContactPayloadResponse();
        response.contactId = '003XXXXXXX';
        response.status = 'SUCCESS';
        response.error = null;

        // THEN
        Assert.areEqual('003XXXXXXX', response.contactId);
        Assert.areEqual('SUCCESS', response.status);

        // GIVEN - FindPerfectMatchContactRequest
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest findRequest =
            new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        findRequest.firstName = 'Jane';
        findRequest.lastName = 'Smith';
        findRequest.birthDate = '1985-05-05';
        findRequest.email = 'jane.smith@example.com';
        findRequest.mobilePhone = '0499998888';
        findRequest.previousMonashId = 'M54321';

        // THEN
        Assert.areEqual('Jane', findRequest.firstName);
        Assert.areEqual('M54321', findRequest.previousMonashId);

        // GIVEN - FindPerfectMatchContactResponse
        PerfectMatchingContactPayload.FindPerfectMatchContactResponse findResponse =
            new PerfectMatchingContactPayload.FindPerfectMatchContactResponse();
        findResponse.personId = 'P123';
        findResponse.unicrmContactId = 'U123';
        findResponse.crmId = 'C123';
        findResponse.applicantId = 'A123';
        findResponse.status = 'MATCH_FOUND';
        findResponse.errorMessage = null;
        findResponse.warningMessage = 'Multiple potential matches found';

        // THEN
        Assert.areEqual('MATCH_FOUND', findResponse.status);
        Assert.areEqual('Multiple potential matches found', findResponse.warningMessage);

        // COVERAGE - Reference static constants
        Assert.areEqual('ERROR: There are no matching contact record.', PerfectMatchingContactPayload.NO_MATCH);
        Assert.areEqual('ERROR: There are multiple matching contact records.', PerfectMatchingContactPayload.MULTIPLE_MATCH);
    }

}