/*
 * @author          Matthew Maramot
 * @description     Test class for EngageBatchRegisterScoringevent
 * @history         08/04/2025 - Matthew Maramot - Initial version
 */
@isTest(isParallel=true)
public class EngageBatchRegisterScoring_Test {

    @testSetup
    static void setup() {
        //Create custom setting test record
        Score_Batch_Settings__c scoreSettings = new Score_Batch_Settings__c(Registration_Expiry__c = 12, Registration_Score__c = 20, Registration_Description__c = 'Registered event last 12 months', Premium_Attended_Expiry__c = 36, Premium_Attended_Score__c = 181, Premium_Attended_Description__c = 'Attended Premium Event in Last 3 Years', Attended_Expiry__c = 12,  Attended_Score__c = 51, Attended_Description__c = 'Attended event last 12 months');
        insert scoreSettings;
        
        //Create Contact for Campaign
        Contact contact = new Contact(LastName = 'LastName', FirstName = 'BatchTest');
        insert contact;

        //Create a Parent Campaign
        Campaign parentCamp = new Campaign();
        parentCamp.Name = 'Test Parent Campaign';
        parentCamp.Agent__c = contact.Id;
        parentCamp.Business_Rationale__c = '(Parent Camp)';
        parentCamp.StartDate = System.today() - 3;
        parentCamp.EndDate = System.today() - 2;
        parentCamp.Event_End_DateTime__c = System.today() - 2;
        parentCamp.Status = 'Completed';
        parentcamp.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ERDA_Event').getRecordTypeId();
        insert parentCamp;

        //Create another Campaign and link to Parent Campaign
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

        //Create Campaign Member for batch query
        CampaignMember campMem = new CampaignMember();
        campMem.CampaignId = camp.Id;
        campMem.ContactId = contact.Id;
        campMem.Registration_Scoring_Applied__c = false;
        campMem.Status = 'Confirmed';
        insert campMem;  
        }

    @IsTest
    static void testCreateScoreRecord()
    {  
        //GIVEN: We have an Alumni Campaign member that has registered to an ERDA event   

        test.startTest();
        //WHEN: The EngageBatchegisterScoring batch runs
        Database.executeBatch(new EngageBatchRegisterScoring(), 1);
        test.stopTest();

        //THEN: Score record is created and CampaignMember is updated
        List<Score__c> scores = [SELECT Constituent__c, Point_Value__c, Status__c FROM Score__c WHERE Constituent__r.FirstName = 'BatchTest' LIMIT 1];
        Assert.areEqual(false, scores.isEmpty(), 'Score record(s) should have been created for contact.');
        Assert.areEqual(20, scores[0].Point_Value__c, 'Score should be 20.');
        Assert.areEqual('Active', scores[0].Status__c, 'Score should be an active score.');
        
        //And CampaignMember is updated to reflect that it has been scored
        List<CampaignMember> cMembers = [SELECT Registration_Scoring_Applied__c FROM CampaignMember WHERE Contact.FirstName =: 'BatchTest' LIMIT 1];
        Assert.areEqual(true, cMembers[0].Registration_Scoring_Applied__c, 'The campaign member should have Registration Scoring Applied checked.');
    }
}