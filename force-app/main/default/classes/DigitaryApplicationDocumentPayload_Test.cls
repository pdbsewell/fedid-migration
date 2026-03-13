/**
 * @description Covers the payload class for Digitary-specific Application Documents
 * @author      Kai-Fan Hsieh
 * @since       26 June 2024
 */
@IsTest(isParallel=true)
private class DigitaryApplicationDocumentPayload_Test {
    /**
     * @description Tests the assignment of property values to the DigitaryApplicationDocumentPayload.PostRequest object.
     */
    @IsTest
    private static void testAssignPostRequestPropertyValues() {
        // Given : DigitaryApplicationDocumentPayload.PostRequest
        DigitaryApplicationDocumentPayload.PostRequest req;
        // When : init and assign values
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            req = new DigitaryApplicationDocumentPayload.PostRequest();
            req.parameters = new DigitaryApplicationDocumentPayload.Parameters();
            req.parameters.monash_reference_id = 'A-000000001';
            req.channel = 'CSSD';
            req.issuerDeliveryId = '4d611b71-3512-4ada-8577-7f63158df235';
            req.issuerDocumentOwnerName = 'Test Owner';
            req.issuerDocumentOwnerEmail = 'Test.Owner@email.com';
            req.documents = new List<DigitaryApplicationDocumentPayload.Document>();
            DigitaryApplicationDocumentPayload.Document document = new DigitaryApplicationDocumentPayload.Document();
            req.documents.add(document);
            document.issuerName = 'Test issuer name';
            document.issuerDocumentType = 'Test issuer document type';
            document.issuerDate = Date.today();
            document.issuerDocumentId = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b6';
            // Then : not null
            Assert.areNotEqual(null, req, 'Unable to create DigitaryApplicationDocumentPayload.PostRequest payload');
        }
    }

    /**
     * @description Tests the assignment of property values to the DigitaryApplicationDocumentPayload.PatchRequest object.
     */
    @IsTest
    private static void testAssignPatchRequestPropertyValues() {
        // Given : DigitaryApplicationDocumentPayload.PostRequest
        DigitaryApplicationDocumentPayload.PatchRequest req;
        // When : init and assign values
        System.runAs(StudFirst_TestHelper.buildDigitaryApiUser()) {
            req = new DigitaryApplicationDocumentPayload.PatchRequest();
            req.issuerDeliveryId = '4d611b71-3512-4ada-8577-7f63158df235';
            req.documents = new List<DigitaryApplicationDocumentPayload.Document>();
            DigitaryApplicationDocumentPayload.Document document = new DigitaryApplicationDocumentPayload.Document();
            req.documents.add(document);
            document.issuerName = 'Test issuer name';
            document.issuerDocumentType = 'Test issuer document type';
            document.issuerDate = Date.today();
            document.issuerDocumentId = '67230a8b-7a3e-58c3-b2c7-f71ecfc049b6';
            // Then : not null
            Assert.areNotEqual(null, req, 'Unable to create DigitaryApplicationDocumentPayload.PatchRequest payload');
        }
    }
}