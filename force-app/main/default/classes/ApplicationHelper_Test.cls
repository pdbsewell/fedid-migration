/**
 * @author      Kristian Vegerano
 * @description Test class for ApplicationHelper class
 * @revision    17/05/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
private with sharing class ApplicationHelper_Test {
         
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {
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
        Country_Attribute__c england = new Country_Attribute__c(Name = 'ENGLAND',
                                                                   Callista_Code__c = '2102',
                                                                   Country__c = 'United Kingdom');

        countriesList.add(england);             
        insert countriesList;

        //Insert test direct agencies
        List<Account> agencyList = new List<Account>();
        agencyList.add(new Account(Name = 'TestAgencyAU',
                                   Phone = '12345',
                                   Email__c = 'test@agency.com',
                                   Website = 'www.test-agency-1.com',
                                   Street__c = '123 testing st',
                                   City__c = 'Melbourne',
                                   State__c = 'VIC',
                                   Post_Code__c = '3000',
                                   Country_Lookup__c = australia.Id,
                                   ShippingStreet = '123 testing st',
                                   ShippingCity = 'Melbourne',
                                   ShippingState = 'VIC',
                                   ShippingPostalCode = '3000',
                                   ShippingCountry = 'Australia',
                                   Monash_AM_Web_Status__c = true,
                                   Callista_Org_Unit_Code__c = 'TESTAU',
                                   Monash_AM_Campus__c = 'Australia',
                                   RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE,
                                   Status__c = 'Appointed'));  

        agencyList.add(new Account(Name = 'TestAgencyNZ',
                                   Phone = '12345',
                                   Email__c = 'test@agency2.com',
                                   Website = 'www.test-agency-2.com',
                                   Street__c = '1233 testing st',
                                   City__c = 'Melbourne',
                                   State__c = 'VIC',
                                   Post_Code__c = '3000',
                                   Country_Lookup__c = newZealand.Id,
                                   ShippingStreet = '123 testing st',
                                   ShippingCity = 'Melbourne',
                                   ShippingState = 'VIC',
                                   ShippingPostalCode = '3000',
                                   ShippingCountry = 'New Zealand',
                                   Monash_AM_Web_Status__c = true,
                                   Callista_Org_Unit_Code__c = 'TESTNZ',
                                   Monash_AM_Campus__c = 'Australia',
                                   RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE,
                                   Status__c = 'Appointed'));

        for(Direct_Application__mdt loopDirectCode : [SELECT Label FROM Direct_Application__mdt]){
            agencyList.add(new Account(Name = loopDirectCode.Label + 'Agency',
                                       Callista_Org_Unit_Code__c = loopDirectCode.Label,
                                       ShippingCountry = 'Australia',
                                       Monash_AM_Campus__c = 'Australia',
                                       Email__c = 'test@agency.com',
                                       Website = 'www.test-agency-1.com',
                                       Street__c = '123 testing st',
                                       City__c = 'Melbourne',
                                       State__c = 'VIC',
                                       Post_Code__c = '3000',
                                       ShippingStreet = '123 testing st',
                                       ShippingCity = 'Melbourne',
                                       ShippingState = 'VIC',
                                       ShippingPostalCode = '3000',
                                       Country_Lookup__c = australia.Id,
                                       Monash_AM_Web_Status__c = true,
                                       RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE));
        }
        insert agencyList;

        //Initialize list of values
        List<List_of_Values__c> listOfValuesList = new List<List_of_Values__c>();
        listOfValuesList.add(new List_of_Values__c(System_Code__c = 'PENDING',
                                                   Value__c = 'PENDING',
                                                   Type__c = 'ADM_OUTCOME_STATUS'));
        listOfValuesList.add(new List_of_Values__c(System_Code__c = 'COND-OFFER',
                                                   Value__c = 'COND-OFFER',
                                                   Type__c = 'ADM_OUTCOME_STATUS'));  
        listOfValuesList.add(new List_of_Values__c(System_Code__c = 'OFFER',
                                                   Value__c = 'OFFER',
                                                   Type__c = 'ADM_OUTCOME_STATUS'));   
        listOfValuesList.add(new List_of_Values__c(System_Code__c = 'REJECTED',
                                                   Value__c = 'REJECTED',
                                                   Type__c = 'ADM_OUTCOME_STATUS'));     
        insert listOfValuesList;
    }
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application insert (Sent for Submission)
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnInsertSentSubmissionDirect() {
	    //Initialize test variables    
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;

        //Start test
        Test.startTest();
            insert testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('malaysia');
            if(loopCountry.Name != null){
                addressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        //Check application's submission location country with the country record of Malaysia (applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('MALAYSIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application insert (Sent for Submission)
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnInsertSentSubmissionNonDirect() {
	    //Initialize test variables   
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'TESTAU';
        testApplication.Applicant__c = testApplicant.Id;
        
        //Start test
        Test.startTest();
            insert testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('AUSTRALIA');
        if(loopCountry.Name != null){
                addressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
        }
        
        
        //Check application's submission location country with the country record of Australia (agency's shipping address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application insert (Non-Sent for Submission)
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnInsertNonSentSubmission() {
	    //Initialize test variables
        Application__c testApplication = new Application__c();
        
        //Start test
        Test.startTest();
            insert testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        
        //Check application's submission location country is still blank
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, null, 'Application\'s Submission Location Country incorrectly updated.');
    }
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application's status change to not sent to submission
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnStatusDoChange() {
        //Initialize test variables   
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;

        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));        
        //Check application's submission location country with blank value
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, null, 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('MALAYSIA');
            if(loopCountry.Name != null){
                addressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        
        
        //Check application's submission location country with the country record of Malaysia (applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('MALAYSIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country does update on application's status change to even there are associated acp
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnStatusDoChangeWithACP() {
        //Initialize test variables   
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;

        Application_Course_Preference__c lockedAcp = new Application_Course_Preference__c();
        lockedAcp.Applicant__c = testApplicant.Id;
        lockedAcp.Application__c = testApplication.Id;
        lockedAcp.Outcome_Status_LOV__c = [SELECT Id FROM List_of_Values__c WHERE System_Code__c = 'PENDING'].Id;        
        insert lockedAcp;

        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));        
        //Check application's submission location country with blank value
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, null, 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('MALAYSIA');
        if(loopCountry.Name != null){
                addressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        //Check application's submission location country with the country record of Malaysia (applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('MALAYSIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country does not update on application's status change to because of there is a locked acp
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnStatusDontChangeDueToACP() {
        //Initialize test variables   
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;

        Application_Course_Preference__c lockedAcp = new Application_Course_Preference__c();
        lockedAcp.Applicant__c = testApplicant.Id;
        lockedAcp.Application__c = testApplication.Id;
        lockedAcp.Outcome_Status_LOV__c = [SELECT Id FROM List_of_Values__c WHERE System_Code__c = 'OFFER'].Id;        
        insert lockedAcp;

        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));        
        //Check application's submission location country with blank value
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, null, 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));    
        //Check application's submission location country as blank because there is a completed ACP
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, null, 'Application\'s Submission Location Country incorrectly updated.');
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application's status change to not sent to submission
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnStatusDontChange() {
        //Initialize test variables	    
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;

        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));        
        //Check application's submission location country with blank value
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, null, 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testApplication.Status__c = Label.ApplicationStatus_Review;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));       
        //Check application's submission location country has not changed and with blank value
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, null, 'Application\'s Submission Location Country incorrectly updated.');
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application's agent change
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnAgentDoChange() {
        //Initialize test variables	    
	    Account testNzAgency = [SELECT Id, Name, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c = 'TESTNZ' LIMIT 1];

	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'TESTAU';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;
        
        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> preAddressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('Australia');
            if(loopCountry.Name != null){
                preAddressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        
        
        //Check application's submission location country with the country record of Australia (agency's shipping address)
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, preAddressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            //Clear application's agency
            testApplication.Agent_Org_Unit_Code__c = 'TESTNZ';
            testApplication.Agent__c = testNzAgency.Id;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountryNZ = CountryServices.getCountry('NEW ZEALAND');
            if(loopCountryNZ.Name != null){
                addressToCountryMap.put(loopCountryNZ.Name.toUpperCase(), loopCountryNZ.Id);
            }
        //Check application's submission location country with the country record of New Zealand (new agency's shipping address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('NEW ZEALAND'), 'Application\'s Submission Location Country incorrectly updated.');
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application's agent change
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnAgentDoChangeNonDirectToDirect() {
        //Initialize test variables	    
	    Account directAgency = [SELECT Id, Name, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c = 'DIRECT' LIMIT 1];

	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'TESTAU';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;
        
        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> preAddressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('AUSTRALIA');
            if(loopCountry.Name != null){
                preAddressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        
        
        //Check application's submission location country with the country record of Australia (agency's shipping address)
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, preAddressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            //Clear application's agency
            testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
            testApplication.Agent__c = directAgency.Id;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountryMY = CountryServices.getCountry('MALAYSIA');
            if(loopCountry.Name != null){
                addressToCountryMap.put(loopCountryMY.Name.toUpperCase(), loopCountryMY.Id);
            }
        
        
        //Check application's submission location country with the country record of Malaysia (applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('MALAYSIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application's agent change but the application refers to the applicant for the country
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnAgentDontChange() {
        //Initialize test variables	    
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;
        
        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> preAddressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('MALAYSIA');
            if(loopCountry.Name != null){
                preAddressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        
        
        //Check application's submission location country with the country record of Malaysia (applicant's mailing address)
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, preAddressToCountryMap.get('MALAYSIA'), 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            //Clear application's agency
            testApplication.Agent_Org_Unit_Code__c = null;
            testApplication.Agent__c = null;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountryMY = CountryServices.getCountry('MALAYSIA');

            if(loopCountryMY.Name != null){
                addressToCountryMap.put(loopCountryMY.Name.toUpperCase(), loopCountryMY.Id);
            }
                
        //Check application's submission location country with the country record of Malaysia (applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('MALAYSIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }
    
    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application's applicant change
    *******************************************************************************/
	@isTest 
    static void testUpdateSubmissionLocationCountryOnApplicantDoChange() {
        //Initialize test variables	    
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Australia');
	    insert testApplicant;
	    
        Contact testChangeApplicant = new Contact(LastName = 'TestChangeApplicant', MailingCountry = 'New Zealand');
	    insert testChangeApplicant;

        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;

        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> preAddressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('AUSTRALIA');
            if(loopCountry.Name != null){
                preAddressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
                
        //Check application's submission location country with the country record of Australia (applicant's mailing address)
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, preAddressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testApplication.Applicant__c = testChangeApplicant.Id;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountryNZ = CountryServices.getCountry('NEW ZEALAND');
        if(loopCountry.Name != null){
            addressToCountryMap.put(loopCountryNZ.Name.toUpperCase(), loopCountryNZ.Id);
        }
        
        
        //Check application's submission location country with the country record of New Zealand (new applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('NEW ZEALAND'), 'Application\'s Submission Location Country incorrectly updated.');
    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests application's submission location country update on application's applicant change but the application refers to the applicant for the country
    *******************************************************************************/
	@isTest 
    static void testUpdateSubmissionLocationCountryOnApplicantDontChange() {
        //Initialize test variables	    
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Malaysia');
	    insert testApplicant;
	    
        Contact testChangeApplicant = new Contact(LastName = 'TestChangeApplicant', MailingCountry = 'New Zealand');
	    insert testChangeApplicant;

        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'TESTAU';
        testApplication.Applicant__c = testApplicant.Id;
        insert testApplication;

        //Pre processing assertions
        Map<Id, Application__c> preApplicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> preAddressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('AUSTRALIA');
            if(loopCountry.Name != null){
                preAddressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        
        
        //Check application's submission location country with the country record of Australia (agency's shipping address)
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, preAddressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testApplication.Applicant__c = testChangeApplicant.Id;
            update testApplication;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountryAU = CountryServices.getCountry('AUSTRALIA');
            if(loopCountryAU.Name != null){
                addressToCountryMap.put(loopCountryAU.Name.toUpperCase(), loopCountryAU.Id);
            }
        
        
        //Check application's submission location country was not changed (agency's shipping address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }    



     /*******************************************************************************
    * @author       Shalini Mendu
    * @date         13.Jan.2023
    * @description  Tests application's submission location country by ISO code(Sent for Submission)
    *******************************************************************************/
	@isTest
	static void testUpdateSubmissionLocationCountryOnInsertWithISOCountry() {
	    //Initialize test variables    
	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'United Kingdom');
	    insert testApplicant;
	    
        Application__c testApplication = new Application__c();
        testApplication.Status__c = Label.ApplicationStatus_Sent_for_Submission;
        testApplication.Agent_Org_Unit_Code__c = 'DIRECT';
        testApplication.Applicant__c = testApplicant.Id;

        //Start test
        Test.startTest();
            insert testApplication;
        Test.stopTest();
        
        //Post processing assertions
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        Country_Attribute__c loopCountry = CountryServices.getCountry('United Kingdom');
            if(loopCountry.Country__c != null){
                addressToCountryMap.put(loopCountry.Country__c.toUpperCase(), loopCountry.Id);
            }
        
        String subLocation  = [select Submission_Location_Country__c from Application__C where id=:testApplication.Id].Submission_Location_Country__c;

        //Check application's submission location country with the country United Kingdom
        System.assertEquals(subLocation, addressToCountryMap.get('UNITED KINGDOM'), 'Application\'s Submission Location Country incorrectly updated.');
    }

  
}