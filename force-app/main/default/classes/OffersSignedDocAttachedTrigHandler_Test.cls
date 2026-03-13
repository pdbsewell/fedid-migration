/**
 * @description Test class for OffersSignedDocAttachedTrigHandler
 */
@isTest
public class OffersSignedDocAttachedTrigHandler_Test {

    private static final String CERTIFICATE_IDENTIFIER_SUBSTRING = 'certificate';

    private static final String ENVELOP_ID_1 = 'abc-123-1';
    private static final String ENVELOP_ID_2 = 'abc-123-2';

   // private static final Id CONTACT_ID_1 = Id.valueOf('0035P000001x1QEQAY');
    //private static final Id CONTACT_ID_2 = Id.valueOf('0035P000001x1QEQAV');
    
    @testSetup
    static void setUp()
    {
		    List<Contact> conList = new List<Contact>();
            Contact c = StudFirst_TestHelper.createApplicant();
            c.Person_ID_unique__c = '12341578';
            conList.add(c);
            
            Contact c10 = StudFirst_TestHelper.createApplicant();
            c10.Person_ID_unique__c = '125754';
            conList.add(c10);        
            insert conList;
    }

    @isTest
    static void shouldCreateContentDocumentLinkToQuote() {
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();
     
        Offers_Signed_Document_Attached__e event = 
            new Offers_Signed_Document_Attached__e();
        event.Envelop_Id__c = ENVELOP_ID_1;
        event.Content_Document_Id__c = '0695P0000002WgMQAU';
        event.File_Name__c = 'test';

        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new SingleMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
       
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
        handler.process(event);
        handler.execute();
        System.assertEquals(1, contentDocumentLinkDaoMock.recordsInserted.size(), 
            'Expected 1 ContentDocument to be created');
    }

    @isTest
    static void shouldCreateTwoContentDocumentLinkForTwoQuotes() {
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();
      
        Offers_Signed_Document_Attached__e event1 = 
            new Offers_Signed_Document_Attached__e();
        event1.Envelop_Id__c = ENVELOP_ID_1;
        event1.Content_Document_Id__c = '0695P0000002WgMQAU';
        event1.File_Name__c = 'test file';

        Offers_Signed_Document_Attached__e event2 = 
            new Offers_Signed_Document_Attached__e();
        event2.Envelop_Id__c = ENVELOP_ID_2;
        event2.Content_Document_Id__c = '0695P0000002WgMQAV';
        event2.File_Name__c = 'test file certificate';

        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new TwoMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.contentDocumentsSelector = (ContentDocumentsSelector) Test.createStub(
            ContentDocumentsSelector.class, 
            new TwoMatchingContentDocumentSelectorSelectorStub());
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
        handler.usersSelector =  (UsersSelector) Test.createStub(
            UsersSelector.class, 
            new TwoMatchUsersSelectorStub());
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
        handler.process(event1);
        handler.process(event2);
        handler.execute();
        System.assertEquals(2, contentDocumentLinkDaoMock.recordsInserted.size(), 
            'Expected 2 ContentDocument to be created');
        System.assert(contentDocumentLinkDaoMock.recordsInserted[0].get('ContentDocumentId') 
            != contentDocumentLinkDaoMock.recordsInserted[1].get('ContentDocumentId'), 
            'Expected two different content document link references');
    }

    @isTest
    static void shouldUpdateQuoteWithSignedDocumentId() {
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();
       

        Offers_Signed_Document_Attached__e event = 
            new Offers_Signed_Document_Attached__e();
        event.Envelop_Id__c = ENVELOP_ID_1;
        event.Content_Document_Id__c = '0695P0000002WgMQAU';
        event.File_Name__c = 'title 1s';

        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new SingleMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentsSelector = (ContentDocumentsSelector) Test.createStub(
            ContentDocumentsSelector.class, 
            new SingleContentDocumentsSelectorStub());
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
        handler.process(event);
        handler.execute();
        
        System.assertNotEquals(null, 
            quoteDaoMock.recordsUpdated[0].get('Final_Signed_Document_Id__c'), 
            'Expected Final Signed Document on Quote to be populated');
        System.assertEquals(null, 
            quoteDaoMock.recordsUpdated[0].get('DocuSign_Signed_Certificate_Document_Id__c'), 
            'Expected DocuSign Signed Certificate Document on Quote to be blank as the file is not considered a certificate');
    }

    @isTest
    static void shouldUpdateTwoQuotesWithSignedDocumentIdWhenTwoSignedDocEventsExist() {
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();

        Offers_Signed_Document_Attached__e event1 = 
            new Offers_Signed_Document_Attached__e();
        event1.Envelop_Id__c = ENVELOP_ID_1;
        event1.Content_Document_Id__c = '0695P0000002WgMQAU';
        event1.File_Name__c = 'title 1';

        Offers_Signed_Document_Attached__e event2 = 
            new Offers_Signed_Document_Attached__e();
        event2.Envelop_Id__c = ENVELOP_ID_2;
        event2.Content_Document_Id__c = '0695P0000002WgMQAV';
        event2.File_Name__c = 'title 2';


        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new TwoMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentsSelector = (ContentDocumentsSelector) Test.createStub(
            ContentDocumentsSelector.class, 
            new TwoSignedDocumentContentDocumentSelectorSelectorStub());
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
        handler.process(event1);
        handler.process(event2);
        handler.execute();
        System.assert(quoteDaoMock.recordsUpdated[0].get('Final_Signed_Document_Id__c') 
            != quoteDaoMock.recordsUpdated[1].get('Final_Signed_Document_Id__c'),
            'Expected different signed document Ids on 2 quotes as each ' 
            + 'there is only 1 signed document per quote/envelop Id.');
    }

    @isTest
    static void shouldUpdateQuoteWithCertificateDocumentId() {
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();

        Offers_Signed_Document_Attached__e event = 
            new Offers_Signed_Document_Attached__e();
        event.Envelop_Id__c = ENVELOP_ID_1;
        event.Content_Document_Id__c = '0695P0000002WgMQAU';
        event.File_Name__c = 'Title 1-' + CERTIFICATE_IDENTIFIER_SUBSTRING;

        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new SingleMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentsSelector = (ContentDocumentsSelector) Test.createStub(
            ContentDocumentsSelector.class, 
            new SingleCertificateContentDocumentsSelectorStub());
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
        handler.process(event);
        handler.execute();
        
        System.assertEquals(null, 
            quoteDaoMock.recordsUpdated[0].get('Final_Signed_Document_Id__c'), 
            'Expected Final Signed Document on Quote to be blank');
        System.assertNotEquals(null, 
            quoteDaoMock.recordsUpdated[0].get('DocuSign_Signed_Certificate_Document_Id__c'), 
            'Expected DocuSign Signed Certificate Document on Quote');
    }

    @isTest
    static void shouldUpdateTwoQuotesWithCertificateDocumentIdWhenTwoSignedDocCertEventsExist() {
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();

        Offers_Signed_Document_Attached__e event1 = 
            new Offers_Signed_Document_Attached__e();
        event1.Envelop_Id__c = ENVELOP_ID_1;
        event1.Content_Document_Id__c = '0695P0000002WgMQAU';
        event1.File_Name__c = 'Title 1-' + CERTIFICATE_IDENTIFIER_SUBSTRING;

        Offers_Signed_Document_Attached__e event2 = 
            new Offers_Signed_Document_Attached__e();
        event2.Envelop_Id__c = ENVELOP_ID_2;
        event2.Content_Document_Id__c = '0695P0000002WgMQAV';
        event2.File_Name__c = 'Title 2-' + CERTIFICATE_IDENTIFIER_SUBSTRING;


        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new TwoMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentsSelector = (ContentDocumentsSelector) Test.createStub(
            ContentDocumentsSelector.class, 
            new TwoCertificateDocumentContentDocumentSelectorSelectorStub());
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
        handler.process(event1);
        handler.process(event2);
        handler.execute();
        
        System.assertNotEquals(null, 
            quoteDaoMock.recordsUpdated[0].get('DocuSign_Signed_Certificate_Document_Id__c'), 
            'Expected DocuSign Certificate Document Id to be populated as the ' 
            + 'file should be classified as a docuSign certificate');
        System.assert(quoteDaoMock.recordsUpdated[0].get('DocuSign_Signed_Certificate_Document_Id__c') 
            != quoteDaoMock.recordsUpdated[1].get('DocuSign_Signed_Certificate_Document_Id__c'),
            'Expected different signed document Ids on 2 quotes as each ' 
            + 'there is only 1 signed document per quote/envelop Id.');
    }

    @isTest
    static void shouldUpdateTwoQuotesWhenOneOfTwoEventIsSignedAndTwoOfTwoIsCertDocId() {
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();

        Offers_Signed_Document_Attached__e event1 = 
            new Offers_Signed_Document_Attached__e();
        event1.Envelop_Id__c = ENVELOP_ID_1;
        event1.Content_Document_Id__c = '0695P0000002WgMQAU';
        event1.File_Name__c = 'Title 1';

        Offers_Signed_Document_Attached__e event2 = 
            new Offers_Signed_Document_Attached__e();
        event2.Envelop_Id__c = ENVELOP_ID_2;
        event2.Content_Document_Id__c = '0695P0000002WgMQAV';
        event2.File_Name__c = 'Title 2-' + CERTIFICATE_IDENTIFIER_SUBSTRING;


        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quotesSelector = (QuotesSelector) Test.createStub(
            QuotesSelector.class, 
            new TwoMatchingQuotesSelectorSelectorStub());
        handler.contentDocumentsSelector = (ContentDocumentsSelector) Test.createStub(
            ContentDocumentsSelector.class, 
            new OneSignedOneCertDocumentContentDocumentSelectorSelectorStub());
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
        handler.process(event1);
        handler.process(event2);
        handler.execute();
        

        Integer numOfQuotesWithFinalSignedDocId = 0;
        Integer numOfQuotesWithSignedCertDocId = 0;

        for (SBQQ__Quote__c result : (SBQQ__Quote__c[]) quoteDaoMock.recordsUpdated) {
            if (String.isNotBlank(result.DocuSign_Signed_Certificate_Document_Id__c)) {
                numOfQuotesWithSignedCertDocId += 1;
            }
            if (String.isNotBlank(result.Final_Signed_Document_Id__c)) {
                numOfQuotesWithFinalSignedDocId += 1;
            }
        }
        System.debug(quoteDaoMock.recordsUpdated);
        System.assertEquals(2, quoteDaoMock.recordsUpdated.size(), 
            'Expected 2 quotes to be updated');
        System.assertEquals(1, numOfQuotesWithFinalSignedDocId, 
            'Expected one final signed doc');
        System.assertEquals(1, numOfQuotesWithSignedCertDocId, 
            'Expected one signed certificate doc');
    }
    
    private class SingleMatchingQuotesSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectQuotesByPrimaryDocuSignEnvelopId method is called

            SBQQ__Quote__c quote = new SBQQ__Quote__c();
            quote.Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1;
            quote.SBQQ__PrimaryContact__c = [select Id from Contact where Person_ID_unique__c ='12341578' ].Id;
            insert quote;
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins_Completed.pdf',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
                );
            insert contentVersion;    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

            //create ContentDocumentLink  record 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = quote.id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'V';
            insert cdl;
             Id quoteId = [select Id from SBQQ__Quote__c].ID;
            return new List<SBQQ__Quote__c>{quote};
        }
        
    }

    private class TwoMatchingQuotesSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectQuotesByPrimaryDocuSignEnvelopId method is called

            SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
            quote1.Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1;
            quote1.SBQQ__PrimaryContact__c = [select Id from Contact where Person_ID_unique__c ='12341578' ].Id;

            SBQQ__Quote__c quote2 = new SBQQ__Quote__c();
            quote2.Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_2;
            quote2.SBQQ__PrimaryContact__c = [select Id from Contact where Person_ID_unique__c ='125754' ].Id;

            List<SBQQ__Quote__c> quoteList = new  List<SBQQ__Quote__c>();
            quoteList.add(quote1);
            quoteList.add(quote2);
            insert quoteList;
            return new List<SBQQ__Quote__c>{quote1, quote2};
        }
        
    }

    private class TwoMatchUsersSelectorStub implements System.StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assume selectUsersByContactId is called

            User user1 = new User();
            user1.Id = Id.valueOf('0050I000008F2cAQAS');
            user1.contactId =  [select Id from Contact where Person_ID_unique__c ='12341578' ].Id;
            
            User user2 = new User();
            user2.Id = Id.valueOf('005280000061WV9AAM');
            user2.contactId = [select Id from Contact where Person_ID_unique__c ='125754' ].Id;

            return new List<User>{user1, user2};
        }
    }

    private class SingleContentDocumentsSelectorStub implements System.StubProvider {

          public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectById method is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 1", "Id": "0695P0000002WgMQAU", "LatestPublishedVersionId":"0695P0000002WgMQAC"}';
            ContentDocument contentDocument1 = 
                        (ContentDocument) JSON.deserialize(contentDocument1Json, 
                        ContentDocument.class);
            return new List<ContentDocument>{contentDocument1};
        }

    }

    private class SingleCertificateContentDocumentsSelectorStub implements System.StubProvider {

          public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectById method is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Abc_Completed.pdf' 
                + CERTIFICATE_IDENTIFIER_SUBSTRING + '", "Id": "0695P0000002WgMQAU", "LatestPublishedVersionId":"0695P0000002WgMQAC"}';
            ContentDocument contentDocument1 = 
                        (ContentDocument) JSON.deserialize(contentDocument1Json, 
                        ContentDocument.class);
            return new List<ContentDocument>{contentDocument1};
        }

    }

    private class TwoSignedDocumentContentDocumentSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes List<ContentDocument> selectById(Set<Id> idSet) is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 1", "Id": "0695P0000002WgMQAU", "LatestPublishedVersionId":"0695P0000002WgMQAC"}';
            ContentDocument contentDocument1 = 
                        (ContentDocument) JSON.deserialize(contentDocument1Json, 
                        ContentDocument.class);

                String contentDocument2Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 2", "Id": "0695P0000002WgMQAV", "LatestPublishedVersionId":"0695P0000002WgMQAA"}';
            ContentDocument contentDocument2 = 
                        (ContentDocument) JSON.deserialize(contentDocument2Json, 
                        ContentDocument.class);

            return new List<ContentDocument>{contentDocument1, contentDocument2};
        }
    }

    private class TwoCertificateDocumentContentDocumentSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes List<ContentDocument> selectById(Set<Id> idSet) is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 1-'
                + CERTIFICATE_IDENTIFIER_SUBSTRING +'", "Id": "0695P0000002WgMQAU", "LatestPublishedVersionId":"0695P0000002WgMQAC"}';
            ContentDocument contentDocument1 = 
                        (ContentDocument) JSON.deserialize(contentDocument1Json, 
                        ContentDocument.class);

            String contentDocument2Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 2-'
                + CERTIFICATE_IDENTIFIER_SUBSTRING +'", "Id": "0695P0000002WgMQAV", "LatestPublishedVersionId":"0695P0000002WgMQAA"}';
            ContentDocument contentDocument2 = 
                        (ContentDocument) JSON.deserialize(contentDocument2Json, 
                        ContentDocument.class);

            return new List<ContentDocument>{contentDocument1, contentDocument2};
        }
    }

    private class OneSignedOneCertDocumentContentDocumentSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes List<ContentDocument> selectById(Set<Id> idSet) is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 1", "Id": "0695P0000002WgMQAU", "LatestPublishedVersionId":"0695P0000002WgMQAC"}';
            ContentDocument contentDocument1 = 
                        (ContentDocument) JSON.deserialize(contentDocument1Json, 
                        ContentDocument.class);

            String contentDocument2Json = 
                '{"attributes":{"type":"ContentDocument"}, "Title": "Title 2-'
                + CERTIFICATE_IDENTIFIER_SUBSTRING +'", "Id": "0695P0000002WgMQAV", "LatestPublishedVersionId":"0695P0000002WgMQAA"}';
            ContentDocument contentDocument2 = 
                        (ContentDocument) JSON.deserialize(contentDocument2Json, 
                        ContentDocument.class);

            return new List<ContentDocument>{contentDocument1, contentDocument2};
        }
    }

    private class TwoMatchingContentDocumentSelectorSelectorStub implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes List<ContentDocument> selectById(Set<Id> idSet) is called

            String contentDocument1Json = 
                '{"attributes":{"type":"ContentDocument"}, "Id": "0695P0000002WgMQAU", "Title": "Title 1"}';
            ContentDocument contentDocument1 = 
                        (ContentDocument) JSON.deserialize(contentDocument1Json, 
                        ContentDocument.class);

                String contentDocument2Json = 
                '{"attributes":{"type":"ContentDocument"}, "Id": "0695P0000002WgMQAV", "Title": "Title 2"}';
            ContentDocument contentDocument2 = 
                        (ContentDocument) JSON.deserialize(contentDocument2Json, 
                        ContentDocument.class);

            return new List<ContentDocument>{contentDocument1, contentDocument2};
        }
        
    }

    private class BulkUpdateQuoteApplicantDocumentsStub 
            implements System.StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {

            // assumes updateContentDocumentOwnerToApplicant is called
            System.debug('updateContentDocumentOwnerToApplicant called');
            return null;
        }
    }
    
    @isTest
    static void shouldCreateContactDocumentForQuote() {
      
        SObjectDaoMock quoteDaoMock = new SObjectDaoMock();
        SObjectDaoMock contactDocumentDaoMock = new SObjectDaoMock();
        SObjectDaoMock contactDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentLinkDaoMock = new SObjectDaoMock();
        SObjectDaoMock contentDocumentDaoMock = new SObjectDaoMock();
      
        Offers_Signed_Document_Attached__e event = 
            new Offers_Signed_Document_Attached__e();
        event.Envelop_Id__c = ENVELOP_ID_1;
        //event.Content_Document_Id__c = '0695P0000002WgMQAU';
        event.File_Name__c = 'test';
        OffersSignedDocAttachedTrigHandler handler = 
            new OffersSignedDocAttachedTrigHandler();
        handler.quoteDao = quoteDaoMock;
        handler.contentDocumentLinkDao = contentDocumentLinkDaoMock;
        handler.contentDocumentDao = contentDocumentDaoMock;
        handler.contactDocumentDao = contactDocumentDaoMock;
        handler.contactDocumentLinkDao = contactDocumentLinkDaoMock;
        handler.bulkUpdateQuoteApplicantDocuments = (BulkUpdateQuoteApplicantDocuments) Test.createStub(
            BulkUpdateQuoteApplicantDocuments.class, 
            new BulkUpdateQuoteApplicantDocumentsStub());
 			SBQQ__Quote__c quote = new SBQQ__Quote__c();
        	Id conId = [select Id from contact where Person_ID_unique__c ='12341578'].Id;
            quote.Primary_DocuSign_Envelop_Id__c = ENVELOP_ID_1;
            quote.SBQQ__PrimaryContact__c = [select Id from Contact where Person_ID_unique__c ='12341578' ].Id;
            insert quote;
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Test.pdf',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
                );
            insert contentVersion;    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

            //create ContentDocumentLink  record 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = quote.id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'V';
            insert cdl;      
        	Id quoteId = [select id from SBQQ__Quote__c].Id;
       		event.Content_Document_Id__c =
           [select Id, LinkedEntityId, LinkedEntity.name, ContentDocumentId , ContentDocument.title from 
            ContentDocumentLink where LinkedEntityId =:quoteId].ContentDocumentId;
       		handler.process(event);
        	handler.execute();
        	System.assertEquals(1, contactDocumentDaoMock.recordsInserted.size(), 
            'Expected 1 Contact doc  to be created');
    }

}