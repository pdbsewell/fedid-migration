/**
 * @description Class to generate fake Salesforce record Ids for unit testing
 * purposes
 */
public class FakeRecordIdGenerator {
    
    private static Decimal recordIdIncrement = 0;

    /**
     * @description Generates a fake record Id
     * @param sObjectType The sObjectType of the object
     * @return Returns a fake record Id
     */
    public static Id generateId(Schema.SObjectType sObjectType) {
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        recordIdIncrement += 1;
        String fakeIdPrefix = '000000000000'.substring(
            0, 12 - recordIdIncrement.precision()
        );
        return Id.valueOf(keyPrefix + fakeIdPrefix + recordIdIncrement);
    }

}