/**
 * @description Test class for GraduationAwardTriggerHandler
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GraduationAwardTriggerHandler_Test {

    @TestSetup
    static void setupTestData() {
        Contact student = new Contact(
            LastName = 'TestStudent',
            FirstName = 'John',
            Person_ID_unique__c = 'TEST001'
        );
        insert student;

        Calendar__c cal = new Calendar__c(
            Calendar_Code__c = '4567',
            Category__c = 'GRADUATION'
        );
        insert cal;

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = student.Id,
            Status__c = 'Applied',
            Graduation_Calendar__c = cal.Id
        );
        insert app;
    }

    private static Graduation_Award__c createAward(Id appId) {
        return new Graduation_Award__c(
            Graduation_Application__c = appId,
            Award_Code_1__c = '1012',
            Award_Course_Code__c = 'A2000',
            Award_Course_Version__c = 2,
            Award_Course_Title__c = 'Bachelor of Arts',
            Award_Title_1__c = 'Bachelor of Arts',
            Award_Type__c = 'SINGLE',
            Course_Code__c = 'A2000',
            Course_Title__c = 'Bachelor of Arts',
            Course_Version_Number__c = 1,
            Integration_Id__c = appId + '|' + '1012|' + System.currentTimeMillis(),
            Is_Attending_Ceremony__c = true
        );
    }

    @IsTest
    static void testDetectWriteBackRequired_Insert() {
        // GIVEN - A new award
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];

        // WHEN - Insert a new award
        Test.startTest();
        Graduation_Award__c award = createAward(app.Id);
        insert award;
        Test.stopTest();

        // THEN - Writeback should be requested
        award = [SELECT Callista_Writeback_Requested_Time__c FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.isNotNull(award.Callista_Writeback_Requested_Time__c, 'Writeback should be requested on insert');

        Assert.areEqual(1, GraduationAwardTriggerHandler.obdAppEvents.size(), 'An event should be published');
        Assert.areEqual(award.Id, GraduationAwardTriggerHandler.obdAppEvents[0].Award_Id__c, 'Published event should contain the correct Award Id');
    }

    @IsTest
    static void testDetectWriteBackRequired_Update() {
        // GIVEN - An award with a monitored field updated
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Award__c award = createAward(app.Id);
        Graduation_Award__c award2 = award.clone();
        award2.Award_Code_1__c = '2021';
        award2.Integration_Id__c = app.Id + '|' + '2021|' + System.currentTimeMillis();
        Graduation_Award__c[] awards = new Graduation_Award__c[]{award, award2};
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert awards;
        TriggerCommon.enableTrigger('Graduation_Award__c');

        // Reset fields
        award.Callista_Writeback_Requested_Time__c = null;
        award2.Callista_Writeback_Requested_Time__c = null;
        award2.Cancellation_Date__c = Datetime.now();
        award2.Cancellation_Succeeded__c = true;
        update awards;

        // WHEN - Update a monitored field
        Test.startTest();
        award.Award_Code_1__c = 'TEST02';
        award2.Award_Code_1__c = 'TEST03';
        update awards;
        Test.stopTest();

        // THEN - Writeback should be requested
        award = [SELECT Callista_Writeback_Requested_Time__c FROM Graduation_Award__c WHERE Id = :award.Id];
        award2 = [SELECT Callista_Writeback_Requested_Time__c FROM Graduation_Award__c WHERE Id = :award2.Id];
        Assert.isNotNull(award.Callista_Writeback_Requested_Time__c, 'Writeback should be requested on monitored field update');
        Assert.isNull(award2.Callista_Writeback_Requested_Time__c, 'Writeback should not be requested on cancelled award');

        Assert.areEqual(1, GraduationAwardTriggerHandler.obdAppEvents.size(), 'An event should be published');
        Assert.areEqual(award.Id, GraduationAwardTriggerHandler.obdAppEvents[0].Award_Id__c, 'Published event should contain the correct Award Id');
    }

    @IsTest
    static void testDetectWriteBackRequired_NoChange() {
        // GIVEN - An award with a non-monitored field updated
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Award__c award = createAward(app.Id);
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert award;
        TriggerCommon.enableTrigger('Graduation_Award__c');

        // Reset the field
        award.Callista_Writeback_Requested_Time__c = null;
        update award;

        // WHEN - Update a non-monitored field
        Test.startTest();
        award.Document_Callista_Id__c = '12345'; // Non-monitored field
        update award;
        Test.stopTest();

        // THEN - Writeback should not be requested
        award = [SELECT Callista_Writeback_Requested_Time__c FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.isNull(award.Callista_Writeback_Requested_Time__c, 'Writeback should not be requested for non-monitored field update');

        Assert.areEqual(0, GraduationAwardTriggerHandler.obdAppEvents.size(), 'No event should be published');
    }

    @IsTest
    static void testHandlePortalUncancel() {
        // GIVEN - A cancelled award with a transaction number
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Award__c award = createAward(app.Id);
        award.Cancellation_Date__c = Datetime.now();
        award.Cancellation_Succeeded__c = true;
        award.Callista_Transaction_Number__c = 'TX12345';
        
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert award;
        TriggerCommon.enableTrigger('Graduation_Award__c');

        // WHEN - Award is uncancelled by a portal user
        Test.startTest();
        GradsUtils.isPortalUser = true; // Mock the portal user
        award.Cancellation_Date__c = null; // Uncancel the award
        update award;
        Test.stopTest();

        // THEN - Transaction number should be cleared
        award = [SELECT Callista_Transaction_Number__c FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.isNull(award.Callista_Transaction_Number__c, 'Transaction number should be cleared when uncancelled by portal user');
    }

    @IsTest
    static void testHandlePortalUncancel_NotPortalUser() {
        // GIVEN - A cancelled award with a transaction number
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];
        Graduation_Award__c award = createAward(app.Id);
        award.Cancellation_Date__c = Datetime.now();
        award.Cancellation_Succeeded__c = true;
        award.Callista_Transaction_Number__c = 'TX12345';
        
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert award;
        TriggerCommon.enableTrigger('Graduation_Award__c');

        // WHEN - Award is uncancelled by a non-portal user
        Test.startTest();
        GradsUtils.isPortalUser = false; // Mock a non-portal user
        award.Cancellation_Date__c = null; // Uncancel the award
        update award;
        Test.stopTest();

        // THEN - Transaction number should remain
        award = [SELECT Callista_Transaction_Number__c FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.areEqual('TX12345', award.Callista_Transaction_Number__c, 'Transaction number should remain when uncancelled by non-portal user');
    }

    @IsTest
    static void testCreateExternalRefund() {
        // GIVEN - some awards that will refund and some that wont
        Graduation_Application__c app = [
            SELECT Graduation_Calendar__r.Calendar_Code__c, Student__c
            FROM Graduation_Application__c LIMIT 1
        ];

        Calendar__c calNoRfnd = new Calendar__c(
            Calendar_Code__c = '555',
            Category__c = 'GRADUATION'
        );
        insert calNoRfnd;

        Graduation_Application__c appNoRfnd = new Graduation_Application__c(
            Student__c = app.Student__c,
            Graduation_Calendar__c = calNoRfnd.Id,
            Status__c = 'Applied'
        );
        insert appNoRfnd;

        // configure RFND-END vals
        Calendar_Dates__c cdRfnd = new Calendar_Dates__c(
            Name = 'RFND-END',
            CalendarId__c = app.Graduation_Calendar__r.Id,
            Date_Value__c = Date.today(),
            Calendar_Code__c = app.Graduation_Calendar__r.Calendar_Code__c
        );
        Calendar_Dates__c cdNoRfnd = new Calendar_Dates__c(
            Name = 'RFND-END',
            CalendarId__c = calNoRfnd.Id,
            Date_Value__c = Date.today().addDays(-1),
            Calendar_Code__c = calNoRfnd.Calendar_Code__c
        );
        insert new Calendar_Dates__c[]{cdRfnd, cdNoRfnd};

        // Create awards
        Graduation_Award__c award1 = createAward(app.Id); // will refund
        award1.Receipt_Number_External_System__c = '';
        award1.Is_Attending_Ceremony__c = false;
        Graduation_Award__c award2 = award1.clone(); // already refunded
        Graduation_Award__c award3 = award1.clone(); // won't refund due to calendar
        award3.Graduation_Application__c = appNoRfnd.Id;
        award3.Receipt_Number_External_System__c = '9101';
        Graduation_Award__c award4 = award1.clone(); // will refund via cancel
        award4.Receipt_Number_External_System__c = '3456';
        award4.Is_Attending_Ceremony__c = true;
        Graduation_Award__c award5 = award1.clone(); // will refund via inab
        award5.Receipt_Number_External_System__c = '7890';
        award5.Is_Attending_Ceremony__c = true;
        Graduation_Award__c award6 = award1.clone(); // won't refund due to no receipt
        award6.Receipt_Number_External_System__c = '';
        award5.Is_Attending_Ceremony__c = true;
        Graduation_Award__c[] awards = new Graduation_Award__c[]{award1, award2, award3, award4, award5, award6};
        Graduation_Payment__c existingRefund = new Graduation_Payment__c(
            Graduation_Application__c = app.Id,
            Type__c = 'Refund',
            Origin__c = 'External',
            Receipt_Number__c = '5678'
        );
        insert existingRefund;
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert awards;
        TriggerCommon.enableTrigger('Graduation_Award__c');

        // WHEN - Changed causes refund
        award1.Receipt_Number_External_System__c = '1234'; // will refund (already inab)
        award2.Receipt_Number_External_System__c = '5678'; // won't refund (existing refunded)
        award3.Cancellation_Date__c = Datetime.now();      // won't refund (past RFND-END)
        award4.Cancellation_Date__c = Datetime.now();      // will refund via cancel
        award5.Is_Attending_Ceremony__c = false;           // will refund via inab
        award6.Cancellation_Date__c = Datetime.now();      // won't refund (due to no receipt)
        // Mock the portal user
        GradsUtils.isPortalUser = true;
        update awards;

        // THEN - 3 refunds should be created
        List<Graduation_Payment__c> refunds = [
            SELECT Receipt_Number__c, Graduation_Application__c
            FROM Graduation_Payment__c
            WHERE Type__c = 'Refund' AND Origin__c = 'External' AND Id != :existingRefund.Id
        ];

        Assert.areEqual(3, refunds.size(), 'Unexpected number of refunds created');
        Set<String> refundReceipts = new Set<String>{};
        for(Graduation_Payment__c refund : refunds) {
            Assert.areEqual(app.Id, refund.Graduation_Application__c, 'Incorrect Graduation Application');
            refundReceipts.add(refund.Receipt_Number__c);
        }
        Assert.isTrue(refundReceipts.containsAll(new Set<String>{'1234', '3456', '7890'}), 'Unexpected refund receipts created');
    }

}