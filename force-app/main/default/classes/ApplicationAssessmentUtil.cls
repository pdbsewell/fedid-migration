/**
 * @description Handles any common functions for Application Assessment
 *              Orchestrator / Required Admin Tasks / Process flows
 */
public class ApplicationAssessmentUtil {

    /**
     * 
     * @description Method to identify if the applicant is DOMESTIC or INTERNATIONAL
     * @param applicationId
     *
     * @return String ('DOMESTIC' or 'INTERNATIONAL')
     */
    public static String getCitizenshipType(String applicationId) {
        String result = 'ERROR';
        try {
            List<Application__c> applications = [SELECT Id, Residency_Status__c FROM Application__c WHERE Id =: applicationId];

            result = ApplicationAssessmentUtil.getCitizenshipType(applications.get(0));

        } catch (Exception ex) {
            ExLog.add('ApplicationAssessmentUtil', 'Application__c', 'getCitizenshipType', ex.getMessage());
        }
        return result;
    }

    /**
     * 
     * @description Method to identify if the applicant is DOMESTIC or INTERNATIONAL
     * @param applicationRecord
     *
     * @return String ('DOMESTIC' or 'INTERNATIONAL')
     */
    public static String getCitizenshipType(Application__c applicationRecord) {
        Set<String> domesticResidencyStatus = new Set<String>{'DOM-AUS','DOM-HV','DOM-NZ','DOM-PR'};
        String result = 'ERROR';
        try {
            String residencyStatus = applicationRecord.Residency_Status__c;

            if (String.isNotBlank(residencyStatus) && domesticResidencyStatus.contains(residencyStatus)) {
                return 'DOMESTIC';
            } else {
                return 'INTERNATIONAL';
            }
        } catch (Exception ex) {
            ExLog.add('ApplicationAssessmentUtil', 'Application__c', 'getCitizenshipType', ex.getMessage());
        }
        return result;
    }
}