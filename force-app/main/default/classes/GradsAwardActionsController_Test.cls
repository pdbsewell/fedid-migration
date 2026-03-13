/**
 * @description Test class for GradsAwardActionsController
 * @group       Grads
 */
@IsTest(IsParallel=true)
private class GradsAwardActionsController_Test {

    @TestSetup
    static void setupTestData() {
        // GIVEN - Common test data
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
            Graduation_Calendar__c = cal.Id,
            Attendance_Mode__c = 'Attending'
        );
        insert app;

        insert new Calendar_Dates__c(
            Name = 'RFND-END',
            CalendarId__c = cal.Id,
            Date_Value__c = Date.today().addDays(7)
        );

        insert new Graduation_Payment__c(
            Graduation_Application__c = app.Id,
            Total_Amount__c = 200,
            Attendance_Fee_Unit_Amount__c = 200,
            Type__c = 'Charge',
            Origin__c = 'Graduation Portal'
        );
    }

    private static Graduation_Award__c createAward(Id appId, Id paymentId, String receipt) {
        return new Graduation_Award__c(
            Graduation_Application__c = appId,
            Graduation_Payment__c = paymentId,
            Receipt_Number_External_System__c = receipt,
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
    static void testGetAwardInfo() {
        // GIVEN
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Payment__c payment = [SELECT Id FROM Graduation_Payment__c LIMIT 1];

        Graduation_Award__c awardWithExt = createAward(app.Id, null, 'RECEIPT123');
        awardWithExt.Is_Attending_Ceremony__c = true;
        awardWithExt.Has_Attendance_Fee_Waiver__c = true;
        awardWithExt.Graduation_Payment__c = null;

        Graduation_Award__c awardWithStripe = createAward(app.Id, payment.Id, null);
        awardWithStripe.Is_Attending_Ceremony__c = false;
        awardWithStripe.Cancellation_Date__c = Datetime.now();
        insert new List<Graduation_Award__c>{awardWithExt, awardWithStripe};

        // WHEN - Award info is requested
        Test.startTest();
        GradsAwardActionsController.AwardInfo info1 = GradsAwardActionsController.getAwardInfo(awardWithExt.Id);
        GradsAwardActionsController.AwardInfo info2 = GradsAwardActionsController.getAwardInfo(awardWithStripe.Id);
        Test.stopTest();

        // THEN - Award info should be as expected
        Assert.isTrue(info1.isAttending, 'Should return attendance status');
        Assert.isTrue(info1.hasFeeWaiver, 'Should detect fee waiver');
        Assert.isTrue(info1.hasReceiptNumber, 'Should detect receipt number');
        Assert.isFalse(info1.isCancelled, 'Should not be cancelled');
        Assert.isTrue(info1.refundInfo.isExternalPayment, 'Should detect external payment');
        Assert.isTrue(info1.refundInfo.isRefundable, 'Should be refundable');

        Assert.isTrue(info2.isCancelled, 'Should detect cancellation');
        Assert.isFalse(info2.isAttending, 'Should detect non-attendance');
        Assert.isFalse(info2.hasFeeWaiver, 'Should detect no fee waiver');
        Assert.isFalse(info2.refundInfo.isExternalPayment, 'Should detect stripe payment');
        Assert.isTrue(info2.refundInfo.isRefundable, 'Should be refundable');
    }

    @IsTest
    static void testCancelAward() {
        // GIVEN
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Payment__c payment = [SELECT Id FROM Graduation_Payment__c LIMIT 1];
        Graduation_Award__c award = createAward(app.Id, payment.Id, null);
        insert award;

        // WHEN - Cancel with refund
        Test.startTest();
        GradsAwardActionsController.cancelAward(award.Id, true);
        Test.stopTest();

        // THEN - Cancellation date should be set and payment cleared
        Graduation_Award__c updatedAward = [
            SELECT Cancellation_Date__c, Graduation_Payment__c
            FROM Graduation_Award__c WHERE Id = :award.Id
        ];
        Assert.isNotNull(updatedAward.Cancellation_Date__c, 'Cancellation date should be set');
        Assert.isNull(updatedAward.Graduation_Payment__c, 'Payment should be cleared after refund');
    }

    @IsTest
    static void testChangeAttendance() {
        // GIVEN
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Payment__c payment = [SELECT Id FROM Graduation_Payment__c LIMIT 1];
        Graduation_Award__c award = createAward(app.Id, payment.Id, null);
        insert award;

        // WHEN - Switch to non-attending with refund
        GradsAwardActionsController.changeAttendance(award.Id, false, true, null, false);
        Graduation_Award__c result1 = [
            SELECT Is_Attending_Ceremony__c, Graduation_Payment__c, Graduation_Application__r.Attendance_Mode__c
            FROM Graduation_Award__c WHERE Id = :award.Id
        ];
        GradsAwardActionsController.changeAttendance(award.Id, true, false, null, false);
        Graduation_Award__c result2 = [
            SELECT Is_Attending_Ceremony__c, Graduation_Payment__c, Graduation_Application__r.Attendance_Mode__c
            FROM Graduation_Award__c WHERE Id = :award.Id
        ];

        // THEN - Attendance should be updated and refund processed
        Assert.isFalse(result1.Is_Attending_Ceremony__c, 'Should update attendance');
        Assert.isNull(result1.Graduation_Payment__c, 'Should process refund');
        Assert.areEqual('In Absentia', result1.Graduation_Application__r.Attendance_Mode__c, 'Should update attendance mode');

        Assert.isTrue(result2.Is_Attending_Ceremony__c, 'Should update attendance');
        Assert.areEqual('Attending', result2.Graduation_Application__r.Attendance_Mode__c, 'Should update attendance mode');
    }

    @IsTest
    static void testAddFeeWaiver() {
        // GIVEN
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Payment__c payment = [SELECT Id FROM Graduation_Payment__c LIMIT 1];
        Graduation_Award__c award = createAward(app.Id, payment.Id, null);
        insert award;

        // WHEN - Fee waiver added
        Test.startTest();
        GradsAwardActionsController.addFeeWaiver(award.Id, 'WAIVER123');
        Test.stopTest();

        // THEN - Fee waiver should be added
        Graduation_Award__c updatedAward = [SELECT Has_Attendance_Fee_Waiver__c, Receipt_Number_External_System__c
        FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.isTrue(updatedAward.Has_Attendance_Fee_Waiver__c, 'Should add fee waiver');
        Assert.areEqual('WAIVER123', updatedAward.Receipt_Number_External_System__c, 'Should set receipt');
    }
}