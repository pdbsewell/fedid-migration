/*******************************************************************************
* @author:		K Liew
* @date:		12.April.2019
* @description:	Scheduled Apex to process Agencies being terminated in a future-dated fashion.
*               To be scheduled for daily execution at COB.  Picks up all Accounts / Agencies
*               with contract termination date is within the 'blackout' period and suspends their
*               Agent Portal access by updating the right fields, which in turns fires off
*               integration to Agent Portal.
* @revision:
*				12.April.2019 KL > Initial class creation.
*******************************************************************************/

global with sharing class SuspendAgencies implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {

            // get Record Type details
            Schema.DescribeSObjectResult d = Account.SObjectType.getDescribe();
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName =  rtMapByName.get('Agency');
            Id rtId = rtByName.getRecordTypeId();

            // retrieve backout period from custom setting
            Agent_Onboarding_Settings__c cs = Agent_Onboarding_Settings__c.getOrgDefaults();

            // retrieve list of agencies whereby latest contract end date is within black-out
            // period (60-days, but configuirable via custom setting), and sets the right fields
            // to enact an integration call that suspends the Agency in Agent Portal
            List<Account> AgenciesToSuspend = 
            [
                SELECT Id
                    , Name
                    , Callista_Org_Unit_Code__c
                    , Status__c
                    , Latest_Contract_End_Date__c
                    , Agent_Portal_Access_Is_Suspended__c
                    , Agent_Portal_Access_Is_Enabled__c
                FROM Account
                WHERE RecordTypeId = :rtId
                AND Agent_Portal_Access_Is_Suspended__c = false
                AND Latest_Contract_End_Date__c != null
                AND Status__c != 'Contract Terminated'
            ];

            // if there are records, loop through and set status to contfact terminated
            if (AgenciesToSuspend.size() > 0) {
                for (Account recordInLoop : AgenciesToSuspend) {
                    // if agency's latest contract end date is within 60-days / blackout period of expiry
                    if (System.today().daysBetween(recordInLoop.Latest_Contract_End_Date__c) <= cs.Termination_Blackout_Period__c.intValue()) {
                        recordInLoop.Agent_Portal_Access_Is_Suspended__c = true;
                    }
                }

                // perform DML to update
                update AgenciesToSuspend;
            }

        } catch (Exception e) {

            ExLog.add('SuspendAgencies','Account / Agent Management Scheduled Apex','execute', e);

        }
    }
}