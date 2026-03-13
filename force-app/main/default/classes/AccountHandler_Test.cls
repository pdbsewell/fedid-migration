/**
 * @description       : Test class for Account Trigger Handler 
 * @author            : Stefan Scheit
 * @group             : Test
 * @last modified on  : 2022-07-06
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Date         Author          Modification
 * 2022-06-30 - Stefan Scheit - Added HandleDunBradstreetElements test logic
 * 2021-11-09 - Inderpal Dhanoa - Added test for SyncHierarchyLevel from Account to Account
 * 2021-03-09 - Stefan Scheit - Added test for DnB fields and exclusion of Accounts of type "Estate"
 * 2021-01-21 - Stefan Scheit - Updated test for PopulateFieldsHandler to include DnB Optimizer field
 * 2020-09-21 - Stefan Scheit - Added test for record type PopulateFieldsHandler
 * 2020-07-01 - Kristian Vegerano - Added test scenarios for UpdateSubmissionLocationCountry
 * 2021-02-02 - Steffi Narang - Added test scenarios for AccountHandler
 * 2024-04-10 - Sachin Shetty - Update to point to DBConnect fields
**/

    
@isTest
public with sharing class AccountHandler_Test {

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
                                   Email__c = 'test@agency.com',
                                   Website = 'www.test-agency-1.com',
                                   Street__c = '123 testing st',
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
                                       RecordTypeId = AccountUtility.ACCOUNT_AGENCY_REC_TYPE));
        }
        insert agencyList;
		
		// Account creation
        Id accountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();
        Account accLevel1 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 1', NumberOfEmployees = 1, RecordTypeId = accountRecTypeId), true);
    }

    /*******************************************************************************
     * @author       Kristian Vegerano
     * @date         17.May.2019
     * @description  Tests agency's related application's submission location country update on agency's shipping country change
    *******************************************************************************/
	@isTest 
    static void testUpdateSubmissionLocationCountryyOnMailingCountryDoChange() {
        //Initialize test variables	    
	    Account testAuAgency = [SELECT Id, Name,Record_Type_Dup__c, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c = 'TESTAU' LIMIT 1];

        Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingCountry = 'Australia');
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
        for(Country_Attribute__c loopCountry : new CountriesSelector(true).selectByName(new Set<String>{'AUSTRALIA'})){
            if(loopCountry.Name != null){
                preAddressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        }
        
        //Check application's submission location country with the country record of Australia (applicant's mailing address)
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, preAddressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testAuAgency.ShippingCountry = 'New Zealand';
            update testAuAgency;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        for(Country_Attribute__c loopCountry : new CountriesSelector(true).selectByName(new Set<String>{'NEW ZEALAND'})){
            if(loopCountry.Name != null){
                addressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        }
        
        //Check application's submission location country with the country record of New Zealand (new applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('NEW ZEALAND'), 'Application\'s Submission Location Country incorrectly updated.');
        List<RecordType> recordTypeDevName= [select id, DeveloperName from RecordType where id =: AccountUtility.ACCOUNT_AGENCY_REC_TYPE limit 1];
        System.assertEquals(testAuAgency.Record_Type_Dup__c,recordTypeDevName[0].DeveloperName);

    }

    /*******************************************************************************
    * @author       Kristian Vegerano
    * @date         17.May.2019
    * @description  Tests agency's related application's submission location country update on agency's shipping country not changed
    *******************************************************************************/
	@isTest 
    static void testUpdateSubmissionLocationCountryOnMailingCountryDontChange() {
        //Initialize test variables	    
	    Account testAuAgency = [SELECT Id, Name, Callista_Org_Unit_Code__c FROM Account WHERE Callista_Org_Unit_Code__c = 'TESTAU' LIMIT 1];

	    Contact testApplicant = new Contact(LastName = 'TestApplicant', MailingStreet = 'TestStreet1', MailingCountry = 'Australia');
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
        for(Country_Attribute__c loopCountry : new CountriesSelector(true).selectByName(new Set<String>{'AUSTRALIA'})){
            if(loopCountry.Name != null){
                preAddressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        }
        
        //Check application's submission location country with the country record of Australia (applicant's mailing address)
        System.assertEquals(preApplicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, preAddressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');

        //Start test
        Test.startTest();
            testAuAgency.ShippingCountry = 'TestStreet2';
            update testAuAgency;
        Test.stopTest();
        
        //Post processing assertions
        Map<Id, Application__c> applicationAssertReferenceMap = new Map<Id, Application__c>(new ApplicationsSelector(true).selectByIdWithParentDetailsAndFinalACPs(new Set<Id>{testApplication.Id}));
        //Retrieve countries
        Map<String, Id> addressToCountryMap = new Map<String, Id>();
        for(Country_Attribute__c loopCountry : new CountriesSelector(true).selectByName(new Set<String>{'AUSTRALIA'})){
            if(loopCountry.Name != null){
                addressToCountryMap.put(loopCountry.Name.toUpperCase(), loopCountry.Id);
            }
        }
        
        //Check application's submission location country with the country record of New Zealand (new applicant's mailing address)
        System.assertEquals(applicationAssertReferenceMap.get(testApplication.Id).Submission_Location_Country__c, addressToCountryMap.get('AUSTRALIA'), 'Application\'s Submission Location Country incorrectly updated.');
    }
	
    /*******************************************************************************
     * @author      Inderpal Dhanoa
     * @date         1.Nov.2021
     * @description  Tests regarding to capturing the Hierarchy
    *******************************************************************************/
	@isTest 
    static void testSyncHierarchyLevel() {

        Id accountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Monash_Organisation').getRecordTypeId();

        //GIVEN
        // The Parent Id exists 
        Account accLevel1 = [SELECT Id, Name, Hierarchy_Level__c FROM Account WHERE Name = 'Level 1'];

        //Start test
        Test.startTest();      
        //WHEN - Accounts are inserted in the hierarchy
        Account accLevel2 = (Account)TestDataFactory.createSObject(new Account(Name = 'Level 2', ParentId=accLevel1.Id, RecordTypeId = accountRecTypeId), true);

        Test.stopTest();
        
        //THEN
        // Async Events are fired 

    }
    
	/*
    * @author       Stefan Scheit
    * @date         2020-09-21
    * @description  Test that the record type text field is set correctly for updates.
    */    
    @isTest
    public static void testHandleExternalOrganisationsRecordTypeDup() {
        
        //GIVEN: an account is inserted
        Map<String, Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        RecordTypeInfo recTypeInfo = recTypeMap.get(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION);
        System.assert(recTypeInfo!=null, 'Record type for '+ AccountServices.ACCOUNT_EXTERNAL_ORGANISATION +' could not be found.');
        System.debug('RT developer name: '+recTypeInfo.getDeveloperName());
        Account acct = new Account();
        acct.name = 'PopulateFieldsUpdate';
        acct.RecordTypeId = recTypeInfo.getRecordTypeId();
        insert acct;

        //THEN: the record text field is set
        acct = [SELECT Id, Record_Type_Dup__c, LD_USE_DnB_Optimize__c FROM Account WHERE Id = :acct.Id];
        System.assert(recTypeInfo.getDeveloperName().equals(acct.Record_Type_Dup__c), 'Record type developer name was not set (as part of an insert) as expected.');

        //WHEN: the record type is changed
        recTypeInfo = recTypeMap.get(AccountServices.ACCOUNT_MONASH_ORGANISATION); // monash organisation
        System.debug('RT developer name: '+recTypeInfo.getDeveloperName());
        acct.RecordTypeId = recTypeInfo.getRecordTypeId();
        update acct;
        
        // THEN: the text field capturing the record typ should be populated (updated)
        acct = [SELECT Id, Record_Type_Dup__c, LD_USE_DnB_Optimize__c FROM Account WHERE Id = :acct.Id];
        System.assert(recTypeInfo.getDeveloperName().equals(acct.Record_Type_Dup__c), 'Record type developer name was not set (as part of an update) as expected.');
    }

    /*
    * @author       Stefan Scheit
    * @date         2021-03-09
    * @description  Test that the DnB Optimizer fields are set for "External Organisation" account, but not when the Type is "Estate".
    */    
    @isTest
    public static void testHandleExternalOrganisationsDnbFields() {

        //GIVEN: an account is inserted
        Map<String, Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        RecordTypeInfo recTypeInfo = recTypeMap.get(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION);
        System.assert(recTypeInfo!=null, 'Record type for '+ AccountServices.ACCOUNT_EXTERNAL_ORGANISATION +' could not be found.');
        System.debug('RT developer name: '+recTypeInfo.getDeveloperName());
        // External Organisation
        Account extOrgAccount = new Account();
        extOrgAccount.Name = 'External Organisation';
        extOrgAccount.RecordTypeId = recTypeInfo.getRecordTypeId();
        // Estate
        Account estateAccount = new Account();
        estateAccount.Name = 'Estate';
        estateAccount.Type = 'Estate'; // this influences the logic
        estateAccount.RecordTypeId = recTypeInfo.getRecordTypeId();
        Database.insert(new List<Account>{extOrgAccount, estateAccount});

        //THEN: the DnB field should be set to true (for External Organisation Accounts), but set to false (for Estate Accounts)
        Map<Id, Account> testAccounts = new Map<Id, Account>([SELECT Id, Record_Type_Dup__c, LD_USE_DnB_Optimize__c FROM Account WHERE Id IN (:extOrgAccount.Id, :estateAccount.Id)]);
        System.assertEquals(true, testAccounts.get(extOrgAccount.Id)?.LD_USE_DnB_Optimize__c, 'The Allow DnB Optimizer field (LD_USE_DnB_Optimize__c) was not set to true/checked for the External Organisation.');
        System.assertEquals(false, testAccounts.get(estateAccount.Id)?.LD_USE_DnB_Optimize__c, 'The Allow DnB Optimizer field (LD_USE_DnB_Optimize__c) was not set to false/unchecked for the Estate Account.');
    }

    /*
    * @author       Stefan Scheit
    * @date         2021-04-08
    * @description  Test that the Industry classification fields (SIC_Division__c and Industry) are set on insert.
    */    
    @isTest
    public static void testHandleExternalOrganisationsSicFieldsInsert() {

        // GIVEN: an account is defined with a SIC code
        Map<String, Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        RecordTypeInfo recTypeInfo = recTypeMap.get(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION);
        System.assert(recTypeInfo!=null, 'Record type for '+ AccountServices.ACCOUNT_EXTERNAL_ORGANISATION +' could not be found.');
        System.debug('RT developer name: '+recTypeInfo.getDeveloperName());
        // external org
        Account extOrgAccount = new Account();
        extOrgAccount.Name = 'External Organisation';
        extOrgAccount.RecordTypeId = recTypeInfo.getRecordTypeId();
        extOrgAccount.Sic = '01190103'; // Lentil farm

        // WHEN account is inserted
        Database.insert(new List<Account>{extOrgAccount});
        Map<Id, Account> testAccounts = new Map<Id, Account>([SELECT Id, Sic, Industry, SIC_Division__c FROM Account WHERE Id IN (:extOrgAccount.Id)]);

        // THEN: the SIC fields are updated
        System.assertEquals(extOrgAccount.Sic.left(2), testAccounts.get(extOrgAccount.Id)?.Industry, 'The \'Industry\' field was not set as expected based on the value of the \'Sic\' field.');
        System.assertEquals('A', testAccounts.get(extOrgAccount.Id)?.SIC_Division__c, 'The \'SIC_Division__c\' field was not set as expected based on the value of the \'Sic\' field.');
    }

    /*
    * @author       Stefan Scheit
    * @date         2021-04-08
    * @description  Test that the Industry classification fields (SIC_Division__c and Industry) are changed on update.
    */    
    @isTest
    public static void testHandleExternalOrganisationsSicFieldsUpdate() {

        // GIVEN: an account is present with a SIC code
        Map<String, Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        RecordTypeInfo recTypeInfo = recTypeMap.get(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION);
        System.assert(recTypeInfo!=null, 'Record type for '+ AccountServices.ACCOUNT_EXTERNAL_ORGANISATION +' could not be found.');
        System.debug('RT developer name: '+recTypeInfo.getDeveloperName());
        // external org (positive test)
        Account extOrgAccount = new Account();
        extOrgAccount.Name = 'External Organisation';
        extOrgAccount.RecordTypeId = recTypeInfo.getRecordTypeId();
        extOrgAccount.Sic = '01190103'; // Lentil farm
        Database.insert(new List<Account>{extOrgAccount});

        // WHEN account's SIC value is updated
        extOrgAccount.Sic = '50859913'; // Springs
        Database.update(new List<Account>{extOrgAccount});
        Map<Id, Account> testAccounts = new Map<Id, Account>([SELECT Id, Sic, Industry, SIC_Division__c FROM Account WHERE Id IN (:extOrgAccount.Id)]);

        // THEN: the SIC fields are updated
        System.assertEquals(extOrgAccount.Sic.left(2), testAccounts.get(extOrgAccount.Id)?.Industry, 'The \'Industry\' field was not set as expected based on the value of the \'Sic\' field.');
        System.assertEquals('F', testAccounts.get(extOrgAccount.Id)?.SIC_Division__c, 'The \'SIC_Division__c\' field was not set as expected based on the value of the \'Sic\' field.');
    }

    /*
    * @author       Stefan Scheit
    * @date         2022-06-30
    * @description  Test that the DnB Company field is blanked out on insert.
    */    
    @isTest
    public static void testDunBradstreetHandlerInsert() {

        // GIVEN: a company record exists
        DNBConnect__D_B_Connect_Company_Profile__c dnbRecord = new DNBConnect__D_B_Connect_Company_Profile__c();
        dnbRecord.Name = 'DnB Record';
        dnbRecord.DNBConnect__DUNSNumber__c = '1234';
        Database.insert(dnbRecord);
        
        // GIVEN: an account is inserted without DUNS number, but CompanyRecord lookup present
        Map<String, Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        RecordTypeInfo recTypeInfo = recTypeMap.get(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION);
        System.assert(recTypeInfo!=null, 'Record type for '+ AccountServices.ACCOUNT_EXTERNAL_ORGANISATION +' could not be found.');
        Account extOrgAccount = new Account();
        extOrgAccount.Name = 'External Organisation';
        extOrgAccount.RecordTypeId = recTypeInfo.getRecordTypeId();
        extOrgAccount.DBC_DUNS_Number__c = '';
        extOrgAccount.DNBConnect__D_B_Connect_Company_Profile__c = dnbRecord.Id;

        // WHEN account is inserted
        Test.startTest();
            Database.insert(extOrgAccount);
        Test.stopTest();
        extOrgAccount = [SELECT Id, DBC_DUNS_Number__c, DNBConnect__D_B_Connect_Company_Profile__c FROM Account WHERE Id = :extOrgAccount.Id];

        // THEN: the DNBConnect__D_B_Connect_Company_Profile__c field should be blank
        Assert.isTrue(String.isBlank(extOrgAccount.DBC_DUNS_Number__c), 'The \'DBC_DUNS_Number__c\' field is not blank as expected.');
        Assert.isNull(extOrgAccount.DNBConnect__D_B_Connect_Company_Profile__c, 'The \'DNBConnect__D_B_Connect_Company_Profile__c\' field was not set to null as expected when the DnB DUNS number is blank.');
    }
    
    /*
    * @author       Stefan Scheit
    * @date         2022-06-30
    * @description  Test that the DnB Company field is blanked out on update.
    */    
    @isTest
    public static void testDunBradstreetHandlerUpdate() {

        // GIVEN: a company record exists
        DNBConnect__D_B_Connect_Company_Profile__c dnbRecord = new DNBConnect__D_B_Connect_Company_Profile__c();
        dnbRecord.Name = 'DnB Record';
        dnbRecord.DNBConnect__DUNSNumber__c = '1234';
        Database.insert(dnbRecord);
        
        // GIVEN: an account is inserted with DUNS number and CompanyRecord lookup present
        Map<String, Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        RecordTypeInfo recTypeInfo = recTypeMap.get(AccountServices.ACCOUNT_EXTERNAL_ORGANISATION);
        //System.assert(recTypeInfo!=null, 'Record type for '+ AccountServices.ACCOUNT_EXTERNAL_ORGANISATION +' could not be found.');
        Assert.isNotNull(recTypeInfo, 'Record type for '+ AccountServices.ACCOUNT_EXTERNAL_ORGANISATION +' could not be found.');

        Account extOrgAccount = new Account();
        extOrgAccount.Name = 'External Organisation';
        extOrgAccount.RecordTypeId = recTypeInfo.getRecordTypeId();
        extOrgAccount.DBC_DUNS_Number__c = '753805670';
        extOrgAccount.DNBConnect__D_B_Connect_Company_Profile__c = dnbRecord.Id;
		Database.insert(extOrgAccount);
        extOrgAccount = [SELECT Id, DBC_DUNS_Number__c, DNBConnect__D_B_Connect_Company_Profile__c FROM Account WHERE Id = :extOrgAccount.Id];
        //System.assertNotEquals(null, extOrgAccount.DNBConnect__D_B_Connect_Company_Profile__c, 'The \'DNBConnect__D_B_Connect_Company_Profile__c\' field is blank.');
        Assert.isNotNull(extOrgAccount.DNBConnect__D_B_Connect_Company_Profile__c, 'The \'DNBConnect__D_B_Connect_Company_Profile__c\' field is blank.');
        
        // WHEN account is updated and the DUNS number is removed
        extOrgAccount.DBC_DUNS_Number__c = '';
        Database.update(extOrgAccount);
        extOrgAccount = [SELECT Id, DBC_DUNS_Number__c, DNBConnect__D_B_Connect_Company_Profile__c FROM Account WHERE Id = :extOrgAccount.Id];

        // THEN: the DNBConnect__D_B_Connect_Company_Profile__c field should be blank
        Assert.isTrue(String.isBlank(extOrgAccount.DBC_DUNS_Number__c), 'The \'DBC_DUNS_Number__c\' field is not blank as expected.');
        Assert.isNull(extOrgAccount.DNBConnect__D_B_Connect_Company_Profile__c, 'The \'DNBConnect__D_B_Connect_Company_Profile__c\' field was not set to null as expected when the DnB DUNS number is blank.');
    }
    
    /**
    * @author       Steffi Narang
    * @description Test method to validate createAccountTeamMemberforPRM method in AccountHandler (ENGAGEIE-621)
    */
    @isTest
    static void createAccountTeamMemberforPRM() {
       //creating unique username 
        String orgId = UserInfo.getOrganizationId();
    	String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
		Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
    	String uniqueName = orgId + dateString + randomInt;       

        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
		Profile profile1 = [Select Id from Profile where name = 'ascend Gift Specialist'];
        //insert a user..
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,           
            Username = uniqueName + '@test' + orgId + '.org',   
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        User portalAccountOwner2 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,           
            Username = uniqueName + '@testing' + orgId + '.org',   
            Alias = 'batman',
            Email='bruce.way12@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner2);
        List<Account> testaccounts = new List<Account>();
        List<Account> updatetestaccounts = new List<Account>();

        system.runAs(portalAccountOwner1){
            Account acct = new Account(Name='testAccount',recordtypeid=AccountUtility.ACCOUNT_EXTERNAL_ORG_REC_TYPE,ucinn_ascendv2__PRM__c =portalAccountOwner1.id);
			testaccounts.add(acct);
            Test.startTest();
            	insert testaccounts;
			Test.stopTest(); 
            AccountTeamMember acc1M = [select id,AccountId,TeamMemberRole from AccountTeamMember where AccountId =:acct.id];
            System.assertEquals(acc1M.TeamMemberRole,'PRM (Philanthropy)');

			for(Account acc: testaccounts){
				acct.ucinn_ascendv2__PRM__c = portalAccountOwner2.Id;
                updatetestaccounts.add(acct);

            }
            
			update updatetestaccounts;
            set<Id> accId  = new set<Id>();
            for(Account acc: updatetestaccounts){
                accId.add(acc.Id);
            }
            AccountTeamMember accM = [select id,AccountId,TeamMemberRole from AccountTeamMember where AccountId IN: accId];
        	System.assertEquals(accM.TeamMemberRole,'PRM (Philanthropy)');
          }   
	}
	
	/**
     * @author      Inderpal Dhanoa
     * @description Tests Create a method to Sync Duns Number from Account to Opportunity
     * @revision    09/08/2021 - Inderpal Dhanoa - Created
     */
    @isTest
    public static void testSyncDUNSNumbrToOppty() {
        
        List<Account> linkedAcc = new List<Account>();
        List<Opportunity> linkedOppty = new List<Opportunity>();

        Account acc2 = new Account(	Name = 'testCreateExternalAccount',DBC_DUNS_Number__c = 'testDuns',
                                 	RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        linkedAcc.add(acc2);
        insert linkedAcc;

        Opportunity opp1 = new Opportunity(	Name = 'testCreateEnterpriseOpportunity1',
                                            AccountId = acc2.Id,
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(),
                                            PURE_Application_ID__c = 'Test2',
                                          	StageName = 'Identify Opportunity',
                                          	CloseDate = Date.today().addDays(1));
        linkedOppty.add(opp1);

        Opportunity opp2 = new Opportunity(	Name = 'testCreateEnterpriseOpportunity2',
                                            AccountId = acc2.Id,
            								RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(),
                                            PURE_Application_ID__c = 'Test3',
                                          	StageName = 'Identify Opportunity',
                                          	CloseDate = Date.today().addDays(1));
        linkedOppty.add(opp2);
        insert linkedOppty;

        //Start test
        Test.startTest();
            opp2 = [SELECT Id, Account.DBC_DUNS_Number__c, Pure_ID__c, PURE_Application_ID__c FROM OPPORTUNITY WHERE NAME = 'testCreateEnterpriseOpportunity2'];
            Assert.areEqual(opp2.PURE_Application_ID__c+acc2.DBC_DUNS_Number__c, opp2.Pure_ID__c, 'DUNS Number did not sync');

            acc2 = [SELECT Id, DBC_DUNS_Number__c FROM Account WHERE Name = 'testCreateExternalAccount'];
            acc2.DBC_DUNS_Number__c = 'testDuns1';
            update acc2;

            opp2 = [SELECT Id, Pure_ID__c, AccountId, PURE_Application_ID__c FROM OPPORTUNITY WHERE NAME = 'testCreateEnterpriseOpportunity2'];
            Assert.areEqual(opp2.PURE_Application_ID__c+acc2.DBC_DUNS_Number__c, opp2.Pure_ID__c, 'DUNS Number did not sync');

        // Stop Test
        Test.stopTest();
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests Create a single partner agreement whenever a partner account is created
     * @revision    03/02/2021 - Kristian Vegerano - Created
     */
    @isTest
    public static void testCreatePartnerAgreement() {
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        //Start test
        Test.startTest();

        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId);
        insert testAccount;

        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Partner_Agreement__c WHERE Partner_Account__c = :testAccount.Id].size());
    }
/**
     * @author      Seeva Singh
     * @description Tests Create an account and changes its record type from household to agency and then back to household 
     * @revision    12/05/2023 - Seeva Singh - Created
     */
    @isTest
    public static void testPopulateAccountRecordTypeNameOnContact() {
        Id householdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
		Id schoolRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('School').getRecordTypeId();

        //Start test
        Test.startTest();
            Account testAccount = new Account(Name = 'TestAccountcheckrandom', RecordTypeId = householdRecordTypeId);
            insert testAccount;
            Id accId = testAccount.Id;

            Contact testContact = new Contact(LastName = 'TestContact', accountId = accId);
            insert testContact;
            
            testAccount = [SELECT Id, recordtypeId,name FROM Account WHERE  name ='TestAccountcheckrandom'];
            testAccount.RecordTypeId = schoolRecordTypeId;
            update testAccount;
            Assert.isNull([SELECT Id, Account_Record_Type_Name__c FROM Contact WHERE accountId = :accId].Account_Record_Type_Name__c, 'Expected the Account Record Type Name to be blank/null');
            
            testAccount = [SELECT Id, recordtypeId,name FROM Account WHERE  name ='TestAccountcheckrandom'];
            testAccount.RecordTypeId = householdRecordTypeId;
            update testAccount;
            Assert.areEqual('Household_Account',[SELECT Id, Account_Record_Type_Name__c FROM Contact WHERE accountId = :accId].Account_Record_Type_Name__c, 'Expected the Account Record Type Name to be Household_Account');
        //Stop test
        Test.stopTest();
    }
    
    /*
    * @author       Sachin Shetty
    * @date         2024-04-10
    * @description  Test that the phone field is updated with international dialing code and other phone.
    */    
    @isTest
    public static void testUpdatePhoneWithDialingCode() {

        // GIVEN: External Organisation
        Account extOrgAccount = new Account();
        extOrgAccount.Name = 'External Organisation';
        extOrgAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId();
        extOrgAccount.other_phone__c = '444444444';
        insert extOrgAccount;
        Id accId = extOrgAccount.Id;
        
        // WHEN: International dialing code and Other Phone fields on account are updated
        extOrgAccount.international_dialing_code__c = '61';
        extOrgAccount.other_phone__c = '333333333';
        Test.startTest();
        	Database.update(extOrgAccount);
        Test.stopTest(); 

        // THEN: the Phone field is updated with the international dialing code and other phone
        String expectedPhoneField = '+'+extOrgAccount.international_dialing_code__c+' '+extOrgAccount.other_phone__c;
        Assert.areEqual(expectedPhoneField, [SELECT Id, Phone FROM Account WHERE Id=:accId].Phone, 'Expected the Phone field to have the international dialing code and other phone');
    }
}