/**
 * @description Test class for OffersCompletedDocumentHandler
 */
@isTest(isParallel=true)
public class OffersCompletedDocumentHandler_Test {

    /**
    Note: The system stores envelop ids on quote in lowercase and envelop ids 
    DocuSign statuses are stored as upper case
    Any test data should follow this.
     */

    private static final String DOCUSIGN_ENVELOP_COMPLETED_STATUS = 'Completed';
    private static final String SINGLE_COMPLETED_DOCUSIGN_ENVELOP_ID = 'COMPLETED-1-0001';

    private static final String ONE_OF_TWO_COMPLETED_DOCUSIGN_ENVELOP_ID = 'COMPLETED-1-0001';
    private static final String TWO_OF_TWO_COMPLETED_DOCUSIGN_ENVELOP_ID = 'COMPLETED-2-0002';

    private static String docuSignStatusRecordIdPrefix;

    @isTest
    static void shouldNotCreateEventWhenContentDocumentLinkIsRelatedToQuote() {
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.process(fakeContentDocumentLink(getQuoteRecordIdPrefix() + '5P000000025NUAQ'));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event created as content document link was no related to DocuSign status');
    }

    @isTest
    static void shouldNotQueryWhenContentDocumentLinkIsRelatedToContact() {
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.process(fakeContentDocumentLink(getContactRecordIdPrefix() + '5P000000025NUAQ'));
        handler.execute();
        System.assertEquals(0, Limits.getQueries(), 
            'Expected no queries executed because the record does not qualify for processing');
    }

    @isTest
    static void shouldNotCreateEventWhenTwoContentDocumentLinkIsRelatedToQuote() {
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.process(fakeContentDocumentLink(getQuoteRecordIdPrefix() + '5P000000025NUAQ'));
        handler.process(fakeContentDocumentLink(getQuoteRecordIdPrefix() + '5P000000025NUAB'));
        handler.execute();
    
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event created as content document link was no related to DocuSign status');
    }

    @isTest
    static void shouldNotCreateEventWhenContentDocumentLinkIsRelatedToContact() {
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.process(fakeContentDocumentLink(getContactRecordIdPrefix() + '5P000000025NUAQ'));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event created as content document link was no related to DocuSign status');
    }

    @isTest
    static void shouldNotCreateEventWhenEnvelopStatusIsNotCompleted() {   
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.docuSignStatusSelector = (DocuSignStatusSelector) Test.createStub(
            DocuSignStatusSelector.class, 
            new SingleNotCompletedDocuSignStatusSelectorSelectorStub());
        handler.process(fakeContentDocumentLink(getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ'));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event created as the envelop status is not completed');
    }

    @isTest
    static void shouldNotCreateEventWhenTwoEnvelopStatusIsNotCompleted() {   
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.docuSignStatusSelector = (DocuSignStatusSelector) Test.createStub(
            DocuSignStatusSelector.class, 
            new SingleNotCompletedDocuSignStatusSelectorSelectorStub());
        handler.process(fakeContentDocumentLink(getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ'));
        handler.process(fakeContentDocumentLink(getDocuSignStatusRecordIdPrefix() + '5P000000025NUAW'));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event created as the envelop status is not completed');
    }

    @isTest
    static void shouldNotCreateEventWhenEnvelopIdIsNotInSystem() {
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.docuSignStatusSelector = (DocuSignStatusSelector) Test.createStub(
            DocuSignStatusSelector.class, 
            new SingleCompletedDocuSignStatusSelectorSelectorStub(getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ'));

        handler.process(fakeContentDocumentLink(getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ'));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event created as the envelop Id did not exist in system');
    }

    @isTest
    static void shouldNotCreateEventWhenTwoEnvelopIdsIsNotInSystem() {
        Id docuSignStatus1RecordId = getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ';
        Id docuSignStatus2RecordId = getDocuSignStatusRecordIdPrefix() + '5P000000025NUAV';
        
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.docuSignStatusSelector = (DocuSignStatusSelector) Test.createStub(
            DocuSignStatusSelector.class, 
            new TwoCompletedDocuSignStatusSelectorSelectorStub(
                docuSignStatus1RecordId, docuSignStatus2RecordId));
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new NoMatchingQuotesSelectorSelectorStub());
        handler.process(fakeContentDocumentLink(docuSignStatus1RecordId));
        handler.process(fakeContentDocumentLink(docuSignStatus2RecordId));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(0, Limits.getDMLStatements(), 
            'Expected no platform event created as the envelop Ids did not exist in system');
    }

    @isTest
    static void shouldCreateEventWhenEnvelopIsCompletedAndInSystem() {
        Id docuSignStatus1RecordId = getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ';
        
        Id contentDocumentRecordId = getContentDocumentRecordIdPrefix() + '5P000000025NUAA';
        
        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.docuSignStatusSelector = (DocuSignStatusSelector) Test.createStub(
            DocuSignStatusSelector.class, 
            new SingleCompletedDocuSignStatusSelectorSelectorStub(
                docuSignStatus1RecordId));
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new SingleMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentsSelector = (ContentDocumentsSelector) Test.createStub(
            ContentDocumentsSelector.class, 
            new SingleContentDocumentsSelectorSelectorStub(
                contentDocumentRecordId));
        handler.process(fakeContentDocumentLink(docuSignStatus1RecordId, contentDocumentRecordId));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(1, Limits.getDMLStatements(), 
            'Expected 1 platform event created as the envelop Ids are valid');
    }

    @isTest
    static void shouldCreateEventWhenTwoEnvelopIsCompletedAndInSystem() {
        Id docuSignStatus1RecordId = getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ';
        Id docuSignStatus2RecordId = getDocuSignStatusRecordIdPrefix() + '5P000000025NUAU';

        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.docuSignStatusSelector = (DocuSignStatusSelector) Test.createStub(
            DocuSignStatusSelector.class, 
            new TwoCompletedDocuSignStatusSelectorSelectorStub(
                docuSignStatus1RecordId, docuSignStatus2RecordId));
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new TwoMatchingQuotesSelectorSelectorStub());
        handler.process(fakeContentDocumentLink(docuSignStatus1RecordId));
        handler.process(fakeContentDocumentLink(docuSignStatus2RecordId));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        System.assertEquals(2, Limits.getDmlRows(), 
            'Expected 2 platform event rows created as 2 envelop Ids are valid');
    }

    @isTest
    static void shouldCreateOneEventWhenOneOfTwoEnvelopIsCompletedAndInSystem() {
        Id docuSignStatus1RecordId = getDocuSignStatusRecordIdPrefix() + '5P000000025NUAQ';
        Id docuSignStatus2RecordId = getDocuSignStatusRecordIdPrefix() + '5P000000025NUAW';

        OffersCompletedDocumentHandler handler = new OffersCompletedDocumentHandler();
        handler.docuSignStatusSelector = (DocuSignStatusSelector) Test.createStub(
            DocuSignStatusSelector.class, 
            new TwoCompletedDocuSignStatusSelectorSelectorStub(
                docuSignStatus1RecordId, docuSignStatus2RecordId));
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new OneOfTwoMatchingQuotesSelectorSelectorStub());
        handler.process(fakeContentDocumentLink(docuSignStatus1RecordId));
        handler.process(fakeContentDocumentLink(docuSignStatus2RecordId));
        handler.execute();
    
        // platform events consume dml statements, using this to infer if 
        // the platform event has been created
        // since platform events is published in bulk, number of rows inserted 
        // can hepl determine the number of actual "events" published
        System.assertEquals(1, Limits.getDmlRows(), 
            'Expected 1 platform event row created as only 1 of 2 envelop Ids are valid');
    }


    private class TwoMatchingQuotesSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectQuotesByPrimaryDocuSignEnvelopId method is called

            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
            quote1.Primary_DocuSign_Envelop_Id__c = 
                ONE_OF_TWO_COMPLETED_DOCUSIGN_ENVELOP_ID.toLowerCase(); // simulate real data
            
            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();
            quote2.Primary_DocuSign_Envelop_Id__c = 
                TWO_OF_TWO_COMPLETED_DOCUSIGN_ENVELOP_ID.toLowerCase(); // simulate real data
            

            return new List<SBQQ__Quote__c>{quote1, quote2};
        }
        
    }

    private class OneOfTwoMatchingQuotesSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectQuotesByPrimaryDocuSignEnvelopId method is called

            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
            quote1.Primary_DocuSign_Envelop_Id__c = 
                ONE_OF_TWO_COMPLETED_DOCUSIGN_ENVELOP_ID.toLowerCase(); // simulate real data
            
            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();
            quote2.Primary_DocuSign_Envelop_Id__c = 'zzzz-83083953-sdsjkfksnjs'; // simulate real data
        
            return new List<SBQQ__Quote__c>{quote1, quote2};
        }
        
    }

    private class SingleMatchingQuotesSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectQuotesByPrimaryDocuSignEnvelopId method is called

            SBQQ__Quote__c quote = new SBQQ__Quote__c();
            quote.Primary_DocuSign_Envelop_Id__c = 
                SINGLE_COMPLETED_DOCUSIGN_ENVELOP_ID.toLowerCase(); // simulate real data
            return new List<SBQQ__Quote__c>{quote};
        }
        
    }

    private class NoMatchingQuotesSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectQuotesByPrimaryDocuSignEnvelopId method is called
            // and no values are found
            return new List<SBQQ__Quote__c>();
        }

    }

    private class TwoCompletedDocuSignStatusSelectorSelectorStub implements System.StubProvider {

        private Id recordId1;
        private Id recordId2;

        public TwoCompletedDocuSignStatusSelectorSelectorStub(Id recordId1, Id recordId2) {
            this.recordId1 = recordId1;
            this.recordId2 = recordId2;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method selectById
            dsfs__DocuSign_Status__c docuSignStatus1 = 
                new dsfs__DocuSign_Status__c();
            docuSignStatus1.Id = this.recordId1;
            docuSignStatus1.dsfs__DocuSign_Envelope_ID__c = 
                ONE_OF_TWO_COMPLETED_DOCUSIGN_ENVELOP_ID.toUpperCase();
            docusignStatus1.dsfs__Envelope_Status__c = 
                DOCUSIGN_ENVELOP_COMPLETED_STATUS;

            dsfs__DocuSign_Status__c docuSignStatus2 = 
                new dsfs__DocuSign_Status__c();
            docuSignStatus2.Id = this.recordId2;
            docuSignStatus2.dsfs__DocuSign_Envelope_ID__c = 
                TWO_OF_TWO_COMPLETED_DOCUSIGN_ENVELOP_ID.toUpperCase();
            docuSignStatus2.dsfs__Envelope_Status__c = 
                DOCUSIGN_ENVELOP_COMPLETED_STATUS;

            return new List<dsfs__DocuSign_Status__c> {
                docusignStatus1, docusignStatus2
            };
        }
    }

    private class SingleCompletedDocuSignStatusSelectorSelectorStub implements System.StubProvider {

        private Id recordId;

        public SingleCompletedDocuSignStatusSelectorSelectorStub(Id recordId) {
            this.recordId = recordId;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method selectById
            dsfs__DocuSign_Status__c docuSignStatus = 
                new dsfs__DocuSign_Status__c();
            docuSignStatus.Id = this.recordId;
            docuSignStatus.dsfs__DocuSign_Envelope_ID__c = 
                SINGLE_COMPLETED_DOCUSIGN_ENVELOP_ID.toUpperCase(); // simulate real life data
            docusignStatus.dsfs__Envelope_Status__c = DOCUSIGN_ENVELOP_COMPLETED_STATUS;
            return new List<dsfs__DocuSign_Status__c> {docusignStatus};
        }
    }

    private class SingleNotCompletedDocuSignStatusSelectorSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method selectById
            dsfs__DocuSign_Status__c docuSignStatus = 
                new dsfs__DocuSign_Status__c();
            docuSignStatus.dsfs__DocuSign_Envelope_ID__c = 'ABC123';
            docusignStatus.dsfs__Envelope_Status__c = 'Sent';
            return new List<dsfs__DocuSign_Status__c> {docusignStatus};
        }
    }

    private class TwoNotCompletedDocuSignStatusSelectorSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method selectById
            dsfs__DocuSign_Status__c docuSignStatus1 = 
                new dsfs__DocuSign_Status__c();
            docuSignStatus1.dsfs__DocuSign_Envelope_ID__c = 'ABC123';
            docusignStatus1.dsfs__Envelope_Status__c = 'Sent';

            dsfs__DocuSign_Status__c docuSignStatus2 = 
                new dsfs__DocuSign_Status__c();
            docuSignStatus2.dsfs__DocuSign_Envelope_ID__c = 'ZXY123';
            docusignStatus2.dsfs__Envelope_Status__c = 'Sent';

            return new List<dsfs__DocuSign_Status__c> {docusignStatus1, docuSignStatus2};
        }
    }

    private class SingleContentDocumentsSelectorSelectorStub implements System.StubProvider {

        private Id contentDocumentId;

        public SingleContentDocumentsSelectorSelectorStub(Id contentDocumentId) {
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            String contentDocumentJson = 
            '{"attributes":{"type":"ContentDocument"}, "Id":"'+ contentDocumentId 
                +'", "Title":"Test Document"}';
            ContentDocument contentDocument = (ContentDocument) JSON.deserialize(contentDocumentJson, 
            ContentDocument.class);
            return new List<ContentDocument> {contentDocument};
        }
    }

    // cannot assume record id prefix will always be the same in different 
    // environments, so this needs to be retrieved once per test class execution
    private static String getQuoteRecordIdPrefix() {
        Schema.DescribeSObjectResult result = SBQQ__Quote__c.sObjectType.getDescribe();
        return result.getKeyPrefix();
    }

    private static String getContactRecordIdPrefix() {
        Schema.DescribeSObjectResult result = Contact.sObjectType.getDescribe();
        return result.getKeyPrefix();
    }

    private static String getDocuSignStatusRecordIdPrefix() {
        if (String.isBlank(docuSignStatusRecordIdPrefix)) {
            Schema.DescribeSObjectResult result = dsfs__DocuSign_Status__c.sObjectType.getDescribe();
            docuSignStatusRecordIdPrefix = result.getKeyPrefix();
        }
        return docuSignStatusRecordIdPrefix;
    }

    private static String getContentDocumentRecordIdPrefix() {
        Schema.DescribeSObjectResult result = ContentDocument.sObjectType.getDescribe();
        return result.getKeyPrefix();
    }

    private static ContentDocumentLink fakeContentDocumentLink(String recordId) {
        String contentDocumentLinkJson = 
            '{"attributes":{"type":"ContentDocumentLink"}, "ShareType":"V", "Visibility": "InternalUsers", "LinkedEntityId": "' + recordId + '"}';
        return (ContentDocumentLink) JSON.deserialize(contentDocumentLinkJson, 
            ContentDocumentLink.class);
    }

    private static ContentDocumentLink fakeContentDocumentLink(String recordId, String contentDocumentLinkRecordId) {
        String contentDocumentLinkJson = 
            '{"attributes":{"type":"ContentDocumentLink"}, "Id":"'+ contentDocumentLinkRecordId +'", "ShareType":"V", "Visibility": "InternalUsers", "LinkedEntityId": "' + recordId + '"}';
        return (ContentDocumentLink) JSON.deserialize(contentDocumentLinkJson, 
            ContentDocumentLink.class);
    }

}