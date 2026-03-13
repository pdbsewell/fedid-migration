/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
public class BMSUpdateCampaignMemStatusQueueable_Test {
	static testMethod void testBMSUpdateCampaignMemStatusQueueable() {
        List<Campaign> campaigns = new List<Campaign>();
        
        Campaign campaignOne = new Campaign();
        campaignOne.Name = 'Name 1';
        campaigns.add(campaignOne);
        
        insert campaigns;
        
        Test.startTest();
        
        System.enqueueJob(new BMSUpdateCampaignMemStatusQueueable(new List<String>{campaignOne.Id}));
        
        Test.stopTest();
    } 
}