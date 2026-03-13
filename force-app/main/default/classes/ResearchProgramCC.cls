/*******************************************************************************
* @author       Davey Yu
* @date         29.August.2024    
* @description  Controller for myGRResearchProgram component
* @revision     Stefan Scheit (2024-08-29): Initial Creation
*******************************************************************************/
public with sharing class ResearchProgramCC {
    /*******************************************************************************
    * @author       Davey Yu
    * @date         29.August.2024
    * @description  Retrieve the Admission Application Course Preference Research Program
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Map<String, Object> retrieveApplicationCoursePreference(String appId) {
        if (ExperienceAuthenticationServices.isUnsafe(appId)){ 
            return null;
        }
        Map<String, Object> data = new Map<String, Object>();

        List<Application_Course_Preference__c> applicationCoursePreferenceList = [SELECT Id, Research_Supervisors__c, Research_Title__c, Research_Summary__c,
                                                                                    External_Supervisor__c, External_Funding__c, External_Funding_Type__c, External_Funding_Name__c, External_Fund_Duration_Value__c, Surrender_External_Fund__c, 
                                                                                    Applied_for_External_Scholarship__c, Employment_During_Research__c, Employer_and_Position__c, Employment_Load__c, Attendance_Type__c,
                                                                                    Employment_Days__c, Employment_Hours__c, Applied_for_External_Scholarship_Name__c, Research_Days__c, Graduate_Research_Application_Type__c
                                                                                    FROM 	Application_Course_Preference__c  
                                                                                    WHERE 	Application__c =: appId LIMIT 1];

        if (!applicationCoursePreferenceList.isEmpty()) {
            data.put('acp', applicationCoursePreferenceList[0]);
        }

        //return surrender external funding options
        List<Map<String,String>> options = new List<Map<String, String>>();

        Map<String, String> blankOption = MyApplicationUtilities.getPicklistOptionsMap('Surrender_External_Fund__c', 'Application_Course_Preference__c');

        for(String key : blankOption.keySet())
        {
            Map<String, String> mapOption = new Map<String, String>();
            mapOption.put('value', blankOption.get(key));
            mapOption.put('label', key);
            options.add(mapOption);
        }

        data.put('surrender_scholarship', options);
        
        //will return new application if application Id is not found
        return data;
    }
    
    /*******************************************************************************
    * @author       Davey Yu
    * @date         29.AUG.2024
    * @description  Update the Admission Application Course Preference Research Program
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Application_Course_Preference__c updateApplicationCoursePreference(Application_Course_Preference__c acp, String supervisor, 
        String title, String summary, Boolean externalSupervisor, Boolean externalFunding, String externalFundingType, String externalFundingName,
        String externalDuration, Boolean appliedForExternalScholarshipCheck, String externalScholarshipName,
        Boolean employmentDuringResearchCheck, String employmentPosition, String employmentLoad, List<String> employmentDays, String employmentHours,
        String researchDays, String surrenderFund){
        try {   
            if (ExperienceAuthenticationServices.isUnsafe(acp)) return acp;


            Application_Course_Preference__c appCourse = [SELECT Id, Research_Supervisors__c, Research_Title__c, Research_Summary__c,
            External_Supervisor__c, External_Funding__c, External_Funding_Type__c, External_Funding_Name__c, External_Fund_Duration_Value__c, Surrender_External_Fund__c, 
            Applied_for_External_Scholarship__c, Employment_During_Research__c, Employer_and_Position__c, Employment_Load__c, Application__c,
            Employment_Days__c, Employment_Hours__c, Applied_for_External_Scholarship_Name__c, Research_Days__c, Graduate_Research_Application_Type__c
            FROM 	Application_Course_Preference__c  
            WHERE 	Id =: acp.id LIMIT 1];

            //authentication for the applicant
            Application__c app = [SELECT Applicant__c FROM Application__c WHERE Id=:appCourse.Application__c AND Status__c = 'Draft'];
            if(!isRecordOwnedByTheUser(app)) {
                throw new AuraHandledException('Invalid application');
            }
            
            appCourse.Research_Supervisors__c = supervisor;
            appCourse.Research_Title__c = title;
            appCourse.Research_Summary__c = summary;
            appCourse.External_Supervisor__c = externalSupervisor;
            appCourse.External_Funding__c = externalFunding;
            appCourse.External_Funding_Type__c = externalFundingType;
            appCourse.External_Funding_Name__c = externalFundingName;
            appCourse.External_Fund_Duration_Value__c = externalDuration;
            appCourse.Applied_for_External_Scholarship__c = appliedForExternalScholarshipCheck;
            appCourse.Applied_for_External_Scholarship_Name__c = externalScholarshipName;
            appCourse.Employment_During_Research__c = employmentDuringResearchCheck;
            appCourse.Employer_and_Position__c = employmentPosition;
            appCourse.Surrender_External_Fund__c = surrenderFund;
            appCourse.Employment_Load__c = employmentLoad;

            if(employmentLoad == 'Full-Time'){
                appCourse.Employment_Hours__c = null;            
            }

            if(employmentLoad == 'Part-Time/Casual'){
                if(!String.isEmpty(employmentHours)){
                    appCourse.Employment_Hours__c = double.valueOf(employmentHours);
                }
            if(employmentDays != null){
                appCourse.Employment_Days__c = String.join(employmentDays, ';');
            }
            
            }
            appCourse.Research_Days__c = researchDays;

            List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
            acpList.add(appCourse);
            update acpList;
            return acpList[0];
            
        } catch (Exception e) {
            Nebula.Logger.error('Update Application Course Preference', e);
            Nebula.Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    /**
     * @author      Vishal Gupta
     * @description method to check if the application is related to the logged in user
     * @revision    2/7/2025 - Initial Version
    */
    private static boolean isRecordOwnedByTheUser(Application__c app){
        MyAppApplicationAuthenticator checker = new MyAppApplicationAuthenticator(app);
        if (checker.isRecordRelatedToCurrentUser()) {
            return true;
        } else {
            return false;
        }
    }
}