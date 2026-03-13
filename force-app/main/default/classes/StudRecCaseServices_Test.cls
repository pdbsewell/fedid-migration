/**
* @author Angelo Rivera
* @date 09.Jan.2020
* @group Test Class
* @description  Test Class to test the functionality of MonConCaseServices
* @revision     APRivera, 09.Jan.2020 - Created <br/>
*/

@isTest(isParallel=true)
private class StudRecCaseServices_Test {
	@IsTest
	static void testBehavior() {
		Test.startTest();
		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact());
		con.Person_ID_unique__c ='213786327';
		insert con;

		Application__c application = (Application__c)MonConTestDataFactory.createSObject(new Application__c());
		application.Applicant__c = con.Id;
		insert application;

		Application_Course_Preference__c appCrsPref = (Application_Course_Preference__c)MonConTestDataFactory.createSObject(new Application_Course_Preference__c());
		appCrsPref.Application__c = application.Id;
		insert appCrsPref;

		Case cse = (Case)MonConTestDataFactory.createSObject(new Case());
		cse.RecordTypeId = StudRecCaseServices.POST_APPLICATION_RECTYPEID;
		cse.Monash_Student_Form_ID__c = '213786327';
		cse.Monash_Application_ID__c = '123456789';
		insert cse;
		Test.stopTest();

		Case c = [SELECT ContactId FROM Case LIMIT 1];
		System.assertNotEquals(null, c.ContactId);

	}
}