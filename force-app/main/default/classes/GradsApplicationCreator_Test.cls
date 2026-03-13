/**
 * @description Test class for GradsApplicationCreator
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 * @revision    2025-04-14 - Updated to match revised GradsApplicationCreator class
 */
@IsTest(IsParallel=true)
private class GradsApplicationCreator_Test {

    @TestSetup
    static void setupTestData() {
        Contact student1 = new Contact(
            LastName = 'William',
            FirstName = 'Adama',
            Person_ID_unique__c = '101'
        );
        Contact student2 = new Contact(
            LastName = 'Saul',
            FirstName = 'Tigh',
            Person_ID_unique__c = '102'
        );
        Contact student3 = new Contact(
            LastName = 'Laura',
            FirstName = 'Roslin',
            Person_ID_unique__c = '103'
        );
        Contact student4 = new Contact(
            LastName = 'Gaius',
            FirstName = 'Baltar',
            Person_ID_unique__c = '104'
        );
        TriggerCommon.disableTrigger('Contact');
        insert new Contact[]{student1, student2, student3, student4};

        Calendar__c[] calendars = new Calendar__c[0];
        for(Integer i = 0; i < 4; i++) {
            Calendar__c cal = new Calendar__c(
                Calendar_Code__c = String.valueOf(100 + i),
                Category__c = 'GRADUATION',
                Start_Date__c = Date.newInstance(Date.today().year(), 1, 1),
                End_Date__c = Date.newInstance(Date.today().year(), 12, 31)
            );
            calendars.add(cal);
        }
        insert calendars;
    }

    /**
    * @description Test creating applications with a mix of successful and failing inputs
    */
    @IsTest
    static void testCreateApplications_Mixed() {
        /**
         * 6x Application inputs
         *   3x expected successful application inputs
         *     1x with skipEligibility=true
         *     1x with multiple awards
         *     1x with skipEligibility=true and multiple awards
         *   3x expected failed application inputs
         *     1x with invalid course code
         *     1x with multiple awards (where one contains an error)
         *     1x with invalid Application field
         */

        // GIVEN - Set up mix of successful and failing application inputs
        Contact[] students = [SELECT Id, Person_ID_unique__c FROM Contact ORDER BY Person_ID_unique__c ASC];
        Calendar__c[] cals = [SELECT Id, Calendar_Code__c FROM Calendar__c ORDER BY Calendar_Code__c ASC];

        GradsApplicationCreator.ApplicationInput[] appInputs = new GradsApplicationCreator.ApplicationInput[0];

        // SUCCESSFUL APPLICATIONS

        // 1. Application with skipEligibility=true (no callout)
        GradsApplicationCreator.ApplicationInput skipEligibilityApp = new GradsApplicationCreator.ApplicationInput();
        skipEligibilityApp.studentPersonId = students[0].Person_ID_unique__c;
        skipEligibilityApp.personalEmail = 'skip@example.com';
        skipEligibilityApp.testamurName = 'Skip Eligibility Student';
        skipEligibilityApp.calendarSequenceNumber = cals[0].Calendar_Code__c;
        skipEligibilityApp.studentContactId = students[0].Id;
        skipEligibilityApp.gradCalendarId = cals[0].Id;
        skipEligibilityApp.paidAmount = 150;
        skipEligibilityApp.status = 'Applied';
        skipEligibilityApp.skipEligibility = true;

        GradsApplicationCreator.AwardInput skipAward = new GradsApplicationCreator.AwardInput();
        skipAward.courseCode = 'SKIP001';
        skipAward.courseTitle = 'Skip Eligibility Course';
        skipAward.courseVersionNumber = 1;
        skipAward.awardTypeIndicator = 'Single';
        skipAward.awardCode1 = 'SKIP1';
        skipAward.awardCode1Title = 'Skip Eligibility Award';
        skipAward.awardCourseCode = 'SKIP001';
        skipAward.awardCourseTitle = 'Skip Eligibility Course';
        skipAward.awardCourseVersionNumber = 1;
        skipAward.isAttending = true;

        skipEligibilityApp.awards = new GradsApplicationCreator.AwardInput[]{skipAward};
        appInputs.add(skipEligibilityApp);

        // 2. Application with multiple awards (1x callout)
        GradsApplicationCreator.ApplicationInput multiAwardApp = new GradsApplicationCreator.ApplicationInput();
        multiAwardApp.studentPersonId = students[1].Person_ID_unique__c;
        multiAwardApp.personalEmail = 'multi@example.com';
        multiAwardApp.testamurName = 'Multiple Awards Student';
        multiAwardApp.calendarSequenceNumber = cals[1].Calendar_Code__c;
        multiAwardApp.studentContactId = students[1].Id;
        multiAwardApp.gradCalendarId = cals[1].Id;
        multiAwardApp.paidAmount = 200;
        multiAwardApp.status = 'Draft';

        GradsApplicationCreator.AwardInput multiAward1 = new GradsApplicationCreator.AwardInput();
        multiAward1.courseCode = '0020';
        multiAward1.awardCode1 = '6007';
        multiAward1.isAttending = true;

        GradsApplicationCreator.AwardInput multiAward2 = new GradsApplicationCreator.AwardInput();
        multiAward2.courseCode = '0020';
        multiAward2.awardCode1 = '3007';
        multiAward2.isAttending = false;

        multiAwardApp.awards = new GradsApplicationCreator.AwardInput[]{multiAward1,multiAward2};
        appInputs.add(multiAwardApp);

        // 3. Application with skipEligibility=true and multiple awards (no callout)
        GradsApplicationCreator.ApplicationInput skipMultiApp = new GradsApplicationCreator.ApplicationInput();
        skipMultiApp.studentPersonId = students[2].Person_ID_unique__c;
        skipMultiApp.personalEmail = 'skipmulti@example.com';
        skipMultiApp.testamurName = 'Skip Multi Student';
        skipMultiApp.calendarSequenceNumber = cals[1].Calendar_Code__c;
        skipMultiApp.studentContactId = students[2].Id;
        skipMultiApp.gradCalendarId = cals[1].Id;
        skipMultiApp.paidAmount = 250;
        skipMultiApp.status = 'Draft';
        skipMultiApp.skipEligibility = true;

        GradsApplicationCreator.AwardInput skipMultiAward1 = new GradsApplicationCreator.AwardInput();
        skipMultiAward1.courseCode = 'SKIPMULTI1';
        skipMultiAward1.courseTitle = 'Skip Multi Course 1';
        skipMultiAward1.courseVersionNumber = 1;
        skipMultiAward1.awardTypeIndicator = 'Single';
        skipMultiAward1.awardCode1 = 'SKIPM1';
        skipMultiAward1.awardCode1Title = 'Skip Multi Award 1';
        skipMultiAward1.awardCourseCode = 'SKIPMULTI1';
        skipMultiAward1.awardCourseTitle = 'Skip Multi Course 1';
        skipMultiAward1.awardCourseVersionNumber = 1;
        skipMultiAward1.isAttending = true;

        GradsApplicationCreator.AwardInput skipMultiAward2 = new GradsApplicationCreator.AwardInput();
        skipMultiAward2.courseCode = 'SKIPMULTI2';
        skipMultiAward2.courseTitle = 'Skip Multi Course 2';
        skipMultiAward2.courseVersionNumber = 2;
        skipMultiAward2.awardTypeIndicator = 'Single';
        skipMultiAward2.awardCode1 = 'SKIPM2';
        skipMultiAward2.awardCode1Title = 'Skip Multi Award 2';
        skipMultiAward2.awardCourseCode = 'SKIPMULTI2';
        skipMultiAward2.awardCourseTitle = 'Skip Multi Course 2';
        skipMultiAward2.awardCourseVersionNumber = 2;
        skipMultiAward2.isAttending = false;

        skipMultiApp.awards = new GradsApplicationCreator.AwardInput[]{skipMultiAward1, skipMultiAward2};
        appInputs.add(skipMultiApp);

        // FAILING APPLICATIONS

        // 4. Application with invalid course code (1x callout)
        GradsApplicationCreator.ApplicationInput invalidCourseApp = new GradsApplicationCreator.ApplicationInput();
        invalidCourseApp.studentPersonId = students[0].Person_ID_unique__c;
        invalidCourseApp.personalEmail = 'invalid@example.com';
        invalidCourseApp.testamurName = 'Invalid Course Student';
        invalidCourseApp.calendarSequenceNumber = cals[0].Calendar_Code__c;
        invalidCourseApp.studentContactId = students[0].Id;
        invalidCourseApp.gradCalendarId = cals[0].Id;
        invalidCourseApp.paidAmount = 150;
        invalidCourseApp.status = 'Applied';

        GradsApplicationCreator.AwardInput invalidCourseAward = new GradsApplicationCreator.AwardInput();
        invalidCourseAward.courseCode = 'INVALID_COURSE_CODE'; // Invalid course code
        invalidCourseAward.isAttending = true;

        invalidCourseApp.awards = new GradsApplicationCreator.AwardInput[]{invalidCourseAward};
        appInputs.add(invalidCourseApp);

        // 5. Application with multiple awards where one contains an error (1x callout)
        GradsApplicationCreator.ApplicationInput partialFailApp = new GradsApplicationCreator.ApplicationInput();
        partialFailApp.studentPersonId = students[1].Person_ID_unique__c;
        partialFailApp.personalEmail = 'partialfail@example.com';
        partialFailApp.testamurName = 'Partial Fail Student';
        partialFailApp.calendarSequenceNumber = cals[1].Calendar_Code__c;
        partialFailApp.studentContactId = students[1].Id;
        partialFailApp.gradCalendarId = cals[1].Id;
        partialFailApp.paidAmount = 200;
        partialFailApp.status = 'Draft';

        GradsApplicationCreator.AwardInput validAward = new GradsApplicationCreator.AwardInput();
        validAward.courseCode = '0020';
        validAward.awardCode1 = '6007';
        validAward.isAttending = true;

        GradsApplicationCreator.AwardInput invalidAward = new GradsApplicationCreator.AwardInput();
        invalidAward.courseCode = '0020';
        invalidAward.awardCode1 = 'NONEXISTENT'; // Invalid award code
        invalidAward.isAttending = false;

        partialFailApp.awards = new GradsApplicationCreator.AwardInput[]{validAward, invalidAward};
        appInputs.add(partialFailApp);

        // 6. Application with invalid field - Will cause Application DML error (1x callout)
        GradsApplicationCreator.ApplicationInput invalidFieldApp = new GradsApplicationCreator.ApplicationInput();
        invalidFieldApp.studentPersonId = students[2].Person_ID_unique__c;
        invalidFieldApp.personalEmail = 'invalidfield@example.com';
        invalidFieldApp.testamurName = 'Invalid Field Student';
        invalidFieldApp.calendarSequenceNumber = cals[2].Calendar_Code__c;
        invalidFieldApp.studentContactId = students[2].Id;
        invalidFieldApp.gradCalendarId = cals[2].Id;
        invalidFieldApp.paidAmount = 150;
        invalidFieldApp.status = 'INVALID_STATUS'; // Invalid status value

        GradsApplicationCreator.AwardInput simpleAward = new GradsApplicationCreator.AwardInput();
        simpleAward.courseCode = '0020';
        simpleAward.awardCode1 = '6007';
        simpleAward.isAttending = true;

        invalidFieldApp.awards = new GradsApplicationCreator.AwardInput[]{simpleAward};
        appInputs.add(invalidFieldApp);

        // 7. Application with skipEligibility=true and an award DML error (no callout)
        GradsApplicationCreator.ApplicationInput awardErrorApp = new GradsApplicationCreator.ApplicationInput();
        awardErrorApp.studentPersonId = students[3].Person_ID_unique__c;
        awardErrorApp.personalEmail = 'awarderror@example.com';
        awardErrorApp.testamurName = 'Award Error Student';
        awardErrorApp.calendarSequenceNumber = cals[0].Calendar_Code__c;
        awardErrorApp.studentContactId = students[3].Id;
        awardErrorApp.gradCalendarId = cals[0].Id;
        awardErrorApp.status = 'Draft';
        awardErrorApp.skipEligibility = true;

        GradsApplicationCreator.AwardInput awardError = new GradsApplicationCreator.AwardInput();
        awardError.courseCode = '0020';
        awardError.awardTypeIndicator = 'INVALID_TYPE'; // Cause DML Error
        awardError.awardCode1 = '6007';
        awardError.awardCode1Title = 'Award Error';
        awardError.awardCourseCode = '0020';

        awardErrorApp.awards = new GradsApplicationCreator.AwardInput[]{awardError};
        appInputs.add(awardErrorApp);

        // Store unique keys for expected successful applications
        Set<String> expectedUniqueKeys = new Set<String>();
        for(GradsApplicationCreator.ApplicationInput successApps : new GradsApplicationCreator.ApplicationInput[]{
            skipEligibilityApp,
            multiAwardApp,
            skipMultiApp
        }) {
            expectedUniqueKeys.add(GradsUtils.createApplicationUniqueKey(
                successApps.calendarSequenceNumber,
                successApps.studentPersonId
            ));
        }

        // Mock the eligibility callout
        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, createEligibilityRespJson()
        );
        Test.setMock(HttpCalloutMock.class, mcr);

        // WHEN - Create the applications
        Test.startTest();
        GradsApplicationCreator.ApplicationOutput[] results = GradsApplicationCreator.createApplications(appInputs);
        Test.stopTest();

        // THEN - Verify results
        Assert.areEqual(appInputs.size(), results.size(), 'Expected one result per input');

        Assert.areEqual(4, mcr.callCount, 'Unexpected number of callouts made');

        // Check successful applications
        Assert.isTrue(results[0].success, 'Expected skipEligibility application to succeed: ' + results[0].errorMessage);
        Assert.isNotNull(results[0].application?.Id, 'Expected skipEligibility application to be created');
        Assert.areEqual(1, results[0].awards.size(), 'Expected one award for skipEligibility application');
        Assert.areEqual('Single', results[0].awards[0].Award_Type__c, 'Expected Single award type');
        Assert.areEqual('Skip Eligibility Award', results[0].awards[0].Award_Title_1__c, 'Expected correct award title');

        Assert.isTrue(results[1].success, 'Expected multi-award application to succeed: ' + results[1].errorMessage);
        Assert.isNotNull(results[1].application?.Id, 'Expected multi-award application to be created');
        Assert.areEqual(2, results[1].awards.size(), 'Expected two awards for multi-award application');

        Assert.isTrue(results[2].success, 'Expected skipEligibility multi-award application to succeed: ' + results[2].errorMessage);
        Assert.isNotNull(results[2].application?.Id, 'Expected skipEligibility multi-award application to be created');
        Assert.areEqual(2, results[2].awards.size(), 'Expected two awards for skipEligibility multi-award application');

        // Check failed applications
        Assert.isFalse(results[3].success, 'Expected invalid course application to fail');
        Assert.isTrue(results[3].errorMessage.contains('Course Code not found'),
            'Incorrect error message for course not found: ' + results[3].errorMessage);

        Assert.isFalse(results[4].success, 'Expected partial fail application to fail');
        Assert.isTrue(results[4].errorMessage.contains('Award not found'),
            'Incorrect error message for award not found: ' + results[4].errorMessage);

        Assert.isFalse(results[5].success, 'Expected invalid field application to fail');
        Assert.isTrue(results[5].errorMessage.contains('Error'),
            'Incorrect error message for invalid field: ' + results[5].errorMessage);

        Assert.isFalse(results[6].success, 'Expected award error application to fail');
        Assert.isTrue(results[6].errorMessage.startsWith('Award Insert Error'),
            'Incorrect error message for award error: ' + results[6].errorMessage);

        // Check that successful applications were actually inserted
        List<Graduation_Application__c> insertedApps = [
            SELECT Student_Testamur_Name__c, Unique_Key__c,
            (SELECT Award_Type__c FROM Graduation_Awards__r)
            FROM Graduation_Application__c
        ];

        // Verify we have 3 successfully inserted applications with their awards
        Assert.areEqual(3, insertedApps.size(), 'Expected 3 applications to be inserted');

        // Count total awards across all inserted applications
        Integer totalAwards = 0;
        for (Graduation_Application__c app : insertedApps) {
            totalAwards += app.Graduation_Awards__r.size();
            expectedUniqueKeys.remove(app.Unique_Key__c);
        }

        Assert.isTrue(expectedUniqueKeys.isEmpty(), 'Expected apps not inserted: ' + expectedUniqueKeys);

        Assert.areEqual(5, totalAwards, 'Expected 5 awards to be inserted (1 + 2 + 2)');
    }

    /**
     * @description Test updating applications with a mix of successful and failing inputs
     */
    @IsTest
    static void testUpdateApplications_Mixed() {
        /**
         * 6x Application inputs
         *  3x expected successful application inputs
         *    1x with skipEligibility=true & existing Callista transaction number
         *    1x with skipEligibility=false & existing Callista transaction number
         *    1x with skipEligibility=false & no existing Callista transaction number
         *  3x expected failed application inputs
         *    1x course code not in eligibility response
         *    1x cancel API call failure
         *    1x update results in no changes
         */

        // GIVEN - Create applications to update
        Contact[] students = [SELECT Id, Person_ID_unique__c FROM Contact ORDER BY Person_ID_unique__c ASC];
        Calendar__c[] cals = [SELECT Id, Calendar_Code__c FROM Calendar__c ORDER BY Calendar_Code__c ASC];

        // Create applications with awards for testing
        List<Graduation_Application__c> applications = new List<Graduation_Application__c>();
        List<Graduation_Award__c[]> appAwards = new List<Graduation_Award__c[]>();

        // 1. skipEligibility=true & existing Callista transaction number
        Graduation_Application__c skipWithTransApp = new Graduation_Application__c(
            Student_Testamur_Name__c = 'Skip With Transaction',
            Student_Personal_Email__c = 'skipwith@example.com',
            Graduation_Calendar__c = cals[0].Id,
            Student__c = students[0].Id,
            Status__c = 'Applied',
            Attendance_Mode__c = 'In Absentia'
        );
        applications.add(skipWithTransApp);

        Graduation_Award__c skipWithTransAward = createAward();
        skipWithTransAward.Course_Code__c = 'SKIP001';
        skipWithTransAward.Award_Code_1__c = 'SKIP1';
        skipWithTransAward.Callista_Transaction_Number__c = 'G001';
        skipWithTransAward.Is_Attending_Ceremony__c = false;
        appAwards.add(new Graduation_Award__c[]{skipWithTransAward});

        // 2. skipEligibility=false & existing Callista transaction number
        Graduation_Application__c apiWithTransApp = new Graduation_Application__c(
            Student_Testamur_Name__c = 'API With Transaction',
            Student_Personal_Email__c = 'apiwith@example.com',
            Graduation_Calendar__c = cals[1].Id,
            Student__c = students[1].Id,
            Status__c = 'Applied',
            Attendance_Mode__c = 'In Absentia'
        );
        applications.add(apiWithTransApp);

        Graduation_Award__c apiWithTransAward = createAward();
        apiWithTransAward.Course_Code__c = 'ICHANGE';
        apiWithTransAward.Award_Code_1__c = '6007';
        apiWithTransAward.Callista_Transaction_Number__c = 'G002';
        apiWithTransAward.Is_Attending_Ceremony__c = false;
        appAwards.add(new Graduation_Award__c[]{apiWithTransAward});

        // 3. skipEligibility=false & no existing Callista transaction number
        Graduation_Application__c apiNoTransApp = new Graduation_Application__c(
            Student_Testamur_Name__c = 'API No Transaction',
            Student_Personal_Email__c = 'apino@example.com',
            Graduation_Calendar__c = cals[0].Id,
            Student__c = students[2].Id,
            Status__c = 'Applied',
            Attendance_Mode__c = 'In Absentia'
        );
        applications.add(apiNoTransApp);

        Graduation_Award__c apiNoTransAward = createAward();
        apiNoTransAward.Course_Code__c = 'ICHANGE';
        apiNoTransAward.Award_Code_1__c = '6007';
        apiNoTransAward.Callista_Transaction_Number__c = null;
        apiNoTransAward.Is_Attending_Ceremony__c = false;
        appAwards.add(new Graduation_Award__c[]{apiNoTransAward});

        // 4. Invalid course
        Graduation_Application__c badCourseApp = new Graduation_Application__c(
            Student_Testamur_Name__c = 'Bad Course',
            Student_Personal_Email__c = 'badcourse@example.com',
            Graduation_Calendar__c = cals[2].Id,
            Student__c = students[3].Id,
            Status__c = 'Applied',
            Attendance_Mode__c = 'In Absentia'
        );
        applications.add(badCourseApp);

        Graduation_Award__c badCourseAward = createAward();
        badCourseAward.Course_Code__c = '0020';
        badCourseAward.Award_Code_1__c = '6007';
        badCourseAward.Callista_Transaction_Number__c = 'G003';
        badCourseAward.Is_Attending_Ceremony__c = false;
        appAwards.add(new Graduation_Award__c[]{badCourseAward});

        // 5. Failing API cancellation
        Graduation_Application__c failCancelApp = new Graduation_Application__c(
            Student_Testamur_Name__c = 'Fail Cancel',
            Student_Personal_Email__c = 'failcancel@example.com',
            Graduation_Calendar__c = cals[2].Id,
            Student__c = students[3].Id,
            Status__c = 'Applied',
            Attendance_Mode__c = 'In Absentia'
        );
        applications.add(failCancelApp);

        Graduation_Award__c failCancelAward = createAward();
        failCancelAward.Course_Code__c = '0020';
        failCancelAward.Award_Code_1__c = '6007';
        failCancelAward.Callista_Transaction_Number__c = 'G003';
        failCancelAward.Is_Attending_Ceremony__c = false;
        appAwards.add(new Graduation_Award__c[]{failCancelAward});

        // 6. Award DML error
        Graduation_Application__c noChangeErrorApp = new Graduation_Application__c(
            Student_Testamur_Name__c = 'No Change',
            Student_Personal_Email__c = 'nochange@example.com',
            Graduation_Calendar__c = cals[3].Id,
            Student__c = students[3].Id,
            Status__c = 'Applied',
            Attendance_Mode__c = 'In Absentia'
        );
        applications.add(noChangeErrorApp);

        Graduation_Award__c noChangeErrorAward = createAward();
        noChangeErrorAward.Course_Code__c = '0020';
        noChangeErrorAward.Award_Code_1__c = '6007';
        noChangeErrorAward.Is_Attending_Ceremony__c = false;
        appAwards.add(new Graduation_Award__c[]{noChangeErrorAward});

        // Create the applications and awards
        insert applications;
        Graduation_Award__c[] awards = new Graduation_Award__c[0];
        for (Integer i = 0; i < applications.size(); i++) {
            for(Graduation_Award__c a : appAwards[i]) {
                a.Graduation_Application__c = applications[i].Id;
                awards.add(a);
            }
        }
        insert awards;

        // Create the update requests
        GradsApplicationCreator.ApplicationUpdateInput[] updateInputs = new GradsApplicationCreator.ApplicationUpdateInput[0];
        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp();

        // 1. Success - Skip eligibility API on Award with Transaction Number - 1x callout (POST)
        mcr.addResponse(200, createPatchRespJson('GNEW1'));
        GradsApplicationCreator.ApplicationUpdateInput skipWithTransUpdate = new GradsApplicationCreator.ApplicationUpdateInput();
        skipWithTransUpdate.existingApplicationId = skipWithTransApp.Id;
        skipWithTransUpdate.existingAwardId = skipWithTransAward.Id;

        GradsApplicationCreator.ApplicationInput skipWithTransInput = new GradsApplicationCreator.ApplicationInput();
        skipWithTransInput.skipEligibility = true;
        skipWithTransInput.testamurName = 'Updated Skip With Trans';
        skipWithTransInput.comments = 'Updated comments for skip with trans';

        GradsApplicationCreator.AwardInput skipWithTransAwardInput = new GradsApplicationCreator.AwardInput();
        skipWithTransAwardInput.courseCode = 'NEWCC01';
        skipWithTransAwardInput.awardCode1 = 'NEWAC01';
        skipWithTransAwardInput.awardCode1Title = 'New Award Title';
        skipWithTransAwardInput.awardCode2 = '';
        skipWithTransAwardInput.awardCourseCode = 'NEWACC01';
        skipWithTransAwardInput.awardCourseTitle = 'New Award Course Title';
        skipWithTransAwardInput.awardTypeIndicator = 'Single';
        skipWithTransAwardInput.courseTitle = 'New Course Title';
        skipWithTransAwardInput.awardCourseVersionNumber = 2;
        skipWithTransAwardInput.courseVersionNumber = 2;
        skipWithTransAwardInput.isAttending = true;

        skipWithTransInput.awardA = skipWithTransAwardInput;

        skipWithTransUpdate.applicationInput = skipWithTransInput;
        updateInputs.add(skipWithTransUpdate);

        // 2. Success - Use eligibility API on Award with Transaction Number - 2x callout (GET + POST)
        mcr.addResponse(200, createEligibilityRespJson());
        mcr.addResponse(200, createPatchRespJson(apiWithTransAward.Callista_Transaction_Number__c));
        GradsApplicationCreator.ApplicationUpdateInput apiWithTransUpdate = new GradsApplicationCreator.ApplicationUpdateInput();
        apiWithTransUpdate.existingApplicationId = apiWithTransApp.Id;
        apiWithTransUpdate.existingAwardId = apiWithTransAward.Id;

        GradsApplicationCreator.ApplicationInput apiWithTransInput = new GradsApplicationCreator.ApplicationInput();
        apiWithTransInput.skipEligibility = false;
        apiWithTransInput.comments = 'Updated comments for API with trans';

        GradsApplicationCreator.AwardInput apiWithTransAwardInput = new GradsApplicationCreator.AwardInput();
        apiWithTransAwardInput.isAttending = true;
        apiWithTransAwardInput.courseCode = '0020';
        apiWithTransInput.awardA = apiWithTransAwardInput;

        apiWithTransUpdate.applicationInput = apiWithTransInput;
        updateInputs.add(apiWithTransUpdate);

        // 3. Success - Use eligibility API on Award with no Transaction Number - 1x callout (GET)
        mcr.addResponse(200, createEligibilityRespJson());
        GradsApplicationCreator.ApplicationUpdateInput apiNoTransUpdate = new GradsApplicationCreator.ApplicationUpdateInput();
        apiNoTransUpdate.existingApplicationId = apiNoTransApp.Id;
        apiNoTransUpdate.existingAwardId = apiNoTransAward.Id;

        GradsApplicationCreator.ApplicationInput apiNoTransInput = new GradsApplicationCreator.ApplicationInput();
        apiNoTransInput.skipEligibility = false;
        apiNoTransInput.calendarSequenceNumber = cals[2].Calendar_Code__c; // update calendar
        apiNoTransInput.gradCalendarId = cals[2].Id;
        apiNoTransInput.comments = 'New comments for API no trans';

        GradsApplicationCreator.AwardInput apiNoTransAwardInput = new GradsApplicationCreator.AwardInput();
        apiNoTransAwardInput.courseCode = '0020';
        apiNoTransInput.awardA = apiNoTransAwardInput;

        apiNoTransUpdate.applicationInput = apiNoTransInput;
        updateInputs.add(apiNoTransUpdate);

        // 4. Failure - Course code not in eligibility response - 1x callout (GET)
        mcr.addResponse(200, createEligibilityRespJson());
        GradsApplicationCreator.ApplicationUpdateInput badCourseUpdate = new GradsApplicationCreator.ApplicationUpdateInput();
        badCourseUpdate.existingApplicationId = badCourseApp.Id;
        badCourseUpdate.existingAwardId = badCourseAward.Id;

        GradsApplicationCreator.ApplicationInput badCourseInput = new GradsApplicationCreator.ApplicationInput();
        badCourseInput.skipEligibility = false;
        badCourseInput.calendarSequenceNumber = cals[3].Calendar_Code__c; // calendar update shouldn't be applied

        GradsApplicationCreator.AwardInput badCourseAwardInput = new GradsApplicationCreator.AwardInput();
        badCourseAwardInput.courseCode = 'NOT_A_COURSE_CODE'; // Invalid course code
        badCourseInput.awardA = badCourseAwardInput;

        badCourseUpdate.applicationInput = badCourseInput;
        updateInputs.add(badCourseUpdate);

        // 5. Failure - Award cancel failure (failure set via mock responses) - 1x callout (POST)
        mcr.addResponse(400, createPatchRespJson(failCancelAward.Callista_Transaction_Number__c));
        GradsApplicationCreator.ApplicationUpdateInput failCancelUpdate = new GradsApplicationCreator.ApplicationUpdateInput();
        failCancelUpdate.existingApplicationId = failCancelApp.Id;
        failCancelUpdate.existingAwardId = failCancelAward.Id;

        GradsApplicationCreator.ApplicationInput failCancelInput = new GradsApplicationCreator.ApplicationInput();
        failCancelInput.skipEligibility = true;

        GradsApplicationCreator.AwardInput failCancelAwardInput = new GradsApplicationCreator.AwardInput();
        failCancelAwardInput.courseCode = 'CHANGED';
        failCancelAwardInput.awardCode1 = '6007';
        failCancelInput.awardA = failCancelAwardInput;

        failCancelUpdate.applicationInput = failCancelInput;
        updateInputs.add(failCancelUpdate);

        // 6. Failure - No change error - no callout
        GradsApplicationCreator.ApplicationUpdateInput noChangeErrorUpdate = new GradsApplicationCreator.ApplicationUpdateInput();
        noChangeErrorUpdate.existingApplicationId = noChangeErrorApp.Id;
        noChangeErrorUpdate.existingAwardId = noChangeErrorAward.Id;

        GradsApplicationCreator.ApplicationInput noChangeErrorInput = new GradsApplicationCreator.ApplicationInput();
        noChangeErrorInput.testamurName = noChangeErrorApp.Student_Testamur_Name__c;
        noChangeErrorInput.calendarSequenceNumber = cals[3].Calendar_Code__c;
        noChangeErrorInput.gradCalendarId = cals[3].Id;

        noChangeErrorUpdate.applicationInput = noChangeErrorInput;
        updateInputs.add(noChangeErrorUpdate);

        Test.setMock(HttpCalloutMock.class, mcr);

        // WHEN - Updating the applications
        Test.startTest();
        GradsApplicationCreator.ApplicationOutput[] results = GradsApplicationCreator.updateApplications(updateInputs);
        Test.stopTest();

        // THEN - A mixture of results are expected
        Assert.areEqual(updateInputs.size(), results.size(), 'Expected one result per input');

        // Verify successful updates
        Assert.isTrue(results[0].success,
            'Expected skipWithTrans update to succeed: ' + results[0].errorMessage + ': ' + results[0].errorDetail);
        Assert.isTrue(results[1].success,
            'Expected apiWithTrans update to succeed: ' + results[1].errorMessage + ': ' + results[1].errorDetail);
        Assert.isTrue(results[2].success,
            'Expected apiNoTrans update to succeed: ' + results[2].errorMessage + ': ' + results[2].errorDetail);

        // Verify failed updates
        Assert.isFalse(results[3].success, 'Expected bad course update to fail');
        Assert.isTrue(results[3].errorMessage.startsWith('Course Code not found'),
            'Expected course not found error: ' + results[3].errorMessage);

        Assert.isFalse(results[4].success, 'Expected cancel API failure');
        Assert.isTrue(results[4].errorMessage.startsWith('Failed to cancel'),
            'Expected API cancellation error: ' + results[4].errorMessage);

        Assert.isFalse(results[5].success, 'Expected Update error');
        Assert.areEqual('Update Error: No changes detected', results[5].errorMessage,
            'Expected error message for no change error: ' + results[5].errorMessage);

        // Verify callouts
        Assert.areEqual(6, mcr.callCount, 'Unexpected number of callouts made');

        // Verify actual database updates for successful cases

        // 1. Verify skipWithTrans update
        Graduation_Application__c skipWithTransResult = [
            SELECT Student_Testamur_Name__c, Attendance_Mode__c,
            (SELECT Staff_Comments__c, Is_Attending_Ceremony__c FROM Graduation_Awards__r)
            FROM Graduation_Application__c
            WHERE Id = :skipWithTransApp.Id
        ];
        Assert.areEqual('Updated Skip With Trans', skipWithTransResult.Student_Testamur_Name__c, 'Expected updated testamur name');
        Assert.areEqual('Attending', skipWithTransResult.Attendance_Mode__c, 'Expected attendance mode to be updated');
        Assert.areEqual('Updated comments for skip with trans', skipWithTransResult.Graduation_Awards__r[0].Staff_Comments__c,
            'Expected updated comments');
        Assert.isTrue(skipWithTransResult.Graduation_Awards__r[0].Is_Attending_Ceremony__c, 'Expected award to be marked as attending');

        // 2. Verify apiWithTrans update
        Graduation_Application__c apiWithTransResult = [
            SELECT Attendance_Mode__c,
            (SELECT Staff_Comments__c, Is_Attending_Ceremony__c FROM Graduation_Awards__r)
            FROM Graduation_Application__c
            WHERE Id = :apiWithTransApp.Id
        ];
        Assert.areEqual('Attending', apiWithTransResult.Attendance_Mode__c, 'Expected attendance mode to be updated');
        Assert.areEqual('Updated comments for API with trans', apiWithTransResult.Graduation_Awards__r[0].Staff_Comments__c,
            'Expected updated comments');

        // 3. Verify apiNoTrans update
        Graduation_Application__c apiNoTransResult = [
            SELECT Graduation_Calendar__c, Unique_Key__c, Student_Person_Id__c,
            (SELECT Staff_Comments__c FROM Graduation_Awards__r)
            FROM Graduation_Application__c
            WHERE Id = :applications[2].Id
        ];
        Assert.areEqual(cals[2].Id, apiNoTransResult.Graduation_Calendar__c, 'Expected calendar to be updated');
        Assert.areEqual('New comments for API no trans', apiNoTransResult.Graduation_Awards__r[0].Staff_Comments__c,
            'Expected updated comments');
        Assert.areEqual(
            GradsUtils.createApplicationUniqueKey(cals[2].Calendar_Code__c, apiNoTransResult.Student_Person_Id__c),
            apiNoTransResult.Unique_Key__c, 'Expected unique key to be updated'
        );

        // 4. 5. 6. Verify no changes for failed updates
        Map<Id, Graduation_Application__c> unchangedApps = new Map<Id, Graduation_Application__c>{
            badCourseApp.Id => badCourseApp,
            failCancelApp.Id => failCancelApp,
            noChangeErrorApp.Id => noChangeErrorApp
        };
        Graduation_Application__c[] unchangedAppResults = [
            SELECT Graduation_Calendar__c, Status__c, Student_Testamur_Name__c,
            (SELECT Course_Code__c FROM Graduation_Awards__r)
            FROM Graduation_Application__c
            WHERE Id IN :unchangedApps.keySet()
        ];
        for(Graduation_Application__c appResult : unchangedAppResults) {
            Graduation_Application__c appOrig = unchangedApps.get(appResult.Id);
            Assert.areEqual(appOrig.Graduation_Calendar__c, appResult.Graduation_Calendar__c,
                'Expected calendar to remain unchanged');
            Assert.areEqual(appOrig.Student_Testamur_Name__c, appResult.Student_Testamur_Name__c,
                'Expected testamur name to remain unchanged');
            Assert.areEqual(appOrig.Status__c, appResult.Status__c,
                'Expected status to remain unchanged');

            for(Graduation_Award__c awardOrig :awards) {
                if(awardOrig.Graduation_Application__c == appOrig.Id) {
                    Assert.areEqual(awardOrig.Course_Code__c, appResult.Graduation_Awards__r[0].Course_Code__c,
                        'Expected course code to remain unchanged');
                    break;
                }
            }
        }
    }

    /**
     * @description Test the findBestMatchingAward method
     */
    @IsTest
    static void testFindBestMatchingAward() {
        // GIVEN - Mocked eligibility available awards
        GradsCallistaCalloutService.EligibilityCourseAttempt courseAttempt = new GradsCallistaCalloutService.EligibilityCourseAttempt();
        courseAttempt.graduationAvailableSelections = new List<GradsCallistaCalloutService.EligibilityGraduationAvailableSelection>();

        // Award 1 - COMBINED
        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection combinedAward1 = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        combinedAward1.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        combinedAward1.awardDetails.awardCode1 = '1001';
        combinedAward1.awardDetails.awardCode2 = '1002';
        combinedAward1.awardDetails.awardTitle1 = 'Award 1';
        combinedAward1.awardDetails.awardTitle2 = 'Award 2';
        combinedAward1.awardDetails.awardTypeIndicator = 'COMBINED';
        courseAttempt.graduationAvailableSelections.add(combinedAward1);

        // Award 2 - COMBINED
        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection combinedAward2 = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        combinedAward2.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        combinedAward2.awardDetails.awardCode1 = '1003';
        combinedAward2.awardDetails.awardCode2 = '1004';
        combinedAward2.awardDetails.awardTypeIndicator = 'COMBINED';
        courseAttempt.graduationAvailableSelections.add(combinedAward2);

        // Award 3 - SINGLE
        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection singleAward = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        singleAward.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        singleAward.awardDetails.awardCode1 = '2001';
        singleAward.awardDetails.awardTypeIndicator = 'SINGLE';
        courseAttempt.graduationAvailableSelections.add(singleAward);

        // Award 4 - ALTERNATIVE EXITS
        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection altExitAward = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        altExitAward.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        altExitAward.awardDetails.awardCode1 = '6007';
        altExitAward.awardDetails.awardTitle1 = 'Award 3';
        altExitAward.awardDetails.awardTypeIndicator = 'ALTERNATIVE EXITS';
        courseAttempt.graduationAvailableSelections.add(altExitAward);

        // WHEN - Call the method with different inputs

        // Test case 1: Automatically select first combined award
        GradsApplicationCreator.AwardInput fullAutoInput = new GradsApplicationCreator.AwardInput();
        GradsCallistaCalloutService.EligibilityAward result1 = GradsApplicationCreator.findBestMatchingAward(
            courseAttempt, fullAutoInput
        );

        // Test case 2: Award Type
        GradsApplicationCreator.AwardInput awardTypeInput = new GradsApplicationCreator.AwardInput();
        awardTypeInput.awardTypeIndicator = 'SINGLE';
        GradsCallistaCalloutService.EligibilityAward result2 = GradsApplicationCreator.findBestMatchingAward(
            courseAttempt, awardTypeInput
        );

        // Test case 3: Award Code1
        GradsApplicationCreator.AwardInput awardCodeInput = new GradsApplicationCreator.AwardInput();
        awardCodeInput.awardCode1 = '2001';
        GradsCallistaCalloutService.EligibilityAward result3 = GradsApplicationCreator.findBestMatchingAward(
            courseAttempt, awardCodeInput
        );

        // Test case 4: No match
        GradsApplicationCreator.AwardInput noMatchInput = new GradsApplicationCreator.AwardInput();
        noMatchInput.awardCode1 = '9999';
        GradsCallistaCalloutService.EligibilityAward result4 = GradsApplicationCreator.findBestMatchingAward(
            courseAttempt, noMatchInput
        );

        // Test case 5: Match on multiple criteria
        GradsApplicationCreator.AwardInput multiMatchInput = new GradsApplicationCreator.AwardInput();
        multiMatchInput.awardCode1 = '1003';
        multiMatchInput.awardCode2 = '1004';
        multiMatchInput.awardTypeIndicator = 'COMBINED';
        GradsCallistaCalloutService.EligibilityAward result5 = GradsApplicationCreator.findBestMatchingAward(
            courseAttempt, multiMatchInput
        );

        // THEN - Verify the results
        Assert.isNotNull(result1, 'Expected to find award with highest preference');
        Assert.areEqual('COMBINED', result1.awardTypeIndicator, 'Expected awardType to match');
        Assert.areEqual('1001', result1.awardCode1, 'Expected correct award to be selected');
        Assert.areEqual('1002', result1.awardCode2, 'Expected correct award to be selected');

        Assert.isNotNull(result2, 'Expected to find award with matching type');
        Assert.areEqual('SINGLE', result2.awardTypeIndicator, 'Expected SINGLE awardType');
        Assert.areEqual('2001', result2.awardCode1, 'Expected correct awardCode1 to be selected');
        Assert.isNull(result2.awardCode2, 'Expected no second award for SINGLE type');

        Assert.isNotNull(result3, 'Expected to find award with matching award code');
        Assert.areEqual('SINGLE', result3.awardTypeIndicator, 'Expected SINGLE award type');
        Assert.areEqual('2001', result3.awardCode1, 'Expected correct awardCode1 to be selected');
        Assert.isNull(result3.awardCode2, 'Expected no awardCode2 for SINGLE type');

        Assert.isNull(result4, 'Expected no award to be found for non-existent awardCode1');

        Assert.isNotNull(result5, 'Expected to find award with matching award codes');
        Assert.areEqual('COMBINED', result5.awardTypeIndicator, 'Expected COMBINED awardType');
        Assert.areEqual('1003', result5.awardCode1, 'Expected correct awardCode1 to be selected');
        Assert.areEqual('1004', result5.awardCode2, 'Expected correct awardCode2 to be selected');
    }

    private static String createPatchRespJson(String transactionNo) {
        return '{"transactionNo": "'+transactionNo+'"}';
    }

    private static String createEligibilityRespJson() {
        GradsCallistaCalloutService.EligibilityDetails eligibilityDetails = new GradsCallistaCalloutService.EligibilityDetails();
        eligibilityDetails.courseAttempts = new List<GradsCallistaCalloutService.EligibilityCourseAttempt>();

        GradsCallistaCalloutService.EligibilityCourseAttempt courseAttempt = new GradsCallistaCalloutService.EligibilityCourseAttempt();
        courseAttempt.courseCode = '0020';
        courseAttempt.courseTitle = 'Doctor of Philosophy';
        courseAttempt.courseVersionNumber = 6;
        courseAttempt.graduationAvailableSelections = new List<GradsCallistaCalloutService.EligibilityGraduationAvailableSelection>();

        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gs1 = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        gs1.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        gs1.awardDetails.awardCode1 = '6007';
        gs1.awardDetails.awardTitle1 = 'Master of Arts';
        gs1.awardDetails.awardTypeIndicator = 'ALTERNATIVE EXITS';
        gs1.awardDetails.awardCourseCode = '0017';
        gs1.awardDetails.awardCourseTitle = 'Doctor of Philosophy';
        gs1.awardDetails.awardCourseVersionNumber = 1;
        courseAttempt.graduationAvailableSelections.add(gs1);

        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gs2 = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        gs2.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        gs2.awardDetails.awardCode1 = '3007';
        gs2.awardDetails.awardTitle1 = 'Doctor of Philosophy';
        gs2.awardDetails.awardTypeIndicator = 'SINGLE';
        gs2.awardDetails.awardCourseCode = '0020';
        gs2.awardDetails.awardCourseTitle = 'Doctor of Philosophy';
        gs2.awardDetails.awardCourseVersionNumber = 6;
        courseAttempt.graduationAvailableSelections.add(gs2);

        // Add a COMBINED type for testing preference order
        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gs3 = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        gs3.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        gs3.awardDetails.awardCode1 = '5007';
        gs3.awardDetails.awardTitle1 = 'Combined Degree';
        gs3.awardDetails.awardTypeIndicator = 'COMBINED';
        gs3.awardDetails.awardCourseCode = '0020';
        gs3.awardDetails.awardCourseTitle = 'Doctor of Philosophy';
        gs3.awardDetails.awardCourseVersionNumber = 6;
        courseAttempt.graduationAvailableSelections.add(gs3);

        eligibilityDetails.courseAttempts.add(courseAttempt);

        // Create mock callout response
        GradsCallistaCalloutService.EligibilityResponse mockResponse = new GradsCallistaCalloutService.EligibilityResponse();
        mockResponse.graduationEligibilityDetails = eligibilityDetails;

        return JSON.serialize(mockResponse);
    }

    private static Graduation_Award__c createAward() {
        return new Graduation_Award__c(
            Award_Type__c = 'Single',
            Course_Code__c = '0020',
            Course_Title__c = 'Doctor of Philosophy',
            Award_Code_1__c = '6007',
            Award_Title_1__c = 'Master of Arts',
            Award_Course_Code__c = '0020',
            Award_Course_Title__c = 'Doctor of Philosophy',
            Award_Course_Version__c = 6,
            Course_Version_Number__c = 6,
            Integration_Id__c = '12345',
            Is_Attending_Ceremony__c = false
        );
    }
}