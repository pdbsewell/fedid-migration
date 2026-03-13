/**
 * @description Test class for GradsAwardFormController
 * @group       Grads
 * @revision    2024-11-12 - Tom Gangemi - Initial version
 */
@IsTest(IsParallel=true)
private class GradsAwardFormController_Test {

    private static final String PERSON_ID = 'TEST001';
    private static final String COURSE_CODE = '0020';
    private static final String AWARD_CODE = '6007';
    private static final Integer CALENDAR_CODE = 13343;

    @TestSetup
    static void setupTestData() {
        Contact cont = new Contact(
            LastName = 'TestStudent',
            Person_ID_unique__c = PERSON_ID
        );
        insert cont;

        Calendar__c cal = new Calendar__c(
            Category__c = 'Graduation',
            Description__c = '2024 (May) Ceremony',
            Type_Description__c = 'SEM 1',
            Type__c = 'GRAD1',
            Type_Alt__c = 'CLAYTON',
            Calendar_Code__c = String.valueOf(CALENDAR_CODE),
            Sequence_Number__c = CALENDAR_CODE,
            Start_Date__c = Date.newInstance(2024, 5, 01),
            End_Date__c = Date.newInstance(2024, 10, 31)
        );
        insert cal;

        Graduation_Application__c app = new Graduation_Application__c(
            Student__c = cont.Id,
            Graduation_Calendar__c = cal.Id,
            Student_Testamur_Name__c = 'Test Student',
            Expected_Attendance_Fee_Unit_Amount__c = 100,
            Status__c = 'Applied'
        );
        TriggerCommon.disableTrigger('Graduation_Application__c');
        insert app;

        // Create test graduation award
        Graduation_Award__c award = new Graduation_Award__c(
            Graduation_Application__c = app.Id,
            Course_Code__c = COURSE_CODE,
            Award_Type__c = 'Alternative Exit',
            Award_Course_Code__c = '0017',
            Award_Course_Version__c = 1,
            Award_Course_Title__c = 'Doctor of Philosophy',
            Award_Code_1__c = AWARD_CODE,
            Award_Title_1__c = 'Master of Arts',
            Course_Version_Number__c = 6,
            Course_Title__c = 'Doctor of Philosophy',
            Integration_Id__c = 'TEST001',
            Bypass_Writeback_Trigger__c = true
        );
        insert award;
    }

    @IsTest
    static void testGetFormDataForApplication() {
        // GIVEN - A graduation application and mocked eligibility response
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];

        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, createEligibilityRespJson()
        ));

        // WHEN - getFormData is called with application Id
        Test.startTest();
        GradsAwardFormController.AwardFormData result = GradsAwardFormController.getFormData(app.Id);
        Test.stopTest();

        // THEN - Form data should be populated correctly
        Assert.areEqual(PERSON_ID, result.personId, 'Person ID should match');
        Assert.areEqual('application', result.formType, 'Form type should be application');
        Assert.isNotNull(result.awards, 'Awards should not be null');
        Assert.isTrue(result.awards.size() > 0, 'Should have at least one award');
        Assert.isNull(result.currentAward, 'Current award should be null for application');
    }

    @IsTest
    static void testGetFormDataForAward() {
        // GIVEN - A graduation award and mocked eligibility response
        Graduation_Award__c award = [SELECT Id FROM Graduation_Award__c LIMIT 1];

        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, createEligibilityRespJson()
        ));

        // WHEN - getFormData is called with award Id
        Test.startTest();
        GradsAwardFormController.AwardFormData result = GradsAwardFormController.getFormData(award.Id);
        Test.stopTest();

        // THEN - Form data should be populated correctly
        Assert.areEqual(PERSON_ID, result.personId, 'Person ID should match');
        Assert.areEqual('award', result.formType, 'Form type should be award');
        Assert.isNotNull(result.awards, 'Awards should not be null');
        Assert.isTrue(result.awards.size() > 0, 'Should have at least one award');
        Assert.isNotNull(result.currentAward, 'Current award should be populated');
        Assert.areEqual(AWARD_CODE, result.currentAward.awardCode1, 'Award code should match');
    }

    @IsTest
    static void testUpdateAward() {
        // GIVEN - An existing award and update data
        Graduation_Award__c existingAward = [SELECT Id FROM Graduation_Award__c LIMIT 1];

        GradsAwardFormController.Award updateData = new GradsAwardFormController.Award();
        updateData.courseCode = '0021';
        updateData.courseVersionNumber = 6;
        updateData.courseTitle = 'Doctor of Good Times';
        updateData.awardTypeIndicator = 'ALTERNATIVE EXITS';
        updateData.awardCourseCode = '0018';
        updateData.awardCourseVersionNumber = 2;
        updateData.awardCourseTitle = 'Updated Title';
        updateData.awardCode1 = '6008';
        updateData.awardTitle1 = 'Updated Award';

        // WHEN - updateAward is called
        Test.startTest();
        GradsAwardFormController.updateAward(existingAward.Id, updateData, false);
        Test.stopTest();

        // THEN - Award should be updated with new values
        Graduation_Award__c updatedAward = [
            SELECT Course_Code__c, Award_Type__c, Award_Course_Code__c,
                Award_Course_Version__c, Award_Course_Title__c,
                Award_Code_1__c, Award_Title_1__c
            FROM Graduation_Award__c
            WHERE Id = :existingAward.Id
        ];

        Assert.areEqual('0021', updatedAward.Course_Code__c);
        Assert.areEqual('Alternative Exit', updatedAward.Award_Type__c);
        Assert.areEqual('0018', updatedAward.Award_Course_Code__c);
        Assert.areEqual(2, updatedAward.Award_Course_Version__c);
        Assert.areEqual('Updated Title', updatedAward.Award_Course_Title__c);
        Assert.areEqual('6008', updatedAward.Award_Code_1__c);
        Assert.areEqual('Updated Award', updatedAward.Award_Title_1__c);
    }

    @IsTest
    static void testUpdateAwardWithPendingCancellation() {
        // GIVEN - An award pending cancellation
        Graduation_Award__c existingAward = [SELECT Id FROM Graduation_Award__c LIMIT 1];
        existingAward.Cancellation_Date__c = Datetime.now();
        existingAward.Cancellation_Succeeded__c = false;
        existingAward.Callista_Transaction_Number__c = '12345';
        update existingAward;

        GradsAwardFormController.Award updateData = new GradsAwardFormController.Award();
        updateData.courseCode = '0021';

        // WHEN - updateAward is called
        try {
            Test.startTest();
            GradsAwardFormController.updateAward(existingAward.Id, updateData, false);
            Test.stopTest();
            Assert.fail('Should have thrown an exception');
        } catch(AuraHandledException e) {
            // THEN - Should throw exception
            Assert.isTrue(e.getMessage().contains('pending cancellation'), 'Unexpected error message: ' + e.getMessage());
        }
    }

    @IsTest
    static void testCreateAwards() {
        // GIVEN - A graduation application and new award data
        Graduation_Application__c app = [SELECT Id FROM Graduation_Application__c LIMIT 1];

        List<GradsAwardFormController.Award> newAwards = new List<GradsAwardFormController.Award>();
        GradsAwardFormController.Award award = new GradsAwardFormController.Award();
        award.courseCode = '0022';
        award.awardTypeIndicator = 'SINGLE';
        award.awardCourseCode = '0022';
        award.awardCourseVersionNumber = 1;
        award.awardCourseTitle = 'New Award';
        award.awardCode1 = '7001';
        award.awardTitle1 = 'New Title';
        award.isAttendingCeremony = true;
        award.receiptNumber = 'REC123';
        award.staffComments = 'Test comments';
        award.courseVersionNumber = 1;
        award.courseTitle = 'Course Title';
        newAwards.add(award);

        // WHEN - createAwards is called
        Test.startTest();
        List<Id> results = GradsAwardFormController.createAwards(app.Id, newAwards);
        Test.stopTest();

        // THEN - New awards should be created
        Assert.areEqual(1, results.size(), 'Should create one award');

        Graduation_Award__c createdAward = [
            SELECT Course_Code__c, Award_Type__c, Is_Attending_Ceremony__c,
                Receipt_Number_External_System__c, Staff_Comments__c
            FROM Graduation_Award__c
            WHERE Id = :results[0]
        ];

        Assert.areEqual('0022', createdAward.Course_Code__c);
        Assert.areEqual('Single', createdAward.Award_Type__c);
        Assert.isTrue(createdAward.Is_Attending_Ceremony__c);
        Assert.areEqual('REC123', createdAward.Receipt_Number_External_System__c);
        Assert.areEqual('Test comments', createdAward.Staff_Comments__c);
    }

    private static String createEligibilityRespJson() {
        GradsCallistaCalloutService.EligibilityDetails eligibilityDetails = new GradsCallistaCalloutService.EligibilityDetails();
        eligibilityDetails.courseAttempts = new List<GradsCallistaCalloutService.EligibilityCourseAttempt>();

        GradsCallistaCalloutService.EligibilityCourseAttempt courseAttempt = new GradsCallistaCalloutService.EligibilityCourseAttempt();
        courseAttempt.courseCode = COURSE_CODE;
        courseAttempt.courseTitle = 'Doctor of Philosophy';
        courseAttempt.courseVersionNumber = 6;
        courseAttempt.graduationAvailableSelections = new List<GradsCallistaCalloutService.EligibilityGraduationAvailableSelection>();

        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gs = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        gs.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        gs.awardDetails.awardCode1 = AWARD_CODE;
        gs.awardDetails.awardTitle1 = 'Master of Arts';
        gs.awardDetails.awardTypeIndicator = 'ALTERNATIVE EXITS';
        gs.awardDetails.awardCourseCode = '0017';
        gs.awardDetails.awardCourseTitle = 'Doctor of Philosophy';
        gs.awardDetails.awardCourseVersionNumber = 1;
        courseAttempt.graduationAvailableSelections.add(gs);

        GradsCallistaCalloutService.EligibilityGraduationApplication[] existingApps = new List<GradsCallistaCalloutService.EligibilityGraduationApplication>();
        GradsCallistaCalloutService.EligibilityGraduationApplication ea1 = new GradsCallistaCalloutService.EligibilityGraduationApplication();
        ea1.transactionNo = '12345';
        ea1.applicationStatus = 'Applied';
        GradsCallistaCalloutService.EligibilityAppAward ea1Award = new GradsCallistaCalloutService.EligibilityAppAward();
        ea1Award.awardCode1 = AWARD_CODE;
        ea1Award.awardCourseCode1 = '0017';
        ea1.awardDetails = ea1Award;
        existingApps.add(ea1);
        courseAttempt.graduationApplications = existingApps;

        eligibilityDetails.courseAttempts.add(courseAttempt);

        GradsCallistaCalloutService.EligibilityResponse mockResponse = new GradsCallistaCalloutService.EligibilityResponse();
        mockResponse.graduationEligibilityDetails = eligibilityDetails;

        return JSON.serialize(mockResponse);
    }
}