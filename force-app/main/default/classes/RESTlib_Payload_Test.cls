/**
 * @description Test class for RESTlib_Payload. No functional tests
 * @author      Nick Guia
 * @date        MAY.05.2024
 * @group       RESTlib
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/618633369/Custom+REST+Framework+-+Base+Handler
 */
@isTest(isParallel=true)
private class RESTlib_Payload_Test {

    @SuppressWarnings('PMD.ApexDoc')
    public class SomeRequest extends RESTlib_Payload.Request { }

    @SuppressWarnings('PMD.ApexDoc')
    public class SomeResponse extends RESTlib_Payload.Response { }

    /**
     * @description no testing since this class is marker only
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldInitRequest() {

        // GIVEN : any request
        SomeRequest req;

        Test.startTest();

        // WHEN : init
        req = new SomeRequest();

        Test.stopTest();

        // THEN : not null
        Assert.isNotNull(req, 'Unable to initialise request');
    }

    /**
     * @description test getters and setters only
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldInitResponse() {

        // GIVEN : any response
        SomeResponse res;

        Test.startTest();

        // WHEN : init
        res = new SomeResponse();
        res.success = false;
        res.description = 'some message';
        res.error = 'SomeExceptionType';

        RESTlib_Payload.ErrorResponse objError = new RESTlib_Payload.ErrorResponse();
        objError.description = 'error message 1';
        objError.error = 'SomeExceptionType';
        res.errorList = new List<RESTlib_Payload.ErrorResponse>{ objError };

        Test.stopTest();

        // THEN : properties should be set
        Assert.areEqual(false, res.success, 'Unable to set payload property');
        Assert.areEqual('some message', res.description, 'Unable to set payload property');
        Assert.areEqual('SomeExceptionType', res.error, 'Unable to set payload property');
        Assert.isNotNull(res.errorList, 'Unable to set payload property');
        Assert.areEqual(1, res.errorList.size(), 'Unexpected number of Exceptions');
    }
}