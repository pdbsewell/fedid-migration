/**
* @description BatchDelete Records
*
* @author P. Victoriano
* @date 16/02/2020
*
* @group Common
* @revision
*           pvic0002 - Fixed as failing on Local Test and User is already deactivated
*
**/
global class BatchDeleteRecords implements Database.Batchable<sObject> {

    global final String query;

    global BatchDeleteRecords(String q) {
        query=q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC,List<sObject> scope) {
        delete scope;
    }

    global void finish(Database.BatchableContext BC) {
        LogUtilityException.debug('Batch Delete Finished');
    }

}