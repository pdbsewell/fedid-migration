/**
* @author Steffi Narang
* @date 22.09.19
* @group TriggerHandlers
* @description Trigger handler for PendingServiceRoutingTriggerHandler-
* @revision APRivera - 04/12/2019 - Remove references of Neuraflash <br/>
*/
@isTest(isParallel=true)
private class PendingServiceRoutingTriggerHandler_Test {

    @isTest static void LiveChatRoutingEngine_General_Routing() {

        Chat_365_Log__c log = new Chat_365_Log__c();
        log.Chat_Key__c = 'askh123456789as';
        log.Account_Type__c = 1;
        log.Id_Number__c = '12345678';
        log.Bot_Name__c = 'exam';
        log.Session_Id__c='21378uidhak';
        insert log;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact();
        con.AccountId = acc.id;
        con.Email = 'test@test.com';
        con.FirstName = 'test';
        con.LastName = 'contact';
        insert con;

        Case testCase = new Case();
        testCase.Subject = 'Chatbot-Escalation';
        testCase.Origin = 'Chat - Bot';
        testCase.ContactId = con.Id;
        testCase.Subject = 'Chatbot - Escalation';
        testCase.Chat_365_Log__c = log.Id;
        testCase.Category_Level_1__c = 'Exams, Assessments, & Assignments';
        insert testCase;

        LiveChatVisitor testVisitor = new LiveChatVisitor();
        insert testVisitor;

        LiveChatTranscript liveChat = new LiveChatTranscript();
        liveChat.OwnerID = userinfo.getUserId();
        livechat.ChatKey = 'askh123456789as';
        livechat.LiveChatVisitorId = testVisitor.Id;
        insert livechat;

        ServiceResource testServiceResource = new ServiceResource();
        testServiceResource.RelatedRecordId = UserInfo.getUserId();
        testServiceResource.IsActive = true;
        testServiceResource.ResourceType = 'A';
        testServiceResource.Name = UserInfo.getUserName();
        insert testServiceResource;

        ServiceResourceSkill testSRSkill = new ServiceResourceSkill();
        testSRSkill.EffectiveStartDate = Date.today().addDays(-5);
        testSRSkill.ServiceResourceId = testServiceResource.Id;
        testSRSkill.SkillId = [SELECT Id FROM Skill WHERE DeveloperName = 'Exams_Chat' LIMIT 1].Id;
        insert testSRSkill;

        UserServicePresence testOnlineAgent = new UserServicePresence();
        testOnlineAgent.UserId = UserInfo.getUserId();
        testOnlineAgent.ServicePresenceStatusId = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Available' LIMIT 1].Id;
        insert testOnlineAgent;

        PendingServiceRouting testRoute = new PendingServiceRouting();
        testRoute.WorkItemId = livechat.Id;
        testRoute.CapacityWeight = 1;
        testRoute.IsReadyForRouting = FALSE;
        testRoute.RoutingModel  = 'MostAvailable';
        testRoute.RoutingPriority = 1;
        testRoute.RoutingType = 'SkillsBased';
        testRoute.ServiceChannelId = [Select Id From ServiceChannel Where RelatedEntity = 'LiveChatTranscript' LIMIT 1].Id;
        testRoute.PushTimeout = 0;
        insert testRoute;

        LiveChatTranscript updatedChatScript = [SELECT Skill_Type__c FROM LiveChatTranscript WHERE ChatKey = 'askh123456789as'];
        Assert.areNotEqual('Exams, Assessments, & Assignments', updatedChatScript.Skill_Type__c);
    }
}