/**
 * @author       Tom Gangemi
 * @description  Scheduled batch job to remove old CaseTeamMembers from Academic Progress cases
 * @group        Batch
 * @testclass    ApCaseTeamMemberRemoverBatch_Test
 * @revision     2022-11-10 - Tom Gangemi - SA-1800 - Initial version
 *               2023-08-02 - Tom Gangemi - SA-2317 - Reduce query limit
 */
public with sharing class ApCaseTeamMemberRemoverBatch implements Database.Batchable<Id>, Database.Stateful, Schedulable {

    private Id[] deleteErrorIds; // track errors for logging
    @TestVisible private static final Datetime CUTOFF_DATETIME;
    private static final String APA_RT_NAME = 'Academic_Progress_Assessment';

    // (QUERY_LIMIT * Average CTMs/Contact) must be < 50,000. Currently, average CTMs/Contact is 89
    private static final Integer QUERY_LIMIT = 400;

    static {
        // get cutoff from System_Settings__mdt
        System_Settings__mdt settingRecord = SystemSettingsUtil.getInstance().getByName('AP_CTM_CASE_AGE');
        Map<String,Integer> ages = (Map<String,Integer>)JSON.deserialize(settingRecord.Value__c, Map<String,Integer>.class);
        Integer cutoffDays = ages.get('days');
        Integer cutoffMinutes = ages.get('minutes');
        CUTOFF_DATETIME = Datetime.now().addDays(-cutoffDays).addMinutes(-cutoffMinutes);
    }

    public ApCaseTeamMemberRemoverBatch() {
        deleteErrorIds = new Id[0];
    }

    /**
     * Collects Ids of Contacts that require CTMs to be pruned.
     * Use Iterable as QueryLocator doesn't support aggregate queries
     */
    public Iterable<Id> start(Database.BatchableContext bc) {
        Id[] contactIds = new Id[0];

        AggregateResult[] ars;
        // can't use AggregateResult with QueryLocator or queryMore()
        if(Test.isRunningTest()) {
            // copy of the live query but replace LastModifiedDate with writeable Last_Status_Change__c
            ars = [
                SELECT Parent.ContactId
                FROM CaseTeamMember
                WHERE Parent.RecordType.DeveloperName = :APA_RT_NAME
                GROUP BY Parent.ContactId
                HAVING MAX(Parent.Service_End_Time__c) < :CUTOFF_DATETIME
                ORDER BY MAX(Parent.Service_End_Time__c) ASC
                LIMIT :QUERY_LIMIT
            ];
        } else {
            // query contact Ids of CTMs that don't have a recently modified Case
            // ORDER BY used to prune oldest first (in event that not all are picked up within this query)
            // LIMIT to prevent this processing for too long on any given run
            ars = [
                SELECT Parent.ContactId
                FROM CaseTeamMember
                WHERE Parent.RecordType.DeveloperName = :APA_RT_NAME
                GROUP BY Parent.ContactId
                HAVING MAX(Parent.LastModifiedDate) < :CUTOFF_DATETIME
                ORDER BY MAX(Parent.LastModifiedDate) ASC
                LIMIT :QUERY_LIMIT
            ];
        }
        for(AggregateResult ar :ars) {
            contactIds.add((Id)ar.get('ContactId'));
        }

        return contactIds;
    }

    public void execute(Database.BatchableContext bc, Id[] contactIds) {
        // delete APA CTMs for given contactIds
        try {
            delete [
                SELECT Id
                FROM CaseTeamMember
                WHERE Parent.ContactId IN :contactIds AND Parent.RecordType.DeveloperName = :APA_RT_NAME
                ORDER BY CreatedDate ASC
                LIMIT 3000
            ];
        } catch (DmlException ex) {
            deleteErrorIds.addAll(contactIds);
            throw ex;
        }

        if(Test.isRunningTest()) {
            // adds code coverage to finish()
            deleteErrorIds.add(contactIds[0]);
        }
    }

    public void finish(Database.BatchableContext bc) {
        if(deleteErrorIds.size() > 0) {
            // log any errors
            String logMsg = 'ApCaseTeamMemberRemoverBatch: Failed to delete ' + deleteErrorIds.size() + ' records.\n';
            logMsg += String.join(deleteErrorIds, ',');
            LogUtilityException.logExceptionMSG('WARNING', null, logMsg);
        }
    }

    /**
     * Schedulable execute - executes the batch job
     */
    public void execute(SchedulableContext sc) {
        // 300 contacts per batch
        Database.executeBatch(new ApCaseTeamMemberRemoverBatch(),300);
    }

}