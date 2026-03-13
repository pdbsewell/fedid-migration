/**
 * @author Trent De Laney
 * @date 16 Dec 2019 at 2:56:05 pm
 * @group Test Class
 * @description Covers the response message for the Comms submission to AP. 
 *              Needs to be covered line by line for Salesforce to pick up the coverage.
 * @revision
 * 	17-08-2025	Sachin Shetty	Formatting
 */
@IsTest
private class ObdAgentPortalCommsResponse_Test {

    /**
     * GIVEN the default constructor is used
     * WHEN an instance of ObdAgentPortalCommsResponse is created
     * THEN all fields should be null
     */
    @IsTest
    static void testDefaultConstructor() {
        // GIVEN + WHEN
        ObdAgentPortalCommsResponse response = new ObdAgentPortalCommsResponse();

        // THEN
        Assert.isNotNull(response, 'Response object should be instantiated');
        Assert.isNull(response.status, 'Default status should be null');
        Assert.isNull(response.enquiryRecordId, 'Default enquiryRecordId should be null');
        Assert.isNull(response.error, 'Default error should be null');
    }

    /**
     * GIVEN the overloaded constructor is used with values
     * WHEN an instance of ObdAgentPortalCommsResponse is created
     * THEN the fields should match the provided values
     */
    @IsTest
    static void testOverloadedConstructor() {
        // GIVEN
        String expectedStatus = 'Success';
        String expectedEnquiryRecordId = '12345';
        String expectedError = 'None';

        // WHEN
        ObdAgentPortalCommsResponse response = new ObdAgentPortalCommsResponse(expectedStatus, expectedEnquiryRecordId, expectedError);

        // THEN
        Assert.isNotNull(response, 'Response object should be instantiated');
        Assert.areEqual(expectedStatus, response.status, 'Status should match expected value');
        Assert.areEqual(expectedEnquiryRecordId, response.enquiryRecordId, 'EnquiryRecordId should match expected value');
        Assert.areEqual(expectedError, response.error, 'Error should match expected value');
    }
}