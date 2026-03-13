/**
 * @description Test class for GradsPaymentsService
 * @group       Grads
 * @revision    2025-01-25 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GradsPaymentsService_Test {

    @TestSetup
    static void setupTestData() {
        // GIVEN - Common test data: Contact, Calendar, Application, Payment, and Refund Date
        Contact student = new Contact(
            LastName = 'TestStudent',
            FirstName = 'John',
            Person_ID_unique__c = 'TEST001'
        );
        insert student;

        Calendar__c cal = new Calendar__c(
            Calendar_Code__c = '2024GRAD',
            Category__c = 'GRADUATION'
        );
        insert cal;

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = student.Id,
            Status__c = 'Applied',
            Graduation_Calendar__c = cal.Id
        );
        insert app;

        Calendar_Dates__c refundEndDate = new Calendar_Dates__c(
            Name = 'RFND-END',
            CalendarId__c = cal.Id,
            Date_Value__c = Date.today().addDays(7),
            Calendar_Code__c = '2024GRAD'
        );
        insert refundEndDate;

        Graduation_Payment__c payment = new Graduation_Payment__c(
            Graduation_Application__c = app.Id,
            Total_Amount__c = 200,
            Attendance_Fee_Unit_Amount__c = 200,
            Attendance_Fee_Qty__c = 1,
            Refunded_Amount__c = 0,
            Type__c = 'Charge',
            Origin__c = 'Graduation Portal'
        );
        insert payment;
    }

    private static Graduation_Award__c createAward(Id appId, Id paymentId, String receiptNumber) {
        return new Graduation_Award__c(
            Graduation_Application__c = appId,
            Graduation_Payment__c = paymentId,
            Receipt_Number_External_System__c = receiptNumber,
            Is_Attending_Ceremony__c = true,

            Award_Code_1__c = '1012',
            Award_Course_Code__c = 'A2000',
            Award_Course_Version__c = 2,
            Award_Course_Title__c = 'Bachelor of Arts',
            Award_Title_1__c = 'Bachelor of Arts',
            Award_Type__c = 'SINGLE',
            Course_Code__c = 'A2000',
            Course_Title__c = 'Bachelor of Arts',
            Course_Version_Number__c = 1,
            Integration_Id__c = appId + '|' + '1012|' + System.currentTimeMillis()
        );
    }

    @IsTest
    static void testStripeRefundScenarios() {
        // GIVEN - Shared setup for Stripe refund tests
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Payment__c charge = [SELECT Total_Amount__c FROM Graduation_Payment__c LIMIT 1];

        Graduation_Award__c awardNoPayment = createAward(app.Id, null, null);
        Graduation_Award__c awardValid = createAward(app.Id, charge.Id, null);
        Graduation_Award__c awardInsufficient = createAward(app.Id, charge.Id, null);
        Graduation_Award__c[] awards = new Graduation_Award__c[]{awardNoPayment, awardValid, awardInsufficient};
        insert awards;

        // Requery awards to populate relationship and formula fields
        for(Graduation_Award__c award: [
            SELECT Student_Person_Id__c, Graduation_Payment__c,
                Graduation_Application__c, Graduation_Application__r.Graduation_Calendar__c
            FROM Graduation_Award__c WHERE Id IN :awards
        ]) {
            if(award.Id == awardInsufficient.Id) {
                awardInsufficient = award;
            }
            if(award.Id == awardValid.Id) {
                awardValid = award;
            }
            if(award.Id == awardNoPayment.Id) {
                awardNoPayment = award;
            }
        }

        // WHEN - Test 1: No payment linked
        GradsPaymentsService.RefundInfo refundInfo1 = GradsPaymentsService.getStripeRefundInfo(awardNoPayment);

        // WHEN - Test 2: Valid refund within period
        GradsPaymentsService.RefundInfo refundInfo2 = GradsPaymentsService.getStripeRefundInfo(awardValid);

        // WHEN - Test 3: Insufficient funds
        charge.Refunded_Amount__c = charge.Total_Amount__c;
        update charge;
        GradsPaymentsService.RefundInfo refundInfo3 = GradsPaymentsService.getStripeRefundInfo(awardInsufficient);

        // THEN - Verify all scenarios
        Assert.isFalse(refundInfo1.hasPayment, 'No payment should be found');
        Assert.areEqual(GradsPaymentsService.NoRefundReason.NO_PAYMENT, refundInfo1.nonRefundableReason, 'Incorrect reason for no payment');

        Assert.isTrue(refundInfo2.isRefundable, 'Payment should be refundable');
        Assert.areEqual(200, refundInfo2.refundableAttendanceFee, 'Incorrect fee amount');
        Assert.isTrue(refundInfo2.isWithinRefundPeriod, 'Should be within refund period');

        Assert.areEqual(GradsPaymentsService.NoRefundReason.INSUFFICIENT_FUNDS, refundInfo3.nonRefundableReason, 'Incorrect reason for insufficient funds');
    }

    @IsTest
    static void testStripeRefundOutsidePeriod() {
        // GIVEN - Refund period has ended
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Payment__c payment = [SELECT Id FROM Graduation_Payment__c LIMIT 1];
        Calendar_Dates__c refundDate = [SELECT CalendarId__r.Type__c FROM Calendar_Dates__c LIMIT 1];
        refundDate.Date_Value__c = Date.today().addDays(-1); // Set to past
        update refundDate;

        Graduation_Award__c award = createAward(app.Id, payment.Id, null);
        insert award;

        // Requery award to populate relationship and formula fields
        award = [
            SELECT Student_Person_Id__c, Graduation_Payment__c,
                Graduation_Application__c, Graduation_Application__r.Graduation_Calendar__c
            FROM Graduation_Award__c WHERE Id = :award.Id
        ];

        // WHEN - Retrieve refund info
        GradsPaymentsService.RefundInfo refundInfo = GradsPaymentsService.getStripeRefundInfo(award);

        // THEN - Verify outside refund period
        Assert.isTrue(refundInfo.isRefundable, 'Payment should be refundable');
        Assert.areEqual(refundDate.CalendarId__r.Type__c, refundInfo.calendarName, 'Incorrect calendar name');
        Assert.isFalse(refundInfo.isWithinRefundPeriod, 'Should be outside refund period');
    }

    @IsTest
    static void testExternalRefundScenarios() {
        // GIVEN - Mixed external refund cases
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];

        Graduation_Award__c awardNoReceipt = createAward(app.Id, null, null);
        Graduation_Award__c awardExistingRefund = createAward(app.Id, null, 'EXT456');
        Graduation_Award__c awardValid = createAward(app.Id, null, 'EXT789');
        Graduation_Award__c[] awards = new Graduation_Award__c[]{awardNoReceipt, awardExistingRefund, awardValid};
        insert awards;

        // Requery awards to populate relationship and formula fields
        for(Graduation_Award__c award: [
            SELECT Student_Person_Id__c, Receipt_Number_External_System__c,
                Graduation_Application__c, Graduation_Application__r.Graduation_Calendar__c
            FROM Graduation_Award__c WHERE Id IN :awards
        ]) {
            if(award.Id == awardNoReceipt.Id) {
                awardNoReceipt = award;
            }
            if(award.Id == awardExistingRefund.Id) {
                awardExistingRefund = award;
            }
            if(award.Id == awardValid.Id) {
                awardValid = award;
            }
        }

        // Create existing refund for EXT456
        insert new Graduation_Payment__c(
            Graduation_Application__c = app.Id,
            Receipt_Number__c = 'EXT456',
            Type__c = 'Refund',
            Origin__c = 'External',
            Refund_Status__c = 'Succeeded'
        );

        // WHEN - Get refund info for all awards
        Map<Id, GradsPaymentsService.RefundInfo> refundInfoMap = GradsPaymentsService.getExternalRefundInfo(
            new List<Graduation_Award__c>{awardNoReceipt, awardExistingRefund, awardValid}
        );

        // THEN - Verify all scenarios in one test
        GradsPaymentsService.RefundInfo info1 = refundInfoMap.get(awardNoReceipt.Id);
        Assert.isFalse(info1.hasPayment, 'No receipt should be detected');
        Assert.areEqual(GradsPaymentsService.NoRefundReason.NO_PAYMENT, info1.nonRefundableReason, 'Incorrect reason for no receipt');

        GradsPaymentsService.RefundInfo info2 = refundInfoMap.get(awardExistingRefund.Id);
        Assert.isFalse(info2.isRefundable, 'Existing refund should block new refund');

        GradsPaymentsService.RefundInfo info3 = refundInfoMap.get(awardValid.Id);
        Assert.isTrue(info3.isRefundable, 'Valid receipt should allow refund');
        Assert.isTrue(info3.isWithinRefundPeriod, 'Should be within refund period');
    }

    @IsTest
    static void testCreateRefunds() {
        // GIVEN - Awards for both Stripe and External refunds
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Payment__c payment = [SELECT Id FROM Graduation_Payment__c LIMIT 1];

        Graduation_Award__c stripeAward = createAward(app.Id, payment.Id, null);
        Graduation_Award__c externalAward = createAward(app.Id, null, 'EXT123');
        insert new List<Graduation_Award__c>{stripeAward, externalAward};

        // WHEN - Create both types of refunds
        Test.startTest();
        Graduation_Payment__c stripeRefund = GradsPaymentsService.createStripeRefund(stripeAward, 200);
        GradsPaymentsService.createExternalRefunds(new List<Graduation_Award__c>{externalAward}, 'Requested');
        Test.stopTest();

        // THEN - Verify Stripe refund
        Assert.areEqual('Graduation Portal', stripeRefund.Origin__c, 'Incorrect origin for Stripe refund');
        Assert.areEqual('Requested', stripeRefund.Refund_Status__c, 'Incorrect status');

        // THEN - Verify External refund
        List<Graduation_Payment__c> externalRefunds = [
            SELECT Receipt_Number__c
            FROM Graduation_Payment__c
            WHERE Origin__c = 'External'
        ];
        Assert.areEqual(1, externalRefunds.size(), 'One external refund should be created');
        Assert.areEqual('EXT123', externalRefunds[0].Receipt_Number__c, 'Incorrect receipt number');
    }
}