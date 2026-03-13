/**
 * @author          Martin Cadman
 * @description     Batch class to sanitise the email fields on Case records (e.g in sandbox refreshes)
 * @group			Sandbox Refresh  
 * @revision        01/12/2023 - Martin Cadman - Initial version (copied from ContactEmailUpdateBatch)
 *                  03/01/2024 - Maritn Cadman - Extended email field coverage and disabled non-UCI automation
 *                  05/01/2024 - Maritn Cadman - Added runIsolated constructor etc
 *                  03/04/2024 - Maritn Cadman - Nebula logger. Some concerns that Stateful may cause heap issues.
 */
public class CaseEmailsUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {

    private Boolean runIsolated = false;
    public static final String MASKED_EMAIL_MONASH = '@idmqat.monash.edu';
    public static final String MASKED_EMAIL_PREFIX = 'test_';

    private String originalTransactionId;
    private integer totalUpdates = 0;
    private integer totalErrors = 0;
    private static final String EVENTTAG = 'Case Obfuscation';
    private static final String SCENARIO = 'Sandbox Refresh';
    
    public CaseEmailsUpdateBatch () {
        this.runIsolated = false;
    }
    
    // Not currently utilised as Case is the last batch job in the email obfiscation chain
    public CaseEmailsUpdateBatch (Boolean runIsolated) {
        this.runIsolated = runIsolated;
    }
    
    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
		this.originalTransactionId = nebula.Logger.getTransactionId();
        nebula.Logger.setScenario(SCENARIO);       
        nebula.Logger.setAsyncContext(bc); 

        // Exclue all empty or already modified email values
        String escapedEmailMonash = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_MONASH);
        String escapedEmailPrefix = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_PREFIX);
        
        String queryDetail = 'SELECT Id, contactid, SuppliedEmail, Supplied_Supervisors_Email__c, Faculty_Email__c, External_Stakeholder_Email__c, Email_To__c, Default_AskMonash_Email__c ';
        String queryCount = 'SELECT count() ';
        
        String queryCriteria = ' FROM Case ' +
                       '   WHERE (SuppliedEmail!=null AND (NOT SuppliedEmail in (\'mu.documents@monash.edu\',\'auto-reply@monash.edu.au\',\'no-reply@e44.e.monash.edu\',\'noreply@e11.e.monash.edu\',\'no-reply@e11.e.monash.edu\',\'noreply@myequals.net\')) AND ((NOT SuppliedEmail LIKE \''+escapedEmailPrefix+'%\') AND (NOT SuppliedEmail LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Supplied_Supervisors_Email__c!=null AND ((NOT Supplied_Supervisors_Email__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Supplied_Supervisors_Email__c LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Faculty_Email__c!=null AND ((NOT Faculty_Email__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Faculty_Email__c LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (External_Stakeholder_Email__c!=null AND ((NOT External_Stakeholder_Email__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT External_Stakeholder_Email__c LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Email_To__c != null AND (NOT Email_to__c in (\'mu.documents@monash.edu\',\'auto-reply@monash.edu.au\',\'no-reply@e44.e.monash.edu\',\'noreply@e11.e.monash.edu\',\'no-reply@e11.e.monash.edu\',\'noreply@myequals.net\')) AND ((NOT Email_To__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Email_To__c LIKE \'%'+escapedEmailMonash+'\'))) ' +
                       '   OR (Default_AskMonash_Email__c!=null AND ((NOT Default_AskMonash_Email__c LIKE \''+escapedEmailPrefix+'%\') AND (NOT Default_AskMonash_Email__c LIKE \'%'+escapedEmailMonash+'\'))) ';

        queryCount = queryCount + queryCriteria;
        queryDetail = queryDetail + queryCriteria + ' order by contactid';
        
        Integer totalRecords = Database.countQuery(queryCount);
		nebula.logger.info('Case records for processing: ' + totalRecords + ' \r' + queryDetail).addTag(EVENTTAG);
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
        List<Case> updateCaseList = new List<Case>();

        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        nebula.Logger.setScenario(SCENARIO);       
        nebula.Logger.setAsyncContext(bc);

        // evaluate each Case's email fields and sanitise
        for (Case iCase : (List<Case>) scope) {

            if(String.isNotBlank(iCase.SuppliedEmail) 
                && !iCase.SuppliedEmail.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
                && !iCase.SuppliedEmail.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                if (EmailServices.isMonashEmail(iCase.SuppliedEmail)) {
                    iCase.SuppliedEmail = iCase.SuppliedEmail.substringBefore('@') + MASKED_EMAIL_MONASH;
                } else {
                    iCase.SuppliedEmail = MASKED_EMAIL_PREFIX + iCase.SuppliedEmail;
                }
                   if (iCase.SuppliedEmail.length() > 80) {iCase.SuppliedEmail = '';} // quick and drity
            }

            if(String.isNotBlank(iCase.Supplied_Supervisors_Email__c) 
               && !iCase.Supplied_Supervisors_Email__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
               && !iCase.Supplied_Supervisors_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                   if (EmailServices.isMonashEmail(iCase.Supplied_Supervisors_Email__c)) {
                       iCase.Supplied_Supervisors_Email__c = iCase.Supplied_Supervisors_Email__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                   } else {
                       iCase.Supplied_Supervisors_Email__c = MASKED_EMAIL_PREFIX + iCase.Supplied_Supervisors_Email__c;
                   }
                   if (iCase.Supplied_Supervisors_Email__c.length() > 80) {iCase.Supplied_Supervisors_Email__c = '';} // quick and drity
               }

            if(String.isNotBlank(iCase.Faculty_Email__c) 
               && !iCase.Faculty_Email__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
               && !iCase.Faculty_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                   if (EmailServices.isMonashEmail(iCase.Faculty_Email__c)) {
                       iCase.Faculty_Email__c = iCase.Faculty_Email__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                   } else {
                       iCase.Faculty_Email__c = MASKED_EMAIL_PREFIX + iCase.Faculty_Email__c;
                   }
                   if (iCase.Faculty_Email__c.length() > 80) {iCase.Faculty_Email__c = '';} // quick and drity
               }
            
            if(String.isNotBlank(iCase.External_Stakeholder_Email__c) 
               && !iCase.External_Stakeholder_Email__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
               && !iCase.External_Stakeholder_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                   if (EmailServices.isMonashEmail(iCase.External_Stakeholder_Email__c)) {
                       iCase.External_Stakeholder_Email__c = iCase.External_Stakeholder_Email__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                   } else {
                       iCase.External_Stakeholder_Email__c = MASKED_EMAIL_PREFIX + iCase.External_Stakeholder_Email__c;
                   }
                   if (iCase.External_Stakeholder_Email__c.length() > 80) {iCase.External_Stakeholder_Email__c = '';} // quick and drity
               }

            if(String.isNotBlank(iCase.Email_To__c) 
               && !iCase.Email_To__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
               && !iCase.Email_To__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                   if (EmailServices.isMonashEmail(iCase.Email_To__c)) {
                       iCase.Email_To__c = iCase.Email_To__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                   } else {
                       iCase.Email_To__c = MASKED_EMAIL_PREFIX + iCase.Email_To__c;
                   }
                   
                   if (iCase.Email_To__c.length() > 250) {iCase.Email_To__c = '';} // quick and drity
               }

            if(String.isNotBlank(iCase.Default_AskMonash_Email__c) 
               && !iCase.Default_AskMonash_Email__c.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
               && !iCase.Default_AskMonash_Email__c.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                   if (EmailServices.isMonashEmail(iCase.Default_AskMonash_Email__c)) {
                       iCase.Default_AskMonash_Email__c = iCase.Default_AskMonash_Email__c.substringBefore('@') + MASKED_EMAIL_MONASH;
                   } else {
                       iCase.Default_AskMonash_Email__c = MASKED_EMAIL_PREFIX + iCase.Default_AskMonash_Email__c;
                   }
                   if (iCase.Default_AskMonash_Email__c.length() > 80) {iCase.Default_AskMonash_Email__c = '';} // quick and drity
               }
   
            updateCaseList.add(iCase);
        }
        
        if(updateCaseList.size()>0) {
            Bypass_Mute_Request__c oldCustomSetting = Bypass_Mute_Request__c.getInstance();
            Bypass_Mute_Request__c customSetting = Bypass_Mute_Request__c.getInstance();
            customSetting.Bypass_All_Flows__c = true;
            customSetting.Bypass_All_Process__c = true;
            customSetting.Bypass_All_Validation_Rules__c = true;
            customSetting.Bypass_All_Triggers__c = true;
            upsert customSetting;

            TriggerCommon.disableTrigger('Case');
            List<Database.SaveResult> srList = Database.update(updateCaseList, false); // allOrNothing=false
            totalUpdates += updateCaseList.size();
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
		nebula.logger.info('Total Case Updated Records: ' + totalUpdates).addTag(EVENTTAG);
		nebula.logger.info('Total Case Errored Records: ' + totalErrors).addTag(EVENTTAG);
        nebula.logger.saveLog();
        
        if(!Test.isRunningTest() && !this.runIsolated) {
            Id jobId = Database.executeBatch(new LeadEmailsUpdateBatch());
        }
    }
}