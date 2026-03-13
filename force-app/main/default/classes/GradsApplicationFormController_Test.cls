/**
 * @description Test class for GradsApplicationFormController
 * @group       Grads
 * @revision    2025-01-12 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GradsApplicationFormController_Test {

    @IsTest
    static void testCreateApplication() {
        // GIVEN - Everything needed to create a new application
        Contact c = new Contact(FirstName = 'John', LastName = 'Crichton', Person_ID_unique__c = '4444');
        TriggerCommon.disableTrigger('Contact');
        insert c;
        Calendar__c cal = new Calendar__c(
            Calendar_Code__c = '12899', Category__c = 'Graduation', Type__c = 'GRAD1', Type_Alt__c = 'Clayton'
        );
        insert cal;

        GradsApplicationFormController.Application app = new GradsApplicationFormController.Application();
        app.contactId = c.Id;
        app.studentPersonId = '4444';
        app.calendarId = cal.Id;
        app.studentTestamurName = 'John Crichton';
        app.studentPersonalEmail = 'john.chrichton@example.com';
        app.status = 'Draft';
        app.hasLateFeeWaiver = false;

        GradsAwardFormController.Award award = new GradsAwardFormController.Award();
        award.courseCode = '123';
        award.awardCourseCode = '123';
        award.awardCode1 = '123';
        award.courseTitle = 'Test Course';
        award.awardTitle1 = 'Test Award';
        award.awardCourseTitle = 'Test Course';
        award.courseVersionNumber = 1;
        award.awardCourseVersionNumber = 1;
        award.awardTypeIndicator = 'SINGLE';
        award.isAttendingCeremony = false;
        app.awards = new GradsAwardFormController.Award[]{award};

        Id appId = GradsApplicationFormController.createApplication(app);
        Assert.isNotNull(appId);
        Graduation_Application__c createdApp = [
            SELECT Expected_Attendance_Fee_Unit_Amount__c FROM Graduation_Application__c WHERE Id = :appId
        ];
        Assert.areEqual(GradsUtils.getAppConfig().prices.attendanceAustralia, createdApp.Expected_Attendance_Fee_Unit_Amount__c);
    }

    @IsTest
    static void testGetStudentData() {
        // GIVEN - Some existing contacts/apps/cals
        Contact c = new Contact(FirstName = 'John', LastName = 'Crichton', Person_ID_unique__c = '4444');
        TriggerCommon.disableTrigger('Contact');
        insert c;
        Calendar__c cal1 = new Calendar__c(Calendar_Code__c = '12899', Category__c = 'Graduation', Type__c = 'GRAD1');
        Calendar__c cal2 = new Calendar__c(Calendar_Code__c = '12915', Category__c = 'Graduation', Type__c = 'GRAD-OS-K1');
        Calendar__c cal3 = new Calendar__c(Calendar_Code__c = '13281', Category__c = 'Graduation', Type__c = 'GRAD2');
        insert new List<Calendar__c>{cal1, cal2, cal3};
        Graduation_Application__c app1 = new Graduation_Application__c(Student__c = c.Id, Graduation_Calendar__c = cal1.Id, Status__c = 'Draft');
        Graduation_Application__c app2 = new Graduation_Application__c(Student__c = c.Id, Graduation_Calendar__c = cal2.Id, Status__c = 'Cancelled');
        insert new List<Graduation_Application__c>{app1, app2};

        // WHEN - Getting student data
        GradsApplicationFormController.StudentData data = GradsApplicationFormController.getStudentData(c.Id);

        // THEN - The expected data should be returned
        Assert.areEqual(1, data.appsByCalendarCode.size());
        Assert.areEqual(app1.Id, data.appsByCalendarCode.get(cal1.Calendar_Code__c));
        Assert.areEqual(3, data.gradCalendars.size());
    }

    @IsTest
    static void testSearchContacts() {
        // GIVEN - Some contacts to search for
        Contact c1 = new Contact(FirstName = 'John', LastName = 'Crichton', Person_ID_unique__c = '4444');
        Contact c2 = new Contact(FirstName = 'Aeryn', LastName = 'Sun', Person_ID_unique__c = '5555');
        Contact c3 = new Contact(FirstName = 'Ka', LastName = 'Dargo', Person_ID_unique__c = '6666');
        Contact c4 = new Contact(FirstName = 'Chaka', LastName = 'Kah', Person_ID_unique__c = '7777');
        TriggerCommon.disableTrigger('Contact');
        insert new List<Contact>{c1, c2, c3, c4};

        // WHEN - Searching for contacts
        Test.setFixedSearchResults(new Id[]{c1.Id}); // mock because SOSL not supported in tests
        List<Contact> results1 = GradsApplicationFormController.searchContacts('Joh', false);
        Test.setFixedSearchResults(new Id[]{c4.Id, c3.Id}); // mock because SOSL not supported in tests
        List<Contact> results2 = GradsApplicationFormController.searchContacts('Ka', false);
        List<Contact> results3 = GradsApplicationFormController.searchContacts('7777', true);

        // THEN - The expected results should be returned
        Assert.areEqual(1, results1.size());
        Assert.areEqual(c1.Id, results1[0].Id);

        Assert.areEqual(2, results2.size());
        Assert.areEqual(c4.Id, results2[0].Id);
        Assert.areEqual(c3.Id, results2[1].Id);

        Assert.areEqual(1, results3.size());
        Assert.areEqual(c4.Id, results3[0].Id);
    }

    @IsTest
    static void testSetApplicationCalendar() {
        // GIVEN - A contact and an application
        Contact c = new Contact(FirstName = 'John', LastName = 'Crichton', Person_ID_unique__c = '4444');
        TriggerCommon.disableTrigger('Contact');
        insert c;
        Calendar__c cal1 = new Calendar__c(Calendar_Code__c = '12899', Category__c = 'Graduation', Type__c = 'GRAD1');
        Calendar__c cal2 = new Calendar__c(Calendar_Code__c = '12915', Category__c = 'Graduation', Type__c = 'GRAD-OS-K1');
        insert new List<Calendar__c>{cal1, cal2};
        Graduation_Application__c app = new Graduation_Application__c(Student__c = c.Id, Graduation_Calendar__c = cal1.Id, Status__c = 'Draft');
        insert app;

        // WHEN - Setting the application calendar
        GradsApplicationFormController.setApplicationCalendar(app.Id, cal2.Id);

        // THEN - The application should be updated with the new calendar
        app = [SELECT Graduation_Calendar__c FROM Graduation_Application__c WHERE Id = :app.Id];
        Assert.areEqual(cal2.Id, app.Graduation_Calendar__c, 'Application calendar should be updated');
    }

    @IsTest
    static void testGetEligibility() {
        // GIVEN - An application
        Contact c = new Contact(FirstName = 'John', LastName = 'Crichton', Person_ID_unique__c = '4444');
        TriggerCommon.disableTrigger('Contact');
        insert c;
        Calendar__c cal = new Calendar__c(Calendar_Code__c = '12899', Category__c = 'Graduation', Type__c = 'GRAD1');
        insert cal;
        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = c.Id, Graduation_Calendar__c = cal.Id, Status__c = 'Cancelled'
        );
        insert app;

        // Mock the Callista response
        String jsonBody = '{"graduationEligibilityDetails": {"courseAttempts": [{"courseCode": "CS101", "courseVersionNumber": 1, "courseTitle": "Intro to CS"}]}}';
        Test.setMock(HttpCalloutMock.class, new GradsCallistaCalloutService_Test.MockCallistaResp(200, jsonBody));

        // WHEN - Getting eligibility details
        Test.startTest();
        GradsApplicationFormController.EligibilityApiResponse ear = GradsApplicationFormController.getAppEligibilityDetails(app.Id);
        Test.stopTest();

        // THEN - The eligibility details should be returned
        Assert.isTrue(ear.success, 'Eligibility check should be successful: ' + ear.errorMessage);
    }
}