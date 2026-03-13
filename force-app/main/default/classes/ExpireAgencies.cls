/***************************************************************************************************
* @author:		K Liew
* @date:		11.April.2019
* @description:	Scheduled Apex to process Agencies being terminated in a future-dated fashion.
*               To be scheduled for daily execution at COB.  Picks up all Accounts / Agencies
*               with contract termination date is today and updates the Status value to
*               'Contact Terminated'.
* @revision:
*				11.April.2019   KL > Initial class creation.
*               2.May.2019      KL > Changes due to findings from end-2-end testing.
*                               No longer need to maintain isSuspended and isEnabbled
*                               fields.  This is automatically handled by Agent Portal with
*                               Salesforce just supplying Status.
*               02.Oct.2019     KL > Updates to include setting of 'Web Status' field to false
*                               when an Agency is being terminated.
***************************************************************************************************/

global with sharing class ExpireAgencies implements Schedulable {
    global void execute(SchedulableContext ctx) {
        try {

            // get Record Type details
            Schema.DescribeSObjectResult d = Account.SObjectType.getDescribe();
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName =  rtMapByName.get('Agency');
            Id rtId = rtByName.getRecordTypeId();

            // retrieve list of agencies whereby latest contract end date is equals to today
            List<Account> expiringAgencies = 
            [
                SELECT Id
                    , Name
                    , Callista_Org_Unit_Code__c
                    , Status__c
                    , Latest_Contract_End_Date__c
                    , Agent_Portal_Access_Is_Suspended__c
                    , Agent_Portal_Access_Is_Enabled__c
                    , Monash_AM_Web_Status__c
                FROM Account
                WHERE RecordTypeId = :rtId
                AND Headquarters__c = true
                AND Status__c != 'Contract Terminated'
                AND Latest_Contract_End_Date__c = today
            ];
            
            // if there are records, loop through and set status to contfact terminated
            if (expiringAgencies.size() > 0) {
                for (Account recordInLoop : expiringAgencies) {
                    recordInLoop.Status__c = 'Contract Terminated';
                    recordInLoop.Monash_AM_Web_Status__c = false;
                    // recordInLoop.Agent_Portal_Access_Is_Suspended__c = false;
                    // recordInLoop.Agent_Portal_Access_Is_Enabled__c = false;
                }

                // perform DML to update
                update expiringAgencies;
            }

        } catch (Exception e) {

            ExLog.add('ExpireAgencies','Account / Agent Management Scheduled Apex','execute', e);

        }
    }
}