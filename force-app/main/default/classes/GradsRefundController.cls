/**
 * @description Controller for refund approval process.
 * @group		Grads
 * @revision    2024-08-20 - Tom Gangemi - Initial version
 *              2025-03-30 - Tom Gangemi - Added support for external refunds and handling failures
 */
public with sharing class GradsRefundController {

    public static final String ACTION_APPROVE = 'Approve';
    public static final String ACTION_REJECT = 'Reject';
    public static final String ACTION_COMPLETE = 'Complete';
    public static final String ACTION_RESOLVE = 'Resolve';

    final static String STRIPE_API_VERSION = '2024-06-20';

    public class RefundRequest {
        @AuraEnabled public Id paymentId;
        @AuraEnabled public String label;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String requestedDate;
        @AuraEnabled public String status;
        @AuraEnabled public String origin; // 'Graduation Portal' or 'External'
    }

    public class RefundOptions {
        @AuraEnabled public RefundRequest[] refundRequests;
    }

    /**
     * Get all refund requests for a graduation application.
     * @param gradAppId
     */
    @AuraEnabled(Cacheable=false)
    public static RefundOptions getRefundOptions(Id gradAppId) {
        Graduation_Payment__c[] refundRequests = [
            SELECT Refund_Status__c, Total_Amount__c, CreatedDate, Origin__c, Receipt_Number__c,
                Attendance_Fee_Qty__c, Late_Fee_Amount__c, Payment_Gateway_Fee_Amount__c
            FROM Graduation_Payment__c
            WHERE Graduation_Application__c = :gradAppId AND Type__c = 'Refund' AND
                Origin__c IN ('Graduation Portal', 'External')
            ORDER BY CreatedDate DESC
        ];

        RefundOptions ro = new RefundOptions();
        ro.refundRequests = new RefundRequest[0];
        for(Graduation_Payment__c rr : refundRequests) {
            RefundRequest r = new RefundRequest();
            r.paymentId = rr.Id;
            String[] parts = new String[0];
            if(rr.Origin__c == 'External') {
                parts.add('Receipt: ' + rr.Receipt_Number__c);
                r.amount = null;
            } else {
                if(rr.Attendance_Fee_Qty__c > 0) {
                    parts.add(rr.Attendance_Fee_Qty__c + 'x Ceremony Fee');
                }
                if(rr.Late_Fee_Amount__c > 0) {
                    parts.add('Late Fee');
                }
                if(rr.Payment_Gateway_Fee_Amount__c > 0) {
                    parts.add('Payment Gateway Fee');
                }
                r.amount = rr.Total_Amount__c;
            }
            r.label = String.join(parts, ', ');

            r.requestedDate = rr.CreatedDate.format('yyyy-MM-dd');
            r.status = rr.Refund_Status__c;
            r.origin = rr.Origin__c;
            ro.refundRequests.add(r);
        }

        return ro;
    }

    /**
     * Process a refund request
     * @param refundRequestId  The Id of the refund request to process
     * @param action           The action to take on the refund request
     * @param reason           The reason for the action (only currently used for rejection)
     */
    @AuraEnabled
    public static void processRefund(Id refundRequestId, String action, String reason, String note) {
        Graduation_Payment__c rr = [
            SELECT Graduation_Application__c, Transaction_Id__c, Type__c, Refund_Status__c, Origin__c,
                Total_Amount__c, Refunded_Amount__c, Refunded_Payment__r.Transaction_Id__c, Internal_Notes__c,
                Refunded_Payment__r.Refunded_Amount__c, Refunded_Payment__r.Total_Amount__c
            FROM Graduation_Payment__c
            WHERE Id = :refundRequestId AND Type__c = 'Refund'
        ] ?? null;

        if(rr == null) {
            throw new AuraHandledException('Invalid Refund request Id');
        }

        if(String.isNotBlank(note)) {
            // append note to Internal_Notes__c field with today's date
            rr.Internal_Notes__c = (rr.Internal_Notes__c == null) ? '' : rr.Internal_Notes__c + '\n';
            rr.Internal_Notes__c += Datetime.now().format('yyyy-MM-dd') + ': ' + note;
        }

        if(action == ACTION_RESOLVE) {
            rr.Refund_Status__c = 'Failed - Resolved';
            update rr;
            return;
        } else if(action == ACTION_REJECT) {
            rr.Refund_Status__c = 'Rejected';
            rr.Refund_Reject_Reason__c = reason;
            update rr;
            return;
        }

        if(rr.Origin__c == 'External') {
            processExternalRefund(rr, action, reason);
        } else if(rr.Origin__c == 'Graduation Portal') {
            processPortalRefund(rr, action, reason);
        } else {
            throw new AuraHandledException('Invalid Refund Origin');
        }
    }

    /**
     * Process a refund request from an external system
     * @param rr              The refund request to process
     * @param action          The action to take on the refund request
     * @param reason          The reason for the action (only currently used for rejection)
     */
    public static void processExternalRefund(Graduation_Payment__c rr, String action, String reason) {
        if(action == ACTION_COMPLETE) {
            rr.Refund_Status__c = 'Succeeded';
            rr.Transaction_Date__c = Datetime.now();
            update rr;
        } else {
            throw new AuraHandledException('Invalid action');
        }
    }

    /**
     * Process a refund request from the Graduation Portal
     * @param rr              The refund request to process
     * @param action          The action to take on the refund request
     * @param reason          The reason for the action (only currently used for rejection)
     */
    public static void processPortalRefund(Graduation_Payment__c rr, String action, String reason) {
        if(action == ACTION_APPROVE) {
            if(rr.Refunded_Payment__r == null) {
                throw new AuraHandledException('Refund request has no payment to refund');
            }
            Decimal remainingFunds = rr.Refunded_Payment__r.Total_Amount__c - rr.Refunded_Payment__r.Refunded_Amount__c;
            if(rr.Total_Amount__c > remainingFunds) {
                throw new AuraHandledException('Payment has insufficient funds to refund');
            }

            RefundResult result = postRefundToStripe(rr.Total_Amount__c, rr.Refunded_Payment__r.Transaction_Id__c);

            Nebula.Logger.newEntry(result.success ? LoggingLevel.INFO : LoggingLevel.ERROR, 'Refund Request')
                .setRecord(rr.Id)
                .setExceptionDetails(result.ex)
                .setHttpRequestDetails(result.httpReq)
                .setHttpResponseDetails(result.httpResp);
            Nebula.Logger.saveLog();

            if(result.success) {
                rr.Refund_Status__c = 'Actioned';
                rr.Transaction_Id__c = result.stripeData.id;
                rr.Transaction_Date__c = Datetime.now();
            } else {
                throw new AuraHandledException('Refund failed: ' + result.errorMessage);
            }
            update rr;
        } else {
            throw new AuraHandledException('Invalid action');
        }
    }

    class StripeResponseSuccess {
        public String id;
        public String status;
        public String charge;
        public Decimal amount;
        public String created;
        public String reason;
        public String description;
        public String failure_reason;
    }

    class StripeResponseError {
        public StripeResponseErrorData error;
    }

    class StripeResponseErrorData {
        public String message;
        public String amount;
        public String request_log_url;
        public String type;
    }

    class RefundResult {
        public StripeResponseSuccess stripeData ;
        public Boolean success;
        public Exception ex;
        public String errorMessage;
        public HttpRequest httpReq;
        public HttpResponse httpResp;
    }

    // https://mix-qat.monash.edu:443/vapi/stripe
    // https://api.stripe.com/
    /**
     * @param amount    The amount to refund
     * @param paymentId The Stripe Payment Intent ID to refund
     *
     * @return          RefundResult object with success flag and error message
     */
    public static RefundResult postRefundToStripe(Decimal amount, String paymentId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:GCP_Stripe_Passthrough/v1/refunds');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Stripe-Version', STRIPE_API_VERSION);

        String body = 'payment_intent=' + EncodingUtil.urlEncode(paymentId, 'UTF-8') +
            '&amount=' + (Integer)(amount * 100) + // Stripe uses cents
            '&reason=' + EncodingUtil.urlEncode('requested_by_customer', 'UTF-8') +
            '&metadata[isInternal]=' + EncodingUtil.urlEncode('true', 'UTF-8');

        request.setBody(body);

        RefundResult result = new RefundResult();
        result.success = false;
        result.httpReq = request;

        try {
            result.httpResp = new Http().send(request);

            if (result.httpResp.getStatusCode() == 200) {
                StripeResponseSuccess respData = (StripeResponseSuccess)JSON.deserialize(result.httpResp.getBody(), StripeResponseSuccess.class);
                if(respData.status == 'succeeded' || respData.status == 'pending') {
                    result.success = true;
                } else {
                    result.errorMessage = 'Refund Failed. Stripe Status: ' + respData.status;
                    if(String.isNotBlank(respData.failure_reason)) {
                        result.errorMessage += ' - ' + respData.failure_reason;
                    }
                }
                result.stripeData = respData;
            } else {
                StripeResponseError respData = (StripeResponseError)JSON.deserialize(result.httpResp.getBody(), StripeResponseError.class);
                result.errorMessage = respData.error.message;
            }
        } catch (Exception ex) {
            result.ex = ex;
            result.errorMessage = ex.getMessage();
        }

        return result;
    }
}