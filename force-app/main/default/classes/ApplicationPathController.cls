/**
 * Created by trentdelaney on 23/8/18.
 * @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
 */

public without sharing class ApplicationPathController {

    public static String FIELD_APPLICATION = 'application';
    public static String FIELD_OLD_STATE = 'old_state';
    public static String FIELD_NEW_STATE = 'new_state';
    public static String FIELD_FURTHEST = 'furthest';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';
    public static String FIELD_STATES = 'states';


    public static List<String> SUBMISSION_STATUSES;


    @AuraEnabled
    public static Map<String, Object> GetInitLoad(Id applicationId, String newState)
    {
        Map<String, Object> mapResults = new Map<String, Object> ();
        // also get the complete Submission Progress values
        Schema.DescribeFieldResult fieldResult = Application__c.Submission_Progress__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        SUBMISSION_STATUSES = new List<String>();
        for( Schema.PicklistEntry f : ple)
        {
            SUBMISSION_STATUSES.add(f.getValue());
        }
        mapResults.put(FIELD_STATES, SUBMISSION_STATUSES);

        SynchApplicationToPage(applicationId, newState, mapResults);

        return mapResults;
    }

    private static void SynchApplicationToPage(Id applicationId, String newState, Map<String, Object> mapResults)
    {
        // get current user
        User currentUser = getCurrentUser();
        
        // check rights
        UserRecordAccess ura = MyApplicationUtilities.getRecordAccessForUserByIds(applicationId, currentUser.Id);
        if (ura.HasEditAccess) 
        {
            Application__c app = [SELECT Id,
                                  Status__c,
                                  Furthest_Progress__c,
                                  Submission_Progress__c                                  
                                  FROM Application__c
                                  WHERE id=:applicationId];

            System.debug('ApplicationPathController:: Application ' + app);
            System.debug('ApplicationPathController:: (1) Application ' + app.Furthest_Progress__c );

            // check if already submitted
            if(app.Status__c == 'Sent for Submission' || app.Status__c == 'Submitted')
            {
                // TODO - do we stop anything here?
            }
            else
            {
                System.debug('ApplicationPathController:: (2) Application furthest::' + app.Furthest_Progress__c + ', current:' + app.Submission_Progress__c + ', new:' + newState);
                // due to new field - initializing
                if(app.Furthest_Progress__c == null)
                {
                    app.Furthest_Progress__c = app.Submission_Progress__c;
                }

                // update the Status based on the section name
                String currState = app.Submission_Progress__c;
                app.Submission_Progress__c = newState;

                if(SUBMISSION_STATUSES.indexOf(app.Submission_Progress__c) > SUBMISSION_STATUSES.indexOf(app.Furthest_Progress__c))
                {
                    System.debug('ApplicationPathController:: (4) Updating furthest ' + app.Furthest_Progress__c );
                    app.Furthest_Progress__c = app.Submission_Progress__c;
                }

                Database.UpsertResult result = Database.upsert(app);

                System.debug ('ApplicationPathController:: errors:: ' + result.getErrors());
                //update app;

                mapResults.put(FIELD_OLD_STATE, currState);
                mapResults.put(FIELD_NEW_STATE, app.Submission_Progress__c);
                mapResults.put(FIELD_FURTHEST, app.Furthest_Progress__c);
                mapResults.put(FIELD_APPLICATION, app);
            }
        }
    }
    
    private static User getCurrentUser()
    {
        List<User> listUsers = [SELECT ProfileId, ContactId, App_Previously_Studied_at_Monash__c
        FROM User
        WHERE Id =: userInfo.getUserId()];

        System.Debug('ApplicationPathController::getCurrentUser:' + listUsers);
        return listUsers[0];
    }
    
    @AuraEnabled
    public static String GetCurrentStatus(String appId)
    {
        return MyApplicationUtilities.getApplicationStatusByAppId(appId);
    }
    
    @AuraEnabled
    public static String[] GetPicklist()
    {
        return MyApplicationUtilities.getPicklistOptions('Submission_Progress__c', 'Application__c');
    }
}