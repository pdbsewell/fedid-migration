/**
 * Created by trentdelaney on 4/9/18.
 * Modified by Andrew Yeo on 8/11/18 - added the fields Offer_response_LOV__c and Outcome_status_LOV__c to the query
 * Modified by Victor Cheng on 28/11/18 - ORDER BY clause to display in ascending Preference_Number__c
 */

public with sharing class ApplicationACPTableController {

    public static final User userRecord = [
            SELECT Id, ContactId,
                    App_Salutation__c,
                    LastName,
                    App_Gender__c,
                    App_Birthdate__c,
                    Email,
                    App_Residency_Status__c,
                    Street,
                    City,
                    App_Address_Type__c,
                    State,
                    PostalCode,
                    MobilePhone,
                    Phone,
                    Country,
                    App_Home_Phone__c
            FROM User
            WHERE Id = :userInfo.getUserId()
            AND IsPortalEnabled = TRUE
    ];

    public class ApplicationWrapper {

        public Application__c appParent;
        public List<Application_Course_Preference__c> appPrefs;

        //Constructor
        public ApplicationWrapper(Application__c app, List<Application_Course_Preference__c> prefs) {
            appParent = app;
            appPrefs = prefs;
        }
    }

    @AuraEnabled
   public static String GetApplicationsWithACP(Boolean editable) {

        Map<Id, ApplicationWrapper> wrappedApplications = new Map<Id, ApplicationWrapper>();
        Map<Id, Application__c> wrappedApps = new Map<Id, Application__c>();

        Set<String> appIds = new Set<String>();

        List<Application__c> apps;

        try{
            if(editable){
                apps = [
                        SELECT Id,  Name, Applicant__c, Status__c
                        FROM Application__c
                        WHERE Status__c = 'Draft' AND Applicant__c = :userRecord.ContactId
                ];
            }else{
                apps = [
                        SELECT Id,  Name, Applicant__c, Status__c
                        FROM Application__c
                        WHERE Status__c = 'Submitted' AND Applicant__c = :userRecord.ContactId
                ];
            }
        }catch(Exception e){
            ExLog.add('AppWrapper', 'test', e.getMessage(), 'test');
        }

        for(Application__c a : apps){
            wrappedApps.put(a.Id, a);
            appIds.add(a.Id);
        }

        List<Application_Course_Preference__c> prefs = [
                SELECT Id, Outcome_Status_LOV__r.Applicant_Value__c, Course_Code__c, Course_Offering__r.Admission_Calendar_Description__c, Offer_Response_Status_LOV__r.Applicant_Value__c, Preference_Number__c, Course_Title__c, Course_Offering__r.Attendance_Mode_Description__c, Course_Offering__r.Location_Description__c, Course_Offering__r.Commencement_Period__c, Application_Date__c, Application__c, Application__r.Submitted_Date__c, Unit_Set_Description__c, Course_Offering__r.Type_of_Place_Description__c
                FROM Application_Course_Preference__c
                WHERE Application__c IN :appIds
                ORDER BY Preference_Number__c ASC
        ];

        for(Application_Course_Preference__c acp : prefs){
            try{
                if (wrappedApplications.containsKey(acp.Application__c)) {
                    wrappedApplications.get(acp.Application__c).appPrefs.add(acp);
                }
                else{
                    List<Application_Course_Preference__c> newPrefs = new List<Application_Course_Preference__c>();
                    newPrefs.add(acp);

                    ApplicationWrapper wrapper = new ApplicationWrapper(wrappedApps.get(acp.Application__c), newPrefs);

                    wrappedApplications.put(acp.Application__c, wrapper);
                }

            }catch(Exception e){
                ExLog.add('AppWrapper', 'test', e.getMessage(), 'test');
            }
        }

        //Add in the blank ones
        for(Application__c ap : apps){
            if(!wrappedApplications.containsKey(ap.Id)){
                wrappedApplications.put(ap.Id, new ApplicationWrapper(ap, new List<Application_Course_Preference__c>()));
            }
        }

        return JSON.serialize(wrappedApplications);
    }

    @AuraEnabled
    public static String EditApplication() {
        List<Application__c> apps = [
                SELECT Id
                FROM Application__c
                WHERE Status__c = 'Draft' AND Applicant__c = :userRecord.ContactId
        ];

        if (apps.size() > 0) {
            String appId = apps[0].Id;
            String stat = MyApplicationUtilities.getApplicationStatusByAppId(appId);

            return JSON.serialize(new AppStatusWrapper(appId, stat));
        } else {
            throw new AuraHandledException('Cannot edit application as there are no drafts');
        }


    }

    public class AppStatusWrapper
    {
        public String appId;
        public String acpId;
        public String status;

        public AppStatusWrapper(String applicationId, String appStatus)
        {
            appId = applicationId;
            status = appStatus;
        }
    }
    
    @AuraEnabled
    public static Boolean RemoveApplication() {
        List<Application__c> apps = [
                SELECT Id
                FROM Application__c
                WHERE Status__c = 'Draft' AND Applicant__c = :userRecord.ContactId
        ];

        if (apps.size() > 0) {
            delete apps[0];
            return true;
        } else {
            throw new AuraHandledException('There is no Application to delete');
        }
    }
}