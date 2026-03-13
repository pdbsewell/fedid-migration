/**
 * @description Test class for RESTlib_ClientImplHandler. No functional tests
 * @author      Nick Guia
 * @date        MAY.05.2024
 * @group       RESTlib
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623870739/Custom+REST+Framework+-+Abstract+Factory
 */
@isTest(isParallel=true)
private class RESTlib_ClientImplHandler_Test {

    private class SomeRequest extends RESTlib_Payload.Request { }

    private class SomeResponse extends RESTlib_Payload.Response { }

    private class SomeClientImplHandler extends RESTlib_ClientImplHandler {

        public override Type getRequestType() {
            return SomeRequest.class;
        }

        public override Type getResponseType() {
            return SomeResponse.class;
        }

        // no implementation
        public override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            return new SomeResponse();
        }
    }

    /**
     * @description No functional tests
     */
    @istest
    static void shouldGetRequestType() {

        // GIVEN
        SomeClientImplHandler h;
        Type reqType;

        Test.startTest();

        // WHEN
        h = new SomeClientImplHandler();
        reqType = h.getRequestType();

        Test.stopTest();

        // THEN
        Assert.areEqual(SomeRequest.class, reqType, 'Unable to get Request Type');
    }

    /**
     * @description No functional tests
     */
    @istest
    static void shouldGetResponseType() {

        // GIVEN
        SomeClientImplHandler h;
        Type resType;

        Test.startTest();

        // WHEN
        h = new SomeClientImplHandler();
        resType = h.getResponseType();

        Test.stopTest();

        // THEN
        Assert.areEqual(SomeResponse.class, resType, 'Unable to get Response Type');
    }
}