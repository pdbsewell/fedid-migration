/**
 * @description Test class for RESTlib_ClientImplFactory. No functional tests
 * @author      Nick Guia
 * @date        MAY.05.2024
 * @group       RESTlib
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/623870739/Custom+REST+Framework+-+Abstract+Factory
 */
@isTest(isParallel=true)
private class RESTlib_ClientImplFactory_Test {

    private static String REQUEST_URI = '/RESTlib_ClientImplFactory_Test/*';

    private class SomeClientImplFactory extends RESTlib_ClientImplFactory { }

    private static void initRestContext() {

        RestRequest restReq = new RestRequest();
        restReq.requestURI = REQUEST_URI;

        RestResponse restResp = new RestResponse();

        RestContext.request = restReq;
        RestContext.response = restResp;
    }

    /**
     * @description initialise class and test that a Nebula log is created
     * since we did not write an implementation
     */
    @isTest
    static void shouldLogWarningWhenMethodsNotImplemented() {

        // GIVEN : a rest context and lazy init
        initRestContext();
        SomeClientImplFactory someClass;

        Test.startTest();

        // WHEN : I initialise and invoked the default methods
        someClass = new SomeClientImplFactory();
        someClass.getImplementation();
        someClass.getImplementationByCondition('any');
        Nebula.Logger.saveLog(); // manually save since the code didn't reach the handler

        Test.stopTest();

        // THEN : log warning since we invoked getImplementation() and getImplementationByCondition() without an implementation
        List<Nebula__LoggerTag__c> tagList = [SELECT Id, Nebula__UniqueId__c
                                    FROM Nebula__LoggerTag__c
                                    WHERE Nebula__UniqueId__c = :REQUEST_URI];
        Assert.isTrue(!tagList.isEmpty(), 'Unable to create a Nebulog Log with this specific tag');
    }
}