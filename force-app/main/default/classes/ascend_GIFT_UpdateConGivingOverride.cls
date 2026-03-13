/**
 * @description    	The purpose of this override is to run the ascend_GIFT_UpdateGivingSummaryBatchBase batch without sharing.
 * 					It is necessary to override transaction entry point methods as well, as methods that are not overridden inherit sharing from the parent class.
 *
 * @author:     UC Innovation
 * @date:      	1/27/2022
 */

global without sharing class ascend_GIFT_UpdateConGivingOverride extends ucinn_ascendv2.ascend_GIFT_UpdateGivingSummaryBatchBase {
	
   /**
    * @description  Called conditionally on construction of the ascend_GIFT_UpdateGivingSummaryBatch class.
    * 				Constructs the batch query to only update contacts and accounts in this list.
    *
    * @param contactIdToProcessSet 	List of contacts that will have their giving summary's updated.
    * @param accountIdsToProcessSet List of accounts that will have their giving summary's updated.
    */
    global override void batchConstructor(Set<Id> contactIdToProcessSet, Set<Id> accountIdsToProcessSet) {
        super.batchConstructor(contactIdToProcessSet, accountIdsToProcessSet);
    }
    
    
   /**
    * @description  Called conditionally on construction of the ascend_GIFT_UpdateGivingSummaryBatch class.
    * 				Constructs the batch query to only update contacts and accounts in this list.
    *
    * @param whereClause 		allows for additional whereClause conditions for the batch query on specific HSC records.
    * @param overrideDefault 	removes the default whereClause conditions.
    */
    global override void batchConstructor(String whereClause, Boolean overrideDefault) {
        super.batchConstructor(whereClause, overrideDefault);
    }
    
 
   /**
    * @description  Called on batch start. Override necessary, as this is a transaction entry point.
    *
    * @param bc 	Batchable Context
    */
    global override Database.Querylocator batchStart(Database.BatchableContext bc) {
        return super.batchStart(bc);
    }
    
    
   /**
    * @description  Called on batch execute. Override necessary, as this is a transaction entry point.
    *
    * @param bc 					Batchable Context
    * @param hardAndSoftCreditList	List of hard and soft credits that will be used to generate the giving summary.
    */
    global override void batchExecute(Database.BatchableContext bc, List<SObject> hardAndSoftCreditList) {
        super.batchExecute(bc, hardAndSoftCreditList);
    }
    
   /**
    * @description  Called on batch execute. Override necessary, as this is a transaction entry point.
    *
    * @param bc 					Batchable Context
    */
    global override void batchFinish(Database.BatchableContext bc) {
		super.batchFinish(bc);
    }
}