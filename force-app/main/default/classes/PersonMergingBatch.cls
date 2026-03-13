/**
 * @description Batchable Class to perform merge for DuplicateRecordSet
 *
 * @author P.Victoriano
 * @date 02/08/19
 *
 * @revision
 *
 **/
public class PersonMergingBatch implements Database.Batchable<sObject>, Database.Stateful {
	public Boolean excludeActiveCommunitiesUser {get; set;}
	public Set<Id> skipDuplicateRecordSetIds {get; set;}
	public Boolean hasRecordsLeft = false;
	public Integer maxRecords = 200;
	public Integer maxRuns = 0;
	public String jobName {get; set;}
	//Count of times batch has rerun it self
	public Integer batchExecutionTimes = 0;

	public PersonMergingBatch() {
		excludeActiveCommunitiesUser = false;
		if (Environment_Settings__c.getInstance().Contact_Merge_Max_Rerun__c != null) {
			maxRuns = Integer.valueOf(Environment_Settings__c.getInstance().Contact_Merge_Max_Rerun__c);
		}
		if(Environment_Settings__c.getInstance().Contact_Merge_Max_Records__c != null){
			maxRecords = Integer.valueOf(Environment_Settings__c.getInstance().Contact_Merge_Max_Records__c);
		}
		jobName = Environment_Settings__c.getInstance().Contact_Merge_Job_Name__c;
		//Set Value to false to reset
		hasRecordsLeft = false;
		skipDuplicateRecordSetIds = new Set<Id>();
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		//Retrieve Duplicate records - Contact

		return Database.getQueryLocator([SELECT Id,
		                                 DuplicateRuleId,
		                                 ParentId,
		                                 RecordCount,
		                                 DuplicateRule.DeveloperName,
		                                 DuplicateRule.SobjectType,
		                                 (SELECT Id, RecordId, DuplicateRecordSetId FROM DuplicateRecordItems)
		                                 FROM DuplicateRecordSet
		                                 WHERE RecordCount > 1
		                                 AND Id NOT IN:skipDuplicateRecordSetIds
		                                 AND (DuplicateRule.DeveloperName LIKE :jobName OR
		                                      Parent.Name LIKE :jobName)
		                                 ORDER BY DuplicateRuleId
		                                 LIMIT :maxRecords]);

	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		PersonMergingHelper helper = new PersonMergingHelper();
		helper.excludeActiveCommunitiesUser = excludeActiveCommunitiesUser;
		Boolean hRecsProcess = helper.init((List<DuplicateRecordSet>)scope);
		skipDuplicateRecordSetIds.addAll(helper.skippedDuplicateRecordSet);
		//Reprocess Records as Merge can only process 2 at a time
		if (hRecsProcess == true) {
			hasRecordsLeft = true;
		}
		batchExecutionTimes++;
	}

	public void finish(Database.BatchableContext bc) {
		System.debug(LoggingLevel.DEBUG, '!!@@##: ' + bc + ' ' + hasRecordsLeft);
		batchExecutionTimes++;
		//There are records to Process rerun batch
		if (hasRecordsLeft) {
			if (maxRuns == 0 || (batchExecutionTimes <= maxRuns && maxRuns > 0)) {
				PersonMergingBatch.runNow(batchExecutionTimes, skipDuplicateRecordSetIds, excludeActiveCommunitiesUser);
			}
		}
	}
    
    /**
    * @description Batch run method helper
    */ 
	public static void runNow(Integer icnt, Set<Id> skipIds, Boolean skipACUsers) {
		PersonMergingBatch bch = new PersonMergingBatch();
		bch.excludeActiveCommunitiesUser = skipACUsers;
		bch.skipDuplicateRecordSetIds = skipIds;
		if (icnt != null) {
			bch.batchExecutionTimes = icnt;
		}
		System.debug(LoggingLevel.DEBUG, '!!@@##:bch.batchExecutionTimes: ' + bch.batchExecutionTimes);
		Database.executeBatch(bch, 1);
	}
}