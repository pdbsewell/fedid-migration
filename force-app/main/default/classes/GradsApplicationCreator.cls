/**
 * @description Class for creating and updating Graduation Applications
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 * @revision    2025-04-02 - Added update functionality
 * @revision    2025-16-08 - Enhance DML failure handling
 *                         - Re-write to pass PMD.CognitiveComplexity then add SuppressWarnings anyway
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class GradsApplicationCreator {

    public class ApplicationInput {
        public String studentPersonId;
        public String personalEmail;
        public String status;
        public String testamurName;
        public String calendarSequenceNumber;
        public AwardInput awardA;
        public AwardInput awardB;
        public AwardInput[] awards;
        public Decimal paidAmount;
        public String comments;
        public String callistaTransactionNumber;
        public Boolean skipEligibility = false;

        public Id studentContactId;
        public Id gradCalendarId;
        public String uniqueKey;

        public String getAttendanceMode() {
            if (awardA?.isAttending == true || awardB?.isAttending == true) {
                return 'Attending';
            }
            return 'In Absentia';
        }
    }

    public class ApplicationUpdateInput {
        public ApplicationInput applicationInput;
        public Id existingAwardId;
        public Id existingApplicationId;
    }

    public class AwardInput {
        public Boolean isAttending;
        public String courseCode;
        public String awardTypeIndicator;
        public String awardCode1;
        public String awardCode2;
        public String receiptNumber;
        public String comments;
        // Fields for skipping eligibility API
        public String courseTitle;
        public Integer courseVersionNumber;
        public String awardCourseCode;
        public String awardCourseTitle;
        public Integer awardCourseVersionNumber;
        public String awardCode1Title;
        public String awardCode2Title;
    }

    public class ApplicationOutput {
        public Boolean success;
        public Boolean cancelPosted;
        public String errorMessage;
        public String errorDetail;
        public Graduation_Application__c application;
        public Graduation_Award__c[] awards;

        public Boolean needsSync() {
            return success || cancelPosted;
        }
    }

    public static final Map<String, String> crmAwardTypesByExtAwardType = new Map<String, String>{
        'COMBINED' => 'Combined',
        'SINGLE' => 'Single',
        'ALTERNATIVE EXITS' => 'Alternative Exit'
    };
    public static final Map<String, String> extAwardTypesByCrmAwardType = new Map<String, String>();
    static {
        for (String key : crmAwardTypesByExtAwardType.keySet()) {
            extAwardTypesByCrmAwardType.put(crmAwardTypesByExtAwardType.get(key), key);
        }
    }

    /**
     * @description Create Graduation Applications from a list of application inputs
     *  - For each application input, get eligibility details if required
     *  - Create Application and Awards records for each input
     *  - Insert records
     * @param appInputs              List of application inputs
     * @return ApplicationOutput[]   List of results for each application input
     */
    public static ApplicationOutput[] createApplications(ApplicationInput[] appInputs) {
        ApplicationOutput[] results = new ApplicationOutput[appInputs.size()];
        Graduation_Application__c[] appsToInsert = new Graduation_Application__c[0];
        Map<Integer, Integer> resultsIndexByInsertIndex = new Map<Integer, Integer>();

        // Collect student ids to query existing awards
        Set<String> studentIds = new Set<String>();
        for (Integer i = 0; i < appInputs.size(); i++) {
            ApplicationInput appInput = appInputs[i];
            if (String.isNotBlank(appInput.studentPersonId)) {
                studentIds.add(appInput.studentPersonId);
            }
        }
        // Query existing student awards
        Map<String, Map<String, Graduation_Award__c>> activeAwardsByStudentId = getStudentsExistingAwards(studentIds);

        // Process each application input
        for (Integer i = 0; i < appInputs.size(); i++) {
            ApplicationInput appInput = appInputs[i];
            ApplicationOutput result = new ApplicationOutput();
            result.success = true;
            result.cancelPosted = false;
            results[i] = result;

            result.application = new Graduation_Application__c(
                Student_Personal_Email__c = appInput.personalEmail,
                Student_Testamur_Name__c = appInput.testamurName,
                Attendance_Mode__c = appInput.getAttendanceMode(),
                Status__c = appInput.status,
                Expected_Attendance_Fee_Unit_Amount__c = appInput.paidAmount,
                Student__c = appInput.studentContactId,
                Graduation_Calendar__c = appInput.gradCalendarId,
                Staff_Comments__c = appInput.comments,
                Unique_Key__c = GradsUtils.createApplicationUniqueKey(
                    appInput.calendarSequenceNumber,
                    appInput.studentPersonId
                )
            );
            result.awards = new Graduation_Award__c[0];

            try {
                GradsCallistaCalloutService.EligibilityDetails eligibility = null;

                if(!appInput.skipEligibility) {
                    GradsCallistaCalloutService.EligibilityCalloutResult ecr =
                        GradsCallistaCalloutService.getEligibility(appInput.studentPersonId);

                    if (!ecr.success) {
                        result.success = false;
                        result.errorMessage = 'Get Eligibility Error: ' + ecr.errorMessage;
                        ecr.logToNebula();
                        continue;
                    }

                    eligibility = ecr.eligibilityDetails;
                }

                // Process each award
                for (AwardInput awardInput : appInput.awards) {
                    // Adds new awards to result.awards
                    processNewAward(appInput, awardInput, result, eligibility);
                }
                if(result.success) {
                    // Check for duplicate awards
                    Map<String, Graduation_Award__c> existingAwardsByKey = activeAwardsByStudentId.get(appInput.studentPersonId);
                    if(existingAwardsByKey != null) {
                        for(Graduation_Award__c newAward : result.awards) {
                            String key = createAwardDupeKey(newAward);
                            if(existingAwardsByKey.containsKey(key)) {
                                result.success = false;
                                result.errorMessage = 'Duplicate Award: ' + key;
                                break;
                            }
                        }
                    }
                }
                if(result.success) {
                    // Only process if no errors in the CSV row
                    appsToInsert.add(result.application);
                    resultsIndexByInsertIndex.put(appsToInsert.size() - 1, i);
                }
            } catch (Exception e) {
                // Handle any exceptions
                result.success = false;
                result.errorMessage = 'Create Records Error: ' + (appInput.skipEligibility ? '(Manual): ' : '(API): ') + e.getMessage();
                result.errorDetail = e.getStackTraceString();
            }
        }

        // Insert applications and awards
        if (!appsToInsert.isEmpty()) {
            insertApplicationsAndAwards(appsToInsert, results, resultsIndexByInsertIndex);
        }

        return results;
    }

    /**
     * @description Create new award and if successful add to the result
     */
    private static void processNewAward(
        ApplicationInput appInput, AwardInput awardInput, ApplicationOutput result,
        GradsCallistaCalloutService.EligibilityDetails eligibility
    ) {
        // Initialise the award
        Graduation_Award__c award = new Graduation_Award__c(
            Receipt_Number_External_System__c = awardInput.receiptNumber,
            Has_Attendance_Fee_Waiver__c = String.isNotBlank(awardInput.receiptNumber),
            Staff_Comments__c = awardInput.comments,
            Is_Attending_Ceremony__c = awardInput.isAttending
        );

        if (appInput.skipEligibility) {
            // Set award details directly using input data
            setAwardDetails(award, awardInput);
        } else {
            // Set award details using eligibility API data
            GradsCallistaCalloutService.EligibilityCourseAttempt apiCourseAttempt =
                findCourseAttempt(eligibility, awardInput.courseCode);

            if (apiCourseAttempt == null) {
                result.success = false;
                result.errorMessage = 'Course Code not found in Eligibility API: ' + awardInput.courseCode;
                return;
            }

            GradsCallistaCalloutService.EligibilityAward apiAward = findBestMatchingAward(apiCourseAttempt, awardInput);

            if (apiAward == null) {
                result.success = false;
                result.errorMessage = 'Award not found for Course/Type: ' + awardInput.courseCode + ' / ' + awardInput.awardTypeIndicator;
                return;
            }

            setAwardDetails(award, apiAward, apiCourseAttempt);
        }
        result.awards.add(award);
    }

    /**
     * @description Insert application records and child award records. Checks for duplicate award prior to insert
     */
    private static void insertApplicationsAndAwards(
        Graduation_Application__c[] appsToInsert,
        ApplicationOutput[] results,
        Map<Integer, Integer> resultsIndexByInsertIndex
    ) {
        // Map to track which awards belong to which application
        Map<Id, List<Graduation_Award__c>> awardsByAppId = new Map<Id, List<Graduation_Award__c>>();
        // Map to track result index by application ID
        Map<Id, Integer> resultIndexByAppId = new Map<Id, Integer>();

        Savepoint sp = Database.setSavepoint(); // Just in case we can't cleanup failed awards' apps

        // Insert applications
        Database.SaveResult[] appSaveResults = Database.insert(appsToInsert, false);

        // Process application results and prepare awards
        for (Integer i = 0; i < appSaveResults.size(); i++) {
            Integer resultIndex = resultsIndexByInsertIndex.get(i);
            ApplicationOutput result = results[resultIndex];

            if (appSaveResults[i].isSuccess()) {
                // Update the application ID in the result
                Id appId = appSaveResults[i].getId();
                result.application.Id = appId;
                resultIndexByAppId.put(appId, resultIndex);

                // Initialize list for this application's awards
                awardsByAppId.put(appId, new List<Graduation_Award__c>());

                // Prepare awards with application ID and integration ID
                for (Graduation_Award__c award : result.awards) {
                    award.Graduation_Application__c = appId;
                    award.Integration_Id__c = GradsUtils.createAwardIntegrationId(award, appId);
                    awardsByAppId.get(appId).add(award);
                }
            } else {
                // Update result with error
                result.success = false;
                result.errorMessage = 'Application Insert Error: ' + appSaveResults[i].getErrors()[0].getMessage();
            }
        }

        // Collect all awards to insert
        List<Graduation_Award__c> awardsToInsert = new List<Graduation_Award__c>();
        for (List<Graduation_Award__c> appAwards : awardsByAppId.values()) {
            awardsToInsert.addAll(appAwards);
        }

        // Insert awards with allOrNothing = false
        if (!awardsToInsert.isEmpty()) {
            Map<Id, Graduation_Application__c> appsToRollback = new Map<Id, Graduation_Application__c>();

            // Insert awards and track results
            Database.SaveResult[] awardSaveResults = Database.insert(awardsToInsert, false);

            // Track which applications have award errors
            for (Integer i = 0; i < awardSaveResults.size(); i++) {
                Graduation_Award__c award = awardsToInsert[i];
                Id appId = award.Graduation_Application__c;
                Integer resultIndex = resultIndexByAppId.get(appId);
                ApplicationOutput result = results[resultIndex];

                if (!awardSaveResults[i].isSuccess()) {
                    // Mark this award as failed
                    result.success = false;
                    String errorMsg = awardSaveResults[i].getErrors()[0].getMessage();
                    result.errorMessage = 'Award Insert Error: ' + errorMsg;

                    // Track this application for rollback
                    if (!appsToRollback.containsKey(appId)) {
                        appsToRollback.put(appId, result.application);
                    }

                    Nebula.Logger.error('Failed to create Graduation_Award__c record: ' + errorMsg).
                        setDatabaseResult(awardSaveResults);
                }
            }

            // Remove created applications that have failed awards
            if (!appsToRollback.isEmpty()) {
                try {
                    delete appsToRollback.values();
                } catch (DmlException e) {
                    Database.rollback(sp); // Last-ditch effort - Rollback to the savepoint
                    Nebula.Logger.error('Failed to delete newly created applications with failed awards')
                        .setExceptionDetails(e);
                }
            }
        }
    }

    /**
     * @description Container class for update context data
     */
    private class UpdateContext {
        public Map<Id, Graduation_Award__c> awardsById;
        public Map<Id, Graduation_Award__c> originalAwardInstancesById;
        public Map<Id, Graduation_Application__c> appsById;
        public Map<Id, Graduation_Award__c[]> relatedAwardsByAppId;
        public Map<String, Map<String, Graduation_Award__c>> activeAwardsByStudentId;
    }

    /**
     * @description Update Graduation Applications from a list of application update inputs
     * @param updateInputs           List of application update inputs
     * @return ApplicationOutput[]   List of results for each application update input
     */
    public static ApplicationOutput[] updateApplications(ApplicationUpdateInput[] updateInputs) {
        ApplicationOutput[] results = new ApplicationOutput[updateInputs.size()];

        // Step 1: Query and prepare existing records
        UpdateContext context = prepareUpdateContext(updateInputs);

        // Step 2: Process each update
        Map<Id,Graduation_Award__c> awardsToUpdate = new Map<Id,Graduation_Award__c>();
        Map<Id,Graduation_Application__c> appsToUpdate = new Map<Id,Graduation_Application__c>();
        Map<Id,ApplicationOutput> resultsByAppId = new Map<Id,ApplicationOutput>();

        for (Integer i = 0; i < updateInputs.size(); i++) {
            ApplicationUpdateInput updateInput = updateInputs[i];
            ApplicationOutput result = processUpdateInput(
                updateInput,
                context,
                awardsToUpdate,
                appsToUpdate,
                resultsByAppId
            );
            results[i] = result;
        }

        // Step 3: Perform database updates
        performDatabaseUpdates(awardsToUpdate, appsToUpdate, resultsByAppId, results);

        return results;
    }

    /**
     * @description Process a single update input
     */
    private static ApplicationOutput processUpdateInput(
        ApplicationUpdateInput updateInput,
        UpdateContext context,
        Map<Id,Graduation_Award__c> awardsToUpdate,
        Map<Id,Graduation_Application__c> appsToUpdate,
        Map<Id,ApplicationOutput> resultsByAppId
    ) {
        ApplicationOutput result = new ApplicationOutput();
        result.success = false;
        result.cancelPosted = false;
        ApplicationInput appInput = updateInput.applicationInput;

        try {
            Graduation_Award__c award = context.awardsById.get(updateInput.existingAwardId);
            Graduation_Application__c app = context.appsById.get(updateInput.existingApplicationId);

            // Validate records exist
            if (award == null || app == null) {
                result.success = false;
                result.errorMessage = 'Record not found: ' +
                    (award == null ? 'Award ' + updateInput.existingAwardId :
                        'Application ' + updateInput.existingApplicationId);
                return result;
            }

            appInput.studentPersonId = app.Student__r.Person_ID__c; // ensure studentId not being changed

            // Initialise result
            result.success = true;
            result.application = app;
            result.awards = new Graduation_Award__c[]{award};
            resultsByAppId.put(app.Id, result);

            // Process updates
            UpdateResult updateResult = processFieldUpdates(
                appInput,
                award,
                app,
                context
            );

            if (!updateResult.success) {
                result.success = false;
                result.errorMessage = updateResult.errorMessage;
                return result;
            }

            // Add to update collections
            if (updateResult.needsAppUpdate) {
                appsToUpdate.put(app.Id, app);
            }
            if (updateResult.needsAwardUpdate) {
                awardsToUpdate.put(award.Id, award);
            }
            result.cancelPosted = updateResult.cancelPosted;

            if (!updateResult.needsAppUpdate && !updateResult.needsAwardUpdate && result.success) {
                // No changes detected
                result.success = false;
                result.errorMessage = 'Update Error: No changes detected';
            }

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Update Error: ' + e.getMessage();
            result.errorDetail = e.getStackTraceString();
        }

        return result;
    }

    /**
     * @description Prepare the update context by querying necessary records
     */
    private static UpdateContext prepareUpdateContext(ApplicationUpdateInput[] updateInputs) {
        UpdateContext context = new UpdateContext();

        // Collect IDs
        Set<Id> awardIds = new Set<Id>();
        Set<Id> appIds = new Set<Id>();
        for (ApplicationUpdateInput updateInput : updateInputs) {
            awardIds.add(updateInput.existingAwardId);
            appIds.add(updateInput.existingApplicationId);
        }

        // Query awards and build app map
        context.awardsById = new Map<Id, Graduation_Award__c>(GradsCallistaSyncService.retrieveAwards(awardIds));

        Set<String> studentIds = new Set<String>();
        context.appsById = new Map<Id, Graduation_Application__c>();
        for (Graduation_Award__c award : context.awardsById.values()) {
            context.appsById.put(award.Graduation_Application__r.Id, award.Graduation_Application__r);
            studentIds.add(award.Graduation_Application__r.Student__r.Person_ID__c);
        }

        // Query related awards for attendance mode calculation
        context.relatedAwardsByAppId = new Map<Id, Graduation_Award__c[]>();
        for(Graduation_Application__c app :[
            SELECT (SELECT Is_Attending_Ceremony__c FROM Graduation_Awards__r)
            FROM Graduation_Application__c
            WHERE Id IN :context.appsById.keySet()
        ]) {
            context.relatedAwardsByAppId.put(app.Id, app.Graduation_Awards__r);
        }

        // Get existing awards for duplicate checking
        context.activeAwardsByStudentId = getStudentsExistingAwards(studentIds);

        // Clone for cancellation tracking
        context.originalAwardInstancesById = context.awardsById.deepClone();

        return context;
    }

    /**
     * @description Update attendance mode
     */
    private static Boolean updateAttendanceMode(
        Graduation_Award__c award,
        Graduation_Application__c app,
        Boolean isAttending,
        Graduation_Award__c[] relatedAwards
    ) {
        award.Is_Attending_Ceremony__c = isAttending;

        // Recalculate attendance mode based on all awards
        Boolean anyAttending = false;
        for (Graduation_Award__c relatedAward : relatedAwards) {
            if (relatedAward.Id == award.Id) {
                if (award.Is_Attending_Ceremony__c) {
                    anyAttending = true;
                }
            } else if (relatedAward.Is_Attending_Ceremony__c) {
                anyAttending = true;
                break;
            }
        }

        String attendanceMode = anyAttending ? 'Attending' : 'In Absentia';
        if (attendanceMode != app.Attendance_Mode__c) {
            app.Attendance_Mode__c = attendanceMode;
            return true;
        }

        return false;
    }

    /**
    * @description Result of field updates
    */
    private class UpdateResult {
        public Boolean success = true;
        public String errorMessage;
        public Boolean needsAwardUpdate = false;
        public Boolean needsAppUpdate = false;
        public Boolean cancelPosted = false;
    }

    /**
     * @description Process all field updates for an application/award
     */
    private static UpdateResult processFieldUpdates(
        ApplicationInput appInput,
        Graduation_Award__c award,
        Graduation_Application__c app,
        UpdateContext context
    ) {
        UpdateResult result = new UpdateResult();
        AwardInput awardInput = appInput.awardA;

        // 1. Update comments (award level) - Allow blanking
        if (appInput?.comments != null && appInput.comments != award.Staff_Comments__c) {
            // TODO allow appending
            award.Staff_Comments__c = appInput.comments;
            result.needsAwardUpdate = true;
        }

        // 2. Change Selected Award
        if (awardInput != null && awardHasChange(awardInput)) {
            AwardChangeResult awardChange = processAwardChange(
                appInput,
                awardInput,
                award,
                app,
                context
            );

            if (!awardChange.success) {
                result.success = false;
                result.errorMessage = awardChange.errorMessage;
                return result;
            } else {
                result.cancelPosted = awardChange.cancelPosted;
            }

            result.needsAwardUpdate = true;
        }

        // 3. Change Attendance Mode
        if (awardInput?.isAttending != null && awardInput.isAttending != award.Is_Attending_Ceremony__c) {
            Boolean attendanceResult = updateAttendanceMode(
                award,
                app,
                awardInput.isAttending,
                context.relatedAwardsByAppId.get(app.Id)
            );
            result.needsAwardUpdate = true;
            if (attendanceResult) {
                result.needsAppUpdate = true;
            }
        }

        // 4. Process other application field updates
        if (processApplicationFieldUpdates(appInput, app)) {
            result.needsAppUpdate = true;
        }

        // 5. Receipt Number
        if (String.isNotBlank(awardInput?.receiptNumber) &&
            awardInput?.receiptNumber != award.Receipt_Number_External_System__c) {
            award.Receipt_Number_External_System__c = awardInput.receiptNumber;
            result.needsAwardUpdate = true;
        }

        return result;
    }

    /**
     * @description Result of award change processing
     */
    private class AwardChangeResult {
        public Boolean success = true;
        public String errorMessage;
        public Boolean needsRecreation = false;
        public Boolean cancelPosted = false;
    }

    /**
     * @description Process award changes (with or without API)
     */
    private static AwardChangeResult processAwardChange(
        ApplicationInput appInput,
        AwardInput awardInput,
        Graduation_Award__c award,
        Graduation_Application__c app,
        UpdateContext context
    ) {
        AwardChangeResult result = new AwardChangeResult();

        Boolean isCallistaActive = String.isNotBlank(award.Callista_Transaction_Number__c) &&
            (award.Cancellation_Date__c == null || award.Cancellation_Succeeded__c == false);

        if (appInput.skipEligibility) {
            // Process without API
            result = processAwardChangeManual(awardInput, award, isCallistaActive);
        } else {
            // Process with API
            result = processAwardChangeWithAPI(
                appInput,
                awardInput,
                award,
                app,
                isCallistaActive
            );
        }

        if (result.success) {
            // Check for duplicates
            Map<String, Graduation_Award__c> existingAwards = context.activeAwardsByStudentId.get(appInput.studentPersonId);
            if (existingAwards != null) {
                String key = createAwardDupeKey(award);
                Graduation_Award__c existingAward = existingAwards.get(key);
                if (existingAward != null && existingAward.Id != award.Id) {
                    result.success = false;
                    result.errorMessage = 'Award Already Exists: ' + existingAward.Id + ' ' + key;
                    return result;
                }
            }

            // Update integration ID
            award.Integration_Id__c = GradsUtils.createAwardIntegrationId(award, app.Id);

            // Handle Callista recreation if needed
            if (result.needsRecreation) {
                String cancelResult = cancelCallistaAward(
                    award,
                    context.originalAwardInstancesById.get(award.Id)
                );
                if (cancelResult != null) {
                    result.success = false;
                    result.errorMessage = cancelResult;
                } else {
                    result.cancelPosted = true;
                }
            }
        }

        return result;
    }

    /**
     * @description Process award change without API (manual mode)
     */
    private static AwardChangeResult processAwardChangeManual(
        AwardInput awardInput,
        Graduation_Award__c award,
        Boolean isCallistaActive
    ) {
        AwardChangeResult result = new AwardChangeResult();

        // Check if immutable Callista fields have changed
        result.needsRecreation = isCallistaActive && (
            (awardInput.courseCode != null && awardInput.courseCode != award.Course_Code__c) ||
            (awardInput.awardCode1 != null && awardInput.awardCode1 != award.Award_Code_1__c) ||
            (awardInput.awardCode2 != null && awardInput.awardCode2 != award.Award_Code_2__c)
        );

        // Update award using input
        setAwardDetails(award, awardInput);

        return result;
    }

    /**
     * @description Process award change with eligibility API
     */
    private static AwardChangeResult processAwardChangeWithAPI(
        ApplicationInput appInput,
        AwardInput awardInput,
        Graduation_Award__c award,
        Graduation_Application__c app,
        Boolean isCallistaActive
    ) {
        AwardChangeResult result = new AwardChangeResult();

        // Call eligibility API
        GradsCallistaCalloutService.EligibilityCalloutResult eligibility =
            GradsCallistaCalloutService.getEligibility(app.Student__r.Person_ID__c);

        if (!eligibility.success) {
            result.success = false;
            result.errorMessage = 'Callista Eligibility API Error: ' + eligibility.errorMessage;
            eligibility.logToNebula();
            return result;
        }

        // Find course attempt
        GradsCallistaCalloutService.EligibilityCourseAttempt apiCourseAttempt =
            findCourseAttempt(eligibility.eligibilityDetails, awardInput.courseCode);

        if (apiCourseAttempt == null) {
            result.success = false;
            result.errorMessage = 'Course Code not found in Eligibility API: ' + awardInput.courseCode;
            return result;
        }

        // Find matching award
        GradsCallistaCalloutService.EligibilityAward apiAward =
            findBestMatchingAward(apiCourseAttempt, awardInput);

        if (apiAward == null) {
            result.success = false;
            result.errorMessage = 'Award not found for Course/Type: ' +
                awardInput.courseCode + ' / ' + awardInput.awardTypeIndicator;
            return result;
        }

        // Check if immutable Callista fields have changed
        result.needsRecreation = isCallistaActive && (
            apiCourseAttempt.courseCode != award.Course_Code__c ||
            apiAward.awardCode1 != award.Award_Code_1__c ||
            (String.isNotBlank(apiAward.awardCode2) && apiAward.awardCode2 != award.Award_Code_2__c)
        );

        // Update award using API data
        setAwardDetails(award, apiAward, apiCourseAttempt);

        return result;
    }

    /**
     * @description Cancel award in Callista
     * @return String error message if cancellation failed, null if successful
     */
    private static String cancelCallistaAward(
        Graduation_Award__c award,
        Graduation_Award__c originalAward
    ) {
        originalAward.Cancellation_Date__c = Datetime.now();

        GradsCallistaCalloutService.ApplicationCalloutResult cr;
        try {
            cr = GradsCallistaSyncService.submitAwardRequest(originalAward);
        } catch (Exception e) {
            String errorMessage = 'Failed to cancel Application in Callista for recreation: ' + e.getMessage();
            Nebula.Logger.error(errorMessage).setExceptionDetails(e).setRecord(award);
            return errorMessage;
        }

        cr.logToNebula();

        if (!cr.success) {
            return 'Failed to cancel Application in Callista for recreation: ' + cr.errorMessage;
        }

        award.Callista_Transaction_Number__c = null;
        return null;
    }

    /**
     * @description Process application field updates (calendar, name, email)
     * @return Boolean indicating if any fields were updated
     */
    private static Boolean processApplicationFieldUpdates(
        ApplicationInput appInput,
        Graduation_Application__c app
    ) {
        Boolean updated = false;

        // Change Calendar
        if (String.isNotBlank(appInput.calendarSequenceNumber) && appInput.gradCalendarId != app.Graduation_Calendar__c) {
            app.Graduation_Calendar__c = appInput.gradCalendarId;
            app.Unique_Key__c = appInput.calendarSequenceNumber + '|' + appInput.studentPersonId;
            updated = true;
        }

        // Change Testamur Name
        if (String.isNotBlank(appInput.testamurName) && appInput.testamurName != app.Student_Testamur_Name__c) {
            app.Student_Testamur_Name__c = appInput.testamurName;
            updated = true;
        }

        // Change Personal Email
        if (String.isNotBlank(appInput.personalEmail) && appInput.personalEmail != app.Student_Personal_Email__c) {
            app.Student_Personal_Email__c = appInput.personalEmail;
            updated = true;
        }

        return updated;
    }

    /**
     * @description This mess performs our DML update but in the event of failure, performs some "back-up" DML.
     *  - The main thing is that it's possible we have already modified Callista data at this point
     *  - At a minimum, we attempt to clear the Callista Transaction Numbers on Awards that were cancelled in Callista
     */
    private static void performDatabaseUpdates(
        Map<Id,Graduation_Award__c> awardsToUpdate,
        Map<Id,Graduation_Application__c> appsToUpdate,
        Map<Id,ApplicationOutput> resultsByAppId,
        ApplicationOutput[] results
    ) {
        Savepoint sp = Database.setSavepoint();

        // Collect Awards that were cancelled in Callista but are unable to update
        Set<Id> awardIdsCancelledWithError = new Set<Id>();

        try {
            // Plan A.
            if (!appsToUpdate.isEmpty()) {
                Triggers.bypass('GraduationApplicationTriggerHandler.DetectWriteBackRequired');
                Database.SaveResult[] dmlResults = Database.update(appsToUpdate.values(), false);
                Triggers.clearBypass('GraduationApplicationTriggerHandler.DetectWriteBackRequired');

                for(Database.SaveResult sr : dmlResults) {
                    if (!sr.isSuccess()) {
                        // Remove this app's award from the update
                        Graduation_Application__c app = appsToUpdate.get(sr.getId());
                        ApplicationOutput result = resultsByAppId.get(app.Id);
                        result.success = false;

                        awardsToUpdate.remove(result.awards[0].Id);
                        if(result.cancelPosted) {
                            awardIdsCancelledWithError.add(result.awards[0].Id);
                            result.errorMessage = 'App DML Error (TransNo cleared): ';
                        } else {
                            result.errorMessage = 'App DML Error: ';
                        }
                        result.errorMessage += sr.getErrors()[0].getMessage();

                        Nebula.Logger.error('Failed to update Graduation_Application__c record: ' +
                            sr.getErrors()[0].getMessage())
                            .setDatabaseResult(sr).setRecord(app);
                    }
                }
            }

            if (!awardsToUpdate.isEmpty()) {
                Triggers.bypass('GraduationAwardTriggerHandler.DetectWriteBackRequired');
                update awardsToUpdate.values();
                Triggers.clearBypass('GraduationAwardTriggerHandler.DetectWriteBackRequired');
            }
        } catch (DmlException e) {
            Database.rollback(sp);
            // Ensure everything is marked as failed whilst retaining existing errors
            for (ApplicationOutput result : results) {
                if(result.cancelPosted) {
                    awardIdsCancelledWithError.add(result.awards[0].Id);
                }
                if(result.success) {
                    result.success = false;
                    result.errorMessage = 'DML Error: ' + e.getMessage();
                    result.errorDetail = e.getStackTraceString();
                }
            }
            Nebula.Logger.error('Failed to update records: ' + e.getMessage()).setExceptionDetails(e);
        }


        if(!awardIdsCancelledWithError.isEmpty()) {
            // Plan B. Clear the Transaction Numbers and let the batch sync job re-create the apps
            Graduation_Award__c[] awardsToClearTransNo = new Graduation_Award__c[0];
            for(Id awardId : awardIdsCancelledWithError) {
                awardsToClearTransNo.add(new Graduation_Award__c(Id = awardId, Callista_Transaction_Number__c = null));
            }
            try {
                update awardsToClearTransNo;
            } catch (Exception e) {
                // Something is very wrong, nothing else we can do
                Nebula.Logger.error('All DML Failed').setExceptionDetails(e);
            }
        }
    }

    /**
     * @description  Find the course attempt from eligibility details
     */
    private static GradsCallistaCalloutService.EligibilityCourseAttempt findCourseAttempt(
        GradsCallistaCalloutService.EligibilityDetails eligibilityDetails,
        String courseCode
    ) {
        GradsCallistaCalloutService.EligibilityCourseAttempt apiCourseAttempt = null;
        for (GradsCallistaCalloutService.EligibilityCourseAttempt ca : eligibilityDetails.courseAttempts) {
            if (ca.courseCode == courseCode) {
                apiCourseAttempt = ca;
                break;
            }
        }
        return apiCourseAttempt;
    }

    /**
      * @description Find closest match from eligibility details
      * @param courseAttempt The course attempt containing available selections
      * @param awardPreference The ordered list of award type preferences
      * @param awardInput The award input with code constraints
      * @return EligibilityAward The selected award or null
      */
    @TestVisible
    private static GradsCallistaCalloutService.EligibilityAward findBestMatchingAward(
        GradsCallistaCalloutService.EligibilityCourseAttempt courseAttempt,
        AwardInput awardInput
    ) {
        // Select an award based on awardCode1+awardCode2+awardTypeIndicator - If any are supplied, they must match.
        // If not, select the award with the highest preferred awardTypeIndicator 'COMBINED' > 'SINGLE' > 'ALTERNATIVE EXITS'

        String[] awardPreference = String.isNotBlank(awardInput.awardTypeIndicator) ?
            new String[]{
                awardInput.awardTypeIndicator
            } :
            new String[]{
                'COMBINED', 'SINGLE', 'ALTERNATIVE EXITS'
            };

        GradsCallistaCalloutService.EligibilityAward selectedAward = null;

        for (String preference : awardPreference) {
            for (GradsCallistaCalloutService.EligibilityGraduationAvailableSelection gas : courseAttempt.graduationAvailableSelections) {
                if (String.isNotBlank(awardInput.awardCode1) && gas.awardDetails.awardCode1 != awardInput.awardCode1) {
                    continue;
                }
                if (String.isNotBlank(awardInput.awardCode2) && gas.awardDetails.awardCode2 != awardInput.awardCode2) {
                    continue;
                }
                if (gas.awardDetails.awardTypeIndicator == preference) {
                    selectedAward = gas.awardDetails;
                    break;
                }
            }
            if (selectedAward != null) {
                break;
            }
        }

        return selectedAward;
    }

    /**
     * @description Set award details using eligibility API data
     */
    private static void setAwardDetails(
        Graduation_Award__c award,
        GradsCallistaCalloutService.EligibilityAward apiAward,
        GradsCallistaCalloutService.EligibilityCourseAttempt apiCourse
    ) {
        award.Award_Type__c = crmAwardTypesByExtAwardType.get(apiAward.awardTypeIndicator);
        award.Course_Code__c = apiCourse.courseCode;
        award.Course_Title__c = apiCourse.courseTitle;
        award.Course_Version_Number__c = apiCourse.courseVersionNumber;
        award.Award_Code_1__c = apiAward.awardCode1;
        award.Award_Code_2__c = apiAward.awardCode2;
        award.Award_Title_1__c = apiAward.awardTitle1;
        award.Award_Title_2__c = apiAward.awardTitle2;
        award.Award_Course_Code__c = apiAward.awardCourseCode;
        award.Award_Course_Title__c = apiAward.awardCourseTitle;
        award.Award_Course_Version__c = apiAward.awardCourseVersionNumber;
    }

    /**
     * @description Set award details using ApplicationInput
     */
    private static void setAwardDetails(Graduation_Award__c award, AwardInput awardInput) {
        award.Award_Type__c = awardInput.awardTypeIndicator;
        award.Course_Code__c = awardInput.courseCode;
        award.Course_Title__c = awardInput.courseTitle;
        award.Course_Version_Number__c = awardInput.courseVersionNumber;
        award.Award_Code_1__c = awardInput.awardCode1;
        award.Award_Code_2__c = awardInput.awardCode2;
        award.Award_Title_1__c = awardInput.awardCode1Title;
        award.Award_Title_2__c = awardInput.awardCode2Title;
        award.Award_Course_Code__c = awardInput.awardCourseCode;
        award.Award_Course_Title__c = awardInput.awardCourseTitle;
        award.Award_Course_Version__c = awardInput.awardCourseVersionNumber;
    }

    private static Boolean awardHasChange(AwardInput ai) {
        return ai.awardCode1 != null || ai.awardCode2 != null ||
            ai.awardTypeIndicator != null || ai.courseCode != null ||
            ai.awardCourseCode != null || ai.courseTitle != null ||
            ai.awardCode1Title != null || ai.awardCode2Title != null ||
            ai.awardCourseTitle != null;
    }

    /**
     * @description Not stored - Used for checking for duplicates prior to insert/update
     */
    private static String createAwardDupeKey(Graduation_Award__c award) {
        return GradsUtils.createAwardIntegrationId(award, null);
    }

    /**
     * @description Get existing awards for students. Map is StudentPersonId -> Map of AwardDupeKey -> Award
     */
    private static Map<String, Map<String, Graduation_Award__c>> getStudentsExistingAwards(Set<String> studentIds) {
        Map<String, Map<String, Graduation_Award__c>> activeAwardsByStudentId = new Map<String, Map<String, Graduation_Award__c>>();
        List<Graduation_Award__c> existingAwards = [
            SELECT Student_Person_Id__c, Course_Code__c, Award_Course_Code__c, Award_Code_1__c, Award_Code_2__c
            FROM Graduation_Award__c
            WHERE Student_Person_Id__c IN :studentIds AND
            Cancellation_Date__c = NULL AND Graduation_Application__r.Status__c != 'Cancelled'
        ];
        for (Graduation_Award__c award : existingAwards) {
            if (!activeAwardsByStudentId.containsKey(award.Student_Person_Id__c)) {
                activeAwardsByStudentId.put(award.Student_Person_Id__c, new Map<String, Graduation_Award__c>());
            }
            activeAwardsByStudentId.get(award.Student_Person_Id__c).put(createAwardDupeKey(award), award);
        }
        return activeAwardsByStudentId;
    }

}