/*
 * @author       Victor Cheng
 * @date         2018
 * @description  
 * @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
 * @revision     Shalini Mendu - 28/2/2019 Fix for SFTDC-255
 *               Martin Cadman - Removed user query that was not utilised and generated errors
*/
public with sharing class asmAlertsACPCC {

    public static String MESSAGE = 'message';

    public static String APPLICATION_ID = 'applicationId';
    public static String CONTACT_ID = 'contactId';
    public static String IS_UNDER18_AT_APPLICATION = 'isUnder18AtApplication';
    public static String AGE_AT_COURSE_START = 'ageAtCourseStart';    
    public static String HAS_ENCUMBRANCES = 'hasEncumbrances';
    public static String APPLICATION_FEE_PAID = 'applicationFeePaid';
    public static String APPLICATION_FEE_AMOUNT = 'applicationFeeAmt';
    public static String HAS_ACCESS_EQUITY = 'hasAccessEquity';
    public static String GTE_ALERT_SUBMISSION_LOCATION = 'gteAlertSubmissionLocation';
    public static String GTE_ALERT_QUALIFICATION = 'gteAlertQualification';
    public static String CREDIT_INTENTION = 'creditIntention';
    public static String TASK_QUALIFICATION = 'taskQualification';
    public static String TASK_VISA = 'taskVisa';
    public static String MANUAL_ASSESSMENT_OVERRIDE = 'manualAssessmentOverride';
    public static String READMIT = 'readmit';
    public static String ADM_KEY = 'admkey';

    @AuraEnabled
    public static Map<String, Object> GetACPAlerts(Id acpId)
    {

        Map<String, Object> mapAlerts = new Map<String, Object>();

        if(acpId == NULL)
        {
            ExLog.add('asmAlertsACPCC', 'N/A', 'GetACPAlerts', 'ACP ID is null');
            mapAlerts.put(MESSAGE, 'Error:ACP Id is null');
        }
        else
        {
            List<Application_Course_Preference__c > listACPs = [SELECT id
                    , Application__c
                    , Applicant__c
                    , Course_Start_Date__c
                    , Admissions_Process_Type__c
                    , Callista_Unique_Key_ADM__c
            FROM Application_Course_Preference__c
            WHERE id =: acpId LIMIT 1];
            if(listACPs.size() != 1)
            {
                ExLog.add('asmAlertsACPCC', 'N/A', 'GetACPAlerts', 'Could not find ACP with Id ' + acpId);
                mapAlerts.put(MESSAGE, 'Error:ACP Id invalid');
            }
            else
            {
                // all good, continue
                Application_Course_Preference__c acp = listACPs[0];
                
                System.Debug('asmAlertsACP: ACP.application = ' + acp.Application__c);

                
                Id appId = acp.Application__c;                
                // application Id for debugging, house keeping
                mapAlerts.put(APPLICATION_ID, appId);
                
                Id contactId = acp.Applicant__c;
                mapAlerts.put(CONTACT_ID, contactId);

                if(listACPs[0].Admissions_Process_Type__c == 'RE-ADMIT'){
                    mapAlerts.put(READMIT, true);
                }

                if(String.isBlank(listACPs[0].Callista_Unique_Key_ADM__c)){
                    mapAlerts.put(ADM_KEY, true);
                }

                List<Application__c> listApplications = [SELECT id
                                                     , Applicant__c
                                                     , Fee_Payment__c     
                                                     , Credit_Intention__c
                                                     , HasDisabilities__c
                                                     , Submitted_Date__c
                                                     , Fee_Amount__c
                                                     , Task_Qualification__c
                                                     , Manual_Assessment_Override__c
                                                     , Task_Visa__c   
                                                     //, Access_and_Equity_Question__c
                                                     FROM Application__c
                                                     WHERE id =: appId LIMIT 1];
                if(listApplications.size() != 1)
                {
                    ExLog.add('asmAlertsACPCC', 'N/A', 'GetACPAlerts', 'Could not find Application with Id ' + appId);
                    mapAlerts.put(MESSAGE, 'Error:Application Id invalid');
                }
                else
                {          
                    Application__c application = listApplications[0];
                        
                    // encumbrances
                    mapAlerts.put(HAS_ENCUMBRANCES, HasAnyEncumbrance(contactId));
    
                    // application fee                    
	                mapAlerts.put(APPLICATION_FEE_PAID, application.Fee_Payment__c);

                    // fee amount - Fix for SFTDC-255
                    mapAlerts.put(APPLICATION_FEE_AMOUNT, application.Fee_Amount__c);

                    // GTE
                    for(assessmentsDSSandGTECheck.DSSandGTECheckResponse res : assessmentsDSSandGTECheck.DSSandGTECheck(new List<Id>{acpId})){
                        if(res.GTEcountry) 
                            mapAlerts.put(GTE_ALERT_SUBMISSION_LOCATION, res.GTEcountry);
                        if(res.GTEQual)
                            mapAlerts.put(GTE_ALERT_QUALIFICATION, res.GTEQual);
                    }
                    
                    // get contact for age calculations
                    List<Contact> listApplicants= [Select c.id, c.Birthdate From Contact c where c.id = :contactId];
        			if (listApplicants.size() == 1) {
                        Contact applicant = listApplicants[0];
                    
                        // under 18 at application
                        mapAlerts.put(IS_UNDER18_AT_APPLICATION, IsAppUnder18AtApplication(applicant.Birthdate, application.Submitted_Date__c));
                        mapAlerts.put(AGE_AT_COURSE_START, AgeAtCourseStart(applicant.Birthdate, acp.Course_Start_Date__c));
                    }
    
                    // Credit Application
                    mapAlerts.put(CREDIT_INTENTION, application.Credit_Intention__c);
                    
                    //TASK QUALIFICATION
                    if(application.Task_Qualification__c == 'Required' || application.Task_Qualification__c == 'In Progress' || application.Task_Qualification__c == 'Waiting for docs' || application.Task_Qualification__c == 'Failed')
                    mapAlerts.put(TASK_QUALIFICATION, true);

                    //TASK VISA
                    if(application.Task_Visa__c == 'Required' || application.Task_Visa__c == 'In Progress' || application.Task_Visa__c == 'Waiting for docs' || application.Task_Visa__c == 'Failed')
                    mapAlerts.put(TASK_VISA, true);

                    // Show alert in ACP record page when Manual Assessment Override (Application__c.Manual_Assessment_Override__c) field is equals to true
                    if (application.Manual_Assessment_Override__c == true)
                        mapAlerts.put(MANUAL_ASSESSMENT_OVERRIDE, true);
    
                    mapAlerts.put(MESSAGE, 'Alerts for ACP:' + acpId + ', application:' + appId +', start date:' + acp.Course_Start_Date__c);
                }               
            }
        }

        return mapAlerts;
    }


    public static Integer AgeAtCourseStart(Date birthDate, Date startDate)
    {
        if(startDate != null && birthDate != null)
        {
            Integer ageAtCourseStart = (birthDate.daysBetween(startDate)/365.2425).intValue();
            System.debug('!@#AgeAtCourseStart:: Age At Course Start ' + ageAtCourseStart);
            return ageAtCourseStart;
        }
        return -1;
    }
    
    public static Boolean IsAppUnder18AtApplication(Date birthDate, Date submittedDate)
    {
        Boolean isUnder18 = false;
        if(birthDate != null && submittedDate != null)
        {
            Decimal ageAtApplication = birthdate.daysBetween(submittedDate)/365.2425;
            System.debug('!@#$asmAlertsACPCC:: Age At Submission ' + ageAtApplication);
            if(ageAtApplication < MyApplicationUtilities.AGE_18)
            {
                isUnder18 = true;
            }
        }
        return isUnder18;   
    }

    private static Boolean HasAnyEncumbrance(Id contactId)
    {
        List<Encumbrance__c> listEncs = MyApplicationUtilities.getEncumbrancesByContact(contactId);
        if(listEncs.size() > 0)
            return true;
        return false;
    }
}