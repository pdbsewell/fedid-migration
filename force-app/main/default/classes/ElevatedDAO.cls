/**
 * @description Common DML without sharing
 * @author      Kai-Fan Hsieh
 * @since       03 July 2024
 */
public without sharing class ElevatedDAO {
    /**
     * @description Insert records bypassing sharing rules. Avoid using AccessLevel.USER_MODE, as it will enforce sharing.
     * @param records : SObject records
     * @return `List<Database.SaveResult>`
     */
    public List<Database.SaveResult> insertRecords(List<SObject> records) {
        return Database.insert(records);
    }

    /**
     * @description Insert record bypassing sharing rules. Avoid using AccessLevel.USER_MODE, as it will enforce sharing.
     * @param record : SObject record
     * @return `Database.SaveResult`
     */
    public Database.SaveResult insertRecord(SObject record) {
        return Database.insert(record);
    }

    /**
     * @description Update records bypassing sharing rules. Avoid using AccessLevel.USER_MODE, as it will enforce sharing.
     * @param records : SObject records
     * @return `List<Database.SaveResult>`
     */
    public List<Database.SaveResult> updateRecords(List<SObject> records) {
        return Database.update(records);
    }

    /**
     * @description Update record bypassing sharing rules. Avoid using AccessLevel.USER_MODE, as it will enforce sharing.
     * @param record : SObject record
     * @return `Database.SaveResult`
     */
    public Database.SaveResult updateRecord(SObject record) {
        return Database.update(record);
    }
}