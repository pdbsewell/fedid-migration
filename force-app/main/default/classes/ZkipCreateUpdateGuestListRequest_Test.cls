/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class ZkipCreateUpdateGuestListRequest_Test {
	@testSetup
	static void setup() {
        // Campaign
        List<Campaign> campaigns = new List<Campaign>();
        
        Campaign campaignOne = new Campaign();
        campaignOne.Name = 'Name';
        campaigns.add(campaignOne);
        
        insert campaigns;
	}
    
    static testMethod void testErrorFreeExecution() {
        Campaign c = [SELECT
                      Id,
                      Name,
                      Parent_ERDA_Event__c,
                      Parent_ERDA_Event__r.Zkipster_Event_Id__c,
                      Zkipster_Guest_List_Id__c
                      FROM Campaign
                      LIMIT 1];
        
        Test.startTest();
        
        ZkipCreateUpdateGuestListRequest.createGuestListPayload(c, true);
        
        Test.stopTest();
    }
}