/**
 * @description       : Trigger for Funding object.
 * @author            : APR
 * @group             : Trigger
 * @last modified on  : 2023-10-04
 * Modifications Log
 * Ver   Date         Author         	Modification
 * 1.0   2023-10-04   APR   	        Initial Version
**/

trigger FundingTrigger on Funding__c (before insert, before update) {

    if (TriggerCommon.doNotRunTrigger('Funding__c')) {
        return;
    }

    new Triggers()
            // insert
            .bindExtended(Triggers.Evnt.beforeinsert, new FundingTriggerHandler.SeFundingUniqueId())
            .execute();

}