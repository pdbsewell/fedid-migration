/**
 * @description Test class for APNG_WebServicePayload.
 *              The class is not meant to have any code logic aside from wrapper classes,
 *              therefore, no functional test will happen here
 * @author      Nick Guia
 * @date        27/09/2023
 * @group       Admissions
 * @see         https://monash-esol.atlassian.net/wiki/spaces/EPOM/pages/328925218/APNG+-+Enquiry+Management+LLD
 */
@isTest(isParallel=true)
private class APNG_WebServicePayload_Test {

    // no actual testing as per header
    @isTest
    static void shouldCreateEnquiryGetResponse() {

        // GIVEN : Enquiry WS GET Response Payload
        APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse response;

        Test.startTest();

        // WHEN : the payload is created
        response = new APNG_WebServicePayload.APNG_EnquiryWebService_GetResponse();
        response.enquiryDetails = new Case();
        response.success = false;
        response.description = 'Exception stacktrace string here';
        response.error = 'error message here';

        Test.stopTest();

        // THEN : the following values should be true
        Assert.isNotNull(response.enquiryDetails, 'Unable to set response property');
        Assert.isNotNull(response.caseFeedList, 'Unable to set response property');
        Assert.isNotNull(response.success, 'Unable to set response property');
        Assert.isNotNull(response.description, 'Unable to set response property');
        Assert.isNotNull(response.error, 'Unable to set response property');
    }

    // no actual testing as per header
    @isTest
    static void shouldCreateAgentManagementGetResponse() {

        // GIVEN : Agent Management WS GET Response Payload
        APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse response;

        Test.startTest();

        // WHEN : the payload is created
        response = new APNG_WebServicePayload.APNG_AgentManagementWebService_GetResponse();
        response.userRecord = new User();
        response.userLoginList = new List<UserLogin>();
        response.contactRecord = new Contact();
        response.accountRecord = new Account();
        response.accountPartnerList = new List<AccountPartner>();

        Test.stopTest();

        // THEN : the following values should be true
        Assert.isNotNull(response.userRecord, 'Unable to set response property');
        Assert.isNotNull(response.userLoginList, 'Unable to set response property');
        Assert.isNotNull(response.contactRecord, 'Unable to set response property');
        Assert.isNotNull(response.accountRecord, 'Unable to set response property');
        Assert.isNotNull(response.accountPartnerList, 'Unable to set response property');
    }
}