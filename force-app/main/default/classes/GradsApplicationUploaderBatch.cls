/**
 * @description Batchable class to upload and update Graduation Applications from a CSV file
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 * @revision    2025-04-03 - Added update functionality and simplified logic
 * @revision    2025-16-08 - Enhance various validations and dupe checks
 *
 * TODO:
 *   - When AppStatus is Applied, Attending Awards require a Receipt Number
 *   - Return missing studentId and CalendarSeqNum errors with a row number
 *   - Allow settings fields of Apps that have multiple children if all children are in CSV and match
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class GradsApplicationUploaderBatch implements Database.Batchable<CsvRow>, Database.Stateful, Database.AllowsCallouts {

    public class CsvRow {
        public GradsApplicationCreator.ApplicationInput appInput;
        public GradsApplicationCreator.ApplicationOutput appOutput;
        public Map<String,String> originalCsvData;
        public Integer originalCsvRow;
        // For update mode only
        public Id existingAwardId;
        public Id existingApplicationId;
    }

    public class Error {
        @AuraEnabled public Integer inputRow;
        @AuraEnabled public String message;

        public Error(Integer inputRow, String message) {
            this.inputRow = inputRow;
            this.message = message;
        }
        public Error(String message) {
            this.inputRow = null;
            this.message = message;
        }
    }

    public static final String COL_TRANSACTION_NO = 'TransactionNo';
    public static final String COL_STUDENT_ID = 'StudentPersonId';
    public static final String COL_EMAIL = 'EmailAddress';
    public static final String COL_TESTAMUR_NAME = 'TestamurName';
    public static final String COL_CAL_SEQ_NUM = 'CalendarSequenceNumber';
    public static final String COL_PAID_AMOUNT = 'PaidAmount';
    public static final String COL_COMMENTS = 'Comments';
    public static final String COL_APP_STATUS = 'AppStatus'; // Applied, Draft, Internal Draft

    public static final String COL_COURSE_CODE = 'CourseCode';
    public static final String COL_AWARD_TYPE = 'AwardTypeIndicator'; // Combined, Single, Alternative Exit
    public static final String COL_AWARD_CODE1 = 'AwardCode1';
    public static final String COL_AWARD_CODE2 = 'AwardCode2';
    public static final String COL_AWARD_COURSE_CODE = 'AwardCourseCode';
    public static final String COL_RECEIPT_NUMBER = 'ReceiptNumber';
    public static final String COL_IS_ATTENDING = 'IsAttending';

    public static final String COL_SKIP_ELIGIBILITY = 'SkipEligibilityCheck'; // Boolean flag

    // Columns required when COL_SKIP_ELIGIBILITY is true
    public static final String COL_COURSE_TITLE = 'CourseTitle';
    public static final String COL_AWARD_CODE1_TITLE = 'AwardCode1Title';
    public static final String COL_AWARD_CODE2_TITLE = 'AwardCode2Title';
    public static final String COL_AWARD_COURSE_TITLE = 'AwardCourseTitle';
    public static final String COL_COURSE_VERSION = 'CourseVersionNumber'; // For update mode
    public static final String COL_AWARD_COURSE_VERSION = 'AwardCourseVersionNumber'; // For update mode

    class UploaderException extends Exception {}

    public static Set<String> requiredColumnsInsert = new Set<String>{
        COL_STUDENT_ID, COL_CAL_SEQ_NUM
    };

    public static Set<String> requiredColumnsUpdate = new Set<String>{
        COL_TRANSACTION_NO
    };

    // fields required when using SkipEligibility
    public static Set<String> requiredColumnsSkipEligibility = new Set<String>{
        COL_COURSE_CODE, COL_AWARD_TYPE, COL_AWARD_CODE1, COL_AWARD_CODE2, COL_AWARD_COURSE_CODE,
        COL_COURSE_TITLE, COL_AWARD_CODE1_TITLE, COL_AWARD_CODE2_TITLE, COL_AWARD_COURSE_TITLE,
        COL_COURSE_VERSION, COL_AWARD_COURSE_VERSION, COL_IS_ATTENDING
    };

    public static Map<SObjectField, Integer> fieldLengths = new Map<SObjectField, Integer>();

    /**
     * @description Load the CSV data into ApplicationInput objects, validate, and start the batch
     * @param header list of column names
     * @param data list of maps of column names to values
     * @param isUpdate boolean flag indicating if this is an update operation
     *
     * @return list of errors encountered during processing (empty if successful)
     */
    @AuraEnabled
    public static Error[] uploadApplications(String[] header, List<Map<String,String>> data, Boolean isUpdate) {
        Error[] errors = new Error[0];

        // Step 1: Check required CSV columns
        errors.addAll(validateRequiredColumns(header, isUpdate));
        if (!errors.isEmpty()) return errors;

        // Step 2: Process CSV data into structured objects
        CsvRow[] csvRows = new CsvRow[0];
        ProcessingResult result = processCsvData(header, data, isUpdate);
        csvRows = result.csvRows;
        errors.addAll(result.errors);

        // Step 3: Check columns that are conditionally required
        errors.addAll(validateConditionallyRequiredColumns(header, result.hasSkipEligibility, isUpdate));
        if (!errors.isEmpty()) return errors;

        // Step 4: Validate input data
        errors.addAll(validateInputData(csvRows, result.hasSkipEligibility, isUpdate));
        if (!errors.isEmpty()) return errors;

        // Step 5: Perform database validation
        errors.addAll(performDatabaseValidation(csvRows, isUpdate, result.studentIds,
            result.calendarSeqNums, result.transactionNumbers,
            result.uniqueKeysForDbCheck));

        if (!errors.isEmpty()) return errors;

        // Step 6: Start the uploader batch
        Database.executeBatch(new GradsApplicationUploaderBatch(csvRows, header, isUpdate), 10);

        return errors;
    }

    /**
     * @description Helper class to hold processing results
     */
    private class ProcessingResult {
        public CsvRow[] csvRows = new CsvRow[0];
        public Set<String> studentIds = new Set<String>();
        public Set<String> calendarSeqNums = new Set<String>();
        public Set<String> transactionNumbers = new Set<String>();
        public Set<String> uniqueKeysForDbCheck = new Set<String>();
        public Error[] errors = new Error[0];
        public Boolean hasSkipEligibility = false; // Flag to check if any row has SkipEligibility
    }

    /**
     * @description Check CSV contains initially required columns
     */
    private static Error[] validateRequiredColumns(String[] header, Boolean isUpdate) {
        Error[] errors = new Error[0];
        Set<String> csvColumns = new Set<String>(header);
        Set<String> requiredColumns = isUpdate ? requiredColumnsUpdate : requiredColumnsInsert;

        if (!csvColumns.containsAll(requiredColumns)) {
            Set<String> missingColumns = new Set<String>(requiredColumns);
            missingColumns.removeAll(header);
            for (String missingCol : missingColumns) {
                errors.add(new Error('CSV column missing: ' + missingCol));
            }
        }

        return errors;
    }

    /**
     * @description Check for columns that are required due to certain input values
     */
    private static Error[] validateConditionallyRequiredColumns(String[] header, Boolean hasSkipEligibility, Boolean isUpdate) {
        Error[] errors = new Error[0];

        if(hasSkipEligibility) {
            // When not using Eligibility API all fields are required
            if (isUpdate) {
                // Updates only have one award per row
                for (String colName : requiredColumnsSkipEligibility) {
                    if (!header.contains(colName)) {
                        errors.add(new Error(COL_SKIP_ELIGIBILITY + ' requires CSV column: ' + colName));
                    }
                }
            } else {
                // Inserts can have two awards (prefixed A. and B.) per row
                Set<String> requiredColumnsA = new Set<String>();
                Set<String> requiredColumnsB = new Set<String>();
                for (String colName : requiredColumnsSkipEligibility) {
                    requiredColumnsA.add('A.' + colName);
                    requiredColumnsB.add('B.' + colName);
                }
                Set<String> missingColumnsA = new Set<String>(requiredColumnsA);
                Set<String> missingColumnsB = new Set<String>(requiredColumnsB);
                missingColumnsA.removeAll(header);
                missingColumnsB.removeAll(header);

                // If any A columns are present, all required A columns must be present
                if (missingColumnsA.size() > 0 && missingColumnsA.size() != requiredColumnsA.size()) {
                    errors.add(new Error(COL_SKIP_ELIGIBILITY + ' requires CSV columns: ' + String.join(missingColumnsA, ',')));
                }
                // If any B columns are present, all required B columns must be present
                if (missingColumnsB.size() > 0 && missingColumnsB.size() != requiredColumnsB.size()) {
                    errors.add(new Error(COL_SKIP_ELIGIBILITY + ' requires CSV columns: ' + String.join(missingColumnsB, ',')));
                }
            }
        } else {
            // Using Eligibility API lookup can make use of just CourseCode
            if(isUpdate) {
                // Updates only need one of the following columns (in addition to TransactionNo)
                Set<String> requireAtLeastOne = new Set<String>{
                    COL_EMAIL, COL_TESTAMUR_NAME, COL_IS_ATTENDING, COL_CAL_SEQ_NUM, COL_COURSE_CODE, COL_COMMENTS
                };
                Boolean foundAtLeastOne = false;
                for(String colName : header) {
                    if (requireAtLeastOne.contains(colName)) {
                        foundAtLeastOne = true;
                        break;
                    }
                }
                if(!foundAtLeastOne) {
                    errors.add(new Error('CSV must contain at least one field to update'));
                }
            } else {
                // Insert and Using Eligibility API
                Set<String> requiredColumns = new Set<String>{'A.'+COL_COURSE_CODE, 'A.'+COL_IS_ATTENDING};
                Set<String> missingColumns = new Set<String>(requiredColumns);
                missingColumns.removeAll(header);
                if (missingColumns.size() > 0) {
                    errors.add(new Error('Missing required CSV columns: ' + String.join(missingColumns, ',')));
                }
            }
        }
        if(isUpdate) {
            // Validations for all update operations
            if (header.contains(COL_APP_STATUS)) {
                errors.add(new Error('Cannot update Application Status'));
            }
        } else {
            // Validations for all insert operations
            if (header.contains(COL_TRANSACTION_NO)) {
                errors.add(new Error('Cannot include TransactionNo in insert operation'));
            }
        }

        return errors;
    }

    /**
     * @description Processes CSV data into structured CsvRow objects
     */
    private static ProcessingResult processCsvData(String[] header, List<Map<String,String>> data, Boolean isUpdate) {
        ProcessingResult result = new ProcessingResult();
        CsvRow[] csvRows = new CsvRow[0];
        Map<String, Integer> uniqueKeysInCsv = new Map<String, Integer>();
        Map<String, Integer> transactionNumbersInCsv = new Map<String, Integer>();

        // if header contains any B. columns, we have an awardB
        Boolean hasAwardB = false;
        for (String colName : header) {
            if (colName.startsWith('B.')) {
                hasAwardB = true;
                break;
            }
        }

        // Process each row from the CSV
        Integer rowNumber = 1; // First data row is 2
        for (Map<String,String> row : data) {
            CsvRow csvRow = new CsvRow();
            csvRow.originalCsvRow = ++rowNumber;
            csvRow.originalCsvData = row;

            // Create application input objects
            GradsApplicationCreator.ApplicationInput app = createApplicationInput(row, rowNumber, isUpdate, result, hasAwardB);
            csvRow.appInput = app;

            // Generate and check for duplicate Unique Key within CSV
            app.uniqueKey = generateUniqueKey(app.calendarSequenceNumber, app.studentPersonId);
            if (String.isNotBlank(app.uniqueKey)) {
                Integer existingRowNum = uniqueKeysInCsv.get(app.uniqueKey);

                if (existingRowNum != null) {
                    result.errors.add(new Error(rowNumber, 'Duplicate Calendar/Student combination found in Row ' + existingRowNum));
                } else {
                    uniqueKeysInCsv.put(app.uniqueKey, rowNumber);
                    if (!isUpdate) { // Only need to check against DB for inserts
                        result.uniqueKeysForDbCheck.add(app.uniqueKey);
                    }
                }
            }

            // Check for duplicate Transaction Number within CSV
            if (String.isNotBlank(app.callistaTransactionNumber)) {
                Integer duplicateRowNum = transactionNumbersInCsv.get(app.callistaTransactionNumber);
                if (duplicateRowNum != null) {
                    result.errors.add(new Error(rowNumber, 'Duplicate TransactionNo found in Row ' + duplicateRowNum));
                } else {
                    transactionNumbersInCsv.put(app.callistaTransactionNumber, rowNumber);
                }
            }

            csvRows.add(csvRow);
        }

        result.csvRows = csvRows;
        return result;
    }

    /**
     * @description Creates and populates an ApplicationInput object from CSV row data
     */
    private static GradsApplicationCreator.ApplicationInput createApplicationInput(
        Map<String,String> row, Integer rowNumber, Boolean isUpdate, ProcessingResult result, Boolean hasAwardB
    ) {
        GradsApplicationCreator.ApplicationInput app = new GradsApplicationCreator.ApplicationInput();
        app.awardA = new GradsApplicationCreator.AwardInput();
        if (hasAwardB) {
            app.awardB = new GradsApplicationCreator.AwardInput();
        }
        app.skipEligibility = false; // Default to false
        app.status = 'Draft'; // Default to Draft

        // For update mode, get transaction number
        if (isUpdate) {
            String transactionNumber = row.get(COL_TRANSACTION_NO);
            if (String.isBlank(transactionNumber)) {
                result.errors.add(new Error(rowNumber, 'Missing required TransactionNo for update operation'));
            } else {
                result.transactionNumbers.add(transactionNumber);
                app.callistaTransactionNumber = transactionNumber;
            }
        }

        GradsApplicationCreator.AwardInput curAwardInp = app.awardA; // default to A.

        // Map CSV columns to ApplicationInput fields
        for (String colName : row.keySet()) {
            String value = row.get(colName);

            if(!isUpdate && colName.startsWith('A.') || colName.startsWith('B.')) {
                // Handle multiple awards for inserts
                if(colName.startsWith('B.')) {
                    curAwardInp = app.awardB;
                }
                processAwardColumn(colName, colName.substring(2), value, app, curAwardInp, rowNumber, result.errors);
            } else {
                processColumn(colName, value, app, rowNumber, result);
            }
        }
        app.awards = new List<GradsApplicationCreator.AwardInput>{app.awardA};
        if(app.awardB != null) {
            app.awards.add(app.awardB);
        }

        return app;
    }

    /**
     * @description Processes an award-specific column (A.* or B.*)
     */
    private static void processAwardColumn(
        String colName, String fieldName, String value, GradsApplicationCreator.ApplicationInput app,
        GradsApplicationCreator.AwardInput curAwardInp, Integer rowNumber, Error[] errors
    ) {
        if (fieldName == COL_COURSE_CODE) { curAwardInp.courseCode = value; }
        else if (fieldName == COL_AWARD_TYPE) { curAwardInp.awardTypeIndicator = value; }
        else if (fieldName == COL_AWARD_CODE1) { curAwardInp.awardCode1 = value; }
        else if (fieldName == COL_AWARD_CODE2) { curAwardInp.awardCode2 = value; }
        else if (fieldName == COL_AWARD_COURSE_CODE) { curAwardInp.awardCourseCode = value; }
        else if (fieldName == COL_COURSE_TITLE) { curAwardInp.courseTitle = value; }
        else if (fieldName == COL_AWARD_CODE1_TITLE) { curAwardInp.awardCode1Title = value; }
        else if (fieldName == COL_AWARD_CODE2_TITLE) { curAwardInp.awardCode2Title = value; }
        else if (fieldName == COL_AWARD_COURSE_TITLE) { curAwardInp.awardCourseTitle = value; }
        else if (fieldName == COL_COURSE_VERSION) {
            curAwardInp.courseVersionNumber = parseInteger(value, rowNumber, colName, errors);
        }
        else if (fieldName == COL_AWARD_COURSE_VERSION) {
            curAwardInp.awardCourseVersionNumber = parseInteger(value, rowNumber, colName, errors);
        }
        else if (fieldName == COL_IS_ATTENDING) { curAwardInp.isAttending = value == 'true'; }
        else if (fieldName == COL_COMMENTS) { curAwardInp.comments = value; }
    }

    /**
     * @description Processes an application-level column
     */
    private static void processColumn(
        String colName, String value, GradsApplicationCreator.ApplicationInput app,
        Integer rowNumber, ProcessingResult result
    ) {
        if (colName == COL_STUDENT_ID) {
            app.studentPersonId = value;
            if (String.isNotBlank(value)) {
                result.studentIds.add(value);
            }
        }
        else if (colName == COL_CAL_SEQ_NUM) {
            app.calendarSequenceNumber = value;
            if (String.isNotBlank(value)) {
                result.calendarSeqNums.add(value);
            }
        }
        else if (colName == COL_EMAIL) {
            String lengthCheck = validateLength(
                Graduation_Application__c.Student_Personal_Email__c, COL_EMAIL, value
            );
            if (lengthCheck != null) {
                result.errors.add(new Error(rowNumber, lengthCheck));
            }
            app.personalEmail = value;
        }
        else if (colName == COL_TESTAMUR_NAME) {
            String lengthCheck = validateLength(
                Graduation_Application__c.Student_Testamur_Name__c, COL_TESTAMUR_NAME, value
            );
            if (lengthCheck != null) {
                result.errors.add(new Error(rowNumber, lengthCheck));
            }
            app.testamurName = value;
        }
        else if (colName == COL_PAID_AMOUNT) {
            if (String.isNotBlank(value)) {
                if (!value.isNumeric()) {
                    result.errors.add(new Error(rowNumber, 'Has invalid number for column: ' + colName + ' (' + value + ')'));
                } else {
                    app.paidAmount = Decimal.valueOf(value);
                }
            }
        }
        else if (colName == COL_RECEIPT_NUMBER) {
            String lengthCheck = validateLength(
                Graduation_Award__c.Receipt_Number_External_System__c, COL_RECEIPT_NUMBER, value
            );
            if (lengthCheck != null) {
                result.errors.add(new Error(rowNumber, lengthCheck));
            }
            app.awardA.receiptNumber = value;
            if (app.awardB != null) {
                app.awardB.receiptNumber = value;
            }
        }
        else if (colName == COL_SKIP_ELIGIBILITY) {
            app.skipEligibility = value == 'true';
            if(app.skipEligibility) {
                result.hasSkipEligibility = true;
            }
        }
        else if (colName == COL_APP_STATUS) {
            app.status = value;
        }
        else if (colName == COL_COMMENTS) {
            app.comments = value;
        }
        else {
            processAwardColumn(colName, colName, value, app, app.awardA, rowNumber, result.errors);
        }
    }

    private static Error[] validateInputData(CsvRow[] csvRows, Boolean hasSkipEligibility, Boolean isUpdate) {
        Error[] errors = new Error[0];
        for (CsvRow row : csvRows) {
            GradsApplicationCreator.ApplicationInput app = row.appInput;

            for(GradsApplicationCreator.AwardInput ai :app.awards) {
                if(String.isNotBlank(ai.awardTypeIndicator) &&
                    !GradsApplicationCreator.extAwardTypesByCrmAwardType.containsKey(ai.awardTypeIndicator))
                {
                    errors.add(new Error(row.originalCsvRow,  'Invalid AwardTypeIndicator: ' + ai.awardTypeIndicator));
                }
            }

            if(String.isNotBlank(app.personalEmail) &&
                (app.personalEmail.containsNone('@') || app.personalEmail.trim().containsWhitespace()))
            {
                errors.add(new Error(row.originalCsvRow, 'Invalid Email Address: ' + app.personalEmail));
            }

            SObjectField commentField = Graduation_Application__c.Staff_Comments__c;

            if(isUpdate) {
                // Validate data for update

                if(hasSkipEligibility) {
                    // When using SkipEligibilityCheck, additional fields are required
                    checkManualRequiredAwardValues(app.awardA, '', row.originalCsvRow, errors);
                }

                commentField = Graduation_Award__c.Staff_Comments__c; // Comments are written to Award for updates
            } else {
                // Validate data for insert

                if (String.isNotBlank(app.status)) {
                    if(app.status != 'Draft' && app.status != 'Internal Draft' && app.status != 'Applied') {
                        errors.add(new Error(row.originalCsvRow, 'Invalid Application Status: ' + app.status));
                    }
                }

                if (String.isBlank(app.studentPersonId)) {
                    errors.add(new Error(row.originalCsvRow, 'Missing required value for column: ' + COL_STUDENT_ID));
                }
                if (String.isBlank(app.calendarSequenceNumber)) {
                    errors.add(new Error(row.originalCsvRow, 'Missing required value for column: ' + COL_CAL_SEQ_NUM));
                }

                checkRequiredAwardValues(app.awardA, 'A.', row.originalCsvRow, errors);
                if(app.awardB != null) {
                    checkRequiredAwardValues(app.awardB, 'B.', row.originalCsvRow, errors);
                }

                if(hasSkipEligibility) {
                    // When using SkipEligibilityCheck, additional fields are required
                    checkManualRequiredAwardValues(app.awardA, 'A.', row.originalCsvRow, errors);
                    if(app.awardB != null) {
                        checkManualRequiredAwardValues(app.awardB, 'B.', row.originalCsvRow, errors);
                    }
                }
            }

            if(String.isNotBlank(app.comments)) {
                String lengthCheck = validateLength(commentField, COL_COMMENTS, app.comments);
                if (lengthCheck != null) {
                    errors.add(new Error(row.originalCsvRow, lengthCheck));
                }
            }

        }
        return errors;
    }

    /**
     * @description Performs database validation for records
     */
    private static Error[] performDatabaseValidation(
        CsvRow[] csvRows, Boolean isUpdate, Set<String> studentIds,
        Set<String> calendarSeqNums, Set<String> transactionNumbers,
        Set<String> uniqueKeysForDbCheck
    ) {
        Error[] errors = new Error[0];

        Set<Id> applicationUpdateIds = new Set<Id>();

        // For update mode, validate transaction numbers against existing records
        if (isUpdate && !transactionNumbers.isEmpty()) {
            Map<String, Graduation_Award__c> awardsByTransactionNumber = getAwardsByTransactionNumber(transactionNumbers);
            uniqueKeysForDbCheck.clear();

            // Validate transaction numbers exist and collect related application IDs
            for (CsvRow row : csvRows) {
                String transNum = row.appInput.callistaTransactionNumber;
                if (!awardsByTransactionNumber.containsKey(transNum)) {
                    errors.add(new Error(row.originalCsvRow, 'TransactionNo not found in UniCRM: ' + transNum));
                    continue;
                }

                Graduation_Award__c award = awardsByTransactionNumber.get(transNum);
                row.existingAwardId = award.Id;
                row.existingApplicationId = award.Graduation_Application__c;
                applicationUpdateIds.add(award.Graduation_Application__c);

                if( String.isNotBlank(row.appInput.calendarSequenceNumber)) {
                    // Generate unique key (wasn't generated earlier due to lack of student Id in update mode)
                    row.appInput.uniqueKey = generateUniqueKey(row.appInput.calendarSequenceNumber, award.Student_Person_Id__c);
                    uniqueKeysForDbCheck.add(row.appInput.uniqueKey);
                }
            }

            // Check if any application has multiple awards when updating application-level fields
            if (!applicationUpdateIds.isEmpty()) {
                errors.addAll(validateApplicationMultipleAwards(csvRows, applicationUpdateIds));
            }
        }

        // Check for existing applications by Unique Key
        if (!uniqueKeysForDbCheck.isEmpty()) {
            errors.addAll(validateUniqueKeys(csvRows, uniqueKeysForDbCheck, applicationUpdateIds));
        }

        if (!isUpdate) {
            // For insert mode, resolve Student Contact IDs
            if (!studentIds.isEmpty()) {
                errors.addAll(resolveStudentContactIds(csvRows, studentIds));
            }
        }

        // For both modes, resolve Calendar IDs if needed
        if (!calendarSeqNums.isEmpty()) {
            errors.addAll(resolveCalendarIds(csvRows, calendarSeqNums, isUpdate));
        }

        return errors;
    }

    /**
     * @description Validates that applications with multiple awards don't update application-level fields
     */
    private static Error[] validateApplicationMultipleAwards(CsvRow[] csvRows, Set<Id> applicationIds) {
        Error[] errors = new Error[0];
        Map<Id, Integer> awardCountByApplication = getAwardCountByApplication(applicationIds);

        for (CsvRow row : csvRows) {
            if (row.existingApplicationId != null) {
                GradsApplicationCreator.ApplicationInput app = row.appInput;

                // Check if trying to update application-level fields when app has multiple awards
                Boolean updatingAppLevelFields = String.isNotBlank(app.calendarSequenceNumber) ||
                    String.isNotBlank(app.testamurName) || String.isNotBlank(app.personalEmail);

                if (updatingAppLevelFields && awardCountByApplication.get(row.existingApplicationId) > 1) {
                    errors.add(new Error(row.originalCsvRow, 'Tries to update application-level fields ' +
                        'but the award is not the only child of its application'));
                }
            }
        }

        return errors;
    }


    private static Error[] validateUniqueKeys(CsvRow[] csvRows, Set<String> uniqueKeysForDbCheck, Set<Id> ignoreIds) {
        Error[] errors = new Error[0];
        Set<String> existingUniqueKeys = getExistingApplicationUniqueKeys(uniqueKeysForDbCheck, ignoreIds);

        if (!existingUniqueKeys.isEmpty()) {
            for (CsvRow row : csvRows) {
                if (existingUniqueKeys.contains(row.appInput.uniqueKey)) {
                    errors.add(new Error(
                        row.originalCsvRow, 'Student already has Application for Calendar ('+row.appInput.uniqueKey+')'
                    ));
                }
            }
        }

        return errors;

    }

    /**
     * @description Resolves Student Contact IDs from Student IDs
     */
    private static Error[] resolveStudentContactIds(CsvRow[] csvRows, Set<String> studentIds) {
        Error[] errors = new Error[0];
        Map<String,Contact> contactIdsByStudentId = getContactByStudentId(studentIds);

        // Set lookups on each ApplicationInput
        for (CsvRow row : csvRows) {
            if (String.isNotBlank(row.appInput.studentPersonId)) {
                Contact c = contactIdsByStudentId.get(row.appInput.studentPersonId);
                if (c == null) {
                    errors.add(new Error(row.originalCsvRow, 'Student not found in UniCRM: ' + row.appInput.studentPersonId));
                    continue;
                }
                row.appInput.studentContactId = c.Id;

                // Set default name & email
                if(String.isBlank(row.appInput.testamurName)) {
                    row.appInput.testamurName = c.First_Name__c + ' ' + c.Last_Name__c;
                }
                if(String.isBlank(row.appInput.personalEmail)) {
                    row.appInput.personalEmail = c.Personal_Email__c;
                }
            }
        }

        return errors;
    }

    /**
     * @description Resolves Calendar IDs from sequence numbers
     */
    private static Error[] resolveCalendarIds(CsvRow[] csvRows, Set<String> calendarSeqNums, Boolean isUpdate) {
        Error[] errors = new Error[0];
        Map<String,Calendar__c> calIdsBySeqNum = getCalendarsBySeqNum(calendarSeqNums);

        GradsUtils.AppConfig ap = GradsUtils.getAppConfig();

        // Set Cal Id and price
        for (CsvRow row : csvRows) {
            if (String.isNotBlank(row.appInput.calendarSequenceNumber)) {
                Calendar__c cal = calIdsBySeqNum.get(row.appInput.calendarSequenceNumber);
                if (cal == null) {
                    errors.add(new Error(row.originalCsvRow, 'Grad Calendar not found in UniCRM: ' + row.appInput.calendarSequenceNumber));
                    continue;
                }
                row.appInput.gradCalendarId = cal.Id;
                if(row.appInput.paidAmount == null && !isUpdate) {
                    // Set default price based on calendar type for inserts
                    if(cal.Type_Alt__c == 'Clayton') {
                        row.appInput.paidAmount = ap.prices.attendanceAustralia;
                    } else {
                        row.appInput.paidAmount = ap.prices.attendanceInternational;
                    }
                }
            }
        }

        return errors;
    }

    // Batchable implementation
    private String originalTransactionId;
    public String[] csvHeader;
    public CsvRow[] csvRowsByRowNum;
    public Datetime submitTime;
    public Boolean isUpdateOperation;

    public GradsApplicationUploaderBatch(CsvRow[] csvRows, String[] csvHeader, Boolean isUpdate) {
        this.csvHeader = csvHeader;
        this.csvRowsByRowNum = new CsvRow[csvRows.size()];
        this.isUpdateOperation = isUpdate;

        for(CsvRow row : csvRows) {
            row.originalCsvRow = row.originalCsvRow - 2; // Adjust from 1-based with header to 0-based
            if(this.csvRowsByRowNum[row.originalCsvRow] != null) {
                throw new UploaderException('Duplicate row number: ' + row.originalCsvRow);
            }
            this.csvRowsByRowNum[row.originalCsvRow] = row;
        }
        this.submitTime = Datetime.now();
    }

    public Iterable<CsvRow> start(Database.BatchableContext context) {
        Nebula.Logger.setAsyncContext(context);
        this.originalTransactionId = Nebula.Logger.getTransactionId();
        return this.csvRowsByRowNum;
    }

    public void execute(Database.BatchableContext context, List<CsvRow> csvRows) {
        Nebula.Logger.setAsyncContext(context);
        Nebula.Logger.setParentLogTransactionId(this.originalTransactionId);

        // Process based on operation type
        if(this.isUpdateOperation) {
            processUpdateRows(csvRows);
        } else {
            processInsertRows(csvRows);
        }

        Nebula.Logger.saveLog();
    }

    private void processUpdateRows(List<CsvRow> csvRows) {
        GradsApplicationCreator.ApplicationUpdateInput[] updateInputs = new GradsApplicationCreator.ApplicationUpdateInput[0];
        for(CsvRow row : csvRows) {
            GradsApplicationCreator.ApplicationUpdateInput updateInput = new GradsApplicationCreator.ApplicationUpdateInput();
            updateInput.applicationInput = row.appInput;
            updateInput.existingAwardId = row.existingAwardId;
            updateInput.existingApplicationId = row.existingApplicationId;
            updateInputs.add(updateInput);
        }

        GradsCallistaCalloutService.DEFAULT_TIMEOUT_SECS = 10; // Low timeout for batch processing

        GradsApplicationCreator.ApplicationOutput[] updateOutputs = GradsApplicationCreator.updateApplications(updateInputs);

        // Copy the results back to the CSV rows
        for(Integer i = 0; i < updateOutputs.size(); i++) {
            this.csvRowsByRowNum[csvRows[i].originalCsvRow].appOutput = updateOutputs[i];
        }
    }

    private void processInsertRows(List<CsvRow> csvRows) {
        GradsApplicationCreator.ApplicationInput[] appInputs = new GradsApplicationCreator.ApplicationInput[0];
        for(CsvRow row : csvRows) {
            appInputs.add(row.appInput);
        }

        GradsApplicationCreator.ApplicationOutput[] appOutputs = GradsApplicationCreator.createApplications(appInputs);

        // Copy the results back to the CSV rows
        for(Integer i = 0; i < appOutputs.size(); i++) {
            this.csvRowsByRowNum[csvRows[i].originalCsvRow].appOutput = appOutputs[i];
        }
    }

    /**
     * - Starts Batch Callista Sync for created/updated Applications
     * - Emails CSV results to the user
     */
    public void finish(Database.BatchableContext context) {
        // Start Batch Callista Sync for created/updated Applications
        Set<Id> awardsForSync = new Set<Id>();
        for(CsvRow row : this.csvRowsByRowNum) {
            if(row.appOutput.needsSync() && row.appOutput.application.Status__c == 'Applied') {
                for(Graduation_Award__c award : row.appOutput.awards) {
                    awardsForSync.add(award.Id);
                }
            }
        }
        if(awardsForSync.size() > 0) {
            Database.executeBatch(new GradsCallistaSyncBatch(new List<Id>(awardsForSync)), 5);
        }

        // Create results CSVs
        String headerRow = String.join(this.csvHeader, ',');
        String[] successCsvRows = new String[]{headerRow};
        String[] errorCsvRows = successCsvRows.clone();
        successCsvRows[0] += ',ApplicationId,Link';
        errorCsvRows[0] += ',Error';
        String baseUrl = Url.getOrgDomainUrl().toExternalForm();
        for(CsvRow row : this.csvRowsByRowNum) {
            String[] resultRow = new String[0];
            for(String header : this.csvHeader) {
                resultRow.add(row.originalCsvData.get(header)?.escapeCsv() ?? '');
            }
            if(row.appOutput.success) {
                String appId = String.valueOf(row.appOutput.application.Id);
                resultRow.add(appId);
                resultRow.add(baseUrl + '/' + appId);
                successCsvRows.add(String.join(resultRow, ','));
            } else {
                resultRow.add(row.appOutput?.errorMessage?.escapeCsv());
                errorCsvRows.add(String.join(resultRow, ','));
            }
        }

        // Create email
        String fileDate = this.submitTime.format('yyyy-MM-dd');
        String operationType = this.isUpdateOperation ? 'Update' : 'Insert';
        String subject = 'Grads ' + operationType + ' (' + this.submitTime.format('yyyy-MM-dd') + ') Completed ';
        Messaging.EmailFileAttachment[] attachments = new Messaging.EmailFileAttachment[0];
        if(errorCsvRows.size() > 1) {
            Messaging.EmailFileAttachment errorCsv = new Messaging.EmailFileAttachment();
            errorCsv.setFileName('GradsBulk' + operationType + '_Failed_' + fileDate + '.csv');
            errorCsv.setBody(Blob.valueOf(String.join(errorCsvRows, '\n')));
            attachments.add(errorCsv);
            subject += 'with Errors';
        } else {
            subject += 'Successfully';
        }
        if(successCsvRows.size() > 1) {
            Messaging.EmailFileAttachment successCsv = new Messaging.EmailFileAttachment();
            successCsv.setFileName('GradsBulk' + operationType + '_Success_' + fileDate + '.csv');
            successCsv.setBody(Blob.valueOf(String.join(successCsvRows, '\n')));
            attachments.add(successCsv);
        }

        String body = 'The Graduation Application ' + (this.isUpdateOperation ? 'update' : 'insert') + ' has completed.\n';
        if(successCsvRows.size() > 1) {
            body += 'Applications will now begin syncing to Callista.\n\n';
        }
        body += 'Applications ' + (this.isUpdateOperation ? 'Updated' : 'Created') + ': ' + (successCsvRows.size()-1) + '\n';
        body += 'Errors: ' + (errorCsvRows.size()-1) + '\n\n';
        body += 'Please see attached CSVs for details.';

        // Send email to current user
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String fromAddress = 'noreply@f.e.monash.edu';
        mail.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromAddress]?.Id);
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setSaveAsActivity(false);
        mail.setFileAttachments(attachments);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
    }

    private static Map<String,Contact> getContactByStudentId(Set<String> studentIds) {
        Map<String,Contact> ret = new Map<String,Contact>();
        for(Contact contact : [
            SELECT Person_ID_unique__c, First_Name__c, Last_Name__c, Personal_Email__c
            FROM Contact WHERE Person_ID_unique__c IN :studentIds])
        {
            ret.put(contact.Person_ID_unique__c, contact);
        }
        return ret;
    }

    private static Map<String,Calendar__c> getCalendarsBySeqNum(Set<String> seqNums) {
        Map<String,Calendar__c> ret = new Map<String,Calendar__c>();
        for(Calendar__c cal : [
            SELECT Calendar_Code__c, Type_Alt__c FROM Calendar__c
            WHERE Calendar_Code__c IN :seqNums AND Category__c = 'GRADUATION'
        ]) {
            ret.put(cal.Calendar_Code__c, cal);
        }
        return ret;
    }

    private static Map<String, Graduation_Award__c> getAwardsByTransactionNumber(Set<String> transactionNumbers) {
        Map<String, Graduation_Award__c> awardMap = new Map<String, Graduation_Award__c>();
        for(Graduation_Award__c award : [
            SELECT Id, Callista_Transaction_Number__c, Graduation_Application__c, Student_Person_Id__c
            FROM Graduation_Award__c
            WHERE Callista_Transaction_Number__c IN :transactionNumbers
        ]) {
            awardMap.put(award.Callista_Transaction_Number__c, award);
        }
        return awardMap;
    }

    private static Map<Id, Integer> getAwardCountByApplication(Set<Id> applicationIds) {
        Map<Id, Integer> countMap = new Map<Id, Integer>();
        for(AggregateResult ar : [
            SELECT Graduation_Application__c, COUNT(Id) awardCount
            FROM Graduation_Award__c
            WHERE Graduation_Application__c IN :applicationIds
            GROUP BY Graduation_Application__c
        ]) {
            countMap.put((Id)ar.get('Graduation_Application__c'), (Integer)ar.get('awardCount'));
        }
        return countMap;
    }

    // Helper to generate the unique key consistently
    private static String generateUniqueKey(String calendarSeqNum, String studentId) {
        if(String.isBlank(calendarSeqNum) || String.isBlank(studentId)) {
            return null;
        }
        return calendarSeqNum + '|' + studentId;
    }

    // Helper to query existing application unique keys
    private static Set<String> getExistingApplicationUniqueKeys(Set<String> uniqueKeys, Set<Id> ignoreIds) {
        Set<String> existingKeys = new Set<String>();
        for(Graduation_Application__c app : [
            SELECT Unique_Key__c FROM Graduation_Application__c
            WHERE Unique_Key__c IN :uniqueKeys AND Id NOT IN :ignoreIds
        ]) {
            existingKeys.add(app.Unique_Key__c);
        }
        return existingKeys;
    }

    // Helper to parse Integer safely
    private static Integer parseInteger(String value, Integer rowNum, String colName, Error[] errors) {
        if (String.isBlank(value)) return null;
        try {
            return Integer.valueOf(value.trim());
        } catch (Exception e) {
            errors.add(new Error(rowNum, 'Invalid Integer for column: ' + colName + ' (' + value + ')'));
            return null;
        }
    }

    // Helper to validate required values for normal award creation
    private static void checkRequiredAwardValues(GradsApplicationCreator.AwardInput awardInput, String prefix, Integer rowNum, Error[] errors) {
        if (String.isBlank(awardInput.courseCode)) {
            errors.add(new Error(rowNum, 'Missing required value ' + prefix + COL_COURSE_CODE));
        }
    }

    // Helper to validate required values for manual award creation
    private static void checkManualRequiredAwardValues(GradsApplicationCreator.AwardInput awardInput, String prefix, Integer rowNum, Error[] errors) {
        if (String.isBlank(awardInput.courseTitle)) errors.add(new Error(rowNum, 'Missing required value ' + prefix + 'CourseTitle when SkipEligibilityCheck'));
        if (String.isBlank(awardInput.awardTypeIndicator)) errors.add(new Error(rowNum, 'Missing required value ' + prefix + 'AwardTypeIndicator when SkipEligibilityCheck'));
        if (String.isBlank(awardInput.awardCode1)) errors.add(new Error(rowNum, 'Missing required value ' + prefix + '.AwardCode1 when SkipEligibilityCheck'));
        if (String.isBlank(awardInput.awardCode1Title)) errors.add(new Error(rowNum, 'Missing required value ' + prefix + '.AwardCode1Title when SkipEligibilityCheck'));
        if (String.isBlank(awardInput.awardCourseCode)) errors.add(new Error(rowNum, 'Missing required value ' + prefix + '.AwardCourseCode when SkipEligibilityCheck'));
        if (String.isBlank(awardInput.awardCourseTitle)) errors.add(new Error(rowNum, 'Missing required value ' + prefix + '.AwardCourseTitle when SkipEligibilityCheck'));
        if (awardInput.courseVersionNumber == null) errors.add(new Error(rowNum, 'Missing required value ' + prefix + '.CourseVersionNumber when SkipEligibilityCheck'));
        if (awardInput.awardCourseVersionNumber == null) errors.add(new Error(rowNum, 'Missing required value ' + prefix + '.AwardCourseVersionNumber when SkipEligibilityCheck'));
        // AwardCode2 and its title are optional
    }

    /**
     * @description Returns the length of a field, caching the result to avoid repeated Describe calls.
     */
    public static Integer getFieldLength(SObjectField field) {
        Integer length = field.getDescribe().getLength();
        if( length == null) {
            length = field.getDescribe().getLength();
            fieldLengths.put(field, length);
        }
        return length;
    }

    /**
     * @description Validates the length of a field value
     * Returns an error message if the value exceeds the field's maximum length, otherwise returns null.
     */
    public static String validateLength(SObjectField field, String name, String value) {
        if (String.isBlank(value)) {
            return null; // No error for blank values
        }

        Integer maxLength = getFieldLength(field);

        if (value.length() > maxLength) {
            return name + 'value exceeds maximum length of ' + maxLength + ' characters';
        }
        return null;
    }

}