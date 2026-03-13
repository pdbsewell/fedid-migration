/*******************************************************************************
* @author		Ant Custodio
* @date         3.Aug.2017        
* @description  test class for StudFirst_SendEmailCE
* @revision     
*******************************************************************************/
@isTest
public with sharing class StudFirst_SendEmailCE_Test {
	private static Application__c appRecord;
	private static User communityUserRec;
	private static Contact contactRec;
	private static Application_Course_Preference__c coursePrefA;
	private static Course_Offering__c courseOfferingRec;
	private static Course_Offering__c courseOfferingRecNoUnit;

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         3.Aug.2017        
	* @description  tests the Send Email functionality on ACP
	* @revision     
	*******************************************************************************/
	static testMethod void test_sendEmailToAgent_HasACP() {
		//create a community user
		communityUserRec = StudFirst_TestHelper.createCommunityUser();
		//create required records
		createSampleData(communityUserRec.ContactId, 'Draft', 'TEST-STATUS', true);
		//sets the page
		Test.setCurrentPageReference(new PageReference('Page.StudFirst_GlobalActionSendEmail'));
		System.currentPageReference().getParameters().put('id', coursePrefA.Id);
		ApexPages.StandardController sc = new ApexPages.standardController(coursePrefA); 
		Test.startTest();
		
		//1st Scenario: no case ready yet
		StudFirst_SendEmailCE cont = new StudFirst_SendEmailCE(sc);
		//action called on page load
		cont.createCaseIfNoneRelated();

		///2nd Scenario: case is already present, reuse the case
		cont = new StudFirst_SendEmailCE(sc);
		//action called on page load
		cont.createCaseIfNoneRelated();
		Test.stopTest();
		Case retEnquiry = [SELECT Notify_Agent__c,is_Visible_to_External_Stakeholder__c FROM Case WHERE Application_Course_Preference__c =: coursePrefA.Id];
		//make sure a case has Notify Agent/is Visible to External Stakeholder assigned to true
		Assert.areEqual(true , retEnquiry.Notify_Agent__c, 'Notify Agent must be true');
		Assert.areEqual(true , retEnquiry.is_Visible_to_External_Stakeholder__c, 'is_Visible_to_External_Stakeholder__c must be true');
	}

	/*******************************************************************************
	* @author       Kristian Vegerano
	* @date         29.Sep.2020        
	* @description  tests the Send Email functionality on ACP for MUM
	* @revision     
	*******************************************************************************/
	static testMethod void test_sendEmailToAgent_MUM_HasACP() {
		//create a community user
		communityUserRec = StudFirst_TestHelper.createCommunityUser();
		//create required records
		createSampleData(communityUserRec.ContactId, 'Draft', 'TEST-STATUS', true);

		//Set the ACP's Location to Malaysia
		coursePrefA.Location_Code__c = 'Malaysia';
		update coursePrefA;
		
		//sets the page
		Test.setCurrentPageReference(new PageReference('Page.StudFirst_GlobalActionSendEmail'));
		System.currentPageReference().getParameters().put('id', coursePrefA.Id);
		ApexPages.StandardController sc = new ApexPages.standardController(coursePrefA); 
		Test.startTest();
		
		//1st Scenario: no case ready yet
		StudFirst_SendEmailCE cont = new StudFirst_SendEmailCE(sc);
		//action called on page load
		cont.createCaseIfNoneRelated();

		///2nd Scenario: case is already present, reuse the case
		cont = new StudFirst_SendEmailCE(sc);
		//action called on page load
		cont.createCaseIfNoneRelated();

	
		Test.stopTest();
		Case retEnquiry = [SELECT Status,Notify_Agent__c,is_Visible_to_External_Stakeholder__c FROM Case WHERE Application_Course_Preference__c =: coursePrefA.Id];
		//make sure the case has Notify Agent/is Visible to External Stakeholder assigned to true
		Assert.areEqual('Draft' , retEnquiry.Status, 'The status must be Draft');
		Assert.areEqual(true , retEnquiry.Notify_Agent__c, 'Notify Agent must be true');
		Assert.areEqual(true , retEnquiry.is_Visible_to_External_Stakeholder__c, 'is_Visible_to_External_Stakeholder__c must be true');
	
	}
	
	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         3.Aug.2017        
	* @description  tests the Send Email functionality on ACP
	*				2nd Scenario: no ACP Id found
	* @revision     
	*******************************************************************************/
	static testMethod void test_sendEmailToAgent_NoACP() {
		//create a community user
		communityUserRec = StudFirst_TestHelper.createCommunityUser();
		//create required records
		createSampleData(communityUserRec.ContactId, 'Draft', 'TEST-STATUS', true);
		ApexPages.StandardController sc = new ApexPages.standardController(coursePrefA); 

		Test.startTest();

		StudFirst_SendEmailCE cont = new StudFirst_SendEmailCE(sc);

		//make sure no case is created
		System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Application_Course_Preference__c =: coursePrefA.Id], 'Case not created');

		Test.stopTest();
	}

	/*******************************************************************************
	* @author       Anterey Custodio
	* @date         3.Aug.2017        
	* @description  creates full application sample data
	* @revision     
	*******************************************************************************/
	static void createSampleData (String contactId, String status, String outcome, Boolean addCourse) {
		AgentMgmtTestUtil.loadAgenciesTestDataNoIntegration();
		// Fetched test agency being setup
		List<Account> agency = [    
			SELECT 
				Id
				, Name 
				, Monash_AM_Web_Status__c
			FROM Account 
			WHERE Callista_Org_Unit_Code__c = 'TAG1000'];
		//create a new draft application
		appRecord = StudFirst_TestHelper.createApplication(contactId);
		appRecord.Agent__c = agency[0].Id;
		appRecord.OwnerId = communityUserRec.Id;
		appRecord.Status__c = status;
		// appRecord.Agent_Email__c = 'agentEmail@agents.com';
		insert appRecord;

		contactRec = [SELECT Id FROM Contact WHERE Id =: contactId];
		contactRec.Residency_Status__c = 'DOM-AUS';
		contactRec.Personal_Email__c = 'testme@testers.orgx';
		contactRec.Monash_Email_Address__c = 'testme@testermonash.orgx';
		contactRec.IT_account_disabled__c = false;
		update contactRec;

		//Tertiary institution & qualification
		Institution__c tertInsRec = StudFirst_TestHelper.createTertiaryInstitution();
		insert tertInsRec;

		Callista_Outcome_Status__c outcomeStatus = StudFirst_TestHelper.createOutcomeStatus();
		insert outcomeStatus;

		Contact_Qualification__c conQualRec = new Contact_Qualification__c();
		conQualRec.Country__c = 'Australia';
		conQualRec.First_Year_Enrolled__c = String.valueOf(date.today().year()-4);
		conQualRec.Last_Year_Enrolled__c = String.valueOf(date.today().year());
		conQualRec.Other_Qualification__c = 'Certificate III';
		conQualRec.Institution_Code__c = tertInsRec.Institution_Code__c;
		conQualRec.Institution_Name__c = tertInsRec.Institution_Name__c;
		conQualRec.Status__c = 'CURRENTLY STUDYING';
		conQualRec.Contact__c = contactRec.Id;
		conQualRec.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get('Tertiary Education').getRecordTypeId();
		insert conQualRec;

		Application_Qualification_Provided__c aqpRecord = new Application_Qualification_Provided__c();
		aqpRecord.Application__c = appRecord.Id;
		aqpRecord.Contact_Qualification__c = conQualRec.Id;
		insert aqpRecord;

		Work_Experience__c workExpRecord = new Work_Experience__c();
		workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);
		workExpRecord.Contact__c = contactRec.Id;
		insert workExpRecord;

		Contact_Document__c contactDocu = new Contact_Document__c();
		contactDocu = StudFirst_TestHelper.createContactDocument(contactRec.Id);
		insert contactDocu;

		Application_Work_Experience_Provided__c aweRecord = new Application_Work_Experience_Provided__c();
		aweRecord.Application__c = appRecord.Id;
		aweRecord.Work_Experience__c = workExpRecord.Id;
		insert aweRecord;

		Course__c courseRec = StudFirst_TestHelper.createCourse();
		insert courseRec;

		courseOfferingRec = StudFirst_TestHelper.createCourseOffering(courseRec);
		insert courseOfferingRec;

		courseOfferingRecNoUnit = StudFirst_TestHelper.createCourseOfferingNoUnitSet(courseRec);
		insert courseOfferingRecNoUnit;

		if(addCourse){
			coursePrefA = StudFirst_TestHelper.createCoursePreferences(appRecord, contactRec, courseOfferingRec, courseRec);
			coursePrefA.Outcome_Status__c = outcome;
			coursePrefA.Offer_Response_Status__c = outcome;
			coursePrefA.Preference_Number__c = '1';
			insert coursePrefA;
		}
	}

	
}