/**
 * @description       : Test class for Chat Transcript: AS : Live Post to Feed Flow.
 * @author            : jackie.ho@monash.edu
 * @group             : 
 * @last modified on  : 12-06-2025
 * @last modified by  : jackie.ho@monash.edu
**/
@isTest(isParallel=true)
public with sharing class ChatTranscriptASLivePostToFeed_FT {
    @isTest
    static void testChatTranscriptASLivePostToFeed() {
        // Given: Create a chat transcript
        LiveChatVisitor liveChatVisitor = new LiveChatVisitor();
        insert liveChatVisitor;

        Case c = (Case)MonConTestDataFactory.createSObject(new Case(), true);
        
        LiveChatTranscript chatTranscript = new LiveChatTranscript();
        chatTranscript.LiveChatVisitorId = liveChatVisitor.Id;
        chatTranscript.CaseId = c.Id;
        insert chatTranscript;

        // When: Insert chat transcript
        test.startTest();
        chatTranscript.Status = 'Completed';
        update chatTranscript;
        test.stopTest();

        // Then: Validate live post to feed
        chatTranscript = [SELECT Id, CaseId, Chat_Link__c FROM LiveChatTranscript WHERE Id = :chatTranscript.Id];
        FeedItem feedItem = [SELECT Id, ParentId, LinkUrl FROM FeedItem ORDER BY CreatedDate DESC LIMIT 1];
        Assert.areEqual(feedItem.ParentId, chatTranscript.CaseId, 'Live post to feed not set');
        Assert.areEqual(feedItem.LinkUrl, chatTranscript.Chat_Link__c, 'Live post to feed not set');
    }
}