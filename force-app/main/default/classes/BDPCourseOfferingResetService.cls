/**
 * @author David Browaeys
 * @description This service class fetch course offering base on transfer information using duplicate management
 * @group Bulk Data Processing
 * @revision
 *  AUG.31.2022     Nick Guia   - Renamed Promise interface to IPromise 
 */
public inherited sharing class BDPCourseOfferingResetService implements IPromise {
    @TestVisible private Suggested_Course_Offering__c[] suggestedCourseOfferings;
    @TestVisible private Dao sobjectDao;

	/**
     * Inittialise process, act as constructor
     * @return   IPromise
     */
	public IPromise init(){
        this.sobjectDao = new SObjectDao();
        return this;
    }

    /**
     * Main execite method of the BDP CourseOffering Matching Service
     * @param  records list of BDP record to fetch data
    */
    public void execute(SObject[] records){
        Map<ID, Bulk_Data_Processing__c> bdps = new Map<ID, Bulk_Data_Processing__c>((Bulk_Data_Processing__c[])records);
        this.suggestedCourseOfferings = [SELECT Id FROM Suggested_Course_Offering__c WHERE Bulk_Data_Processing__c IN :bdps.keySet() ];
        commitAll();
    }
    public void commitAll(){
        this.sobjectDao.deleteRecords(this.suggestedCourseOfferings);
    }
}