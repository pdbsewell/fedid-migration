/**
 * @description Batch job for posting Graduation Fees to SAP
 * @group       Grads
 * @revision    2024-08-20 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GradsJournalingBatch_Test {

    static final String grad1CeremonyLine = 'May ceremony - Australia';
    static final String grad2CeremonyLine = 'September ceremony - Australia';
    static final String gradK1CeremonyLine = 'April ceremony - Malaysia';

    static final String accountGraduation = '159';
    static final String accountLate = '160';
    static final String grad1Fund = 'G1_FUND';
    static final String gradK1Fund = 'GK1_FUND';

    static final String studentId = '112';
    static final String sapDocNum = 'SAP-123';

    static void setConfValues(GradsUtils.JournalConfig jc) {
        jc.ceremonyLineTextByCalType = new Map<String,String>{
            'GRAD1' => grad1CeremonyLine,
            'GRAD2' => grad2CeremonyLine,
            'GRAD-OS-K1' => gradK1CeremonyLine
        };
        jc.fundsByCalType = new Map<String,String>{
            'GRAD1' => grad1Fund,
            'GRAD2' => 'XXYYZZ',
            'GRAD-OS-K1' => gradK1Fund
        };
        jc.accounts = new Map<String,String>{
            GradsJournalingBatch.ACC_FEES_GRADUATION_KEY => accountGraduation,
            GradsJournalingBatch.ACC_FEES_LATE_KEY => accountLate
        };
    }

    @IsTest
    static void testCreateLines() {
        // GIVEN - a payment, a refund and an expected config

        // Charge that should generate 4 lines
        Graduation_Payment__c charge = new Graduation_Payment__c(
            Type__c = 'Charge',
            Attendance_Fee_Unit_Amount__c = 110.25,
            Attendance_Fee_Qty__c = 2,
            Payment_Gateway_Fee_Amount__c = 5.25,
            Late_Fee_Amount__c = 75,
            Transaction_Date__c = Datetime.now(),
            Transaction_Id__c = '888',
            Origin__c = 'Graduation Portal',
            Calendar_Type__c = 'GRAD1'
        );
        // Refund that should generate 2 lines (1 for the refund and 1 for the late fee)
        Graduation_Payment__c refund = new Graduation_Payment__c(
            Type__c = 'Refund',
            Attendance_Fee_Unit_Amount__c = 110.25,
            Attendance_Fee_Qty__c = 1,
            Late_Fee_Amount__c = 75,
            Transaction_Date__c = charge.Transaction_Date__c,
            Transaction_Id__c = '999',
            Origin__c = 'Graduation Portal',
            Refunded_Payment__r = charge
        );

        GradsJournalingBatch gjb = new GradsJournalingBatch();
        setConfValues(gjb.conf);

        // WHEN - lines are created from a payment records
        GradsJournalingBatch.JournalLine[] paymentLines = gjb.createLines(charge, studentId);
        Assert.areEqual(4, paymentLines.size());
        GradsJournalingBatch.JournalLine[] refundLines = gjb.createLines(refund, studentId);

        GradsJournalingBatch.JournalLine[] allLines = new List<GradsJournalingBatch.JournalLine>();
        allLines.addAll(paymentLines);
        allLines.addAll(refundLines);
        GradsJournalingBatch.JournalLine aggregateLine = gjb.createAggregateLine(allLines, charge.Transaction_Date__c);

        // THEN - paymentLines are created as expected
        GradsJournalingBatch.JournalLine attendanceLine1 = paymentLines[0];
        Assert.areEqual(GradsJournalingBatch.CR, attendanceLine1.posting_key);
        Assert.areEqual(accountGraduation, attendanceLine1.GL_account);
        Assert.isNotNull(attendanceLine1.cost_center);
        Assert.areEqual(grad1Fund, attendanceLine1.fund);
        Assert.areEqual('S1', attendanceLine1.tax_code);
        Assert.areEqual('110.25', attendanceLine1.amount_inc);
        Assert.areEqual(studentId + ' - ' + grad1CeremonyLine, attendanceLine1.GL_text);

        GradsJournalingBatch.JournalLine attendanceLine2 = paymentLines[1];
        Assert.areEqual(GradsJournalingBatch.CR, attendanceLine2.posting_key);
        Assert.areEqual(accountGraduation, attendanceLine2.GL_account);
        Assert.isNotNull(attendanceLine2.cost_center);
        Assert.areEqual(grad1Fund, attendanceLine2.fund);
        Assert.areEqual('S1', attendanceLine2.tax_code);
        Assert.areEqual('110.25', attendanceLine2.amount_inc);
        Assert.areEqual(studentId + ' - ' + grad1CeremonyLine, attendanceLine2.GL_text);

        GradsJournalingBatch.JournalLine lateLine = paymentLines[2];
        Assert.areEqual(GradsJournalingBatch.CR, lateLine.posting_key);
        Assert.areEqual(accountLate, lateLine.GL_account);
        Assert.isNotNull(lateLine.cost_center);
        Assert.areEqual(grad1Fund, lateLine.fund);
        Assert.areEqual('S1', lateLine.tax_code);
        Assert.areEqual('75.00', lateLine.amount_inc);
        Assert.areEqual(studentId + ' - Late fee for Australia ceremony', lateLine.GL_text);

        GradsJournalingBatch.JournalLine gatewayFeeLine = paymentLines[3];
        Assert.areEqual(GradsJournalingBatch.DR, gatewayFeeLine.posting_key);
        Assert.isTrue(gatewayFeeLine.GL_text.endsWith('Payment Gateway Fee'));
        Assert.areEqual('5.25', gatewayFeeLine.amount_inc);

        // THEN - refundLines are created as expected
        Assert.areEqual(2, refundLines.size());
        GradsJournalingBatch.JournalLine refundAttendanceLine = refundLines[0];
        Assert.areEqual(GradsJournalingBatch.DR, refundAttendanceLine.posting_key);
        Assert.areEqual(accountGraduation, refundAttendanceLine.GL_account);
        Assert.areEqual(-refund.Attendance_Fee_Unit_Amount__c, refundAttendanceLine.amount_inc_decimal);
        GradsJournalingBatch.JournalLine refundLateFeeLine = refundLines[1];
        Assert.areEqual(GradsJournalingBatch.DR, refundLateFeeLine.posting_key);
        Assert.areEqual(accountLate, refundLateFeeLine.GL_account);
        Assert.areEqual(-refund.Late_Fee_Amount__c, refundLateFeeLine.amount_inc_decimal);

        // THEN - aggregateLine is created as expected
        Assert.areEqual(GradsJournalingBatch.DR, aggregateLine.posting_key);
        Assert.areEqual(gjb.conf.aggregateAccount, aggregateLine.GL_account);
        Assert.isNotNull(aggregateLine.cost_center);
        Assert.areEqual('', aggregateLine.fund);
        Assert.areEqual('', aggregateLine.tax_code);
        Assert.areEqual('105.00', aggregateLine.amount_inc, 'Should be Charges - Refunds (180-75)');
    }

    private static void setupRecords() {
        Contact student = new Contact(
            Person_ID_unique__c = studentId,
            LastName = 'Jackson',
            Email = 'djackson@example.com.au'
        );
        Calendar__c cal = new Calendar__c(
            Type__c = 'GRAD1'
        );
        insert cal;
        TriggerCommon.disableTrigger('Contact');
        insert student;
        Graduation_Application__c gapp = new Graduation_Application__c(
            Student__c = student.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Applied'
        );
        TriggerCommon.disableTrigger('Graduation_Application__c');
        insert gapp;
        Graduation_Payment__c payment = new Graduation_Payment__c(
            Graduation_Application__c = gapp.Id,
            Attendance_Fee_Unit_Amount__c = 200,
            Attendance_Fee_Qty__c = 2,
            Late_Fee_Amount__c = 50,
            Total_Amount__c = 250,
            Transaction_Date__c = Datetime.now(),
            Transaction_Id__c = '999',
            Type__c = 'Charge',
            Calendar_Type__c = 'GRAD1'
        );
        insert payment;
    }

    @IsTest
    static void testSuccess() {
        // GIVEN - a payment and an expected config
        setupRecords();

        // WHEN - the batch is run (with a mocked HTTP response)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201));
        Test.startTest();
        GradsJournalingBatch batch = new GradsJournalingBatch();
        setConfValues(batch.conf);
        Database.executeBatch(batch);
        Test.stopTest();

        // THEN - There should be no errors
        Nebula__LogEntry__c[] logs = [
            SELECT Nebula__Message__c, Nebula__ExceptionLocation__c, Nebula__ExceptionMessage__c
            FROM Nebula__LogEntry__c
            WHERE Nebula__ApexClassName__c = 'GradsJournalingBatch' AND Nebula__LoggingLevel__c = 'ERROR'
        ];
        Assert.isTrue(logs.isEmpty(), 'Error was logged');

        // THEN - Payments should have a SAP_Request_Id__c, SAP_Document_Number__c AND SAP_Sync_Date__c
        Graduation_Payment__c updatedPayment = [
            SELECT SAP_Request_Id__c, SAP_Document_Number__c, SAP_Sync_Date__c
            FROM Graduation_Payment__c
        ];
        Assert.areEqual(sapDocNum, updatedPayment.SAP_Document_Number__c);
        Assert.isNotNull(updatedPayment.SAP_Sync_Date__c);
        Assert.isNotNull(updatedPayment.SAP_Request_Id__c);
    }

    @IsTest
    static void testFailure() {
        // GIVEN - a payment and an expected config
        setupRecords();

        // WHEN - the batch is run (with a mocked HTTP response)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500));
        Test.startTest();
        GradsJournalingBatch batch = new GradsJournalingBatch();
        setConfValues(batch.conf);
        Database.executeBatch(batch);
        Test.stopTest();

        // THEN - There should be an error
        Nebula__LogEntry__c[] logs = [
            SELECT Nebula__Message__c
            FROM Nebula__LogEntry__c
            WHERE Nebula__ApexClassName__c = 'GradsJournalingBatch' AND Nebula__LoggingLevel__c = 'ERROR'
        ];
        Assert.isFalse(logs.isEmpty(), 'Error was not logged');
    }

    class MockHttpResponseGenerator implements HttpCalloutMock {
        final Integer statusCode;
        public MockHttpResponseGenerator(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HttpResponse respond(HttpRequest req) {
            Assert.areEqual('POST', req.getMethod());

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            GradsJournalingBatch.PostingResult pr = new GradsJournalingBatch.PostingResult();
            pr.documentNumber = sapDocNum;
            GradsJournalingBatch.JournalResponse jr = new GradsJournalingBatch.JournalResponse();
            jr.postingResult = pr;
            res.setBody(JSON.serialize(jr));
            res.setStatusCode(statusCode);
            return res;
        }
    }
}