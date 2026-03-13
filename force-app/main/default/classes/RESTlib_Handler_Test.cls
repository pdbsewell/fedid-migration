/**
 * @description Test class for RESTlib_Handler
 * @author      Nick Guia
 * @date        MAY.03.2024
 * @group       RESTlib
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/618633369/Custom+REST+Framework+-+Base+Handler
 */
@isTest(isParallel=true)
private class RESTlib_Handler_Test {

    private static final String VALIDATION_FAILED_ERROR_MSG = 'Invalid request!';
    private static final String SOME_SENSITIVE_DETAILS = 'some data';
    private static final String REQUEST_THAT_THROWS_CUSTOM_MESSAGE = 'some custom exception message';
    private static final String REQUEST_URI = '/RESTlib_Handler_Test/*';
    private static final String GENERIC_PLACEHOLDER_EXCEPTION_MESSAGE_FOR_MULTIPLE_ERRORS = 'Exceptions occurred';
    private static final String MULTIPLE_EXCEPTION_MSG_1 = 'Field 1 missing';
    private static final String MULTIPLE_EXCEPTION_MSG_2 = 'Field 2 missing';
    private static final String MULTIPLE_EXCEPTION_MSG_3 = 'Invalid date format for Field 3';

    /**
     * @description for testing the implementation of a POST request
     */
    public class HandlePost extends RESTlib_Handler {

        /**
         * @description implementation of the validate method
         * @param req base request object
         */
        public override void validate(RESTlib_Payload.Request req) {
            SimpleRequest sReq = (SimpleRequest) req;
            if(sReq.myRequest != 'some valid request' && sReq.myRequest != REQUEST_THAT_THROWS_CUSTOM_MESSAGE) {
                throw new RESTlib_Ex.InvalidRequestException(VALIDATION_FAILED_ERROR_MSG);
            }
        }
    
        /**
         * @description implementation of the process method
         * @param reqObj base request object
         * @param responseObj base response object
         * @return `RESTlib_Payload.Response`
         */
        public override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            SimpleRequest req = (SimpleRequest) reqObj;
            SimpleResponse resp = (SimpleResponse) responseObj;

            if(req.myRequest == REQUEST_THAT_THROWS_CUSTOM_MESSAGE) {
                throw new RESTlib_Ex.WebServiceException(REQUEST_THAT_THROWS_CUSTOM_MESSAGE);
            }

            resp.acknowledge = 'message received : ' + req.sendBack;
            return resp;
        }
    }

    /**
     * @description for testing the implementation of a GET request and throw an Exception
     */
    public class HandleGet extends RESTlib_Handler {

        final Exception mockException;

        /**
        * @description implementation of the constructor to allow mocking different type of exceptions.
        * @param e exception to mock, can be null.
        */
        public HandleGet(Exception e) {
            this.mockException = e;
        }

        /**
         * @description implementation of the process method
         * @param reqObj base request object
         * @param responseObj base response object
         * @return `RESTlib_Payload.Response`    
         */
        public override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            if(this.mockException == null) {
                throw new HandlerException(SOME_SENSITIVE_DETAILS);
            } else {
                throw this.mockException;
            }
        }
    }

    /**
     * @description for testing the implementation of a GET request and throw a list of Exception
     */
    public class HandlePut extends RESTlib_Handler {

        /**
         * @description implementation of the validate method - explicitly throw a list of exceptions
         * @param req base request object
         */
        public override void validate(RESTlib_Payload.Request req) {
            RESTlib_Ex.InvalidRequestException invalidRequest = new RESTlib_Ex.InvalidRequestException();
            invalidRequest.addException(new RESTlib_Ex.InvalidRequestException('Field 1 missing'));
            invalidRequest.addException(new RESTlib_Ex.InvalidRequestException('Field 2 missing'));
            invalidRequest.addException(new RESTlib_Ex.InvalidRequestException('Invalid date format for Field 3'));
            invalidRequest.setMessage(GENERIC_PLACEHOLDER_EXCEPTION_MESSAGE_FOR_MULTIPLE_ERRORS);
            throw invalidRequest;
        }
    
        /**
         * @description no implementation
         * @param reqObj base request object
         * @param responseObj base response object
         * @return `RESTlib_Payload.Response`
         */
        public override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            return responseObj;
        }
    }

    /**
     * @description a custom class to mock the System Exception and test the safety net catcher
     */
    public class HandlerException extends Exception { }

    /**
     * @description a simple valid request wrapper
     */
    public class SimpleRequest extends RESTlib_Payload.Request {
        public String sendBack = 'send this back to me';
        public String myRequest = 'some valid request';
    }
    /**
     * @description a simple valid response wrapper
     */
    public class SimpleResponse extends RESTlib_Payload.Response {
        public String acknowledge;
    }

    /**
     * @description A sample class that does not extend to the Base Request
     * to test that the handler class throws a TypeException
     */
    public class InvalidRequestType { }

    /**
     * @description A sample class that does not extend to the Base Response
     * to test that the handler class throws a TypeException
     */
    public class InvalidResponseType { }

    private static void initRestContext() {

        RestRequest restReq = new RestRequest();
        restReq.requestURI = REQUEST_URI;

        RestResponse restResp = new RestResponse();

        RestContext.request = restReq;
        RestContext.response = restResp;
    }

    /**
     * @description test that the handler class persists the payload types
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void handlerShouldSetPayload() {

        // GIVEN : a handler implementation
        HandlePost handler = new HandlePost();

        Test.startTest();

        // WHEN : I set the request and response class types
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);

        Test.stopTest();

        // THEN : the handler class should privately store them
        Assert.areEqual(SimpleRequest.class, handler.requestType, 'Unable to set request type properly');
        Assert.areEqual(SimpleResponse.class, handler.responseType, 'Unable to set response type properly');
    }

    /**
     * @description test that the Base Handler class sends the option to
     *  supress nulls in the JSON.serialize() method. This is a JSON class functionality
     *  so there's really no need to test the outcome, other than checking that the
     *  handler class privately stores the option.
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void handlerShouldSuppressNullsWithinTheJSON() {
        
        // GIVEN : a handler implementation
        HandlePost handler = new HandlePost();
        Boolean expectedValue = true;

        Test.startTest();

        // WHEN : I call the suppressNullsInResponse() method
        handler.suppressNullsInResponse(expectedValue);

        Test.stopTest();

        // THEN : the handler class should privately store it
        Assert.areEqual(expectedValue, handler.shouldSuppressNullsInResponse, 'Unable to suppress null values in the response');
    }

    /**
     * @description when the handler received an invalid request,
     * it should throw an InvalidRequestException
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void handlerShouldThrowAnInvalidRequestExceptionOnValidate() {

        // GIVEN : an invalid request
        SimpleRequest simpReq = new SimpleRequest();
        simpReq.myRequest = 'not the expected string';
        HandlePost handler = new HandlePost();

        
        Test.startTest();

        // WHEN : the handler validates the request
        try {
            handler.validate(simpReq);
            Assert.fail('Unable to throw an exception');
        } catch(RESTlib_Ex.InvalidRequestException e) {
            // THEN : the handler should throw an InvalidRequestException
            Assert.isTrue(true, 'Expected an ' + e.getTypeName());
        } catch(Exception e) {
            Assert.fail('Uncaught exception ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description the handler should set the expected response
     * in the rest context when no errors occur.
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void handlerShouldProcessRequest() {
        
        // GIVEN : a sample request
        initRestContext();
        SimpleRequest simpReq = new SimpleRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(simpReq));
        HandlePost handler = new HandlePost();
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);

        
        
        Test.startTest();

        // WHEN : the handler processes the request
        handler.execute();

        Test.stopTest();

        /**
         * THEN : 
         * - the expected response is as per below
         * - success is true
         * - no errors and error description
         */
        String expectedStr = 'message received : ' + simpReq.sendBack;

        String strResponse = RestContext.response.responseBody.toString();
        SimpleResponse objResponse = (SimpleResponse) JSON.deserialize(strResponse, SimpleResponse.class);
        Assert.areEqual(expectedStr, objResponse.acknowledge, 'Expected acknowledge to match');
        Assert.areEqual(true, objResponse.success, 'Expected success to be true');
        Assert.areEqual(null, objResponse.error, 'Expected error to be null');
        Assert.areEqual(null, objResponse.description, 'Expected description to be null');
    }

    /**
     * @description when the handler receives a payload request type that
     * does not extend to the Base Request type, it should throw an error.
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldReceiveGenericResponseWhenRequestTypeInvalid() {

        // GIVEN : an invalid request
        initRestContext();
        InvalidRequestType invReq = new InvalidRequestType();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(invReq));

        HandlePost handler = new HandlePost();
        handler.setPayloadType(InvalidRequestType.class, SimpleResponse.class);

        Test.startTest();

        // WHEN : I process an invalid request type
        handler.execute();

        Test.stopTest();

        // THEN : the response should have a generic response message and create a log
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(false, objResponse.success, 'Invalid response');
        Assert.areEqual('RESTlib_Ex.DeveloperException', objResponse.error, 'Invalid response');
        Assert.areEqual(RESTlib_Ex.EX_MSG_BASE_ERROR_RESPONSE, objResponse.description, 'Invalid response');
        List<Nebula__LoggerTag__c> tagList = [SELECT Id, Nebula__UniqueId__c
                                    FROM Nebula__LoggerTag__c
                                    WHERE Nebula__UniqueId__c = :REQUEST_URI];
        Assert.isTrue(!tagList.isEmpty(), 'Unable to create a Nebulog Log with this specific tag');
    }

    /**
     * @description when the handler receives a payload response type that
     * does not extend to the Base Response type, it should throw an error.
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldReceiveGenericResponseWhenResponseTypeInvalid() {

        // GIVEN : an invalid request
        initRestContext();
        SimpleRequest simpReq = new SimpleRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(simpReq));

        HandlePost handler = new HandlePost();
        handler.setPayloadType(SimpleRequest.class, InvalidRequestType.class);

        Test.startTest();

        // WHEN : I process an invalid response type
        handler.execute();

        Test.stopTest();

        // THEN : the response should have a generic response message and create a log
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(false, objResponse.success, 'Invalid response');
        Assert.areEqual('RESTlib_Ex.DeveloperException', objResponse.error, 'Invalid response');
        Assert.areEqual(RESTlib_Ex.EX_MSG_BASE_ERROR_RESPONSE, objResponse.description, 'Invalid response');
        List<Nebula__LoggerTag__c> tagList = [SELECT Id, Nebula__UniqueId__c
                                    FROM Nebula__LoggerTag__c
                                    WHERE Nebula__UniqueId__c = :REQUEST_URI];
        Assert.isTrue(!tagList.isEmpty(), 'Unable to create a Nebulog Log with this specific tag');
    }

    /**
     * @description when the request validation fails, the handler should
     * respond with the right error message about the validation error
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldReceiveInvalidRequestOnInvalidRequestException() {

        // GIVEN : A request that should fail the validation rules
        initRestContext();
        SimpleRequest reqWithInvalidParameters = new SimpleRequest();
        reqWithInvalidParameters.myRequest = 'wrong parameter';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(reqWithInvalidParameters));

        HandlePost handler = new HandlePost();
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);

        Test.startTest();

        // WHEN : I process an invalid request parameter
        handler.execute();

        Test.stopTest();

        // THEN : the response should have a helpful message and create a log
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(false, objResponse.success, 'Invalid response');
        Assert.areEqual('RESTlib_Ex.InvalidRequestException', objResponse.error, 'Invalid response');
        Assert.areEqual(VALIDATION_FAILED_ERROR_MSG, objResponse.description, 'Invalid response');
        List<Nebula__LoggerTag__c> tagList = [SELECT Id, Nebula__UniqueId__c
                                    FROM Nebula__LoggerTag__c
                                    WHERE Nebula__UniqueId__c = :REQUEST_URI];
        Assert.isTrue(!tagList.isEmpty(), 'Unable to create a Nebulog Log with this specific tag');
    }

    /**
     * @description When an unexpected error occurs, the handler catches
     *  the error with a System Exception. This exception may or may not contain
     *  sensitive information about the nature of the error, and we have to make sure
     *  that any sensitive details will not be passed back to the consumer.
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldReceiveGenericResponseOnSystemException() {

        // GIVEN : any request
        initRestContext();
        SimpleRequest anyRequest = new SimpleRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(anyRequest));
        
        HandleGet handler = new HandleGet(null);
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);

        Test.startTest();

        // WHEN : I process the request that is bound to fail
        handler.execute();

        Test.stopTest();

        // THEN : the handler should respond with a generic error message and hide sensitive details
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(false, objResponse.success, 'Invalid response');
        Assert.areEqual('RESTlib_Ex.WebServiceException', objResponse.error, 'Invalid response');
        Assert.areNotEqual(SOME_SENSITIVE_DETAILS, objResponse.description, 'Invalid response. Unable to hide sensitive details');
    }

    /**
     * @description When an unexpected error occurs, the handler catches
     *  the error with a System Exception. This exception may or may not contain
     *  sensitive information about the nature of the error, and we have to make sure
     *  that any sensitive details will not be passed back to the consumer.
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldReceiveGenericResponseOnDmlException() {

        // GIVEN : any request
        initRestContext();
        SimpleRequest anyRequest = new SimpleRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(anyRequest));
        DmlException mockException;
        try{
            insert new Account();
        } catch(DmlException e){
            mockException = e;
        }
        HandleGet handler = new HandleGet(mockException);
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);

        Test.startTest();

        // WHEN : I process the request that is bound to fail
        handler.execute();

        Test.stopTest();

        // THEN : the handler should respond with a DML error message and hide sensitive details
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(false, objResponse.success, 'Invalid response');
        Assert.areEqual('RESTlib_Ex.WebServiceException', objResponse.error, 'Invalid response');
        Assert.areNotEqual(mockException.getMessage(), objResponse.description, 'Invalid response. Unable to hide sensitive details');
    }

    /**
     * @description when an exception occurred during processing and was caught with a custom
     * exception message, then endpoint should respond with the custom message
     * to ensure that the error is actionable
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldReceiveCustomResponseWhenExceptionOcurredOnProcessing() {

        // GIVEN : a request that throws a custom exception message
        initRestContext();
        SimpleRequest someRequest = new SimpleRequest();
        someRequest.myRequest = REQUEST_THAT_THROWS_CUSTOM_MESSAGE;
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(someRequest));
        
        HandlePost handler = new HandlePost();
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);

        Test.startTest();

        // WHEN : I process the request that is bound to fail
        handler.execute();

        Test.stopTest();

        // THEN : the handler should respond with a custom error message and hide sensitive details
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(false, objResponse.success, 'Invalid response');
        Assert.areEqual('RESTlib_Ex.WebServiceException', objResponse.error, 'Invalid response');
        Assert.areEqual(REQUEST_THAT_THROWS_CUSTOM_MESSAGE, objResponse.description, 'Invalid response. Custom exception message was not sent');
    }

    /**
     * @description when multiple validation exceptions occur, all custom
     * exception messages must be sentback to the client for actionable feedbacks
     */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    @isTest
    static void shouldReceiveListOfExceptionsOnValidate() {

        // GIVEN : a request that throws a custom exception message
        initRestContext();
        SimpleRequest someRequest = new SimpleRequest();
        someRequest.myRequest = 'any';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(someRequest));
        
        HandlePut handler = new HandlePut();
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);

        Test.startTest();

        // WHEN : I process the request that is bound to fail
        handler.execute();

        Test.stopTest();

        // THEN : the handler should respond the list of custom validation messages
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(false, objResponse.success, 'Invalid response');
        Assert.areEqual('RESTlib_Ex.InvalidRequestException', objResponse.error, 'Invalid response');
        Assert.areEqual(GENERIC_PLACEHOLDER_EXCEPTION_MESSAGE_FOR_MULTIPLE_ERRORS, objResponse.description, 'Invalid response. Custom exception message was not sent');
        Assert.isTrue(objResponse.errorList != null, 'Invalid errorList for multiple exception messages');
        Assert.areEqual(MULTIPLE_EXCEPTION_MSG_1, objResponse.errorList[0].description, 'Unexpected error message');
        Assert.areEqual('RESTlib_Ex.InvalidRequestException', objResponse.errorList[0].error, 'Unexpected exception type');
        Assert.areEqual(MULTIPLE_EXCEPTION_MSG_2, objResponse.errorList[1].description, 'Unexpected error message');
        Assert.areEqual('RESTlib_Ex.InvalidRequestException', objResponse.errorList[1].error, 'Unexpected exception type');
        Assert.areEqual(MULTIPLE_EXCEPTION_MSG_3, objResponse.errorList[2].description, 'Unexpected error message');
        Assert.areEqual('RESTlib_Ex.InvalidRequestException', objResponse.errorList[2].error, 'Unexpected exception type');
    }
    @isTest
    static void testStatusCode(){
        initRestContext();
        SimpleRequest someRequest = new SimpleRequest();
        someRequest.myRequest = 'any';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(someRequest));
        
        HandlePut handler = new HandlePut();
        handler.setPayloadType(SimpleRequest.class, SimpleResponse.class);
        Test.startTest();

        // WHEN : I process the request that is bound to fail
        handler.execute();

        Test.stopTest();

        // THEN : the handler should respond the list of custom validation messages
        String strResponse = RestContext.response.responseBody.toString();
        RESTlib_Payload.Response objResponse = (RESTlib_Payload.Response) JSON.deserialize(strResponse, RESTlib_Payload.Response.class);
        Assert.areEqual(RESTLib_Constants.BAD_REQUEST, objResponse.statusCode, 'Incorrecnt status code');
        Assert.areEqual(false, objResponse.success, 'Invalid response');
    }


}