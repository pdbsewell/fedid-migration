/*******************************************************************************
* @author       Angelo Rivera
* @date         05/08/2019
* @description  Batch class that updates MonTrack Tasks previously tagged as In Class
* @revision    	02/05/2019 - Initial Version
*******************************************************************************/
global class MontrackUpdateInClassTasksBatch implements Database.Batchable<SObject>, Schedulable{
    Id mtRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();
    public String strQuery = 'SELECT Id, Offer_Status__c FROM Task WHERE Status = \'Call Attempt\' AND Offer_Status__c = \'In Class\' AND ' +
                                'RecordTypeId = \'' + mtRecordTypeId + '\' ';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug(LoggingLevel.DEBUG, 'Query: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Task> lstTasks = (List<Task>)scope;
        List<Task> lstTasksToUpdate = new List<Task>();
        System.debug(LoggingLevel.DEBUG, 'Number of Tasks to Update: ' + lstTasks.size());
        if(!lstTasks.isEmpty()){
            for(Task tsk : lstTasks){
                tsk.Offer_Status__c = 'Not Started';
                lstTasksToUpdate.add(tsk);
            }

            if(!lstTasksToUpdate.isEmpty()){
                Update lstTasksToUpdate;
                System.debug(LoggingLevel.DEBUG,'Task update completed.');
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new MontrackUpdateInClassTasksBatch(), 200);
    }

}