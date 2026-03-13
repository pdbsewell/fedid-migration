/**
 * @author      JM Mapanao
 * @description Test class for DMSFileService class
 * @group       Test Class
 * @revision    18.SEP.2020 - JM Mapanao - Created
 */
@isTest(isParallel=true)
public with sharing class DMSFileService_Test {
    /**
     * @description Tests getDocuments method
     */ 
    @isTest 
    static void test_getDocumentsPositive() {
        // Create Contact test data
        Contact con = new Contact(
        FirstName = 'TestFirstName',
        LastName = 'TestLastName',
        Person_ID_unique__c = '1043');
        insert con;

        // Create a mock response
        String mockReponse = '[{"category": "Offer","personId": "88","location": "https://test.com","name": "testPdf","createdDate": "2019-01-13 09:20:59.0","extension": "pdf","subCategory": "ISCA","size": 1190573}]';
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(mockReponse);

        //Start test process
        Test.startTest();

        Test.setContinuationResponse('Continuation-1', response);
        Continuation testContinuation = (Continuation)DMSFileService.getDocuments(con.Id);
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = testContinuation.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
        List<String> labels = new List<String>{'Continuation-1'};

        Map<String, Object> result = (Map<String, Object>) DMSFileService.processAllResponses(labels, null);
        System.debug(LoggingLevel.DEBUG, '##### test_getDocumentsPositive ===>' + testContinuation);
        System.assertNotEquals(null, result.get('docList'), 'Continuation failed: response body not valid for request');

        List<DMSFileService.DocumentDetails> res = (List<DMSFileService.DocumentDetails>) result.get('docList');
        System.assertEquals('Offer', res[0].category, 'Continuation failed: response body category not equal to Offer');
        System.assertEquals('ISCA', res[0].subCategory, 'Continuation failed: response body subCategory not equal to ISCA');
        System.assertEquals('88', res[0].personId, 'Continuation failed: response body personId not equal to 88');
        System.assertEquals('https://test.com', res[0].location, 'Continuation failed: response body location not equal to https://test.com');
        System.assertEquals('testPdf', res[0].name, 'Continuation failed: response body name not equal to testPdf');
        System.assertEquals('2019-01-13 09:20:59.0', res[0].createdDate, 'Continuation failed: response body createdDate not equal to 2019-01-13 09:20:59.0');
        System.assertEquals('pdf', res[0].extension, 'Continuation failed: response body extension not equal to pdf');
        System.assertEquals(1190573, res[0].size, 'Continuation failed: response body size not equal to 1190573');
        

        Test.stopTest();
    }

    /**
     * @description Tests getDocuments method
     */ 
    @isTest 
    static void test_getDocumentsNegative1() {
        // Create Contact test data
        Contact con = new Contact(
        FirstName = 'TestFirstName',
        LastName = 'TestLastName',
        Person_ID_unique__c = '');
        insert con;

        //Start test process
        Test.startTest();
        
        Map<String, Object> resultMap = (Map<String, Object>)DMSFileService.getDocuments(con.Id);
        // Verify that the continuation return state is error
        System.assertEquals('error', resultMap.get('state'), 'Continuation failed: No person id found');

        Test.stopTest();
    }

    /**
     * @description Tests getDocuments method
     */ 
    @isTest 
    static void test_getDocumentsNegative2() {
        // Create Contact test data
        Contact con = new Contact(
        FirstName = 'TestFirstName',
        LastName = 'TestLastName',
        Person_ID_unique__c = '1043');
        insert con;

        // Create a mock response
        String mockReponse = '[{}]';
        HttpResponse response = new HttpResponse();
        response.setStatusCode(404);
        response.setBody(mockReponse);

        //Start test process
        Test.startTest();

        Test.setContinuationResponse('Continuation-1', response);
        Continuation testContinuation = (Continuation)DMSFileService.getDocuments(con.Id);
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = testContinuation.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
        List<String> labels = new List<String>{'Continuation-1'};

        Map<String, Object> result = (Map<String, Object>) DMSFileService.processAllResponses(labels, null);
        System.debug(LoggingLevel.DEBUG, '##### test_getDocumentsPositive ===>' + testContinuation);
        System.assertEquals(false, result.containsKey('docList'), 'Continuation failed: response body not valid for request');

        Test.stopTest();
    }
}