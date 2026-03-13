/**
 * @description Test class for GradsApplicationUploaderBatch
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 * @revision    2025-04-02 - Updated to match revised GradsApplicationUploaderBatch class
 */
@IsTest(IsParallel=true)
private class GradsApplicationUploaderBatch_Test {

    final static Integer CALENDAR_SEQ_NUM = 4567;
    final static String STUDENT_ID = 'TEST001';
    final static String TEST_TRANSACTION_NO = 'T12345';

    @TestSetup
    static void setupTestData() {
        Contact student = new Contact(
            LastName = 'TestStudent',
            Person_ID_unique__c = STUDENT_ID
        );
        insert student;

        Calendar__c cal = new Calendar__c(
            Calendar_Code__c = String.valueOf(CALENDAR_SEQ_NUM),
            Category__c = 'GRADUATION'
        );
        insert cal;
    }

    /**
     * @description Test successful insert of application using eligibility API
     */
    @IsTest
    static void testUploadApplications_InsertSuccess() {
        // GIVEN - A valid application CSV row
        List<Map<String, String>> data = new List<Map<String, String>>();
        Map<String, String> row = new Map<String, String>{
            GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID,
            GradsApplicationUploaderBatch.COL_EMAIL => 'test@example.com',
            GradsApplicationUploaderBatch.COL_TESTAMUR_NAME => 'Test Student',
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => String.valueOf(CALENDAR_SEQ_NUM),
            GradsApplicationUploaderBatch.COL_PAID_AMOUNT => '100',
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => 'COURSE001',
            'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'true',
            GradsApplicationUploaderBatch.COL_RECEIPT_NUMBER => 'REC001'
        };
        data.add(row);

        // Mock the eligibility callout
        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, createEligibilityRespJson('COURSE001')
        );
        Test.setMock(HttpCalloutMock.class, mcr);

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            new List<String>(row.keySet()), data, false);
        Test.stopTest();

        // THEN - Application should be created with eligibility API data
        Assert.areEqual(0, errors.size(), 'Expected no errors but got: ' + (errors.isEmpty() ? 'none' : errors[0].message));
        Assert.areEqual(1, mcr.callCount, 'Expected one callout to eligibility API');

        List<Graduation_Application__c> applications = [
            SELECT Id, Student_Personal_Email__c, Student_Testamur_Name__c, Attendance_Mode__c
            FROM Graduation_Application__c
        ];
        Assert.areEqual(1, applications.size(), 'Expected one Graduation Application');
        Assert.areEqual('test@example.com', applications[0].Student_Personal_Email__c, 'Wrong email');
        Assert.areEqual('Test Student', applications[0].Student_Testamur_Name__c, 'Wrong name');
        Assert.areEqual('Attending', applications[0].Attendance_Mode__c, 'Wrong attendance mode');

        List<Graduation_Award__c> awards = [
            SELECT Id, Course_Code__c, Is_Attending_Ceremony__c
            FROM Graduation_Award__c
        ];
        Assert.areEqual(1, awards.size(), 'Expected one Graduation Award');
        Assert.areEqual('COURSE001', awards[0].Course_Code__c, 'Wrong course code');
        Assert.isTrue(awards[0].Is_Attending_Ceremony__c, 'Expected is attending to be true');
    }

    /**
     * @description Test successful insert with SkipEligibility=true
     */
    @IsTest
    static void testUploadApplications_InsertWithSkipEligibility() {
        // GIVEN - A valid application CSV row with SkipEligibility=true
        List<Map<String, String>> data = new List<Map<String, String>>();
        Map<String, String> row = new Map<String, String>{
            GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID,
            GradsApplicationUploaderBatch.COL_EMAIL => 'test@example.com',
            GradsApplicationUploaderBatch.COL_TESTAMUR_NAME => 'Test Student',
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => String.valueOf(CALENDAR_SEQ_NUM),
            GradsApplicationUploaderBatch.COL_PAID_AMOUNT => '100',
            GradsApplicationUploaderBatch.COL_SKIP_ELIGIBILITY => 'true',
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => 'MANUAL001',
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_TITLE => 'Manual Course',
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_VERSION => '1',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_TYPE => 'Single',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_CODE1 => 'MANUAL-A1',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_CODE2 => '',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_CODE1_TITLE => 'Manual Award 1',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_CODE2_TITLE => '',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_COURSE_CODE => 'MANUAL001',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_COURSE_TITLE => 'Manual Course',
            'A.' + GradsApplicationUploaderBatch.COL_AWARD_COURSE_VERSION => '1',
            'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'true'
        };
        data.add(row);

        // No mock needed as we're skipping the eligibility API

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            new List<String>(row.keySet()), data, false);
        Test.stopTest();

        // THEN - Application should be created with manual data
        Assert.areEqual(0, errors.size(), 'Expected no errors but got: ' + (errors.isEmpty() ? 'none' : errors[0].message));

        List<Graduation_Application__c> applications = [
            SELECT Id, Student_Personal_Email__c, Student_Testamur_Name__c, Attendance_Mode__c
            FROM Graduation_Application__c
        ];
        Assert.areEqual(1, applications.size(), 'Expected one Graduation Application');
        Assert.areEqual('test@example.com', applications[0].Student_Personal_Email__c, 'Wrong email');
        Assert.areEqual('Test Student', applications[0].Student_Testamur_Name__c, 'Wrong name');
        Assert.areEqual('Attending', applications[0].Attendance_Mode__c, 'Wrong attendance mode');

        List<Graduation_Award__c> awards = [
            SELECT Id, Course_Code__c, Course_Title__c, Award_Code_1__c, Award_Title_1__c, Award_Type__c
            FROM Graduation_Award__c
        ];
        Assert.areEqual(1, awards.size(), 'Expected one Graduation Award');
        Assert.areEqual('MANUAL001', awards[0].Course_Code__c, 'Wrong course code');
        Assert.areEqual('Manual Course', awards[0].Course_Title__c, 'Wrong course title');
        Assert.areEqual('MANUAL-A1', awards[0].Award_Code_1__c, 'Wrong award code');
        Assert.areEqual('Manual Award 1', awards[0].Award_Title_1__c, 'Wrong award title');
        Assert.areEqual('Single', awards[0].Award_Type__c, 'Wrong award type');
    }

    /**
     * @description Test successful update using Transaction Number
     */
    @IsTest
    static void testUploadApplications_UpdateSuccess() {
        // GIVEN - An existing graduation application and award with transaction number
        Contact student = [SELECT Id, Person_ID_unique__c FROM Contact LIMIT 1];
        Calendar__c cal1 = [SELECT Id, Calendar_Code__c FROM Calendar__c LIMIT 1];

        // Create a second calendar for update testing
        Calendar__c cal2 = new Calendar__c(
            Calendar_Code__c = '5678',
            Category__c = 'GRADUATION'
        );
        insert cal2;

        Graduation_Application__c existingApp = new Graduation_Application__c(
            Student__c = student.Id,
            Graduation_Calendar__c = cal1.Id,
            Unique_Key__c = cal1.Calendar_Code__c + '|' + student.Person_ID_unique__c,
            Status__c = 'Applied',
            Student_Testamur_Name__c = 'Original Name',
            Attendance_Mode__c = 'In Absentia',
            Student_Personal_Email__c = 'old@example.com'
        );
        insert existingApp;

        Graduation_Award__c existingAward = new Graduation_Award__c(
            Graduation_Application__c = existingApp.Id,
            Course_Code__c = 'OLDCOURSE',
            Award_Code_1__c = 'OLDAWARD',
            Award_Type__c = 'Single',
            Callista_Transaction_Number__c = TEST_TRANSACTION_NO,
            Is_Attending_Ceremony__c = false,
            Staff_Comments__c = 'Old comment',
            Award_Course_Code__c = 'OLDCOURSE',
            Award_Course_Title__c = 'Old Course Title',
            Award_Course_Version__c = 1,
            Award_Title_1__c = 'Old Award Title',
            Course_Title__c = 'Old Course Title',
            Course_Version_Number__c = 1,
            Integration_Id__c = 'OLD_INTEGRATION_ID'
        );
        insert existingAward;

        // Create update data
        List<Map<String, String>> data = new List<Map<String, String>>();
        Map<String, String> row = new Map<String, String>{
            GradsApplicationUploaderBatch.COL_TRANSACTION_NO => TEST_TRANSACTION_NO,
            GradsApplicationUploaderBatch.COL_TESTAMUR_NAME => 'Updated Name',
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => cal2.Calendar_Code__c,
            GradsApplicationUploaderBatch.COL_EMAIL => 'new@example.com',
            GradsApplicationUploaderBatch.COL_COMMENTS => 'Updated comment',
            GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'true'
        };
        data.add(row);

        // Mock the callout for award update
        GradsCallistaCalloutService_Test.MockCallistaResp mcr = new GradsCallistaCalloutService_Test.MockCallistaResp(
            200, '{"transactionNo": "' + TEST_TRANSACTION_NO + '"}'
        );
        Test.setMock(HttpCalloutMock.class, mcr);

        // WHEN - CSV is processed for update
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            new List<String>(row.keySet()), data, true);
        Test.stopTest();

        // THEN - Application and award should be updated
        Assert.areEqual(0, errors.size(), 'Expected no errors but got: ' + (errors.isEmpty() ? 'none' : errors[0].message));

        Graduation_Application__c updatedApp = [
            SELECT Id, Student_Testamur_Name__c, Graduation_Calendar__c, Student_Personal_Email__c,
                Attendance_Mode__c
            FROM Graduation_Application__c WHERE Id = :existingApp.Id
        ];

        Assert.areEqual('Updated Name', updatedApp.Student_Testamur_Name__c, 'Name should be updated');
        Assert.areEqual(cal2.Id, updatedApp.Graduation_Calendar__c, 'Calendar should be updated');
        Assert.areEqual('new@example.com', updatedApp.Student_Personal_Email__c, 'Email should be updated');
        Assert.areEqual('Attending', updatedApp.Attendance_Mode__c, 'Attendance mode should be updated');

        Graduation_Award__c updatedAward = [
            SELECT Staff_Comments__c, Is_Attending_Ceremony__c
            FROM Graduation_Award__c WHERE Id = :existingAward.Id
        ];

        Assert.areEqual('Updated comment', updatedAward.Staff_Comments__c, 'Comments should be updated');
        Assert.isTrue(updatedAward.Is_Attending_Ceremony__c, 'Is_Attending should be updated to true');
    }

    /**
     * @description Test missing required columns for insert
     */
    @IsTest
    static void testUploadApplications_MissingRequiredColumns() {
        // GIVEN - Missing required column in header
        List<String> incompleteHeader = new List<String>{
            GradsApplicationUploaderBatch.COL_STUDENT_ID,
            // Missing COL_CAL_SEQ_NUM which is required
            GradsApplicationUploaderBatch.COL_EMAIL,
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE
        };

        List<Map<String, String>> data = new List<Map<String, String>>{
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID,
                GradsApplicationUploaderBatch.COL_EMAIL => 'test@example.com',
                'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => 'COURSE001'
            }
        };

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            incompleteHeader, data, false);
        Test.stopTest();

        // THEN - Should get an error about missing required column
        Assert.areEqual(1, errors.size(), 'Expected one error');
        Assert.isTrue(errors[0].message.contains('CSV column missing: ' +
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM),
            'Error should mention missing required column, got: ' + errors[0].message);
    }

    /**
     * @description Test missing required values
     */
    @IsTest
    static void testUploadApplications_MissingRequiredValues() {
        // GIVEN - Missing required value in row data
        List<String> header = new List<String>{
            GradsApplicationUploaderBatch.COL_STUDENT_ID,
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM,
            GradsApplicationUploaderBatch.COL_EMAIL,
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE,
            'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING
        };

        List<Map<String, String>> data = new List<Map<String, String>>{
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID,
                GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => String.valueOf(CALENDAR_SEQ_NUM),
                GradsApplicationUploaderBatch.COL_EMAIL => 'test@example.com',
                'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => '', // Empty required value
                'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'true'
            }
        };

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            header, data, false);
        Test.stopTest();

        // THEN - Should get an error about missing required value
        Assert.areEqual(1, errors.size(), 'Expected one error');
        Assert.isTrue(errors[0].message.contains('Missing required value A.' +
            GradsApplicationUploaderBatch.COL_COURSE_CODE),
            'Error should mention missing required value, got: ' + errors[0].message);
    }

    /**
     * @description Test invalid values
     */
    @IsTest
    static void testUploadApplications_InvalidValues() {
        // GIVEN - Invalid value types
        List<String> header = new List<String>{
            GradsApplicationUploaderBatch.COL_STUDENT_ID,
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM,
            GradsApplicationUploaderBatch.COL_PAID_AMOUNT,
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE,
            'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING,
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_VERSION
        };

        List<Map<String, String>> data = new List<Map<String, String>>{
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID,
                GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => String.valueOf(CALENDAR_SEQ_NUM),
                GradsApplicationUploaderBatch.COL_PAID_AMOUNT => 'not-a-number', // Invalid number
                'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => 'COURSE001',
                'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'true',
                'A.' + GradsApplicationUploaderBatch.COL_COURSE_VERSION => 'not-an-integer' // Invalid integer
            }
        };

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            header, data, false);
        Test.stopTest();

        // THEN - Should get errors about invalid values
        Assert.areEqual(2, errors.size(), 'Expected two errors');
        Boolean hasPaidAmountError = false;
        Boolean hasCourseVersionError = false;

        for (GradsApplicationUploaderBatch.Error error : errors) {
            if (error.message.contains(GradsApplicationUploaderBatch.COL_PAID_AMOUNT)) {
                hasPaidAmountError = true;
            }
            if (error.message.contains(GradsApplicationUploaderBatch.COL_COURSE_VERSION)) {
                hasCourseVersionError = true;
            }
        }

        Assert.isTrue(hasPaidAmountError, 'Expected error for invalid paid amount');
        Assert.isTrue(hasCourseVersionError, 'Expected error for invalid course version');
    }

    /**
     * @description Test duplicate entries in CSV for insert mode
     */
    @IsTest
    static void testUploadApplications_DuplicateInCsv_InsertMode() {
        // GIVEN - Two rows with the same StudentId and CalendarSequenceNumber
        List<String> header = new List<String>{
            GradsApplicationUploaderBatch.COL_STUDENT_ID,
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM,
            GradsApplicationUploaderBatch.COL_EMAIL,
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE,
            'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING
        };

        List<Map<String, String>> data = new List<Map<String, String>>{
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID,
                GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => String.valueOf(CALENDAR_SEQ_NUM),
                GradsApplicationUploaderBatch.COL_EMAIL => 'row1@example.com',
                'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => 'COURSE001',
                'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'true'
            },
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID, // Same student
                GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => String.valueOf(CALENDAR_SEQ_NUM), // Same calendar
                GradsApplicationUploaderBatch.COL_EMAIL => 'row2@example.com',
                'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => 'COURSE002',
                'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'false'
            }
        };

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            header, data, false);
        Test.stopTest();

        // THEN - Should get an error about duplicate rows
        Assert.areEqual(1, errors.size(), 'Expected one error');
        Assert.isTrue(errors[0].message.contains('Duplicate Calendar/Student combination'),
            'Error should mention duplicate combination, got: ' + errors[0].message);
    }

    /**
     * @description Test duplicate transaction numbers in CSV for update mode
     */
    @IsTest
    static void testUploadApplications_DuplicateTransactionNoInCsv_UpdateMode() {
        // GIVEN - Two rows with the same TransactionNo
        List<String> header = new List<String>{
            GradsApplicationUploaderBatch.COL_TRANSACTION_NO,
            GradsApplicationUploaderBatch.COL_COMMENTS
        };

        List<Map<String, String>> data = new List<Map<String, String>>{
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_TRANSACTION_NO => TEST_TRANSACTION_NO,
                GradsApplicationUploaderBatch.COL_COMMENTS => 'Comment 1'
            },
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_TRANSACTION_NO => TEST_TRANSACTION_NO, // Same transaction number
                GradsApplicationUploaderBatch.COL_COMMENTS => 'Comment 2'
            }
        };

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            header, data, true);
        Test.stopTest();

        // THEN - Should get an error about duplicate transaction numbers
        Assert.areEqual(1, errors.size(), 'Expected one error');
        Assert.isTrue(
            errors[0].message.contains('Duplicate TransactionNo'),
            'Error should mention duplicate transaction number, got: ' + errors[0].message
        );
    }

    /**
     * @description Test transaction number not found for update mode
     */
    @IsTest
    static void testUploadApplications_TransactionNotFound_UpdateMode() {
        // GIVEN - Row with non-existent TransactionNo
        List<String> header = new List<String>{
            GradsApplicationUploaderBatch.COL_TRANSACTION_NO,
            GradsApplicationUploaderBatch.COL_COMMENTS
        };

        List<Map<String, String>> data = new List<Map<String, String>>{
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_TRANSACTION_NO => 'NONEXISTENT',
                GradsApplicationUploaderBatch.COL_COMMENTS => 'Updated comment'
            }
        };

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            header, data, true);
        Test.stopTest();

        // THEN - Should get an error about transaction not found
        Assert.areEqual(1, errors.size(), 'Expected one error');
        Assert.isTrue(errors[0].message.contains('TransactionNo not found'),
            'Error should mention transaction not found, got: ' + errors[0].message);
    }

    /**
     * @description Test missing required fields for SkipEligibility
     */
    @IsTest
    static void testUploadApplications_MissingSkipEligibilityRequiredFields() {
        // GIVEN - Missing required fields for SkipEligibility
        List<String> header = new List<String>{
            GradsApplicationUploaderBatch.COL_STUDENT_ID,
            GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM,
            GradsApplicationUploaderBatch.COL_SKIP_ELIGIBILITY,
            'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE,
            'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING
            // Missing many required columns for SkipEligibility
        };

        List<Map<String, String>> data = new List<Map<String, String>>{
            new Map<String, String>{
                GradsApplicationUploaderBatch.COL_STUDENT_ID => STUDENT_ID,
                GradsApplicationUploaderBatch.COL_CAL_SEQ_NUM => String.valueOf(CALENDAR_SEQ_NUM),
                GradsApplicationUploaderBatch.COL_SKIP_ELIGIBILITY => 'true',
                'A.' + GradsApplicationUploaderBatch.COL_COURSE_CODE => 'COURSE001',
                'A.' + GradsApplicationUploaderBatch.COL_IS_ATTENDING => 'true'
            }
        };

        // WHEN - CSV is processed
        Test.startTest();
        GradsApplicationUploaderBatch.Error[] errors = GradsApplicationUploaderBatch.uploadApplications(
            header, data, false);
        Test.stopTest();

        // THEN - Should get errors about missing required SkipEligibility fields
        Assert.isTrue(errors.size() > 0, 'Expected errors');
        Boolean hasSkipEligibilityError = false;

        for (GradsApplicationUploaderBatch.Error error : errors) {
            if (error.message.contains(GradsApplicationUploaderBatch.COL_SKIP_ELIGIBILITY + ' requires CSV column')) {
                hasSkipEligibilityError = true;
                break;
            }
        }

        Assert.isTrue(hasSkipEligibilityError, 'Expected error for missing SkipEligibility required columns');
    }

    /**
     * @description Helper method to create eligibility response JSON
     */
    private static String createEligibilityRespJson(String courseCode) {
        GradsCallistaCalloutService.EligibilityDetails eligibilityDetails = new GradsCallistaCalloutService.EligibilityDetails();
        eligibilityDetails.courseAttempts = new List<GradsCallistaCalloutService.EligibilityCourseAttempt>();

        GradsCallistaCalloutService.EligibilityCourseAttempt courseAttempt = new GradsCallistaCalloutService.EligibilityCourseAttempt();
        courseAttempt.courseCode = courseCode;
        courseAttempt.courseTitle = 'Test Course';
        courseAttempt.courseVersionNumber = 1;
        courseAttempt.graduationAvailableSelections = new List<GradsCallistaCalloutService.EligibilityGraduationAvailableSelection>();

        GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gradSelection = new GradsCallistaCalloutService.EligibilityGraduationAvailableSelection();
        gradSelection.awardDetails = new GradsCallistaCalloutService.EligibilityAward();
        gradSelection.awardDetails.awardCode1 = 'AWD001';
        gradSelection.awardDetails.awardTitle1 = 'Test Award';
        gradSelection.awardDetails.awardTypeIndicator = 'SINGLE';
        gradSelection.awardDetails.awardCourseCode = courseCode;
        gradSelection.awardDetails.awardCourseTitle = 'Test Course';
        gradSelection.awardDetails.awardCourseVersionNumber = 1;

        courseAttempt.graduationAvailableSelections.add(gradSelection);
        eligibilityDetails.courseAttempts.add(courseAttempt);

        // Create mock callout response
        GradsCallistaCalloutService.EligibilityResponse mockResponse = new GradsCallistaCalloutService.EligibilityResponse();
        mockResponse.graduationEligibilityDetails = eligibilityDetails;

        return JSON.serialize(mockResponse);
    }
}