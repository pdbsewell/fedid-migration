/**
 * @description Mock for SObjectDao for unit testing purposes
 */
@isTest
public inherited sharing class SObjectDaoMock implements Dao {
    
    public List<SObject> recordsInserted;

    public List<SObject> recordsUpdated;

    public List<SObject> recordsUpserted;

    public List<SObject> recordsDeleted;


    public SObjectDaoMock() {
        this.recordsInserted = new List<SObject>();
        this.recordsUpdated = new List<SObject>();
        this.recordsUpserted = new List<SObject>();
        this.recordsDeleted = new List<SObject>();
    }

    public void insertRecords(List<SObject> quotes) {
        this.recordsInserted.addAll(quotes);
    }

    public void updateRecords(List<SObject> quotes) {
        this.recordsUpdated.addAll(quotes);
    }
    
    public void upsertRecords(List<SObject> quotes) {
        this.recordsUpserted.addAll(quotes);
    }
    
    public void deleteRecords(List<SObject> quotes) {
        this.recordsDeleted.addAll(quotes);
    }
}