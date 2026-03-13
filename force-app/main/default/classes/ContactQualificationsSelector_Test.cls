/**
 * @author      Kristian Vegerano
 * @description Test class for AccountSelector class
 * @group       Test Class
 * @revision    16/09/2019 - Kristian Vegerano - Created
 */
@isTest(isParallel=true)
public with sharing class ContactQualificationsSelector_Test {
    /**
     * @description Setup test data
     */
    @testSetup 
    static void setup() {
        //Create test applicant
        User applicant = StudFirst_TestHelper.createCommunityUser();

        //Create test contact
        Contact c = [SELECT id FROM Contact WHERE id =: applicant.contactId];

        //Create Qualifications
        Qualification__c qual1 = StudFirst_TestHelper.createQualification('Secondary');
        insert qual1;

        //Create Contact Qualifications
        Contact_Qualification__c cq1 = StudFirst_TestHelper.createContactQualification(c, qual1, 'Secondary Education');
        insert cq1;
        
        //Create Application
        Application__c application = StudFirst_TestHelper.createApplication(c);
        insert application;
        //Create Junction object record for Contact Qualification <-> Application
        Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c(Contact_Qualification__c = cq1.id, Application__c = application.id);
        insert aqp;
    }

    /**
     * @description Test select contact qualification by Id
     */
    @isTest 
    static void test_SelectById() {
        //Initialize variables
        Set<Id> contactQualificationIds = new Set<Id>();
        List<Contact_Qualification__c> testContactQualificationList = new List<Contact_Qualification__c>();

        //Retrieve existing account ids
        for(Contact_Qualification__c loopContactQualification : [SELECT Id FROM Contact_Qualification__c LIMIT 10]){
            contactQualificationIds.add(loopContactQualification.Id);
        }

        //Start test process
	 	Test.startTest();
            testContactQualificationList.addAll(new ContactQualificationsSelector().selectById(contactQualificationIds));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(1, testContactQualificationList.size());
    }

    /**
     * @description Test select contact qualification by Id override permissions
     */
    @isTest 
    static void test_SelectByIdOverride() {
        //Initialize variables
        Set<Id> contactQualificationIds = new Set<Id>();
        List<Contact_Qualification__c> testContactQualificationList = new List<Contact_Qualification__c>();

        //Retrieve existing account ids
        for(Contact_Qualification__c loopContactQualification : [SELECT Id FROM Contact_Qualification__c LIMIT 10]){
            contactQualificationIds.add(loopContactQualification.Id);
        }

        //Start test process
	 	Test.startTest();
            testContactQualificationList.addAll(new ContactQualificationsSelector(true).selectById(contactQualificationIds));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(1, testContactQualificationList.size());
    }

    /**
     * @description Test select contact qualification by Id
     */
    @isTest 
    static void test_SelectByContactId() {
        //Initialize variables
        Set<Id> contactIds = new Set<Id>();
        List<Contact_Qualification__c> testContactQualificationList = new List<Contact_Qualification__c>();

        //Retrieve existing account ids
        for(Contact loopContact : [SELECT Id FROM Contact LIMIT 10]){
            contactIds.add(loopContact.Id);
        }

        //Start test process
	 	Test.startTest();
            testContactQualificationList.addAll(new ContactQualificationsSelector().selectByContactId(contactIds));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(1, testContactQualificationList.size());
    }
    /**
     * @description Test select contact qualification by ApplicationId
     */
    @isTest 
    static void test_SelectByApplicationId() {
        //Initialize variables
		List<Contact_Qualification__c> testContactQualificationList = new List<Contact_Qualification__c>();
		Map<Id, Application__c> mapAppns = new Map<Id, Application__c> ([SELECT id FROM Application__c LIMIT 10]);
        
        //Start test process
	 	Test.startTest();
            testContactQualificationList.addAll(new ContactQualificationsSelector().selectByApplicationId(mapAppns.keySet()));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(1, testContactQualificationList.size());
    }

    /**
     * @description Test select contact qualification by ApplicationId
     */
    @isTest 
    static void test_SelectQualificationsWithDocumentsByApplicationId() {
        //Initialize variables
		List<Contact_Qualification__c> testContactQualificationList = new List<Contact_Qualification__c>();
		Map<Id, Application__c> mapAppns = new Map<Id, Application__c> ([SELECT id FROM Application__c LIMIT 10]);
        
        //Start test process
	 	Test.startTest();
            testContactQualificationList.addAll(new ContactQualificationsSelector().selectQualificationsWithDocumentsByApplicationId(mapAppns.keySet()));
	 	Test.stopTest();

        //Start assertion
        Assert.areEqual(1, testContactQualificationList.size());
    }
}