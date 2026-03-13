/**
 * @description Test class for RESTlib_Ex. No functional tests
 * @author      Nick Guia
 * @date        MAY.05.2024
 * @group       RESTlib
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/618633369/Custom+REST+Framework+-+Base+Handler
 */
@isTest(isParallel=true)
private class RESTlib_Ex_Test {

    /**
     * @description Test adding a list of custom exception messages
     * within a parent placeholder exception
     */
    
    @isTest
    static void shouldCreateListInvalidRequestException() {

        // GIVEN : any request
        RESTlib_Ex.InvalidRequestException ex;
        String topLevelErrorMessage = 'A descriptive top-level error message';
        String error1 = 'Field 1 missing';
        String error2 = 'Field 2 missing';
        String error3 = 'Invalid date format for Field 3';

        Test.startTest();

        // WHEN : init
        ex = new RESTlib_Ex.InvalidRequestException(topLevelErrorMessage);
        ex.addException(new RESTlib_Ex.InvalidRequestException(error1));
        ex.addException(new RESTlib_Ex.InvalidRequestException(error2));
        ex.addException(new RESTlib_Ex.InvalidRequestException(error3));

        Test.stopTest();

        // THEN : validation exception messages.
        Assert.areEqual(topLevelErrorMessage, ex.getMessage(), 'Unexpected exception message');
        Assert.areEqual(error1, ex.getExceptions()[0].getMessage(), 'Unexpected exception message');
        Assert.areEqual(error2, ex.getExceptions()[1].getMessage(), 'Unexpected exception message');
        Assert.areEqual(error3, ex.getExceptions()[2].getMessage(), 'Unexpected exception message');
        Assert.areEqual(RESTLib_Constants.BAD_REQUEST , ex.statusCode, 'Incorrect status code');
        Assert.isTrue(ex.message.contains('Field 1 missing, Field 2 missing, Invalid date format for Field 3'), 'Exception message should contain appended messages');
    }

    /**
     * @description No functional tests
     */
    
    @isTest
    static void shouldInitialise() {

        // GIVEN : main class
        RESTlib_Ex ex;
        String msg;

        Test.startTest();

        // WHEN : init
        ex = new RESTlib_Ex();
        msg = RESTlib_Ex.EX_MSG_BASE_ERROR_RESPONSE;

        Test.stopTest();

        // THEN : not null
        Assert.isNotNull(ex, 'Unable to initialise main class');
        Assert.isNotNull(msg, 'Unable to get base message');
    }

    /**
     * @description No functional tests
     */
    
    @isTest
    static void shouldCreateInvalidRequestException() {

        // GIVEN : any request
        RESTlib_Ex.InvalidRequestException ex;

        Test.startTest();

        // WHEN : init
        ex = new RESTlib_Ex.InvalidRequestException('some message');

        Test.stopTest();

        // THEN : not null
        Assert.isNotNull(ex, 'Unable to initialise custom exception');
        Assert.areEqual(RESTLib_Constants.BAD_REQUEST , ex.statusCode, 'Incorrect status code');
    }

    /**
     * @description No functional tests
     */
    
    @isTest
    static void shouldCreateDeveloperException() {

        // GIVEN : any request
        RESTlib_Ex.DeveloperException ex;

        Test.startTest();

        // WHEN : init
        ex = new RESTlib_Ex.DeveloperException('some message');

        Test.stopTest();

        // THEN : not null
        Assert.isNotNull(ex, 'Unable to initialise custom exception');
    }

    /**
     * @description No functional tests
     */
    
    @isTest
    static void shouldCreateWebServiceException() {

        // GIVEN : any request
        RESTlib_Ex.WebServiceException ex;

        Test.startTest();

        // WHEN : init
        ex = new RESTlib_Ex.WebServiceException('some message');

        Test.stopTest();

        // THEN : not null
        Assert.isNotNull(ex, 'Unable to initialise custom exception');
        Assert.areEqual(RESTLib_Constants.INTERNAL_SERVER_ERROR , ex.statusCode, 'Incorrect status code');
    }
      /**
     * @description No functional tests
     */
    
     @isTest
     static void shouldCreateNotFoundException() {
 
         // GIVEN : any request
         RESTlib_Ex.NotFoundException ex;
 
         Test.startTest();
 
         // WHEN : init
         ex = new RESTlib_Ex.NotFoundException('some message');
 
         Test.stopTest();
 
         // THEN : not null
         Assert.isNotNull(ex, 'Unable to initialise custom exception');
         Assert.areEqual(RESTLib_Constants.NOT_FOUND , ex.statusCode, 'Incorrect status code');
     }
    @istest
    private static void addExceptionTest() {
        // GIVEN : any request
        RESTlib_Ex.ListException exlib = new RESTlib_Ex.ListException();
        List<RESTlib_Ex.ListException> ex = new List<RESTlib_Ex.ListException>();
        Test.startTest();
        //WHEN : an exception is added
        ex.add(new RESTlib_Ex.ListException('some message'));
        exlib.addException(ex);
        Test.stopTest();
        //THEN exception size should be 1
        Assert.areEqual(1, ex.size(), 'No error exception found');
        //Assert.fail(JSON.serializePretty(exlib));
        Assert.isTrue(exlib.getListExceptionSummaryString().contains('some message'), 'Incorrect message value');
    }
}