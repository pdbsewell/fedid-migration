/**
* @author Angelo Rivera
* @date 19.12.19
* @group Test Class
* @description  Test Class to test the functionality of ChatLog365DetailCC
* @revision     10/10/2019 - Steffi Narang - Created <br/>
*               15/12/2019 - APRivera - Fix test class and increase coverage <br/>
*/
@isTest(isParallel=true)
private class ChatLog365DetailCC_Test {

	static testMethod void testCaseBotTranscript(){
		//inserts contact to be linked to the case that will be generated after Chat 365 Log detail is created.
		Contact con = (Contact)MonConTestDataFactory.createSObject(new Contact(), true);

		//inserts Chat 365 Log - as if Chatbot was invoked by a user
		Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c(), true);

		//inserts Chat 365 Log and Detail - This generates enquiry ( intent = 1 : Submit an enquiry)
		Chat_365_Log_Detail__c chat365DetailLog = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
		chat365DetailLog.Chat_365_Log__c = chat365Log.Id;
		chat365DetailLog.Intent__c = 1;
		insert chat365DetailLog;

		//inserts Chat 365 Log and Detail - This generates enquiry ( intent = 4 : Live Chat Handover)
		Chat_365_Log_Detail__c chat365DetailLog1 = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
		chat365DetailLog1.Chat_365_Log__c = chat365Log.Id;
		chat365DetailLog1.Intent__c = 4;
		insert chat365DetailLog1;

		//inserts Chat 365 Log - as if Chatbot was invoked by a user
		Chat_365_Log__c chat365Log1 = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
		chat365Log1.Chat_Key__c = '123abc456defg';
		chat365Log1.Session_Id__c = '123abc456defg';
		insert chat365Log1;

		//inserts Chat 365 Log and Detail - This generates enquiry ( intent = 1 : Submit an enquiry)
		Chat_365_Log_Detail__c chat365DetailLog2 = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
		chat365DetailLog2.Chat_365_Log__c = chat365Log1.Id;
		chat365DetailLog2.Intent__c = 1;
		insert chat365DetailLog2;

		//retrieve the case that's generated.
		List<Case> lstCases = [SELECT Id FROM Case WHERE Chat_365_Log__c =: chat365Log.Id];
		Case case1 = [SELECT Id FROM Case WHERE Chat_365_Log__c =: chat365Log1.Id].get(0);

		//create chat request by inserting LiveChatVisitor
		LiveChatVisitor liveChatVisitor = new LiveChatVisitor();
		insert liveChatVisitor;

		//simulate agent accepting the chat request by inserting LiveChatTranscript with In Progress Status
		LiveChatTranscript lct = (LiveChatTranscript)MonConTestDataFactory.createSObject(new LiveChatTranscript());
		lct.LiveChatVisitorId = liveChatVisitor.Id;
		lct.CaseId = lstCases.get(0).Id;
		insert lct;

		Test.startTest();
			// LiveChatTranscript Id will be passed to the Chatbot Transcripts controller
			ChatLog365DetailCC.getChatbotTranscript(chat365Log.Id);

			// LiveChatTranscript Id will be passed to the Chatbot Transcripts controller
			ChatLog365DetailCC.getChatbotTranscript(lct.Id);

			// Case Id will be passed to the Chatbot Transcripts controller
			ChatLog365DetailCC.getChatbotTranscript(lstCases.get(0).Id);

			// Case ChatLog365DetailCC will be passed to the Chatbot Transcripts controller
			ChatLog365DetailCC.getChatbotTranscript(lstCases.get(1).Id);

			// Case Id will be passed to the Chatbot Transcripts controller
			ChatLog365DetailCC.getChatbotTranscript(case1.Id);

			// Test exception
			ChatLog365DetailCC.getChatbotTranscript(con.Id);

		Test.stopTest();

		System.assertEquals(3,[SELECT Id FROM Case].size());

	}
}