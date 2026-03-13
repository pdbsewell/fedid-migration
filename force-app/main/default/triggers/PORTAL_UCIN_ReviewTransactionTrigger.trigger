/**
 * @author          Charlie Park: UC Innovation
 * @description    	Separate trigger for community users. TDTM cannot be utilized by community users.
 * @revision        10/09/2019 - Charlie Park - Initial version
 */
trigger PORTAL_UCIN_ReviewTransactionTrigger on ucinn_ascendv2__Review_Transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    // Only run this if running user is not a standard salesforce user
    if (UserInfo.getUserType() != 'Standard') {    
        ReviewTransactionHandler handler = new ReviewTransactionHandler();
        handler.matchingPledgeMap = new Map<String, Opportunity>();
        if (trigger.isInsert) {
            if (trigger.isBefore) {
                handler.setupReviewTransaction(trigger.new, ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeInsert);
                handler.performOperationsBeforeInsert(trigger.new);
                handler.updateSessionBeforeInsert();
            } else if (trigger.isAfter) {
                handler.createMapOfOppsToUpdate(trigger.new);
                handler.performOperationsAfterInsert(trigger.new);
                handler.updateMapOfOpportunitiesAfterInsert();
            }
        } else if (trigger.isUpdate && trigger.isBefore) {
            handler.setupReviewTransaction(trigger.new, ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeUpdate);
            handler.performOperationsBeforeUpdate(trigger.new, trigger.oldMap);
            handler.updateSessionBeforeUpdate();
        }
    }
}