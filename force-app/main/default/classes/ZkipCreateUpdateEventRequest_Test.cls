/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class ZkipCreateUpdateEventRequest_Test {
	@testSetup
	static void setup() {
        // Campaign
        List<Campaign> campaigns = new List<Campaign>();
        
        Campaign campaignOne = new Campaign();
        campaignOne.Name = 'Name';
        campaignOne.Event_Start_DateTime__c = DateTime.now();
        campaignOne.Event_End_DateTime__c = DateTime.now().addDays(1);
        campaigns.add(campaignOne);
        
        insert campaigns;
	}
    
    static testMethod void testErrorFreeExecution() {
        Campaign c = [SELECT
                      Id,
                      Event_Street__c,
                      Event_City__c,
                      Event_State__c,
                      Event_Zip__c,
                      Event_Country__c,
                      Name,
                      Type,
                      Event_Start_DateTime__c,
                      Event_End_DateTime__c,
                      Event_Location__c,
                      Zkipster_Event_Id__c
                      FROM Campaign
                      LIMIT 1];
        
        Test.startTest();
        
        ZkipCreateUpdateEventRequest.createEventPayload(c, true);
        
        Test.stopTest();
    }
}