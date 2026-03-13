/**
 * @description     Handles the deletion of soft-deleted Person360 Objects
 *                  such as Contact, Address, Email, and Phone
 * @author          J.Mapanao
 * @date            09.APR.2020
 * 
 * @revision
 *                  09.APR.2020 - J.Mapanao - Initial Created
 */
global with sharing class Person360PurgeBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    @TestVisible
    private List<String> objNames = 
        new List<String>
        {
            Schema.getGlobalDescribe().get('Contact').getDescribe().getName(),
            Schema.getGlobalDescribe().get('Address__c').getDescribe().getName(),
            Schema.getGlobalDescribe().get('Phone__c').getDescribe().getName(),
            Schema.getGlobalDescribe().get('Email__c').getDescribe().getName()
        };

    @TestVisible
    private Integer counter {get;set;}

    @TestVisible
    // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
    private static final String DEFAULT_SCHEDULE = '0 0 1 * * ?'; // at 1 am every day

    global Person360PurgeBatch() {
        counter = 0;
    }

    global Person360PurgeBatch(Integer count) {
        this.counter = count;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String sWhereClause = '';
        if (objNames.get(counter) == 'Contact') {
            sWhereClause += 'Deleted_In_Source__c = true';
        }
        else if (objNames.get(counter) == 'Address__c' || objNames.get(counter) == 'Phone__c' || objNames.get(counter) == 'Email__c') {
            sWhereClause += 'Is_Deleted__c = true';
        }

        String query = String.format('SELECT Id FROM {0} WHERE {1}',
            new List<String>{
                objNames.get(counter),
                sWhereClause
            });
        LogUtilityException.debug('Person360PurgeBatch query:' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scopes) {
        if (!scopes.isEmpty()) {
            //delete scopes;
            Database.DeleteResult[] drList = Database.delete(scopes, false);

            // Iterate through each returned result
			integer i = 0;
            for (Database.DeleteResult dr : drList) {
            	if (!dr.isSuccess()) {
                	// Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        LogUtilityException.addLogEvent(objNames[counter], scopes[i], err, 'Person360PurgeBatch.execute');
                    }
                }
                i++;
            }
            LogUtilityException.publishAll();
        }
    }

    global void finish(Database.BatchableContext BC) {
        LogUtilityException.getLimits();
        if (counter < objNames.size()-1) {
            counter++;
            Database.executeBatch(new Person360PurgeBatch(counter));
        }
    }

    global void execute(SchedulableContext sc) {
        Person360PurgeBatch batchObj = new Person360PurgeBatch();
        Id batchProcessId = Database.executeBatch(batchObj);
    }

    /**
	 * Method to schedule the Person360PurgeBatch with a default cron timing (at 1:00 am everyday)
	 */
	public String schedule() {
		String schedule = DEFAULT_SCHEDULE;
		return this.schedule(schedule);
    }
    
    /**
    * Method to schedule the Person360PurgeBatch with a set cron timing
    * @param schedule The schedule as cron String
    */
	public String schedule(String schedule) {
		String jobId;
        String scheduleName = String.valueOf(Person360PurgeBatch.class);

        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }

        List<CronTrigger> ctList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName];

        if (ctList.size() <= 0) {
            jobId = System.schedule(scheduleName, schedule, new Person360PurgeBatch());
        }
		return jobId;
    }
    
    /**
    * Method to unschedule the Person360PurgeBatch
    */
    public void unschedule() {
        String scheduleName = String.valueOf(Person360PurgeBatch.class);
        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }
        for ( CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName] ) {
            System.abortJob(ct.Id);
        }
    }
}