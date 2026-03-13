/*******************************************************************************
* @author		Sachin Shetty
* @date         2025-17-08   
* @description  Test class for GRDocumentRequestPatchJSON
* @revision
 * 		2025-17-08	-	Sachin Shetty	-	Created
*******************************************************************************/
@isTest(isParallel=true)
public class GRDocumentRequestPatchJSON_Test {
@IsTest
    static void testGRDocumentRequestPatchJSON() {
        // GIVEN - a new instance of the JSON wrapper class
        GRDocumentRequestPatchJSON jsonWrapper;
        
        // WHEN - instantiating the class
        jsonWrapper = new GRDocumentRequestPatchJSON();
        
        // THEN - verify the instance is created and inner HDRDocumentRequest is initialized
        Assert.isNotNull(jsonWrapper, 'GRDocumentRequestPatchJSON instance should be created');
        Assert.isNotNull(jsonWrapper.hdrDocumentRequest, 'HDRDocumentRequest instance should be initialized');
        
        // THEN - set some sample values and assert
        jsonWrapper.hdrDocumentRequest.applicantId = 12345;
        jsonWrapper.hdrDocumentRequest.hdrApplicationNumber = 67890;
        jsonWrapper.hdrDocumentRequest.requestSequenceNumber = 1;
        jsonWrapper.hdrDocumentRequest.smsDocumentId = 54321;
        jsonWrapper.hdrDocumentRequest.submittedDate = '2025-08-18';
        
        Assert.areEqual(12345, jsonWrapper.hdrDocumentRequest.applicantId);
        Assert.areEqual(67890, jsonWrapper.hdrDocumentRequest.hdrApplicationNumber);
        Assert.areEqual(1, jsonWrapper.hdrDocumentRequest.requestSequenceNumber);
        Assert.areEqual(54321, jsonWrapper.hdrDocumentRequest.smsDocumentId);
        Assert.areEqual('2025-08-18', jsonWrapper.hdrDocumentRequest.submittedDate);
    }
}