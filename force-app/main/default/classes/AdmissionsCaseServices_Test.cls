/**
* @author Angelo Rivera
* @date 05.09.19
* @group Test Class
* @description Test Class of AdmissionsCaseServices
* @revision 05.12.19 - Initial Create <br/>
* @revision Ken McGuire 17 Aug 2022 - retired static country list for database table
* @revision Shalini M 06/01/2023 - MFA Enquiry page enhancements

*/
@isTest //Parallel Tests not allowed on User
public class AdmissionsCaseServices_Test {

	@isTest
	static void testAdmissionsCaseServices() {
		Test.startTest();
			Id admissionsId = AdmissionsCaseServices.ADMISSIONS_RECTYPEID;
		Test.stopTest();
		System.assert(admissionsId != null);
	}

	/**
     * Tests initiateCommitRecord method that creates an enquiry record with DML Option specifications
     */
	@isTest
	static void test_initiateCommitRecord() {
		// initialize
		Integer firstItem = 0;
        //User

        Account accountRecord = new Account(name ='AccountTest') ;
        insert accountRecord;

        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'First';
        contactRecord.LastName = 'Last';
        contactRecord.AccountId = accountRecord.Id;
        contactRecord.Residency_Status__c = 'DOM-AUS';
        contactRecord.HasDisabilities__c = 'No';
        contactRecord.Aboriginal_or_Torres_Strait_Islander__c = 'No';
        contactRecord.Birthdate = System.today().addYears(-15);
        contactRecord.Personal_Email__c = 'applicant@mailinator.com';
        contactRecord.MailingStreet = '1 smile street';
        contactRecord.MailingCity = 'Melbourne';
        contactRecord.MailingState = 'Victoria';
        contactRecord.MailingCountry = 'Australia';
        contactRecord.MailingPostalCode = '3000';
        contactRecord.MobilePhone = '0411111111';
        contactRecord.Gender__c = 'M';
        contactRecord.Salutation = 'Mr';
        contactRecord.Title = 'Mr';
        insert contactRecord;
      
        Profile internalProfile = [SELECT Id FROM Profile WHERE name = 'Customer Community General User'];
        String random = String.valueOf(System.currentTimeMillis());

        User userRecord1 = new User(
            ProfileId = internalProfile.Id,
            Username = random +  'testing1@monash.edu',
            Alias = 'test_ao',
            Email='abc@gmail.com',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname' + random,
            Lastname='Lastname' + random,
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ContactId = contactRecord.Id,
            TimeZoneSidKey='Australia/Sydney'
        );
        insert userRecord1;
        //insert Exception Log
        Exception_Log__c exLog = new Exception_Log__c();
            exLog.Function_Name__c = 'ExperienceMFAServices';
            exLog.Message__c = 'Some error';
            exLog.CurrentUser__r =  userRecord1;
            insert exLog;
		// given - an standard enquiry with mfa details
		Case mfaCase = new Case(Subject = 'My.App MFA Support Enquiry', Origin = 'Web - My.App', SuppliedEmail='abc@gmail.com');

		// when UI sends an enquiry to commit
		Test.startTest();
			AdmissionsCaseServices.initiateCommitRecord(JSON.serialize(mfaCase), true, true);
		Test.stopTest();

		// then the mfa enquiry record should be available
		System.assertEquals(1, [SELECT Id FROM Case].size());
		System.assertEquals('00G', String.valueOf([SELECT Id, OwnerId FROM Case][firstItem].OwnerId).substring(0,3));
	}
        /*
     * @author       Ken McGuire
     * @date         3.Aug.2022
     * @description  Tests construction of country list
     */
	@IsTest
    // Given (includes duplicate record)
    static void testConstructCountryList() {
     	List<Country_Attribute__c> countryTestData = new List<Country_Attribute__c>();
        countryTestData.add(new Country_Attribute__c(Name = 'AUSTRALIA',
                                                     ShortName__c = 'Australia',
                                                     Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                     NumericPhoneCode__c = '61',
                                                     Blocked__c = false, 
                                                     Country__c = 'Australia'));
        countryTestData.add(new Country_Attribute__c(Name = 'ENGLAND',
                                                     ShortName__c = 'United Kingdom',
                                                     Callista_Code__c = '2102',
                                                     NumericPhoneCode__c = '42',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        countryTestData.add(new Country_Attribute__c(Name = 'UK',
                                                     ShortName__c = 'United Kingdom',
                                                     NumericPhoneCode__c = '42',
                                                     Callista_Code__c = '2103',
                                                     Blocked__c = false, 
                                                     Country__c = 'United Kingdom'));
        insert countryTestData;  
        // When 
        Map<String,Object> countryList = AdmissionsCaseServices.retrieveCountryList();
        // Then
        system.assertEquals(2, ((List<Country_Attribute__c>)countryList.get('allCountries')).size(),'Duplicate value should not appear in list');
    }
}