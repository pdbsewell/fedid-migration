/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
public class BMSInsertCampaignMemberCSVQueueable_Test {
	static testMethod void testBMSInsertCampaignMemberCSVQueueable() {
        List<Campaign> campaigns = new List<Campaign>();
        
        Campaign campaignOne = new Campaign();
        campaignOne.Name = 'Name 1';
        campaigns.add(campaignOne);
        
        insert campaigns;
        
        Attachment a = new Attachment();
        a.Body = Blob.valueOf('Test');
        a.Name = 'Name';
        a.ParentId = campaignOne.Id;
        insert a;
        
        Test.startTest();
        
        System.enqueueJob(new BMSInsertCampaignMemberCSVQueueable(a.Id, campaignOne.Id, false));
        
        Test.stopTest();
    } 
}