/**
 * @author          Mark Johnson: UC Innovation
 * @description    	This override class is to provide custom logic after in progres batch runs 
 * @revision        3/1/2022 - Mark Johnson - Initial version
 */

global class ascend_DEDUPE_ProcessInProgOverride extends ucinn_ascendv2.ascend_DEDUPE_ProcessInProgressBaseV2 {

    // used keep track of all interims processed
    private List<ucinn_ascendv2__Interim__c> interimsProcessed;

    /**
    * @description: Query for contact information and create maps for easy processing
    *
    * @param:       params: {'interimList' => List<Interim>: List of interims to process}
    * @return:      void
    * @since:       2.17
    */
    global override void prepareContactInformation(Map<String, Object> params) {
        List<ucinn_ascendv2__Interim__c> interimList = (List<ucinn_ascendv2__Interim__c>) params.get('interimList');
        Map<Id, Id> interimIdToContactIdMap = new Map<Id, Id>();    //Map of interim IDs to contact IDs
        Set<Id> contactIds = new Set<Id>();                         //Set of all IDs that are associated to contacts. Used as a variable in query below.

        String queryToRun = autoMergeHelper.targetSoql + ' FROM Contact WHERE Id IN: contactIds';

        for (ucinn_ascendv2__Interim__c interim : interimList) {
            if (interim.ucinn_ascendv2__Contact__c != null) {
                contactIds.add(interim.ucinn_ascendv2__Contact__c);
                interimIdToContactIdMap.put(interim.Id, interim.ucinn_ascendv2__Contact__c);
            }
        }

        //Get all contacts associated with the interims to process
        Map<Id, Contact> contactMap = new Map<Id, Contact>((List<Contact>) Database.query(queryToRun));

        params.put('interimIdToContactIdMap', interimIdToContactIdMap);
        params.put('contactMap', contactMap);
    }

    global override void batchConstructor(String recordTypeName, String recordTypeNamespace) {
        interimsProcessed = new List<ucinn_ascendv2__Interim__c>();
        super.batchConstructor(recordTypeName, recordTypeNamespace);
    }
    
    global override void batchExecute(Database.BatchableContext BC, List<sObject> interimList) {
        super.batchExecute(BC, interimList);
        interimsProcessed.addAll((List<ucinn_ascendv2__Interim__c>)interimList);
    }

    global override void batchFinish(Database.BatchableContext BC) {

        Map<String, Object> params = new Map<String, Object>();//additionalVariables;

        // run update giving summary batch for completed interims with child rtv2 records that posted
        Set<Id> contactIdSet = new Set<Id>();
        List<ucinn_ascendv2__Interim__c> interimsCompleted = [
            SELECT Id, ucinn_ascendv2__Contact__c,
                (SELECT Id, ucinn_ascendv2__Status__c
                 FROM ucinn_ascendv2__Review_Transactions_v2_Interim__r
                 WHERE ucinn_ascendv2__Status__c = 'Posted')
            FROM ucinn_ascendv2__Interim__c
            WHERE ucinn_ascendv2__Status__c = 'Completed' AND ucinn_ascendv2__Contact__c != null AND Id IN :interimsProcessed
            LIMIT 25000
        ];
        System.debug('ascend_DEDUPE_ProcessInProgOverride: interimsCompleted[' + interimsCompleted.size() + ']=' + interimsCompleted);

        for (ucinn_ascendv2__Interim__c interim : interimsCompleted) {
            if (interim.ucinn_ascendv2__Review_Transactions_v2_Interim__r != null 
                    && interim.ucinn_ascendv2__Review_Transactions_v2_Interim__r.size() > 0) {
                contactIdSet.add(interim.ucinn_ascendv2__Contact__c);
            }
        }
        System.debug('ascend_DEDUPE_ProcessInProgOverride: contactIdSet[' + contactIdSet.size() + ']=' + contactIdSet);

        if(!contactIdSet.isEmpty()) {
            params.put('batchSize', 50);
            params.put('householdBatchSize', 50);
            params.put('callUpdateHouseholdGivingBatch', true);
            params.put('contactIdToProcessSet', contactIdSet);
            ucinn_ascendv2.ascend_UTIL_RunBatch.ascend_GIFT_UpdateGivingSummaryBatch(params);
        }
    }
}