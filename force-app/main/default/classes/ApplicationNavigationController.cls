/*******************************************************************************
 * @author       Trent Delaney
 * @date         22 Aug 2018
 * @description  Class containing methods during Application Navigation
 * @revision
 * 05/03/2019 - Shalini Mendu - SFTDC-239
 * 08/02/2022 - Vinothraja    - SFTG-2477 Added validations while uploading documents
 * 11/08/2022 - Ken McGuire - Security Uplift
 * 14/02/2025 - Davey Yu - MGROI-706 Don't validate for access and equity on Graduate Research Applications
*******************************************************************************/

public with sharing class ApplicationNavigationController {

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
            AND IsPortalEnabled = True
    ];

    public static String FIELD_STATUS = 'status';
    public static String FIELD_MESSAGE_HEADER = 'header';
    public static String FIELD_MESSAGE = 'message';

    /*
    * @description Method validating Documents submitted
    * check if the applicant has uploaded the following mandatory documents
    *   1. Proof of Residency / Passport MUST be uploaded
    *   2. Educational History entries MUST have document uploaded
    * @param applicationId application record id
    * @return mapResults results
    */
    @AuraEnabled
    public static Map<String, String> validateApplicantDocuments(String applicationId) {
        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(applicationId)){
            return unsafeParameterMessage();
        }
        Map<String, String> mapResults = new Map<String, String>();
        try {
            Set<String> submittedDocTypes = new Set<String> ();
            String validationErrorMessage = '';
            // Check Contact Document, whether Applicant had submitted any documents for this Application
            for (Contact_Document__c cd : [SELECT Id, Document_Type__c, Document_Checklist_Type_F__c, Contact_Qualification__c
                                            FROM Contact_Document__c 
                                            WHERE Contact__c IN (SELECT applicant__c 
                                                                FROM Application__c 
                                                                WHERE ID =:applicationId) 
                                            AND Application__c = :applicationId
                                            LIMIT 50]) {
                    submittedDocTypes.add(cd.Contact_Qualification__c + cd.Document_Type__c);                                        
            }
            // Check Document Checklist, whether Any document is required for Residency and Qualifications
            for (Document_Checklist__c dc :[SELECT Id, Application__c, Checklist_Requirement__c, Application__r.Type_of_Study__c, Type__c, Allowed_Document_Type__c, Status__c, Contact_Qualification__c
                                            FROM Document_Checklist__c 
                                            WHERE Application__c = :applicationId
                                            LIMIT 50]){
                Boolean submitted = false;
                // validations for Monash Abroad applications
                if((dc.Application__r.Type_of_Study__c == 'Study Abroad' ||  dc.Application__r.Type_of_Study__c == 'Exchange') )
                {
                    // Other document type is not accepted
                    Set<String> allowedDocumentTypes = new Set<String>(dc.Allowed_Document_Type__c.split(';'));
                    allowedDocumentTypes.remove('OTHERDCTYP');
                    // Documents for Residency & Qualifications are mandatory 
                    if (dc.Type__c == 'Residency' || dc.Type__c == 'Qualification') {
                        // Check if a document is Submitted; if yes, checks whether it is one of the Specific & Allowed Document types
                        if ( dc.Status__c == 'Submitted' ) {
                            for (String docType : allowedDocumentTypes) {
                                if(submittedDocTypes.contains(dc.Contact_Qualification__c + docType)) {
                                    submitted = true ;
                                } 
                            }
                        } else {
                            submitted = false ;
                        }
                        if (!submitted) {
                            validationErrorMessage += ' - ' + dc.Checklist_Requirement__c + ' <br />';
                        }
                    }
                } else {
                    // TODO: Validations for Coursework applications
                    break;
                }
            }
            if (String.isNotBlank(validationErrorMessage)) {
                mapResults.put(FIELD_STATUS, 'ValidationError');
                mapResults.put(FIELD_MESSAGE_HEADER, 'Missing Required Documents');
                mapResults.put(FIELD_MESSAGE, validationErrorMessage);
            }
            return mapResults;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @description process status my application
     * @param appId applicationId
     * @param direction navigation direction
     * @return save results
     */
    @AuraEnabled
    public static Map<String, Object> ProcessStatus(String appId, String direction)
    {
        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{appId,direction})) {
            return unsafeParameterMessage();
        }
        Map<String, Object> mapResults = new Map<String, Object>();
        try {            
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :currentUserId];

            Application__c[] listApps = [
                    SELECT Id, Submission_Progress__c, Residency_Status__c,Type_of_Study__c,Duration_of_Study__c, Campus_Location__c, HasDisabilities__c, Existing_Aus_disability_support__c,
                     Criminal_History_Opt_In__c
                    ,Disability_opt_In__c, Currently_residing_in_Malaysia__c, Malaysia_pass_expiry__c, 
                    Malaysia_pass_type__c, Malaysian_NRIC_Passport__c
                    FROM Application__c
                    WHERE Id = :appId
            ];
            Application__c app;
            if (listApps.size() > 0) {
                app = listApps[0];
            } else {
                mapResults.put(FIELD_STATUS, 'Error');
                mapResults.put(FIELD_MESSAGE, 'Application Not Found');
                return mapResults;
            }
            //check if application has a related unit preference with a prerequisite
            if(app != null){
                Set<String> prerequisiteColorsSet = new Set<String>{'red','yellow'};
                List<Unit_Preference__c> unitPreferencePreReqList = new List<Unit_Preference__c>();
                for(Unit_Preference__c loopUnitPreReq : [SELECT Id 
                                                         FROM Unit_Preference__c 
                                                         WHERE MA_Status__c IN :prerequisiteColorsSet 
                                                            AND Application_Course_Preference__r.Application__c = :app.Id]){
                    unitPreferencePreReqList.add(loopUnitPreReq);
                }
                app.Has_Unit_Prerequisite__c = !unitPreferencePreReqList.isEmpty();

            }

            //String status = MyApplicationUtitiles.GetApplicationStatusByAppId(appId);
            String currentStatus = app.Submission_Progress__c;
            String[] options = MyApplicationUtilities.getPicklistOptions('Submission_Progress__c', 'Application__c');

            String newStatus;
            for (Integer i = 0; i < options.size(); i++) {
                if (currentStatus == options[i]) {
                    if (direction == 'Backward') {
                        //always allow Backwards
                        newStatus = options[i - 1];
                        app.Submission_Progress__c = newStatus;
                    } else if (direction == 'Forward') {
                        //Navigation error handling
                        /* Personal Details */
                        if(app.Submission_Progress__c == 'Personal Details'){
                          // ignore question validations if current user is a partner
                            if(!currentUser.Profile.Name.containsIgnoreCase('partner')){
                                if((app.Disability_Opt_In__c==null || app.Disability_Opt_In__c== 'No') && app.Type_of_Study__c != 'Graduate Research'){
                                  mapResults.put(FIELD_STATUS, 'ValidationError');
                                  mapResults.put(FIELD_MESSAGE_HEADER, 'Access and Equity');
                                  mapResults.put(FIELD_MESSAGE, 'You must consent to collecting sensitive information about disabilities.');
                                  return mapResults;
                                }
                                if(app.HasDisabilities__c == null && app.Type_of_Study__c != 'Graduate Research'){
                                    mapResults.put(FIELD_STATUS, 'ValidationError');
                                    mapResults.put(FIELD_MESSAGE_HEADER, 'Access and Equity');
                                    mapResults.put(FIELD_MESSAGE, 'Please confirm if you have a disability, mental health or ongoing medical condition that may affect your studies or may prevent you to undertake full-time study?');
                                    return mapResults;
                                } else if(app.HasDisabilities__c == 'Yes' && app.Existing_Aus_disability_support__c == null && app.Type_of_Study__c != 'Graduate Research'){
                                    mapResults.put(FIELD_STATUS, 'ValidationError');
                                    mapResults.put(FIELD_MESSAGE_HEADER, 'Access and Equity');
                                    mapResults.put(FIELD_MESSAGE, 'Please confirm if you have registered for disability support in an Australian tertiary institution in the last 5 years?');
                                    return mapResults;
                                }
                            }
                        }
                        if(app.Type_of_Study__c == 'Study Abroad' || app.Type_of_Study__c == 'Exchange' && app.Duration_of_Study__c==null){
                            mapResults.put(FIELD_MESSAGE_HEADER, 'Duration of Study');
                            mapResults.put(FIELD_MESSAGE, 'Please specify Duration of Study');
             
                        }                       
                        if ( (app.Campus_Location__c == '' || app.Campus_Location__c == null) && i > 0) {
                            mapResults.put(FIELD_STATUS, 'Error');
                            mapResults.put(FIELD_MESSAGE, 'Empty');
                            return mapResults;
                        } else if (app.Campus_Location__c != 'Australia' && i > 0 && app.Campus_Location__c != 'Malaysia' && app.Campus_Location__c != 'Indonesia' && app.Campus_Location__c != 'Online' && app.Type_Of_Study__c != 'Graduate Research') {
                            // TECH DEBT: 2018/09/07 hack to block non-Australian applications from progressing past Personal Details
                            mapResults.put(FIELD_STATUS, 'Error');
                            mapResults.put(FIELD_MESSAGE, 'Not Australia');

                            // early return
                            return mapResults;
                        } else if ( (app.Campus_Location__c == 'Australia' || app.Campus_Location__c == 'Malaysia' || app.Campus_Location__c == 'Indonesia') && i > 0) {

                            if (String.isBlank(app.Residency_Status__c)) {
                                mapResults.put(FIELD_STATUS, 'Error');
                                mapResults.put(FIELD_MESSAGE, 'No Residency');
                                return mapResults;
                            }

                        }

                        newStatus = options[i + 1];
                        app.Submission_Progress__c = newStatus;
                    }
                  
                    mapResults.put(FIELD_STATUS, 'Success');
                    mapResults.put(FIELD_MESSAGE, newStatus);
                    return mapResults;
                }
            }
            update app;
            mapResults.put(FIELD_STATUS, 'Error');
            mapResults.put(FIELD_MESSAGE, 'Unknown');
            return mapResults;
        }catch(Exception ex)
        {
            ExLog.add('Application Naviagtion Controller', '', ex.getMessage(), '');
            throw new AuraHandledException('Unable to progress: ' + ex.getMessage());
        }

    }

     /**
     * @description create application record
     * @param none
     * @return returnValue application record id
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
                insert applicationRecord;

                //insert junction object records if there are any
                //insertChildRecords(applicationRecord.Id);

                returnValue = applicationRecord.Id;
                // Added By Majid Reisi Dehkordi 14/06/2018 For Online Credit
                //retrieveOnlineCreditURLs(applicationRecord.Applicant__c);
            }

        } catch (Exception ex) {
            ExLog.add('Application Naviagtion Controller', '', ex.getMessage(), '');
            throw new AuraHandledException('Unable to update your details: ' + ex.getMessage());
        }
        return returnValue;
    }

    /**
     * @date March 2021
     * @description - check if the Application is created by the Partner or by the community user
     * @param appId application Id
     * @return boolean duration study is valid
    */
    @AuraEnabled
    public static Boolean isValidDurationStudy(String appId)
    {
        if (ExperienceAuthenticationServices.isUnsafe(appId)) {
            return false;
        }
        try{
            //update application's has unit prereq field
            if(appId != null && appId != ''){
                Set<String> prerequisiteColorsSet = new Set<String>{'red','yellow'};
                List<Unit_Preference__c> unitPreferencePreReqList = new List<Unit_Preference__c>();
                //check if application has a related unit preference with a prerequisite
                for(Unit_Preference__c loopUnitPreReq : [SELECT Id 
                                                         FROM Unit_Preference__c 
                                                         WHERE MA_Status__c IN :prerequisiteColorsSet 
                                                            AND Application_Course_Preference__r.Application__c = :appId]){
                    unitPreferencePreReqList.add(loopUnitPreReq);
                }
                update new Application__c(Id = appId, Has_Unit_Prerequisite__c = !unitPreferencePreReqList.isEmpty());
            }
            
            Application__c app =  [select Id,Owner_profile_name__c,Duration_of_Study__c,Type_of_Study__c from Application__c where id=:appId];
            if( (app.Type_of_Study__c=='Study Abroad'|| app.Type_of_Study__c=='Exchange') && app.Duration_of_Study__c!=null){
                return true;
            }
            else if(app.Type_of_Study__c!='Study Abroad' && app.Type_of_Study__c!='Exchange'  ){
                return true;
            }
            
        }catch(Exception e)
        {
            LogUtilityException.logException(e,'ApplicationNavigationController.isValidDurationStudy');
            throw e;
        }
        
        return false;
    }
    
    /**
     * @date March 2021
     * @description - Validate study plan to check that the student has created atleast 4 unit preferences and a maximum
     * of 8 unit preferences for the first semester only
     * @param appId applicationId
     * @return retMap 
     * revision
     * 17/08/2022   Vinothraja  SFTG-2826 Minimum & Maximum units fetched via Custom Settings
    */
    @AuraEnabled
    public static Map<String,String> validateStudyPlans(String appId)
    {
        if (ExperienceAuthenticationServices.isUnsafe(appId)){
            return unsafeUserInputMessage();
        }
        Map<String, String> retMap = new Map<String,String>();

        try{
            Application__c app = [SELECT Campus_Location__c,Type_of_Study__c,Duration_of_Study__c from Application__c where id=:appId];
            
            if( app.Type_of_Study__c!='Study Abroad' && app.Type_of_Study__c!='Exchange') {
                return retMap;
            }
            
            List<Application_Course_Preference__c> lstAcp = [SELECT ID,NAME, Course_Offering__r.Start_Date__c  FROM Application_Course_Preference__c 
                                                                WHERE Application__c = :appId LIMIT 1];
            if (lstAcp == null || lstAcp.size() ==0 ) {
                retMap.put('ACPSelection','You should choose a valid Course');
                return retMap;
            }
            Application_Course_Preference__c acp = lstAcp[0];
            if( acp.Course_Offering__r.Start_Date__c == null){ 
                return retMap;
            }

            // validate Unit Preferences in ACP
            Integer unitPreferencesInACP = (Integer) ([SELECT count(id)countUnits FROM unit_preference__c 
                                                        WHERE Application_Course_Preference__c= :acp.id 
                                                        AND Semester__c IN (1,2)][0].get('countUnits'));

            if (app.Campus_Location__c == 'Online' && (unitPreferencesInACP < Constants.MIN_UNITS_ONLINE || unitPreferencesInACP > Constants.MAX_UNITS_ONLINE)) {
                retMap.put('UnitPreferenceSelection','You should choose at least ' + Constants.MIN_UNITS_ONLINE + ' unit preference and a maximum of ' + Constants.MAX_UNITS_ONLINE + ' preferences per semester.');
            }
            else if (app.Campus_Location__c != 'Online' && (unitPreferencesInACP < Constants.MIN_UNITS_MA || unitPreferencesInACP > Constants.MAX_UNITS_MA)) {
                retMap.put('UnitPreferenceSelection', 'You should choose at least ' + Constants.MIN_UNITS_MA +' unit preferences and a maximum of ' + Constants.MAX_UNITS_MA + ' preferences per semester');
            }
           
        }catch(Exception e)
        {
            LogUtilityException.logException(e,'ApplicationNavigationController.validateStudyPlans');
            throw e;
        }
        return retMap;
       
    }
    
     /**
     * @description generate user reset application progress status
     * @param applicationId application Id
     * @return mapResults
     */
    @AuraEnabled
    public static Map<String, Object> generateUserResetApplicationProgressStatus(String applicationId) {
         Map<String, Object> mapResults = new Map<String, Object>();
        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(applicationId)){
            return unsafeParameterMessage();
        } 

        mapResults.putAll(ExperienceAuthenticationServices.generateUserResetApplicationProgressStatus(applicationId));

        //Return results
        return mapResults;
    }

     /**
     * @description update Application Record
     * @param recordJSON json record
     * @return resultMap
     */
    @AuraEnabled
    public static Map<String, Object> updateApplicationRecord(String recordJSON) {
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(resultMap.values())){
            return unsafeUserInputMessage();
        } 
        try{
            Application__c applicationContext = (Application__c)JSON.deserialize(recordJSON, Application__c.class);
            update applicationContext;

            resultMap.put('RESULT', 'SUCCESS');
        }catch(Exception ex){
            resultMap.put('RESULT', 'ERROR');
            resultMap.put('MESSAGE', ex.getMessage());
        }

        //Return results
        return resultMap;
    }
    
    private static Map<String,String> unsafeUserInputMessage() {
        return ExperienceAuthenticationServices.userMessage(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }
    private static Map<String,String> unsafeParameterMessage() {
        return ExperienceAuthenticationServices.userMessage(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }

   /**
     * @date May 2023
     * @description - retrieve Application to determine source system
     * @param applicationId application id
    * 15/05/2034 Smendu
    */
    @AuraEnabled
    public static Application__c retrieveApplication(String  applicationId) {
            List<Application__c> applicationRecords = [
            SELECT Id, Owner.name, Name, Source_System__c, Type_of_Study__c
            FROM Application__c
            WHERE id = :applicationId];
            return applicationRecords.size() == 0 ? null : applicationRecords[0];
    }

    /**
     * @date 4 July 2024
     * @description - fetch the my app feature toggle metadata
    */
    @AuraEnabled
    public static Feature_Switch__c fetchMyAppFeatureToggle() {
        return Feature_Switch__c.getInstance();
    }
}