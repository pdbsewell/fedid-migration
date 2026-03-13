/**
 * @description Covers the payload class for Digitary-specific Application Document Content
 * @author      Kai-Fan Hsieh
 * @since       08/08/2024
 */
@IsTest(isParallel=true)
private class DigitaryAppDocContentPayload_Test {
    /**
     * @description Tests the assignment of property values to the DigitaryApplicationDocContentPayload.PostRequest object.
     */
    @IsTest
    private static void testAssignPropertyValues() {
        // Given : DigitaryApplicationDocContentPayload.PostRequest
        DigitaryApplicationDocContentPayload.PostRequest req;
        // When : init and assign values
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            req = new DigitaryApplicationDocContentPayload.PostRequest();
            req.issuerDeliveryId = '4d611b71-3512-4ada-8577-7f63158df235';
            req.issuerDocumentId = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b6';
            req.contentVersionId = FakeRecordIdGenerator.generateId(ContentVersion.getSObjectType());
            req.contentType = 'application/pdf';
            // Then : not null
            Assert.areNotEqual(null, req, 'Unable to create DigitaryApplicationDocContentPayload.PostRequest payload');
        }
    }
}