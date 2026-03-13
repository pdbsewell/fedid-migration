/**
 * @description Trigger handler for Graduation_Award__c
 * @group	    Grads
 * @revision    2024-09-06 - Tom Gangemi - Initial version
 */
public with sharing class GraduationAwardTriggerHandler {

    @TestVisible // used to track published events in unit test
    private static Outbound_Grad_Application__e[] obdAppEvents = new Outbound_Grad_Application__e[0];

    public static Boolean awardIsCancelled(Graduation_Award__c award) {
        return award.Cancellation_Date__c != null && award.Cancellation_Succeeded__c;
    }

    /**
     * Clear Callista_Transaction_Number__c when the award is uncancelled.
     */
    public class HandlePortalUncancel extends TriggerAbstract {

        public override void process(SObject rec, SObject oldRec) {
            Graduation_Award__c award = (Graduation_Award__c) rec;
            Graduation_Award__c oldAward = (Graduation_Award__c) oldRec;

            Boolean unCancelled = award.Cancellation_Date__c == null && awardIsCancelled(oldAward);
            Boolean transNoUnchangedNotBlank = award.Callista_Transaction_Number__c != null
                && award.Callista_Transaction_Number__c == oldAward.Callista_Transaction_Number__c;
            if(unCancelled && transNoUnchangedNotBlank) {
                records.add(award);
            }
        }

        public override void execute() {
            if(GradsUtils.isPortalUser()) {
                for(Graduation_Award__c award : (List<Graduation_Award__c>) records) {
                    award.Callista_Transaction_Number__c = null;
                }
            }
        }
    }

    /**
     * Detects if Callista_Writeback_Requested_Time__c should be set.
     */
    public class DetectWriteBackRequired extends TriggerAbstract {

        final Set<SObjectField> monitoredFields = new Set<SObjectField> {
            Graduation_Award__c.Award_Code_1__c,
            Graduation_Award__c.Award_Course_Code__c,
            Graduation_Award__c.Award_Course_Version__c,
            Graduation_Award__c.Award_Title_1__c,
            Graduation_Award__c.Award_Code_2__c,
            Graduation_Award__c.Award_Title_2__c,
            Graduation_Award__c.Cancellation_Date__c,
            Graduation_Award__c.Is_Attending_Ceremony__c,
            Graduation_Award__c.Award_Type__c,
            Graduation_Award__c.Award_Course_Title__c,
            Graduation_Award__c.Course_Version_Number__c,
            Graduation_Award__c.Course_Code__c,
            Graduation_Award__c.Staff_Comments__c
        };

        public override void process(SObject rec) {
            process(rec, null);
        }

        public override void process(SObject rec, SObject oldRec) {
            Graduation_Award__c award = (Graduation_Award__c) rec;
            Graduation_Award__c oldAward = (Graduation_Award__c) oldRec;

            if(award.Bypass_Writeback_Trigger__c || GradsUtils.getSyncConfig().triggerEnabled != true) {
                return;
            }

            if(awardIsCancelled(award)) {
                // Don't enqueue writeback for cancelled awards
                return;
            }

            // Detect if record is new or any monitored fields have changed
            if(oldAward == null) {
                records.add(award);
                return;
            } else {
                for(SObjectField field : monitoredFields) {
                    if(award.get(field) != oldAward.get(field)) {
                        records.add(award);

                        String oldValue = oldAward.get(field) == null ? '' : String.valueOf(oldAward.get(field));
                        String newValue = award.get(field) == null ? '' : String.valueOf(award.get(field));
                        String debugMsg = 'Award Field ' + field + ' has changed from ' + oldValue + ' to ' + newValue;
                        Nebula.Logger.debug(debugMsg, award);

                        return;
                    }
                }
            }
        }

        public override void execute() {
            Graduation_Award__c[] awards = this.records;

            Id[] appIds = new Id[0];
            for(Graduation_Award__c award : awards) {
                appIds.add(award.Graduation_Application__c);
            }

            // Only request write-back for Applied and Cancelled applications
            Map<Id,Graduation_Application__c> appById = new Map<Id,Graduation_Application__c>([
                SELECT Status__c FROM Graduation_Application__c
                WHERE Id IN :appIds AND Status__c IN ('Applied', 'Cancelled')
            ]);

            for(Graduation_Award__c award : awards) {
                if (appById.containsKey(award.Graduation_Application__c)) {
                    award.Callista_Writeback_Requested_Time__c = Datetime.now();
                }
            }

            Nebula.Logger.saveLog();
        }
    }

    /**
     * Publishes Outbound_Grad_Application__e events when Callista_Writeback_Requested_Time__c is changed.
     * Do not include logic for setting Callista_Writeback_Requested_Time__c here - Use DetectWriteBackRequired.
     */
    public class QueueSyncJob extends TriggerAbstract {

        public override void process(SObject rec) {
            process(rec, null);
        }

        public override void process(SObject rec, SObject oldRec) {
            Graduation_Award__c award = (Graduation_Award__c) rec;
            Graduation_Award__c oldAward = (Graduation_Award__c) oldRec;

            if(award.Callista_Writeback_Requested_Time__c != null && !award.Bypass_Writeback_Trigger__c) {
                // Record is new or Requested Time has been set forward
                if (oldAward == null || oldAward.Callista_Writeback_Requested_Time__c == null) {
                    records.add(award);
                } else if (award.Callista_Writeback_Requested_Time__c > oldAward.Callista_Writeback_Requested_Time__c) {
                    records.add(award);
                }
            }
        }

        public override void execute() {
            if(!records.isEmpty()) {
                // Publish Outbound_Grad_Application__e events
                List<Outbound_Grad_Application__e> events = new List<Outbound_Grad_Application__e>();
                for(SObject award : records) {
                    events.add(new Outbound_Grad_Application__e(
                        Award_Id__c = award.Id
                    ));
                }
                EventBus.publish(events);
                if(Test.isRunningTest()) {
                    obdAppEvents.addAll(events);
                }
            }
        }

    }

    /**
     * SA-2936
     * Check if an external refund might be required:
     * - Award must have a Receipt_Number_External_System__c
     * - Award must have Is_Attending_Ceremony__c = false or Cancellation_Date__c != null
     *
     * Only used by GCP Portal
     */
    public class CreateExternalRefund extends TriggerAbstract {

        // Detect if receipt number has been set or changed to inab/cancelled
        public override void process(SObject rec, SObject oldRec) {
            Graduation_Award__c award = (Graduation_Award__c) rec;
            Graduation_Award__c oldAward = (Graduation_Award__c) oldRec;

            if(String.isBlank(award.Receipt_Number_External_System__c) || !GradsUtils.isPortalUser()) {
                // Only proceed if there's a receipt number AND this is a portal user
                return;
            }

            Boolean receiptNumberSet = award.Receipt_Number_External_System__c != oldAward.Receipt_Number_External_System__c;
            Boolean isInab = award.Is_Attending_Ceremony__c == false;
            Boolean inabSet = isInab && award.Is_Attending_Ceremony__c != oldAward.Is_Attending_Ceremony__c;
            Boolean isCancelled = award.Cancellation_Date__c != null;
            Boolean cancelledSet = isCancelled && oldAward.Cancellation_Date__c == null;

            // Receipt number set for existing inab/cancelled OR inab/cancelled set
            if((receiptNumberSet && (isInab || isCancelled))
                ||
                (inabSet || cancelledSet))
            {
                records.add(award);
            }
        }

        /**
         * Create external refunds for awards that are refundable and within the refund period.
         */
        public override void execute() {
            if(!records.isEmpty()) {
                Map<Id,GradsPaymentsService.RefundInfo> refundInfos = GradsPaymentsService.getExternalRefundInfo(records);
                Graduation_Award__c[] awardsToRefund = new List<Graduation_Award__c>();
                for(Graduation_Award__c award :(Graduation_Award__c[])records) {
                    GradsPaymentsService.RefundInfo refundInfo = refundInfos.get(award.Id);
                    if(refundInfo.isRefundable && refundInfo.isWithinRefundPeriod) {
                        awardsToRefund.add(award);
                    }
                }
                GradsPaymentsService.createExternalRefunds(awardsToRefund, 'Requested');
            }
        }
    }

}