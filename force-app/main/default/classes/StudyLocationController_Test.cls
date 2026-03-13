/**
 * @description Test class for StudyLocationController
 * @group       Admissions
 * @Revision 
 * 2018-12-18   Created
 * 2024-07-17   updated updated the degree selector options for my.app
 */
//APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User
@isTest(isParallel=false)
public class StudyLocationController_Test {
    
   @TestSetup
   static void createData(){
        //Turn on environment settings - Exploding Leads Active
        Environment_Settings__c envSettings = new Environment_Settings__c();
        envSettings.CampusLocation_Australia__c = true;
        envSettings.CampusLocation_Australia__c = true;
        envSettings.CampusLocation_Australia__c = true;
        envSettings.StudyType_Australia__c = 'Coursework, Exchange';
        envSettings.StudyType_Malaysia__c = 'Coursework';
        envSettings.StudyType_Indonesia__c = 'Coursework'; 
        envSettings.StudyType_China__c = 'Graduate Research'; 
        envSettings.ResidencyStatus_DOMAUS__c =true;
        insert envSettings;
        //Insert test countries
        List<Country_Attribute__c> countriesList = new List<Country_Attribute__c>();
        Country_Attribute__c malaysia = new Country_Attribute__c(Name = 'MALAYSIA',
                                                                 Callista_Code__c = '5203',
                                                                 Country__c = 'Malaysia');
        countriesList.add(malaysia);
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        countriesList.add(australia);   
        Country_Attribute__c newZealand = new Country_Attribute__c(Name = 'NEW ZEALAND',
                                                                   Callista_Code__c = '1201',
                                                                   Country__c = 'New Zealand');
        countriesList.add(newZealand);             
        insert countriesList;        

   }

   /**
     * @author      unknown
     * @description Tests creating for the apex class StudyLocationController
     * @revision    17/07/24 updated
     *
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app
     * THEN system shoud show no existing application to the student
     */
    @isTest
    public static void test_NoApplication() {
        Contact c = new Contact();
        c.FirstName = 'Tester';
        c.LastName = 'Tester';
        insert c;

        Test.startTest();
        Map<String, Object> mapResults = StudyLocationController.initDataLoad(c.Id);
        Application__c appResult = (Application__c) mapResults.get(StudyLocationController.FIELD_APPLICATION);
        Assert.areEqual(null, appResult, 'No Application found for a bad Id');

        Test.stopTest();
    }

     /**
     * @description test_initDataLoad
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app
     * THEN system shoud show Australia as country
     */
    @IsTest
    public static void test_initDataLoad() {
        User applicant = StudFirst_TestHelper.createCommunityUser();

        Application__c app = StudFirst_TestHelper.createApplication(applicant.ContactId);
        app.Applicant__c = applicant.ContactId;
        app.Campus_Location__c = 'Australia';
        insert app;
       

        // insert a country object
        Country_Attribute__c countryAttribute = new Country_Attribute__c();
        countryAttribute.Country__c = 'Australia';
        insert countryAttribute;

        Test.startTest();
        System.runAs(applicant) {
            Map<String, Object> mapResults = StudyLocationController.initDataLoad(app.Id);
            Application__c appResult = (Application__c) mapResults.get(StudyLocationController.FIELD_APPLICATION);
            Assert.areEqual(app.Id, appResult.Id);

            Map<String, List<Map<String, String>>> countryOptions = (Map<String, List<Map<String, String>>>) mapResults.get(StudyLocationController.FIELD_COUNTRY_OPTIONS);
            Assert.areNotEqual(countryOptions.size(), 0, 'Country Options should be returned');
            Assert.areEqual(false, StudyLocationController.CheckACP(app.Id));
            StudyLocationController.RemoveApplicationACPs(app.Id);
            Assert.areEqual(0,[SELECT Id, Application__c FROM Application_Course_Preference__c WHERE Application__c = :app.Id].size());

        }
        Test.stopTest();

    }

    /**
     * @author      Kristian Vegerano
     * @description Tests initIndonesia method
     *              Test initializing the page for the application page with the campus location as indonesia
     *              Validates that application details are returned properly
     * @revision    25/02/2021 - Kristian Vegerano - Created
     * 
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app
     * THEN system shoud show Indonesia as country
     *
     */
    @IsTest
    public static void test_initIndonesia() {
        User applicant = StudFirst_TestHelper.createCommunityUser();

        Application__c app = StudFirst_TestHelper.createApplication(applicant.ContactId);
        app.Applicant__c = applicant.ContactId;
        app.Campus_Location__c = 'Indonesia';
        insert app;

        // insert a country object
        Country_Attribute__c countryAttribute = new Country_Attribute__c();
        countryAttribute.Country__c = 'Indonesia';
        insert countryAttribute;

        Test.startTest();
        System.runAs(applicant) {
            Map<String, Object> mapResults = StudyLocationController.initDataLoad(app.Id);
            Application__c appResult = (Application__c) mapResults.get(StudyLocationController.FIELD_APPLICATION);
            Assert.areEqual(app.Id, appResult.Id);

            Map<String, List<Map<String, String>>> countryOptions = (Map<String, List<Map<String, String>>>) mapResults.get(StudyLocationController.FIELD_COUNTRY_OPTIONS);
            Assert.areNotEqual(countryOptions.size(), 0, 'Country Options should be returned');
        }
        Test.stopTest();
    }

    /**
     * @description test_SaveApplicationLocation
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app
     * THEN system shoud show Australia as campus location
     */
    TestMethod
    public static void test_SaveApplicationLocation() {
        User applicant = StudFirst_TestHelper.createCommunityUser();

        Application__c app = new Application__c();
        app.Applicant__c = applicant.ContactId;
        insert app;

        Test.startTest();
        System.runAs(applicant) {
            String location = 'Australia';
            StudyLocationController.SaveApplicationLocation(app.Id, location);
            Application__c appResult = [SELECT id, Campus_Location__c FROM Application__c WHERE id = :app.Id];

            Assert.areEqual(location, appResult.Campus_Location__c);
        }
        Test.stopTest();
    }

    /**
     * @description test_SaveApplicationCitizenshipDomestic
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app and they have an application to proceed with
     * THEN system shoud show visa/citizenship options as domestic
     */
    @IsTest
    public static void test_SaveApplicationCitizenshipDomestic() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Application__c app = new Application__c();
        app.Applicant__c = applicant.ContactId;
        insert app;

        Test.startTest();
        System.runAs(applicant) {
            String citizenship = 'DOM-NZ';
            StudyLocationController.SaveApplicationCitizenship(app.Id, citizenship);
            Application__c newApp = [SELECT Id, Residency_Status__c FROM Application__c WHERE Id = :app.Id];
            Assert.areEqual(citizenship, newApp.Residency_Status__c, 'Residency should be updated');
        }
        Test.stopTest();
    }

    /**
     * @description test_SaveApplicationCitizenshipInternational
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app and they have an application to proceed with
     * THEN system shoud show visa/citizenship options as international
     */
    @IsTest
    public static void test_SaveApplicationCitizenshipInternational() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Application__c app = new Application__c();
        app.Applicant__c = applicant.ContactId;
        insert app;

        Test.startTest();
        System.runAs(applicant) {
            String citizenship = 'INT-TEP';
            StudyLocationController.SaveApplicationCitizenship(app.Id, citizenship);
            Application__c newApp = [SELECT Id, Residency_Status__c FROM Application__c WHERE Id = :app.Id];

            Assert.areEqual(citizenship, newApp.Residency_Status__c, 'Residency should be updated');
        }
        Test.stopTest();
    }

    /**
     * @description test_SaveApplicationCitizenshipNull
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app and they have an application to proceed with and upon changing the citizenshipn type
     * THEN system shoud clear the Residency status
     */
    @IsTest
    public static void test_SaveApplicationCitizenshipNull() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Application__c app = new Application__c();
        app.Applicant__c = applicant.ContactId;
        insert app;

        Test.startTest();
        System.runAs(applicant) {
            String citizenship = '';
            StudyLocationController.SaveApplicationCitizenship(app.Id, citizenship);
            Application__c newApp = [SELECT Id, Residency_Status__c FROM Application__c WHERE Id = :app.Id];

            Assert.areEqual(null, newApp.Residency_Status__c, 'Residency should be cleared');
        }
        Test.stopTest();
    }

    /**
     * @description test_SaveApplicationCitizenshipAgentBlank
     * GIVEN a new student is registered for my.app
     * WHEN student is logged in to my.app and they have a GR application to proceed with and upon changing the citizenshipn type
     * THEN system shoud clear the Agent
     */
    @IsTest
    public static void test_SaveApplicationCitizenshipAgentBlank() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Application__c app = new Application__c();
        app.Applicant__c = applicant.ContactId;
        app.Applicant_Agent__c = 'Yes';
        app.Type_Of_Study__c = 'Graduate Research';
        app.Agent_Staff_Email__c = 'testagentemail@test.com';
        insert app;

        Test.startTest();
        System.runAs(applicant) {
            String citizenship = '';
            StudyLocationController.SaveApplicationCitizenship(app.Id, citizenship);
            Application__c newApp = [SELECT Id, Applicant_Agent__c FROM Application__c WHERE Id = :app.Id];

            Assert.areEqual(null, newApp.Applicant_Agent__c, 'Agency should be cleared');
        }
        Test.stopTest();
    }

    /**
     * @description test_SaveCitizenshipQuestionsErrors
     * GIVEN a student is logged in to my.app and they have an application to proceed with
     * WHEN they try to save citizenship without entering anything
     * THEN system shoud show errors for citizenship questions
     */
    @IsTest
    public static void test_SaveCitizenshipQuestionsErrors() {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Application__c app = new Application__c();
        app.Applicant__c = applicant.ContactId;
        insert app;

        Test.startTest();
        System.runAs(applicant) {
            Map<String, Object> mapResults = StudyLocationController.SaveCitizenshipQuestions(app);
            List<String> listErrors = (List<String>) mapResults.get(StudyLocationController.FIELD_CITIZENSHIP_ERRORS);
            Assert.areNotEqual(listErrors.size(), 0, 'Errors should be returned for citizenship questions');

        }
        Test.stopTest();
    }

    /**
     * @description test_SaveCitizenshipQuestionsNoErrors
     * GIVEN a student is logged in to my.app and they have an application to proceed with
     * WHEN they try to save citizenship with the required info
     * THEN system shoud show not show any errors for citizenship questions
     */
    @IsTest
    public static void test_SaveCitizenshipQuestionsNoErrors() {
        User userApplicant = StudFirst_TestHelper.createCommunityUser();

        Contact conApplicant = [
                SELECT Id, Residency_Status__c
                FROM CONTACT
                WHERE id = :userApplicant.ContactId
        ];
        conApplicant.Residency_Status__c = AppDeclarationFormCC.DOMESTIC_AUS;
        update conApplicant;

        Application__c app = new Application__c();
        app.Applicant__c = conApplicant.Id;
        app.Refused_entry_visa_to_any_country__c = 'No';
        app.Breached_visa_condition__c = 'No';
        app.Medical_health_prevent_visa__c = 'No';
        app.Protection_visa_in_any_country__c = 'No';
        app.Convicted_of_crime_offence__c = 'No';
        app.Residency_Status__c = 'DOM-AUS';
        app.Disability_Opt_In__c = 'Yes';
        insert app;

        Test.startTest();
        System.runAs(userApplicant) {
            //replicate update
            app.Disability_Opt_In__c = 'No';
            Map<String, Object> mapResults = StudyLocationController.SaveCitizenshipQuestions(app);
            List<String> listErrors = (List<String>) mapResults.get(StudyLocationController.FIELD_CITIZENSHIP_ERRORS);
            Assert.areEqual(null, listErrors, 'No errors should be returned for citizenship questions ' + listErrors);
            Assert.areEqual('Yes', [Select Disability_Opt_In__c from Application__c where id=:app.id].Disability_Opt_In__c, 'Disability_Opt_In__c must be Yes');
        }
        Test.stopTest();
    }
    
    /**
     * @author     Shalini Mendu
     * @description Test to validate custom settings configuration for Monash Abroad
     * @revision    12/03/2021 -   Shalini Mendu - Created
     * 16/09/2022 - Vinothraja  -   SFTG-2866 Added code to fetch Qns based on each study type
     * 17/07/2024 - Vishal Gupta  - change the study type options for degree selector 
     */
    @isTest
    public static void testEnvironmSettingsConfig()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        Test.startTest();
        System.runAs(applicant) {
        Map<String, List<String>> retStMap = StudyLocationController.retrieveStudyTypeMap('StudyType');
        System.assertEquals(retStMap.get('Australia').size(), 2 );
        
        Map<String, Map<String, List<String>>> retStMapQns = StudyLocationController.retrieveStudyTypeQuestionsMap(retStMap);
        System.assertEquals(retStMapQns.get('Australia').get('Coursework').size(), 4 );

        Map<String, Boolean> retLocMap = StudyLocationController.retrieveEnvironmentSettingFeature('CampusLocation');
        System.assertEquals(retLocMap.get('Australia'), true );
        }
        Test.stopTest();
    }

    /**
     * @author      Vinothraja
     * @description Test getCitizenShipTypes 
     * @revision    03/06/2021 - Created
     */
    @isTest
    public static void testGetCitizenshipTypes()
    {
        User applicant = StudFirst_TestHelper.createCommunityUser();
        List<Map<String, String>> lstOptions = null;
        Test.startTest();
        System.runAs(applicant) {
            lstOptions = StudyLocationController.getCitizenshipTypes('Australia');  
        }
        Test.stopTest();
        // Should fetch Residency Status + Residency sub Status options
        Assert.areEqual(1, lstOptions.size(), 'Residency_status__c picklist options for Australia not fetched properly');
    }

    /**
     * @author      Vinothraja
     * @description Test getCitizenShipTypes
     * @revision    03/06/2021 - Created
     * GIVEN a student is logged in to my.app and they have an application to proceed with
     * WHEN students save tge citizenship type on the screen
     * THEN it shoud be saved successfully in the system  
     */
    @isTest
    public static void test_SaveApplicationCitizenshipDefaults()
    {
        User userApplicant = StudFirst_TestHelper.createCommunityUser();

        Contact conApplicant = [
                SELECT Id, Residency_Status__c
                FROM CONTACT
                WHERE id = :userApplicant.ContactId
        ];
        conApplicant.Residency_Status__c = AppDeclarationFormCC.DOMESTIC_AUS;
        update conApplicant;

        Application__c app = new Application__c();
        app.Applicant__c = conApplicant.Id;
        app.Refused_entry_visa_to_any_country__c = 'No';
        app.Breached_visa_condition__c = 'No';
        app.Medical_health_prevent_visa__c = 'No';
        app.Protection_visa_in_any_country__c = 'No';
        app.Convicted_of_crime_offence__c = 'No';
        app.Residency_Status__c = 'DOM-AUS';
        insert app;

        Test.startTest();
        System.runAs(userApplicant) {
            //Australin Citizen check
            app = StudyLocationController.SaveApplicationCitizenship(''+app.id, 'DOM-AUS');
            update app;
            Application__c updatedApp = [SELECT id, Residency_status__c, Residency_sub_status__c, Citizenship_Country__c FROM Application__c WHERE id = :app.id LIMIT 1];
            Country_Attribute__c australia = [SELECT id FROM Country_Attribute__c WHERE Country__c = 'Australia' LIMIT 1];
            Assert.areEqual(australia.id, updatedApp.Citizenship_Country__c, 'Citizenship Country: Australia not defaulted correctly ');
            //Applicant with/without Australian Visa
            app = StudyLocationController.SaveApplicationCitizenship(''+app.id, 'INTRNTNL.A');
            update app;
            updatedApp = [SELECT id, Residency_status__c, Residency_sub_status__c, Citizenship_Country__c FROM Application__c WHERE id = :app.id LIMIT 1];
            Assert.areEqual('INTRNTNL', updatedApp.Residency_status__c, 'Residency_status__c not set');
            Assert.areEqual(null, updatedApp.Citizenship_Country__c, 'Citizenship Country not blanked out during change');
            //Malaysian Citizen check
            app = StudyLocationController.SaveApplicationCitizenship(''+app.id, 'DOM-SUN.A');
            update app;
            updatedApp = [SELECT id, Residency_status__c, Residency_sub_status__c, Citizenship_Country__c FROM Application__c WHERE id = :app.id LIMIT 1];
            Country_Attribute__c malaysia = [SELECT id FROM Country_Attribute__c WHERE Country__c = 'Malaysia' LIMIT 1];
            Assert.areEqual(malaysia.id, updatedApp.Citizenship_Country__c, 'Citizenship Country: Malaysia not defaulted correctly ');
        }
        Test.stopTest();
    }

    /*
    * @description shouldHandleDuplicateCountriesOnInitLoad
     * GIVEN a student is logged in to my.app and they have an application to proceed with
     * WHEN students come to see the citizenship country
     * THEN system shoud check whether the Application displayed in My.App contains the Citizenship Country updated earlier through other systems
    */
    @IsTest
    public static void shouldHandleDuplicateCountriesOnInitLoad() {
		// GIVEN
		// A Valid Applicant
        User applicant = StudFirst_TestHelper.createCommunityUser();
        // Multiple Country records with same ISO names
        // insert a country object
        Country_Attribute__c countryAttribute = new Country_Attribute__c();
        countryAttribute.Country__c = 'Australia';
        // insert a duplicate country object
        Country_Attribute__c duplicateCountryAttribute = new Country_Attribute__c();
        duplicateCountryAttribute.Country__c = 'Australia';
        TriggerCommon.disableTrigger('Country_Attribute__c');
        insert new List<Country_Attribute__c> {countryAttribute, duplicateCountryAttribute};       
        TriggerCommon.enableTrigger('Country_Attribute__c');
        // A Valid Application
        Application__c app = StudFirst_TestHelper.createApplication(applicant.ContactId);
        app.Applicant__c = applicant.ContactId;
        app.Campus_Location__c = 'Australia';
        app.Citizenship_Country__c = countryAttribute.Id; // country set by external system
        insert app;
       

        System.runAs(applicant) {
            // WHEN
            // Application is loaded from My.APP
	        Test.startTest();
	            Map<String, Object> mapResults = StudyLocationController.initDataLoad(app.Id);
            	app.Citizenship_Country__c = duplicateCountryAttribute.Id; // country updated by external system
		        update app;
	            Map<String, Object> mapResultsAfterUpdate = StudyLocationController.initDataLoad(app.Id);
	        Test.stopTest();
            

            // THEN
            // Country Options are populated
            Map<String, List<Map<String, String>>> countryOptions = (Map<String, List<Map<String, String>>>) mapResults.get(StudyLocationController.FIELD_COUNTRY_OPTIONS);
            Assert.areNotEqual(countryOptions.size(), 0, 'Country Options not returned');
            // Country Options contain the Application's Citizenship Country set earlier
            for (Map<String, String> country : countryOptions.get('Default')) {
                if (country.get('label').equalsIgnoreCase('Australia')) {
		            Assert.isTrue(country.get('value').equals(countryAttribute.Id), 'Preset Country is not retreived as one of the options');
                }
            }            
            // Country Options contain the Application's Citizenship Country set earlier
            countryOptions = (Map<String, List<Map<String, String>>>) mapResultsAfterUpdate.get(StudyLocationController.FIELD_COUNTRY_OPTIONS);
            for (Map<String, String> country : countryOptions.get('Default')) {
                if (country.get('label').equalsIgnoreCase('Australia')) {
		            Assert.isTrue(country.get('value').equals(duplicateCountryAttribute.Id), 'Preset Country is not retreived as one of the options');
                }
            }            
        }
    }
}