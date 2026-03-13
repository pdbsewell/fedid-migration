/**
* @author Angelo Rivera
* @date 19.12.19
* @group Test Class
* @description  Test Class to test the functionality of Chat365LogTriggerHandler
* @revision     15/12/2019 - Creation
				17 March 2020 - Cartick Sub - Linked Contact tests
*/

@isTest(isParallel=true)
private class Chat365LogTriggerHandler_Test {

	/**
	 * This is to test update event on the triggerhandler
	 */
	@IsTest
	static void testFeedbackUpdate() {
		Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
		insert chat365Log;
		Test.startTest();
			chat365Log.Feedback_Comment__c = 'This is a test comment.';
			chat365Log.Feedback_Rating__c = 10;
			update chat365Log;
		Test.stopTest();
		List<Survey__c> lstSurvey = [SELECT Id FROM Survey__c];
		System.assertEquals(1,lstSurvey.size());
	}

	/**
	 * This is to test exception
	 */
	@IsTest
	static void testException() {
		Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
		insert chat365Log;
		Test.startTest();
			chat365Log.Feedback_Comment__c = 'This is a test comment.';
			chat365Log.Feedback_Rating__c = 100;
			update chat365Log;
		Test.stopTest();
		List<Survey__c> lstSurvey = [SELECT Id FROM Survey__c];
		System.assertEquals(0,lstSurvey.size());
	}

	/**
	@description Test method to validate if, on insert of a Chat 365 Log, the correct student Contact is linked
	@revision Initial version 17 March 2020
	**/
	@IsTest
	public static void validateLinkStudentContactOnInsert() {

		Test.startTest();
		Contact testStudentContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Chat_365_Log__c testLog = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c(), true);
		Test.stopTest();

		List<Chat_365_Log__c> testLogFromDB = [SELECT Id, Contact__c FROM Chat_365_Log__c];

		System.assertEquals(testStudentContact.Id, testLogFromDB[0].Contact__c, 'Student Contact not linked to Chat 365 Log');

	}

	/**
	@description Test method to validate if, on update of a Chat 365 Log to add an Id Number, the correct student Contact is linked
	@revision Initial version 17 March 2020
	**/
	@IsTest
	public static void validateLinkStudentContactOnUpdate() {

		Test.startTest();
		Contact testStudentContact = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);
		Chat_365_Log__c testLog = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
		testLog.Id_Number__c = '';
		insert testLog;
		testLog.Id_Number__c = '12345678';
		update testLog;
		Test.stopTest();

		List<Chat_365_Log__c> testLogFromDB = [SELECT Id, Contact__c FROM Chat_365_Log__c];

		System.assertEquals(testStudentContact.Id, testLogFromDB[0].Contact__c, 'Student Contact not linked to Chat 365 Log');
	}

	/**
	@description Test method to validate if, on insert of a Chat 365 Log, the correct staff Contact is linked
	@revision Initial version 17 March 2020
	**/
	@IsTest
	public static void validateLinkStaffContactOnInsert() {

		Test.startTest();
		Contact testStaffContact = (Contact)MonConTestDataFactory.createSObject(new Contact());
		testStaffContact.SAP_Staff_Id__c = '12345678';
		insert testStaffContact;

		Chat_365_Log__c testLog = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
		testLog.Account_Type__c = 2;
		insert testLog;
		Test.stopTest();

		List<Chat_365_Log__c> testLogFromDB = [SELECT Id, Contact__c FROM Chat_365_Log__c];

		System.assertEquals(testStaffContact.Id, testLogFromDB[0].Contact__c, 'Staff Contact not linked to Chat 365 Log');
	}

	/**
	@description Test method to validate if, on update of a Chat 365 Log to add an Id Number, the correct staff Contact is linked
	@revision Initial version 17 March 2020
	**/
	@IsTest
	public static void validateLinkStaffContactOnUpdate() {

		Test.startTest();
		Contact testStaffContact = (Contact)MonConTestDataFactory.createSObject(new Contact());
		testStaffContact.SAP_Staff_Id__c = '12345678';
		insert testStaffContact;

		Chat_365_Log__c testLog = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
		testLog.Id_Number__c = '';
		insert testLog;
		testLog.Id_Number__c = '12345678';
		update testLog;
		Test.stopTest();

		List<Chat_365_Log__c> testLogFromDB = [SELECT Id, Contact__c FROM Chat_365_Log__c];

		System.assertEquals(testStaffContact.Id, testLogFromDB[0].Contact__c, 'Staff Contact not linked to Chat 365 Log');
	}
}