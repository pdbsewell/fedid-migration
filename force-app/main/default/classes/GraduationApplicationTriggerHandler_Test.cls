/**
 * @description Test class for GraduationApplicationTriggerHandler
 * @group       Grads
 * @revision    2024-08-20 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GraduationApplicationTriggerHandler_Test {

    @TestSetup
    static void setupTestData() {
        Contact student = new Contact(
            LastName = 'Test',
            FirstName = 'Person',
            Person_ID_unique__c = 'TEST001',
            Email = 'test.person@example.com'
        );
        insert student;

        Calendar__c cal = new Calendar__c(
            Calendar_Code__c = '4567',
            Category__c = 'GRADUATION'
        );
        insert cal;
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
    static void testUniqueKeyClear() {
        // GIVEN - An application with a Unique Key
        Contact student = [SELECT Person_ID_unique__c FROM Contact LIMIT 1];
        Calendar__c cal = [SELECT Calendar_Code__c FROM Calendar__c LIMIT 1];
        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = student.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Applied',
            Unique_Key__c = '123456'
        );
        insert app;

        // WHEN 1- Status is changed to 'Cancelled'
        Test.startTest();
        app.Status__c = 'Cancelled';
        update app;
        Graduation_Application__c clearedResult = [SELECT Unique_Key__c FROM Graduation_Application__c WHERE Id = :app.Id];
        // WHEN 2 - Status is changed back to 'Applied'
        app.Status__c = 'Applied';
        update app;
        Graduation_Application__c setResult = [SELECT Unique_Key__c FROM Graduation_Application__c WHERE Id = :app.Id];
        Test.stopTest();

        // THEN 1 - Unique Key should be cleared
        Assert.isNull(clearedResult.Unique_Key__c, 'Unique Key should be cleared when application is cancelled');

        // THEN 2 - Unique Key should be set
        Assert.areEqual(
            cal.Calendar_Code__c + '|' + student.Person_ID_unique__c,
            setResult.Unique_Key__c,
            'Unique Key set when application is no longer cancelled'
        );
    }

    @IsTest
    static void testHandleNameChange() {
        // GIVEN - An application with a name change
        Contact student = [SELECT Id, FirstName, LastName FROM Contact LIMIT 1];
        Calendar__c cal = [SELECT Id FROM Calendar__c LIMIT 1];

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = student.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Applied',
            Student_Testamur_Name__c = 'John Doe',
            Student_Testamur_Name_Change_Status__c = 'Pending'
        );
        insert app;

        // WHEN - Name change is approved
        Test.startTest();
        app.Student_Testamur_Name_Change_Status__c = 'Rejected';
        app.Student_Testamur_Name_Reject_Reason__c = 'Test Reason';
        update app;
        Test.stopTest();

        // THEN - Name should be reset
        app = [SELECT Student_Testamur_Name__c FROM Graduation_Application__c WHERE Id = :app.Id];
        Assert.areEqual(student.FirstName + ' ' + student.LastName, app.Student_Testamur_Name__c, 'Testamur name should be reset to original name when rejected');
    }

    @IsTest
    static void testDetectWriteBackRequired_Update() {
        // GIVEN - An application with an award
        Contact student = [SELECT Id FROM Contact LIMIT 1];
        Calendar__c cal = [SELECT Id FROM Calendar__c LIMIT 1];

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = student.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Applied',
            Student_Testamur_Name__c = 'John Doe'
        );
        TriggerCommon.disableTrigger('Graduation_Application__c');
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert app;
        Graduation_Award__c award = createAward(app.Id);
        insert award;
        TriggerCommon.enableTrigger('Graduation_Application__c');
        TriggerCommon.enableTrigger('Graduation_Award__c');

        // WHEN - Update a monitored field
        Test.startTest();
        app.Student_Testamur_Name__c = 'John Smith';
        update app;
        Test.stopTest();

        // THEN - Writeback should be requested
        award = [SELECT Callista_Writeback_Requested_Time__c FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.isNotNull(award.Callista_Writeback_Requested_Time__c, 'Writeback should be requested on monitored field update of parent application');
    }

    @IsTest
    static void testDetectWriteBackRequired_NoChange() {
        // GIVEN - An application with an award
        Contact student = [SELECT Id FROM Contact LIMIT 1];
        Calendar__c cal = [SELECT Id FROM Calendar__c LIMIT 1];

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = student.Id,
            Graduation_Calendar__c = cal.Id,
            Status__c = 'Applied',
            Student_Testamur_Name__c = 'John Doe'
        );
        TriggerCommon.disableTrigger('Graduation_Application__c');
        TriggerCommon.disableTrigger('Graduation_Award__c');
        insert app;

        Graduation_Award__c award = createAward(app.Id);
        insert award;
        TriggerCommon.enableTrigger('Graduation_Application__c');
        TriggerCommon.enableTrigger('Graduation_Award__c');

        // WHEN - Update a non-monitored field
        Test.startTest();
        app.Expected_Attendance_Fee_Unit_Amount__c = 20; // Non-monitored field
        update app;
        Test.stopTest();

        // THEN - Writeback should not be requested
        award = [SELECT Callista_Writeback_Requested_Time__c FROM Graduation_Award__c WHERE Id = :award.Id];
        Assert.isNull(award.Callista_Writeback_Requested_Time__c, 'Writeback should not be requested for non-monitored field update on parent application');
    }
}