/**
 * @author          Martin Cadman
 * @description     Batch class to sanitise the name field on Email fields on Lead
 * @group			Sandbox Refresh  
 * @revision        28/05/2024 - Maritn Cadman - A late additional to the batch job suite
 */
public class LeadEmailsUpdateBatch implements Database.Batchable<sObject>, Database.stateful {

    private Boolean runIsolated = false;
    public static final String MASKED_EMAIL_MONASH = '@idmqat.monash.edu';
    public static final String MASKED_EMAIL_PREFIX = 'test_';

    private String originalTransactionId;
    private integer totalUpdates = 0;
    private integer totalErrors = 0;
    private static final String EVENTTAG = 'Lead Obfuscation';
    private static final String SCENARIO = 'Sandbox Refresh';
    
    public LeadEmailsUpdateBatch () {
        this.runIsolated = false;
    }
    
    public LeadEmailsUpdateBatch (Boolean runIsolated) {
        this.runIsolated = runIsolated;
    }

    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
		this.originalTransactionId = nebula.Logger.getTransactionId();
        nebula.Logger.setScenario(SCENARIO);       
        nebula.Logger.setAsyncContext(bc);
        
        String escapedEmailMonash = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_MONASH);
        String escapedEmailPrefix = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_PREFIX);
        
        String queryDetail = 'SELECT Id, email, Parent_Guardian_Email__c, contact__c';
        String queryCount = 'SELECT count() ';
        String queryCriteria = ' FROM lead WHERE (email!= null AND ((NOT email LIKE \''+escapedEmailPrefix+'%\') AND (NOT email LIKE \'%'+escapedEmailMonash+'\')))'
                             + ' OR ( Parent_Guardian_Email__c!=null AND ((NOT Parent_Guardian_Email__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Parent_Guardian_Email__c LIKE \'%'+escapedEmailMonash+'\')))';
        
        queryCount = queryCount + queryCriteria;
        queryDetail = queryDetail + queryCriteria + ' order by contact__c';

        Integer totalRecords = Database.countQuery(queryCount);
		nebula.logger.info('Lead records for processing: ' + totalRecords + ' \r' + queryDetail).addTag(EVENTTAG);
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

        List<Lead> updateLeadList = new List<Lead>();

        for (Lead iRec : (List<Lead>) scope) {
            if(String.isNotBlank(iRec.Email) 
               && !iRec.Email.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
               && !iRec.Email.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                   if (EmailServices.isMonashEmail(iRec.Email)) {
	                   iRec.Email = iRec.Email.substringBefore('@') + MASKED_EMAIL_MONASH;
    	           } else {
        		       iRec.Email = MASKED_EMAIL_PREFIX + iRec.Email;
                	}
                }
            
            if(String.isNotBlank(iRec.Parent_Guardian_Email__c) 
               && !iRec.Parent_Guardian_Email__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
               && !iRec.Parent_Guardian_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                   if (EmailServices.isMonashEmail(iRec.Parent_Guardian_Email__c)) {
                       iRec.Parent_Guardian_Email__c = iRec.Parent_Guardian_Email__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                   } else {
                       iRec.Parent_Guardian_Email__c = MASKED_EMAIL_PREFIX + iRec.Parent_Guardian_Email__c;
                   }
               }
            
			updateLeadList.add(iRec);
        }

        if(updateLeadList.size() > 0) {
            Bypass_Mute_Request__c oldCustomSetting = Bypass_Mute_Request__c.getInstance();
            Bypass_Mute_Request__c customSetting = Bypass_Mute_Request__c.getInstance();
            customSetting.Bypass_All_Flows__c = true;
            customSetting.Bypass_All_Process__c = true;
            customSetting.Bypass_All_Validation_Rules__c = true;
            customSetting.Bypass_All_Triggers__c = true;
            upsert customSetting;

            TriggerCommon.disableTrigger('Lead__c');
            List<Database.SaveResult> srList = Database.update(updateLeadList, false); // allOrNothing=false
            totalUpdates += updateLeadList.size();
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
		nebula.logger.info('Total Lead Updated Records: ' + totalUpdates).addTag(EVENTTAG);
		nebula.logger.info('Total Lead Errored Records: ' + totalErrors).addTag(EVENTTAG);
        nebula.logger.saveLog();
    }
}