/**
 * @description       : Test class for PartnerApplicationService
 * @author            : Kristian Vegerano
 * @group             : Test
 * @last modified on  : 2021-03-03
 * @last modified by  : Kristian Vegerano
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2021-03-03 - Kristian Vegerano - Added test scenarios for partner application actions
**/
@isTest
public with sharing class PartnerApplicationService_Test {
    
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        //Create test Course
        Course__c testCourse = new Course__c();
        testCourse.Name = '8003';
        testCourse.Course_Code__c = '8003';
        testCourse.Title__c = 'Exchange Virtual';
        testCourse.Type__c = 'Course-All';
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = new Course_Offering__c();
        testOffering.Course__c = testCourse.Id;
        testOffering.Academic_CI_Sequence_Number__c = 1;
        testOffering.Academic_Calendar_Type__c = '2019';
        testOffering.Admission_CI_Sequence_Number__c = 1;
        testOffering.Admission_Calendar_Type__c = 'ADM';
        testOffering.Attendance_Mode__c = 'SCG';
        testOffering.Attendance_Type__c = 'PT';
        testOffering.Course_Code__c = '8003';
        testOffering.Course_Title__c = 'Exchange Virtual';
        testOffering.Course_Version_Number__c = 1;
        testOffering.Admission_Calendar_Description__c = 'July-2019';
        testOffering.Attendance_Mode_Description__c = 'On Campus';
        testOffering.Attendance_Type_Description__c = 'FULL TIME';
        testOffering.Citizenship_Type__c = 'DOM-AUS';
        testOffering.Course_Type_Group__c = 'OPG';
        testOffering.Location_Code__c = 'CLAYTON';
        testOffering.Type_of_Place_Description__c = 'Test type of place';
        testOffering.Type_of_Place_Code__c = 'PC001';
        testOffering.Unit_Set_Code__c = 'MM00000';
        testOffering.Unit_Set_Description__c = 'set description';
        testOffering.Active__c = true;
        insert testOffering;

        //Create setting for Countries
        Country_Attribute__c australia = new Country_Attribute__c(Name = 'AUSTRALIA',
                                                                  Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
                                                                  Country__c = 'Australia');
        insert australia;  
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests retrievePartnerUserDetails method
     *              Retrieves current user (Partner User) details and details about the partner account's partner agreement details
     *              Validates that expected details are returned properly
     * @revision    27/02/2021 - Kristian Vegerano - Created
     */
    @isTest 
    static void test_RetrievePartnerUserDetails() {
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId);
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        ExperienceAuthenticationServices.generatePartnerUser('{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","DelegatedAdmin":' + true + '}');
        User partnerUser = [SELECT Id 
                            FROM User 
                            WHERE ContactId = :testContact.Id 
                                AND Contact.AccountId = :testAccount.Id
                                AND Profile.Name = :Constants.PARTNER_USER_PROFILE 
                                AND IsActive = true LIMIT 1];
       
        Map<String, Object> resultsMap = new Map<String, Object>();
        Test.startTest();
            resultsMap = PartnerApplicationService.retrievePartnerUserDetails(partnerUser.Id);
            System.runAs(partnerUser){
                resultsMap = PartnerApplicationService.retrievePartnerUserDetails(partnerUser.Id);
            }
        Test.stopTest();

        //Start assertion
        System.assertEquals('SUCCESS', resultsMap.get('STATUS'));
        System.assertEquals(JSON.serialize(new Set<String>{'Exchange'}), resultsMap.get('ALLOWED_APP_TYPES'));
        System.assertEquals(JSON.serialize(testAccount.Id), resultsMap.get('PARTNER_ACCOUNT_ID'));
        System.assertEquals(JSON.serialize(Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Non_Student').getRecordTypeId()), resultsMap.get('NOT_KNOWN_TO_MONASH_ID'));
    }

    /**
     * @author      Kristian Vegerano
     * @description Tests createApplication method
     *              Test creates an exchange application
     *              Validates that expected details are returned properly
     * @revision    27/02/2021 - Kristian Vegerano - Created
     *              31/03/2021 - Vinothraja - added Location param while Application creation
     */
    @isTest 
    static void test_CreateApplication() {
        Map<String, Object> resultsMap = new Map<String, Object>();
        Account testAccount = new Account(Name = 'TestAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
       
        Test.startTest();
            resultsMap = PartnerApplicationService.createApplication(JSON.serialize(testContact),
                                                                     testAccount.Id,
                                                                     'Exchange',
                                                                     '1', 
                                                                     'Australia',
                                                                     'DOM-AUS');
        Test.stopTest();

        //Start assertion
        System.assertEquals('SUCCESS', resultsMap.get('STATUS'));
        System.assertNotEquals(null, resultsMap.get('APPLICANT'));
        System.assertNotEquals(null, resultsMap.get('APPLICATION'));
    }

    /**
     * @author      Shalini Mendu
     * @description Retrieves Partner Agreement quota details
     * @revision   8/June/2021 - Created
     */
    @isTest
    static void test_RetrievePartnerAgreement()
    {
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Account testAccount = new Account(Name = 'TestAccount', RecordTypeId = partnerRecordTypeId);
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'TestFirstName', LastName = 'TestLastName', AccountId = testAccount.Id, Email = 'TestEmail@testemail.com');
        insert testContact;
        ExperienceAuthenticationServices.generatePartnerUser('{"ContactId":"' + testContact.Id + '","FirstName":"TestFirstName","MiddleName":"TestMiddleName","LastName":"TestLastName","Suffix":"TestSuffix","Email":"testemail@testemail.com","Username":"' + String.valueOf(Math.random()) + 'testemail@testemail.com","Nickname":"TestNickname","DelegatedAdmin":' + true + '}');
        User partnerUser = [SELECT Id 
                            FROM User 
                            WHERE ContactId = :testContact.Id 
                                AND Contact.AccountId = :testAccount.Id
                                AND Profile.Name = :Constants.PARTNER_USER_PROFILE 
                                AND IsActive = true LIMIT 1];
        Partner_Agreement__c pa = [Select Quota__C,Expiry_date__c,Remaining_quota__C from Partner_Agreement__c where Partner_Account__c=:testAccount.Id limit 1];
        pa.Quota__C = 10;
        pa.Remaining_quota__C = 2;
        update pa;
        Map<String, Object> resultsMap = new Map<String, Object>();
        Test.startTest();
       
        System.runAs(partnerUser){
                resultsMap = PartnerApplicationService.retrievePartnerAgreementDetails(partnerUser.Id);
            }
        Test.stopTest();

        //Start assertion
        System.assertEquals(10, resultsMap.get('Quota'));
        System.assertEquals(2, resultsMap.get('RemainingQuota'));
      
    }
}