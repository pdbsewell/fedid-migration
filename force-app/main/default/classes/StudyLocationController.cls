/**
 * @author Trent De Laney
 * @group Admissions
 * @description Used to drive the Application Study Location Controller in my.app
 * @Revision 
 * 2018-12-18   Created
 * 2022-02-27   Shalini Mendu   SFTDC-236 Modified & refactored 
 * 2022-09-16   Vinothraja      SFTG-2866 Added code to fetch Qns based on each study type
 * 2023-02-28   Ken McGuire     ensure citizenship country refers to ISO / align with counry services
 * 2023-11-07   Vinothraja      SFTG-3632 Ensure Citizenship Country populated from External Systems are retained, and not blanked out  
 */
public with sharing class StudyLocationController {
    /********************************************************
    PROPERTIES
    ********************************************************/
    public static String FIELD_SAVE_STATUS = 'save_status';
    public static String FIELD_APPLICATION = 'application';
    public static String FIELD_COUNTRY_OPTIONS = 'countryOptions';
    public static String FIELD_RESIDENCY_OPTIONS = 'residencyOptions';
    public static String FIELD_VISA_OPTIONS = 'visaOptions';
    public static String FIELD_PREVIOUS_APPLICATIONS = 'previous_applications';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';
    public static String FIELD_CITIZENSHIP_ERRORS = 'citizenshipErrors';
    public static String FIELD_CONTACT = 'contact';
    public static String FIELD_CAMPUS_LOCATIONS = 'campusLocations';
    private static final String ISO_AUSTRALIA = 'Australia';
    private static final String ISO_INDONESIA = 'Indonesia';
    private static final String ISO_MALAYSIA = 'Malaysia';
    private static final String ISO_SOUTH_AFRICA = 'South Africa';
    private static final String ISO_NEW_ZEALAND = 'New Zealand';
    private static final String ISO_GRT = 'GRT';
    private static final String CONSTANT_DEFAULT = 'Default';
    private static final String RESIDENCY_STATUS_DOMESTIC = 'DOMESTIC';
    private static final String STATUS_SUBMITTED = 'Submitted';


    /********************************************************
    AURA FUNCTIONS
    ********************************************************/

    /**
     * @author Trent De Laney
     * @description Initial load of data to populate the component with information
     * @date 18 Dec 2018 at 1:21:50 pm
     * @param applicationId application Id
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> initDataLoad(String applicationId) {
        Map<String, Object> mapResults = new Map<String, Object>();

        //Current Application
        Application__c app = getApplicationById(applicationId);

        if(app != null){
            List<Contact> c = [
                    SELECT Id, Aboriginal_or_Torres_Strait_Islander__c, Residency_Status__c, Citizenship_Type_Description__c
                    FROM Contact
                    WHERE Id = :app.Applicant__c
            ];

            if (c.size() > 0) {
                mapResults.put(FIELD_CONTACT, c[0]);
            }

            // previous submitted applications
            List<Application__c> submittedApps = [
                    SELECT Id, Status__c
                    FROM Application__c
                    WHERE Status__c = 'Submitted'
                    AND Applicant__c = :app.Applicant__c
            ];

            mapResults.put(FIELD_PREVIOUS_APPLICATIONS, submittedApps.size());
            mapResults.put(FIELD_APPLICATION, app);
            mapResults.put(FIELD_RESIDENCY_OPTIONS, getFilteredResidencyOptions(app.Applicant__c, app));
        }
        // Retrieve the Citizenship Country from Application
        Map<String, String> mapExistingCountriesInApplication = new Map<String, String> ();
        if (app != null && String.isNotBlank(app.Citizenship_Country__c)) {
            mapExistingCountriesInApplication.put(app.Citizenship_Country__r.Country__c, app.Citizenship_Country__c);
        }
        // Align the picklist options map from CountryServices to point to the record Id used by External System
        mapResults.put(FIELD_COUNTRY_OPTIONS, getFilteredCountries(mapExistingCountriesInApplication));
        mapResults.put(FIELD_VISA_OPTIONS, getVisaTypeOptions());
        
        //Retrieve environment switch for campus location
        Map<String, Boolean> campusLocationSwitchMap = StudyLocationController.retrieveEnvironmentSettingFeature('CampusLocation');

        //Add campus location results as options
        List<Map<String, String>> campusLocationOptions = new List<Map<String, String>>();
        campusLocationOptions.add(new Map<String, String>{FIELD_VALUE => '', FIELD_LABEL => 'choose one...'});
        Map<String, String> campusLocationResults = MyApplicationUtilities.getPicklistOptionsMap('Campus_Location__c', 'Application__c');
        for(String loopCampusLocation : campusLocationResults.keySet()){
            //check if the campus location is available
            Boolean isAvailable = true;

            String valueWithRemovedWhiteSpace = loopCampusLocation.remove(' ');
            if(campusLocationSwitchMap.containsKey(valueWithRemovedWhiteSpace)){
                isAvailable = campusLocationSwitchMap.get(valueWithRemovedWhiteSpace);
            }

            if(isAvailable){
                Map<String, String> option = new Map<String, String>();
                option.put(FIELD_VALUE, loopCampusLocation);
                option.put(FIELD_LABEL, campusLocationResults.get(loopCampusLocation));
                campusLocationOptions.add(option);
            }
        }

        mapResults.put(FIELD_CAMPUS_LOCATIONS, campusLocationOptions);

        return mapResults;
    }

    /**
     * @author n/a
     * @description save application location
     * @date 18 Dec 2018 at 1:21:50 pm
     * @param appId application Id
     * @param campusLocation campus location
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> SaveApplicationLocation(String appId, String campusLocation) {
        Map<String, Object> values = new Map<String, Object>();

        User currentUser = getCurrentUser();
        UserRecordAccess ura = MyApplicationUtilities.getRecordAccessForUserByIds(appId, currentUser.Id);
        if (ura != null && ura.HasEditAccess) {
            List<Application__c> apps = [
                    SELECT Id, Applicant__c, Campus_Location__c, Type_of_Study__c
                    FROM Application__c
                    WHERE Id = :appId
            ];

            if (apps.size() > 0) {
                apps[0].Campus_Location__c = campusLocation;
                apps[0].Residency_Status__c = '';
                //clear Visa questions when on change
                apps[0] = clearVisaQuestions(apps[0]);
                update apps[0];

                values.put('application', apps[0]);
                values.put('options', getFilteredResidencyOptions(apps[0].Applicant__c, apps[0]));
                return values;
            }
        }
        throw new AuraHandledException('Unable to update application');
    }

    /********************************************************
    HELPER FUNCTIONS
    ********************************************************/


    /**
     * @author Trent De Laney
     * @description Gets the list of Residency Statuses and filters them based on selection of the Campus Location
     *              5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
     * @date 18 Dec 2018 at 1:22:21 pm
     * @param contactId contact record id
     * @param app application id
     * @return Map<String, List<Map<String, String>>>
     */
    private static Map<String, List<Map<String, String>>> getFilteredResidencyOptions(String contactId, Application__c app ) {
        Map<String, List<Map<String, String>>> filteredOptions = new Map<String, List<Map<String, String>>>();

        List<Map<String, String>> australianOptions = new List<Map<String, String>>();
        List<Map<String, String>> indonesianOptions = new List<Map<String, String>>();
        List<Map<String, String>> southAfricanOptions = new List<Map<String, String>>();
        List<Map<String, String>> malaysianOptions = new List<Map<String, String>>();
        List<Map<String, String>> graduateResearchOptions = new List<Map<String, String>>();


        List<Map<String, String>> options = getResidencyOptions(app);

        Boolean previousDomestic = false;
        if (!String.isEmpty(contactId)) {
            previousDomestic = PreviousDomesticCheck(contactId,app);
        }
        //Boolean previousDomestic = true;

        //Retrieve environment switch for residency status
        Map<String, Boolean> residencyStatusSwitchMap = StudyLocationController.retrieveEnvironmentSettingFeature('ResidencyStatus');
        List<Map<String,String>> residencySubStatusTypeOptions = getResidencySubStatusTypeOptions();

        for (Map<String, String> m : options) {
            //check if the campus location is available
            Boolean isAvailable = true;

            String valueWithRemovedWhiteSpace = m.get(FIELD_VALUE).remove('-');
            if(residencyStatusSwitchMap.containsKey(valueWithRemovedWhiteSpace)){
                isAvailable = residencyStatusSwitchMap.get(valueWithRemovedWhiteSpace);
            }

            if(isAvailable){
                switch on m.get(FIELD_VALUE) {
                    when 'DOM-AUS', 'DOM-NZ','DOM-PR','DOM-HV' {
                        australianOptions.add(m);
                    }
                    when 'INT-TEP' {
                        if (!previousDomestic) {
                            australianOptions.add(m);
                        }
                    }
                    when 'INT-SA','DOM-SA' {
                        southAfricanOptions.add(m);
                    }
                    when 'INT-SUN','INT-SUN-P' {
                        if (!previousDomestic){
                            malaysianOptions.add(m);
                        }
                    }
                    //5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
                    when 'DOM-IDN','DOM-IDN-PR','INT-IDN-P','INT-IDN' {
                        indonesianOptions.add(m);
                    }

                    when 'DOM-SUN' {
                        //SFTG-1944 handling of Residency Sub-statuses
                        for(Map<String, String> substatusOption : residencySubStatusTypeOptions) {
                            if (substatusOption.get(FIELD_VALUE).containsIgnoreCase('DOM-SUN')){
                                malaysianOptions.add(substatusOption);
                            }
                        }
                    }
                    when 'INTRNTNL' {
                        if (!previousDomestic) {
                            //SFTG-1944 handling of Residency Sub-statuses
                            for(Map<String, String> substatusOption : residencySubStatusTypeOptions) {
                                if (substatusOption.get(FIELD_VALUE).containsIgnoreCase('INTRNTNL')){
                                    australianOptions.add(substatusOption);
                                }
                            }
                        }
                    }
                 
                }
                if(app.Campus_Location__c == 'Australia'){
                    if(m.get(FIELD_VALUE) == 'DOM-AUS' || m.get(FIELD_VALUE) == 'DOM-NZ'
                    || m.get(FIELD_VALUE) == 'DOM-PR' || m.get(FIELD_VALUE) == 'INTRNTNL'){
                        graduateResearchOptions.add(m);
                    }
                }else if(app.Campus_Location__c == 'Malaysia'){
                    if(m.get(FIELD_VALUE) == 'DOM-AUS' || m.get(FIELD_VALUE) == 'DOM-NZ'
                    || m.get(FIELD_VALUE) == 'DOM-PR' || m.get(FIELD_VALUE) == 'DOM-SUN' || m.get(FIELD_VALUE) == 'INTRNTNL'){
                        graduateResearchOptions.add(m);
                    }
                }else if(app.Campus_Location__c == 'Indonesia'){
                    if(m.get(FIELD_VALUE) == 'DOM-AUS' || m.get(FIELD_VALUE) == 'DOM-NZ'
                    || m.get(FIELD_VALUE) == 'DOM-PR' || m.get(FIELD_VALUE) == 'DOM-IDN' || m.get(FIELD_VALUE) == 'DOM-IDN-PR' 
                    || m.get(FIELD_VALUE) == 'INTRNTNL'){
                        graduateResearchOptions.add(m);
                    }
                }
            }
        }

        graduateResearchOptions.sort(new residencyGRTComparator());

        filteredOptions.put(ISO_AUSTRALIA, australianOptions);
        filteredOptions.put(ISO_GRT, graduateResearchOptions);
        filteredOptions.put(ISO_INDONESIA, indonesianOptions);
        filteredOptions.put(ISO_MALAYSIA, malaysianOptions);
        filteredOptions.put(ISO_SOUTH_AFRICA, southAfricanOptions);

        return filteredOptions;
    }

    /**
     * @author Trent De Laney
     * @description Gets the currently logged in user and the associated contact information
     * @date 18 Dec 2018 at 1:25:14 pm
     * @return User
     */
    private static User getCurrentUser() {
        User currentUser = [
                SELECT Id, ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];
        return currentUser;
    }

    /**
     * @author Trent De Laney
     * @description Gets the Residency Status options for the application
     * @date 18 Dec 2018 at 1:28:23 pm
     * @return List<Map<String, String>>
     */
    private static List<Map<String, String>> getResidencyOptions(Application__c app) {
        Schema.DescribeFieldResult fieldResult = Application__c.Residency_Status__c.getDescribe();
        return populatePicklistAsOptions(fieldResult, app);

    }

    /**
     * @author Trent De Laney
     * @description Gets the information relating to the application for Study Location
     * @date 18 Dec 2018 at 1:29:01 pm
     * @param appId application id
     * @return Application__c
     */
    private static Application__c getApplicationById(Id appId) {
        List<Application__c> listApps = [
                SELECT Id,
                        Applicant__c,
                        Campus_Location__c,
                        Citizenship_Country__c,
                        Citizenship_Country__r.Callista_Country__c,
                        Citizenship_Country__r.Country__c,
                        Visa_Type__c,
                        Australian_Immigration_Office_Issued__c,
                        Visa_Number__c,
                        Passport_Number__c,
                        Visa_Start_Date__c,
                        Visa_End_Date__c,
                        Refused_entry_visa_to_any_country__c,
                        Breached_visa_condition__c,
                        Medical_health_prevent_visa__c,
                        Protection_visa_in_any_country__c,
                        Convicted_of_crime_offence__c,
                        Residency_Status__c,
                        Residency_Sub_status__c,
                        Student_Pass_Availability__c,
                        Criminal_History_Opt_In__c
                        ,Disability_opt_in__C, Type_of_Study__c,
                        PR_Application_Date__c,
                        Applied_For_Permanent_Residency__c
                        
                FROM Application__c
                WHERE Id = :appId
        ];
        if (listApps.size() == 1) {
            return listApps[0];
        }
        return null;
    }

    /**
     * @author Trent De Laney
     * @description Gets the country attributes which are required for the selection of Country
     * @date 18 Dec 2018 at 1:29:36 pm
     * @return List<Map<String, String>>
     */
    private static List<Map<String, String>> getCountryAttributes() {
        return CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_ISO,false);
    }
    /**
     * @author Vinothraja
     * @description Gets the country attributes which are required for the selection of Country, with some options preset
     * @param presentCountries Map of present countries
     * @return List<Map<String, String>>
     * @revision 
     * 2023-11-07   Created
     */
    private static List<Map<String, String>> getCountryAttributesWithPresetOptions(Map<String, String> presetCountries) {
        List<Map<String, String>> allOptions =  CountryServices.getCountryAttributeOptions(CountryServices.FORMAT_ISO,false);
        for (Map<String, String> isoCountry : allOptions) {
            if (presetCountries != null && presetCountries.containsKey(isoCountry.get(FIELD_LABEL))) {
                // populate the picklist option's value with the preset country's record Id
                isoCountry.put(FIELD_VALUE, presetCountries.get(isoCountry.get(FIELD_LABEL)));
            }
        }
        return allOptions;
    }

    /**
     * @author Trent De Laney
     * @description Filters the country selection based on the Campus Location for the application
     *              5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes - part of indonesian implementation
     * @param presetOptions Map of preset options
     * @return Map<String, List<Map<String, String>>>
     * @revision
     * 2018-12-18   Created
     * 2023-11-07   Added logic to generate picklist options for My.App, with certain countries preset 
     *              Primarily introduced for handling mismatch between CountryServices & APNG's reference data (obtained via MiX SOQL)
     *              more details in SFTG-3632
     */
    private static Map<String, List<Map<String, String>>> getFilteredCountries(Map<String, String> presetOptions) {
        List<Map<String, String>> allOptions = presetOptions == null || presetOptions.isEmpty() ?  getCountryAttributes() : getCountryAttributesWithPresetOptions(presetOptions);
        Map<String, List<Map<String, String>>> filteredOptions = new Map<String, List<Map<String, String>>>();

        List<Map<String, String>> australianOptions = new List<Map<String, String>>();
        List<Map<String, String>> southAfricanOptions = new List<Map<String, String>>();
        List<Map<String, String>> malaysianOptions = new List<Map<String, String>>();
        List<Map<String, String>> indonesiaOptions = new List<Map<String, String>>();

        for (Map<String, String> values : allOptions) {
            if (values.get(FIELD_LABEL) == ISO_AUSTRALIA) {
                southAfricanOptions.add(values);
                malaysianOptions.add(values);
                indonesiaOptions.add(values);
            } else if (values.get(FIELD_LABEL) == ISO_INDONESIA) {
                australianOptions.add(values);
                southAfricanOptions.add(values);
                malaysianOptions.add(values);
            } else if (values.get(FIELD_LABEL) == ISO_MALAYSIA) {
                australianOptions.add(values);
                southAfricanOptions.add(values);
                indonesiaOptions.add(values);
            } else if (values.get(FIELD_LABEL) == ISO_SOUTH_AFRICA) {
                australianOptions.add(values);
                malaysianOptions.add(values);
                indonesiaOptions.add(values);
            }
            else if(values.get(FIELD_LABEL) == ISO_NEW_ZEALAND){
                southAfricanOptions.add(values);
                malaysianOptions.add(values);
                indonesiaOptions.add(values);
            } else {
                australianOptions.add(values);
                malaysianOptions.add(values);
                southAfricanOptions.add(values);
                indonesiaOptions.add(values);
            }
        }

        filteredOptions.put(ISO_AUSTRALIA, australianOptions);
        filteredOptions.put(ISO_INDONESIA, indonesiaOptions);
        filteredOptions.put(ISO_MALAYSIA, malaysianOptions);
        filteredOptions.put(ISO_SOUTH_AFRICA, southAfricanOptions);
        filteredOptions.put(CONSTANT_DEFAULT, allOptions);

        return filteredOptions;
    }

    /**
     * @author Trent De Laney
     * @description Gets the Visa options which are selectable for the application
     * @date 18 Dec 2018 at 1:31:13 pm
     * @return List<Map<String, String>>
     */
    private static List<Map<String, String>> getVisaTypeOptions() {
        Schema.DescribeFieldResult fieldResult = Application__c.Visa_Type__c.getDescribe();
        return populatePicklistAsOptions(fieldResult, null);
    }

    /**
     * @author Vinothraja
     * @description Gets the Residency Sub-status options which are selectable for the application
     * @date 21 May 2021 
     * @return List<Map<String, String>>
     */
    private static List<Map<String, String>> getResidencySubStatusTypeOptions() {
        Schema.DescribeFieldResult fieldResult = Application__c.Residency_Sub_status__c.getDescribe();
        return populatePicklistAsOptions(fieldResult, null);// removed previous change
    }
    
    /**
     * @author Vinothraja
     * @description Gets the list of Residency Statuses and filters them based on selection of the Campus Location
     * @date 1 Jun 2021
     * @param campusLocation campus location string
     * @return List<Map<String, String>>
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCitizenshipTypes(String campusLocation){
        List<Map<String, String>> lstCitizenshipTypeOptions = new List<Map<String, String>> ();
        
        try {
            Application__c app = new Application__c(Campus_Location__c = campusLocation);
            String contactId = '';
            Map<String, List<Map<String, String>>> mapCitizenshipTypes = getFilteredResidencyOptions(contactId, app);
            lstCitizenshipTypeOptions = mapCitizenshipTypes.get(campusLocation);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return lstCitizenshipTypeOptions;
    }

    /**
     * @author Trent De Laney
     * @description Checks to see if the applicant was previously a Domestic applicant based on the selection of Campus Location and Residency Status
     * @date 18 Dec 2018 at 1:20:14 pm
     * @param contactId contact record id
     * @return Boolean
     */
    public static Boolean PreviousDomesticCheck(String contactId, Application__c app) {
        Map<String, Map<String, String>> citizenshipTypes = MyApplicationUtilities.getDynamicCitizenship();

        /* SFTM-274 KL, this statement replaced with the one below, additional WHERE clause condition to only consider 'Submitted' application records
        List<Application__c> apps = [
                SELECT Campus_Location__c, Residency_Status__c
                FROM Application__c
                WHERE Applicant__c = :contactId
        ];
        */
        
        List<Application__c> apps = [
                SELECT Campus_Location__c, Residency_Status__c, Status__c
                FROM Application__c
                WHERE Applicant__c = :contactId
                AND Status__c = :STATUS_SUBMITTED
        ];


        if (apps.size() > 0) {
            for (Application__c a : apps) {
                if (a.Campus_Location__c != null) {
                    Map<String, String> values = citizenshipTypes.get(a.Campus_Location__c);
                    if (values.get(a.Residency_Status__c) == RESIDENCY_STATUS_DOMESTIC && a.Campus_Location__c == app.Campus_Location__c) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
    * @author ???
    * @description Defaults the selected country on the UI after Citizenship type is selected
    *              5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
    * @date ???
    * @paramn applicationId application id
    * @param citizenshipCode citizenship code
    * @return Application__c
    */
    @AuraEnabled
    public static Application__c SaveApplicationCitizenship(String applicationId, String citizenshipCode) {
        List<Application__c> apps = [
                SELECT Id, Residency_Status__c, Residency_Sub_Status__c, Citizenship_Country__c, Type_Of_Study__c, Agent__c
                FROM Application__c
                WHERE Id = :applicationId
        ];

        if (apps.size() > 0) {
            Application__c app = apps[0];
            app.Residency_Status__c = citizenshipCode;
            //If Australian Citizen, default the country
            if (app.Residency_Status__c == 'DOM-AUS') {
                //Lookup the country
                app.Citizenship_Country__c = CountryServices.getCountryId(ISO_AUSTRALIA);
                app.Residency_Sub_Status__c = '';
            } else if (app.Residency_Status__c == 'DOM-IDN' || app.Residency_Status__c == 'DOM-IDN-PR') {
                //5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
                //Lookup the country
                app.Citizenship_Country__c = CountryServices.getCountryId(ISO_INDONESIA);
            } else if (app.Residency_Status__c == 'DOM-SUN.A' || app.Residency_Status__c == 'DOM-SUN.B') { //SFTG-1944 handling of Residency Sub Statuses
                app.Residency_Sub_Status__c = app.Residency_Status__c;
                app.Residency_Status__c = 'DOM-SUN';
                app.Student_Pass_Availability__c = '';
                if (app.Residency_Sub_Status__c == 'DOM-SUN.A') {
                    //Lookup the country
                    app.Citizenship_Country__c = CountryServices.getCountryId(ISO_MALAYSIA);
                } else {
                    app.Citizenship_Country__c = null;
                }
            } else if (app.Residency_Status__c == 'INT-SUN' || app.Residency_Status__c == 'INT-SUN-P') {
                app.Residency_Sub_Status__c = '';
                app.Citizenship_Country__c = null;
                app.Student_Pass_Availability__c = '';
            } else if (app.Residency_Status__c == 'INTRNTNL.A' || app.Residency_Status__c == 'INTRNTNL.B'|| app.Residency_Status__c == 'INTRNTNL.O') { //SFTG-1944 handling of Residency Sub Statuses //SFTG-3859 NTRNTNL.O offshore online
                app.Residency_Sub_Status__c = app.Residency_Status__c;
                app.Residency_Status__c = 'INTRNTNL';
                app.Citizenship_Country__c = null;
            } else if (app.Residency_Status__c == 'DOM-SUN') {
                app.Citizenship_Country__c = CountryServices.getCountryId(ISO_MALAYSIA);
            }else {
                //Otherwise set it to blank
                app.Residency_Sub_Status__c = '';
                app.Citizenship_Country__c = null;
            }
            //clear Visa questions when on change
            app = clearVisaQuestions(app);
            //clear Agent when on change
            if(app.Type_Of_Study__c == 'Graduate Research') {
                app = clearAgent(app);
            }            
            update app;
            return app;
        }

        throw new AuraHandledException('Unable to update the application');
    }
    /**
     * @author Vinothraja
     * @description Helper service for converting Residency Sub-status options to Callista allowed Residency Statuses for the application
     * @date 2 Jun 2021 
     * @param application application record
     */
    public static void setResidencySubStatuses(Application__c application) {
        if (application.Residency_Status__c == 'INTRNTNL.A' || application.Residency_Status__c == 'INTRNTNL.B'|| application.Residency_Status__c == 'INTRNTNL.O') { //SFTG-1944 handling of Residency Sub Statuses
            application.Residency_Sub_Status__c = application.Residency_Status__c;
            application.Residency_Status__c = 'INTRNTNL';
        } else if (application.Residency_Status__c == 'DOM-SUN.A' || application.Residency_Status__c == 'DOM-SUN.B') { //SFTG-1944 handling of Residency Sub Statuses
            application.Residency_Sub_Status__c = application.Residency_Status__c;
            application.Residency_Status__c = 'DOM-SUN';
        } else {
            application.Residency_Sub_Status__c = '';
        }
    }
    /**
     * @author Vinothraja
     * @description Helper service for setting Country of Citizenship for the application based on the citizenship of the Applicant
     * @date 2 Jun 2021 
     * @param application application record
     */
    public static void setCountryOfCitizenship(Application__c application) {
        //If Australian Citizen, default the country to Australia
        if (application.Residency_Status__c == 'DOM-AUS') {

            application.Residency_Sub_Status__c = '';
            application.Citizenship_Country__c = CountryServices.getCountryId(ISO_AUSTRALIA);
        }else if (application.Residency_Status__c == 'DOM-IDN') {
            //5/2/2021 KV - SFTG-1713 - Added Indonesian citizenship residency codes
            //Lookup the country
            application.Citizenship_Country__c = CountryServices.getCountryId(ISO_INDONESIA);            
        }
        //If Malaysian Citizen, default the country to Malaysia
        if (application.Residency_Status__c == 'DOM-SUN' && application.Residency_Sub_Status__c == 'DOM-SUN.A') {
            application.Citizenship_Country__c = CountryServices.getCountryId(ISO_MALAYSIA);
        }
    }
    
    /**
     * @author SMendu
     * @description Saving Residencystatus/citizenship and DisabilityOpt In selection 
     * @date 2017
     * @Revision 24 Jan 2024 - Updating with comments
     * @param application application record
     */
    @AuraEnabled
    public static Map<String, Object> saveCitizenshipQuestions(Application__c application) {
        Map<String, Object> mapResults = new Map<String, Object>();
        //Query Application record from the database 
        //application - has stale Disability_Opt_In__c if the applicant navigates to another link and comes back to this page
        //instead of using Save and Continue button. We must retrieve the value from the database and save the whole Application to avoid override
        Application__C queryApplication = [select Disability_Opt_In__c from Application__C where id=:application.Id];
        //Update Application record field if it is updated and not followed by clicking on Save Continue 
        application.Disability_Opt_In__c = queryApplication.Disability_Opt_In__c;
        setResidencySubStatuses(application);
        setCountryOfCitizenship(application);
        update application;
        
        // need to re-query the app, or the citizenship will not be available
        Application__c app = [
                SELECT Id,
                        Citizenship_Country__c,
                        Visa_Type__c,
                        Australian_Immigration_Office_Issued__c,
                        Visa_Number__c, Passport_Number__c, Visa_Start_Date__c, Visa_End_Date__c, Residency_Status__c, Residency_Sub_Status__c,
                        Refused_entry_visa_to_any_country__c,
                        Breached_visa_condition__c,
                        Medical_health_prevent_visa__c,
                        Protection_visa_in_any_country__c,
                        Criminal_History_Opt_In__c
                        ,Disability_opt_in__C,
                        Convicted_of_crime_offence__c, Campus_Location__c, Student_Pass_Availability__c, Type_of_Study__c,
                        PR_Application_Date__c, Applied_For_Permanent_Residency__c
                FROM Application__c
                WHERE Id = :application.Id
    ];

        // get any errors using the app declaration validation
        List<String> errorMessages = AppDeclarationFormCC.validateCitizenshipSection(app);
        if (errorMessages.size() > 0) {
            mapResults.put(FIELD_CITIZENSHIP_ERRORS, errorMessages);
        }

        return mapResults;
    }

    /**
     * Helper function to populate Schema picklist as drowdown options
     *
     * @param fieldResult
     *
     * @return
     */
    private static List<Map<String, String>> populatePicklistAsOptions(Schema.DescribeFieldResult fieldResult, Application__c app) {
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String, String>> options = new List<Map<String, String>> ();
        for (Schema.PicklistEntry f : ple) {
            Map<String, String> mapOption = new Map<String, String>();
            mapOption.put(FIELD_VALUE, f.getValue());
            if(app != null && app.Type_of_Study__c == 'Graduate Research' && f.getValue() == 'INTRNTNL'){
                mapOption.put(FIELD_LABEL, 'Other Nationality');
            }else{
                mapOption.put(FIELD_LABEL, f.getLabel());
            }

            options.add(mapOption);
        }
        return options;
    }

    /**
     * @author Trent De Laney
     * @description Checks if there are any ACPs relating to this application
     * @date 18 Dec 2018 at 12:41:03 pm
     * @param appId application id
     * @return Boolean
     */
    @AuraEnabled
    public static Boolean CheckACP(String appId) {
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
     * @description Removes the Application ACPs when the user changes their study location. To ensure applications are completed with the single study location.
     * @date 13 Dec 2018 at 3:28:38 pm
     * @param appId application id
     */
    @AuraEnabled
    public static void RemoveApplicationACPs(String appId) {
        List<Application_Course_Preference__c> prefs = [
                SELECT Id, Application__c
                FROM Application_Course_Preference__c
                WHERE Application__c = :appId
        ];

        if (prefs.size() > 0) {
            delete prefs;
        }
    }

    /**
  * @author Trent De Laney
  * @description Used to Wipe Visa questions from the Application
  * @date 22 Feb 2019 at 2:28:06 pm
  * @param app application record
  * Refactored - SMen - 27/02
  */
    private static Application__c clearVisaQuestions(Application__c app) {
            app.Visa_Type__c = '';
            app.Australian_Immigration_Office_Issued__c = '';
            app.Visa_Number__c = '';
            app.Passport_Number__c = '';
            app.Visa_Start_Date__c = null;
            app.Visa_End_Date__c = null;
            app.Refused_entry_visa_to_any_country__c = null;
            app.Breached_visa_condition__c = null;
            app.Medical_health_prevent_visa__c = null;
            app.Protection_visa_in_any_country__c = null;
            app.Convicted_of_crime_offence__c = null;
            return app;
        }
        
    /**
     * Helper function to retrieve the proper environment settings
     * @param featureSwitch   
     * @return Map<String, Boolean> key of the option and value of active or not
     */
    public static Map<String, Boolean> retrieveEnvironmentSettingFeature(String featureSwitch) {
        //Retrieve environment switch for campus location
        Map<String, Boolean> environmentSwitchMap = new Map<String, Boolean>();
        
        Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
        for(String fieldDeveloperName : environmentSettings.getPopulatedFieldsAsMap().keySet()){
            List<String> fieldDetails = fieldDeveloperName.split('_');
            if(fieldDetails[0] == featureSwitch){
                environmentSwitchMap.put(fieldDetails[1], (Boolean)environmentSettings.getPopulatedFieldsAsMap().get(fieldDeveloperName));
            }
        }

        return environmentSwitchMap;
    }

   
     /**
     * @description Helper function to retrieve study type options from Environment_Settings__c cs
     * @param featureSwitch   
     * @return Map<String, List<String>> key of the option and value of the country config
     */
    public static Map<String, List<String>> retrieveStudyTypeMap(String featureSwitch) {
        //Retrieve environment switch for campus location
        Map<String, List<String>> studyTypeMap = new Map<String, List<String>>();
        
        Environment_Settings__c environmentSettings = Environment_Settings__c.getOrgDefaults();
        for(String fieldDeveloperName : environmentSettings.getPopulatedFieldsAsMap().keySet()){
            List<String> fieldDetails = fieldDeveloperName.split('_');
         
            if(fieldDetails[0] == featureSwitch){
                String val = (String)environmentSettings.getPopulatedFieldsAsMap().get(fieldDeveloperName);
                List<String> studyTypes = val.split(',');
                studyTypeMap.put(fieldDetails[1], studyTypes);
            }
        }
        return studyTypeMap;
    }
     /**
     * @description Helper function to retrieve study type questions from Constants
     * @param studyTypeMap   
     * @return Map<String, Map<String,List<String>>> the questions for each of its Study Types for every Campus Location
     * for ex. 'Australia' => {'StudyAbroad' => {'Are you X?', 'Will you do Y?'}}
     */
    public static Map<String, Map<String, List<String>>> retrieveStudyTypeQuestionsMap(Map<String, List<String>> studyTypeMap) {
        Map<String, Map<String, List<String>>> studyTypeQuestionsMap = new Map<String, Map<String, List<String>>> ();
        for(String studyLocation : studyTypeMap.keySet()){
            Map<String, List<String>> mapStudyTypeQuestions = new Map<String, List<String>> ();
            for (String studyType : studyTypeMap.get(studyLocation)) {
                mapStudyTypeQuestions.put(studyType, Constants.MY_APP_STUDYTYPE_QUESTIONS.get(studyType));
            }
            studyTypeQuestionsMap.put(studyLocation, mapStudyTypeQuestions);
        }
        return studyTypeQuestionsMap;
    }
    
    // Custom comparator class
    public class residencyGRTComparator implements Comparator<Object>{
        // Predefined order list
       private final List<String> predefinedOrder = new List<String>{
           'DOM-AUS', 'DOM-PR', 'DOM-NZ', 'DOM-SUN', 'DOM-IDN', 'DOM-IDN-PR', 'INTRNTNL'
       };

       public Integer compare(Object obj1, Object obj2) {
           Map<String, String> map1 = (Map<String, String>) obj1;
           Map<String, String> map2 = (Map<String, String>) obj2;

           // Extract values for comparison
           String name1 = map1.get('value');
           String name2 = map2.get('value');
           
           // Get index in predefined order list
           Integer index1 = predefinedOrder.indexOf(name1);
           Integer index2 = predefinedOrder.indexOf(name2);

           // If the name is not found in predefinedOrder, treat it as the end of the list
           if (index1 == -1) index1 = predefinedOrder.size();
           if (index2 == -1) index2 = predefinedOrder.size();

           // Compare based on the predefined order
           return index1 - index2;
       }
   }

    /* @description Used to Wipe Agency from the Application
    * @param app 
    * @return Application__c
    */
    private static Application__c clearAgent(Application__c app) {
        app.Agent__c = null;
        app.Agent_Org_Unit_Code__c = '';
        app.Agent_Staff_Email__c = '';
        app.Agent_Staff_Details__c = '';
        app.Applicant_Agent__c = '';
        app.Furthest_Progress__c = 'Personal Details';
        return app;
    }
}