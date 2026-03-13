/**
 * @description Flow invocable method to set quiz attempts for a CUA
 * @group       SpecCon
 * @author      tom.gangemi@monash.edu
 * @revision    2025-02-10 - Initial version
 */
public without sharing class SpecConFlowSetAttempts {

    // new values to write to moodle
    public class QuizAttemptInfo {
        @InvocableVariable public Id cuaId;
        @InvocableVariable public Integer numberOfAttemptsAllowable;
        @InvocableVariable public Date extensionDate;
    }

    /**
     * Flow invocable method to set quiz attempts for a CUA
     * @param infos - List of QuizAttemptInfo
     * @return List of strings, one for each QuizAttemptInfo (null if success, error message if failed)
     */
    @InvocableMethod(Label='Moodle - Set Quiz Attempts' Description='Grant quiz extension in moodle')
    public static List<String> setQuizExtension(List<QuizAttemptInfo> infos) {
        String[] results = new String[0];
        for(QuizAttemptInfo qai :infos) {
            Case_Unit_Attempt__c cua = SpecConCaseCuaController.getCua(qai.cuaId);
            try {
                SpecConCaseCuaController.updateAttemptsAllowed(cua.Id, qai.numberOfAttemptsAllowable);
                results.add(null); // success
            } catch (Exception e) {
                Nebula.Logger.error('Failed to update moodle quiz', e);
                results.add('Failed to update moodle');
            }
        }
        Nebula.Logger.saveLog();
        return results;
    }
}