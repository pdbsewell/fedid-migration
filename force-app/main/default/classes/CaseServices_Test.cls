/**
* @author Angelo Rivera
* @date 07.01.2020
* @group Test Class
* @description  Test Class to test the functionality of CaseServices
* @revision     APRivera, 07.January.2019 - Fixed and Increase Code Coverage <br/>
*/
@isTest(isParallel=true)
private class CaseServices_Test {
	// Set up test data that will be used across all test methods
	@testSetup
	static void setup(){
		//Populate custom settings
		MonConTestDataFactory.createSObject(new RecordTypes_Allowed_on_CaseTrigger__c(), true);
		MonConTestDataFactory.createSObject(new Environment_Settings__c(), true);
		MonConTestDataFactory.createSObject(new CalabrioIntegration__c(), true);
	}


	// test all other methods from CaseServices
	@IsTest
	static void test_Other(){
		Test.startTest();
		Id professionalYearRecId = CaseServices.CASE_PROFESSIONALYEAR_RECTYPE;
		Id professionalYearQueueId = CaseServices.CASE_PROFESSIONALYEAR_QUEUE;
		Id professionalFutureQueueId = CaseServices.CASE_PROFESSIONALFUTUREYEAR_QUEUE;
		CaseServices.storeExLog('test_Other', 'CaseServices', 'test_Other', 'Test');
		Test.stopTest();

		System.assertNotEquals(null, professionalYearRecId);
		System.assertNotEquals(null, professionalYearQueueId);
		System.assertNotEquals(null, professionalFutureQueueId);
	}

	// test clearLastEmailReceived method
	@IsTest
	static void test_clearLastEmailReceived(){
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		cse.Latest_Inbound_Email__c = System.now();
		insert cse;

		Test.startTest();
		cse.Status = 'Pending Investigation';
		update cse;

		Task tsk = new Task(WhatId=cse.Id, Subject='Test task');
		insert tsk;
		Test.stopTest();

		Case c = [SELECT Id, Latest_Inbound_Email__c FROM Case where Id =: cse.Id];
		System.assertEquals(null, c.Latest_Inbound_Email__c);
	}

	/**
	 * @author                  Kristian Vegerano
	 * @description             Test method that tests sending email message when the MGE Form stack form is submitted with an attachment
	 */
	@istest
	static void testMgeDefaultValuesIncludeAttachmentOnEmailToFaculty(){
		//Initialize variables
		Id mgeRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MGE_Enquiry').getRecordTypeId();

		//Create test contact to associate the enquiry with
		Contact testContact = new Contact(LastName = 'TestContact');
		insert testContact;

		//Create test mge enquiry
		List<Case> enquiryList = new List<Case>();
		for(Integer counter = 0; counter < 5; counter++){
			enquiryList.add(new Case(Subject = 'Test MGE Enquiry',
					ContactId = testContact.Id,
					RecordTypeId = mgeRecordTypeId,
					Origin = 'Web - Research Deferral Request',
					File_Attachment__c = 'www.testlink.com'));
		}
		insert enquiryList;

		//Create test attachments
		List<Attachment> attachmentList = new List<Attachment>();
		for(Case loopCase : enquiryList){
			attachmentList.add(new Attachment(Name = String.valueOf('test.txt'),
					Body = Blob.valueOf('TestAttachmentContent'),
					ParentId = loopCase.Id));
		}

		//Retrieve system email sends actual count before test
		System.assert(0 == [SELECT Id FROM AsyncApexJob].size());

		//Start test
		Test.StartTest();
		//Create test attachments
		insert attachmentList;
		Test.StopTest();

		//Retrieve system email sends actual count after test
		System.assert(0 < [SELECT Id FROM AsyncApexJob].size());
	}

}