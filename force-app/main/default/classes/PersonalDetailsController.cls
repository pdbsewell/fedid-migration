/**
 * @author Trent De Laney
 * @date 13 Dec 2018 at 10:06:35 am
 * @group Aura Controller
 * @description Used to drive the Personal Details Component on my.app
 * @revision Updated mapping for Email field to Personal_Email__c for person matching.
 * @revision Shalini Mendu - Make Title(Salutation) optional
 * @revision  09/08/2022 - Ken McGuire - Security uplift 
 * 20.3.2023    Ken McGuire - country of birth replace ISO with SAAC
 * 27.7.2023    SMen - read the country of birth values
 * 02.5.2025    APR - Added Previous_Firstname SOQL reference
 * 14.4.2025  Vishal Gupta - MGROI-880 adding code for allowing sanctioned countries to bypass MFA SMS
 */
public with sharing class PersonalDetailsController {

    /********************************************************
    PROPERTIES
    ********************************************************/
    public static String FIELD_CONTACT = 'contact';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';
    public static String FIELD_COUNTRY_OPTIONS = 'countryOptions';
    public static String FIELD_COUNTRY_OF_BIRTH_OPTIONS = 'countryOBOptions';
    public static String FIELD_MFA_PHONE_NO = 'mfaPhoneNo';
    public static String FIELD_GENDER_OPTIONS = 'genderOptions';
    public static String FIELD_PREVIOUS_APPLICATION = 'previousApplication';
    public static String FIELD_HAS_PREVIOUS_APPLICATIONS = 'hasPreviousApplications';
    public static String MFARequired = 'mfaRequired';
    public static String ISCOUNTRYSANCTIONED = 'isCountrySanctioned';
    public static Set<String> EXCLUDED_GENDERS_FROM_MYAPP = new Set<String> {'P', 'U'};

    /********************************************************
    AURA FUNCTIONS
    ********************************************************/

    /**
     * @author Trent De Laney
     * @description Initialises the component with data that is required for functionality
     * @date 13 Dec 2018 at 10:07:10 am
     * @param applicationId application Id
     * @param currentURL current url
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> GetPersonalDetailsInitLoad(String applicationId, String currentUrl) {
        //Guard
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{applicationId,currentUrl})){
            return unsafeParameterMessage();
        } 
        
        Map<String, Object> mapResults = new Map<String, Object>();
        Application__c applicationRecord;
        Contact currentContact;
                
        // check if the user has registered mfa mobile number
        Map<String, Object> resultsMap = new Map<String, Object>();
        resultsMap = ExperienceMFAServices.retrieveCurrentUserDetails();
        Boolean shouldShowInternalMFA = (Boolean)resultsMap.get('ShouldShowInternalMFA');

        //MGROI-880 adding code for sacntioned countries
        String mobileNumber = (String) resultsMap.get('contactPhone');
        if(mobileNumber != null) {
            List<String> compoundMobileNumber = mobileNumber.split(' ');
            String unverifiedMobileCountryCode = compoundMobileNumber[0];
            if(new CountriesSelector().isSanctionedBySFDC(unverifiedMobileCountryCode)) {
                mapResults.put(ISCOUNTRYSANCTIONED, true);
            }            
        }

        // determine if the screen needs to bypass mfa for autotest usage - read url parameter
        Boolean doBypass = false;
        Integer secondItemIndex = 1;
        String bypassParameter;
        List<String> urlParameterList = currentUrl.split('\\?');
        if(urlParameterList.size() > 1){
            List<String> paramItemList = urlParameterList[secondItemIndex].split('&');
            for(String loopParameter : paramItemList){
                if(loopParameter.containsIgnoreCase('bypass')){
                    bypassParameter = loopParameter.split('=')[secondItemIndex];
                }
            }
        }
        if(bypassParameter != null){
            ExperienceMFASetting__c mfaSetting = ExperienceMFASetting__c.getInstance();
            if(mfaSetting != null){
                if(mfaSetting.Autotest_Bypass_Key__c != null){
                    if(bypassParameter.containsIgnoreCase(mfaSetting.Autotest_Bypass_Key__c)){
                        doBypass = true;
                    }
                }
            }
        }

        // return that the current user is meant to be mfa challenged        
        Boolean hasMyApp2FAPermission = FeatureManagement.checkPermission('MyApplication_Experience_2FA');
        mapResults.put(MFARequired, (hasMyApp2FAPermission && shouldShowInternalMFA) && !doBypass);        

        mapResults.put(FIELD_HAS_PREVIOUS_APPLICATIONS, false);
        // get contact
        currentContact = GetCurrentContact();
        if (currentContact != null) {
            mapResults.put(FIELD_HAS_PREVIOUS_APPLICATIONS, CheckPreviousApplications(currentContact.Id));
        }

        //Current Application
        if(applicationId != null)
        {
            applicationRecord = GetCurrentApplication(applicationId);
            mapResults.put(FIELD_PREVIOUS_APPLICATION, applicationRecord);

            // get contact
            currentContact = GetCurrentContact(applicationRecord.Applicant__c);
        }
        // set contact record 
        mapResults.put(FIELD_CONTACT, currentContact);
        
        // set country options
        mapResults.put(FIELD_COUNTRY_OPTIONS, GetCountryOptions());
        
         // set country options
        mapResults.put(FIELD_COUNTRY_OF_BIRTH_OPTIONS, getCountryAttributes());
        
        
        // set gender options
        mapResults.put(FIELD_GENDER_OPTIONS, getGenderOptions());

        // set MFA verified Phone number
        if (currentContact != null) {
            mapResults.put(FIELD_MFA_PHONE_NO, PhoneServices.retrieveMFAVerifiedPhone(currentContact.Id));
        }
        // add today
        DateTime dateTimeNow = System.NOW();
        List<String> dateTimeNowString = dateTimeNow.format('yyyy-MM-dd', 'Australia/Sydney').split('-');
        mapResults.put('TODAY', Date.newInstance(Integer.valueOf(dateTimeNowString[0]), Integer.valueOf(dateTimeNowString[1]), Integer.valueOf(dateTimeNowString[2])));

        return mapResults;
    }

    /**
     * @author Trent De Laney
     * @description Gets picklist values to be populated on the front end. Uses passthrough to Library class.
     * @date 13 Dec 2018 at 10:34:32 am
     * @param objectName object name
     * @param fieldName  field name
     * @return Map<String, String>
     */
    @AuraEnabled
    public static Map<String, String> GetPicklistValues(String objectName, String fieldName) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{objectName,fieldName})) {
            return null;
        }
        return MyApplicationUtilities.getPicklistOptionsMap(fieldName, objectName);
    }

    /**
     * @author Trent De Laney
     * @description Determines if there an ACP relating to this application
     * @date 13 Dec 2018 at 10:35:19 am
     * @param appId application id
     * @return Boolean
     */
    @AuraEnabled
    public static Boolean HasACPonApplication(String appId) {
        if (ExperienceAuthenticationServices.isUnsafe(appId)){
            return null;
        } 
        List<Application_Course_Preference__c> prefs = [
                SELECT Id
                FROM Application_Course_Preference__c
                WHERE Application__c = :appId
        ];

        if (prefs.size() > 0) {
            return true;
        }
        return false;
    }

    /**
     * @author Trent De Laney
     * @description Saves the application to Salesforce for Disabilities
     * @date 13 Dec 2018 at 11:41:36 am
     * @param appId application Id
     * @param hasDisabilities has Disabilities
     */
    @AuraEnabled
    public static void UpdateApplication(String appId, String hasDisabilities) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{appId,hasDisabilities})){
            return;
        } 
        List<Application__c> apps = [
                SELECT Id, HasDisabilities__c
                FROM Application__c
                WHERE Id = :appId
        ];

        if(apps.size() > 0 ){
            apps[0].HasDisabilities__c = hasDisabilities;
            update apps[0];
        }
    }

    /**
     * @author      Kristian Vegerano
     * @description Updates the application's Existing_Aus_disability_support__c field 
     * @param       appId application Id
     * @param       existingAusDisabilitySupport existing disability support
     *              String existingAusDisabilitySupport
     * @revision    2/07/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static void updateExistingAusDisabilitySupport(String appId, String existingAusDisabilitySupport) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{appId,existingAusDisabilitySupport})){
            return;
        } 
        //Check application record if does exist
        List<Application__c> apps = [SELECT Id
                                     FROM Application__c
                                     WHERE Id = :appId];

        //Update the application record's field if the record exists
        if(!apps.isEmpty()){
            apps[0].Existing_Aus_disability_support__c = existingAusDisabilitySupport;
            update apps[0];
        }
    }

    /**
     * @author Trent De Laney
     * @description Saves the applicants personal details to Salesforce. Returns a list of errors if there are any validation errors to be rendered to the user
     * @date 13 Dec 2018 at 11:39:56 am
     * @param updatedContact contact record
     * @param mfaRequired mfa required
     * @return List<String> errors
     */
    @AuraEnabled
    public static List<String> SavePersonalDetails(Contact updatedContact, String mfaRequired) {
        if (ExperienceAuthenticationServices.isUnsafe(mfaRequired)) {
            return new List<String>{ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT};
        }
        if (ExperienceAuthenticationServices.isUnsafe(updatedContact)) {
            return  new List<String>{ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT};
        }
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :currentUserId];

        List<String> errors = new List<String> ();
        Boolean updateUser = false; // MGROI-880 adding code for sanctioned countries
        if(!currentUser.Profile.Name.containsIgnoreCase('partner')){ //SFTG-2015 Validation disabled for Partners
            errors = ValidateMandatoryFields(updatedContact);            
            // only run when the user is meant to be MFA challenged        
            Boolean hasMyApp2FAPermission = FeatureManagement.checkPermission('MyApplication_Experience_2FA');
            
            //MGROI-880 adding code for sanctioned countries
            //check if user mobile number has changed and is from sanctioned country...
            if(updatedContact.MobilePhone != null) {
                List<String> compoundMobileNumber = updatedContact.MobilePhone.split(' ');
                String unverifiedMobileCountryCode = compoundMobileNumber[0];
                //... if new mobile is from sanctioned contry, ...
                if(new CountriesSelector().isSanctionedBySFDC(unverifiedMobileCountryCode)) {
                    //... remove mobile number in user therefore reseting mfaMobileVerification ...
                    currentUser.MobilePhone = null;
                    updateUser = true;
                    //... and do not require MFA
                    hasMyApp2FAPermission = false;
                }            
            }

            if(hasMyApp2FAPermission){
                // check if the user has registered mfa mobile number
                Map<String, Object> resultsMap = new Map<String, Object>();
                resultsMap = ExperienceMFAServices.retrieveCurrentUserDetails();
                Boolean hasRegisteredNumberMFA = (Boolean)resultsMap.get('HasVerified');
                if (!hasRegisteredNumberMFA && Boolean.valueOf(mfaRequired)) {
                    errors.add('Multi-Factor Authentication mobile number needs to be populated and verified');
                }
            }
        }
        if (errors.size() == 0) {
            // default disabilities to No
            if (String.isBlank(updatedContact.HasDisabilities__c)) {
                updatedContact.HasDisabilities__c = 'No';
            }
            // Use Salutation - updated to check for non empty Salutation before the assignment
            if(String.isBlank(updatedContact.Salutation_ERDA__c) && String.isNotBlank(updatedContact.Salutation)) {
                updatedContact.Salutation_ERDA__c = updatedContact.Salutation;
            }

            updatedContact = TranslateCitizenship(updatedContact);
            try{
                if(updateUser){
                    update currentUser;
                }
            update updatedContact;
            }catch(Exception exc){
                Nebula.Logger.error('PersonalDetailsController.SavePersonalDetails', exc);
                Nebula.Logger.saveLog();
            }
        }
        return errors;
    }

    /********************************************************
    HELPER FUNCTIONS
    ********************************************************/

    /**
     * @author Trent De Laney
     * @description Gets the current application that the applicant is filling out
     * @date 13 Dec 2018 at 10:31:13 am
     * @param applicationId application id
     * @return Application__c
     */
    private static Application__c GetCurrentApplication(String applicationId) {
        List<Application__c> apps = [
                SELECT Id, Applicant__c, HasDisabilities__c, Residency_Status__c, Campus_Location__c, Existing_Aus_disability_support__c,
                Criminal_History_Opt_In__c
                ,Disability_opt_in__c, Type_of_Study__c, Currently_residing_in_Malaysia__c, Malaysia_pass_expiry__c, 
                Malaysia_pass_type__c, Malaysian_NRIC_Passport__c
                FROM Application__c
                WHERE Id = :applicationId
        ];

        if(apps.size() > 0 ){
            return apps[0];
        }
        return null;
    }

    /**
     * @author Trent De Laney
     * @description Gets the current contact information which is relating to the application and associated information
     * @date 13 Dec 2018 at 10:35:56 am
     * @return Contact
     */
    private static Contact GetCurrentContact() {
        List<User> user = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if (user.size() > 0) {
            List<Contact> contacts = [
                    SELECT Id, Name, FirstName, Salutation, Personal_Email__c, LastName,
                            Birthdate, MailingStreet, MailingCity, MailingState,
                            MailingCountry, MailingPostalCode, Phone, HomePhone, Other_Given_Name__c,
                            Aboriginal_or_Torres_Strait_Islander__c,Country_Of_Birth__c,CountryOfBirth__c,
                            HasDisabilities__c, MobilePhone, Gender__c,Pronouns_V2__c,Preferred_Name__c,
                            Citizenship_Type_Description__c, Residency_Status__c, Previous_Firstname__c,
                            Previous_Surname__c, Previous_Monash_ID__c, Previously_Studied_at_Monash__c,
                            Previous_Monash_Institution__c, Person_ID_unique__c, Is_Mononymous_Name__c,
                            Salutation_ERDA__c, First_Name__c, Last_Name__c, Monash_Staff_ID__c 
                    FROM Contact
                    WHERE Id = :user[0].ContactId
            ];
            if (contacts.size() > 0) {
                return contacts[0];
            }
        }
        return null;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the contact record details from the id parameter
     * @param       contactId Contact record
     * @date        01/03/2021
     * @return      Contact
     */
    private static Contact GetCurrentContact(String contactId) {
        List<Contact> contacts = [
            SELECT Id, Name, FirstName, Salutation, Personal_Email__c, LastName,
                    Birthdate, MailingStreet, MailingCity, MailingState, Is_Mononymous_Name__c,
                    MailingCountry, MailingPostalCode, Phone, HomePhone, Other_Given_Name__c,
                    Aboriginal_or_Torres_Strait_Islander__c,Country_Of_Birth__c,CountryOfBirth__c,
                    HasDisabilities__c, MobilePhone, Gender__c,Pronouns_V2__c,Preferred_Name__c,
                    Citizenship_Type_Description__c, Residency_Status__c, Previous_Firstname__c,
                    Previous_Surname__c, Previous_Monash_ID__c, Previously_Studied_at_Monash__c,
                    Previous_Monash_Institution__c, Person_ID_unique__c, First_Name__c, Last_Name__c, Monash_Staff_ID__c 
            FROM Contact
            WHERE Id = :contactId
        ];
        if (contacts.size() > 0) {
            return contacts[0];
        }
        return null;
    }
    
    /**
     * @author Trent De Laney
     * @Revision Shalini Mendu 13 June 2022 - Update the previous application checking to include CANCELLED status
     * @description Checks to see if the applicant has a previously submitted application
     * @date 13 Dec 2018 at 11:38:43 am
     * @param contactId contact record
     * @return Boolean
     */
    private static Boolean CheckPreviousApplications(String contactId) {
        List<Contact> contacts = [
            SELECT Id
            FROM Contact
            WHERE Id = :contactId];

        if (contacts.size() > 0) {
            List<Application__c> apps = [
                SELECT Id
                FROM Application__c
                WHERE Applicant__c = :contacts[0].Id 
                AND Status__c IN (:MyApplicationUtilities.APP_SENT_SUBMITTED_STATUS ,
                                  :MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS,
                                  :MyApplicationUtilities.APP_SENT_REVIEW_STATUS,
                                  :MyApplicationUtilities.APP_PENDING_MERGE_STATUS,
                                  :MyApplicationUtilities.APP_CANCELLED_STATUS )];
                
        if (apps.size() > 0) {
            return true;
        }
    }

    return false;
    }

    /**
     * @author Trent De Laney
     * @description Gets the list of country options in a picklist <<TECHDEBT>> This should be moved to a library class so that it can be used across the platform
     * @date 13 Dec 2018 at 11:16:52 am
     * @return List<Map<String, String>>
     */
    private static List<Map<String, String>> GetCountryOptions() {
        return CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_ISO,true);
    }
    /**
     * @author Vinothraja
     * @description Gets the Gender options from Contact.Gender__c picklist
     * @date 04 Nov 2022
     * @return List<Map<String, String>>
     */
    private static List<Map<String, String>> getGenderOptions() {
        Map<String, String> mapGenderValues = CommonUtilities.getPicklistValues('Contact', 'Gender__c');
        List<Map<String, String>> options = new List<Map<String, String>> ();

        // add a blank value
        Map<String, String> blankOption = new Map<String, String>();
        blankOption.put(FIELD_VALUE, '');
        blankOption.put(FIELD_LABEL, 'Please select a value');
        options.add(blankOption);

        for (String gender : mapGenderValues.keySet()) {
            if (!EXCLUDED_GENDERS_FROM_MYAPP.contains(gender)){
                Map<String, String> mapOption = new Map<String, String>();
                mapOption.put(FIELD_VALUE, gender);
                mapOption.put(FIELD_LABEL, mapGenderValues.get(gender));
                options.add(mapOption);
            }
        }
        return options;
    }

    /**
     * @author Trent De Laney
     * @description Translates the Residency Status to a Domestic or International Classification
     * @date 13 Dec 2018 at 11:09:47 am
     * @param  c contact record
     * @return c contact
    */
    private static Contact TranslateCitizenship(Contact c) {
        if (MyApplicationUtilities.isDomestic(c.Residency_Status__c)) {
            c.Citizenship__c = 'DOMESTIC';
        } else {
            c.Citizenship__c = 'INTERNATIONAL';
        }
        return c;
    }

    /**
     * @author Trent De Laney
     * @description Validates the Mandatory Fields server side relating to the component
     * @date 13 Dec 2018 at 11:04:08 am
     * @Revision 
     * 13 Jun 2022 - Shalini Mendu - Make Salutation optional - remove the validation
     * 31 Aug 2022 - Vinothraja - Removed validation for First Name, to allow Mononymous names
     * @param c contact record
     * @return List<String> errors
     */
    public static List<String> ValidateMandatoryFields(Contact c) {
        List<String> errors = new List<String>();
        //return without validating if there is a previous submitted application
        List<Application__C> appList =  new List<Application__c> ([select name from Application__C where status__c  in ( :MyApplicationUtilities.APP_PENDING_MERGE_STATUS , :MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS, :MyApplicationUtilities.APP_SENT_SUBMITTED_STATUS, :MyApplicationUtilities.APP_SENT_REVIEW_STATUS ) and applicant__c = :c.Id]);
        if(appList.size()>0) 
        {
            return errors; 
        }

        if (String.isBlank(c.Last_Name__c)) {
            errors.add('Last Name needs to be populated');
        } else if (!Pattern.matches('[A-z \'-]*', c.Last_Name__c)) {
            errors.add('Only letters are allowed in the name fields');
        }
        if (!String.isBlank(c.First_Name__c) && !Pattern.matches('[A-z \'-]*', c.First_Name__c)) {
            errors.add('Only letters are allowed in the name fields');
        }
        if (c.Birthdate == null) {
            errors.add('Birthdate needs to be populated');
        }
        if(c.Birthdate >= Date.today().addYears(-10)){
            errors.add('Please ensure that your birthday selected over 10 years ago');
        }
        if (String.isBlank(c.Gender__c) || c.Gender__c.equalsIgnoreCase('U')) { // SFTG-2970 Make Gender mandatory (validates against blanks & the default 'U' when created)
            errors.add('Gender needs to be populated');
        }
        if (String.isBlank(c.HomePhone) && String.isBlank(c.MobilePhone)) {
            errors.add('Either of the two phone numbers need to be populated');
        }
        if (String.isBlank(c.Personal_Email__c) || EmailServices.isMonashEmail(c.Personal_Email__c)) {
            errors.add('Email needs to be populated and not a Monash provided email address');
        }
        if (String.isBlank(c.MailingStreet)) {
            errors.add('Street Address needs to be populated');
        }
        if (String.isBlank(c.MailingCity) && c.MailingCountry == 'Australia') {
            errors.add('City Address needs to be populated');
        }
        if (String.isBlank(c.MailingState) && c.MailingCountry == 'Australia') {
            errors.add('State needs to be populated');
        }
        if (String.isBlank(c.MailingPostalCode) && c.MailingCountry == 'Australia') {
            errors.add('Post code needs to be populated');
        }
        if (String.isBlank(c.MailingCountry) || c.MailingCountry == 'choose one...') {
            errors.add('Country needs to be populated');
        }
        if (c.Previously_Studied_at_Monash__c == true && !Pattern.matches('[0-9]*', c.Previous_Monash_ID__c)) {
            errors.add('Only numbers are allowed in this field');
        }

        return errors;
    }

    /**
     * @author          Kristian Vegerano
     * @description     Validates the previous monash id and birthdate and find a match for a current / previous student
     * @date            03/03/2020
     * @param           previousMonashId previous monash id
     * @param           applicantBirthDate applicant birth date
     * @return          String
     */
    @AuraEnabled
    public static String findMatchingStudent(String previousMonashId, String applicantBirthDate) {
        if (ExperienceAuthenticationServices.isUnsafe(new List<String>{previousMonashId,applicantBirthDate})) {
            return null;
        }
        //Initialize Variables
        String queryResult = 'NoMatch';

        //Query matching contact record
        if(previousMonashId != null && applicantBirthDate != null){
            queryResult = MyApplicationUtilities.findCurrentPreviousStudent(previousMonashId, Date.valueOf(applicantBirthDate));
        }

        return queryResult;
    }
    private static Map<String,String> unsafeUserInputMessage() {
        return ExperienceAuthenticationServices.userMessage(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }
    private static Map<String,String> unsafeParameterMessage() {
        return ExperienceAuthenticationServices.userMessage(ExperienceAuthenticationServices.RESULT_TYPE_ERROR,ExperienceAuthenticationServices.MESSAGE_UNSAFE_INPUT);
    }

      /**
     * @author          Shalini Mendu
     * @description     Return all the SAAC countries values 
     * @date            27/07/2023

     * @return          List<Map<String,String>> 
     */
    @AuraEnabled
    public static List<Map<String,String>> getCountryAttributes() {
        return CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_SAAC,true);
    }
    
    
    /**
	 * @author          Shalini Mendu
	 * @description     save Disability_Opt_In__c choice from aura
     * @param           appId application id
     * @param           disabilityConsent disability consent
	 * @date            27/09/2023
     */
     @AuraEnabled
    public static void saveApplicationDisabilityConsent(String appId, String disabilityConsent) {
        //Check application record if does exist
        List<Application__c> apps = [SELECT Id,Disability_Opt_In__c
                                     FROM Application__c
                                     WHERE Id = :appId];

        //Update the application record's field if the record exists
        if(!apps.isEmpty()){
            apps[0].Disability_Opt_In__c = disabilityConsent;
            update apps[0];
        }
    }

    /**
	 * @author          Davey YU
	 * @description     save Details for Malaysia Application
     * @param           appId application id
     * @param           malaysianPassport disability consent
     * @param           residingMalaysia boolean if residing in malaysia
     * @param           passExpiry malaysia passport expiry
     * @param           passType malaysia passport type
	 * @date            27/09/2023
     */
    @AuraEnabled
    public static void saveApplicationMalaysianDetails(String appId, String malaysianPassport, Boolean residingMalaysia, Date passExpiry, String passType) {
        //Check application record if does exist
    
        List<Application__c> apps = [SELECT Id,  Currently_residing_in_Malaysia__c, Malaysia_pass_expiry__c, 
        Malaysia_pass_type__c, Malaysian_NRIC_Passport__c FROM Application__c
                                     WHERE Id = :appId];

        //Update the application record's field if the record exists
        if(!apps.isEmpty()){
            apps[0].Malaysian_NRIC_Passport__c = malaysianPassport;
            apps[0].Currently_residing_in_Malaysia__c = residingMalaysia;
            apps[0].Malaysia_pass_expiry__c = residingMalaysia ? passExpiry : null;
            apps[0].Malaysia_pass_type__c = residingMalaysia ? passType : '';
            update apps[0];
        }
    }

    /**
	 * @author          Sethu Venna
	 * @description     check whether user logged in via SSO
     * @param           contactId 
     * @return          boolean - true if logged in via SSO else false
	 * @revision        created Sethu Venna  27/09/2024
     */
    @AuraEnabled
    public static boolean isSSOUser(String contactId) {
        return new MyAppWelcomeEmailController().isSSOUser(contactId);
    }
}