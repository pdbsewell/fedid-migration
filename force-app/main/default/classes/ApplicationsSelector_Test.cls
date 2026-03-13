/**
 * @author      Kristian Vegerano
 * @description Test class for ApplicationsSelector class
 * @group       Test Class
 * @revision    20/09/2019 - Kristian Vegerano - Created
 *              25/10/2024 - Vishal Gupta modified - added a query selector to retrieve the application documents
 */
@isTest/*(isParallel=true) APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object*/
public with sharing class ApplicationsSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        //Create test country
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;

        //Create test agency record
        Account testAgency = new Account(Name = 'TestAgencyAU',
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
                                         Status__c = 'Appointed');
        insert testAgency;

        //Create test account record - applicant default account
        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        //Create test contact record - applicant record
        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'INT-TEP';
        contactRecord.MailingCountry = 'AUSTRALIA';
        insert contactRecord;

        //Create test my.app community user and contact record
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community General User' LIMIT 1].Id;
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User testCommunityUser = new User(Alias = String.valueOf(rnd)+ 'usr',
                                     Email = String.valueOf(rnd) +'testuser@mutesting.edu',
                                     EmailEncodingKey = 'UTF-8',
                                     LastName = 'TestingUser',
                                     LanguageLocaleKey = 'en_US',
                                     LocaleSidKey = 'en_GB',
                                     ProfileId = profileId,
                                     TimeZoneSidKey = 'Australia/Sydney',
                                     UserName = String.valueOf(rnd) +'testuser@mutesting.edu',
                                     ContactId = contactRecord.Id,
                                     App_Salutation__c = '',
                                     App_Gender__c = '',
                                     App_Birthdate__c = null,
                                     App_Residency_Status__c = 'INT-TEP',
                                     Street = '',
                                     App_Address_Type__c = 'POSTAL');
        insert testCommunityUser;
        
        //Insert my.app permission set
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = [SELECT Id 
                                                                                         FROM PermissionSet 
                                                                                         WHERE Name = :LightningSelfRegisterCC.MYAPP_PERMSET_NAME].Id,
                                                                      AssigneeId = testCommunityUser.Id);
            insert psa;
        }

        //Create test application data
        Application__c testApplication = new Application__c();
        testApplication.Applicant__c = testCommunityUser.ContactId;
        testApplication.Passport_Number__c = 'A1234567';
        testApplication.Campus_Location__c = null;
        testApplication.Visa_Type__c = null;
        testApplication.Australian_Immigration_Office_Issued__c = null;
        testApplication.Visa_Number__c = null;
        testApplication.Passport_Number__c = null;
        testApplication.Visa_Start_Date__c = null;
        testApplication.Visa_End_Date__c = null;
        testApplication.Refused_entry_visa_to_any_country__c = null;
        testApplication.Breached_visa_condition__c = null;
        testApplication.Medical_health_prevent_visa__c = null;
        testApplication.Protection_visa_in_any_country__c = null;
        testApplication.Convicted_of_crime_offence__c = null;
        testApplication.Agent__c = testAgency.Id;
        insert testApplication;
    }

    /**
     * @description Test select applications by Id with full record and child details necessary for assessment
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        Set<Id> applicationIds = new Set<Id>();
        List<Application__c> testApplicationList = new List<Application__c>();

        //Retrieve existing application ids
        //GIVEN application record is for assessment
        for(Application__c loopApplication : [SELECT Id FROM Application__c LIMIT 10]){
            applicationIds.add(loopApplication.Id);
        }

        //Start test process
	 	Test.startTest();
            //WHEN you want to retrieved all fields and child details
            testApplicationList.addAll(new ApplicationsSelector(true).selectById(applicationIds));
	 	Test.stopTest();

        //Start assertion
        //THEN you should get all fields and child details via the Application Id
        Assert.areEqual(1, testApplicationList.size());
    }

    /**
     * @description Test select applications by Id with parent lookup details and final ACP child records
     */
    @isTest 
    static void test_SelectByIdWithParentDetailsAndFinalACPs() {
        //Initialize variables
        Set<Id> applicationIds = new Set<Id>();
        List<Application__c> testApplicationList = new List<Application__c>();

        //Retrieve existing application ids
        //GIVEN application record is for assessment
        for(Application__c loopApplication : [SELECT Id FROM Application__c LIMIT 10]){
            applicationIds.add(loopApplication.Id);
        }

        //Start test process
	 	Test.startTest();
            //WHEN you want to retrieved all fields and the final ACP child record
            testApplicationList.addAll(new ApplicationsSelector().selectByIdWithParentDetailsAndFinalACPs(applicationIds));
	 	Test.stopTest();

        //Start assertion
        //THEN you should get all fields and get the details of the final ACP record
        Assert.areEqual(1, testApplicationList.size());
    }

    /**
     * @description Test select applications by applicant Ids
     */
    @isTest 
    static void test_SelectByApplicantId() {
        //Initialize variables
        Set<Id> applicantIds = new Set<Id>();
        List<Application__c> testApplicationList = new List<Application__c>();

        //Retrieve existing applicant ids
        //GIVEN application record is for assessment
        for(Application__c loopApplication : [SELECT Id, Applicant__c FROM Application__c LIMIT 10]){
            applicantIds.add(loopApplication.Applicant__c);
        }

        //Start test process
	 	Test.startTest();
            //WHEN you want to retrieved application records by applicant id
            testApplicationList.addAll(new ApplicationsSelector().selectByApplicantId(applicantIds));
	 	Test.stopTest();

        //Start assertion
        //THEN you should get all application fields based on the applicant id
        Assert.areEqual(1, testApplicationList.size());
    }

    /**
     * @description Test select applications by agency account Ids
     */
    @isTest 
    static void test_SelectByAgencyId() {
        //Initialize variables
        Set<Id> agencyIds = new Set<Id>();
        List<Application__c> testApplicationList = new List<Application__c>();

        //Retrieve existing applicant ids
        //GIVEN application record is for assessment
        for(Application__c loopApplication : [SELECT Id, Agent__c FROM Application__c LIMIT 10]){
            agencyIds.add(loopApplication.Agent__c);
        }

        //Start test process
	 	Test.startTest();
            //WHEN you want to retrieved application records by agency id
            testApplicationList.addAll(new ApplicationsSelector().selectByAgencyId(agencyIds));
	 	Test.stopTest();

        //Start assertion
        //THEN you should get all application fields based on the agency id
        Assert.areEqual(1, testApplicationList.size());
    }

    /**
     * @description Test select applications by Id with full record and child details necessary for assessment
     */
    @isTest 
    static void test_SelectByIdWithFullAssessmentDetails() {
        //Initialize variables
        Set<Id> applicationIds = new Set<Id>();
        List<Application__c> testApplicationList = new List<Application__c>();

        //Retrieve existing application ids
        //GIVEN application record is for assessment
        for(Application__c loopApplication : [SELECT Id FROM Application__c LIMIT 10]){
            applicationIds.add(loopApplication.Id);
        }

        //Start test process
	 	Test.startTest();
            //WHEN you want to retrieved application records by application id
            testApplicationList.addAll(new ApplicationsSelector().selectByIdWithFullAssessmentDetails(applicationIds));
	 	Test.stopTest();

        //Start assertion
        //THEN you should get all application fields based on the application id necessary for assessment
        Assert.areEqual(1, testApplicationList.size());
    }

    /**
     * @description Test select applications by Id with linked contacts document
     * GIVEN there is an application record submitted from my.app
     * WHEN there are documents attached to the application
     * THEN we can get the documents after querying the application record
     */
    @isTest 
    static void test_SelectByIdWithParentDetailsAndDocuments() {
        //GIVEN there is an application record submitted from my.app
        Set<Id> applicationIds = new Set<Id>();
        List<Application__c> testApplicationList = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        List<Contact_Document__c> conDocList = new List<Contact_Document__c>();
        for(Integer i=0; i < 10 ; i++) {
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = testApplicationList[0].Applicant__c;
            conDoc.Application__c = testApplicationList[0].Id;
            conDoc.Document_Type__c = 'PARENT_GUARDIAN';
            conDoc.Filename__c = 'testdoc';
            conDocList.add(conDoc);
        }
        //WHEN there are documents attached to the application
        insert conDocList;

        //Start test process
	 	Test.startTest();
         List<Application__c> selectApplications =new ApplicationsSelector().selectByIdWithParentDetailsAndDocuments(new set<Id>{testApplicationList[0].Id});
	 	 //THEN we can get the documents after querying the application record
          Assert.areEqual(false, selectApplications[0].Contact_Documents__r.isEmpty(), 'there are documents linked to the application');
        Test.stopTest();

       
    }
}