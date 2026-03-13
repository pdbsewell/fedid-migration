/**
 * @author      Kristian Vegerano
 * @description Test class for DocumentChecklistParserServices class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
public with sharing class DocumentChecklistParserServices_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        //Create country record
        Country_Attribute__c countryRec = new Country_Attribute__c ();
        countryRec.Name = 'AUSTRALIA';
        countryRec.Country__c = 'Australia';
        countryRec.Regional_Manager__c = UserInfo.getUserId();
        insert countryRec;

        //Create agency
        Schema.RecordTypeInfo agencyRTByName = Account.SObjectType.getDescribe().getRecordTypeInfosByName().get('Agency');

        //Create test agency
        Account agencyRecord = new Account();
        agencyRecord.RecordTypeId = agencyRTByName.getRecordTypeId();
        agencyRecord.Name = 'test agency 1';
        agencyRecord.Phone = '12345';
        agencyRecord.Email__c = 'test@agency.com';
        agencyRecord.Website = 'www.test-agency-1.com';
        agencyRecord.Street__c = '123 testing st';
        agencyRecord.City__c = 'Melbourne';
        agencyRecord.State__c = 'VIC';
        agencyRecord.Post_Code__c = '3000';
        agencyRecord.Country_Lookup__c = countryRec.Id;
        agencyRecord.ShippingStreet = '123 testing st';
        agencyRecord.ShippingCity = 'Melbourne';
        agencyRecord.ShippingState = 'VIC';
        agencyRecord.ShippingPostalCode = '3000';
        agencyRecord.ShippingCountry = 'Australia';
        agencyRecord.Monash_AM_Web_Status__c = true;
        agencyRecord.Callista_Org_Unit_Code__c = 'tagent1';
        agencyRecord.Monash_AM_Campus__c = 'Australia';
        agencyRecord.Status__c = 'Appointed';
        insert agencyRecord;

        //Create community user
        User testApplicant = StudFirst_TestHelper.createCommunityUser();
        Contact testContact = [SELECT Id FROM Contact WHERE Id =: testApplicant.contactId];

        //Create test Create application
        Application__c testApplication = StudFirst_TestHelper.createApplication(testContact.Id);
        insert testApplication;

        //Create test Course
        Course__c testCourse = StudFirst_TestHelper.createCourse();
        insert testCourse;

        //Create test Offering
        Course_Offering__c testOffering = StudFirst_TestHelper.createCourseOffering(testCourse);
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        insert testACP;

        //Submit the application
        testApplication.Status__c = 'Submitted';
        testApplication.Residency_Status__c = 'DOM-AUS';
        update testApplication;
    }

    /**
     * @description Tests alwaysSmallCaps
     */
    @isTest 
    static void test_AlwaysSmallCaps() {
        //Initialize variables
        Set<String> smallCapsList;

        //Start test process
	 	Test.startTest();
            smallCapsList = DocumentChecklistParserServices.alwaysSmallCaps;
	 	Test.stopTest();

        //Start assertion
        Assert.areNotEqual(smallCapsList, null);
    }

    /**
     * @description Tests alwaysBigCaps
     */
    @isTest 
    static void test_AlwaysBigCaps() {
        //Initialize variables
        Set<String> bigCapsList;

        //Start test process
	 	Test.startTest();
            bigCapsList = DocumentChecklistParserServices.alwaysBigCaps;
	 	Test.stopTest();

        //Start assertion
        Assert.areNotEqual(bigCapsList, null);
    }

    /**
     * @description Tests querySetup
     */
    @isTest 
    static void test_QuerySetup() {
        //Initialize variables
        Map<String, List<Document_Checklist_Parser_Setting__mdt>> resultMap;

        //Start test process
	 	Test.startTest();
            resultMap = DocumentChecklistParserServices.querySetup();
	 	Test.stopTest();

        //Start assertion
        Assert.areNotEqual(resultMap, null);
    }

    /**
     * @description Tests buildSoql
     */
    @isTest 
    static void test_BuildSoql() {
        //Initialize variables
        Set<String> testResults;
        Map<String, List<Document_Checklist_Parser_Setting__mdt>> parserSettingMap = DocumentChecklistParserServices.querySetup();

        //Start test process
	 	Test.startTest();
            for(String loopSetting : parserSettingMap.keySet()){
                testResults = DocumentChecklistParserServices.buildSoql(parserSettingMap.get(loopSetting));
            }
	 	Test.stopTest();

        //Start assertion
        Assert.areNotEqual(testResults, null);
    }

    /**
     * @description Tests capitalCase
     */
    @isTest 
    static void test_CapitalCase_Single() {
        //Initialize variables
        String resultString;

        //Start test process
	 	Test.startTest();
            resultString = DocumentChecklistParserServices.capitalCase('I');
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(resultString.trim(), 'i');
    }

    /**
     * @description Tests capitalCase
     */
    @isTest 
    static void test_CapitalCase_AllCaps() {
        //Initialize variables
        String resultString;

        //Retrieve items always small
        Set<String> bigCapsList = DocumentChecklistParserServices.alwaysBigCaps;

        //Start test process
	 	Test.startTest();
            resultString = DocumentChecklistParserServices.capitalCase(String.join(new List<String>(bigCapsList), ' '));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(resultString.trim(), String.join(new List<String>(bigCapsList), ' ').trim());
    }

    /**
     * @description Tests capitalCase
     */
    @isTest 
    static void test_CapitalCase_SmallCaps() {
        //Initialize variables
        String resultString;

        //Retrieve items always small
        Set<String> smallCapsList = DocumentChecklistParserServices.alwaysSmallCaps;
        for(String loopString : smallCapsList){
            loopString = loopString.toLowerCase();
        }

        //Start test process
	 	Test.startTest();
            resultString = DocumentChecklistParserServices.capitalCase(String.join(new List<String>(smallCapsList), ' '));
	 	Test.stopTest();
    }

    /**
     * @description Tests capitalCase
     */
    @isTest 
    static void test_CapitalCase_Initial() {
        //Initialize variables
        String resultString;

        //Start test process
	 	Test.startTest();
            resultString = DocumentChecklistParserServices.capitalCase('initial');
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(resultString.trim(), 'Initial');
    }

    /**
     * @description Tests parseString
     */
    @isTest 
    static void test_ParseString() {
        //Initialize variables
        String resultString;
        Map<String, List<Document_Checklist_Parser_Setting__mdt>> parserSettingMap = DocumentChecklistParserServices.querySetup();

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        
        //Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        //Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        testContactQualification.Year_of_Completion__c = '2000';
        insert testContactQualification;

        //Start test process
	 	Test.startTest();
            resultString = DocumentChecklistParserServices.parseString(parserSettingMap.get('Contact_Qualification__c'), new Map<String, Schema.DisplayType>(), testContactQualification, '[QUALIFICATION_COMPLETION_YEAR]');
	 	Test.stopTest();

        //Start assertion
        Assert.areNotEqual(resultString.trim(), '');
    }

    /**
     * @description Tests parseString Date
     */
    @isTest 
    static void test_ParseString_Date() {
        //Initialize variables
        String resultString;
        Map<String, List<Document_Checklist_Parser_Setting__mdt>> parserSettingMap = DocumentChecklistParserServices.querySetup();

        //Retrieve test applicant        
        Contact testApplicant = [SELECT Id FROM Contact LIMIT 1];

        //Retrieve test application
        Application__c testApplication = [SELECT Id, Applicant__c FROM Application__c LIMIT 1];
        
        //Create Qualifications
        Qualification__c testQualification = StudFirst_TestHelper.createQualification('Secondary');
        insert testQualification;

        //Create Contact Qualifications
        Contact_Qualification__c testContactQualification = StudFirst_TestHelper.createContactQualification(testApplicant, testQualification, 'Secondary Education');
        testContactQualification.Expected_date_of_completion__c = System.TODAY();
        insert testContactQualification;

        //Start test process
	 	Test.startTest();
            resultString = DocumentChecklistParserServices.parseString(parserSettingMap.get('Contact_Qualification__c'), new Map<String, Schema.DisplayType>(), testContactQualification, '[QUALIFICATION_EXPECTED_DATE]');
	 	Test.stopTest();

        //Start assertion
        Assert.areNotEqual(resultString.trim(), '');
    }
}