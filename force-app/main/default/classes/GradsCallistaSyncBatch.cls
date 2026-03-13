/**
 * @description Batch job for syncing Graduation Awards with Callista.
 *              - Scheduled batch picks up stuck awards
 *              - Manual batch can be used to process a specific set of awards
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 * @revision    2025-08-18 - Tom Gangemi - Avoid retrying in progress writebacks
 */
public with sharing class GradsCallistaSyncBatch implements Database.AllowsCallouts, Database.Stateful, Database.Batchable<Id>, Schedulable {

    public Id[] suppliedAwardIds;

    /**
     * Process retries (awards with Writeback_Requested_Age_Minutes__c >= calculateBackoffMinutes(retryAttempt))
     */
    public GradsCallistaSyncBatch() {}

    /**
     * Process a specific set of awards
     */
    public GradsCallistaSyncBatch(Id[] awardIds) {
        suppliedAwardIds = awardIds;
    }

    /**
     * Calculate minimum age in minutes based on retry attempt count using exponential backoff
     * @param retryAttempt Number of retry attempts
     * @return Minimum age in minutes before next retry
     */
    public static Integer calculateBackoffMinutes(Integer retryAttempt) {
        if(retryAttempt == null || retryAttempt == 0) {
            return 2; // small delay to avoid race condition on new requests
        }
        if(retryAttempt > 6) {
            return 2147483647; // no more retries after 6 (max int value)
        }
        // 60 minutes * 2^(retryAttempt)
        // e.g. 1 = 2h, 2 = 4h, 3 = 8h, 4 = 16h, 5 = 32h, 6 = 64h
        return 60 * Integer.valueOf(Math.pow(2, retryAttempt));
    }

    public Iterable<Id> start(Database.BatchableContext context) {

        Graduation_Award__c[] awards = new Graduation_Award__c[0];
        if(suppliedAwardIds != null) {
            for(Id awardId : suppliedAwardIds) {
                awards.add(new Graduation_Award__c(Id = awardId));
            }
        } else {
            // throw in SystemModstamp for performance since Writeback_Requested_Age_Minutes__c is a formula
            awards = [
                SELECT Writeback_Retry_Attempt__c, Writeback_Requested_Age_Minutes__c, Writeback_Apex_Job_Id__c
                FROM Graduation_Award__c
                WHERE Writeback_Requested_Age_Minutes__c > 0
                    AND SystemModstamp = LAST_N_DAYS:7
                    AND Graduation_Application__r.Status__c IN ('Applied', 'Cancelled')
                ORDER BY Callista_Writeback_Requested_Time__c ASC
                LIMIT 4000
            ];
            // filter awards based on exponential backoff
            List<Graduation_Award__c> eligibleAwards = new List<Graduation_Award__c>();
            for(Graduation_Award__c award : awards) {
                Decimal age = award.Writeback_Requested_Age_Minutes__c;

                if(String.isNotBlank(award.Writeback_Apex_Job_Id__c) && age < 30) {
                    continue; // Wait 30 minutes before assuming job id is stale
                }

                if(age >= calculateBackoffMinutes(Integer.valueOf(award.Writeback_Retry_Attempt__c))) {
                    eligibleAwards.add(award);
                }
            }
            awards = eligibleAwards;
        }

        for(Graduation_Award__c award : awards) {
            award.Writeback_Retry_Attempt__c = (award.Writeback_Retry_Attempt__c ?? 0) + 1; // cleared on success
            award.Writeback_Apex_Job_Id__c = context.getJobId();
        }
        update awards;

        return new List<Id>(new Map<Id,Graduation_Award__c>(awards).keySet());
    }

    public void execute(Database.BatchableContext context, Id[] awardIds) {
        Nebula.Logger.setAsyncContext(context);
        GradsCallistaSyncService.processAwards(new Set<Id>(awardIds), true);
    }

    public void finish(Database.BatchableContext context) {}

    public void execute(SchedulableContext context) {
        if(GradsUtils.getSyncConfig().scheduledBatchEnabled == true) {
            Database.executeBatch(new GradsCallistaSyncBatch(), GradsUtils.getSyncConfig().retryBatchSize);
        }
    }
}