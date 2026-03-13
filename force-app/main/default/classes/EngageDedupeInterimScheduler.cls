/**
 * @author Charlie Park, UC Innovation
 * @date 2020-1-14
 * @description Schedule class to class to run Interim Process
 */
global class EngageDedupeInterimScheduler implements Schedulable {
    global Map<String, Object> params;
    global String batchType = '';
    /*******************************************************************************************************
     * @description Execute schedule context.
     * @param sc Parameter type of a schedulable context.
     * @return N/A.
     */
    global void execute(SchedulableContext sc) {
        if(batchType == 'MatchingKVBatch'){
            
            /*
         	 * Params for executeCreateMatchingKVBatch are as follows:
    	 	 *    {'matchingRuleId' : Id of the matching rule
    	 	 *     'recordIdList' : List of Ids to create matching key values for
    	 	 *     'batchSize' : size of the batch. Max is 200}
    	 	 *
    	 	 *    OR
    	 	 *
    	 	 *    {'matchingRuleId' : Id of the matching rule
    	 	 *     'whereClause' : Where clause to filter constituents
    	 	 *     'batchSize' : size of the batch. Max is 200}
    	 	 *
    	 	 *    OR
    	 	 *
    	 	 *    {'keyRuleIdList' : List of key rule Ids
    	 	 *     'recordIdList' : List of Ids to create matching key values for
    	 	 *     'batchSize' : size of the batch. Max is 200}
         	 */
            
        	ucinn_ascendv2.ascend_DEDUPE_GlobalWrapper.executeCreateMatchingKVBatch(params);
        } else if (batchType == 'FindDuplicateBatch') {
            
            /*
         	 * Params for executeFindDuplicateBatch are as follows:
         	 *    {'matchingRuleId' : Id of the matching rule
    	 	 *     'lastModifiedDate' : Find duplicates that were modified after this date
    	 	 *     'duplicateCheckedFieldAPIName' : Field that denotes that duplicates were already checked
    	 	 *     'additionalCriteria' : specifications for the duplicates in the form of an addon to a where clause Example: 'LastName = \'Bob\''
    	 	 *     'batchSize' : size of the batch. Max is 200}
         	 */
            
        	ucinn_ascendv2.ascend_DEDUPE_GlobalWrapper.executeFindDuplicateBatch(params);
        } else {
            
        	/*
         	* Params for startProcessInterims are as follows:
         	* 'interimNewBatchSize' : size of the batch for interims with status New. Max is 200
         	* 'interimPendingBatchSize' : size of the batch for interims with status Pending. Max is 200
         	* 'interimInProgressBatchSize' : size of the batch for interims with status In Progress. Max is 200
         	* 'recordTypeDeveloperName' : Record type name for the interims to dedupe
         	* 'recordTypeNamespacePrefix' : Namespace prefix for the interim recordtype if applicable
         	*/
            
        	ucinn_ascendv2.ascend_DEDUPE_GlobalWrapper.startProcessInterims(params);
        }
    }
    
}