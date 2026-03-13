/**
* @author Angelo Rivera
* @date 15.Jan.2020
* @group Test Class
* @description  Test Functionality of EnquiryInterestTriggerHandler
* @revision     APRivera, 15.Jan.2020 - Created <br/>
*/

@isTest(isParallel=true)
private class EnquiryInterestTriggerHandler_Test {
	@IsTest
	static void test_linkInterestsToPerson(){
		Test.startTest();
		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		cse.ContactId = con.Id;
		cse.Enquiry_Type__c = 'Future Course';
		insert cse;
		Enquiry_Interest__c enquiryInterest = (Enquiry_Interest__c)MonConTestDataFactory.createSObject(new Enquiry_Interest__c());
		enquiryInterest.Study_Area__c = 'Engineering';
		enquiryInterest.Case__c = cse.Id;
		insert enquiryInterest;
		Test.stopTest();
		Assert.isNotNull([SELECT Person__c from Enquiry_Interest__c].Person__c);
	}


	@IsTest
	static void test_preventDeletionOnClosedCases(){
		Test.startTest();
		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		cse.ContactId = con.Id;
		cse.Enquiry_Type__c = 'Future Course';
		insert cse;
		Enquiry_Interest__c enquiryInterest = (Enquiry_Interest__c)MonConTestDataFactory.createSObject(new Enquiry_Interest__c());
		enquiryInterest.Study_Area__c = 'Engineering';
		enquiryInterest.Case__c = cse.Id;
		insert enquiryInterest;
		cse.Status = 'Solved';
		update cse;
		delete enquiryInterest;
		Test.stopTest();
	}
}