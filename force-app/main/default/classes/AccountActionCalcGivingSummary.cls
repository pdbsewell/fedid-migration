/**
 * @description       : Class to expose an invocable action for Account
 * @author            : Stefan Scheit
 * @group             : Enterprise
 * @last modified on  : 2021-04-15
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2021-04-15   Stefan Scheit   Initial Version
**/
public with sharing class AccountActionCalcGivingSummary {
    
    @InvocableMethod(label='Calculate Giving Summary' description='Triggers the calculation of the giving summary for the specified Account Ids.' category='Account')
    public static void calculateGivingSummary(List<List<String>> accountIdsList) {

        if(accountIdsList!=null && accountIdsList.size()>0) {
            
            // grab first list entry from input (contains account ids)
            List<String> accountIds = accountIdsList[0];
            
            try{
                // add account ids to a set of Ids
                Set<Id> accountIdsToProcessSet = new Set<Id>();
                for(String accountId : accountIds) {
                    accountIdsToProcessSet.add(Id.valueOf(accountId));
                }

                // prepare input and call the batch logic
                Map<String, Object> params = new Map<String, Object>();
                params.put('accountIdsToProcessSet', accountIdsToProcessSet);
                params.put('batchSize', 200);
            
                // invoke the managed package logic to calculate the giving summary
                ucinn_ascendv2.ascend_UTIL_RunBatch.ascend_GIFT_UpdateGivingSummaryBatch(params);
            } catch(Exception exc) {
                // log the exception (async)
                LogUtilityException.logExceptionMSG('Account', accountIds, 'The giving summary batch could not be created for the provided account ids.');
                throw(exc);
            }
        }
    }
}