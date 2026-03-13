/**
* @author Angelo Rivera
* @date 19.12.19
* @group Test Class
* @description  Test Class to test the functionality of Chat365LogDetailTriggerHandler
* @revision     15/12/2019 - Creation <br/>
*/

@isTest(isParallel=true)
private class Chat365LogDetailTriggerHandler_Test {

	/**
	 * This is to test insert event on the triggerhandler
	 */
	@IsTest
	static void testInsert() {
		Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c(), true);
		Chat_365_Log_Detail__c chat365DetailLog1 = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
		Chat_365_Log_Detail__c chat365DetailLog2 = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
		chat365DetailLog1.Chat_365_Log__c = chat365Log.Id;
		chat365DetailLog2.Chat_365_Log__c = chat365Log.Id;
		chat365DetailLog1.Intent__c = 1;
		chat365DetailLog2.Intent__c = 4;
		Test.startTest();
			insert chat365DetailLog1;
			insert chat365DetailLog2;
		Test.stopTest();
		Chat_365_Log__c chat365Log2 = [SELECT Id, (SELECT Id FROM Enquiries__r) from Chat_365_Log__c where Id=: chat365Log.Id];
		System.assertEquals(2,chat365Log2.Enquiries__r.size());
	}
}