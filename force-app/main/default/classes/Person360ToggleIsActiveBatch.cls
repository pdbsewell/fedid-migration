/**
 * @description       : Batchable Class to toggle IsActive__c for Person 360 objects (Address__c, Email__c, Name__c, Phone__c)
 * @author            : J.Mapanao
 * @group             : Test
 * @last modified on  : 2021-12-02
 * @last modified by  : Stefan Scheit
 * @revision
 * 2019-03-21 - J.Mapanao - Initial version.
 * 2020-04-21 - J.Mapanao - Updated the where clause in the query and to exclude records where Is_Deleted__c = true
 * 2021-12-02 - Stefan Scheit - Added logic to query Unreachable__c field for Email__c records as the batch class into the helper directly :-(
 **/
global with sharing class Person360ToggleIsActiveBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    @TestVisible
    private final List<String> sObjectList =
        new List<String>
        {
            Schema.getGlobalDescribe().get('Address__c').getDescribe().getName(),
            Schema.getGlobalDescribe().get('Email__c').getDescribe().getName(),
            Schema.getGlobalDescribe().get('Name__c').getDescribe().getName(),
            Schema.getGlobalDescribe().get('Phone__c').getDescribe().getName(),
            Schema.getGlobalDescribe().get('Social__c').getDescribe().getName()
        };
    @TestVisible
    private Integer counter {get;set;}

    @TestVisible
    // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
    private static final String DEFAULT_SCHEDULE = '0 30 1 * * ?'; // at 1:30 am every day
    
    global Person360ToggleIsActiveBatch() {
        counter = 0;
    }
    
    global Person360ToggleIsActiveBatch(Integer count) {
        this.counter = count;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String sParamadd = '';
        String sWhereClause = 'WHERE ((End_Date__c < TODAY AND Is_Active__c = true) OR (Start_Date__c < TODAY AND End_Date__c = null AND Is_Active__c = false))';
        // add Is_deleted__c field for Address__c, Email__c, and Phone__c
        if(sObjectList.get(counter) == 'Address__c' || sObjectList.get(counter) == 'Email__c' || sObjectList.get(counter) == 'Phone__c'){
            sParamadd += ', Is_Deleted__c';
            sWhereClause +=' AND Is_Deleted__c = false';
        }
        // add Unreachable__c field for Email__c
        if(sObjectList.get(counter) == 'Email__c') {
            sParamadd += ', Unreachable__c';
        }
        // form query
        String query = String.format('SELECT Id, Start_Date__c, End_Date__c, Is_Active__c {0} FROM {1} {2}',
            new List<String>{
                sParamadd,
                sObjectList.get(counter),
                sWhereClause
            });
        System.debug(System.LoggingLevel.DEBUG, '### start query:' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        LogUtilityException.debug('Person360ToggleIsActiveBatch scope:' + scope);
        if (scope != null && !scope.isEmpty()) {
            Person360ToggleIsActiveHelper helper = new Person360ToggleIsActiveHelper();
            helper.init(scope);
            helper.startMapping();
            helper.processRecords();
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        if (counter < sObjectList.size()-1) {
            counter++;
            Database.executeBatch(new Person360ToggleIsActiveBatch(counter));
        }
    }

    global void execute(SchedulableContext sc) {
        Person360ToggleIsActiveBatch batchObj = new Person360ToggleIsActiveBatch();
        Id batchProcessId = Database.executeBatch(batchObj);
    }

    /**
	 * Method to schedule the Person360ToggleIsActiveBatch with a default cron timing (at 1:00 am everyday)
	 */
	public String schedule() {
		String schedule = DEFAULT_SCHEDULE;
		return this.schedule(schedule);
    }
    
    /**
    * Method to schedule the Person360ToggleIsActiveBatch with a set cron timing
    * @param schedule The schedule as cron String
    */
	public String schedule(String schedule) {
		String jobId;
        String scheduleName = String.valueOf(Person360ToggleIsActiveBatch.class);

        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }

        List<CronTrigger> ctList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName];

        if (ctList.size() <= 0) {
            jobId = System.schedule(scheduleName, schedule, new Person360ToggleIsActiveBatch());
        }
		return jobId;
    }
    
    /**
    * Method to unschedule the Person360ToggleIsActiveBatch
    */
    public void unschedule() {
        String scheduleName = String.valueOf(Person360ToggleIsActiveBatch.class);
        if (Test.isRunningTest()) {
            scheduleName = 'Testing'+scheduleName;
        }
        for ( CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName] ) {
            System.abortJob(ct.Id);
        }
    }
}