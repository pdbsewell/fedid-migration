/**
 * @author David Browaeys
 * @description This batch mass generate offer for bulk data processing
 * @group Bulk Data Processing
 */
public without sharing class BulkGenerateOfferBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    BulkDataProcessingSelector bdpSelector;
    @TestVisible BulkGenerateOfferService bdpOfferGenService;
    @TestVisible static Boolean disableNotification;
    public BulkGenerateOfferBatch() {
        this.bdpSelector = new BulkDataProcessingSelector();
        this.bdpOfferGenService = new BulkGenerateOfferService();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        //is the batch alreadt running ? 
        AsyncApexJob[] jobs = [SELECT Id FROM AsyncApexJob WHERE Id != :bc.getJobId() AND Status = 'Processing' AND ApexClass.Name = 'BulkGenerateOfferBatch'];
        if (jobs != null && jobs.isEmpty() == false) return null;   //if so then don't query anything
        return this.bdpSelector.selectGenerateOffers();
    }
    //DUE TO CPQ AND CONGA PERFORMANCE/LIMITATION THIS BATCH CAN ONLY RUN WITH A SCOPE OF '1'.
    public void execute(Database.BatchableContext BC,List<Bulk_Data_Processing__c> scope) {
        if (scope.size() > 1) throw new IllegalArgumentException('Scope for this batch can onle be set to 1');

        Bulk_Data_Processing__c bdp =  scope[0];
        bdp.Status__c = 'Processing Offer';
        bdp.Log__c = null;
        bdp.isLocked__c = true;
        bdp.Bulk_Job_ID__c = BC != null ? BC.getJobId() : null;
        TriggerCommon.disableTrigger('Bulk_Data_Processing__c');
        update bdp;
        TriggerCommon.enableTrigger('Bulk_Data_Processing__c');

        SavePoint savePointDML = Database.setSavepoint();
        try{
            this.bdpOfferGenService.execute(bdp);
        }catch(Exception e){
             Database.rollback(savePointDML);
             LogUtilityException.addLogEvent('Bulk Data Processing',bdp,e,'Bulk Offer Generation');
             bdp.Log__c = 'Error found in the creation of the Offer. Please contact Offers Specialist to resolve the issue.\n\nError Details: '+ e.getMessage() +'\n\n'+ e.getStackTraceString();
             bdp.isLocked__c = false;
             bdp.Status__c = 'Offer Error';
             update bdp;
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (Test.isRunningTest() == false) new CustomNotification().type('BatchApexError').title('Bulk Offer Generation Batch Completed!').body('To see the results please open opportunity list view, review the created offer and publish.').sendToCurrentUser();
    }
}