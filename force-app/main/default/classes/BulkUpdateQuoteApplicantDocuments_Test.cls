/**
 * @description Test class for BulkUpdateQuoteApplicantDocuments
 */
@isTest(isParallel=true)
public class BulkUpdateQuoteApplicantDocuments_Test {
    
    private static final String ENVELOP_ID_1 = 'abc-123-1';
    private static final String ENVELOP_ID_2 = 'abc-123-2';

    private static final Id CONTACT_ID_1 = Id.valueOf('0035P000001x1QEQAY');
    private static final Id CONTACT_ID_2 = Id.valueOf('0035P000001x1QEQAV');

    private static final Id OTHER_USER_ID = Id.valueOf('0050I000008F2cAQAV');
    private static final Id USER_ID_1 = Id.valueOf('0050I000008F2cAQAS');
    private static final Id USER_ID_2 = Id.valueOf('0050I000008F2cAQAV');

    private static final Id CONTENT_DOCUMENT_ID_1 = Id.valueOf('0695P0000002WgMQAU');
    private static final Id CONTENT_DOCUMENT_ID_2 = Id.valueOf('0695P0000002WgMQAV');

    @isTest
    static void shouldUpdateQuoteDocumentOwnerToApplicant() {

        Offers_Signed_Document_Attached__e event = 
        new Offers_Signed_Document_Attached__e();
        event.Envelop_Id__c = ENVELOP_ID_1;
        event.Content_Document_Id__c = CONTENT_DOCUMENT_ID_1;
        event.File_Name__c = 'test';

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1;
        quote.SBQQ__PrimaryContact__c = CONTACT_ID_1;

        ContentDocumentsSelector contentDocumentsSelector = 
            (ContentDocumentsSelector) Test.createStub(
                ContentDocumentsSelector.class, 
                new SingleFileContentDocumentsSelectorStub()
            );

        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();

        UsersSelector usersSelector = (UsersSelector) Test.createStub(
            UsersSelector.class, 
            new SingleUsersSelectorStub()
        );

        BulkUpdateQuoteApplicantDocuments bulkUpdateQuoteApplicantDocuments = 
            new BulkUpdateQuoteApplicantDocuments(
                contentDocumentsSelector, contentDocumentDaoMock, 
                usersSelector
            );

        bulkUpdateQuoteApplicantDocuments.updateContentDocumentOwnerToApplicant(
            new List<Offers_Signed_Document_Attached__e>{event},
            new List<SBQQ__Quote__c>{quote}
        );
        
        ContentDocument contentDocumentInserted = 
            (ContentDocument) contentDocumentDaoMock.recordsUpdated[0];
        System.assertEquals(USER_ID_1, contentDocumentInserted.OwnerId, 
            'Expected owner Id to be update to the primary contact\'s user Id');
    }

    @isTest
    static void shouldUpdateQuoteDocumentOwnerToApplicantWhenThereAreTwoDifferentQuotes() {

        Offers_Signed_Document_Attached__e event1 = 
        new Offers_Signed_Document_Attached__e();
        event1.Envelop_Id__c = ENVELOP_ID_1;
        event1.Content_Document_Id__c = CONTENT_DOCUMENT_ID_1;
        event1.File_Name__c = 'test';

        Offers_Signed_Document_Attached__e event2 = 
        new Offers_Signed_Document_Attached__e();
        event2.Envelop_Id__c = ENVELOP_ID_2;
        event2.Content_Document_Id__c = CONTENT_DOCUMENT_ID_2;
        event2.File_Name__c = 'test';

        SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
        quote1.Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1;
        quote1.SBQQ__PrimaryContact__c = CONTACT_ID_1;

        SBQQ__Quote__c quote2 = new SBQQ__Quote__c();
        quote2.Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_2;
        quote2.SBQQ__PrimaryContact__c = CONTACT_ID_2;

        ContentDocumentsSelector contentDocumentsSelector = 
            (ContentDocumentsSelector) Test.createStub(
                ContentDocumentsSelector.class, 
                new TwoFilesContentDocumentsSelectorStub()
            );

        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();

        UsersSelector usersSelector = (UsersSelector) Test.createStub(
            UsersSelector.class, 
            new TwoUsersSelectorStub()
        );

        BulkUpdateQuoteApplicantDocuments bulkUpdateQuoteApplicantDocuments = 
            new BulkUpdateQuoteApplicantDocuments(
                contentDocumentsSelector, contentDocumentDaoMock, 
                usersSelector
            );

        bulkUpdateQuoteApplicantDocuments.updateContentDocumentOwnerToApplicant(
            new List<Offers_Signed_Document_Attached__e>{event1, event2},
            new List<SBQQ__Quote__c>{quote1, quote2}
        );
        
        boolean isMatchDocument1ToQuote1UserId = false;
        boolean isMatchDocument2ToQuote2UserId = false;

        for (ContentDocument contentDocumentInserted : 
                (ContentDocument[]) contentDocumentDaoMock.recordsUpdated) {
            
            if (contentDocumentInserted.Id == CONTENT_DOCUMENT_ID_1 && 
                    contentDocumentInserted.OwnerId == USER_ID_1) {
                isMatchDocument1ToQuote1UserId = true;
            }

            if (contentDocumentInserted.Id == CONTENT_DOCUMENT_ID_2 && 
                    contentDocumentInserted.OwnerId == USER_ID_2) {
                isMatchDocument2ToQuote2UserId = true;
            }
        }
        System.assertEquals(true, isMatchDocument1ToQuote1UserId, 
            'Expected content document 1 Owner Id to match the quote\'s ' + 
            ' primary contact\'s user id');
        System.assertEquals(true, isMatchDocument2ToQuote2UserId, 
            'Expected content document 2 Owner Id to match the quote\'s ' + 
            ' primary contact\'s user id');
    }

    // SCENARIO: single quote, single file and single contact/user

    private class SingleUsersSelectorStub implements System.StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assume selectUsersByContactId is called
            User user1 = new User();
            user1.Id = USER_ID_1;
            user1.contactId = CONTACT_ID_1;
            return new List<User>{user1};
        }
    }

    private class SingleFileContentDocumentsSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectById method is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 1", "Id": "' 
                + CONTENT_DOCUMENT_ID_1 + '", "OwnerId": "' + OTHER_USER_ID 
                + '", "LatestPublishedVersionId":"0695P0000002WgMQAC"}';
            ContentDocument contentDocument1 = 
                        (ContentDocument) JSON.deserialize(contentDocument1Json, 
                        ContentDocument.class);
            return new List<ContentDocument>{contentDocument1};
        }
    }

    // SCENARIO: Two quotes, two different contact, two different files
    
    private class TwoUsersSelectorStub implements System.StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assume selectUsersByContactId is called
            User user1 = new User();
            user1.Id = USER_ID_1;
            user1.contactId = CONTACT_ID_1;

            User user2 = new User();
            user2.Id = USER_ID_2;
            user2.contactId = CONTACT_ID_2;
            return new List<User>{user1, user2};
        }
    }

    private class TwoFilesContentDocumentsSelectorStub 
            implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectById method is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 1", "Id": "' 
                + CONTENT_DOCUMENT_ID_1 + '", "OwnerId": "' + OTHER_USER_ID 
                + '", "LatestPublishedVersionId":"0695P0000002WgMQAC"}';
            ContentDocument contentDocument1 = 
                (ContentDocument) JSON.deserialize(contentDocument1Json, 
                ContentDocument.class);
            
            String contentDocument2Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 1", "Id": "' 
                + CONTENT_DOCUMENT_ID_2 + '", "OwnerId": "' + OTHER_USER_ID 
                + '", "LatestPublishedVersionId":"0695P0000002WgMQAV"}';
            ContentDocument contentDocument2 = 
                (ContentDocument) JSON.deserialize(contentDocument2Json, 
                ContentDocument.class);
            
            return new List<ContentDocument>{contentDocument1, contentDocument2};
        }
    }
}