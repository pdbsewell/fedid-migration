/**
 * @description Test class for RESTlib_ClientFactoryUtility.
 *  For testing the fluent API only. the first part of the code is a light
 *  sample of an implementation in order to test that the factory utility class
 *  returns the right product
 * @author      Nick Guia
 * @date        MAY.05.2024
 * @group       RESTlib
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623837950/Custom+REST+Framework+-+Factory+Utility
 */
@isTest(isParallel=true)
private class RESTlib_ClientFactoryUtility_Test {

    private class SomeRequest extends RESTlib_Payload.Request { }

    private class SomeResponse extends RESTlib_Payload.Response { }

    /**
     * Sample implementation of the HTTP methods for a specific client.
     * In practice, their request and response payloads are different.
     * Simplifying in this test...
     */
    private class SomeClientHandleGet extends RESTlib_ClientImplHandler {

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

    private class SomeClientHandlePost extends RESTlib_ClientImplHandler {

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

    private class SomeClientHandlePut extends RESTlib_ClientImplHandler {

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

    private class SomeClientHandlePatch extends RESTlib_ClientImplHandler {

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

    // a sample implementation of ClientImpl
    private class SomeClientImpl implements RESTlib_IClientImpl {

        public RESTlib_ClientImplHandler getHandleGet() {
            return new SomeClientHandleGet();
        }

        public RESTlib_ClientImplHandler getHandlePost() {
            return new SomeClientHandlePost();
        }

        public RESTlib_ClientImplHandler getHandlePut() {
            return new SomeClientHandlePut();
        }

        public RESTlib_ClientImplHandler getHandlePatch() {
            return new SomeClientHandlePatch();
        }
    }
    // a sample implementation of SomeClientImplFactory
    private class SomeClientImplFactory extends RESTlib_ClientImplFactory {

        public override RESTlib_IClientImpl getImplementation() {
            return new SomeClientImpl();
        }

        public override RESTlib_IClientImpl getImplementationByCondition(Object condition) {
            RESTlib_IClientImpl impl;
            Boolean bCondition = (Boolean) condition;
            if(bCondition) {
                impl = new  SomeClientImpl();
            }
            return impl;
        }
    }

    // a sample implementation of IClientFactory
    private class SomeClientFactory implements RESTlib_IClientFactory {

        public RESTlib_ClientImplFactory getClientImplFactory() {
            return new SomeClientImplFactory();
        }
    }

    /**
     * @description test singleton
     */
    @isTest
    static void shouldGetInstance() {

        // GIVEN : lazy init
        RESTlib_ClientFactoryUtility util;

        Test.startTest();

        // WHEN : get instace
        util = RESTlib_ClientFactoryUtility.getInstance();

        Test.stopTest();

        // THEN : should not be null
        Assert.isNotNull(util, 'Unable to get instance');

    }

    /**
     * @description test that client factory persists
     */
    @isTest
    static void shouldSetSourceFactory() {

        // GIVEN : a util instance
        RESTlib_ClientFactoryUtility util = RESTlib_ClientFactoryUtility.getInstance();

        Test.startTest();

        // WHEN : i set client factory
        util.setSourceFactory(new SomeClientFactory());

        Test.stopTest();

        // THEN : private var should not be null
        Assert.isNotNull(util.cFactory, 'Unable to set client factory');

    }

    /**
     * @description test that implementation condition persists
     */
    @isTest
    static void shouldSetImplementationCondition() {

        // GIVEN : a util instance
        RESTlib_ClientFactoryUtility util = RESTlib_ClientFactoryUtility.getInstance();

        Test.startTest();

        // WHEN : i set an implementation condition
        util.setImplementationCondition(true); // any

        Test.stopTest();

        // THEN : private var should not be null
        Assert.isNotNull(util.implCondition, 'Unable to set implementation condition');
    }

    /**
     * @description test that getting an implementation without a condition
     * returns the expected result
     */
    @isTest
    static void shouldGetHandlerWithoutImplementationCondition() {

        // GIVEN : a client implementation handler as the expected output
        RESTlib_ClientImplHandler handler;

        Test.startTest();

        // WHEN : I get the handler instance without setting a condition
        handler = RESTlib_ClientFactoryUtility.getInstance()
                    .setSourceFactory(new SomeClientFactory())
                    .getHandleGet();

        Test.stopTest();

        // THEN : I should receive the Handle Get implementation
        Assert.isNotNull(handler, 'Unable to get the right handler');
        try {
            SomeClientHandleGet concrete = (SomeClientHandleGet) handler;
        } catch(Exception e) {
            Assert.fail('Returned an unexpected concrete class');
        }
    }

    /**
     * @description test that the utility class returns an instance of a handler.
     */
    @isTest
    static void shouldGetHandleGet() {

        // GIVEN : a client implementation handler as the expected output
        RESTlib_ClientImplHandler handler;

        Test.startTest();

        // WHEN : I get the handler instance
        handler = RESTlib_ClientFactoryUtility.getInstance()
                    .setSourceFactory(new SomeClientFactory())
                    .setImplementationCondition(true)
                    .getHandleGet();

        Test.stopTest();

        // THEN : I should receive the Handle Get implementation
        Assert.isNotNull(handler, 'Unable to get the right handler');
        try {
            SomeClientHandleGet concrete = (SomeClientHandleGet) handler;
        } catch(Exception e) {
            Assert.fail('Returned an unexpected concrete class');
        }
    }

    /**
     * @description test that the utility class returns an instance of a handler.
     */
    @isTest
    static void shouldGetHandlePost() {

        // GIVEN : a client implementation handler as the expected output
        RESTlib_ClientImplHandler handler;

        Test.startTest();

        // WHEN : I get the handler instance
        handler = RESTlib_ClientFactoryUtility.getInstance()
                    .setSourceFactory(new SomeClientFactory())
                    .setImplementationCondition(true)
                    .getHandlePost();

        Test.stopTest();

        // THEN : I should receive the Handle Post implementation
        Assert.isNotNull(handler, 'Unable to get the right handler');
        try {
            SomeClientHandlePost concrete = (SomeClientHandlePost) handler;
        } catch(Exception e) {
            Assert.fail('Returned an unexpected concrete class');
        }
    }

    /**
     * @description test that the utility class returns an instance of a handler.
     */
    @isTest
    static void shouldGetHandlePut() {

        // GIVEN : a client implementation handler as the expected output
        RESTlib_ClientImplHandler handler;

        Test.startTest();

        // WHEN : I get the handler instance
        handler = RESTlib_ClientFactoryUtility.getInstance()
                    .setSourceFactory(new SomeClientFactory())
                    .setImplementationCondition(true)
                    .getHandlePut();

        Test.stopTest();

        // THEN : I should receive the Handle Put implementation
        Assert.isNotNull(handler, 'Unable to get the right handler');
        try {
            SomeClientHandlePut concrete = (SomeClientHandlePut) handler;
        } catch(Exception e) {
            Assert.fail('Returned an unexpected concrete class');
        }
    }

    /**
     * @description test that the utility class returns an instance of a handler.
     */
    @isTest
    static void shouldGetHandlePatch() {

        // GIVEN : a client implementation handler as the expected output
        RESTlib_ClientImplHandler handler;

        Test.startTest();

        // WHEN : I get the handler instance
        handler = RESTlib_ClientFactoryUtility.getInstance()
                    .setSourceFactory(new SomeClientFactory())
                    .setImplementationCondition(true)
                    .getHandlePatch();

        Test.stopTest();

        // THEN : I should receive the Handle Patch implementation
        Assert.isNotNull(handler, 'Unable to get the right handler');
        try {
            SomeClientHandlePatch concrete = (SomeClientHandlePatch) handler;
        } catch(Exception e) {
            Assert.fail('Returned an unexpected concrete class');
        }
    }

    /**
     * @description test that the utility class returns an instance of a client implementation.
     */
    @isTest
    static void shouldGetClientImpl() {

        // GIVEN : an expected client implementation
        RESTlib_IClientImpl clientImpl;

        Test.startTest();

        // WHEN
        clientImpl = RESTlib_ClientFactoryUtility.getInstance()
                    .setSourceFactory(new SomeClientFactory())
                    .setImplementationCondition(true)
                    .getClientImpl();

        Test.stopTest();

        // THEN : I should receive a client implementation
        Assert.isNotNull(clientImpl, 'Unable to get the a client implementation');
        try {
            SomeClientImpl conClientImpl = (SomeClientImpl) clientImpl;
        } catch(Exception e) {
            Assert.fail('Returned an unexpected concrete class');
        }
    }

    /**
     * @description test that the utility class sets the payload of the handler
     */
    @isTest
    static void shouldSetPayload() {

        // GIVEN : a handler as the expected output
        RESTlib_ClientImplHandler handler;
        RESTlib_ClientFactoryUtility util = RESTlib_ClientFactoryUtility.getInstance();

        Test.startTest();

        // WHEN : I set the handler payload
        handler = util.setSourceFactory(new SomeClientFactory())
                    .setImplementationCondition(true)
                    .getHandleGet();
        handler = util.setPayload(handler);

        Test.stopTest();

        // THEN : the handler should store the payload type
        Assert.isNotNull(handler, 'Unable to get the right handler');
        Assert.isNotNull(handler.requestType, 'Unable to set handler payload');
        Assert.isNotNull(handler.responseType, 'Unable to set handler payload');
    }

    /**
     * @description test that the utility class resets the variables
     */
    @isTest
    static void shouldFlushVariables() {

        // GIVEN : a util instance with set variables
        RESTlib_ClientFactoryUtility util = RESTlib_ClientFactoryUtility.getInstance();
        util.setSourceFactory(new SomeClientFactory())
            .setImplementationCondition(true);

        Test.startTest();

        // WHEN : flush
        util.flush();

        Test.stopTest();

        // THEN : vars removed
        Assert.isNull(util.cFactory, 'Unable to flush variable');
        Assert.isNull(util.implCondition, 'Unable to flush variable');
    }
}