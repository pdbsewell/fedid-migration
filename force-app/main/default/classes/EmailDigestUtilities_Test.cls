/**
 * @author      Tom Gangemi
 * @date        2023-06-09
 * @group       Test
 **/
@IsTest
public with sharing class EmailDigestUtilities_Test {

    private static Case createCase(Id ownerId, Datetime mockCreatedDate) {
        Case c = (Case)MonConTestDataFactory.createSObject(new Case());
        c.Id = fflib_IDGenerator.generate(Case.getSObjectType());
        c.OwnerId = ownerId;
        if(mockCreatedDate != null) {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(c));
            m.put('CreatedDate', mockCreatedDate);
            c = (Case)JSON.deserialize(JSON.serialize(m), Case.class);
        }
        return c;
    }

    private static Case createCase(Id ownerId) {
        return createCase(ownerId, null);
    }

    final static String PREFIX = 'test';

    @IsTest
    public static void testDigestTrackingCleanup() {
        // Arrange
        Id userId = fflib_IDGenerator.generate(User.getSObjectType());
        Case doiCase01 = createCase(null);
        Case doiCase02 = createCase(null);
        Case doiCase03 = createCase(null);

        EmailDigestUtilities.Digest[] digests = new EmailDigestUtilities.Digest[]{
            new EmailDigestUtilities.Digest(userId, new Case[]{
                doiCase01, doiCase02, doiCase03
            })
        };
        EmailDigestUtilities.markAsSent(PREFIX, digests);

        // Act - Test Before Cutoff
        EmailDigestUtilities.removeOldDigestTracking(PREFIX, 8);

        // Assert
        Apex_Job_Tracking__c[] ajtResults = [SELECT Id FROM Apex_Job_Tracking__c];
        System.assertEquals(3, ajtResults.size());

        // Arrange
        for(Apex_Job_Tracking__c ajt :ajtResults) {
            Test.setCreatedDate(ajt.Id, Datetime.now().addDays(-9));
        }

        // Act - Test After Cutoff
        EmailDigestUtilities.removeOldDigestTracking(PREFIX, 8);

        // Assert
        System.assertEquals(0, [SELECT Id FROM Apex_Job_Tracking__c].size());
    }

    @IsTest
    public static void testDigestTracking() {
        // GIVEN
        Id userId1 = fflib_IDGenerator.generate(User.getSObjectType());
        Id userId2 = fflib_IDGenerator.generate(User.getSObjectType());
        Id userId3 = fflib_IDGenerator.generate(User.getSObjectType());
        Case doiCase01 = createCase(userId1);
        Case doiCase02 = createCase(userId1);
        Case doiCase03 = createCase(userId2);
        Case doiCase04 = createCase(userId1);
        Case doiCase05 = createCase(userId2);
        Case doiCase06 = createCase(userId3);

        Map<Id, EmailDigestUtilities.Digest> digests = new Map<Id, EmailDigestUtilities.Digest>{
            userId1 => new EmailDigestUtilities.Digest(userId1, new Case[]{doiCase01, doiCase02, doiCase04}),
            userId2 => new EmailDigestUtilities.Digest(userId2, new Case[]{doiCase03, doiCase05}),
            userId3 => new EmailDigestUtilities.Digest(userId3, new Case[]{doiCase06})
        };
        Map<Id, EmailDigestUtilities.Digest> sentDigests = new Map<Id, EmailDigestUtilities.Digest>{
            userId1 => new EmailDigestUtilities.Digest(userId1, new Case[]{doiCase01, doiCase02}),
            userId2 => new EmailDigestUtilities.Digest(userId2, new Case[]{doiCase03}),
            userId3 => new EmailDigestUtilities.Digest(userId3, new Case[]{doiCase06})
        };

        // WHEN - Digest 3 cases then check previously sent
        EmailDigestUtilities.markAsSent(PREFIX, sentDigests.values());
        EmailDigestUtilities.filterPreviouslySent(PREFIX, digests, false);

        // THEN
        Assert.areEqual(3, digests.size());
        Assert.isTrue(digests.get(userId1).previouslySentTimeById.get(doiCase01.Id) != null);
        Assert.isTrue(digests.get(userId3).previouslySentTimeById.get(doiCase06.Id) != null);

        // WHEN - Remove the previously sent digests
        EmailDigestUtilities.filterPreviouslySent(PREFIX, digests, true);

        // THEN
        Assert.areEqual(2, digests.size());
        Assert.isTrue(digests.containsKey(userId1));
        Assert.areEqual(1, digests.get(userId1).casesById.size());
        Assert.areEqual(doiCase04, digests.get(userId1).casesById.get(doiCase04.Id));

        Assert.isTrue(digests.containsKey(userId2));
        Assert.areEqual(1, digests.get(userId2).casesById.size());
        Assert.areEqual(doiCase05, digests.get(userId2).casesById.get(doiCase05.Id));

        // GIVEN - Logging Test
        final String TEST_SOURCE = 'TEST_SOURCE';
        final String TEST_MSG_SHORT = 'Short Message';
        final String TEST_MSG_LONG = 'Long Message';

        // WHEN
        EmailDigestUtilities.insertLog(TEST_SOURCE, 'tfunc', TEST_MSG_SHORT, TEST_MSG_LONG);

        // THEN - Check sobject record and file attachment
        Exception_Log__c logResult = [SELECT Input__c FROM Exception_Log__c WHERE Source_Type__c = :TEST_SOURCE];
        Assert.areEqual(TEST_MSG_SHORT, logResult.Input__c);
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :logResult.Id].ContentDocumentId;
        ContentVersion cvResult = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId];
        Assert.areEqual(TEST_MSG_LONG, cvResult.VersionData.toString());
    }
}