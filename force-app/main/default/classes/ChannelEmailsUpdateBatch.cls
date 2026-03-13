/**
 * @author          Stefan Scheit
 * @description     Batch class to sanitise the name fields on Channel records (e.g in sandbox refreshes)
 * @group			Sandbox Refresh  
 * @revision        12/12/2018 - Stefan Scheit - Initial version
 *                  03/01/2024 - Maritn Cadman - Extended email field coverage and disabled non-UCI automation
 *                  04/01/2024 - Maritn Cadman - Email_Unverified__c fix + removed Monash address handling
 *                  05/01/2024 - Maritn Cadman - Added runIsolated constructor etc
 *                  03/04/2024 - Maritn Cadman - Nebula logger. Some concerns that Stateful may cause heap issues.
 */
public class ChannelEmailsUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {

    private Boolean runIsolated = false;
    public static final String MASKED_EMAIL_PREFIX = 'test_';

    private String originalTransactionId;
    private integer totalUpdates = 0;
    private integer totalErrors = 0;
    private static final String EVENTTAG = 'Channel Obfuscation';
    private static final String SCENARIO = 'Sandbox Refresh';
    
    public ChannelEmailsUpdateBatch () {
        this.runIsolated = false;
    }
    
    public ChannelEmailsUpdateBatch (Boolean runIsolated) {
        this.runIsolated = runIsolated;
    }
    
    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
		this.originalTransactionId = nebula.Logger.getTransactionId();
        nebula.Logger.setScenario(SCENARIO);       
        nebula.Logger.setAsyncContext(bc); 
        
        String escapedEmailPrefix = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_PREFIX);
        
        String queryDetail = 'SELECT Id, Email__c';
        String queryCount = 'SELECT count() ';
        String queryCriteria = ' FROM Channel__c WHERE Email__c != null AND (NOT Email__c LIKE \''+escapedEmailPrefix+'%\')';

        queryCount = queryCount + queryCriteria;
        queryDetail = queryDetail +  + queryCriteria + ' order by contact__c';
        
        Integer totalRecords = Database.countQuery(queryCount);
		nebula.logger.info('Channel records for processing: ' + totalRecords + ' \r' + queryDetail).addTag(EVENTTAG);
        nebula.logger.saveLog();

        //return results to process only if the current instance is a sandbox or a test is running
        Boolean sandbox;
        for(Organization o:[SELECT isSandbox FROM Organization LIMIT 1]) {
            sandbox = o.isSandbox;
        }
        
        if(sandbox && Test.isRunningTest() == false) {
            return Database.getQueryLocator(queryDetail);
        } else if (Test.isRunningTest()) {
            return Database.getQueryLocator(queryDetail + ' LIMIT 1');
        } else {
            // avoid running in production environment
            return Database.getQueryLocator(queryDetail + ' LIMIT 0');
        }
    }

    /**
    * Implement execute method (from interface) to run the business logic
    */
    public void execute(Database.BatchableContext bc, List<Sobject> scope) {
        nebula.Logger.setAsyncContext(bc);
        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        nebula.Logger.setScenario(SCENARIO);       

        List<Channel__c> updateChannelList = new List<Channel__c>();
        // evaluate each Channel's email fields and sanitise
        for(Channel__c iChannel : (List<Channel__c>) scope) {
            if(String.isNotEmpty(iChannel.Email__c) && (!iChannel.Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX))) {
                // prefix email
                iChannel.Email__c = MASKED_EMAIL_PREFIX + iChannel.Email__c;
            	iChannel.Email_Unverified__c = iChannel.Email__c;
            }
            updateChannelList.add(iChannel);
        }

        if(updateChannelList.size()>0) {
            Bypass_Mute_Request__c oldCustomSetting = Bypass_Mute_Request__c.getInstance();
            Bypass_Mute_Request__c customSetting = Bypass_Mute_Request__c.getInstance();
            customSetting.Bypass_All_Flows__c = true;
            customSetting.Bypass_All_Process__c = true;
            customSetting.Bypass_All_Validation_Rules__c = true;
            customSetting.Bypass_All_Triggers__c = true;
            upsert customSetting;

            TriggerCommon.disableTrigger('Channel__c');
            List<Database.SaveResult> srList = Database.update(updateChannelList, false); // allOrNothing=false
            totalUpdates += updateChannelList.size();
            for(Integer i=0; i<srList.size(); i++) {
                Database.SaveResult sr = srList[i];
                if (!sr.isSuccess()) {
					for (Database.Error err : sr.getErrors()) {
						nebula.logger.error(String.valueOf(err.getStatusCode()), sr).addTag(EVENTTAG);
                    }
                    totalErrors++;
                    totalUpdates--;
                }
            }
            
			// return the custom setting back to original values
            customSetting.Bypass_All_Flows__c = oldCustomSetting.Bypass_All_Flows__c;
            customSetting.Bypass_All_Process__c = oldCustomSetting.Bypass_All_Process__c;
            customSetting.Bypass_All_Validation_Rules__c = oldCustomSetting.Bypass_All_Validation_Rules__c;
            customSetting.Bypass_All_Triggers__c = oldCustomSetting.Bypass_All_Triggers__c;
            upsert customSetting;
        }
        nebula.logger.saveLog();
    }

    /**
    * Implement finsh method (from interface) to wrap up processing.
    */
    public void finish(Database.BatchableContext bc) {
        nebula.Logger.setAsyncContext(bc);
        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        nebula.Logger.setScenario(SCENARIO);       
		nebula.logger.info('Total Channel__c Updated Records: ' + totalUpdates).addTag(EVENTTAG);
		nebula.logger.info('Total Channel__c Errored Records: ' + totalErrors).addTag(EVENTTAG);
        nebula.logger.saveLog();

        if(!Test.isRunningTest() && !this.runIsolated) {
            Id jobId = Database.executeBatch(new EmailUpdateBatch()); // sanitise Email email addresses
        }
    }
}