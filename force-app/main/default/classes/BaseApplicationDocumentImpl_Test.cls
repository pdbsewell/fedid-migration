/**
 * @description Test class to cover BaseApplicationDocumentImpl
 * @author      Kai-Fan Hsieh
 * @since       28 June 2024
 */
@isTest(isParallel=true)
public class BaseApplicationDocumentImpl_Test {

    /**
     * @description Sets up test data including a Contact, Application for testing.
     */
    @TestSetup
    private static void setupData() {
        //Create a new Contact for testing
        Contact testContact = StudFirst_TestHelper.createApplicant();
        testContact.Citizenship__c = MyApplicationUtilities.DOMESTIC;
        testContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId();
        Date dtToday = Date.today();
        testContact.Birthdate = dtToday.addYears(-20);
        insert testContact;
        // create application for contact
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        testApplication.Fee_Payment__c = true;
        insert testApplication;
    }

    /**
     * @description Tests the handlePost method when provided with a valid Application name in the request payload.
     */
    @isTest
    private static void testHandlePostPositive() {
        // Given : post request payload is valid
        Application__c testApplication = [SELECT Name FROM Application__c LIMIT 1];

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.addParameter('applicationId', testApplication.Name);
        request.addParameter('fileName', 'Test.pdf');
        request.addParameter('comments', 'Test Comment');
        request.requestBody = Blob.valueOf('Test binary string');

        RestContext.request = request;
        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new BaseApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(BaseApplicationDocumentPayload.PostRequest.class, BaseApplicationDocumentPayload.PostResponse.class);
            Assert.areEqual(clientImplHandler.getRequestType(), BaseApplicationDocumentPayload.PostRequest.class, 'Request type should match');
            Assert.areEqual(clientImplHandler.getResponseType(), BaseApplicationDocumentPayload.PostResponse.class, 'Response type should match');
            clientImplHandler.execute();
            Test.stopTest();
        }

        // Then : get response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        BaseApplicationDocumentPayload.PostResponse customResponse = (BaseApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, BaseApplicationDocumentPayload.PostResponse.class);
        Assert.isTrue(customResponse.success, 'Expected success to be true');
        // Must create Nebula Log entry
        Assert.isTrue([SELECT Id, Nebula__OriginLocation__c FROM Nebula__LogEntry__c].size()>0);
    }

    /**
    * @description Tests the handlePost method when Application name is not provided in the request payload.
    */
    @isTest
    private static void testHandlePostNegative() {
        // Given : post request payload is invalid
        BaseApplicationDocumentPayload.PostRequest postRequestPayload = new BaseApplicationDocumentPayload.PostRequest();
        postRequestPayload.fileName = 'Test.pdf';
        postRequestPayload.binaryContent = Blob.valueOf('Test binary string');
        postRequestPayload.comments = 'Test Comment';

        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(postRequestPayload));
        RestContext.request = request;

        RestResponse response = new RestResponse();
        RestContext.response = response;

        // When : calling process method
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            RESTlib_ClientImplHandler clientImplHandler = new BaseApplicationDocumentImpl().getHandlePost();
            clientImplHandler.setPayloadType(BaseApplicationDocumentPayload.PostRequest.class, BaseApplicationDocumentPayload.PostResponse.class);
            clientImplHandler.execute();
            Test.stopTest();
        }
        // Then : get response
        String responseBodyString = response.responseBody.toString();
        // Deserialize string to custom payload class
        BaseApplicationDocumentPayload.PostResponse customResponse = (BaseApplicationDocumentPayload.PostResponse) JSON.deserialize(responseBodyString, BaseApplicationDocumentPayload.PostResponse.class);
        Assert.isFalse(customResponse.success, 'Expected success to be false');
    }
}