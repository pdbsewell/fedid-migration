/**
 * @description Test class for GradsRefundController
 * @group       Grads
 * @revision    2024-08-20 - Tom Gangemi - Initial version
 *              2025-03-30 - Tom Gangemi - Added test for Stripe error handling
 *
 */
@IsTest(IsParallel=true)
private class GradsRefundController_Test {

    static final Decimal REFUND_REQ_MOUNT = 100;

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test University');
        insert acc;

        Contact cont = new Contact(
            LastName = 'TestStudent', AccountId = acc.Id, Person_ID_unique__c = '12345',
            Email = 'test@example.com'
        );
        TriggerCommon.disableTrigger('Contact');
        insert cont;

        final Integer calendar_code = 13343;
        Calendar__c cal = new Calendar__c(
            Description__c = '2024 (May) Ceremony',
            Type_Description__c = 'SEM 1',
            Type__c = 'GRAD1',
            Type_Alt__c = 'CLAYTON',
            Calendar_Code__c = String.valueOf(calendar_code),
            Sequence_Number__c = calendar_code,
            Start_Date__c = Date.newInstance(2024, 5, 01),
            End_Date__c = Date.newInstance(2024, 10, 31)
        );
        insert cal;

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = cont.Id,
            Graduation_Calendar__c = cal.Id,
            Student_Testamur_Name__c = 'Test Student',
            Student_Personal_Email__c = cont.Email,
            Expected_Attendance_Fee_Unit_Amount__c = 100,
            Status__c = 'Applied'
        );
        TriggerCommon.disableTrigger('Graduation_Application__c');
        insert app;

        // Create test Graduation Payment (Charge)
        Graduation_Payment__c charge = new Graduation_Payment__c(
            Graduation_Application__c = app.Id,
            Type__c = 'Charge',
            Total_Amount__c = REFUND_REQ_MOUNT,
            Refunded_Amount__c = 0,
            Attendance_Fee_Unit_Amount__c = REFUND_REQ_MOUNT,
            Attendance_Fee_Qty__c = 1,
            Transaction_Id__c = 'pi_test_charge',
            Transaction_Date__c = Datetime.now()
        );
        insert charge;

        // Create test Graduation Payment (Refund Request)
        Graduation_Payment__c refundReq = new Graduation_Payment__c(
            Graduation_Application__c = app.Id,
            Type__c = 'Refund',
            Total_Amount__c = REFUND_REQ_MOUNT,
            Refund_Status__c = 'Requested',
            Refunded_Payment__c = charge.Id,
            Origin__c = 'Graduation Portal'
        );

        // Create external refund request
        Graduation_Payment__c refundReqExt = new Graduation_Payment__c(
            Graduation_Application__c = app.Id,
            Type__c = 'Refund',
            Total_Amount__c = REFUND_REQ_MOUNT,
            Refund_Status__c = 'Requested',
            Refunded_Payment__c = charge.Id,
            Origin__c = 'External'
        );

        insert new Graduation_Payment__c[] { refundReq, refundReqExt };
    }

    @IsTest
    static void testGetRefundOptions() {
        // GIVEN - Test Graduation Application that has a refund request
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];

        // WHEN - Refund options are retrieved
        GradsRefundController.RefundOptions options = GradsRefundController.getRefundOptions(app.Id);

        // THEN - Refund request should be returned
        Assert.areEqual(2, options.refundRequests.size());
        Assert.areEqual(REFUND_REQ_MOUNT, options.refundRequests[0].amount);
        Assert.areEqual('Requested', options.refundRequests[0].status);
    }

    @IsTest
    static void testProcessRefund_Approve() {
        // GIVEN - A refund request
        Graduation_Payment__c refundRequest = [SELECT Id FROM Graduation_Payment__c WHERE Type__c = 'Refund' LIMIT 1];

        // Mock the Stripe API response
        Test.setMock(HttpCalloutMock.class, new StripeAPIMock(true));

        // WHEN - Refund request is approved
        Test.startTest();
        GradsRefundController.processRefund(refundRequest.Id, GradsRefundController.ACTION_APPROVE, null, null);
        Test.stopTest();

        // THEN - Refund status should be updated
        Graduation_Payment__c result = [SELECT Refund_Status__c, Transaction_Id__c FROM Graduation_Payment__c WHERE Id = :refundRequest.Id];
        Assert.areEqual('Actioned', result.Refund_Status__c, 'Refund status should be Actioned');
        Assert.isNotNull(result.Transaction_Id__c, 'Transaction Id should be set');
    }

    @IsTest
    static void testProcessExternalRefund_Complete() {
        // GIVEN - An external refund request
        Graduation_Payment__c refundRequest = [
            SELECT Id
            FROM Graduation_Payment__c
            WHERE Type__c = 'Refund' AND Origin__c = 'External'
            LIMIT 1
        ];

        // WHEN - External refund request is completed
        Test.startTest();
        GradsRefundController.processRefund(
            refundRequest.Id,
            GradsRefundController.ACTION_COMPLETE,
            null,
            'External refund completed'
        );
        Test.stopTest();

        // THEN - Refund status should be updated
        Graduation_Payment__c result = [
            SELECT Refund_Status__c, Transaction_Date__c, Internal_Notes__c
            FROM Graduation_Payment__c
            WHERE Id = :refundRequest.Id
        ];

        Assert.areEqual('Succeeded', result.Refund_Status__c, 'Refund status should be Succeeded');
        Assert.isNotNull(result.Transaction_Date__c, 'Transaction date should be set');
        Assert.isTrue(result.Internal_Notes__c.contains('External refund completed'), 'Internal notes should contain the note');
    }

    @IsTest
    static void testProcessRefund_Reject() {
        // GIVEN - A refund request
        Graduation_Payment__c refundRequest = [SELECT Id FROM Graduation_Payment__c WHERE Type__c = 'Refund' LIMIT 1];

        // WHEN - Refund request is rejected
        Test.startTest();
        GradsRefundController.processRefund(
            refundRequest.Id, GradsRefundController.ACTION_REJECT, 'Test rejection reason', 'This a note'
        );
        Test.stopTest();

        // THEN - Refund status should be updated
        Graduation_Payment__c result = [
            SELECT Refund_Status__c, Refund_Reject_Reason__c, Internal_Notes__c
            FROM Graduation_Payment__c WHERE Id = :refundRequest.Id
        ];
        Assert.areEqual('Rejected', result.Refund_Status__c, 'Refund status should be Rejected');
        Assert.areEqual('Test rejection reason', result.Refund_Reject_Reason__c, 'Rejection reason should be set');
        Assert.isTrue(String.isNotBlank(result.Internal_Notes__c), 'Internal notes should be set');
    }

    @IsTest
    static void testProcessRefund_InvalidAction() {
        // GIVEN - A refund request
        Graduation_Payment__c refundRequest = [SELECT Id FROM Graduation_Payment__c WHERE Type__c = 'Refund' LIMIT 1];

        // WHEN - Invalid action is attempted
        try {
            GradsRefundController.processRefund(refundRequest.Id, 'InvalidAction', null, null);
            // THEN - Should throw an exception
            Assert.fail('Should have thrown an exception for invalid action');
        } catch (AuraHandledException e) {}
    }

    @IsTest
    static void testProcessRefund_StripeError() {
        // GIVEN - A refund request (but Stripe API will return an error)
        Graduation_Payment__c refundRequest = [SELECT Id FROM Graduation_Payment__c WHERE Type__c = 'Refund' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new StripeAPIMock(false));

        // WHEN - Refund request is approved
        try {
            GradsRefundController.processRefund(refundRequest.Id, GradsRefundController.ACTION_APPROVE, null, null);
            // THEN - Should throw an exception
            Assert.fail('Should have thrown an exception for Stripe error');
        } catch (AuraHandledException e) {}
    }

    private class StripeAPIMock implements HttpCalloutMock {
        private Boolean isSuccess;

        public StripeAPIMock(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (isSuccess) {
                res.setStatusCode(200);
                res.setBody('{"id":"re_test","object":"refund","amount":5000,"status":"succeeded"}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":{"message":"Test error message","type":"invalid_request_error"}}');
            }

            return res;
        }
    }
}