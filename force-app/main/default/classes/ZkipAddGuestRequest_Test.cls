/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class ZkipAddGuestRequest_Test {
	@testSetup
	static void setup() {
        // Campaign
        List<Campaign> campaigns = new List<Campaign>();
        
        Campaign campaignOne = new Campaign();
        campaignOne.Name = 'Name';
        campaigns.add(campaignOne);
        
        insert campaigns;
        
        // Contact
        List<Contact> contacts = new List<Contact>();
        
        Contact contactOne = new Contact();
        contactOne.LastName = 'LastName';
        contacts.add(contactOne);
        
        insert contacts;
        
        // CampaignMember
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        
        CampaignMember campaignMemberOne = new CampaignMember();
        campaignMemberOne.CampaignId = campaignOne.Id;
        campaignMemberOne.ContactId = contactOne.Id;
        campaignMembers.add(campaignMemberOne);
        
        insert campaignMembers;
	}
    
    static testMethod void testErrorFreeExecution() {
        CampaignMember cm = [SELECT
                             Id,
                             Campaign.Zkipster_Guest_List_Id__c,
                             Invitee_Title__c,
                             Invitee_First_Name__c,
                             Invitee_Last_Name__c,
                             Invitee_Suffix__c,
                             Invitee_Guest__c,
                             Invitee_Position__c,
                             Dietary_Requirements__c,
                             Invitee_Accessibility_Requirements__c,
                             Invitee_Organization__c,
                             Invitee_Phone__c,
                             Invitee_Email__c,
                             Invitee_Salutation__c
                             FROM CampaignMember
                             LIMIT 1];
        
        Test.startTest();
        
        ZkipAddGuestRequest.addGuestPayload(cm);
        
        Test.stopTest();
    }
}