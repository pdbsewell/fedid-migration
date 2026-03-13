/*******************************************************************************
* @author       Ryan Wilson
* @date         07.Apr.2017         
* @description  controller class for CoursePreference.cmp lightning component
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
* @revision     Ken McGuire (2022-08-12): Security Uplift
* @revision     APRivera (2025-01-28): Added method to pull picklist value - getEnglishProficiencyPicklistValues
* @revision     APRivera (2025-04-01): Added references of Contact Legal First & Last names
*******************************************************************************/
@SupressWarnings('PMD.ClassNamingConventions')
public with sharing class appAddQualificationCC {

    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';
    public static String FIELD_USER = 'user';
    public static String FIELD_ACCESS_ALLOWED = 'access_allowed';

    public static String FIELD_APPLICATION = 'application';
    public static String FIELD_DRAFT_QUALIFICATIONS = 'draft_qualifications';
    public static String FIELD_HISTORICAL_QUALIFICATIONS = 'historical_qualifications';
    public static String FIELD_DRAFT_INSTITUTIONS = 'draft_institutions';

    public static String FIELD_MESSAGE = 'message';
    public static String FIELD_DELETE_AQ_RESULT = 'delete_appqual_result';
    public static String FIELD_DELETE_CQ_RESULT = 'delete_conqual_result';
    public static final String LOGGER_TAG = 'My.App - Add Qualification';

    /**
     * @description Retrieves the current user record with specific fields.
     *
     * @return User - The current user record.
     */
    @AuraEnabled
    public static User getCurrentUser() {
        List<User> listUsers = [SELECT ProfileId, ContactId, App_Previously_Studied_at_Monash__c
        FROM User
        WHERE Id = :UserInfo.getUserId()];

        return listUsers[0];
    }

    /**
     * @description Retrieves a set of contact qualification IDs associated with the specified application.
     *
     * @param applicationId The ID of the `Application__c` record.
     * @return Set<Id> - A set of contact qualification IDs linked to the application.
     */
    private static Set<Id> getContactQualificationIdsForApplication(Id applicationId) {
        List<Application_Qualification_Provided__c> aqpList = [SELECT Id
                , Contact_Qualification__c
        FROM Application_Qualification_Provided__c
        WHERE Application__c =: applicationId];

        Set<Id> conQualForThisAppIds = new Set<Id>();
        for(Application_Qualification_Provided__c aqp:aqpList)
        {
            conQualForThisAppIds.add(aqp.Contact_Qualification__c);
        }
        return conQualForThisAppIds;
    }

    /**
     * @description Constructs and returns a comma-separated string of SOQL fields for querying qualifications.
     *
     * @return String - A formatted string of SOQL fields.
     */
    private static String makeQualificationSOQLFieldString() {
        String sFields = 'Id';
        sFields +=',RecordTypeId';
        sFields += ',RecordType.Name';
        sFields += ',Qualification_Country__c';
        sFields += ',State_Province__c';
        sFields += ',State__c';

        sFields += ',Qualification__c';
        sFields += ',Other_Qualification__c';
        sFields += ',Qualification__r.Qualification_Name__c';
        sFields += ',Qualification__r.Id';

        // institution/ awarding body
        sFields += ',Other_Institution__c';
        sFields += ',Institution_Code__c';
        sFields += ',Institution_Name__c';

        // time periods
        sFields += ',Date_Achieved__c';
        sFields += ',Expected_date_of_completion__c';
        sFields += ',First_Year_Enrolled__c';
        sFields += ',Last_Year_Enrolled__c';
        sFields += ',Year_of_Completion__c';

        sFields += ',Instruction_in_English__c';

        // scores/results
        sFields += ',isTestCompleted__c';
        sFields += ',Listening__c';
        sFields += ',Reading__c';
        sFields += ',Speaking__c';
        sFields += ',Writing__c';
        sFields += ',Score__c';
        
        sFields += ',Status__c';
        sFields += ',Expiry_Date__c';
        sFields += ',Source_Channel__c';
        sFields += ',Verification_Status__c';
        sFields += ',English_Test_Number__c';
        sFields += ',English_Proficiency__c';

        sFields += ',Other_Qualification_Comments__c';
        sFields += ', (SELECT Is_Submitted__c FROM Application_Qualifications__r)';
        return sFields;
    }

    /**
     * @description Retrieves a list of qualifications associated with the specified contact.
     *
     * @AuraEnabled
     * @param contactId The ID of the `Contact` record.
     * @return List<Contact_Qualification__c> - A list of qualifications for the given contact.
     */
    @AuraEnabled
    public static List<Contact_Qualification__c> getContactQualifications(Id contactId) {
		//Guard
        if (ExperienceAuthenticationServices.isUnsafe(contactId)) return null;
        String sSOQL = 'SELECT ' + makeQualificationSOQLFieldString();
        sSOQL += ' FROM Contact_Qualification__c ';
        sSOQL += ' WHERE Contact__c =\'' + contactId + '\'';
        sSOQL += ' ORDER BY CreatedDate DESC';
        List<Contact_Qualification__c> conQualList = Database.query(sSOQL);
        return conQualList;
    }

    /**
     * @description Retrieves a list of institutions based on the institution codes found in the provided qualifications.
     *
     * @param qualifications A list of `Contact_Qualification__c` records to extract institution codes from.
     * @return List<Institution__c> - A list of matching institutions.
     */
    private static List<Institution__c> getUsedInstitutionMap(List<Contact_Qualification__c> qualifications) {
        List<String> institutionCodes = new List<String>();
        for(Contact_Qualification__c cq:qualifications)
        {
            if(cq.Institution_Name__c != null && cq.Institution_Code__c!= null)
            {
                institutionCodes.add(cq.Institution_Code__c);
            }
        }

        List<Institution__c> institutions = [SELECT Id,
                Institution_Code__c,
                Institution_Name__c,
                Type__c
        FROM Institution__c
        WHERE Institution_Code__c IN: institutionCodes];

        /*
        Map<String, Institution__c> mapInstitutionsByCode = new Map<String, Institution__c>();
        for(Institution__c objInst:institutions)
        {
            mapInstitutionsByCode.put(objInst.Institution_Code__c, objInst);
        }
        return mapInstitutionsByCode;
        */
        return institutions;
    }

    /**
     * @description Retrieves draft qualifications and associated institutions for the specified application.
     *
     * @AuraEnabled
     * @param applicationId The ID of the `Application__c` record.
     * @return Map<String, Object> - Contains draft qualifications and their associated institutions.
     */
    @AuraEnabled
    public static Map<String, Object> getDraftQualifications(Id applicationId) {
       	//Guard
        if (ExperienceAuthenticationServices.isUnsafe(applicationId)) return unsafeParameterMessage();
        Map<String, Object> mapResults = new Map<String, Object>();

        // get all Contact Qualification Ids attached to this app
        Set<Id> appQualificationIds = getContactQualificationIdsForApplication(applicationId);

        String sSOQL = 'SELECT ' + makeQualificationSOQLFieldString();
        sSOQL += ' FROM Contact_Qualification__c ';
        sSOQL += ' WHERE Id IN: appQualificationIds';
        sSOQL += ' ORDER BY CreatedDate DESC';
        List<Contact_Qualification__c> conQualList = Database.query(sSOQL);

        //Map<String, Institution__c> mapInstitutionsByIds = getUsedInstitutionMap(conQualList);
        List<Institution__c> institutions = getUsedInstitutionMap(conQualList);
        mapResults.put(FIELD_DRAFT_INSTITUTIONS, institutions);
        mapResults.put(FIELD_DRAFT_QUALIFICATIONS, conQualList);
        return mapResults;
    }

    /**
     * @description Retrieves and categorizes qualifications for a given application and contact into draft and historical,
     *              along with related institution data.
     *
     * @TestVisible
     * @param applicationId The ID of the `Application__c` record.
     * @param contactId The ID of the `Contact` record.
     * @return Map<String, Object> - Contains draft qualifications, historical qualifications, and associated institutions.
     */
    @TestVisible
    private static Map<String, Object> getQualificationsByApplicationAndContact(Id applicationId, Id contactId) {
        Map<String, Object> mapResults = new Map<String, Object>();
        // get all Contact Qualifications
        List<Contact_Qualification__c> allContactQualifications = getContactQualifications(contactId);

        // get all Contact Qualification Ids attached to this app
        Set<id> appQualificationIds = getContactQualificationIdsForApplication(applicationId);
        
        // separate into draft and historical
        List<Contact_Qualification__c> historicalQualifications = new List<Contact_Qualification__c>();
        List<Contact_Qualification__c> draftQualifications = new List<Contact_Qualification__c>();
        for(Contact_Qualification__c qualification : allContactQualifications)
        {
            if(appQualificationIds.contains(qualification.id))
            {
                // it's attached to the current app
                draftQualifications.add(qualification);
            }
            else
            {
                historicalQualifications.add(qualification);
            }
        }

        List<Institution__c> listInstitutions = getUsedInstitutionMap(draftQualifications);

        mapResults.put(FIELD_DRAFT_INSTITUTIONS, listInstitutions);
        mapResults.put(FIELD_DRAFT_QUALIFICATIONS, draftQualifications);
        mapResults.put(FIELD_HISTORICAL_QUALIFICATIONS, historicalQualifications);

        return mapResults;
    }

    /**
     * @description Retrieves the current user, application details, qualifications, and additional related data
     *              for the provided `Application__c` ID, ensuring user access permissions.
     *
     * @AuraEnabled
     * @param applicationId The ID of the `Application__c` record to retrieve related information for.
     * @return Map<String, Object> - Contains user data, application details, qualifications, and permissions.
     */
    @AuraEnabled
    public static Map<String, Object> getCurrentUserAndQualifications(String applicationId) {
        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(applicationId)) return unsafeParameterMessage();
        
        if(applicationId != null)
        {
            Map<String, Object> mapResults = new Map<String, Object>();
            User objUser = getCurrentUser();

            UserRecordAccess ura = MyApplicationUtilities.getRecordAccessForUserByIds(applicationId, objUser.Id);
            if (ura == null || !ura.HasReadAccess) {
                mapResults = new Map<String, Object>();
                mapResults.put(FIELD_ACCESS_ALLOWED, false);

                Nebula.Logger.error('getCurrentUserAndQualifications no read access to ' + applicationId + ', for user ' + objUser.Id).addTag(LOGGER_TAG);
                String exMessage = 'No Access to Record ' + applicationId + ', for user ' + objUser.Id;
                mapResults.put(FIELD_MESSAGE, exMessage);
                //throw new NoAccessException();
                // early out and don't return further data
                return mapResults;
            }
                        
            // add the application
            List<Application__c> listApps = [SELECT Id, Applicant__c, Credit_Intention__c, English_Language_Proficiency__c, English_Program_Consideration__c,
                                                    English_Proficiency_Requirement__c, Type_of_Study__c, Agent__c, AgentName__c, Owner_Profile_Name__c, Partner_Name__c
                                             FROM Application__c 
                                             WHERE Id = :applicationId];
            Application__c resultApplication = listApps[0];
            // Check for latest Submitted Application by the same Applicant for pre-filling English_Language_Proficiency__c
            if (String.isBlank(resultApplication.English_Language_Proficiency__c)){
                for (Application__c otherAppn : [SELECT Id, Applicant__c, English_Language_Proficiency__c, English_Program_Consideration__c, English_Proficiency_Requirement__c
                                                FROM Application__c 
                                                WHERE Applicant__c = :resultApplication.Applicant__c
                                                AND Submission_Progress__c = 'Submit' 
                                                AND English_Language_Proficiency__c <> NULL ORDER BY Submitted_Date__c DESC LIMIT 1]){
                    resultApplication.English_Language_Proficiency__c = otherAppn.English_Language_Proficiency__c;
                    resultApplication.English_Proficiency_Requirement__c = otherAppn.English_Proficiency_Requirement__c;
                    resultApplication.English_Program_Consideration__c = otherAppn.English_Program_Consideration__c;
                }
            }
            mapResults.put(FIELD_APPLICATION, resultApplication);
            mapResults.put(FIELD_USER, objUser);
            mapResults.put(FIELD_ACCESS_ALLOWED, true);
            mapResults.put('APPLICANT', resultApplication.Applicant__c);
            mapResults.put('ApplicationCreatedByProfile', resultApplication.Owner_Profile_Name__c);
            mapResults.put('ACCOUNT_PARTNER_RECORDTYPE_ID', Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId());

            mapResults.putAll(getQualificationsByApplicationAndContact(applicationId, resultApplication.Applicant__c));

            //Initialize Variables
            String queryResult = 'NoMatch';
            //Query matching contact record
            Application__c applicationRecord = [SELECT Id, Applicant__c, Applicant__r.Previous_Monash_ID__c, Applicant__r.Person_ID_unique__c,
                                                    Applicant__r.Birthdate, Applicant__r.FirstName, Applicant__r.LastName, Applicant__r.Previous_Surname__c, Applicant__r.Previous_Firstname__c
                                                FROM Application__c
                                                WHERE Id = :applicationId LIMIT 1];
            if(applicationRecord != null){

                if(applicationRecord.Applicant__c != null){
                    //Setup correct parameters
                    String searchPersonId = applicationRecord.Applicant__r.Previous_Monash_ID__c;
                    if(applicationRecord.Applicant__r.Person_ID_unique__c != null){
                        searchPersonId = applicationRecord.Applicant__r.Person_ID_unique__c;
                    }
                    //Call logic to determine applicant student type
                    if(searchPersonId != null && applicationRecord.Applicant__r.Birthdate != null){
                        queryResult = MyApplicationUtilities.findCurrentPreviousStudent(searchPersonId, applicationRecord.Applicant__r.Birthdate);
                    }
                    mapResults.put('STUDENT_STATUS', queryResult);
                    Contact con = [SELECT Id,Birthdate, FirstName, LastName, First_Name__c, Last_Name__c, Previous_Surname__c, Previous_Firstname__c FROM Contact WHERE Id =: applicationRecord.Applicant__c];

                    mapResults.put('APPLICATION_CONTACT', applicationRecord);
                    mapResults.put('APPLICANT_Birthdate', con.Birthdate);
                    mapResults.put('APPLICANT_FirstName', con.First_Name__c);
                    mapResults.put('APPLICANT_LastName', con.Last_Name__c);
                    mapResults.put('APPLICANT_PreviousFirstName', con.Previous_Firstname__c);
                    mapResults.put('APPLICANT_PreviousLastName', con.Previous_Surname__c);
                }
            }

            // retrieve partner accounts
            Set<String> partnerNames = new Set<String>();
            for(Account accountItem : new SearchPartners().queryPartnerAccounts()){
                partnerNames.add(accountItem.Name);
            }
            mapResults.put('PARTNER_ACCOUNTS', partnerNames);

            Nebula.Logger.saveLog();
            return mapResults;
        }
        return null;

    }

    /**
     * Get the qualification type options for adding a new qualification
     *
     * @return Qualification record Types
     */
    @AuraEnabled
    public static List<Map<String,String>> getQualificationRecordTypeOptions() {
        List<Map<String,String>>  options = new List<Map<String,String>> ();

        for( RecordType recType: [SELECT Id, Name, SobjectType
        FROM        RecordType
        WHERE       SobjectType = 'Contact_Qualification__c'
        ORDER BY    Name DESC])
        {
            Map<String,String> mapOption = new Map<String, String>();
            mapOption.put(FIELD_VALUE, recType.Id);
            mapOption.put(FIELD_LABEL, recType.Name);

            options.add(mapOption);
        }
        return options;
    }

    /**
     * Using the Country_Attribute__c object for country
     *
     * @return country attribute
     */
    @AuraEnabled
    public static List<Map<String,String>> getCountryAttributes() {
        return CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_SAAC,false);
    }

    /**
     * Get the English Test options for a Select, the type is Admission due to Callista dependency
     * @return admissions record type
     */
    @AuraEnabled
    public static List<Map<String, String>> getAdmissionTestOptions() {
        // Get the RecordTypeId of admission test qualifications
        String admissionTestRecTypeId = Schema.SObjectType.Qualification__c.getRecordTypeInfosByDeveloperName().get('Admission_Test').getRecordTypeId();

        // Initialize the list to store options
        List<Map<String, String>> options = new List<Map<String, String>>();

        // Query qualifications for the Admission Test record type
        for (Qualification__c qualificationRec : [
                SELECT Qualification_Name__c, Available_on_Portal__c
                FROM Qualification__c
                WHERE RecordTypeId = :admissionTestRecTypeId
                AND Available_on_Portal__c = TRUE
                ORDER BY Qualification_Name__c
        ]) {
            // Create a map for each qualification option
            Map<String, String> mapOption = new Map<String, String>();
            mapOption.put(FIELD_VALUE, qualificationRec.Id);
            mapOption.put(FIELD_LABEL, qualificationRec.Qualification_Name__c);

            // Add the option to the list
            options.add(mapOption);
        }

        // Return the list of options
        return options;
    }

    @AuraEnabled
    public static List<Map<String,String>> getCountryOptions() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Country__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    @AuraEnabled
    public static List<Map<String,String>> getAusStateOptions() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.State__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    @AuraEnabled
    public static List<Map<String,String>>  getCompletionStatusOptions() {
        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Status__c.getDescribe();
        return populatePicklistAsOptions(fieldResult);
    }

    /**
     * reusable function to get picklist options for lightning components
     * @param fieldResult - Contains methods for describing sObject fields
     * @return a list of {value,label} objects for use as lightning:select options
     */
    private static List<Map<String,String>> populatePicklistAsOptions(Schema.DescribeFieldResult fieldResult) {
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String,String>> options = new List<Map<String,String>> ();
        for( Schema.PicklistEntry f : ple)
        {
            Map<String,String> mapOption = new Map<String, String>();
            mapOption.put(FIELD_VALUE, f.getValue());
            mapOption.put(FIELD_LABEL, f.getLabel());

            options.add(mapOption);
        }
        return options;
    }

    /**
     * @description Upserts a Contact Qualification record in Salesforce and links it to the specified Contact
     *              and Application. If the qualification is new, it creates an `Application_Qualification_Provided__c`
     *              record to associate the qualification with the application.
     * @AuraEnabled
     * @param contactId The ID of the Contact to which the qualification will be linked.
     * @param applicationId The ID of the Application to which the qualification will be linked.
     * @param contactQualification The `Contact_Qualification__c` record to be created or updated.
     *                              If the `Source_Channel__c` field is populated, it assigns a specific Record Type ID.
     * @return Map<String, Object> - A map containing the following:
     *         - `contact_qualification_id`: The ID of the upsert `Contact_Qualification__c` record.
     *         - `app_qualification_id`: The ID of the inserted `Application_Qualification_Provided__c` record, if applicable.
     *         - `message`: A message string summarizing the operation results or errors.
     * @throws Exception If an error occurs during upsert or insert operations, an error message is included in the returned map.
     * @guard Ensures the safety of parameters and prevents unsafe operations via input validation using
     *        `ExperienceAuthenticationServices`.
     */
    @AuraEnabled
    public static Map<String,Object> upsertQualificationToContact(Id contactId, Id applicationId, Contact_Qualification__c contactQualification) {
        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{contactId,applicationId})) return unsafeParameterMessage();
		if (ExperienceAuthenticationServices.isUnsafe(contactQualification)) return unsafeUserInputMessage();
        Map<String, Object> objResults = new Map<String, Object>();
        String sMessage;
        Boolean newQualification = contactQualification?.Id == null;

        try {
            if(contactQualification.Source_Channel__c != null){
                contactQualification.RecordTypeId = getRecordTypeIdForEnglishTest();
            }

            Database.UpsertResult upr = Database.upsert(contactQualification);
            sMessage = 'Success! Upsert Contact Qualification Result: ' + upr;
            objResults.put('contact_qualification_id', contactQualification.Id);
            if(newQualification)
            {
                // new qualification, attach to current application
                Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
                aqp.Contact_Qualification__c = contactQualification.Id;
                aqp.Application__c = applicationId;

                Database.SaveResult sr = Database.insert(aqp);
                objResults.put('app_qualification_id', aqp.Id);
                sMessage += '\n\nSuccess! Insert Application Qualification Provided Result: ' + sr;
            }
            Nebula.Logger.info(sMessage).addTag(LOGGER_TAG);
        }
        catch (Exception e)
        {
            sMessage = 'UPSERT Error: ' + e.getMessage();
            Nebula.Logger.error(sMessage).addTag(LOGGER_TAG);
        }
        Nebula.Logger.saveLog();
        objResults.put(FIELD_MESSAGE, sMessage);
        return objResults;

    }

    /**
     * @description Deletes a `Contact_Qualification__c` record and its associated
     *              `Application_Qualification_Provided__c` record if the current user owns it.
     *              Updates the application's credit intention flag if no "Tertiary Education"
     *              qualifications remain.
     *
     * @AuraEnabled
     * @param contactQualificationId The ID of the `Contact_Qualification__c` record to delete.
     * @param applicationId The ID of the associated `Application__c` record.
     * @return Map<String, Object> - Contains deletion results, updated application, and a status message.
     * @throws Exception Includes an error message in case of failure.
     */
    @AuraEnabled
    public static Map<String,Object> deleteContactAndAppQualification(Id contactQualificationId, Id applicationId) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{contactQualificationId,applicationId})) return unsafeParameterMessage();
        Map<String, Object> objResults = new Map<String, Object>();
        String sMessage;

        try
        {
            // get the contact qualification
            List<Contact_Qualification__c> listConQuals = [SELECT Id, Contact__c
                                                           FROM Contact_Qualification__c
                                                           WHERE Id =: contactQualificationId LIMIT 1];
            if(listConQuals.size() > 0)
            {
                Contact_Qualification__c cqToDelete = listConQuals[0];

                // get the current user for permission checking
                User currentUser = getCurrentUser();
                
                // check still required due to test class evaluation against this...
                if(currentUser.ContactId == cqToDelete.Contact__c)
                {
                    // look for application qualification
                    List<Application_Qualification_Provided__c> listAppQuals = [SELECT id, Application__c
                    FROM Application_Qualification_Provided__c
                    WHERE Contact_Qualification__c =: contactQualificationId
                    AND Application__c =: applicationId];

                    if(listAppQuals.size() > 0)
                    {
                        // deleting the contact qualification will delete the APQ junction object
                        Database.DeleteResult[] drConQual = Database.delete(listConQuals);

                        objResults.put(FIELD_DELETE_CQ_RESULT, 'SUCCESS = ' + drConQual[0].isSuccess());
                        sMessage = 'DELETE:: Success found CQs=' + listConQuals.size() + ', AQs=' + listAppQuals.size();
                        
                        // check if there are Tertiary Qualifications remaining, if not, clear the credit intention flag
                        Application__c app = [SELECT Id FROM Application__c WHERE Id =: applicationId];
                        List<Contact_Qualification__c> terQuals = [SELECT Id FROM Contact_Qualification__c
                                                                  WHERE RecordType.Name = 'Tertiary Education'];
                        if(terQuals.size() == 0)
                        {
                            saveCreditIntention(applicationId, false);                            
                        }
                        objResults.put(FIELD_APPLICATION, app);
                        Nebula.Logger.info('DELETE:: Success found CQs=' + listConQuals.size() + ', AQs=' + listAppQuals.size()).addTag(LOGGER_TAG);

                    }
            	}
                else
                {
                    // error: contact does not own this record
                    sMessage = 'DELETE error:: User does not own this record';
                    Nebula.Logger.error('DELETE error:: User does not own this record').addTag(LOGGER_TAG);
                }
            }
            else
            {
                // error handling
                sMessage = 'DELETE error:: found ' + listConQuals.size() + ' records for ' + contactQualificationId;
                Nebula.Logger.error('DELETE error:: found ' + listConQuals.size() + ' records for ' + contactQualificationId).addTag(LOGGER_TAG);
            }

        }
        catch(Exception e)
        {
            sMessage = 'DELETE ERROR:' + e.getMessage();
            Nebula.Logger.error('DELETE ERROR: ' + e.getMessage()).addTag(LOGGER_TAG);
        }
        Nebula.Logger.info('appAddQualificationCC::deleteContactAndAppQualification: ' + objResults).addTag(LOGGER_TAG);
        Nebula.Logger.saveLog();
        objResults.put(FIELD_MESSAGE, sMessage);
        return objResults;
    }

    /**
     * @description Updates the credit intention flag on an `Application__c` record if the user has edit access.
     *
     * @AuraEnabled
     * @param applicationId The ID of the `Application__c` record to update.
     * @param creditIntent The new credit intention value.
     * @return Map<String, Object> - Contains the updated `Application__c` record.
     */
    @AuraEnabled
    public static Map<String, Object> saveCreditIntention(Id applicationId, Boolean creditIntent) {
        if (ExperienceAuthenticationServices.isUnsafe(applicationId)) return unsafeParameterMessage();
        Map<String, Object> mapResults = new Map<String, Object>();
 		if(applicationId != null)
        {
            //User objUser = getCurrentUser();
            
            UserRecordAccess ura = MyApplicationUtilities.getRecordAccessForUserByIds(applicationId, UserInfo.getUserId());
            
            if (ura != null && ura.HasEditAccess)
            {       
                Application__c app = [SELECT Id, Credit_Intention__c FROM Application__c WHERE Id=: applicationId];
                if(app.Credit_Intention__c != creditIntent)
                {
                    app.Credit_Intention__c = creditIntent;
                    update app;
                }
                mapResults.put(FIELD_APPLICATION, app);
            }
        }
        
        return mapResults;            
    }

    /**
    * @description Associates an `Application__c` record with a Partner Account by publishing an
    *              asynchronous event (`Async_Process__e`) with the given details.
    *
    * @AuraEnabled
    * @param applicationId The ID of the `Application__c` record to associate.
    * @param partnerAccountId The ID of the Partner `Account` to link to the application.
    * @param partnerAccountName The name of the Partner `Account` (optional).
    * @return Map<String, Object> - Contains:
    *         - `STATUS`: `SUCCESS` or `ERROR`.
    *         - `MESSAGE`: A summary of the operation's result or error details.
    * @throws Exception If the process fails, the result includes the error message.
    */
    @AuraEnabled
    public static Map<String, Object> associateApplicationToPartner(String applicationId, String partnerAccountId, String partnerAccountName) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{applicationId,partnerAccountId,partnerAccountName})) return unsafeParameterMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();
        Id partnerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

        try{
            List<Async_Process__e> associateApplicationToPartnerEventsToPub = new List<Async_Process__e>();
            //prepare payload
            AsyncProcessPayload payload = new AsyncProcessPayload();
            payload.put('applicationId', JSON.serializePretty(applicationId));
            payload.put('partnerAccountId', JSON.serializePretty(partnerAccountId));
            if(partnerAccountName != null){
                payload.put('partnerAccountName', JSON.serializePretty(partnerAccountName));
                payload.put('partnerAccountRecordTypeId', JSON.serializePretty(partnerAccountRecordTypeId));
            }

            associateApplicationToPartnerEventsToPub.add(new Async_Process__e(
                Process_Name__c = 'appAddQualificationCC.AssociateApplicationPartner',
                Parameter__c = payload.serialize()
            ));
            EventBus.publish(associateApplicationToPartnerEventsToPub);

            //add result
            resultMap.put('STATUS', 'SUCCESS');
            resultMap.put('MESSAGE', 'Updated Application\'s Partner Account');
            Nebula.Logger.error('Success: Updated Application\'s Partner Account').addTag(LOGGER_TAG);
        }catch(Exception ex){
            //add error
            resultMap.put('STATUS', 'ERROR');
            resultMap.put('MESSAGE', ex.getMessage());
            Nebula.Logger.error('Error: ' + ex.getMessage()).addTag(LOGGER_TAG);
        }
        Nebula.Logger.saveLog();
        //Return results
        return resultMap;
    }

    /**
     * @description Removes the Partner account association from the specified `Application__c` record
     *              by clearing the `Agent__c` field.
     *
     * @AuraEnabled
     * @param applicationId The unique ID of the `Application__c` record to update.
     * @return Map<String, Object> - A map containing:
     *         - `STATUS`: `SUCCESS` or `ERROR` indicating the operation result.
     *         - `MESSAGE`: A success or error message.
     * @throws Exception If the operation fails, the `STATUS` will be `ERROR` and include the error details.
     * @guard Validates the `applicationId` for safety using `ExperienceAuthenticationServices`.
     */
    @AuraEnabled
    public static Map<String, Object> removePartnerOnApplication(String applicationId) {
        if (ExperienceAuthenticationServices.isUnsafe(applicationId)) return unsafeParameterMessage();
        //Initialize variables
        Map<String, Object> resultMap = new Map<String, String>();        
        //Id partnerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

        try{
            //update application details
            Application__c pageApplication = new Application__c(Id = applicationId, Agent__c = null);
            update pageApplication;

            //add result
            resultMap.put('STATUS', 'SUCCESS');
            resultMap.put('MESSAGE', 'Removed Application\'s Partner Account');
            Nebula.Logger.info('Success: Removed Application\'s Partner Account').addTag(LOGGER_TAG);
        }catch(Exception ex){
            //add error
            resultMap.put('STATUS', 'ERROR');
            resultMap.put('MESSAGE', ex.getMessage());
            Nebula.Logger.error('Error: ' + ex.getMessage()).addTag(LOGGER_TAG);
        }

        Nebula.Logger.saveLog();
        //Return results
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Method that runs on system context started by a platform event to create/assign a partner account to an application
     *              my.app user does not have account access which brings the need to run this on system context
     *              String partnerAccountId
     *              String partnerAccountName
     * @revision    25/01/2021 - Kristian Vegerano - Created
     */
    public class AssociateApplicationPartner implements IPlatformEventInvocable {
        public void execute(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
                String applicationId;
                String partnerAccountId;   
                String partnerAgreementId;  
                String partnerAccountName;
                String partnerAccountRecordTypeId;

                for(AsyncProcessPayload payload : payloads) {
                    applicationId = payload.get('applicationId').toString().remove('"');
                    partnerAccountName = payload.get('partnerAccountName').toString().remove('"');    
                    partnerAccountRecordTypeId = payload.get('partnerAccountRecordTypeId').toString().remove('"');
                }

                // retrieve matching partner account
                Integer firstItem = 0;
                List<Account> partnerAccountList = [SELECT Id, Name, Owner.Name, (SELECT Id FROM Partner_Agreements__r)
                                                    FROM Account 
                                                    WHERE RecordType.Name = 'Partner' 
                                                        AND Name = :partnerAccountName
                                                    ORDER BY Name ASC
                                                    LIMIT 1];

                //Check if a partner account needs to be created
                if(partnerAccountList.isEmpty()){
                    //create partner account then update the application with the partner account
                    Account newPartner = new Account(Name = partnerAccountName, RecordTypeId = partnerAccountRecordTypeId);
                    insert newPartner;

                    //flag the partner id to be associated to the application
                    partnerAccountId = newPartner.Id;
                    List<Partner_Agreement__c> partnerAgreementList = [SELECT Id
                                                                       FROM Partner_Agreement__c 
                                                                       WHERE Partner_Account__c = :partnerAccountId
                                                                       LIMIT 1];
                    partnerAgreementId = partnerAgreementList[firstItem].Id;
                }else{
                    // retrieve partner account and agreement ids from existing record
                    partnerAccountId = partnerAccountList[firstItem].Id;
                    partnerAgreementId = partnerAccountList[firstItem].Partner_Agreements__r[firstItem].Id;
                }

                //update application details
                Application__c pageApplication = new Application__c(Id = applicationId, Agent__c = partnerAccountId, Partner_Agreement__c = partnerAgreementId);
                update pageApplication;
            }
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Updates the provided application record in the database. Accepts a serialized
     *              JSON string representing the application record, performs deserialization, and updates
     *              the corresponding record in Salesforce. Also validates the input and handles exceptions.
     * @param       application - A serialized JSON string representing the application record to update.
     * @return      Map<String, Object> - A map containing the operation's status (`STATUS`) and a message (`MESSAGE`).
     *              STATUS can be either 'SUCCESS' or 'ERROR', and MESSAGE provides additional details.
     * @revision    19/01/2022 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> updateApplication(String application) {
         if (ExperienceAuthenticationServices.isUnsafe(application)) return unsafeUserInputMessage();
        // initialize variables
        Map<String, Object> resultMap = new Map<String, String>();     

        try{
            // deserialize parameter application
            Application__c applicationRecord = (Application__c)JSON.deserialize(application, Application__c.class);

            // update application details
            update applicationRecord;

            // add result
            resultMap.put('STATUS', 'SUCCESS');
            resultMap.put('MESSAGE', 'Successfully updated application');
            Nebula.Logger.info('Successfully updated application').addTag(LOGGER_TAG);
        }catch(Exception ex){
            // add error
            resultMap.put('STATUS', 'ERROR');
            resultMap.put('MESSAGE', ex.getMessage());

            Nebula.Logger.error('Error: ' + ex.getMessage()).addTag(LOGGER_TAG);
        }
        Nebula.Logger.saveLog();
        // return results
        return resultMap;
    }

    /**
     * @description       : Inner class to enable my.app applicants to search partner account names for selection as their current institutions
     * @group             : Services
     * @last modified on  : 2021-03-12
     * @last modified by  : Kristian Vegerano
     * Modifications Log 
     * Ver   Date         Author          Modification
     * 1.0   2021-03-12 - Kristian Vegerano - Created
     */
    private without sharing class SearchPartners {
        /**
         * @author      Kristian Vegerano
         * @description This method is used to remove the permission sets to the user
         * @return      String queryString - for the partners
         * @revision    25/02/2021 - Kristian Vegerano - Created
         */
        public List<Account> queryPartnerAccounts() {
            return [SELECT Id, Name, Owner.Name 
                    FROM Account 
                    WHERE RecordType.Name = 'Partner' 
                        AND ((NOT Name LIKE '% test %') AND (NOT Name LIKE 'test %') AND (NOT Name LIKE '% test') AND (NOT Name = 'test'))
                    ORDER BY Name ASC
                    LIMIT 10000];
        }
    }

    /**
         * @description Generates and returns a map containing an error message for unsafe user input.
         *
         * @return Map<String, String> - A map with the error message details.
         */
    private static Map<String, String> unsafeUserInputMessage() {
        return ExperienceAuthenticationServices.userMessageCC(ExperienceAuthenticationServices.RESULT_TYPE_ERROR, ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }

    /**
     * @description Generates and returns a map containing an error message for unsafe parameter input.
     *
     * @return Map<String, String> - A map with the error message details.
     */
    private static Map<String,String> unsafeParameterMessage() {
        return ExperienceAuthenticationServices.userMessageCC(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_PARAMETERS);
    }

    /**
     * Retrieves the country name (ISO/SAAC format) based on Country_Attribute__c.Country__c or Country_Attribute__c.Callista_Country__c.
     * Handles null checks and format validation.
     *
     * @param countryId The Id of the Country_Attribute__c record to retrieve.
     * @param format The format required - either "ISO" or "SAAC".
     * @return The corresponding country name based on the requested format or null if invalid.
     */
    @AuraEnabled
    public static String getCountryNameById(Id countryId, String format) {
        //Not null checks
        if ( countryId == null || String.isBlank(format))
        {
            return null;
        }

        Country_Attribute__c ca = [SELECT Id,Country__c, Callista_Country__c FROM Country_Attribute__c WHERE Id=:countryId];
        return CountryServices.getCountryName(ca,format);
    }

    /**
     * @description Retrieves and filters the picklist values for the `English_Proficiency__c` field
     *              on the `Contact_Qualification__c` object. Only active picklist values with specific
     *              API names are included in the result.
     * @AuraEnabled(Cacheable=true)
     * @return      List<Map<String, String>> - A list of maps representing the allowed picklist values.
     *              Each map contains:
     *              - 'label': The human-readable picklist label.
     *              - 'value': The API name of the picklist value.
     * @throws      AuraHandledException - Thrown if there is an error while fetching or processing the picklist values.
     */
    @AuraEnabled(Cacheable=true)
    public static List<Map<String, String>> getEnglishProficiencyPicklistValues() {
        try {
            // Retrieve picklist values for English_Proficiency__c field
            List<Schema.PicklistEntry> picklistEntries = Schema.getGlobalDescribe()
                    .get('Application__c')
                    .getDescribe()
                    .fields.getMap()
                    .get('English_Proficiency_Requirement__c')
                    .getDescribe()
                    .getPicklistValues();

            // Build and return the values as a List of Maps (label and value - API name)
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();

            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) { // Only include active and allowed values
                    // Add label and API name as a key-value pair
                    Map<String, String> picklistOption = new Map<String, String>();
                    picklistOption.put('label', entry.getLabel()); // Human-readable label
                    picklistOption.put('value', entry.getValue()); // API name
                    picklistOptions.add(picklistOption);
                }
            }

            return picklistOptions;
        } catch (Exception e) {
            // Handle any error that might occur and return an empty result or raise an exception
            throw new AuraHandledException('Error while retrieving picklist values: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves the Record Type ID for the `English_Test` on `Contact_Qualification__c`.
     *
     * @AuraEnabled(Cacheable=true)
     * @return Id The Record Type ID for `English_Test`, or null if not found.
     */
    @AuraEnabled(Cacheable=true)
    public static Id getRecordTypeIdForEnglishTest() {
        // Return null if not found
        return Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByDeveloperName().get('English_Test').getRecordTypeId();
    }


    /**
         * @description Retrieves the ID of the Qualification record where the name
         *              contains "Language of Instruction".
         *              Caches the result for optimization.
         *
         * @return Id - The ID of the matching Qualification__c record, or null if no match is found.
         */
    @AuraEnabled(Cacheable=true)
    public static Id getLanguageOfInstruction() {
        return [SELECT Id FROM Qualification__c WHERE Qualification_Name__c LIKE '%Language of Instruction%' LIMIT 1].Id;
    }

}