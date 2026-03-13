/**
 * @description Flow invocable method to get quiz attempts for a CUA
 * @group       SpecCon
 * @author      tom.gangemi@monash.edu
 * @revision    2025-02-10 - Initial version
 */
public without sharing class SpecConFlowGetAttempts {

    public class QuizAttemptInfo {
        @InvocableVariable public Integer attemptsTaken;
        @InvocableVariable public Integer attemptsAllowed;
        @InvocableVariable public Boolean moodleUnreachable;
    }

    /**
     * Flow invocable method to get quiz attempts for a CUA
     */
    @InvocableMethod(Label='Moodle - Get Quiz Attempts' Description='Returns number of quiz attempts for a CUA')
    public static List<QuizAttemptInfo> getQuizAttemptInfo(List<Id> cuaIds) {
        List<QuizAttemptInfo> res = new List<QuizAttemptInfo>();
        for(Id cuaId :cuaIds) {
            Case_Unit_Attempt__c cua = SpecConCaseCuaController.getCua(cuaId);
            QuizAttemptInfo qaiRes = new QuizAttemptInfo();
            try {
                SpecConCaseCuaController.QuizAttemptInfo qai = SpecConCaseCuaController.getQuizAttemptInfo(cua);
                qaiRes.attemptsTaken = qai.attemptsTaken;
                if(qai.attemptsAllowedOverride != null) {
                    qaiRes.attemptsAllowed = qai.attemptsAllowedOverride;
                } else {
                    qaiRes.attemptsAllowed = SpecConCaseCuaController.getQuizAllowableAttempts(cua);
                }
                qaiRes.moodleUnreachable = false;
            } catch (Exception e) {
                qaiRes.moodleUnreachable = true;
                qaiRes.attemptsTaken = Integer.valueOf(cua.Assessment_Attempts_Taken__c);
                qaiRes.attemptsAllowed = Integer.valueOf(cua.Assessment_Attempts_Allowable__c);
            }
            res.add(qaiRes);
        }
        return res;
    }
}