/**
 * @description Test class for FakeRecordIdGenerator
 */
@isTest(isParallel=true)
public class FakeRecordIdGenerator_Test {

    @isTest
    static void shouldGenerateFakeAccountRecordId() {
        Id fakeAccountRecordId = FakeRecordIdGenerator.generateId(
            Account.getSObjectType()
        );
        System.assertNotEquals(null, fakeAccountRecordId, 
            'Expected a fake account id to be generated');
    }

    @isTest
    static void shouldGenerateFakeContactRecordId() {
        Id fakeContactRecordId = FakeRecordIdGenerator.generateId(
            Contact.getSObjectType()
        );
        System.assertNotEquals(null, fakeContactRecordId, 
            'Expected a fake contact id to be generated');
    }

    @isTest
    static void shouldGenerateTwoDifferentFakeRecordIdsForSameObjectWhenExecutedTwice() {
        Id fakeContactRecordId1 = FakeRecordIdGenerator.generateId(
            Contact.getSObjectType()
        );
        Id fakeContactRecordId2 = FakeRecordIdGenerator.generateId(
            Contact.getSObjectType()
        );

        System.assert(fakeContactRecordId1 != fakeContactRecordId2, 
            'Expected two different contact record ids to be generated when ' 
            + 'executed twice'
        );
    }

    @isTest
    static void shouldGenerateTwoDifferentFakeRecordIdsForDiffObjectWhenExecuted() {
        Id fakeContactRecordId = FakeRecordIdGenerator.generateId(
            Contact.getSObjectType()
        );
        Id fakeAccountRecordId = FakeRecordIdGenerator.generateId(
            Account.getSObjectType()
        );

        System.assert(fakeContactRecordId != fakeAccountRecordId, 
            'Expected two different record ids to be generated when ' 
            + 'executed together for different objects'
        );
    }

    @isTest
    static void shouldGenerateManyFakeRecordIdsInASingleTransaction() {
        Id lastFakeIdGenerated = null;
        for (Integer i = 0; i< 2000; i++) {
            lastFakeIdGenerated = FakeRecordIdGenerator.generateId(
                Account.getSObjectType()
            );
        }
        System.assertNotEquals(null, lastFakeIdGenerated, 
            'Expected fake Ids to be generated when executed 2000 times.');
    }

}