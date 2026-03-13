/**
* @author Steffi Narang
* @date 24.09.19
* @group Test Class
* @description Test Class to test the functionality of MonashChat365TriggerHandler
* @revision 24.09.19 - Steffi Narang - Created <br/>
*           20.12.19 - Angelo Rivera - Fixed and increased code coverage to 100% <br/>
*/

@isTest(isParallel=true)
private class MonashChat365TriggerHandler_Test{

    // test scenario of accepting chat request
    @isTest
    private static void test_UpdateChatTranscript(){
        //inserting chat362log..
        Chat_365_Log__c chatLog = new Chat_365_Log__c();
        chatLog.Bot_Name__c ='Chat365Bot';
        chatLog.Session_Id__c='101010';
        chatLog.Email__c= 'test.test@monash.edu';
        chatLog.Account_Type__c =1;
        chatLog.Id_Number__c ='12345678';
        chatLog.Feedback_Comment__c='test1';
        chatLog.Bot_Name__c ='tester';
        chatLog.Feedback_Rating__c =5;
        chatLog.Chat_Agent_Availability_Status__c ='Available';
        insert chatLog;

        //create chat request by inserting LiveChatVisitor
        LiveChatVisitor liveChatVisitor = new LiveChatVisitor();
        insert liveChatVisitor;

        LiveChatTranscript lct = (LiveChatTranscript)MonConTestDataFactory.createSObject(new LiveChatTranscript());
        lct.LiveChatVisitorId = liveChatVisitor.Id;
        lct.Status = '';
        lct.Chat_365_Log__c = chatLog.Id;
        insert lct;

        LiveChatTranscriptEvent le = new LiveChatTranscriptEvent();
        le.LiveChatTranscriptId = lct.id;
        le.type = 'ChatRequest';
        le.time = system.now();
        insert le;

        LiveChatTranscriptEvent le1 = new LiveChatTranscriptEvent();
        le1.LiveChatTranscriptId = lct.id;
        le1.type = 'Enqueue';
        le1.time = system.now();
        insert le1;

        LiveChatTranscriptEvent le3 = new LiveChatTranscriptEvent();
        le3.LiveChatTranscriptId = lct.id;
        le3.type = 'PushAssignment';
        le3.time = system.now();
        insert le3;

        LiveChatTranscriptEvent le2 = new LiveChatTranscriptEvent();
        le2.LiveChatTranscriptId = lct.id;
        le2.type = 'Accept';
        le2.time = system.now();
        insert le2;

        Test.startTest();
        //simulate agent accepting the chat request by updating LiveChatTranscript with InProgress Status
        lct.VTAC_Number__c = '1234567';
        update lct;
        Test.stopTest();
        

    }

    // test scenario of accepting chat request
    @isTest
    private static void test_checkStatusUpdates(){
        //create chat request by inserting LiveChatVisitor
        LiveChatVisitor liveChatVisitor = new LiveChatVisitor();
        insert liveChatVisitor;

        LiveChatTranscript lct = (LiveChatTranscript)MonConTestDataFactory.createSObject(new LiveChatTranscript());
        lct.LiveChatVisitorId = liveChatVisitor.Id;
        lct.Status = '';
        insert lct;

        LiveChatTranscriptEvent le = new LiveChatTranscriptEvent();
        le.LiveChatTranscriptId = lct.id;
        le.type = 'ChatRequest';
        le.time = system.now();
        insert le;

        LiveChatTranscriptEvent le1 = new LiveChatTranscriptEvent();
        le1.LiveChatTranscriptId = lct.id;
        le1.type = 'Enqueue';
        le1.time = system.now();
        insert le1;

        LiveChatTranscriptEvent le3 = new LiveChatTranscriptEvent();
        le3.LiveChatTranscriptId = lct.id;
        le3.type = 'PushAssignment';
        le3.time = system.now();
        insert le3;

        LiveChatTranscriptEvent le2 = new LiveChatTranscriptEvent();
        le2.LiveChatTranscriptId = lct.id;
        le2.type = 'Accept';
        le2.time = system.now();
        insert le2;

        Test.startTest();
        //simulate agent accepting the chat request by updating LiveChatTranscript with InProgress Status
        lct.Status = 'InProgress';
        update lct;
        Test.stopTest();

        Assert.areEqual('InProgress', [SELECT Status from LiveChatTranscript].get(0).Status);
    }
    
    @IsTest
    private static void testChat365MFACase() {

        //create contact
        Contact conRecord = (Contact)MonConTestDataFactory.createSObject(new Contact());
        conRecord.SAP_Staff_Id__c = '12345678';
        conRecord.Personal_Email__c = 'testEmail@test.edu';
        insert conRecord;

        //inserts Chat 365 Log - as if Chatbot was invoked by a user
        Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log.Bot_Name__c = 'myApp';
        insert chat365Log;


        Test.startTest();

        // GIVEN: The chat record is created


        //test Future Students
        Chat_365_Log_Detail__c chat365LogDetail1 = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
        chat365LogDetail1.Chat_365_Log__c = chat365Log.Id;
        chat365LogDetail1.Intent__c = 4;
        chat365LogDetail1.Topic__c = 'Future Student';
        insert chat365LogDetail1;


        // WHEN: The chat detail record is created 
        Chat_365_Log_Detail__c chatDetail1 = (Chat_365_Log_Detail__c)TestDataFactory.createSObject(new Chat_365_Log_Detail__c(Chat_365_Log__c = chat365Log.Id, Intent__c = 4, Topic__c = 'Future Student'), true);

        Test.stopTest();

        // THEN : corresoding case record will be created
        Assert.areEqual(2, [SELECT count() FROM Case]);

    }

}