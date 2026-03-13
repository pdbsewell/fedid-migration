/**
 * @description Controller for award actions
 * @group	    Grads
 * @revision    2025-01-25 - Tom Gangemi - Initial version
 */
public with sharing class GradsAwardActionsController {

    public class AwardsActionException extends Exception {}

    public class AwardInfo {
        @AuraEnabled public GradsPaymentsService.RefundInfo refundInfo;
        @AuraEnabled public Boolean isCancelled;
        @AuraEnabled public Boolean cancellationSucceeded;
        @AuraEnabled public Boolean isAttending;
        @AuraEnabled public Boolean hasFeeWaiver;
        @AuraEnabled public Boolean hasReceiptNumber;
        @AuraEnabled public Boolean applicationIsApplied;
        @AuraEnabled public Boolean hasPaymentPendingState;
        @AuraEnabled public String paymentPendingStateExpiry;
        @AuraEnabled public Long writebackRequestedTimestamp;
        @AuraEnabled public Boolean lastWritebackFailed;
    }

    private static Graduation_Award__c getAward(Id awardId) {
        Graduation_Award__c[] result = [
            SELECT Graduation_Application__c, Graduation_Payment__c, Is_Attending_Ceremony__c,
                Has_Attendance_Fee_Waiver__c, Cancellation_Date__c, Cancellation_Succeeded__c,
                Receipt_Number_External_System__c, Student_Person_Id__c, Integration_Id__c,
                Writeback_Apex_Job_Id__c, Callista_Writeback_Requested_Time__c, Last_Callista_Writeback_Status__c,
                Graduation_Application__r.Status__c, Graduation_Application__r.Graduation_Calendar__c,
                Graduation_Application__r.Payment_Pending_State__c, Graduation_Application__r.Payment_Pending_State_Expiry__c,
                Graduation_Application__r.Attendance_Mode__c
            FROM Graduation_Award__c
            WHERE Id = :awardId
        ];
        if(result.isEmpty()) {
            throw new IllegalArgumentException('Award not found');
        }
        return result[0];
    }

    @AuraEnabled(Cacheable=false)
    public static AwardInfo getAwardInfo(Id awardId) {
        AwardInfo awardInfo = new AwardInfo();
        Graduation_Award__c award = getAward(awardId);
        awardInfo.isCancelled = award.Cancellation_Date__c != null;
        awardInfo.cancellationSucceeded = awardInfo.isCancelled && award.Cancellation_Succeeded__c;
        awardInfo.isAttending = award.Is_Attending_Ceremony__c;
        awardInfo.hasFeeWaiver = award.Has_Attendance_Fee_Waiver__c;
        awardInfo.hasReceiptNumber = String.isNotBlank(award.Receipt_Number_External_System__c);
        awardInfo.applicationIsApplied = award.Graduation_Application__r.Status__c == 'Applied';

        awardInfo.refundInfo = getRefundInfo(awardId);

        GradsPendingStateHandler.PendingAwardImpact pai = GradsPendingStateHandler.getAwardImpact(
            award.Integration_Id__c, award.Graduation_Application__r
        );
        awardInfo.hasPaymentPendingState = pai.hasPendingState;
        awardInfo.paymentPendingStateExpiry = pai.expiryDate?.format();

        awardInfo.writebackRequestedTimestamp = award.Callista_Writeback_Requested_Time__c?.getTime();
        awardInfo.lastWritebackFailed = award.Last_Callista_Writeback_Status__c == 'Failed';

        return awardInfo;
    }

    /**
     * Convenience method for calling getRefundInfo from LWC without Award instance
     * @return
     */
    @AuraEnabled(Cacheable=false)
    public static GradsPaymentsService.RefundInfo getRefundInfo(Id awardId) {
        return getRefundInfo(getAward(awardId));
    }

    /**
     * Get refund info for an award. Will automatically determine if external or stripe
     */
    public static GradsPaymentsService.RefundInfo getRefundInfo(Graduation_Award__c award) {
        if(String.isNotBlank(award.Receipt_Number_External_System__c)) {
            // award has external payment
            return GradsPaymentsService.getExternalRefundInfo(new Graduation_Award__c[]{award}).get(award.Id);
        } else {
            return GradsPaymentsService.getStripeRefundInfo(award);
        }
    }

    /**
     * Cancel an award - Does nothing if already cancelled
     * @param awardId       Id of the award to cancel
     * @param createRefund  If true, create a refund
     */
    @AuraEnabled
    public static void cancelAward(Id awardId, Boolean createRefund) {
        Graduation_Award__c award = getAward(awardId);
        if(award.Cancellation_Date__c != null || award.Cancellation_Succeeded__c) {
            return;
        }
        award.Cancellation_Date__c = Datetime.now();

        if(createRefund) {
            refundAward(award);
        }

        update award;
    }

    /**
     * @param awardId         Id of the award to change attendance for
     * @param isAttending     New value for Is_Attending_Ceremony__c
     * @param createRefund    If true and changing to not attending, create a refund
     * @param receiptNumber   If not blank and changing to attending, set receipt number
     * @param hasFeeWaiver    If true, set has a fee waiver
     *
     * @description Change the attendance status of an award. Optionally refund and update App's Attendance Mode
     */
    @AuraEnabled
    public static void changeAttendance(Id awardId, Boolean isAttending, Boolean createRefund, String receiptNumber, Boolean hasFeeWaiver) {
        Graduation_Award__c award = getAward(awardId);

        if(award.Is_Attending_Ceremony__c != isAttending) {
            Graduation_Application__c appUpdate = null;
            award.Is_Attending_Ceremony__c = isAttending;
            if(isAttending) {
                // change to attending
                if(String.isNotBlank(receiptNumber)) {
                    award.Receipt_Number_External_System__c = receiptNumber;
                    award.Has_Attendance_Fee_Waiver__c = true;
                } else if(hasFeeWaiver) {
                    award.Has_Attendance_Fee_Waiver__c = true;
                }
                if(award.Graduation_Application__r.Attendance_Mode__c != 'Attending') {
                    appUpdate = new Graduation_Application__c(
                        Id = award.Graduation_Application__c,
                        Attendance_Mode__c = 'Attending'
                    );
                }
            } else {
                // change to not attending
                if(createRefund) {
                    refundAward(award);
                }
                if(award.Graduation_Application__r.Attendance_Mode__c != 'In Absentia') {
                    // check if App Attendance Mode change needed
                    if([
                        SELECT Id, Graduation_Application__c, Graduation_Payment__c
                        FROM Graduation_Award__c
                        WHERE Id != :award.Id AND Graduation_Application__c = :award.Graduation_Application__c AND
                            Is_Attending_Ceremony__c = TRUE AND Cancellation_Date__c = NULL
                    ].isEmpty()) {
                        // no active attending awards in app
                        appUpdate = new Graduation_Application__c(
                            Id = award.Graduation_Application__c,
                            Attendance_Mode__c = 'In Absentia'
                        );
                    }
                }
            }
            if(appUpdate != null) {
                update appUpdate;
            }
            update award;
        }
    }

    /**
     * Convenience method for calling refundAward from LWC without Award instance
     * @param awardId Id of the award to refund
     */
    @AuraEnabled
    public static void refundAward(Id awardId) {
        Graduation_Award__c award = getAward(awardId);
        refundAward(award);
        update award;
    }

    /**
     * Refund an award. Will automatically determine if an external or stripe refund is required
     * Uses getRefundInfo to determine if refundable
     *
     * @param award Award to refund
     */
    public static void refundAward(Graduation_Award__c award) {
        GradsPaymentsService.RefundInfo ri = getRefundInfo(award);
        if(ri.isRefundable) {
            if(ri.isExternalPayment) {
                // create approved external refund
                GradsPaymentsService.createExternalRefunds(new List<Graduation_Award__c>{award}, 'Actioned');
            } else {
                // create stripe refund request
                if(GradsPaymentsService.createStripeRefund(award, ri.refundableAttendanceFee) != null) {
                    award.Graduation_Payment__c = null;
                }
            }
        } else {
            throw new AwardsActionException('Award is not refundable');
        }
    }

    /**
     * Add a fee waiver to an award - Will always refund existing payment if possible
     * @param awardId       Id of the award to add the fee waiver to
     * @param receiptNumber Receipt number to set
     */
    @AuraEnabled
    public static void addFeeWaiver(Id awardId, String receiptNumber) {
        Graduation_Award__c award = getAward(awardId);
        GradsPaymentsService.RefundInfo ri = getRefundInfo(award);
        if(ri.isRefundable && !ri.isExternalPayment) {
            refundAward(award);
        }
        award.Has_Attendance_Fee_Waiver__c = true;
        if(String.isNotBlank(receiptNumber)) {
            award.Receipt_Number_External_System__c = receiptNumber;
        }
        update award;
    }

}