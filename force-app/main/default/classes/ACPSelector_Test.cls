/**
 * @author      Kristian Vegerano
 * @description Test class for ACPSelector class
 * @group       Test Class
 * @revision    13/12/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=false) // FIELD_CUSTOM_VALIDATION_EXCEPTION, System.DmlException: Insert failed. First exception on row 0; first error: APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: SourceMember
public with sharing class ACPSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
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
        testOffering.Mix_Unique_Id__c = '1234567';
        insert testOffering;

        //Create test ACP
        Application_Course_Preference__c testACP = StudFirst_TestHelper.createCoursePreferences(testApplication, testContact, testOffering, testCourse);
        testACP.Preference_Number__c = '1';
        insert testACP;

        //Submit the application
        testApplication.Status__c = 'Submitted';
        testApplication.Residency_Status__c = 'DOM-AUS';
        update testApplication;

        //Added list of values reference records
        List<List_of_Values__c> lstOfValues = new List<List_of_Values__c>();
        List_of_Values__c lov1 = new List_of_Values__c();
            lov1.Value__c = 'PENDING';
            lov1.Type__c =    'ADM_DOC_STATUS';
            lov1.System_Code_Description__c = 'DOCUMENTARY EVIDENCE NOT YET ASSESSED';
            lov1.System_Code__c = 'PENDING';
        lstOfValues.add(lov1);
        List_of_Values__c lov2 = new List_of_Values__c();
            lov2.Value__c = 'NOT-APPLIC';
            lov2.Type__c =    '  ADM_OFFER_DFRMNT_STATUS';
            lov2.System_Code_Description__c = 'DEFERRAL OF ADMISSION NOT ALLOWED';
            lov2.System_Code__c = 'NOT-APPLIC';
        lstOfValues.add(lov2);
        List_of_Values__c lov5 = new List_of_Values__c();
        	lov5.Value__c = 'NOT-APPLIC';
            lov5.Type__c =    'ADM_OFFER_RESP_STATUS';
            lov5.System_Code_Description__c = 'RESPONSE TO OFFER NOT REQUIRED';
            lov5.System_Code__c = '  NOT-APPLIC';
            lov5.Government_Code__c = '6';
            lov5.Description__c = 'Applicant is not required to respond';
        lstOfValues.add(lov5);
        List_of_Values__c lov6 = new List_of_Values__c();
            lov6.Value__c = 'NOT-APPLIC';
            lov6.Type__c =    'ADM_CNDTNL_OFFER_STATUS';
            lov6.System_Code_Description__c = 'NO CONDITIONS ATTACHED TO OFFER';
            lov6.System_Code__c = 'NOT-APPLIC';
        lstOfValues.add(lov6);
        List_of_Values__c lov3 = new List_of_Values__c();
            lov3.Value__c = 'PENDING';
            lov3.Type__c =    'ADM_ENTRY_QUAL_STATUS';
            lov3.System_Code_Description__c = 'ENTRY QUALIFICATIONS YET TO BE DETERMINED';
            lov3.System_Code__c = 'PENDING';
        lstOfValues.add(lov3);
        List_of_Values__c lov4 = new List_of_Values__c();
            lov4.Value__c = 'AP-PROGRES';
            lov4.Type__c =    'ADM_OUTCOME_STATUS';
            lov4.System_Code_Description__c = 'APPLICATION UNDER CONSIDERATION';
            lov4.System_Code__c = 'AP-PROGRES';
        lstOfValues.add(lov4);
        insert lstOfValues;
    }

    /**
     * @description Test select accounts by Id
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        Set<Id> acpIds = new Set<Id>();
        List<Application_Course_Preference__c> testAcpList = new List<Application_Course_Preference__c>();

        //Retrieve existing account ids
        for(Application_Course_Preference__c loopACP : [SELECT Id FROM Application_Course_Preference__c LIMIT 10]){
            acpIds.add(loopACP.Id);
        }

        //Start test process
	 	Test.startTest();
            testAcpList.addAll(new ACPSelector().selectById(acpIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(1, testAcpList.size());
    }

    @isTest
    static void test_acp_offers(){
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        new ACPSelector().selectOfferedByApplicantId(testContact.Id);
    }

    @isTest static void test_selectOfferedById(){
        Application_Course_Preference__c source = [SELECT Id FROM Application_Course_Preference__c LIMIT 1];
        Application_Course_Preference__c target = new ACPSelector().selectOfferedById(source.Id);
        System.assert(target.Id == source.Id, 'Query looks good.');
    }

    /**
     * @description Test select application course preferences by application id
     */
    @isTest 
    static void test_SelectByApplicationId() {
        //Initialize variables
        Set<Id> applicationIds = new Set<Id>();
        List<Application_Course_Preference__c> testAcpList = new List<Application_Course_Preference__c>();

        //Retrieve existing course prerequisite ids
        for(Application__c loopCoursePrerequisite : [SELECT Id FROM Application__c LIMIT 10]){
            applicationIds.add(loopCoursePrerequisite.Id);
        }

        //Start test process
	 	Test.startTest();
         testAcpList.addAll(new ACPSelector().selectByApplicationId(applicationIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(1, testAcpList.size());
    }

    /** 
     * @author Shalini Mendu
     * @date 02/11/2021
     * @description Tests to ensure INDONESIA campus will fetch ACP records to show on the Offer wizard
     */
    @isTest
    static void test_INDO_acp_offers(){
        //Initialize variables
        Set<Id> applicationIds = new Set<Id>();
        List<Application_Course_Preference__c> testAcpList = new List<Application_Course_Preference__c>();

        List<Application__c> appList = [SELECT Id,Campus_Location__c FROM Application__c LIMIT 10];
        for(Application__c app :appList){
            app.Campus_Location__c = 'INDONESIA';
        }
        update appList;

        //Retrieve existing course prerequisite ids
        for(Application__c loopCoursePrerequisite : [SELECT Id FROM Application__c LIMIT 10]){
            applicationIds.add(loopCoursePrerequisite.Id);
        }
   
        //Start test process
	 	Test.startTest();
            testAcpList.addAll(new ACPSelector().selectByApplicationId(applicationIds));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(1, testAcpList.size());
    }

    /** 
     * @author      Kristian Vegerano
     * @date        02/11/2021
     * @description Tests to ensure applications for Malaysia campus and Study Type of Study Abroad will fetch ACP records to show on the Offer wizard
     */
    @isTest
    static void test_MalaysiaAcpOffers(){
        //Initialize variables
        Set<Id> applicationIds = new Set<Id>();
        List<Application_Course_Preference__c> testAcpList = new List<Application_Course_Preference__c>();

        List<Application__c> appList = [SELECT Id,Campus_Location__c FROM Application__c LIMIT 1];
        for(Application__c app :appList){
            app.Campus_Location__c = 'Malaysia';
            app.Type_of_Study__c = Constants.MONASH_ABROAD_SA_STUDY_TYPE;
        }
        update appList;
   
        //Start test process
	 	Test.startTest();
            testAcpList.addAll(new ACPSelector().selectOfferedByApplicantId(appList[0].Id));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(0, testAcpList.size());
    }

    /** 
     * @author      Kristian Vegerano
     * @date        02/11/2021
     * @description Tests to ensure applications for Malaysia campus and Study Type of Study Abroad will fetch ACP records to show on the Offer wizard - should have no result
     */
    @isTest
    static void test_MalaysiaAcpOffersNoResult(){
        //Initialize variables
        Set<Id> applicationIds = new Set<Id>();
        List<Application_Course_Preference__c> testAcpList = new List<Application_Course_Preference__c>();

        List<Application__c> appList = [SELECT Id, Campus_Location__c FROM Application__c LIMIT 1];
        for(Application__c app :appList){
            app.Campus_Location__c = 'Malaysia';
            app.Type_of_Study__c = 'Coursework';
        }
        update appList;
   
        //Start test process
	 	Test.startTest();
            testAcpList.addAll(new ACPSelector().selectOfferedByApplicantId(appList[0].Id));
	 	Test.stopTest();

        //Start assertion
        System.assertEquals(0, testAcpList.size());
    }
}