/**
 * @description Batch job for posting Graduation Fees to SAP.
 * @group       Grads
 * @revision    2024-08-20 - Tom Gangemi - Initial version
 *
 * Terminology:
 *  - Journal Document: A collection of lines and associated info that will be posted to SAP in a single POST request
 *  - Line: A single line item in a Journal Document
 */
public with sharing class GradsJournalingBatch implements Database.Batchable<JournalRequestContext>, Database.Stateful, Schedulable, Database.AllowsCallouts {

    private static final Integer TIMEOUT_SECONDS = 40; // 40 = 1/3 of 120s limit

    public static final String CR = '50';
    public static final String DR = '40';

    public static final String ACC_FEES_GRADUATION_KEY = 'feesGraduation';
    public static final String ACC_FEES_LATE_KEY = 'feesLate';
    public static final String ACC_FEES_PAYMENT_GATEWAY = 'feesPaymentGateway';

    public static final String TAX_AU = 'S1';
    public static final String TAX_OS = 'S0';
    public static final String TAX_PURCHASE = 'P1';

    // Line item in a Journal Document
    public class JournalLine {
        public String posting_key;
        public String GL_account;
        public String cost_center;
        public String fund;
        public String tax_code;
        public String amount_inc;
        public transient Decimal amount_inc_decimal; // only used for internal calculations
        public String GL_text;
        public String Assignment;
    }

    // JSON body for the POST request (Journal Document)
    public class JournalRequest {
        public String request_id;
        public String document_type;
        public String document_date;
        public String posting_date;
        public String company_code;
        public String reference;
        public String document_header;
        public String currency_xxREMOVEMExx; // hack to get around reserved identifier 'currency'
        public String period;
        public List<JournalLine> GL_lines;
    }

    // Holds data needed to create a JournalRequest along with related Graduation_Payment__c records
    public class JournalRequestContext {
        public String requestId;
        public Graduation_Payment__c[] payments;
        public JournalLine[] lines;
        public Date docDate;
        public String documentNumber;

        public JournalRequestContext(Date docDate) {
            this.docDate = docDate;
            this.requestId = System.UUID.randomUUID().toString();
            this.payments = new Graduation_Payment__c[0];
            this.lines = new JournalLine[0];
        }

    }

    // Inner data of the JSON response body
    public class PostingResult {
        public String status;
        public String documentNumber;
    }

    // JSON response body
    public class JournalResponse {
        public PostingResult postingResult;
    }

    // Batch/Schedule class properties
    private String originalTransactionId;
    public Integer recordsProcessed;
    public GradsUtils.JournalConfig conf;
    public Boolean dryRun = false;
    public Integer batchSize;
    public String[] errors;
    public Integer calloutSeconds; // seconds spent on callouts in current transaction

    public GradsJournalingBatch() {
        this(false);
    }

    /**
     * @param dryRun If true, the batch will not post to the endpoint or update Payment records
     */
    public GradsJournalingBatch(Boolean dryRun) {
        this.conf = GradsUtils.getJournalConfig();
        this.recordsProcessed = 0;
        this.dryRun = dryRun;
        this.batchSize = this.conf.batchSize;
        this.errors = new String[0];
    }

    /**
     * Create JournalRequestContexts from Graduation_Payment__c records that are yet to be posted
     * Includes:
     *  - Grouping by Transaction_Date__c, Type__c
     *  - Creating 1 or more JournalLines from each Graduation_Payment__c
     *  - Creating an aggregate line (batch payment) where necessary for each Journal Document
     */
    public Iterable<JournalRequestContext> start(Database.BatchableContext context) {
        Nebula.Logger.setAsyncContext(context);
        this.originalTransactionId = Nebula.Logger.getTransactionId();

        Graduation_Payment__c[] payments = [
            SELECT Type__c, Attendance_Fee_Unit_Amount__c, Attendance_Fee_Qty__c, Late_Fee_Amount__c,
                Payment_Gateway_Fee_Amount__c, Transaction_Date__c, Transaction_Id__c, Calendar_Type__c,
                Refunded_Payment__r.Calendar_Type__c,
                Graduation_Application__r.Student__r.Person_ID__c
            FROM Graduation_Payment__c
            WHERE SAP_Sync_Date__c = NULL AND Transaction_Date__c != NULL AND CreatedDate = LAST_N_DAYS:30 AND
                (
                    (Type__c = 'Charge' AND (Attendance_Fee_Unit_Amount__c > 0 OR Late_Fee_Amount__c > 0 OR Payment_Gateway_Fee_Amount__c > 0))
                    OR
                    (Type__c = 'Refund' AND Attendance_Fee_Unit_Amount__c > 0 AND Refund_Status__c = 'Succeeded')
                ) AND Origin__c = 'Graduation Portal'
            ORDER BY Transaction_Date__c ASC
            LIMIT 30000
        ];

        Nebula.Logger.info(
            'Starting Graduation Journaling Batch Job (' + payments.size() + ' Payments)', payments
        );

        // Group Payments by Transaction_Date__c (day)
        Map<Date, List<Graduation_Payment__c>> paymentsByDate = new Map<Date, List<Graduation_Payment__c>>();
        for(Graduation_Payment__c payment : payments) {
            Date transDate = payment.Transaction_Date__c.date();
            Graduation_Payment__c[] paymentsForDate = paymentsByDate.get(transDate);
            if(paymentsForDate != null) {
                paymentsForDate.add(payment);
            } else {
                paymentsByDate.put(transDate, new List<Graduation_Payment__c>{payment});
            }
        }

        JournalRequestContext[] requestContexts = new JournalRequestContext[0];

        for(Date paymentDate : paymentsByDate.keySet()) {
            // Create request contexts for each date
            JournalRequestContext rc = new JournalRequestContext(paymentDate);

            Graduation_Payment__c[] datesPayments = paymentsByDate.get(paymentDate);
            Integer paymentIndex = 0;
            for(Graduation_Payment__c payment : datesPayments) {
                // For each payment, generate lines
                paymentIndex++;
                try {
                    rc.lines.addAll(createLines(
                        payment,
                        payment.Graduation_Application__r.Student__r.Person_ID__c
                    ));
                    rc.payments.add(payment);
                } catch(Exception e) {
                    // Log error and continue processing other payments
                    String msg = 'Failed to create Lines from Payment';
                    Nebula.Logger.error(msg, payment, e);
                    this.errors.add(msg + ' ' + payment.Id);
                }

                if(rc.lines.size() >= conf.maxDocLines - 1 || paymentIndex == datesPayments.size()) {
                    // Document max line size reached OR last payment in group, create new context
                    JournalLine aggLine = createAggregateLine(rc.lines, rc.docDate);
                    if (aggLine != null) {
                        rc.lines.add(aggLine);
                    }
                    requestContexts.add(rc);
                    rc = new JournalRequestContext(paymentDate);
                }
            }
        }

        Nebula.Logger.info('Created (' + requestContexts.size() + ' JournalRequestContexts)');

        Nebula.Logger.saveLog();
        return requestContexts;
    }

    /**
     *  For each JournalRequestContext, POST a JournalRequest to the endpoint
     */
    public void execute(Database.BatchableContext context, List<JournalRequestContext> requestContexts) {
        Nebula.Logger.setParentLogTransactionId(this.originalTransactionId);
        Nebula.Logger.setAsyncContext(context);
        Nebula.Logger.setScenario('Grads SAP Journaling');

        Graduation_Payment__c[] payments = new Graduation_Payment__c[0];
        for(JournalRequestContext rc : requestContexts) {
            processRequest(rc, dryRun);
            payments.addAll(rc.payments);
        }

        if(!dryRun) {
            Database.SaveResult[] saveResults = Database.update(payments, false);
            for (Database.SaveResult r : saveResults) {
                if (!r.isSuccess()) {
                    String msg = 'DML failed for the following JournalRequestContexts:\n';
                    for (JournalRequestContext rc : requestContexts) {
                        msg += rc.requestId + ' - ' + rc.documentNumber + '\n';
                    }
                    Nebula.Logger.error(msg, saveResults).setRecord(payments);
                    this.errors.add(msg);
                    break;
                }
            }
        }

        this.recordsProcessed += payments.size();
        Nebula.Logger.saveLog();
    }

    /**
     * This will mutate context with the request_id and if successful the returned document number
     * @param context     The JournalRequestContext to process
     * @param dryRun      If true, the request will not be posted to the endpoint
     */
    public void processRequest(JournalRequestContext context, Boolean dryRun) {
        final String reqId = context.requestId;
        Nebula.Logger.info('Submitting Request '+reqId+' (' + context.lines.size() + ' lines)').setRecord(context.payments);
        JournalRequest request = new JournalRequest();
        HttpRequest req = new HttpRequest();

        try {
            request.request_id = reqId;
            request.document_type = 'SA';
            request.document_date = formatDate(context.docDate, 'yyyy-MM-dd');
            request.posting_date = formatDate(context.docDate, 'yyyy-MM-dd');
            request.company_code = '1000';
            request.reference = 'Graduation Fees';
            request.document_header = 'Graduation fees ' + Datetime.now().format('dd-MM-yyyy');
            request.currency_xxREMOVEMExx = 'AUD';
            request.period = formatDate(context.docDate, 'M');
            request.GL_lines = context.lines;

            req.setEndpoint('callout:MIX_UniCRM_Student_Admin_Experience_API/general-journal');
            req.setTimeout(TIMEOUT_SECONDS*1000);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(request).replace('_xxREMOVEMExx', ''));

        } catch(Exception e) {
            String msg = 'Request '+reqId+' - Failed to create JournalRequest';
            Nebula.Logger.error(msg, e).setRecord(context.payments);
            this.errors.add(msg);
            return;
        }

        if(dryRun) {
            Nebula.Logger.info('Request '+reqId+' - Dry Run').
                setHttpRequestDetails(req).
                setRecord(context.payments);
            return;
        }

        for(Graduation_Payment__c payment : context.payments) {
            payment.SAP_Request_Id__c = reqId;
        }

        Datetime now = Datetime.now();
        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch(System.CalloutException e) {
            String msg = 'Request '+reqId+' - Posting HTTP failure';
            Nebula.Logger.error(msg, e).setHttpRequestDetails(req).setRecord(context.payments);
            this.errors.add(msg);
            if(e.getMessage().contains('Read timed out')) {
                // Request may have been processed by SAP, set Sync Date to avoid getting re-posted
                for(Graduation_Payment__c payment : context.payments) {
                    payment.SAP_Sync_Date__c = now;
                }
            }
            return;
        }

        if(res.getStatusCode() == 201) {
            JournalResponse response;
            try {
                response = (JournalResponse) JSON.deserialize(res.getBody(), JournalResponse.class);
                Nebula.Logger.info('Batch '+reqId+' - Posting successful').
                    setHttpRequestDetails(req).
                    setHttpResponseDetails(res).
                    setRecord(context.payments);
            } catch(JSONException e) {
                String msg = 'Batch '+reqId+' - Parsing response failed';
                Nebula.Logger.error(msg, e).
                    setHttpRequestDetails(req).
                    setHttpResponseDetails(res).
                    setRecord(context.payments);
                this.errors.add(msg);
                return;
            }
            context.documentNumber = response.postingResult.documentNumber;
            for(Graduation_Payment__c payment : context.payments) {
                payment.SAP_Sync_Date__c = now;
                payment.SAP_Document_Number__c = context.documentNumber;
            }
        } else {
            String msg = 'Batch '+reqId+' - Received non 201 status';
            Nebula.Logger.error(msg).
                setHttpRequestDetails(req).
                setHttpResponseDetails(res);
            this.errors.add(msg);
        }
        return;
    }

    public String getFundCode(String calType) {
        String fund = conf.fundsByCalType.get(calType);
        if(String.isBlank(fund)) {
            throw new IllegalArgumentException('No fund code found for calType: ' + calType);
        }
        return conf.fundsByCalType.get(calType);
    }

    public String getTaxCode(String calType) {
        if(conf.australiaCalTypes.contains(calType)) {
            return TAX_AU;
        } else {
            return TAX_OS;
        }
    }

    public String getLineTextCeremony(String studentId, String calType) {
        return studentId + ' - ' + conf.ceremonyLineTextByCalType.get(calType);
    }

    public String getLineTextLate(String studentId, String calType) {
        if(conf.australiaCalTypes.contains(calType)) {
            return studentId + ' - Late fee for Australia ceremony';
        } else {
            return studentId + ' - Late fee for international ceremony';
        }
    }

    private JournalLine[] createChargeLines(Graduation_Payment__c payment, String studentId) {
        JournalLine[] lines = new JournalLine[0];
        for(Integer i = 0; i < (payment.Attendance_Fee_Qty__c ?? 0); i++) {
            // Graduation Attendance Fee Line
            JournalLine l = new JournalLine();
            l.posting_key = CR;
            l.GL_account = conf.accounts.get(ACC_FEES_GRADUATION_KEY);
            l.cost_center = conf.costCenter;
            l.fund = getFundCode(payment.Calendar_Type__c);
            l.tax_code = getTaxCode(payment.Calendar_Type__c);
            l.amount_inc = String.valueOf(payment.Attendance_Fee_Unit_Amount__c.setScale(2));
            l.amount_inc_decimal = payment.Attendance_Fee_Unit_Amount__c;
            l.GL_text = getLineTextCeremony(studentId, payment.Calendar_Type__c);
            l.Assignment = payment.Transaction_Id_Short__c;
            lines.add(l);
        }
        if(payment.Late_Fee_Amount__c > 0) {
            // Late Fee Line
            JournalLine l = new JournalLine();
            l.posting_key = CR;
            l.GL_account = conf.accounts.get(ACC_FEES_LATE_KEY);
            l.cost_center = conf.costCenter;
            l.fund = getFundCode(payment.Calendar_Type__c);
            l.tax_code = getTaxCode(payment.Calendar_Type__c);
            l.amount_inc = String.valueOf(payment.Late_Fee_Amount__c.setScale(2));
            l.amount_inc_decimal = payment.Late_Fee_Amount__c;
            l.GL_text = getLineTextLate(studentId, payment.Calendar_Type__c);
            l.Assignment = payment.Transaction_Id_Short__c;
            lines.add(l);
        }
        if(payment.Payment_Gateway_Fee_Amount__c > 0) {
            // Payment Gateway Fee Line
            JournalLine l = new JournalLine();
            l.posting_key = DR;
            l.GL_account = conf.accounts.get(ACC_FEES_PAYMENT_GATEWAY);
            l.cost_center = conf.costCenter;
            l.fund = conf.paymentGatewayFund;
            l.tax_code = TAX_PURCHASE;
            l.amount_inc = String.valueOf(payment.Payment_Gateway_Fee_Amount__c.setScale(2));
            l.amount_inc_decimal = -payment.Payment_Gateway_Fee_Amount__c;
            l.GL_text = studentId + ' - Payment Gateway Fee';
            l.Assignment = payment.Transaction_Id_Short__c;
            lines.add(l);
        }
        return lines;
    }

    private JournalLine[] createRefundLines(Graduation_Payment__c payment, String studentId) {
        JournalLine[] lines = new JournalLine[0];
        for(Integer i = 0; i < (payment.Attendance_Fee_Qty__c ?? 0); i++) {
            // Attendance Refund Line
            JournalLine l = new JournalLine();
            l.posting_key = DR;
            l.GL_account = conf.accounts.get(ACC_FEES_GRADUATION_KEY);
            l.cost_center = conf.costCenter;
            l.fund = getFundCode(payment.Refunded_Payment__r.Calendar_Type__c);
            l.tax_code = getTaxCode(payment.Refunded_Payment__r.Calendar_Type__c);
            l.amount_inc = String.valueOf(payment.Attendance_Fee_Unit_Amount__c.setScale(2));
            l.amount_inc_decimal = -payment.Attendance_Fee_Unit_Amount__c;
            l.GL_text = studentId + ' - Refund';
            l.Assignment = payment.Transaction_Id_Short__c;
            lines.add(l);
        }
        // Late Fee Refund Line
        if(payment.Late_Fee_Amount__c > 0) {
            JournalLine l = new JournalLine();
            l.posting_key = DR;
            l.GL_account = conf.accounts.get(ACC_FEES_LATE_KEY);
            l.cost_center = conf.costCenter;
            l.fund = getFundCode(payment.Refunded_Payment__r.Calendar_Type__c);
            l.tax_code = getTaxCode(payment.Refunded_Payment__r.Calendar_Type__c);
            l.amount_inc = String.valueOf(payment.Late_Fee_Amount__c.setScale(2));
            l.amount_inc_decimal = -payment.Late_Fee_Amount__c;
            l.GL_text = studentId + ' - Refund Late Fee';
            l.Assignment = payment.Transaction_Id_Short__c;
            lines.add(l);
        }
        return lines;
    }

    /**
     * Create lines for a Graduation_Payment__c record
     */
    public JournalLine[] createLines(Graduation_Payment__c payment, String studentId) {
        JournalLine[] lines = new JournalLine[0];
        payment.Transaction_Id_Short__c = payment.Transaction_Id__c.left(18);
        if(payment.Type__c == 'Charge') {
            lines.addAll(createChargeLines(payment, studentId));
        }
        else if(payment.Type__c == 'Refund') {
            lines.addAll(createRefundLines(payment, studentId));
        }
        return lines;
    }

    /**
     * For all lines in a Document, create the aggregate line
     */
    public JournalLine createAggregateLine(JournalLine[] lines, Datetime batchDate) {
        Decimal totalAmount = 0;
        for(JournalLine l :lines) {
            totalAmount += l.amount_inc_decimal;
        }
        if(totalAmount == 0) {
            // No need to create an aggregate line if total is 0
            return null;
        }
        JournalLine al = new JournalLine();
        al.posting_key = totalAmount >= 0 ? DR : CR;
        al.GL_account = conf.aggregateAccount;
        al.cost_center = '';
        al.fund = '';
        al.tax_code = '';
        al.amount_inc = String.valueOf(Math.abs(totalAmount).setScale(2));
        al.Assignment = 'STR_GRAD_' + batchDate.format('dd_MM_yy');
        al.GL_text = al.Assignment + ' Batch Payment';
        return al;
    }

    private static String formatDate(Date d, String format) {
        return Datetime.newInstance(d.year(), d.month(), d.day()).format(format);
    }

    public void finish(Database.BatchableContext context) {
        if(this.errors.size() > 0 && String.isNotBlank(this.conf.errorAlertEmail)) {
            // if there are any errors, send an email to errorAlertEmail
            OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@f.e.monash.edu'];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{this.conf.errorAlertEmail});
            String today = Datetime.now().format('yyyy-MM-dd');
            mail.setSubject('Grads Journaling Error ' + today);
            String body = 'The Grads Journaling Batch Job for '+today+' encountered the following errors:\n';
            body += String.join(this.errors, '\n');
            body += '\n\nSee Nebula Logs in UniCRM for details.';
            mail.setPlainTextBody(body);
            mail.setOrgWideEmailAddressId(owea.Id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    }

    // Schedulable
    public void execute(SchedulableContext context) {
        if(GradsUtils.getJournalConfig().scheduledBatchEnabled == true) {
            Database.executeBatch(new GradsJournalingBatch(dryRun), batchSize);
        }
    }

}