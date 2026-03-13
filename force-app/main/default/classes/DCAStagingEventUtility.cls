/**
 * @description Custom Persistence Utility using Platform Events
 * Request counts as an API request
 *
 *
 * @author Sheeba
 * @date 09/05/2022
 * @last modified on  : 2022-05-26
 * @last modified by  : Sachin Shetty
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2022-05-26   Sachin Shetty   Moved processStagingEvents from trigger
 **/
public class DCAStagingEventUtility {    

    /**
     * add a custom staging event
     * @param primaryContactId primaryContactId
     * @param counter   current record count
     * @param totalRecordCount   TotalRecordCountToBeBulkProcessed
     * @param uniqueId   uniqueId for the batch of records in DCA run
     * @param bulkProcessed   flag to indicate whether bulkProcessed
     */
    public static void dispatchStagingEvent(String primaryContactId, Integer counter, Integer totalRecordCount, String uniqueId, boolean bulkProcessed) {
        DCAStagingEvent__e stagingEvent = new DCAStagingEvent__e(
            primaryContactId__c = primaryContactId,
            counter__c = counter,
            TotalContactsToBeBulkProcessed__c = totalRecordCount,
            bulkProcessed__c = bulkProcessed,
            uniqueId__c = uniqueId
        );
        QueueEvents(stagingEvent);
        
    }
    
    /**
     * publish DCAStagingEvent__e object
     */
    @TestVisible
    static void QueueEvents(List<DCAStagingEvent__e> stes) {
        if (stes != null) {
            if (!stes.isEmpty()) {
                EventBus.publish(stes);
            }
        }
    }

    static void QueueEvents(DCAStagingEvent__e ste) {
        if (ste != null) {
            QueueEvents(new List<DCAStagingEvent__e> {ste});
        }
    }

    /***
    * Method name	: processStagingEvents
    * Description	: Process DCAStagingEvent events, create/update DCAStaging records and run the DCA post merge calculations 
    * Author        : Sachin Shetty
    * Return Type	: void
    * Parameter     : List of DCAStagingEvent events
    */
    public static void processStagingEvents(List<DCAStagingEvent__e> DCAStagingEvents){

        List<DCAStaging__c> stagingList = new List<DCAStaging__c>();
        Boolean bulkProcess = false;
        String uniqueId;
        for (DCAStagingEvent__e stagingEvent : DCAStagingEvents) {
            DCAStaging__c staging = new DCAStaging__c(
                primaryContactId__c = stagingEvent.primaryContactId__c,
                mergeUser__c = stagingEvent.mergeUser__c,
                mergeAccount__c = stagingEvent.mergeAccount__c,
                mergeContact__c = stagingEvent.mergeContact__c,           
                bulkProcessed__c = stagingEvent.bulkProcessed__c,
                TotalContactsToBeBulkProcessed__c = stagingEvent.TotalContactsToBeBulkProcessed__c,
                counter__c = stagingEvent.counter__c,
                uniqueId__c = stagingEvent.uniqueId__c
            );
            stagingList.add(staging);

            if(stagingEvent.TotalContactsToBeBulkProcessed__c == stagingEvent.counter__c){
                bulkProcess = true;
                uniqueId = stagingEvent.uniqueId__c;
            }             
        }
        Database.insert(stagingList, false);

        if(bulkProcess){
            Set<Id> primaryContactIdSet = new Set<Id>();
            List<DCAStaging__c> stListToBeUpdated = [SELECT bulkProcessed__c,primaryContactId__c 
                                                    FROM DCAStaging__c 
                                                    WHERE bulkProcessed__c = false 
                                                        AND uniqueId__c =: uniqueId];
            for(DCAStaging__c staging : stListToBeUpdated){
                staging.bulkProcessed__c = true;
                primaryContactIdSet.add(staging.primaryContactId__c);
            }
            Database.update(stListToBeUpdated, false);

            //Run the DCA post merge calculations for a set of contact records
            ContactMergeController.runBulkRecalculations(primaryContactIdSet);
        }
    }
}