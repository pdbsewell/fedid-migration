/**
 * @description    	Temporary workaround for avoiding CPU limits when terminating RG..
 *
 * @author:     UC Innovation
 * @date:      	2/27/2023
 */
global class ascend_GIFT_RecurringGiftOverride extends ucinn_ascendv2.ascend_GIFT_RecurringGiftAdjustment {
    
    /**
     * @description Override of general adjustment top level method
     *
     * @param params	Map of parameters holding transaction information.
    */
	global override Object adjustRecurringGift(Map<String, Object> params) {
        
        //De-activate ascend Payment Trigger
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('' + ucinn_ascendv2__Payment__c.SObjectType, false);
        
        //Perform adjustment
        Object returnObj = super.adjustRecurringGift(params);
        
        //Activate ascend Payment Trigger
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('' + ucinn_ascendv2__Payment__c.SObjectType, true);
        
        Opportunity newOpp = (Opportunity) params.get('giftRec');
        
        //Asynchronously update payments. This should cover most use cases where hundreds of payments are present.
        //This is only a temporary workaround. Batch should be used if this fails to execute.
        if (newOpp != null) {
            updatePayments(newOpp.Id);
        }
        
        return returnObj;
    }
    
    
    /**
     * @description Future method. Runs in a different transaction than the adjustment. Simply update the payments to allow trigger logic to resolve.
     *
     * @param oppId		Grabs all payments associated with the opp and updates them.
    */
    
    @future
    private static void updatePayments(Id oppId)
    {   
		List<ucinn_ascendv2__Payment__c> paymentList = [SELECT Id FROM ucinn_ascendv2__Payment__c WHERE ucinn_ascendv2__Opportunity__c =: oppId];
        
        if (!paymentList.isEmpty()) {
            update paymentList;
        }
    }
}