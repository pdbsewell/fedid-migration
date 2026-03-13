/**
 * @author	Ayush Agrawal (ayush.agrawal@monash.edu)
 */

@isTest(isParallel=true)
private class BMSMassEmailContactBatch_Test {
	static testMethod void testErrorFreeExecution() {
        List<Contact> contacts = new List<Contact>();
        
        Contact contactOne = new Contact();
        contactOne.LastName = 'Test';
        contacts.add(contactOne);
        
        insert contacts;
        
        List<Campaign> campaigns = new List<Campaign>();
        
        Campaign campaignOne = new Campaign();
        campaignOne.Name = 'Test';
        campaigns.add(campaignOne);
        
        insert campaigns;
        
        Test.startTest();
        
        Database.executeBatch(new BMSMassEmailContactBatch(new List<String>{contactOne.Id}, null, campaignOne.Id, null));
        
        Test.stopTest();
	}
}