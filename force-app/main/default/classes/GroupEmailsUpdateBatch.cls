/**
 * @author          Stefan Scheit
 * @description     Batch class to sanitise the name fields on queues (groups)
 * @group			Sandbox Refresh  
 * @revision        13/12/2018 - Stefan Scheit - Initial version
 *                  03/01/2024 - Maritn Cadman - Extended email field coverage
 */
public class GroupEmailsUpdateBatch implements Database.Batchable<sObject>, Database.stateful {

    public static final String MASKED_EMAIL_PREFIX = 'test_';
    public static final String MASKED_EMAIL_MONASH = '@idmqat.monash.edu';

    private String originalTransactionId;
    private integer totalUpdates = 0;
    private integer totalErrors = 0;
    private static final String EVENTTAG = 'Group-Queue Obfuscation';
    private static final String SCENARIO = 'Sandbox Refresh';
    
    /**
    * Implement start method (from interface) to create a query and return the QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        this.originalTransactionId = nebula.Logger.getTransactionId();
        nebula.Logger.setScenario(SCENARIO);       
        nebula.Logger.setAsyncContext(bc);

        String escapedEmailMonash = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_MONASH);
        String escapedEmailPrefix = SandboxPostRefresh.escapeSoqlSpecialCharactersInLike(MASKED_EMAIL_PREFIX);

        String queryDetail = 'SELECT Id, Email';
        String queryCount = 'SELECT count() ';
        String queryCriteria = ' FROM Group WHERE Type = \'Queue\'' +
                               '  AND (Email != null AND (NOT Email LIKE \''+escapedEmailPrefix+'%\') AND (NOT Email LIKE \'%'+escapedEmailMonash+'\'))';

        queryCount = queryCount + queryCriteria;
        queryDetail = queryDetail + queryCriteria;

        Integer totalRecords = Database.countQuery(queryCount);
		nebula.logger.info('Queues for processing: ' + totalRecords + ' \r' + queryDetail).addTag(EVENTTAG);
        nebula.logger.saveLog();    
        
        //return results to process only if the current instance is a sandbox or a test is running
        Boolean sandbox;
        for(Organization o:[SELECT isSandbox FROM Organization LIMIT 1]) {
            sandbox = o.isSandbox;
        }
        if(sandbox && Test.isRunningTest() == false) {
            return Database.getQueryLocator(queryDetail);
        } else if (Test.isRunningTest()) {
            // All queues are accessible from the test class. This helps ensures the 'test' queue is picked up.
            return Database.getQueryLocator(queryDetail + ' order by createddate desc LIMIT 1');
        } else {
            // avoid running in production environment
            return Database.getQueryLocator(queryDetail + ' LIMIT 0');
        }
    }

    /**
    * Implement execute method (from interface) to run the business logic
    */
    public void execute(Database.BatchableContext bc, List<Sobject> scope) {
        nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        nebula.Logger.setScenario(SCENARIO);       
        nebula.Logger.setAsyncContext(bc);
        
        List<Group> updateGroupList = new List<Group>();

        for(Group iGroup : (List<Group>)scope) {
            if(String.isNotBlank(iGroup.Email) 
                && !iGroup.Email.endsWithIgnoreCase(MASKED_EMAIL_MONASH) 
                && !iGroup.Email.startsWithIgnoreCase(MASKED_EMAIL_PREFIX)) {
                if (EmailServices.isMonashEmail(iGroup.Email)) {
                    iGroup.Email = iGroup.Email.substringBefore('@') + MASKED_EMAIL_MONASH;
                } else {
                    iGroup.Email = MASKED_EMAIL_PREFIX + iGroup.Email;
                }
				updateGroupList.add(iGroup);
            } 
        }
        
        if(updateGroupList.size()>0) {
            TriggerCommon.disableTrigger('Group');
            List<Database.SaveResult> srList = Database.update(updateGroupList, false); // allOrNothing=false
            totalUpdates += updateGroupList.size();
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
		nebula.logger.info('Total Group Updated Records: ' + totalUpdates).addTag(EVENTTAG);
		nebula.logger.info('Total Group Errored Records: ' + totalErrors).addTag(EVENTTAG);
        nebula.logger.saveLog();
    }
}