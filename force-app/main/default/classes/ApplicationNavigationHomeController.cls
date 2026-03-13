/**
 * @author Trent De Laney
 * @date 21 Feb 2019 at 3:33:55 pm
 * @group AuraController
 * @description Used to manage the front page of my.app and its associated "new application" functions.
 */
public with sharing class ApplicationNavigationHomeController {

    /********************************************************
    Internal Wrappers
    ********************************************************/
    /**
     * @author Trent De Laney
     * @date 21 Feb 2019 at 3:33:13 pm
     * @group Wrappers
     * @description Used for easy parsing on the Aura front end
     */
    public class AppStatusWrapper {
        public String appId;
        public String acpId;
        public String status;

        public AppStatusWrapper(String applicationId, String appStatus) {
            appId = applicationId;
            status = appStatus;
        }
    }

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

    /********************************************************
    AURA FUNCTIONS
    ********************************************************/

    /**
    * @author Trent De Laney
    * @description Creates a new application in my.app portal
    * @date 21 Feb 2019 at 3:28:52 pm
    * @return String (appId)
    */
    @AuraEnabled
    public static String CreateApplication() {
        Application__c applicationRecord = new Application__c();
        applicationRecord.Applicant__c = userRecord.ContactId;
        String returnValue = '';
        try {
            List<Application__c> apps = [
                    SELECT Id
                    FROM Application__c
                    WHERE Status__c = 'Draft' AND Applicant__c = :userRecord.ContactId
            ];

            if (apps.size() > 0) {
                throw new AuraHandledException('You may only have 1 Application at a time');
            } else {
                applicationRecord.From_Portal__c = true; //R.Wilson added indicator for Callista Migration.
                applicationRecord.Status__c = 'Draft'; //R.Wilson added default status for PD merge.
                applicationRecord.Source_System__c = 'my.app';
                insert applicationRecord;

                //insert junction object records if there are any
                InsertChildRecords(applicationRecord.Id, userRecord.ContactId);

                returnValue = applicationRecord.Id;
            }

        } catch (Exception ex) {
            ExLog.add('Application Navigation Controller', '', ex.getMessage(), '');
            throw new AuraHandledException('Unable to update your details: ' + ex.getMessage());
        }
        return returnValue;
    }

    /**
    * @author Trent De Laney
    * @description Checks to see if the user has any drafts, if they do, don't allow record creation
    * @date 21 Feb 2019 at 3:29:39 pm
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean HasDrafts() {
        List<Application__c> apps = [
                SELECT Id
                FROM Application__c
                WHERE Status__c = 'Draft' AND Applicant__c = :userRecord.ContactId
        ];

        if (apps.size() > 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
    * @author Trent De Laney
    * @description Edits the application and navigates the user to the appropriate page in my.app
    * @date 21 Feb 2019 at 3:31:21 pm
    * @return String appStatus
    */
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

    /********************************************************
    PRIVATE FUNCTIONS
    ********************************************************/
    /**
    * @author Trent De Laney
    * @description Inserts the child records for previous applications to ensure they are linked for future submissions
    * @date 21 Feb 2019 at 3:32:12 pm
    * @param String appId, String contactId
    */
    private static void InsertChildRecords(String appId, String contactId) {
        //Get all work exp
        List<Work_Experience__c> workExp = [
                SELECT Id
                FROM Work_Experience__c
                WHERE Contact__c = :contactId
        ];

        if(workExp.size() > 0){
            //Create the new list to be inserted
            List<Application_Work_Experience_Provided__c> appWorkExp = new List<Application_Work_Experience_Provided__c>();
            for (Work_Experience__c work : workExp){
                Application_Work_Experience_Provided__c newAppWork = new Application_Work_Experience_Provided__c();
                newAppWork.Work_Experience__c = work.Id;
                newAppWork.Application__c = appId;
                appWorkExp.add(newAppWork);
            }

            insert appWorkExp;
        }
    }
}