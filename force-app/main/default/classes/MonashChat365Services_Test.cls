/**
* @author Steffi Narang
* @date 22.09.19
* @group 
* @description chat365Services for MonashChat365Services
* @revision 07.09.2020 - APRivera - Refactor test class to correctly test the functionality <br/>
* @revision 08.06.2023 - Inderpal Dhanoa - Refactor test class to have additional values on Live Chat Log <br/>
*/
@isTest(isParallel=true)
private class MonashChat365Services_Test{

    @IsTest
    private static void testUpdatesOnChat365Log() {
        //inserts Chat 365 Log - as if Chatbot was invoked by a user
        Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c(), true);
        chat365Log.VTAC_Number__c = '123456';
        update chat365Log;

        //create chat request by inserting LiveChatVisitor
        LiveChatVisitor liveChatVisitor = new LiveChatVisitor();
        insert liveChatVisitor;

        //simulate agent accepting the chat request by inserting LiveChatTranscript with In Progress Status
        LiveChatTranscript lct = (LiveChatTranscript)MonConTestDataFactory.createSObject(new LiveChatTranscript());
        lct.LiveChatVisitorId = liveChatVisitor.Id;
        lct.Chat_365_Log__c = chat365Log.Id;
        lct.VTAC_Number__c = '123456';
        insert lct;

        Test.startTest();
            lct.VTAC_Number__c = '1234567';
            update lct;
        Test.stopTest();

        System.assertEquals('1234567', [SELECT VTAC_Number__c FROM Chat_365_Log__c].VTAC_Number__c, 'VTAC Number mismatch');
    }

    @IsTest
    private static void testUpdatesOnLiveChatTranscript() {
        //inserts Chat 365 Log - as if Chatbot was invoked by a user
        Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log.User_Authenticated__c = 'Yes';
        insert chat365Log;

        //inserts Chat 365 Log Detail
        Chat_365_Log_Detail__c chat365LogDetail = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
        chat365LogDetail.Chat_365_Log__c = chat365Log.Id;
		chat365LogDetail.Intent__c = 4;
        chat365LogDetail.Intent_Name__c = 'trigger_live_chat';
        insert chat365LogDetail;

        //create chat request by inserting LiveChatVisitor
        LiveChatVisitor liveChatVisitor = new LiveChatVisitor();
        insert liveChatVisitor;

        Test.startTest();
            //simulate agent accepting the chat request by inserting LiveChatTranscript with In Progress Status
            LiveChatTranscript lct = (LiveChatTranscript)MonConTestDataFactory.createSObject(new LiveChatTranscript());
            lct.LiveChatVisitorId = liveChatVisitor.Id;
            lct.Status = 'InProgress';
            insert lct;

            List<LiveChatTranscript> lstChatTranscripts = new List<LiveChatTranscript>();
            lstChatTranscripts.add(lct);

            Set<String> setChatKeys = new Set<String>();
            setChatKeys.add(lct.ChatKey);

            MonashChat365Services.checkStatusUpdatesOnLiveChatTranscript(lstChatTranscripts, setChatKeys, true);

            //inserting a skill...
            Skill sk = new Skill();
            sk.Description ='testing';
            sk.DeveloperName ='Live_Chat';
            sk.Language ='en_US';
            sk.MasterLabel ='Live Chat';

            UserServicePresence userPresence= new UserServicePresence();
            userPresence.UserId = UserInfo.getUserId();
            userPresence.ServicePresenceStatusId = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Available' LIMIT 1].Id;
            insert userPresence;

            //inserting the PendingServiceRouting....
            PendingServiceRouting testRoute = new PendingServiceRouting();
            testRoute.WorkItemId = lct.Id;
            testRoute.CapacityWeight = 1;
            testRoute.IsReadyForRouting = false;
            testRoute.RoutingModel  = 'MostAvailable';
            testRoute.RoutingPriority = 1;
            testRoute.RoutingType = 'SkillsBased';
            testRoute.ServiceChannelId = [SELECT Id FROM ServiceChannel WHERE RelatedEntity = 'LiveChatTranscript' LIMIT 1].Id;
            testRoute.PushTimeout = 0;
            insert testRoute;
        Test.stopTest();

        LiveChatTranscript chatTranscript = [SELECT First_Name__c, Last_Name__c, Email__c, ID_Number__c FROM LiveChatTranscript];

        Assert.areEqual('TestFName', chatTranscript.First_Name__c, 'FirstName mismatch');
        Assert.areEqual('TestLName', chatTranscript.Last_Name__c, 'LastName mismatch');
        Assert.areEqual('12345678', chatTranscript.ID_Number__c, 'Transcript name mismatch');
    } 
        
    @IsTest
    private static void testCreateContact() {
        
        // GIVEN: A Chat 365 record exists
        Integer rnd = Integer.valueOf(Math.random()*9999);
            
        Chat_365_Log__c chatLog3 = (Chat_365_Log__c)TestDataFactory.createSObject(new Chat_365_Log__c(First_Name__c = 'Contact FirstName', Last_Name__c = 'Contact LName',
                                                                                                      Id_Number__c = '1234',Session_Id__c = '123abc456defgh', Chat_Key__c = '123abc456defgh',
                                                                                                      	Email__c = String.valueOf(rnd) + 'testUserChat365@monash.edu', Account_Type__c = 2), true);
        Test.startTest();
        // WHEN : The method is invoked
        Contact newIncomingContact = MonashChat365Services.createContact(chatLog3);
        
        Test.stopTest();
        
        // THEN: New COntact should be created
        newIncomingContact = [SELECT Id, SAP_Staff_Id__c FROM Contact WHERE Id = :newIncomingContact.Id];
        Assert.areEqual('1234', newIncomingContact.SAP_Staff_Id__c, 'Contact creation failed');        
    }

    /* 
     * Ensure the SOQL generated is ok when the input is 'invalid'
     * 
     * A limit 0 is added to the SOQL if there is an invalid type or other conditions are not available.
     */ 
	@IsTest
    private static void testgenerateContactQuery() {
        Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log.Account_Type__c = null;
        chat365Log.Email__c = null;
        chat365Log.Id_Number__c = null;
        insert chat365Log;
        
        test.startTest();
		// No id, email and invalid type.
        String soql = MonashChat365Services.generateContactQuery(chat365Log);
        Assert.isTrue(soql.containsIgnoreCase('limit'));

		// No id or email but valid visitor type
        chat365Log.Account_Type__c = 3;
        update chat365Log;
        soql = MonashChat365Services.generateContactQuery(chat365Log);
        Assert.isTrue(soql.containsIgnoreCase('limit'));

		// No id or email but valid staff type
        chat365Log.Account_Type__c = 2;
        update chat365Log;
        soql = MonashChat365Services.generateContactQuery(chat365Log);
        Assert.isTrue(soql.containsIgnoreCase('limit'));

		// No id but an email with a valid student type creates some useful SOQL
        chat365Log.Account_Type__c = 1;
        chat365Log.Email__c = 'dummyemail@textclass.com';
        update chat365Log;
        soql = MonashChat365Services.generateContactQuery(chat365Log);
        Assert.isfalse(soql.containsIgnoreCase('limit'));
        Assert.istrue(soql.containsIgnoreCase('Monash_Email_Address__c'));
        
        test.stopTest();
    }
    
    @IsTest
    private static void testChat365CaseDefaults() {

        //create contact
        Contact conRecord = (Contact)MonConTestDataFactory.createSObject(new Contact());
        conRecord.SAP_Staff_Id__c = '12345678';
        conRecord.Personal_Email__c = 'testEmail@test.edu';
        insert conRecord;

        //inserts Chat 365 Log - as if Chatbot was invoked by a user
        Chat_365_Log__c chat365Log = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log.Bot_Name__c = 'VTAC';
        insert chat365Log;

        //inserts Chat 365 Log - as if Chatbot was invoked by a user
        Chat_365_Log__c chat365Log1 = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log1.Account_Type__c = 3;
        chat365Log1.Chat_Key__c = '123abc456defg';
        chat365Log1.Session_Id__c = '123abc456defg';
        chat365Log1.Course__c = 'Information Technology';
        chat365Log1.User_Authenticated__c = 'No';
        insert chat365Log1;

        //inserts Chat 365 Log - as if Chatbot was invoked by a user
        Chat_365_Log__c chat365Log2 = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log2.Id_Number__c = '';
        chat365Log2.Chat_Key__c = '123abc456defgh';
        chat365Log2.Session_Id__c = '123abc456defgh';
        chat365Log2.Account_Type__c = 2;
        insert chat365Log2;

        Chat_365_Log__c chat365Log3 = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log3.Id_Number__c = '';
        chat365Log3.Chat_Key__c = '123abc456defghi';
        chat365Log3.Session_Id__c = '123abc456defghi';
        chat365Log3.Account_Type__c = 2;
        insert chat365Log3;

        Chat_365_Log__c chat365Log4 = (Chat_365_Log__c)MonConTestDataFactory.createSObject(new Chat_365_Log__c());
        chat365Log4.Id_Number__c = '';
        chat365Log4.Chat_Key__c = '123abc456defghij';
        chat365Log4.Session_Id__c = '123abc456defghij';
        chat365Log4.Account_Type__c = 2;
        insert chat365Log4;

        Test.startTest();

        // GIVEN: The chat record is created

        //test VTAC bot
        Chat_365_Log_Detail__c chat365LogDetail = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
        chat365LogDetail.Chat_365_Log__c = chat365Log.Id;
        chat365LogDetail.Intent__c = 4;
        insert chat365LogDetail;

        // //test Future Students
        Chat_365_Log_Detail__c chat365LogDetail1 = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
        chat365LogDetail1.Chat_365_Log__c = chat365Log1.Id;
        chat365LogDetail1.Intent__c = 4;
        chat365LogDetail1.Topic__c = 'Future Student';
        insert chat365LogDetail1;

        // //test Library
        Chat_365_Log_Detail__c chat365LogDetail2 = (Chat_365_Log_Detail__c)MonConTestDataFactory.createSObject(new Chat_365_Log_Detail__c());
        chat365LogDetail2.Chat_365_Log__c = chat365Log2.Id;
        chat365LogDetail2.Intent__c = 4;
        chat365LogDetail2.Topic__c = 'Library';
        insert chat365LogDetail2;

        //test Live Person        
        Chat_365_Log_Detail__c chatDetail3 = (Chat_365_Log_Detail__c)TestDataFactory.createSObject(new Chat_365_Log_Detail__c(Chat_365_Log__c = chat365Log3.Id, Intent__c = 5, Topic__c = 'Library'), true);

        // WHEN: The chat detail record is created 
        Chat_365_Log_Detail__c chatDetail4 = (Chat_365_Log_Detail__c)TestDataFactory.createSObject(new Chat_365_Log_Detail__c(Chat_365_Log__c = chat365Log4.Id, Intent__c = 4, Topic__c = 'Future Student'), true);

        Test.stopTest();

        // THEN : corresponding case record will be created
        Assert.areEqual(5, [SELECT count() FROM Case], 'Count Mismatch');

    }

}