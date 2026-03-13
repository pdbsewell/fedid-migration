/**
 * @author RANAND
 * @date 2022-05-10
 * @group Event Keyword Management
 * @description Test class for Blackthorn Event Keyword Trigger
 * @revision
 *         2022-05-10 -   RANAND     -EPBBS-2629 Validate Event Keyword Selection on Events
 **/
@isTest(isParallel=true)
private class BTEventKeywordTrigger_Test {
    @TestSetup
    static void setupData(){
        //create blackthorn event
        List<conference360__Event__c> btEventList = TestHelper.createBlackthornEvents(5);
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
        //GIVEN - The Event and Keyword are already present 
        List<conference360__Event__c> events = [SELECT Id FROM conference360__Event__c];
        List<conference360__Keyword__c> keywords = [SELECT Id FROM conference360__Keyword__c];
        List<conference360__Event_Keyword__c> eventKeywords = new List<conference360__Event_Keyword__c>();

        //WHEN - Two Event Category with same Category is being created in same transaction
        eventKeywords.add(new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[0].Id, conference360__Event__c = events[0].Id));
        eventKeywords.add(new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[1].Id, conference360__Event__c = events[1].Id));

        Test.startTest();
        try{
            insert eventKeywords;
        }
        catch(Exception ex){
            //THEN - System shouldn't allow to create new Event Keyword record and throw error
            Assert.isTrue(ex.getMessage().contains('You can only choose one keyword for these categories'));
        }
        Test.stopTest();
    }
    @isTest
    static void ValidateCategoryonKeyword_testInsertFailure(){
        //GIVEN - The Event and Keyword are already present and a new Event Kayword is being created
        conference360__Event__c event = [SELECT Id FROM conference360__Event__c LIMIT 1];
        List<conference360__Keyword__c> keywords = [SELECT Id FROM conference360__Keyword__c];
        conference360__Event_Keyword__c eventKeyword = new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[0].Id, conference360__Event__c = event.Id);
        insert eventKeyword;
        
        //WHEN - A new Event Keywords is created against same Category as above
        Test.startTest();
        Boolean exceptionThrown = false; // Flag to track if the exception was thrown

        try{
            conference360__Event_Keyword__c eventKeywordDup = new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[1].Id, conference360__Event__c = event.Id);
            insert eventKeywordDup;
        }
        catch(Exception ex){
            //THEN - System shouldn't allow to create new Event Keyword record and throw error
            exceptionThrown = true;
            Assert.isTrue(exceptionThrown, 'The expected exception was not thrown. You can only choose one keyword for these categories');   
        }
        Test.stopTest();
 
    }
    @isTest
    static void ValidateCategoryonKeyword_testUpdate(){
        //GIVEN - The Event and Keyword are already present
        conference360__Event__c event = [SELECT Id FROM conference360__Event__c LIMIT 1];
        List<conference360__Keyword__c> keywords = [SELECT Id FROM conference360__Keyword__c];
        conference360__Event_Keyword__c eventKeyword = new conference360__Event_Keyword__c(conference360__Keyword__c= keywords[0].Id, conference360__Event__c = event.Id);
        insert eventKeyword;
        //WHEN - Category is updated to a new value which doesn't exist alrerady Event Keywords 
        Test.startTest();
        eventKeyword.conference360__Keyword__c = keywords[1].Id;
        update eventKeyword;
        Test.stopTest();
        //THEN - Successfully save the record and update the Category on Event Keyword
        Assert.areEqual('interest2', [SELECT conference360__Keyword__r.Name FROM conference360__Event_Keyword__c WHERE Id=:eventKeyword.Id LIMIT 1].conference360__Keyword__r.Name);
    }
}