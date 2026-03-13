/**
 * @description Central service for the Callista write-back process
 *              - Map records into Callista request format
 *              - Methods for synchronous and asynchronous Application write-back
 *              - Methods for asynchronous Document write-back
 * @group       Grads
 * @revision    2024-09-23 - Tom Gangemi - Initial version
 * @revision    2025-08-16 - Tom Gangemi - Increase comments field length
 */
public with sharing class GradsCallistaSyncService {

    /**
     * Retrieve everything needed to update the Award in Callista
     * Records with oldest Callista_Writeback_Requested_Time__c first
     */
    public static Graduation_Award__c[] retrieveAwards(Set<Id> awardIds) {
        return [
            SELECT Name, Award_Code_1__c, Award_Code_2__c, Award_Course_Code__c, Award_Course_Title__c,
                Award_Course_Version__c, Award_Title_1__c, Award_Title_2__c, Award_Type__c, Callista_Transaction_Number__c,
                Course_Code__c, Course_Version_Number__c, Cancellation_Date__c, Is_Attending_Ceremony__c,
                Callista_Writeback_Requested_Time__c, Last_Callista_Writeback_Success_Time__c, Writeback_Apex_Job_Id__c,
                Graduation_Application__c, Staff_Comments__c, Receipt_Number_External_System__c,
                Document_Callista_Id__c, Cancellation_Succeeded__c,
                app.Name, app.Student_Testamur_Name__c, app.Student_Testamur_Name_Change_Status__c, app.Status__c,
                app.Student_Personal_Email__c, app.Student__r.Person_ID__c, app.Student__r.IT_account_disabled__c,
                app.Student__r.Monash_Email_Address__c, app.Student__r.Name, app.Document_Writeback_Pending__c,
                app.Additional_Reqs_Graduand__c, app.Additional_Reqs_Description_Graduand__c,
                app.Additional_Reqs_Guest__c, app.Additional_Reqs_Description_Guest__c,
                app.Additional_Reqs_Description_Staff__c, app.Expected_Attendance_Fee_Unit_Amount__c,
                app.Staff_Comments__c, app.Graduation_Calendar__c, app.Attendance_Mode__c,
                cal.Description__c, cal.Type__c, cal.Type_Alt__c,
                cal.Type_Description__c, cal.Sequence_Number__c,
                cal.Start_Date__c, cal.End_Date__c
            FROM Graduation_Award__c awa, awa.Graduation_Application__r app, awa.Graduation_Application__r.Graduation_Calendar__r cal
            WHERE Id IN :awardIds
            ORDER BY Callista_Writeback_Requested_Time__c ASC
        ];
    }

    public static String formatDate(Date d, String format) {
        return Datetime.newInstance(d.year(), d.month(), d.day()).format(format);
    }

    // Replaces anything that isn't an ascii char from space to tilde or whitespaces with a question mark
    public static String replaceNonPrintableAscii(String s) {
        return s?.replaceAll('[^ -~\\n\\r\\t]', '?');
    }

    public static String createSpecialReqStr(Graduation_Application__c app) {
        String[] parts = new String[0];
        if(String.isNotBlank(app.Additional_Reqs_Description_Staff__c)) {
            parts.add(app.Additional_Reqs_Description_Staff__c);
        }
        if(String.isNotBlank(app.Additional_Reqs_Graduand__c)) {
            parts.add('Graduand - ' + String.join(app.Additional_Reqs_Graduand__c.split(';'), ', ') + ' - ' + app.Additional_Reqs_Description_Graduand__c);
        }
        if(String.isNotBlank(app.Additional_Reqs_Guest__c)) {
            parts.add('Guest - ' + String.join(app.Additional_Reqs_Guest__c.split(';'), ', ') + ' - ' + app.Additional_Reqs_Description_Guest__c);
        }
        return String.join(parts, '\n');
    }

    /**
     * Map a Graduation_Award__c record into a Callista request body
     */
    public static GradsCallistaCalloutService.AppReqBody createReq(Graduation_Award__c award) {
        Graduation_Application__c app = award.Graduation_Application__r;
        Calendar__c cal = app.Graduation_Calendar__r;

        GradsCallistaCalloutService.AppReqGraduationApplication reqApp = new GradsCallistaCalloutService.AppReqGraduationApplication();
        reqApp.transactionNo = award.Callista_Transaction_Number__c;
        reqApp.graduationName = replaceNonPrintableAscii(app.Student_Testamur_Name__c);
        reqApp.alternateEmailAddr = app.Student_Personal_Email__c;
        reqApp.authcateIndicator = app.Student__r.IT_account_disabled__c ? 'N' : 'Y';

        // Combine Application and Award level comments but truncate if over 500 characters
        String[] commentParts = new String[0];
        if(String.isNotBlank(app.Staff_Comments__c)) {
            commentParts.add('Ceremony: ' + app.Staff_Comments__c);
        }
        if(String.isNotBlank(award.Staff_Comments__c)) {
            commentParts.add('Award: ' + award.Staff_Comments__c);
        }
        String comments = String.join(commentParts, '\n');
        final Integer maxCommentLength = 1020;
        if(comments.length() > maxCommentLength) {
            String reviewMsg = ' (REVIEW CRM)';
            comments = comments.substring(0, maxCommentLength - reviewMsg.length()) + reviewMsg;
        }
        reqApp.comment = replaceNonPrintableAscii(comments);

        reqApp.nameChangeRequest = String.isNotBlank(app.Student_Testamur_Name_Change_Status__c) ? 'Y' : 'N';
        reqApp.nameChangedStatus = app.Student_Testamur_Name_Change_Status__c?.toUpperCase();

        reqApp.amountPaid = 0;
        if(award.Is_Attending_Ceremony__c) {
            if(app.Expected_Attendance_Fee_Unit_Amount__c != null) {
                reqApp.amountPaid = Integer.valueOf(app.Expected_Attendance_Fee_Unit_Amount__c);
            }
            reqApp.receiptNumber = award.Receipt_Number_External_System__c ?? app.Name;
            reqApp.transactionCode = cal.Type_Alt__c == 'CLAYTON' ? '005' : '006';
        } else {
            reqApp.receiptNumber = 'NO FEE';
            reqApp.transactionCode = '';
        }
        reqApp.graduandType = award.Cancellation_Date__c != null ? 'CANCELLED' : (award.Is_Attending_Ceremony__c ? 'ATTENDING' : 'INABSENTIA');

        reqApp.specialRequirement = replaceNonPrintableAscii(createSpecialReqStr(app));

        reqApp.awardDetails = new GradsCallistaCalloutService.AppReqAwardDetails();

        reqApp.awardDetails.awardCode1 = award.Award_Code_1__c;
        reqApp.awardDetails.awardCourseCode1 = award.Award_Course_Code__c;
        reqApp.awardDetails.awardCourseCode1Version = award.Award_Course_Version__c.intValue();
        reqApp.awardDetails.awardTitle1 = award.Award_Title_1__c;

        if(award.Award_Type__c == 'Combined') {
            reqApp.awardDetails.awardCode2 = award.Award_Code_2__c;
            reqApp.awardDetails.awardCourseCode2 = award.Award_Course_Code__c;
            reqApp.awardDetails.awardCourseCode2Version = award.Award_Course_Version__c.intValue();
            reqApp.awardDetails.awardTitle2 = award.Award_Title_2__c;
        }
        reqApp.alternateExit = 'N';
        if(award.Award_Type__c == 'Alternative Exit') {
            reqApp.alternateExitCourseTitle = award.Award_Course_Title__c;
            reqApp.alternateExit = 'Y';
        }

        reqApp.graduationCalendar = new GradsCallistaCalloutService.AppReqGraduationCalendar();
        reqApp.ceremonyLocation = cal.Description__c;
        reqApp.graduationCalendarType = cal.Type__c;
        reqApp.graduationCiSequenceNumber = Integer.valueOf(cal.Sequence_Number__c);

        reqApp.graduationCalendar.graduationStartDate = formatDate(cal.Start_Date__c, 'yyyy-MM-dd');
        reqApp.graduationCalendar.graduationEndDate = formatDate(cal.End_Date__c, 'yyyy-MM-dd');
        reqApp.graduationCalendar.graduationLocation = cal.Type_Alt__c;
        reqApp.graduationCalendar.graduationLocationSemester = cal.Type_Description__c;
        reqApp.graduationCalendar.graduationLocationType = cal.Type_Alt__c == 'CLAYTON' ? 'ONSHORE' : 'OFFSHORE';

        GradsCallistaCalloutService.AppReqBody req = new GradsCallistaCalloutService.AppReqBody();
        req.courseAttempts = new GradsCallistaCalloutService.AppReqCourseAttempts();
        req.courseAttempts.courseCode = award.Course_Code__c;
        req.courseAttempts.courseVersionNumber = award.Course_Version_Number__c.intValue();

        replaceNullsWithEmptyStrings(reqApp);
        req.graduationApplication = reqApp;

        return req;
    }

    /**
     * Replace null values with empty strings to ensure that data that becomes blank is sent to Callista
     */
    public static void replaceNullsWithEmptyStrings(GradsCallistaCalloutService.AppReqGraduationApplication app) {
        if (app.awardDetails != null) {
            app.awardDetails.awardCode1 = app.awardDetails.awardCode1 ?? '';
            app.awardDetails.awardCourseCode1 = app.awardDetails.awardCourseCode1 ?? '';
            app.awardDetails.awardTitle1 = app.awardDetails.awardTitle1 ?? '';
            app.awardDetails.awardCode2 = app.awardDetails.awardCode2 ?? '';
            app.awardDetails.awardCourseCode2 = app.awardDetails.awardCourseCode2 ?? '';
            app.awardDetails.awardTitle2 = app.awardDetails.awardTitle2 ?? '';
        }

        app.graduationName = app.graduationName ?? '';
        app.alternateEmailAddr = app.alternateEmailAddr ?? '';
        app.receiptNumber = app.receiptNumber ?? '';
        app.graduandType = app.graduandType ?? '';
        app.specialRequirement = app.specialRequirement ?? '';
        app.comment = app.comment ?? '';
        app.alternateExitCourseTitle = app.alternateExitCourseTitle ?? '';

        app.nameChangedStatus = app.nameChangedStatus ?? '';
    }

    public static String processAwards(Set<Id> awardIds) {
        return processAwards(awardIds, false);
    }

    /**
     * @description Complete write-back and update records as required. As this is primarily for async contexts,
     *              errors are primarily just logged
     * @param awardIds
     * @param force    If true, do write-back regardless of Settings & Callista_Writeback_Requested_Time__c
     * @return         the last error encountered or null if every award was successful
     */
    public static String processAwards(Set<Id> awardIds, Boolean force) {
        Datetime recordRetrieveTime = Datetime.now();
        Graduation_Award__c[] awardsToProcess = new Graduation_Award__c[0];
        Nebula.Logger.setScenario('Grads Callista Sync');

        if (!force && GradsUtils.getSyncConfig().asyncProcessEnabled != true) {
            return 'Callista Sync is disabled';
        }

        for (Graduation_Award__c award : retrieveAwards(awardIds)) {
            if(!force) {
                if (award.Callista_Writeback_Requested_Time__c == null) {
                    // Skip if write-back request has been cleared
                    continue;
                }
                if (award.Last_Callista_Writeback_Success_Time__c > award.Callista_Writeback_Requested_Time__c) {
                    // Skip if the Award has had write-back since last requested
                    continue;
                }
            }
            awardsToProcess.add(award);
        }

        Graduation_Award__c[] awardsForUpdate = new Graduation_Award__c[0];
        Set<Id> awardIdsForDocCallout = new Set<Id>();
        String errorMessage = null;

        for (Graduation_Award__c award : awardsToProcess) {

            // Create a new instance of the award to avoid overwriting other values
            Graduation_Award__c updatedAward = new Graduation_Award__c(
                Id = award.Id,
                Writeback_Apex_Job_Id__c = null,
                Bypass_Writeback_Trigger__c = false,
                Last_Callista_Writeback_Status_Time__c = Datetime.now(),
                Last_Callista_Writeback_Status__c = 'Failed' // Default to failed
            );
            awardsForUpdate.add(updatedAward);

            // Create and submit request
            GradsCallistaCalloutService.ApplicationCalloutResult cr;
            try {
                cr = submitAwardRequest(award);
                cr.logToNebula();
            } catch (Exception e) {
                errorMessage = 'Failed to create or submit request for Callista Sync';
                Nebula.Logger.error(errorMessage).setExceptionDetails(e).setRecord(award);
                continue;
            }

            if (cr.success) {
                updatedAward.Last_Callista_Writeback_Status__c = 'Success';
                updatedAward.Writeback_Retry_Attempt__c = 0;
                updatedAward.Last_Callista_Writeback_Success_Time__c = recordRetrieveTime;
                updatedAward.Last_Callista_Writeback_Payload__c = cr.request.getBody();
                Boolean newTransNo = String.isNotBlank(cr.transactionNo) && award.Callista_Transaction_Number__c != cr.transactionNo;
                updatedAward.Callista_Transaction_Number__c = cr.transactionNo;
                if(award.Cancellation_Date__c != null) {
                    updatedAward.Cancellation_Succeeded__c = true;
                } else if (newTransNo) {
                    updatedAward.Cancellation_Succeeded__c = false; // Reset on new transaction number
                }
                if (award.Graduation_Application__r.Document_Writeback_Pending__c) {
                    awardIdsForDocCallout.add(award.Id);
                }
            } else {
                updatedAward.Last_Callista_Writeback_Error__c = cr.errorMessage;
                errorMessage = 'Write-back failed: ' + cr.errorMessage;
            }
        }

        if (awardIdsForDocCallout.size() > 0) {
            if(System.isQueueable()) {
                // Can make 50 future calls from Queueable context (but 0 from batch context)
                for(Id awardId : awardIdsForDocCallout) {
                    documentFutureSync(awardId);
                }
            } else {
                // Can make 1 Queueable call from all async contexts
                System.enqueueJob(new DocumentQueueableSync(awardIdsForDocCallout));
            }
        }

        // Update awards and log any DML errors
        Database.SaveResult[] saveResults = Database.update(awardsForUpdate, false);
        Database.SaveResult[] errorResults = new Database.SaveResult[0];
        for (Database.SaveResult sr : saveResults) {
            if (!sr.isSuccess()) {
                errorResults.add(sr);
            }
        }
        if (errorResults.size() > 0) {
            Nebula.Logger.error('Failed to update awards after Callout').setDatabaseResult(errorResults);
        }

        Nebula.Logger.saveLog();
        return errorMessage;
    }

    /**
     * @description Creates and submits a Callista request for a single award without any side effects
     */
    public static GradsCallistaCalloutService.ApplicationCalloutResult submitAwardRequest(Graduation_Award__c award) {
        GradsCallistaCalloutService.AppReqBody rb = createReq(award);

        // Submit the request and return the result
        return GradsCallistaCalloutService.submitApplication(
            rb, award.Graduation_Application__r.Student__r.Person_ID__c, award.Id
        );
    }

    /**
     * Application write-back wrapped in a @AuraEnabled method
     * Returns the error encountered or null if successful
     */
    @AuraEnabled
    public static String syncNow(Id awardId) {
        if(awardId == null || awardId.getSobjectType() != Graduation_Award__c.SObjectType) {
            throw new IllegalArgumentException('Invalid Award Id');
        }

        return processAwards(new Set<Id>{awardId}, true);
    }

    /**
     * Application write-back wrapped in a Queueable
     */
    public class QueueableSync implements Queueable, Database.AllowsCallouts {

        private final Set<Id> awardIds;

        public QueueableSync(Set<Id> awardIds) {
            this.awardIds = awardIds;
        }

        public void execute(QueueableContext context) {
            Nebula.Logger.setAsyncContext(context);
            processAwards(awardIds);
        }
    }

    /**
     * Retrieve the latest document for the given applications
     */
    public static Map<Id, ContentVersion> retrieveDocs(Set<Id> applicationIds) {
        Map<Id, ContentVersion> docsByAppId = new Map<Id, ContentVersion>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionData,
                LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :applicationIds
            AND ContentDocument.LatestPublishedVersion.File_Category__c = 'Graduation Portal - External User Generated'
            ORDER BY ContentDocument.CreatedDate ASC
        ]) {
            docsByAppId.put(cdl.LinkedEntityId, cdl.ContentDocument.LatestPublishedVersion);
        }
        return docsByAppId;
    }

    /**
     * Retrieve a single document for the given application
     */
    public static ContentVersion retrieveDoc(Id applicationId) {
        return retrieveDocs(new Set<Id>{applicationId}).get(applicationId);
    }

    /**
     * Document write-back wrapped in a @Future method
     */
    @Future(Callout=true)
    public static void documentFutureSync(Id awardId) {
        new DocumentQueueableSync(new Set<Id>{awardId}).execute(null);
    }

    /**
     * Document write-back Queueable
     */
    public class DocumentQueueableSync implements Queueable, Database.AllowsCallouts {

        private final Set<Id> nextAwardIds;
        private final Id awardId;

        public DocumentQueueableSync(Set<Id> awardIds) {
            // Grab one of the awardIds to process
            this.awardId = awardIds.iterator().next();
            // Remove the processed awardId from the set passed to the next job
            awardIds.remove(awardId);
            nextAwardIds = awardIds;
        }

        public void execute(QueueableContext context) {
            Nebula.Logger.setAsyncContext(context);
            Graduation_Award__c award = retrieveAwards(new Set<Id>{
                awardId
            })[0];
            ContentVersion cv = retrieveDoc(award.Graduation_Application__r.Id);

            GradsCallistaCalloutService.DocumentCalloutResult dcr = GradsCallistaCalloutService.submitDocument(
                award.Graduation_Application__r.Student__r.Person_ID__c,
                award.Callista_Transaction_Number__c,
                award.Document_Callista_Id__c,
                cv
            );

            dcr.awardId = award.Id;
            dcr.logToNebula();
            Nebula.Logger.saveLog();

            if (dcr.success) {
                update new Graduation_Application__c(
                    Id = award.Graduation_Application__r.Id,
                    Document_Writeback_Pending__c = false
                );
                update new Graduation_Award__c(
                    Id = award.Id,
                    Document_Callista_Id__c = dcr.documentId
                );
            }

            // Process remaining requests via chaining
            if (nextAwardIds.size() > 0) {
                System.enqueueJob(new DocumentQueueableSync(nextAwardIds));
            }
        }
    }

}