/**
 * @author          Ajitabh
 * @description     Batch class for Affiliation creation and contact profile update
 * @revision
 */
global class UpdateContactProfileBatch implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Contact__c,Course__c from Course_Attempt__C ' +
            'Where Course_Attempt_Status__c = \'Completed\''+' OR '+'Course_Attempt_Status__c =\'Discontin\''
        );
    }
    global void execute(Database.BatchableContext bc, List<Course_Attempt__C> scope){
        // process each batch of records
        set<string> caIds= new set<string>();
        for (Course_Attempt__C ca : scope) {
              caIds.add(ca.id);
        }
        If(!caIds.isEmpty()){
                        AffiliationService.performAlumniNoDegreeLogic(CAIds);
        }
    }
    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
    }
}