/**
 * @description Service class for handling Graduations payments
 * @group	    Grads
 * @revision    2025-01-25 - Tom Gangemi - Initial version
 */
public with sharing class GradsPaymentsService {

    public enum NoRefundReason {NO_PAYMENT, INSUFFICIENT_FUNDS}
    public static final Map<NoRefundReason,String> NO_REFUND_LABELS = new Map<NoRefundReason,String> {
        NoRefundReason.NO_PAYMENT => 'No payment found',
        NoRefundReason.INSUFFICIENT_FUNDS => 'Insufficient funds'
    };

    public class RefundInfo {
        @AuraEnabled public Boolean isExternalPayment;
        @AuraEnabled public Decimal refundableAttendanceFee;
        @AuraEnabled public Boolean hasPayment;
        @AuraEnabled public Boolean isRefundable;
        @AuraEnabled public Boolean isWithinRefundPeriod; // default to true for when no refund end date is defined
        @AuraEnabled public NoRefundReason nonRefundableReason;
        @AuraEnabled public String nonRefundableReasonLabel;
        @AuraEnabled public String calendarName;
        @AuraEnabled public String refundEndDate;
    }

    /**
     * Refunded awards have their Graduation_Payment__c value cleared.
     * Once a Graduation_Payment__c of Type = 'Refund' reaches status = Succeed. The payment it refunds has its Refunded_Amount__c incremented.
     */

    /**
     * Get refund information for a Graduation_Award__c
     */
    public static RefundInfo getStripeRefundInfo(Graduation_Award__c award) {

        RefundInfo refundInfo = new RefundInfo();
        refundInfo.isRefundable = false;
        refundInfo.hasPayment = false;
        refundInfo.isExternalPayment = false;

        Graduation_Payment__c payment = [
            SELECT Refunded_Amount__c, Total_Amount__c, Attendance_Fee_Unit_Amount__c, Late_Fee_Amount__c,
                (SELECT Total_Amount__c FROM Graduation_Refunds__r WHERE Refund_Status__c != 'Rejected')
            FROM Graduation_Payment__c
            WHERE Id = :award.Graduation_Payment__c
        ] ?? null;

        refundInfo.hasPayment = payment != null;

        if(!refundInfo.hasPayment) {
            // no payment found
            refundInfo.nonRefundableReason = NoRefundReason.NO_PAYMENT;
            refundInfo.nonRefundableReasonLabel = NO_REFUND_LABELS.get(NoRefundReason.NO_PAYMENT);
            return refundInfo;
        }

        // add up any refunded amounts that might not be accounted for in the payment's Refunded_Amount__c
        Decimal amountRefunded = 0;
        for(Graduation_Payment__c refund : payment.Graduation_Refunds__r) {
            amountRefunded += refund.Total_Amount__c;
        }
        // take the greater of processed refunds and in-flight refunds
        amountRefunded = Math.max(amountRefunded, payment.Refunded_Amount__c);
        if(payment.Total_Amount__c - amountRefunded < payment.Attendance_Fee_Unit_Amount__c) {
            // payment has insufficient remaining funds
            refundInfo.nonRefundableReason = NoRefundReason.INSUFFICIENT_FUNDS;
            refundInfo.nonRefundableReasonLabel = NO_REFUND_LABELS.get(NoRefundReason.INSUFFICIENT_FUNDS);
            return refundInfo;
        }

        Calendar_Dates__c calendarDate = [
            SELECT Date_Value__c, CalendarId__r.Type__c
            FROM Calendar_Dates__c
            WHERE CalendarId__c = :award.Graduation_Application__r.Graduation_Calendar__c
            AND Name = 'RFND-END'
        ] ?? null;

        refundInfo.calendarName = calendarDate?.CalendarId__r.Type__c;
        Date refundEndDate = calendarDate?.Date_Value__c;
        if(refundEndDate != null) {
            Datetime refundEndDateTime = Datetime.newInstance(refundEndDate, Time.newInstance(0,0,0,0));
            refundInfo.refundEndDate = refundEndDateTime.format('yyyy-MM-dd');
        }

        // payment is refundable
        refundInfo.isRefundable = true;
        refundInfo.refundableAttendanceFee = payment.Attendance_Fee_Unit_Amount__c;

        // refund period is not defined or has not ended
        refundInfo.isWithinRefundPeriod = refundEndDate == null || refundEndDate >= Date.today();

        return refundInfo;
    }

    /**
     * Create a stripe refund for a Graduation_Award__c
     */
    public static Graduation_Payment__c createStripeRefund(Graduation_Award__c award, Decimal refundAmount) {
        Graduation_Payment__c refundRequest = null;
        if(refundAmount > 0 && award.Graduation_Payment__c != null) {
            refundRequest = new Graduation_Payment__c(
                Type__c = 'Refund',
                Attendance_Fee_Qty__c = 1,
                Attendance_Fee_Unit_Amount__c = refundAmount,
                Total_Amount__c = refundAmount,
                Refund_Status__c = 'Requested',
                Origin__c = 'Graduation Portal',
                Refunded_Payment__c = award.Graduation_Payment__c,
                Graduation_Application__c = award.Graduation_Application__c
            );
            insert refundRequest;
        }
        return refundRequest;
    }

    /**
     * Get refund information for a Graduation_Award__c with an external payment
     */
    public static Map<Id, RefundInfo> getExternalRefundInfo(List<Graduation_Award__c> awards) {
        Map<Id, RefundInfo> refundInfoMap = new Map<Id, RefundInfo>();
        Set<Id> gradAppIds = new Set<Id>();
        Set<String> receiptNumbers = new Set<String>();
        Set<String> studentIds = new Set<String>();

        for (Graduation_Award__c award : awards) {
            if (String.isNotBlank(award.Receipt_Number_External_System__c)) {
                gradAppIds.add(award.Graduation_Application__c);
                receiptNumbers.add(award.Receipt_Number_External_System__c);
                studentIds.add(award.Student_Person_Id__c);
            }
        }

        // get existing refunds by student id and receipt number
        Set<String> existingRefundKeys = new Set<String>();
        if (!gradAppIds.isEmpty() && !receiptNumbers.isEmpty()) {
            for (Graduation_Payment__c refund : [
                SELECT Graduation_Application__r.Student_Person_Id__c, Receipt_Number__c
                FROM Graduation_Payment__c
                WHERE Type__c = 'Refund' AND Origin__c = 'External' AND Refund_Status__c != 'Rejected'
                AND Receipt_Number__c IN :receiptNumbers AND Graduation_Application__r.Student_Person_Id__c IN :studentIds
            ]) {
                existingRefundKeys.add(refund.Graduation_Application__r.Student_Person_Id__c + ':' + refund.Receipt_Number__c);
            }
        }

        // get calendar code by grad app id
        Map<Id, String> calCodeByAppId = new Map<Id, String>();
        if (!gradAppIds.isEmpty()) {
            for (Graduation_Application__c app : [
                SELECT Id, Graduation_Calendar__r.Calendar_Code__c
                FROM Graduation_Application__c
                WHERE Id IN :gradAppIds
            ]) {
                calCodeByAppId.put(app.Id, app.Graduation_Calendar__r.Calendar_Code__c);
            }
        }

        // get refund end date by calendar code
        Map<String, Date> refundEndByCalCode = new Map<String, Date>();
        if (!calCodeByAppId.isEmpty()) {
            for (Calendar_Dates__c calDate : [
                SELECT Date_Value__c, CalendarId__r.Calendar_Code__c
                FROM Calendar_Dates__c
                WHERE CalendarId__r.Calendar_Code__c IN :calCodeByAppId.values()
                AND Name = 'RFND-END'
            ]) {
                refundEndByCalCode.put(calDate.CalendarId__r.Calendar_Code__c, calDate.Date_Value__c);
            }
        }

        // create refund info for each award
        for (Graduation_Award__c award : awards) {
            RefundInfo info = new RefundInfo();
            info.isExternalPayment = true;
            info.hasPayment = String.isNotBlank(award.Receipt_Number_External_System__c);
            info.isRefundable = false;
            info.isWithinRefundPeriod = true; // default to true for when no refund end date is defined

            if (!info.hasPayment) {
                info.nonRefundableReason = NoRefundReason.NO_PAYMENT;
                info.nonRefundableReasonLabel = NO_REFUND_LABELS.get(NoRefundReason.NO_PAYMENT);
            } else {
                String appId = award.Graduation_Application__c;
                String receiptNumber = award.Receipt_Number_External_System__c;
                String refundKey = award.Student_Person_Id__c + ':' + receiptNumber;

                if (!existingRefundKeys.contains(refundKey)) {
                    info.isRefundable = true;

                    String calendarCode = calCodeByAppId.get(appId);
                    if (String.isNotBlank(calendarCode)) {
                        info.calendarName = calendarCode;
                        Date refundEndDate = refundEndByCalCode.get(calendarCode);
                        if (refundEndDate != null) {
                            Datetime refundEndDatetime = Datetime.newInstance(refundEndDate, Time.newInstance(0,0,0,0));
                            info.refundEndDate = refundEndDatetime.format('yyyy-MM-dd');
                            info.isWithinRefundPeriod = (refundEndDate == null) || (refundEndDate >= Date.today());
                        }
                    }
                }
            }

            refundInfoMap.put(award.Id, info);
        }

        return refundInfoMap;
    }

    /**
     * Create external refunds for a list of Graduation_Award__c
     */
    public static void createExternalRefunds(Graduation_Award__c[] awards, String status) {

        List<Graduation_Payment__c> refundsToInsert = new List<Graduation_Payment__c>();

        for (Graduation_Award__c award : awards) {
            refundsToInsert.add(new Graduation_Payment__c(
                Graduation_Application__c = award.Graduation_Application__c,
                Receipt_Number__c = award.Receipt_Number_External_System__c,
                Type__c = 'Refund',
                Origin__c = 'External',
                Refund_Status__c = status
            ));
        }

        insert refundsToInsert;
    }
}