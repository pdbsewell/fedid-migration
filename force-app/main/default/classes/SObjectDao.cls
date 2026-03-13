/**
 * @description Generic Data access object for sObjects
 * @group Data Access Object
 */
public inherited sharing class SObjectDao implements Dao {

    // DO NOT MODIFY FOR SPECIFIC USE CASES
    // Implement Dao instead

    /**
     * @description Inserts a list of records
     */
    public void insertRecords(List<sObject> records) {
        insert records;
    }
    
    /**
     * @description Updates a list of records
     */
    public void updateRecords(List<sObject> records) {
        update records;
    }
    
    /**
     * @description Upserts a list of records
     */
    public void upsertRecords(List<sObject> records) {
        upsert records;
    }
    
    /**
     * @description Deletes a list of records
     */
    public void deleteRecords(List<sObject> records) {
        delete records;
    }

}