public with sharing class appAddWorkExperienceCC {

    public static String FIELD_CONTACT_ID = 'contactId';
    public static String FIELD_USER = 'user';
    public static String FIELD_WORK_EXPERIENCES = 'workExperiences';
    public static String FIELD_HISTORICAL_WORK_EXPERIENCES = 'historicalWorkExperiences';
    public static String FIELD_COUNTRY_OPTIONS = 'countryOptions';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';


    public static String FIELD_DELETE_STATUS = 'deleteStatus';
    public static String FIELD_SAVE_STATUS = 'saveStatus';
    public static String FIELD_MESSAGE = 'message';
    public static String FIELD_ERRORS = 'errors';
    public static String SUCCESS = 'success';
    public static String FAILED = 'failed';

    private static User getCurrentUser()
    {
        List<User> listUsers = [SELECT ProfileId, ContactId, App_Previously_Studied_at_Monash__c
        FROM User
        WHERE Id = :UserInfo.getUserId()];

        System.Debug('appAddWorkExperienceCC::getCurrentUser:' + listUsers);
        return listUsers[0];
    }

    /**
     * Function for initial loading of appAddWorkExperience component, retrieves the following:
     * user: Current User
     * contactId: Contact Id related to this user
     * workExperiences: Work Experiences attached to the current Application, ie editable
     * historicalWorkExperiences: Work Experiences from previous Applications (only if the application still exists)
     * countryOptions: the list of Country Attribute records
     *
     * @param appId - the application Id parsed from the Community Page URL
     *
     * @return a named map which is essentially a JSON object for setting up the lightning component
     */
    @AuraEnabled
    public static Map<String, Object> getInitLoad(Id appId)
    {
        if (ExperienceAuthenticationServices.isUnsafe(appId)) return unsafeParameterMessage();
        Map<String, Object> mapResults = new Map<String, Object>();

        // user
        User currUser = getCurrentUser();
        mapResults.put(FIELD_USER, currUser);

        // contact
        Id contactId = currUser.ContactId;
        Application__c contextApplication = [SELECT Id, Applicant__c FROM Application__c WHERE Id = :appId LIMIT 1];
        mapResults.put(FIELD_CONTACT_ID, contextApplication.Applicant__c);

        // existing work Experience
        List<Work_Experience__c> workExps = getAppWorkExperienceList(appId);
        mapResults.put(FIELD_WORK_EXPERIENCES, workExps);

        // historical
        List<Work_Experience__c> historicalWExps = getHistoricalWorkExperienceList(contactId, appId);
        mapResults.put(FIELD_HISTORICAL_WORK_EXPERIENCES, historicalWExps);

        // country options
        List<Map<String, String>> countryOptions = getCountryOptions();
        mapResults.put(FIELD_COUNTRY_OPTIONS, countryOptions);

        return mapResults;
    }


    /**
     * Gets the Work Experience records for this Application Id
     *
     * @param applicationId
     *
     * @return a list of Work Experience records
     */
    private static List<Work_Experience__c> getAppWorkExperienceList(Id applicationId)
    {

        if(applicationId != null) {
            List<Application_Work_Experience_Provided__c> listWorkExpProvided = [
                    SELECT Id,
                            Is_Submitted__c,
                            Application__c,
                            Work_Experience__c,
                            Work_Experience__r.Contact__c,
                            Work_Experience__r.Position__c,
                            Work_Experience__r.Employer_Name__c,
                            Work_Experience__r.Start_Date__c,
                            Work_Experience__r.End_Date__c
                    FROM Application_Work_Experience_Provided__c
                    WHERE Application__c = :applicationId AND Work_Experience__r.Reference_Count__c < 2
            ];

            Set<Id> workExpIds = new Set<Id>();
            for(Application_Work_Experience_Provided__c awp:listWorkExpProvided)
            {
                workExpIds.add(awp.Work_Experience__c);
            }

            if(workExpIds.size() > 0)
            {
                List<Work_Experience__c> workExpList = [SELECT Id,
                        Contact__c,
                        Position__c,
                        Employer_Name__c,
                        Start_Date__c,
                        End_Date__c,
                        Contact_Person__c,
                        Contact_Person_First_Name__c,
                        Contact_Person_Last_Name__c,
                        Contact_Person_Email__c,
                        Contact_Person_Phone__c,
                        Country__c
                FROM Work_Experience__c
                WHERE Id IN: workExpIds];
                return workExpList;
            }
        }

        return new List<Work_Experience__c>();
    }

    /**
     * Gets all valid Work Experience records for this contact NOT related to the current Application
     *
     * @param contactId - Id of the contact to search for
     * @param currentAppId - the application Id to exclude work experiences for
     *
     * @return a list of Work Experience records
     */
    private static List<Work_Experience__c> getHistoricalWorkExperienceList(Id contactId, Id currentAppId)
    {

        // get all applications for this contact
        List<Application__c> allApps = [SELECT Id, Name
        FROM Application__c
        WHERE Applicant__c =: contactId
        AND Id !=: currentAppId];
        List<Id> appIds = new List<Id>();
        for(Application__c application:allApps)
        {
            appIds.add(application.Id);
        }


        if(appIds.size() > 0) {

            // get all the junction objects for these applications
            List<Application_Work_Experience_Provided__c> listWorkExpProvided = [
                    SELECT Id,
                            Is_Submitted__c,
                            Application__c,
                            Work_Experience__c
                    FROM Application_Work_Experience_Provided__c
                    WHERE Application__c IN :appIds
            ];
            Set<Id> workExpIds = new Set<Id>();
            for(Application_Work_Experience_Provided__c awp:listWorkExpProvided)
            {
                workExpIds.add(awp.Work_Experience__c);
            }

            // query the actual work experience objects
            if(workExpIds.size() > 0)
            {
                List<Work_Experience__c> workExpList = [SELECT Id,
                        Contact__c,
                        Position__c,
                        Employer_Name__c,
                        Start_Date__c,
                        End_Date__c,
                        Contact_Person__c,
                        Contact_Person_First_Name__c,
                        Contact_Person_Last_Name__c,
                        Contact_Person_Email__c,
                        Contact_Person_Phone__c,
                        Country__c
                FROM Work_Experience__c
                WHERE Id IN: workExpIds
                ];
                return workExpList;
            }
        }

        return new List<Work_Experience__c>();
    }


    /**
     * Add or Update a Work Experience record passed in from the component UI
     *
     * @param appId - the application Id this Work Experience record belongs to
     * @param workExp - the work experience record
     *
     * @return JSON with the updated lists of current and historical work experience records
     */
    @AuraEnabled
    public static Map<String, Object> saveWorkExperience(Id appId, Work_Experience__c workExp)
    {
        if (ExperienceAuthenticationServices.isUnsafe(appId)) return unsafeParameterMessage();
        if (ExperienceAuthenticationServices.isUnsafe(workExp)) return unsafeUserInputMessage();
        Map<String, Object> mapResults = new Map<String, Object> ();
        system.debug('appAddWorkExperienceCC:: saveWorkExperience '+ workExp);

        Application__c contextApplication = [SELECT Id, Applicant__c FROM Application__c WHERE Id = :appId LIMIT 1];

        if (appId != null && workExp != null)
        {
            List<String> saveErrors = validateWorkExperience(workExp);
            if(saveErrors.size() == 0) {

                if(workExp.Contact__c == null) {
                    workExp.Contact__c = contextApplication.Applicant__c;
                }
                upsert workExp;

                // find if junction object exists
                List<Application_Work_Experience_Provided__c> listAWPs = [
                        SELECT Id
                        FROM Application_Work_Experience_Provided__c
                        WHERE Work_Experience__c = :workExp.Id
                        AND Application__c = :appId
                ];
                if (listAWPs.size() == 0) {
                    Application_Work_Experience_Provided__c appWorkExpToInsert = new Application_Work_Experience_Provided__c();
                    appWorkExpToInsert.Work_Experience__c = workExp.Id;
                    appWorkExpToInsert.Application__c = appId;
                    insert appWorkExpToInsert;

                    mapResults.put(FIELD_MESSAGE, 'Upserting');
                }

                mapResults.put(FIELD_SAVE_STATUS, SUCCESS);
            }
            else
            {
                mapResults.put(FIELD_SAVE_STATUS, FAILED);
                mapResults.put(FIELD_ERRORS, saveErrors);
            }
        }
        else
        {
            mapResults.put(FIELD_SAVE_STATUS, FAILED);
            mapResults.put(FIELD_MESSAGE, 'bad Arguments app Id = ' + appId + ', work exp = ' + workExp);
        }

        List<Work_Experience__c> workExperiences = getAppWorkExperienceList(appId);
        mapResults.put(FIELD_WORK_EXPERIENCES, workExperiences);
        // historical
        List<Work_Experience__c> historicalWExps = getHistoricalWorkExperienceList(contextApplication.Applicant__c, appId);
        mapResults.put(FIELD_HISTORICAL_WORK_EXPERIENCES, historicalWExps);


        return mapResults;
    }


    /**
     * Supporting function to validate that the fields on the Work Experience record have been properly completed before committing
     * to DB
     *
     * @param workExp
     *
     * @return
     */
    private static List<String> validateWorkExperience(Work_Experience__c workExp)
    {
        List<String> listErrors = new List<String>();

        if(workExp.Position__c == null || workExp.Position__c == '')
        {
            listErrors.add('Position is missing');
        }
        if(workExp.Employer_Name__c== null || workExp.Employer_Name__c== '')
        {
            listErrors.add('Employer is missing');
        }
        if(workExp.Start_Date__c == null)
        {
            listErrors.add('Start Date is missing');
        }
        if(workExp.Country__c == null)
        {
            listErrors.add('Country is missing');
        }

        // TODO Referee rules
        return listErrors;
    }


    /**
     * Retrieve an existing work experience record for editing in the UI
     *
     * @param workExpId - Id of the target Work Exp record
     *
     * @return JSON with the following:
     * workExperiences: [target_work_exp_record]
     */
    @AuraEnabled
    public static Map<String, Object> retrieveWorkExpForEdit(Id workExpId)
    {
         if (ExperienceAuthenticationServices.isUnsafe(workExpId)) return unsafeParameterMessage();
        Map<String, Object> mapResults = new Map<String, Object> ();
        if(null != workExpId)
        {
            List<Work_Experience__c> workExpList = [SELECT Id,
                    Contact__c,
                    Position__c,
                    Employer_Name__c,
                    Start_Date__c,
                    End_Date__c,
                    Contact_Person__c,
                    Contact_Person_First_Name__c,
                    Contact_Person_Last_Name__c,
                    Contact_Person_Email__c,
                    Contact_Person_Phone__c,
                    Country__c
            FROM Work_Experience__c
            WHERE Id =: workExpId];
            mapResults.put(FIELD_WORK_EXPERIENCES, workExpList);
        }

        return mapResults;
    }

    /**
     * Delete a work experience record from a request via the component's UI
     *
     * @param workExpId - Id of the record to delete
     * @param appId - the related Application Id to retrieve the updated the lists
     *
     * @return JSON with the updated current and historical work experience lists
     */
    @AuraEnabled
    public static Map<String, Object> deleteWorkExp(Id workExpId, Id appId)
    {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{workExpId,appId})) return unsafeParameterMessage();
        Map<String, Object> mapResults = new Map<String, Object> ();
        if(null != workExpId)
        {
            List<Work_Experience__c> toDelete  = [SELECT Id
            FROM Work_Experience__c
            WHERE Id =: workExpId];
            if(toDelete.size() > 0)
            {
                delete toDelete;
                mapResults.put(FIELD_DELETE_STATUS, SUCCESS);
            }
            else
            {
                mapResults.put(FIELD_DELETE_STATUS, FAILED);
                mapResults.put(FIELD_MESSAGE, 'No record found for ' + workExpId);
            }
        }

        List<Work_Experience__c> workExperiences = getAppWorkExperienceList(appId);
        mapResults.put(FIELD_WORK_EXPERIENCES, workExperiences);

        User currUser = getCurrentUser();
        List<Work_Experience__c> historicalWExps = getHistoricalWorkExperienceList(currUser.ContactId, appId);
        mapResults.put(FIELD_HISTORICAL_WORK_EXPERIENCES, historicalWExps);

        return mapResults;
    }

    /**
     * Gets all the Country Attribute records which have a country attached (for naming purposes)
     *
     * @return a list of option objects
     */
    private static List<Map<String,String>> getCountryOptions()
    {
		return CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_ISO,false);
    }

    private static Map<String,String> unsafeUserInputMessage() {
        return new Map<String,String> {
            FIELD_SAVE_STATUS => FAILED,
            FIELD_MESSAGE => ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT
            };
    }
    private static Map<String,String> unsafeParameterMessage() {
        return new Map<String,String> {
            FIELD_SAVE_STATUS => FAILED,
            FIELD_MESSAGE => ExperienceAuthenticationServices.MESSAGE_UNSAFE_PARAMETERS
            };
    }
}