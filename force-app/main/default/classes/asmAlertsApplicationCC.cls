/*******************************************************************************
* @author       Victor Cheng
* @date         2018
* @description
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
* @revision     Shalini Mendu - 28/2/2019 Fix for SFTDC-255
* @revision     Trent De Laney - 15/04/2019 Fix for SF-2620, Under 18 Evaluation logic
*******************************************************************************/
public with sharing class asmAlertsApplicationCC {

    public static String MESSAGE = 'message';

    public static String CONTACT_ID = 'contactId';
    public static String IS_UNDER18_AT_APPLICATION = 'isUnder18AtApplication';
    public static String HAS_ENCUMBRANCES = 'hasEncumbrances';
    public static String APPLICATION_FEE_PAID = 'applicationFeePaid';
    public static String APPLICATION_FEE_AMT = 'applicationFeeAmt';
    public static String HAS_ACCESS_EQUITY = 'hasAccessEquity';
    public static String GTE_ALERT_SUBMISSION_LOCATION = 'gteAlertSubmissionLocation';
    public static String GTE_ALERT_QUALIFICATION = 'gteAlertQualification';
    public static String CREDIT_INTENTION = 'creditIntention';
    public static String TASK_QUALIFICATION = 'taskQualification';
    public static String TASK_VISA = 'taskVisa';
    public static String ADM_KEY = 'admkey';
    //public static String HAS_CITIZENSHIP_ALERT = 'hasCitizenshipAlert';

    @AuraEnabled
    public static Map<String, Object> GetApplicationAlerts(Id applicationId)
    {

        Map<String, Object> mapAlerts = new Map<String, Object>();

        if(applicationId == NULL)
        {
            ExLog.add('asmAlertsApplicationCC', 'N/A', 'GetApplicationAlerts', 'Application ID is null');
            mapAlerts.put(MESSAGE, 'Error:Application Id is null');
        }
        else
        {
            List<Application__c> listApplications = [SELECT id
                    , Applicant__c
                    , Fee_Payment__c
                    , Fee_Amount__c
                    , Credit_Intention__c
                    , Submitted_Date__c
                    , Access_and_Equity_Question__c
                    , Task_Qualification__c
                    , Task_Visa__c                                
            FROM Application__c
            WHERE id =: applicationId LIMIT 1];
            if(listApplications.size() != 1)
            {
                ExLog.add('asmAlertsApplicationCC', 'N/A', 'GetApplicationAlerts', 'Could not find Assessment Plan with Id ' + applicationId);
                mapAlerts.put(MESSAGE, 'Error:Application Id invalid');
            }
            else
            {
                // all good, continue
                Application__c application = listApplications[0];

                // application Id for debugging, house keeping
                //mapAlerts.put(APPLICATION_ID, appId);

                // under 18
                mapAlerts.put(IS_UNDER18_AT_APPLICATION, IsAppUnder18AtApplication(application));
                // encumbrances
                mapAlerts.put(HAS_ENCUMBRANCES, HasAnyEncumbrance(application.Applicant__c));

                // fee payment
                mapAlerts.put(APPLICATION_FEE_PAID, application.Fee_Payment__c);

                // fee amt - Fix for SFTDC-255
                mapAlerts.put(APPLICATION_FEE_AMT, application.Fee_Amount__c);

                // access equity
                if(application.Access_and_Equity_Question__c == 'Yes')
                    mapAlerts.put(HAS_ACCESS_EQUITY, true);

                // GTE
                Map<Id, Application_Course_Preference__c> acps = new Map<ID, Application_Course_Preference__c>([SELECT Id, Callista_Unique_Key_ADM__c
                                                                                                                FROM Application_Course_Preference__c
                                                                                                                Where Application__c =: applicationId]);

                //ADM Key on ACP
                for(Application_Course_Preference__c acp : acps.values()){
                    if(String.isBlank(acp.Callista_Unique_Key_ADM__c)){
                        mapAlerts.put(ADM_KEY, true);
                    }
                }

                for(assessmentsDSSandGTECheck.DSSandGTECheckResponse res : assessmentsDSSandGTECheck.DSSandGTECheck(new List<Id>(acps.keySet()))){
                    if(res.GTEcountry) 
                        mapAlerts.put(GTE_ALERT_SUBMISSION_LOCATION, res.GTEcountry);
                    if(res.GTEQual)
                        mapAlerts.put(GTE_ALERT_QUALIFICATION, res.GTEQual);
                }

                // Credit Intent
                mapAlerts.put(CREDIT_INTENTION, application.Credit_Intention__c);
                
                //TASK QUALIFICATION
                if(application.Task_Qualification__c == 'Required' || application.Task_Qualification__c == 'In Progress' || application.Task_Qualification__c == 'Waiting for docs' || application.Task_Qualification__c == 'Failed')
                    mapAlerts.put(TASK_QUALIFICATION, true);

                //TASK VISA
                if(application.Task_Visa__c == 'Required' || application.Task_Visa__c == 'In Progress' || application.Task_Visa__c == 'Waiting for docs' || application.Task_Visa__c == 'Failed')
                    mapAlerts.put(TASK_VISA, true);

                mapAlerts.put(MESSAGE, 'Alerts for application:' + applicationId);
            }
        }

        return mapAlerts;
    }

    public static Boolean IsAppUnder18AtApplication(Application__c application)
    {
        Boolean isUnder18 = false;
        List<Contact> listCons = [Select c.id, c.Birthdate From Contact c where c.id = :application.Applicant__c];

        if(listCons.size() == 1)
        {
            Contact conApplicant = listCons[0];
            if(conApplicant.Birthdate != null && application.Submitted_Date__c != null)
            {
                //SF-2620 - Updated calculation logic
                Decimal ageAtApplication = conApplicant.Birthdate.daysBetween(application.Submitted_Date__c)/365.2425;
                if(ageAtApplication < MyApplicationUtilities.AGE_18)
                {
                    isUnder18 = true;
                }
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