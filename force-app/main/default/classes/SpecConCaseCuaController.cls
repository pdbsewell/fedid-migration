/**
 * @description Controller for specConChildCUA LWC component.
 * @group       SpecCon
 * @author      tom.gangemi@monash.edu
 * @revision    2025-02-10 - Initial version
 */
public class SpecConCaseCuaController {

    public class QuizAttemptInfo {
        @AuraEnabled public Integer attemptsTaken;
        @AuraEnabled public Integer attemptsAllowedOverride;
        @AuraEnabled public QuizAttempt[] quizAttempts;
    }

    public class QuizAttempt {
        @AuraEnabled public Datetime timeStart;
        @AuraEnabled public String timeStartFormatted;
        @AuraEnabled public Long durationSeconds;
        @AuraEnabled public Integer attemptNum;
    }

    /**
     * Convenience/Aura method for getQuizAttemptInfo(Case_Unit_Attempt__c)
     */
    @AuraEnabled
    public static QuizAttemptInfo getQuizAttemptInfo(Id cuaId) {
        return getQuizAttemptInfo(getCua(cuaId));

    }

    /**
     * Retrieves data from quiz attempts API
     * @param cuaId - Case_Unit_Attempt__c Id
     * @return QuizAttemptInfo
     */
    public static QuizAttemptInfo getQuizAttemptInfo(Case_Unit_Attempt__c cua) {
        final String studentId = cua.Unit_Attempt__r.Person_ID__c;
        final String quizId = cua.Moodle_Assessment_ID__c;

        SpecConMoodleCalloutService.QuizAttemptsResult qar = SpecConMoodleCalloutService.getQuizAttempts(studentId, quizId);
        qar.cuaId = cua.Id; // set this so log entry can be related to CUA
        handleCalloutError(qar);

        QuizAttemptInfo res = new QuizAttemptInfo();
        res.quizAttempts = new QuizAttempt[0];
        Set<String> countableStatuses = new Set<String>{'inprogress', 'submitted', 'finished', 'abandoned'};

        res.attemptsAllowedOverride = qar.quizAttempts.noOfAllowableUserOverriddenAttempts;
        // Count all attempts with one of the above status
        res.attemptsTaken = 0;
        for(SpecConMoodleCalloutService.QuizAttempt a :qar.quizAttempts.attempts) {
            if(a.status != null && countableStatuses.contains(a.status.toLowerCase())) {
                res.attemptsTaken += 1;
                QuizAttempt quizAttempt = new QuizAttempt();
                quizAttempt.timeStart = a.timeStart;
                quizAttempt.timeStartFormatted = a.timeStart.format();
                quizAttempt.durationSeconds = a.timeFinish != null ? a.timeFinish.getTime() - a.timeStart.getTime() : null;
                quizAttempt.attemptNum = a.attempt;
                res.quizAttempts.add(quizAttempt);
            }
        }

        return res;
    }

    /**
     * Convenience/Aura method for getQuizAllowableAttempts(Case_Unit_Attempt__c)
     */
    @AuraEnabled
    public static Integer getQuizAllowableAttempts(Id cuaId) {
        return getQuizAllowableAttempts(getCua(cuaId));
    }

    /**
     * Retrieves data from the assessments API
     */
    public static Integer getQuizAllowableAttempts(Case_Unit_Attempt__c cua) {
        final String studentId = cua.Unit_Attempt__r.Person_ID__c;
        final String unitOfferingId = cua.Unit_Attempt__r.Unit_Offering__r.UOO_ID__c;
        final String quizId = cua.Moodle_Assessment_ID__c;

        SpecConMoodleCalloutService.AssessmentsResults ar = SpecConMoodleCalloutService.getAssessments(studentId, unitOfferingId);
        handleCalloutError(ar);

        for(SpecConMoodleCalloutService.Assessment a :ar.assessments) {
            if(a.id == quizId) {
                return a.numberOfAllowedAttempts;
            }
        }
        return null;
    }

    /**
     * @param cuaId - Case_Unit_Attempt__c Id
     * @param attempts - New Number of attempts allowed
     * @description Updates the number of attempts allowed for a quiz
     * @return void (successful unless an exception is thrown)
     */
    @AuraEnabled
    public static void updateAttemptsAllowed(Id cuaId, Integer attempts) {
        Case_Unit_Attempt__c cua = getCua(cuaId);

        // default to today + 2 days
        cua.Assessment_Due_Date_New__c = cua.Assessment_Due_Date_New__c ?? Date.today().addDays(2);

        SpecConMoodleCalloutService.QuizExtensionResult qer = SpecConMoodleCalloutService.postQuizExtension(
            cua.Unit_Attempt__r.Person_ID__c,
            cua.Moodle_Assessment_ID__c,
            attempts,
            cua.Assessment_Due_Date_New__c,
            cua.Unit_Attempt__r.Location__c
        );
        handleCalloutError(qer);

        if(qer.success) {
            insert UpdateMoodleCC.createCaseComment(cua);
            cua.Moodle_Integration_Status__c = Label.Moodle_Integration_Status_Success;
        } else {
            cua.Moodle_Integration_Status__c = ('Failed - Logged');
        }

        update cua;
    }

    public static Case_Unit_Attempt__c getCua(Id cuaId) {
        return [
            SELECT Name, Assessment_Due_Date_New__c, Assessment_Due_Date_Original__c, Enquiry__c,
                Moodle_Assessment_ID__c, Assessment_Attempts_Allowable__c, Assessment_Attempts_Taken__c,
                Unit_Attempt__r.Location__c, Unit_Attempt__r.Unit_Offering__r.UOO_ID__c,
                Unit_Attempt__r.Person_ID__c
            FROM Case_Unit_Attempt__c WHERE Id = :cuaId
        ];
    }

    /**
     * Handles callout errors (throws exception if any error present)
     * @param res - CalloutResult
     */
    public static void handleCalloutError(SpecConMoodleCalloutService.CalloutResult res) {
        if(res.success) {
            return;
        }
        res.logToNebula();
        Nebula.Logger.saveLog();
        if(res.ex != null) {
            throw res.ex;
        } else {
            String errorMessage = 'MIX Error: ' + res.errorMessage;
            AuraHandledException ex = new AuraHandledException(errorMessage);
            ex.setMessage(errorMessage);
            throw ex;
        }
    }
}