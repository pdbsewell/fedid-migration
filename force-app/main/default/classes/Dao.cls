/**
 * @description Data access object interface for sObjects
 * @group Data Access Object
 */
public interface Dao {

    /**
     * @description Inserts a list of records
     */
    void insertRecords(List<sObject> records);
    
    /**
     * @description Updates a list of records
     */
    void updateRecords(List<sObject> records);
    
    /**
     * @description Upserts a list of records
     */
    void upsertRecords(List<sObject> records);
    
    /**
     * @description Deletes a list of records
     */
    void deleteRecords(List<sObject> records);

}