/**
 * @description Trigger handler for Outbound_Grad_Application__e
 * @group		Grads
 * @revision    2024-09-06 - Tom Gangemi - Initial version
 */
public with sharing class ObdGradApplicationServices {

    public class EventHandler extends TriggerAbstract {

        public override void execute() {
            Outbound_Grad_Application__e[] events = this.records;

            // Collect Award Ids from events
            Set<Id> awardIds = new Set<Id>();
            for(Outbound_Grad_Application__e event : events) {
                awardIds.add(event.Award_Id__c);
            }

            // Query Awards to process
            Graduation_Award__c[] awards = [
                SELECT Callista_Writeback_Requested_Time__c, Last_Callista_Writeback_Success_Time__c, Writeback_Apex_Job_Id__c
                FROM Graduation_Award__c
                WHERE Id IN :awardIds
            ];

            Graduation_Award__c[] awardsToProcess = new Graduation_Award__c[0];

            for(Graduation_Award__c award : awards) {
                if(award.Last_Callista_Writeback_Success_Time__c > award.Callista_Writeback_Requested_Time__c) {
                    // Skip if the Award has had write-back since last requested
                    continue;
                }
                if(award.Writeback_Apex_Job_Id__c != null) {
                    // Skip if the Award has already been queued for processing
                    continue;
                }
                // Create new Award instance to avoid modifying anything other than desired fields
                awardsToProcess.add(new Graduation_Award__c(Id = award.Id));

            }
            Nebula.Logger.fine('Processing ' + events.size() + ' Outbound_Grad_Application__e events')
                .setRecord(awardsToProcess);
            Nebula.Logger.saveLog();

            if(awardsToProcess.size() > 0) {
                Set<Id> procIds = new Map<Id,SObject>(awardsToProcess).keySet();
                Id jobId = System.enqueueJob(new GradsCallistaSyncService.QueueableSync(procIds));
                for(Graduation_Award__c award : awardsToProcess) {
                    award.Writeback_Apex_Job_Id__c = jobId;
                }
                update awardsToProcess;
            }
        }
    }
}