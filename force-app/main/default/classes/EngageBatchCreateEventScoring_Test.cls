/**
 * @author          James Seto - UC Innovation
 * @description     For testing the EngageServiceIndicatorAlertsCC Simply grabs custom metadata types from the controller.
 * 
 * @revision        07/10/2019 - James Seto - Initial version
 * @revision        08/10/2019 - Mark Johnson - Add assertions, clean up.
 */

@isTest(isParallel=true)
public class EngageBatchCreateEventScoring_Test {
    @testSetup
    static void setup() {
        //Create custom setting test record
        Score_Batch_Settings__c scoreSettings = new Score_Batch_Settings__c(Registration_Expiry__c = 12, Registration_Score__c = 20, Registration_Description__c = 'Registered event last 12 months', Premium_Attended_Expiry__c = 36, Premium_Attended_Score__c = 181, Premium_Attended_Description__c = 'Attended Premium Event in Last 3 Years', Attended_Expiry__c = 12,  Attended_Score__c = 51, Attended_Description__c = 'Attended event last 12 months');
        insert scoreSettings;
    }
    
    @IsTest
    static void test_method_one_premium_event()
    {
        //GIVEN: We have a campaign member that has attended a premium ERDA event
        //campaign records a contact, so add contacts(s) first
        Contact contact = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert contact;
        
        //Parent Campaign
        Campaign parentCamp = new Campaign();
        parentCamp.Name = 'Test Parent Campaign';
        parentCamp.Agent__c = contact.Id;
        parentCamp.Business_Rationale__c = '(Parent Camp)';
        parentCamp.Premium_Event__c = true;
        parentCamp.StartDate = System.today() - 3;
        parentCamp.EndDate = System.today() - 2;
        parentCamp.Event_End_DateTime__c = System.today() - 2;
        parentCamp.Status = 'Completed';
        parentcamp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Event').getRecordTypeId();
        insert parentCamp;
        
        //CampaignMember has a lookup to Campaign, so create Campaign(s) before CampaignMember(s)
        Campaign camp = new Campaign();
        camp.Name = 'Test Campaign';
        camp.Agent__c = contact.Id;
        camp.Business_Rationale__c = '(Campaign Member)';
        camp.Premium_Event__c = true;
        camp.StartDate = System.today() - 2;
        camp.EndDate = System.today() - 1;
        camp.Event_End_DateTime__c = System.today() - 1;
        camp.Status = 'Completed';
        camp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Guest_List').getRecordTypeId();
        camp.Parent_ERDA_Event__c = parentCamp.Id;
        insert camp;
        
        //insert CampaignMembers(s) for the batch class
        //fields must match the query in start function
        CampaignMember campMem = new CampaignMember();
        campMem.CampaignId = camp.Id;
        campMem.ContactId = contact.Id;
        //Premium Event value is calculated from the campaign value (formula)
        campMem.Engagement_Scoring_Applied__c = false;
        campMem.Status = 'CheckedIn';
        insert campMem;      
  
        //WHEN: The EngageBatchCreateEventScoring batch is run
        test.startTest();
        Database.executeBatch(new EngageBatchCreateEventScoring(), 1);
        test.stopTest();
        
        //THEN: Score records are created, with scores varying depending on the type of event
        List<Score__c> scores = [SELECT Point_Value__c, Status__c FROM Score__c WHERE Constituent__c =: contact.Id];
        
        Assert.areEqual(false, scores.isEmpty(), 'Scores should have been created for contact.');
        Assert.areEqual(181, scores[0].Point_Value__c, 'Score for premium event should be 181.');
        Assert.areEqual('Active', scores[0].Status__c, 'Score should be an active score.');
        
        List<CampaignMember> cMembers = [SELECT Engagement_Scoring_Applied__c FROM CampaignMember WHERE ContactId =: contact.Id LIMIT 1];
        
        Assert.areEqual(false, cMembers.isEmpty(), 'There should be an existing campaign member associated with the contact.');
        Assert.areEqual(true, cMembers[0].Engagement_Scoring_Applied__c, 'The campaign member should have Engagement Scoring Applied checked.');
    }
    
    //make another test method where it is not a Premium Event
    //that should get full test coverage
    @IsTest
    static void test_method_two_non_premium_event()
    {
        //GIVEN: We have a campaign member that has attended a non-premium ERDA event
        //campaign records a contact, so add contacts(s) first
        Contact contact = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert contact;
        
        //Parent Campaign (Campaign seems to have a lookup to another campaign, not sure why this is the case)
        Campaign parentCamp = new Campaign();
        parentCamp.Name = 'Test Parent Campaign';
        parentCamp.Agent__c = contact.Id;
        parentCamp.Business_Rationale__c = '(Parent Camp)';
        parentCamp.Premium_Event__c = false;
        parentCamp.StartDate = System.today() - 3;
        parentCamp.EndDate = System.today() - 2;
        parentCamp.Event_End_DateTime__c = System.today() - 2;
        parentCamp.Status = 'Completed';
        parentcamp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Event').getRecordTypeId();
        insert parentCamp;
        
        //CampaignMember has a lookup to Campaign, so create Campaign(s) before CampaignMember(s)
        Campaign camp = new Campaign();
        camp.Name = 'Test Campaign';
        camp.Agent__c = contact.Id;
        camp.Business_Rationale__c = '(Campaign)';
        camp.Premium_Event__c = false;
        camp.StartDate = System.today() - 2;
        camp.EndDate = System.today() - 1;
        camp.Event_End_DateTime__c = System.today() - 1;
        camp.Status = 'Completed';
        camp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Guest_List').getRecordTypeId();
        camp.Parent_ERDA_Event__c = parentCamp.Id;
        insert camp;
        
        //insert CampaignMembers(s) for the batch class
        //fields must match the query in start function
        CampaignMember campMem = new CampaignMember();
        campMem.CampaignId = camp.Id;
        campMem.ContactId = contact.Id;
        //Premium Event value is calculated from the campaign value (formula)
        campMem.Engagement_Scoring_Applied__c = false;
        campMem.Status = 'CheckedIn';
        insert campMem;
        
        //WHEN: The EngageBatchCreateEventScoring batch is run
        test.startTest();
        Database.executeBatch(new EngageBatchCreateEventScoring(), 1);
        test.stopTest();
        
        //THEN: Score record is created and CampaignMember is updated
        List<Score__c> scores = [SELECT Point_Value__c, Status__c FROM Score__c WHERE Constituent__c =: contact.Id];
        
        Assert.areEqual(false, scores.isEmpty(), 'Scores should have been created for contact.');
        Assert.areEqual(51, scores[0].Point_Value__c, 'Score for event should be 51.');
        Assert.areEqual('Active', scores[0].Status__c, 'Score should be an active score.');
        
        List<CampaignMember> cMembers = [SELECT Engagement_Scoring_Applied__c FROM CampaignMember WHERE ContactId =: contact.Id LIMIT 1];
        
        Assert.areEqual(false, cMembers.isEmpty(), 'There should be an existing campaign member associated with the contact.');
        Assert.areEqual(true, cMembers[0].Engagement_Scoring_Applied__c, 'The campaign member should have Engagement Scoring Applied checked.');
    }
     
}