/**
 * @description    	The purpose of this override is to run the ascend_GIFT_UpdateHouseholdGivingBase batch without sharing.
 * 					It is necessary to override transaction entry point methods as well, as methods that are not overridden inherit sharing from the parent class.
 *
 * @author:     UC Innovation
 * @date:      	1/27/2022
 */

global without sharing class ascend_GIFT_UpdateHHGivingOverride extends ucinn_ascendv2.ascend_GIFT_UpdateHouseholdGivingBase {
	
   /**
    * @description  Called conditionally on construction of the ascend_GIFT_UpdateHouseholdGivingBatch class.
    * 				Constructs the batch query to only update accounts in this list.
    *
    * @param householdsToUpdateList 	List of accounts that will have their giving summary's updated.
    */
    global override void batchConstructor(List<Account> householdsToUpdateList) {
        super.batchConstructor(householdsToUpdateList);
    }
    
    
   /**
    * @description  Called conditionally on construction of the ascend_GIFT_UpdateHouseholdGivingBatch class.
    * 				Constructs the batch query to only update accounts with Ids in this list.
    *
    * @param householdIdToUpdateSet 	Set of account IDs for accounts that will have their giving summary's update
    */
    global override void batchConstructor(Set<Id> householdIdToUpdateSet) {
        super.batchConstructor(householdIdToUpdateSet);
    }
    
    
   /**
    * @description  Called conditionally on construction of the ascend_GIFT_UpdateHouseholdGivingBatch class.
    * 				Constructs the batch query to calcluate giving summaries for all households.
    */
    global override void batchConstructor() {
        super.batchConstructor();
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
    global override void batchExecute(Database.BatchableContext bc, List<ucinn_ascendv2__Hard_And_Soft_Credit__c> hardAndSoftCreditList) {
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