/**
 * @description Covers the payload class for (generic) Base Application Documents
 * @author      Kai-Fan Hsieh
 * @since       26 June 2024
 */
@IsTest(isParallel=true)
private class BaseApplicationDocumentPayload_Test {
    /**
     * @description Tests the assignment of property values to the BaseApplicationDocumentPayload.PostRequest object.
     */
    @IsTest
    private static void testAssignPropertyValues() {
        // Given : BaseApplicationDocumentPayload.PostRequest
        BaseApplicationDocumentPayload.PostRequest req;
        // When : init and assign values
        System.runAs(new User(Id = UserInfo.getUserId())) {
            req = new BaseApplicationDocumentPayload.PostRequest();
            req.applicationId = 'A-000000001';
            req.fileName = 'Test.pdf';
            req.binaryContent = Blob.valueOf('Test binary string');
            req.comments = 'Test Comment';
            req.documentChecklistId = 'Test internal Salesforce Id';
            req.documentType = 'Test document type';
        }
        // Then : not null
        Assert.areNotEqual(null, req, 'Unable to create BaseApplicationDocumentPayload.PostRequest payload');
    }
}