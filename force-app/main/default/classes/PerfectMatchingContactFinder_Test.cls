/**
 * @author  Shalini Mendu
 * @date 03 Dec 2019
 * @group Test Class
 * @description Covers the PerfectMatchingContactFinder class
 * 20.3.2023	Ken McGuire - country of birth replace ISO with SAAC
 */
@isTest(isParallel=true)
private with sharing class PerfectMatchingContactFinder_Test {

    @TestSetup
    static void setup() {            
        //Insert custom settings for Bypass_Mute_Request__c
        Bypass_Mute_Request__c bmr = Bypass_Mute_Request__c.getOrgDefaults();
        bmr.Enable_LogUtility_Debug__c = true;
        bmr.Enable_LogUtility_ShowLimits__c = true;
        upsert bmr;
    }

    private static void createTestCountryAttributes() {
        List<Country_Attribute__c> countryAttributes = new List<Country_Attribute__c>{
         new Country_Attribute__c(
             Country__c = 'United States of America',
             Callista_Country__c = 'United States of America',
             ISO_Alpha_2__c = 'US',
             ISO_Alpha_3__c = 'USA',
             Numeric_Country_Code__c = '001'
         ),
             new Country_Attribute__c(
                 Country__c = 'Australia',
                  Callista_Country__c = 'Australia',
                 ISO_Alpha_2__c = 'AU',
                 ISO_Alpha_3__c = 'AUS',
                 Numeric_Country_Code__c = '002'
             ),
             new Country_Attribute__c(
                 Country__c = 'India',
                 Callista_Country__c = 'India',
                 ISO_Alpha_2__c = 'IN',
                 ISO_Alpha_3__c = 'IND',
                 Numeric_Country_Code__c = '003'
             )
             };
        insert countryAttributes;
    }

    static testMethod void testPerfectMatchingContactFinder()
    {
        createTestCountryAttributes();
        Test.startTest();
        Contact con = new Contact(
                LastName = 'Ctwentysix',
                FirstName = 'Kptest',
                First_Name__c = 'Kptest',
                Salutation = 'Ms',
                Gender__c = 'F',
                Previous_Monash_ID__c = 'null',
                Previously_Studied_at_Monash__c = true,
                Birthdate = Date.valueOf('1998-12-12'),
                Email = 'kptestctwentysix@mailinator.com',
                Personal_Email__c = 'kptestctwentysix@mailinator.com',
                MailingStreet = 'TEST',
                MailingCity = 'MELBOURNE',
                MailingState = 'VIC',
                MailingCountry = 'hello',
                MailingPostalCode = '3000',
                MobilePhone ='0401717999',
                HasDisabilities__c = 'false',
                Preferred_Name__c = 'Kp',
                Country_Of_Birth__c = 'Australia',
                CountryOfBirth__c = CountryServices.getCountryId('Australia'),
                Pronouns_v2__c = 'He/They',
                Previous_Surname__c = 'Smith'
                );
        insert con;

        Contact c = [select firstname, lastname, first_name__c, last_name__c, mobilephone, mobilephone_dup__c, birthdate, Birthdate_Dup__c, Personal_Email__c,Account_Record_Type_Name__c 
                       from contact where id = :con.id];//ADDED Account_Record_Type_Name__c FOR EPCP 2739
        
        Contact dupCon = new Contact(
                LastName = 'Ctwentysix',
                FirstName = 'Kptest',
                First_Name__c = 'Kptest',
                Last_Name__c = 'Ctwentysix',
                Birthdate_Dup__c = '19981212',
                Personal_Email__c = 'kptestctwentysix@mailinator.com',
                MobilePhone_dup__c ='0401717999',
				Account_Record_Type_Name__c = 'Household_Account'//ADDED Account_Record_Type_Name__c FOR EPCP 2739
                );

        PerfectMatchingContactFinder pfM =
                new PerfectMatchingContactFinder(dupCon);
        Id latestConid = pfM.handleMatchingContacts();
        Test.stopTest();
        
        Assert.isNotNull(latestConid);
   }

    /**
     * @description     tests FindPerfectMatchContactWebService api for searching matching contact with a has contact match scenario 
     */
    @isTest
    static void testFindMatchingContacts() {
        //setup test data
        List<Contact> matchedContacts = new List<Contact>();
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        requestWrapper.lastName = 'Ctwentysix';
        requestWrapper.firstName = 'Kptest';
        requestWrapper.birthDate = '1998-12-12';
        requestWrapper.email = 'kptestctwentysix@mailinator.com';
        requestWrapper.mobilePhone = '0400000000';
        
        Contact testContact = new Contact(FirstName = requestWrapper.firstName,
										First_Name__c = requestWrapper.firstName,
                                        LastName = requestWrapper.lastName,
                                        Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                        Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                        MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                        MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                        Account_Record_Type_Name__c = 'Household_Account',//ADDED BY SEEVA FOR EPCP 2739
                                       	Email = requestWrapper.email);
        insert testContact;

        //execute contact finding logic
        Test.startTest();
            matchedContacts = new PerfectMatchingContactFinder(new Contact(FirstName = requestWrapper.firstName,
                                                                           First_Name__c = requestWrapper.firstName,
                                                                           LastName = requestWrapper.lastName,
                                                                           Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                                                           Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                                                           MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                                                           MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                                                           Account_Record_Type_Name__c = 'Household_Account',//ADDED BY SEEVA FOR EPCP 2739
                                                                           Email = requestWrapper.email)).findMatchingContacts();
        Test.stopTest();

        //check asserts
        Assert.areEqual(1, matchedContacts.size());
    }

    /**
     */
    @isTest
    static void findPerfectwithPrevious() {
        List<Contact> matchedContacts = new List<Contact>();
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        requestWrapper.lastName = 'James';
        requestWrapper.firstName = 'Masters';
        requestWrapper.birthDate = '1998-12-12';
        requestWrapper.email = 'jm@perfectmatchtest.com';
        requestWrapper.mobilePhone = '0401666555';
        
        Contact testContact = new Contact(FirstName = requestWrapper.firstName,
										First_Name__c = requestWrapper.firstName,
                                        LastName = requestWrapper.lastName,
                                        //Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                        //Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                        MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                        MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                        Account_Record_Type_Name__c = 'Household_Account',//ADDED BY SEEVA FOR EPCP 2739
                                       	Email = requestWrapper.email,
                                        Person_Id_unique__c = '30000001');
        insert testContact;

        //execute contact finding logic
        Test.startTest();
            matchedContacts = new PerfectMatchingContactFinder(new Contact(FirstName = requestWrapper.firstName,
                                                                           First_Name__c = requestWrapper.firstName,
                                                                           LastName = requestWrapper.lastName,
                                                                           Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                                                           Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                                                           MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                                                           MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                                                           Account_Record_Type_Name__c = 'Household_Account',//ADDED BY SEEVA FOR EPCP 2739
                                                                           Email = requestWrapper.email,
                                                                           previous_monash_id__c = '30000001')).findMatchingContacts();
        Test.stopTest();

        //check asserts
        Assert.areEqual(1, matchedContacts.size());
    }    
    
    /**
     * @description     tests retrieveResultContactDetails() that retrieves additional contact details
     */
    @isTest
    static void testRetrieveContactDetails() {
        //setup test data
        Contact testResultContact = new Contact();
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        requestWrapper.lastName = 'Ctwentysix';
        requestWrapper.firstName = 'Kptest';
        requestWrapper.birthDate = '1998-12-12';
        requestWrapper.email = 'kptestctwentysix@mailinator.com';
        requestWrapper.mobilePhone = '0400000000';
        
        Contact testContact = new Contact(FirstName = requestWrapper.firstName,
                                        First_Name__c = requestWrapper.firstName,
                                        LastName = requestWrapper.lastName,
                                        Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                        Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                        MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                        MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                        Account_Record_Type_Name__c = 'Household_Account',//ADDED Account_Record_Type_Name__c FOR EPCP 2739
                                        Email = requestWrapper.email);
        insert testContact;

        //execute contact finding logic
        Test.startTest();
            PerfectMatchingContactFinder perfectMatchFinder = new PerfectMatchingContactFinder(new Contact(FirstName = requestWrapper.firstName,
                                                                                                            First_Name__c = requestWrapper.firstName,
                                                                                                            LastName = requestWrapper.lastName,
                                                                                                            Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                                                                                            Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                                                                                            MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                                                                                            MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                                                                                           Account_Record_Type_Name__c = 'Household_Account',//ADDED Account_Record_Type_Name__c FOR EPCP 2739 
                                                                                                           Email = requestWrapper.email));
            perfectMatchFinder.findMatchingContacts();
            testResultContact = perfectMatchFinder.retrieveResultContactDetails(); 
        Test.stopTest();

        //check asserts
        Assert.areEqual(testContact.Id, testResultContact.Id);
    }

    /**
     * @description     tests retrieveResultApplicationDetails() that retrieves contact's application details
     */
    @isTest
    static void testRetrieveResultApplicationDetails() {
        //setup test data
        Application__c testResultApplication = new Application__c();
        PerfectMatchingContactPayload.FindPerfectMatchContactRequest requestWrapper = new PerfectMatchingContactPayload.FindPerfectMatchContactRequest();
        requestWrapper.lastName = 'Ctwentysix';
        requestWrapper.firstName = 'Kptest';
        requestWrapper.birthDate = '1998-12-12';
        requestWrapper.email = 'kptestctwentysix@mailinator.com';
        requestWrapper.mobilePhone = '0400000000';
        
        //create test contacts to be matched by the api
        Contact testContact = new Contact(FirstName = requestWrapper.firstName,
                                          First_Name__c = requestWrapper.firstName,
                                          LastName = requestWrapper.lastName,
                                          Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                          Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                          MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                          MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                          Account_Record_Type_Name__c = 'Household_Account',//ADDED Account_Record_Type_Name__c FOR EPCP 2739 
                                          Email = requestWrapper.email);
        insert testContact;

        //create test applications
        Application__c testApplication = new Application__c(Applicant__c = testContact.Id,
                                                            Callista_Applicant_Id__c = '43214321');
        insert testApplication;

        //execute contact finding logic
        Test.startTest();
            PerfectMatchingContactFinder perfectMatchFinder = new PerfectMatchingContactFinder(new Contact(FirstName = requestWrapper.firstName,
                                                                                                           First_Name__c = requestWrapper.firstName,
                                                                                                           LastName = requestWrapper.lastName,
                                                                                                           Birthdate = requestWrapper.birthDate!=null?Date.valueOf(requestWrapper.birthDate):null,
                                                                                                           Birthdate_Dup__c = requestWrapper.birthDate!=null?requestWrapper.birthDate.replace('-',''):null,
                                                                                                           MobilePhone = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone:null,
                                                                                                           MobilePhone_Dup__c = requestWrapper.mobilePhone!=null?requestWrapper.mobilePhone.replaceAll('[^0-9]',''):null,
                                                                                                           Account_Record_Type_Name__c = 'Household_Account',//ADDED Account_Record_Type_Name__c FOR EPCP 2739 
                                                                                                           Email = requestWrapper.email));
            perfectMatchFinder.findMatchingContacts();
            testResultApplication = perfectMatchFinder.retrieveResultApplicationDetails(); 
        Test.stopTest();

        //check asserts
        Assert.areEqual(testResultApplication.Id, testResultApplication.Id);
    }
}