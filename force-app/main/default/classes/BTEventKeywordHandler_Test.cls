/**
 * @author RANAND
 * @date 2022-05-10
 * @group Event Keyword Management
 * @description Test class for Blackthorn Event Keyword Trigger
 * @revision
 *         2022-05-10 -   RANAND           -EPBBS-2629 Validate Event Keyword Selection on Events
 *         2022-06-01 -   Ibrahim Rumi     -EPBBS-2643 Manage event keywords cascading from event groups to related events test methods
 **/
@isTest(isParallel=true)
private class BTEventKeywordHandler_Test {
    @TestSetup
    static void setupData(){
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(10);
        TriggerCommon.disableTrigger('conference360__Event__c');
        insert btEventList;
        TriggerCommon.enableTrigger('conference360__Event__c'); 
        List<conference360__Keyword__c> keywords = new List<conference360__Keyword__c>();
        keywords.add(new conference360__Keyword__c( Name = 'interest1', conference360__Category__c='Interest Areas'));
        keywords.add(new conference360__Keyword__c( Name = 'interest2', conference360__Category__c='Interest Areas'));
        keywords.add(new conference360__Keyword__c( Name = 'interest3', conference360__Category__c='Interest Areas'));
        insert keywords;
    }
    @isTest
    static void ValidateCategoryonKeyword_testInsert(){
        List<conference360__Event__c> events = [SELECT Id FROM conference360__Event__c LIMIT 2];
        List<conference360__Keyword__c> keywords = [SELECT Id FROM conference360__Keyword__c];
        List<conference360__Event_Keyword__c> eventKeywords = new List<conference360__Event_Keyword__c>();

        eventKeywords.add(new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[0].Id, conference360__Event__c = events[0].Id));
        eventKeywords.add(new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[1].Id, conference360__Event__c = events[1].Id));

        Test.startTest();
        try{
            insert eventKeywords;
        }
        catch(Exception ex){
            Assert.isTrue(ex.getMessage().contains('You can only choose one keyword for these categories'));
        }
        Test.stopTest();
    }
    @isTest
    static void ValidateCategoryonKeyword_testInsertFailure(){
        conference360__Event__c event = [SELECT Id FROM conference360__Event__c LIMIT 1];
        List<conference360__Keyword__c> keywords = [SELECT Id FROM conference360__Keyword__c];
        conference360__Event_Keyword__c eventKeyword = new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[0].Id, conference360__Event__c = event.Id);
        insert eventKeyword;
        
        Test.startTest();
        Boolean exceptionThrown = false; // Flag to track if the exception was thrown

        try{
            conference360__Event_Keyword__c eventKeywordDup = new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[1].Id, conference360__Event__c = event.Id);
            insert eventKeywordDup;
        }
        catch(Exception ex){
            // Assert that the exception was thrown
            exceptionThrown = true;
            Assert.isTrue(exceptionThrown, 'The expected exception was not thrown. You can only choose one keyword for these categories');   
        }
        Test.stopTest();
 
    }
    @isTest
    static void ValidateCategoryonKeyword_testUpdate(){
        conference360__Event__c event = [SELECT Id FROM conference360__Event__c LIMIT 1];
        List<conference360__Keyword__c> keywords = [SELECT Id FROM conference360__Keyword__c];
        conference360__Event_Keyword__c eventKeyword = new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[0].Id, conference360__Event__c = event.Id);
        insert eventKeyword;
        
        Test.startTest();
        eventKeyword.conference360__Keyword__c = keywords[1].Id;
        update eventKeyword;
        Test.stopTest();
        
        Assert.areEqual('interest2', [SELECT conference360__Keyword__r.Name FROM conference360__Event_Keyword__c WHERE Id=:eventKeyword.Id LIMIT 1].conference360__Keyword__r.Name);
    }
    
	/*
    * Test for events where EventGroupStaff is already available on associated EventGroup
    */
    @isTest()
    static void autoCreateEventKeywordsForEventsOnEvntGroups(){
    
        conference360__Event_Group__c eventGroup = new conference360__Event_Group__c(Name='Event Group 1');
        insert eventGroup;
        List<conference360__Event_Keyword__c> eventKeywordList = new List<conference360__Event_Keyword__c>();
        
        List<conference360__Event__c> eventList = [SELECT id FROM conference360__Event__c];
        for(conference360__Event__c evt: eventList){
            evt.conference360__Event_Group__c = eventGroup.Id;
        }
        
        update eventList;
        
        for(conference360__Keyword__c keyword:[SELECT Id FROM conference360__Keyword__c LIMIT 4]){
            conference360__Event_Keyword__c eventKeyword = new conference360__Event_Keyword__c();
            eventKeyword.conference360__Keyword__c = keyword.id;
            eventKeyword.Event_Group__c = eventGroup.Id;
            eventKeywordList.add(eventKeyword);
        }
        
        
        Test.startTest();
        insert eventKeywordList;
        Test.stopTest();
        // Assert.areEqual(3, [SELECT COUNT() FROM conference360__event_Keyword__c WHERE conference360__Event__c != null],'No Event Keyword created');
    }
    
    /*
     * Test for eventKeywords where Keyword is changed on event group's EventKeyword
     */
    @isTest()
    static void autoUpdateEventKeywordsForEventsOnEvntGroups(){
        conference360__Event_Group__c eventGroup = new conference360__Event_Group__c(Name='Event Group 1');
        insert eventGroup;
        
        List<conference360__Event__c> eventList = [SELECT id FROM conference360__Event__c];
        for(conference360__Event__c evt: eventList){
            evt.conference360__Event_Group__c = eventGroup.Id;
        }
        
        update eventList;
        
        conference360__Keyword__c keyword1 = [SELECT Id FROM conference360__Keyword__c WHERE Name ='interest1'];
        conference360__Keyword__c keyword2 = [SELECT Id FROM conference360__Keyword__c WHERE Name ='interest2'];
        conference360__Event_Keyword__c eventKeyword = new conference360__Event_Keyword__c(conference360__Keyword__c = keyword1.Id, Event_Group__c = eventGroup.Id);
       
        insert eventKeyword;
        
        Test.startTest();
        eventKeyword.conference360__Keyword__c = keyword2.Id;
             update eventKeyword;
        Test.stopTest();
        Assert.areEqual(1, [SELECT count() FROM conference360__event_Keyword__c WHERE conference360__Event__c=:eventList[0].Id AND conference360__Keyword__c =:keyword2.Id],'No Event Keyword created');
    }
    
    /*
    * Test for events where EventGroupStaff is already available on associated EventGroup
    */
    @isTest()
    static void autoDeleteEventKeywordsForEventsOnEvntGroups(){
    
        conference360__Event_Group__c eventGroup = new conference360__Event_Group__c(Name='Event Group 1');
        insert eventGroup;
        
        conference360__Event__c event = [SELECT id FROM conference360__Event__c][0];
        
        event.conference360__Event_Group__c = eventGroup.Id;
        update event;
        
        conference360__Keyword__c keyword1 = [SELECT Id FROM conference360__Keyword__c WHERE Name ='interest1'];
        conference360__Event_Keyword__c eventKeyword = new conference360__Event_Keyword__c(conference360__Keyword__c= keyword1.Id, Event_Group__c = eventGroup.Id);
        insert eventKeyword;
        Assert.areEqual(1, [SELECT count() FROM conference360__event_Keyword__c WHERE conference360__Event__c=:event.Id AND conference360__Keyword__c =:keyword1.Id],'No Event Keyword created');
        
        Test.startTest();
             Delete eventKeyword;
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM conference360__event_Keyword__c WHERE conference360__Event__c=:event.Id AND conference360__Keyword__c =:keyword1.Id],'Event Keyword not deleted on event');
    }
    
    
}