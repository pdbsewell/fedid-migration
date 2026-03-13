/*
Author: Victor Cheng
Description: Class to display Drafts with the same style as Offers on Home page
* @revision    Shalini Mendu - Update with class comments
*/
public with sharing class appHomeDraftCC {

    public static String FIELD_USER = 'user';
    public static String FIELD_ACPS = 'acps';
    public static String FIELD_APPLICATION = 'application';

    public static String STATUS_DRAFT = 'Draft';

    /**
     * Get the current logged in User
     *
     * @return User Record
     */
    private static User getCurrentUser() {
        List<User> listUsers = [
                SELECT
                        ProfileId,
                        ContactId,
                        App_Previously_Studied_at_Monash__c,
                        App_Residency_Status__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];
        return listUsers[0];
    }

    /**
     * Get the latest Draft Application for this Contact
     *
     * @param applicantId - Contact Id to search for
     *
     * @return Application record
     */
    private static Application__c getDraftApplication(Id applicantId)
    {
        List<Application__c> apps = [SELECT Id
                , Name
                , Submitted_Date__c
                , Submission_Progress__c
                , CreatedDate
        FROM Application__c
        WHERE Applicant__c =: applicantId
        AND Status__c =: STATUS_DRAFT
        ORDER BY CreatedDate DESC
        LIMIT 1
        ];
        if(apps.size() > 0)
        {
            return apps[0];
        }

        return null;
    }

    /**
     * Return all ACPS which are attached to an Application, assumes the Id is for a draft Application
     *
     * @param applicationId - Id of the Draft Application
     *
     * @return a list of all the ACPs attached to this Application
     */
    private static List<Application_Course_Preference__c> getDraftACPs(Id applicationId)
    {
        List<Application_Course_Preference__c> acps = [SELECT Id
                , Preference_Number__c
                , Application__c
                , Application__r.Name
                , Application__r.Submitted_Date__c
                , Unit_Set_Description__c
                , Course_Title__c
                , Course_Code__c
                , Course_Offering__r.Attendance_Mode_Description__c
                , Course_Offering__r.Location_Description__c
                , Course_Offering__r.Admission_Calendar_Description__c
                , Course_Offering__r.Type_of_Place_Description__c
                , Outcome_Status_LOV__r.Applicant_Value__c
                , Outcome_Status_LOV__r.Value__c
                , Offer_Response_Status_LOV__r.Applicant_Value__c
                , Offer_Response_Status_LOV__r.Value__c
                , Offer_Response_Date__c
                , Conditional_Offer_Status_LOV__r.Value__c
                , Conditional_Offer_Status_LOV__r.Applicant_Value__c
                , Offer_Condition__c, Conditional_Offer_Satisfied_Date__c
                , Actual_Offer_Response_Date__c
                , Admission_Category__c
        FROM Application_Course_Preference__c
        WHERE Application__c =: applicationId
        //AND Application__r.Status__c = :STATUS_DRAFT
        //AND Admission_Category__c =: DOMESTIC_PG_FEE
        ORDER BY Application__r.Name, Preference_Number__c ASC
        ];

        return acps;
    }


    /**
     * Initial loading function for the LEX component appHomeDraft
     *
     * @return JSON with the following fields
     * user: current logged in user
     * application: draft application record for this user (if any)
     * acps: all the acps attached to this draft application (if any)
     */
    @AuraEnabled
    public static Map<String, Object> getInitLoadDrafts()
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        // get the user
        User currUser = getCurrentUser();
        mapResults.put(FIELD_USER, currUser);

        // get the acps on offer
        if(currUser != null)
        {
            // get the latest draft application
            Application__c draftApp = getDraftApplication(currUser.ContactId);
            if(draftApp != null)
            {
                mapResults.put(FIELD_APPLICATION, draftApp);

                // group by Application Id
                List<Application_Course_Preference__c> acps = getDraftACPs(draftApp.Id);
                mapResults.put(FIELD_ACPS, acps);
            }
        }

        return mapResults;
    }

    /**
     * Cancel the draft application by deleting it
     *
     * @param application - the application record to cancel
     *
     * @return a refresh of the initial load
     */
    @AuraEnabled
    public static Map<String, Object> cancelApplication(Application__c application)
    {
        if(null != application)
        {
            application.Status__c = 'Cancelled';
            update application;
        }

        return getInitLoadDrafts();
    }
}