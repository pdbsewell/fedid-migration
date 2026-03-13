/**
 * @description Test class for OfferGrantScholarshipQuotaService
 */
@isTest(isParallel=true)
public class OfferGrantScholarshipQuotaService_Test {

    private static final Id SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_GRANT_1_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());
    
    private static final Id SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_2 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_2_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());
    
    private static final Id SIGNED_QUOTE_ID_WITH_UNCAPPED_SCHOLARSHIP_3 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id UNCAPPED_SCHOLARSHIP_3_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());
        
    private static final Id SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_4 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_5 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_4_AND_5_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());
        
    private static final Id REJECTED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_6 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_6_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());

    private static final Id CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_7_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());

        
    private static final Id EXPIRED_REGEN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_8 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_8_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());
    
    private static final Id EXPIRED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_9 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_9_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());

    private static final Id DEFERRED_AFTER_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_10 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_10_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());

    private static final Id DEFERRED_BEFORE_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_11 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_SCHOLARSHIP_11_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());

    private static final Id IN_REVIEW_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_12 = 
        FakeRecordIdGenerator.generateId(SBQQ__Quote__c.getSObjectType());
    private static final Id CAPPED_GRANT_12_ID = 
        FakeRecordIdGenerator.generateId(Product2.getSObjectType());

    @isTest
    static void shouldUpdateSingleSignedQuoteCappedGrantQuotaCorrectly() {
        
        SBQQ__Quote__c signedQuote = new SBQQ__Quote__c();
        signedQuote.id = SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1;
        signedQuote.SBQQ__Status__c = 'Signed';

        SBQQ__Quote__c oldSignedQuote = new SBQQ__Quote__c();
        oldSignedQuote.id = SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1;
        oldSignedQuote.SBQQ__Status__c = 'In Review';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote signedCappedGrantQuote = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(signedQuote, oldSignedQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1, 
            signedCappedGrantQuote
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedGrant = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_GRANT_1_ID, updatedGrant.Id,
            'Expected grant Id that was updated to match'
        );
        System.assertEquals(1, updatedGrant.Quota_Accepted__c, 
            'Expected accepted to have one added because quote is signed'
        );
        System.assertEquals(0, updatedGrant.Quota_Assigned__c, 
            'Expected assigned to have one removed because quote is signed so '
            + 'the assignment should move from assigned to accepted'
        );
    }

    @isTest
    static void shouldUpdateSingleSignedQuoteCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c signedQuote = new SBQQ__Quote__c();
        signedQuote.id = SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_2;
        signedQuote.SBQQ__Status__c = 'Signed';

        SBQQ__Quote__c oldSignedQuote = new SBQQ__Quote__c();
        oldSignedQuote.id = SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_2;
        oldSignedQuote.SBQQ__Status__c = 'In Review';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote signedCappedScholarshipQuota = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(signedQuote, oldSignedQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_2, 
            signedCappedScholarshipQuota
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_SCHOLARSHIP_2_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(21, updatedScholarship.Quota_Accepted__c, 
            'Expected accepted to have one added because quote is signed'
        );
        System.assertEquals(9, updatedScholarship.Quota_Assigned__c, 
            'Expected assigned to have one removed because quote is signed so '
            + 'the assignment should move from assigned to accepted'
        );
    }

    @isTest
    static void shouldNotUpdateSingleSignedQuoteUncappedScholarshipQuota() {
        
        SBQQ__Quote__c signedQuote = new SBQQ__Quote__c();
        signedQuote.id = SIGNED_QUOTE_ID_WITH_UNCAPPED_SCHOLARSHIP_3;
        signedQuote.SBQQ__Status__c = 'Signed';

        SBQQ__Quote__c oldSignedQuote = new SBQQ__Quote__c();
        oldSignedQuote.id = SIGNED_QUOTE_ID_WITH_UNCAPPED_SCHOLARSHIP_3;
        oldSignedQuote.SBQQ__Status__c = 'In Review';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote signedUncappedScholarshipQuote = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(signedQuote, oldSignedQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            SIGNED_QUOTE_ID_WITH_UNCAPPED_SCHOLARSHIP_3, 
            signedUncappedScholarshipQuote
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        System.assertEquals(true, productDaoMock.recordsUpdated.isEmpty(),
            'Expected no updates to the scholarship because the scholarship '
            + 'type is uncapped and therefore does not have any quotas'
        );
    }

    @isTest
    static void shouldUpdateTwoSignedQuoteSameCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c signedQuote4 = new SBQQ__Quote__c();
        signedQuote4.id = SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_4;
        signedQuote4.SBQQ__Status__c = 'Signed';

        SBQQ__Quote__c oldSignedQuote4 = new SBQQ__Quote__c();
        oldSignedQuote4.id = SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_4;
        oldSignedQuote4.SBQQ__Status__c = 'In Review';

        SBQQ__Quote__c signedQuote5 = new SBQQ__Quote__c();
        signedQuote5.id = SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_5;
        signedQuote5.SBQQ__Status__c = 'Signed';

        SBQQ__Quote__c oldSignedQuote5 = new SBQQ__Quote__c();
        oldSignedQuote5.id = SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_5;
        oldSignedQuote5.SBQQ__Status__c = 'In Review';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote signedCappedScholarshipQuota4 = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(signedQuote4, oldSignedQuote4);
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote signedCappedScholarshipQuota5 = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(signedQuote5, oldSignedQuote5);

        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        
        quoteWithOldQuoteByIds.put(
            SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_4, 
            signedCappedScholarshipQuota4
        );

        quoteWithOldQuoteByIds.put(
            SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_5, 
            signedCappedScholarshipQuota5
        );

        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(1, productDaoMock.recordsUpdated.size(),
            'Expected one product (Scholarship) to be updated because both '
            + ' quotes point to the same scholarship'
        );

        System.assertEquals(CAPPED_SCHOLARSHIP_4_AND_5_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(102, updatedScholarship.Quota_Accepted__c, 
            'Expected accepted to have two added because two different quote'
            + ' were signed with the same scholarship'
        );
        System.assertEquals(78, updatedScholarship.Quota_Assigned__c, 
            'Expected assigned to have two removed because two different quote'
            + ' were signed with the same scholarship'
        );
    }

    @isTest
    static void shouldUpdateSingleRejectedQuoteCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c rejectedQuote = new SBQQ__Quote__c();
        rejectedQuote.id = REJECTED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_6;
        rejectedQuote.SBQQ__Status__c = 'Rejected';

        SBQQ__Quote__c oldRejectedQuote = new SBQQ__Quote__c();
        oldRejectedQuote.id = REJECTED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_6;
        oldRejectedQuote.SBQQ__Status__c = 'In Review';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote rejectedCappedScholarshipQuota = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(rejectedQuote, oldRejectedQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            REJECTED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_6, 
            rejectedCappedScholarshipQuota
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_SCHOLARSHIP_6_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(6, updatedScholarship.Quota_Assigned__c, 
            'Expected assigned to have one removed because quote is rejected so '
            + 'the it should free up a scholarship quota'
        );
    }

    @isTest
    static void shouldUpdateSingleCancelledQuoteCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c cancelledQuote = new SBQQ__Quote__c();
        cancelledQuote.id = CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7;
        cancelledQuote.SBQQ__Status__c = 'Cancelled';

        SBQQ__Quote__c oldCancelledQuote = new SBQQ__Quote__c();
        oldCancelledQuote.id = CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7;
        oldCancelledQuote.SBQQ__Status__c = 'In Review';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote cancelledCappedScholarshipQuota = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(cancelledQuote, oldCancelledQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7, 
            cancelledCappedScholarshipQuota
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_SCHOLARSHIP_7_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(0, updatedScholarship.Quota_Assigned__c, 
            'Expected assigned to have one removed because quote is cancelled so '
            + 'the it should free up a scholarship quota'
        );
    }

    @isTest
    static void shouldUpdateSingleExpiredRegenQuoteCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c expiredAndRegenQuote = new SBQQ__Quote__c();
        expiredAndRegenQuote.id = EXPIRED_REGEN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_8;
        expiredAndRegenQuote.SBQQ__Status__c = 'Expired and regenerated';

        SBQQ__Quote__c oldExpiredAndRegenQuote = new SBQQ__Quote__c();
        oldExpiredAndRegenQuote.id = EXPIRED_REGEN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_8;
        oldExpiredAndRegenQuote.SBQQ__Status__c = 'Published';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote expiredRegenCappedScholarshipQuota = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(expiredAndRegenQuote, oldExpiredAndRegenQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            EXPIRED_REGEN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_8, 
            expiredRegenCappedScholarshipQuota
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_SCHOLARSHIP_8_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(0, updatedScholarship.Quota_Assigned__c, 
            'Expected assigned to have one removed because quote is expired '
            + ' and regenerated so the it should free up a scholarship quota'
        );
    }

    @isTest
    static void shouldUpdateSingleExpiredQuoteCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c expiredQuote = new SBQQ__Quote__c();
        expiredQuote.id = EXPIRED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_9;
        expiredQuote.SBQQ__Status__c = 'Expired';

        SBQQ__Quote__c oldExpiredQuote = new SBQQ__Quote__c();
        oldExpiredQuote.id = EXPIRED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_9;
        oldExpiredQuote.SBQQ__Status__c = 'Published';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote expiredCappedScholarshipQuota = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(expiredQuote, oldExpiredQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            EXPIRED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_9, 
            expiredCappedScholarshipQuota
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_SCHOLARSHIP_9_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(998, updatedScholarship.Quota_Assigned__c, 
            'Expected assigned to have one removed because quote is expired '
            + ' so the it should free up a scholarship quota'
        );
    }

    @isTest
    static void shouldUpdateSingleDeferredAfterSignQuoteCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c deferredAfterSignQuote = new SBQQ__Quote__c();
        deferredAfterSignQuote.id = DEFERRED_AFTER_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_10;
        deferredAfterSignQuote.SBQQ__Status__c = 'Deferred';

        SBQQ__Quote__c oldDeferredAfterSignQuote = new SBQQ__Quote__c();
        oldDeferredAfterSignQuote.id = DEFERRED_AFTER_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_10;
        oldDeferredAfterSignQuote.SBQQ__Status__c = 'Signed';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote deferredSignedCappedScholarshipQuota = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(deferredAfterSignQuote, oldDeferredAfterSignQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            DEFERRED_AFTER_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_10, 
            deferredSignedCappedScholarshipQuota
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_SCHOLARSHIP_10_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(4, updatedScholarship.Quota_Accepted__c, 
            'Expected accepted to have one removed because quote is deferred '
            + ' after it was signed so the it should free up a scholarship quota'
        );
    }

    @isTest
    static void shouldUpdateSingleDeferredBeforeSignQuoteCappedScholarshipQuotaCorrectly() {
        
        SBQQ__Quote__c deferredBeforeSignQuote = new SBQQ__Quote__c();
        deferredBeforeSignQuote.id = DEFERRED_BEFORE_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_11;
        deferredBeforeSignQuote.SBQQ__Status__c = 'Deferred';

        SBQQ__Quote__c oldDeferredBeforeSignQuote = new SBQQ__Quote__c();
        oldDeferredBeforeSignQuote.id = DEFERRED_BEFORE_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_11;
        oldDeferredBeforeSignQuote.SBQQ__Status__c = 'Published';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote deferredNotSignedCappedScholarshipQuota = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(
                deferredBeforeSignQuote, oldDeferredBeforeSignQuote
            );
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            DEFERRED_BEFORE_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_11, 
            deferredNotSignedCappedScholarshipQuota
        );
        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        System.assertEquals(CAPPED_SCHOLARSHIP_11_ID, updatedScholarship.Id,
            'Expected scholarship Id that was updated to match'
        );
        System.assertEquals(256, updatedScholarship.Quota_Assigned__c, 
            'Expected assigned to have one removed because quote is deferred '
            + ' before it was signed so the it should free up a scholarship quota'
        );
    }

    @isTest
    static void shouldUpdateTwoDifferentSignedQuotDifferentQuotaCorrectly() {
        
        SBQQ__Quote__c signedQuoteGrant1 = new SBQQ__Quote__c();
        signedQuoteGrant1.id = SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1;
        signedQuoteGrant1.SBQQ__Status__c = 'Signed';

        SBQQ__Quote__c oldSignedQuoteGrant1 = new SBQQ__Quote__c();
        oldSignedQuoteGrant1.id = SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1;
        oldSignedQuoteGrant1.SBQQ__Status__c = 'In Review';

        SBQQ__Quote__c cancelledQuoteScholarship7 = new SBQQ__Quote__c();
        cancelledQuoteScholarship7.id = CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7;
        cancelledQuoteScholarship7.SBQQ__Status__c = 'Rejected';

        SBQQ__Quote__c oldCancelledQuoteScholarship7 = new SBQQ__Quote__c();
        oldCancelledQuoteScholarship7.id = CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7;
        oldCancelledQuoteScholarship7.SBQQ__Status__c = 'In Review';


        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote signedCappedGrantQuota1 = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(
                signedQuoteGrant1, oldSignedQuoteGrant1
            );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote cancelledCappedScholarshipQuota7 = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(
                cancelledQuoteScholarship7, oldCancelledQuoteScholarship7
            );

        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        
        quoteWithOldQuoteByIds.put(
            SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1, 
            signedCappedGrantQuota1
        );

        quoteWithOldQuoteByIds.put(
            CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7, 
            cancelledCappedScholarshipQuota7
        );

        quotaService.updateQuota(quoteWithOldQuoteByIds);

        Product2 updatedScholarship = (Product2) productDaoMock.recordsUpdated[0];

        Set<ProductResult> expectedResults = new Set<ProductResult>();
        
        ProductResult signedQuoteGrantResult = new ProductResult(
            CAPPED_GRANT_1_ID, 1, 0
        );
        expectedResults.add(signedQuoteGrantResult);
        
        ProductResult cancelledQuoteScholarshipResult = new ProductResult(
            CAPPED_SCHOLARSHIP_7_ID, 0, 0
        );
        expectedResults.add(cancelledQuoteScholarshipResult);

        Set<ProductResult> results = new Set<ProductResult>();
        for (Product2 productsUpdated : 
                (List<Product2>) productDaoMock.recordsUpdated) {
            ProductResult result = new ProductResult(
                productsUpdated.Id,
                productsUpdated.Quota_Accepted__c,
                productsUpdated.Quota_Assigned__c
            );
            results.add(result);
        }

        System.assertEquals(2, productDaoMock.recordsUpdated.size(),
            'Expected two different products (Scholarship/Grant) to be updated '
            + 'because the two quotes are referencing different grant/'
            + 'scholarship'
        );
        System.assertEquals(
            true, 
            results.contains(signedQuoteGrantResult), 
            'Expected signed quote grant\'s quota to be updated correctly'
        );
        System.assertEquals(
            true, 
            results.contains(cancelledQuoteScholarshipResult), 
            'Expected cancelled quote scholarship\'s quota to be updated correctly'
        );
    }

    @isTest
    static void shouldThrowIllegalArgumentExceptionOnQuoteWithOldQuoteWhenQuoteDoesNotMatchOldQuoteId() {
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Id = SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1;

        SBQQ__Quote__c differentQuote = new SBQQ__Quote__c();
        differentQuote.Id = DEFERRED_BEFORE_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_11;

        try {
            OfferGrantScholarshipQuotaService.QuoteWithOldQuote mismatchQuote = 
                new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(
                    quote, differentQuote
                );
            System.assert(false, 
                'Expected IllegalArgumentException because the quote ids do '
                + 'not match and therefore the old quote is not really an '
                + 'old quote of the quote'
            );
        } catch (IllegalArgumentException e) {
            System.assert(true, 
                'Expected IllegalArgumentException because the quote ids do '
                + 'not match and therefore the old quote is not really an '
                + 'old quote of the quote'
            );
        } catch (Exception e) {
            System.assert(false, 
                'Expected IllegalArgumentException because the quote ids do '
                + 'not match and therefore the old quote is not really an '
                + 'old quote of the quote'
            );
        }
    }

    @isTest
    static void shouldIllegalArgumentExceptionWhenThereIsNoMatchingQuotaStrategy() {
        // assumes code calling the OfferGrantScholarshipQuotaService will
        // filter out the invalid ones, this unit test tests a validation 
        // if something was not filtered properly
        SBQQ__Quote__c reviewQuote = new SBQQ__Quote__c();
        reviewQuote.id = IN_REVIEW_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_12;
        reviewQuote.SBQQ__Status__c = 'In Review';

        SBQQ__Quote__c oldReviewQuote = new SBQQ__Quote__c();
        oldReviewQuote.id = IN_REVIEW_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_12;
        oldReviewQuote.SBQQ__Status__c = 'Processing';

        QuoteLinesSelector quoteLinesSelectorStub = (QuoteLinesSelector) Test.createStub(
            QuoteLinesSelector.class,
            new QuoteLinesSelectorStub()
        );
        SObjectDaoMock productDaoMock = new SObjectDaoMock();

        OfferGrantScholarshipQuotaService quotaService = new OfferGrantScholarshipQuotaService(
            quoteLinesSelectorStub,
            productDaoMock
        );
        
        OfferGrantScholarshipQuotaService.QuoteWithOldQuote reviewCappedGrantQuote = 
            new OfferGrantScholarshipQuotaService.QuoteWithOldQuote(reviewQuote, oldReviewQuote);
        Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote> quoteWithOldQuoteByIds = 
            new Map<Id, OfferGrantScholarshipQuotaService.QuoteWithOldQuote>();
        quoteWithOldQuoteByIds.put(
            IN_REVIEW_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_12, 
            reviewCappedGrantQuote
        );

        try {
            quotaService.updateQuota(quoteWithOldQuoteByIds);
            System.assert(false, 
                'Expected illegal argument exception because no strategy has '
                + 'been implmented for quotes in review as quotes in review '
                + 'should not have their quota\'s changed'
            );
        } catch (IllegalArgumentException e) {
            System.assert(true, 
                'Expected illegal argument exception because no strategy has '
                + 'been implmented for quotes in review as quotes in review '
                + 'should not have their quota\'s changed'
            );
        } catch (Exception e) {
            System.assert(false, 
                'Expected illegal argument exception because no strategy has '
                + 'been implmented for quotes in review as quotes in review '
                + 'should not have their quota\'s changed'
            );
        }

    }

    private class ProductResult {
        private Id id;
        private Integer quotaAccepted;
        private Integer quotaAssigned;

        public ProductResult(Id id, Decimal quotaAccepted, Decimal quotaAssigned) {
            // quota numbers are always whole numbers, but just represented in 
            // Salesforce as decimal
            this(
                id,
                Integer.valueOf(quotaAccepted),
                Integer.valueOf(quotaAssigned)
            );
        }

        public ProductResult(Id id, Integer quotaAccepted, Integer quotaAssigned) {
            this.id = id;
            // Treat null as 0 for hashcode, it doesn't matter too much 
            // as this is only used for unit testing
            if (quotaAccepted != null) {
                this.quotaAccepted = quotaAccepted;
            } else {
                this.quotaAccepted = 0;
            }
            if (quotaAssigned != null) {
                this.quotaAssigned = quotaAssigned;
            } else {
                this.quotaAssigned = 0;
            }
        }

        public Boolean equals(Object obj){
            if (obj instanceof ProductResult) {
                ProductResult otherProductResult = (ProductResult) obj;
                return (
                    this.id == otherProductResult.id 
                    && this.quotaAccepted == otherProductResult.quotaAccepted 
                    && this.quotaAssigned == otherProductResult.quotaAssigned
                );
            }
            return false;
        }

        public Integer hashCode() {
            // apparently hashcode for record id is broken in Salesforce 
            // at the time of this implementation
            // https://salesforce.stackexchange.com/questions/327876/system-hashcode-still-broken-for-id
            // https://trailblazer.salesforce.com/issues_view?id=a1p300000008YQ0AAM
            // workaround applied
            return System.hashCode(String.valueOf(this.Id)) + this.quotaAccepted * 31 + this.quotaAssigned;
        }
    }

    private class QuoteLinesSelectorStub implements System.StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method selectByIdWithQuoteLines is called
            if (!listOfArgs.isEmpty()) {
                List<SBQQ__QuoteLine__c> queryResults = new List<SBQQ__QuoteLine__c>();

                Set<Id> quoteQueryIds = (Set<Id>) listOfArgs[0];
                SObjectMockBuilder quoteLineBuilder = new SObjectMockBuilder(SBQQ__QuoteLine__c.class);

                if (quoteQueryIds.contains(SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1)) {
                    
                    SBQQ__QuoteLine__c signedQuoteLineCappedGrant1 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Grant')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_GRANT_1_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, SIGNED_QUOTE_ID_WITH_CAPPED_GRANT_1)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_GRANT_1_ID)
                                    .with(Product2.Quota_Accepted__c, 0)
                                    .with(Product2.Quota_Assigned__c, 1)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(signedQuoteLineCappedGrant1);

                }
                if (quoteQueryIds.contains(SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_2)) {

                    SBQQ__QuoteLine__c signedQuoteLineCappedScholarship2 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_2_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_2)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_2_ID)
                                    .with(Product2.Quota_Accepted__c, 20)
                                    .with(Product2.Quota_Assigned__c, 10)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(signedQuoteLineCappedScholarship2);

                }
                if(quoteQueryIds.contains(SIGNED_QUOTE_ID_WITH_UNCAPPED_SCHOLARSHIP_3)) {
                    SBQQ__QuoteLine__c signedQuoteLineUncappedScholarship3 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, UNCAPPED_SCHOLARSHIP_3_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, SIGNED_QUOTE_ID_WITH_UNCAPPED_SCHOLARSHIP_3)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, UNCAPPED_SCHOLARSHIP_3_ID)
                                    .with(Product2.Type__c, 'Uncapped')
                                    .create()
                            ).create();
                    queryResults.add(signedQuoteLineUncappedScholarship3);
                }
                if (quoteQueryIds.contains(SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_4)) {

                    SBQQ__QuoteLine__c signedQuoteLineCappedScholarship4 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_4_AND_5_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_4)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_4_AND_5_ID)
                                    .with(Product2.Quota_Accepted__c, 100)
                                    .with(Product2.Quota_Assigned__c, 80)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(signedQuoteLineCappedScholarship4);

                }
                if (quoteQueryIds.contains(SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_5)) {

                    SBQQ__QuoteLine__c signedQuoteLineCappedScholarship5 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_4_AND_5_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, SIGNED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_5)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_4_AND_5_ID)
                                    .with(Product2.Quota_Accepted__c, 100)
                                    .with(Product2.Quota_Assigned__c, 80)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(signedQuoteLineCappedScholarship5);
                }
                if (quoteQueryIds.contains(REJECTED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_6)) {

                    SBQQ__QuoteLine__c rejectedQuoteLineCappedScholarship6 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_6_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, REJECTED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_6)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_6_ID)
                                    .with(Product2.Quota_Accepted__c, 40)
                                    .with(Product2.Quota_Assigned__c, 7)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(rejectedQuoteLineCappedScholarship6);

                }

                if (quoteQueryIds.contains(CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7)) {

                    SBQQ__QuoteLine__c rejectedQuoteLineCappedScholarship7 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_7_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, CANCELLED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_7)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_7_ID)
                                    .with(Product2.Quota_Accepted__c, 0)
                                    .with(Product2.Quota_Assigned__c, 1)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(rejectedQuoteLineCappedScholarship7);

                }

                if (quoteQueryIds.contains(EXPIRED_REGEN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_8)) {

                    SBQQ__QuoteLine__c expiredRegenQuoteLineCappedScholarship8 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_8_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, EXPIRED_REGEN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_8)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_8_ID)
                                    .with(Product2.Quota_Accepted__c, 0)
                                    .with(Product2.Quota_Assigned__c, 1)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(expiredRegenQuoteLineCappedScholarship8);

                }

                if (quoteQueryIds.contains(EXPIRED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_9)) {

                    SBQQ__QuoteLine__c expiredQuoteLineCappedScholarship9 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_9_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, EXPIRED_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_9)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_9_ID)
                                    .with(Product2.Quota_Accepted__c, 0)
                                    .with(Product2.Quota_Assigned__c, 999)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(expiredQuoteLineCappedScholarship9);

                }

                if (quoteQueryIds.contains(DEFERRED_AFTER_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_10)) {

                    SBQQ__QuoteLine__c deferredAfterSignQuoteLineCappedScholarship10 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_10_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, DEFERRED_AFTER_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_10)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_10_ID)
                                    .with(Product2.Quota_Accepted__c, 5)
                                    .with(Product2.Quota_Assigned__c, 800)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(deferredAfterSignQuoteLineCappedScholarship10);

                }

                if (quoteQueryIds.contains(DEFERRED_BEFORE_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_11)) {

                    SBQQ__QuoteLine__c deferredBeforeSignQuoteLineCappedScholarship11 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Scholarship')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_SCHOLARSHIP_11_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, DEFERRED_BEFORE_SIGN_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_11)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_SCHOLARSHIP_11_ID)
                                    .with(Product2.Quota_Accepted__c, 838)
                                    .with(Product2.Quota_Assigned__c, 257)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(deferredBeforeSignQuoteLineCappedScholarship11);

                }

                if (quoteQueryIds.contains(IN_REVIEW_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_12)) {

                    SBQQ__QuoteLine__c inReviewQuoteLineCappedGrant12 = 
                        (SBQQ__QuoteLine__c) quoteLineBuilder
                            .with(SBQQ__QuoteLine__c.SBQQ__ProductFamily__c, 'Grant')
                            .with(SBQQ__QuoteLine__c.SBQQ__Product__c, CAPPED_GRANT_12_ID)
                            .with(SBQQ__QuoteLine__c.SBQQ__Quote__c, IN_REVIEW_QUOTE_ID_WITH_CAPPED_SCHOLARSHIP_12)
                            .withParentRelationship(
                                SBQQ__QuoteLine__c.SBQQ__Product__c,
                                new SObjectMockBuilder(Product2.class)
                                    .with(Product2.Id, CAPPED_GRANT_12_ID)
                                    .with(Product2.Quota_Accepted__c, 80)
                                    .with(Product2.Quota_Assigned__c, 30)
                                    .with(Product2.Type__c, 'Capped')
                                    .create()
                            ).create();
                    queryResults.add(inReviewQuoteLineCappedGrant12);

                }

                return queryResults;
            }
            return null;

        }
    }

}