/**
* @author Angelo Rivera
* @date 13.Jan.2020
* @group Test Class
* @description  Test Class to test the functionality of MontrackUpdateInClassTasksBatch
* @revision     APRivera, 13.Jan.2020 - Created <br/>
*/
@isTest(isParallel=true)
private class MontrackUpdateInClassTasksBatch_Test {

	@IsTest
	static void testBatchClass() {
		Id mtRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('MonTrack').getRecordTypeId();
		List<User> lstUsers = TestHelper.createTestUsers('Outbound Base Profile', 1);
		List<Account> lstAccts = TestHelper.createStudent(3);

		System.runAs(lstUsers.get(0)) {
			insert lstAccts;
			List<Contact> lstContacts = TestHelper.createStudentContacts(3,lstAccts);
			insert lstContacts;
			List<Campaign> lstCampaigns = TestHelper.createCampaign(1);
			for(Campaign cmp : lstCampaigns){
				cmp.RecordTypeId = mtRecordTypeId;
			}
			insert lstCampaigns;
			Set<Id> setConIds = new Set<Id>();
			for(Contact con : [SELECT Id FROM Contact]){
				setConIds.add(con.Id);
			}
			List<CampaignMember> lstCmpMembers = TestHelper.createCampaignMember(lstUsers.get(0).Id, null, lstCampaigns.get(0).Id,setConIds );
			insert lstCmpMembers;

			Test.startTest();
			List<Task> lstTasks = [SELECT Id, Offer_Status__c FROM Task WHERE WhoId IN: setConIds];
			System.debug('Number of tasks generated: ' + lstTasks.size());
			System.assertEquals(3, lstTasks.size());

			List<Task> lstTasksToUpdate = new List<Task>();
			for(Integer x=0; x<3; x++){
				Task tsk = lstTasks.get(x);
				tsk.Offer_Status__c = 'In Class';
				tsk.Description = 'Student is in class.';
				lstTasksToUpdate.add(tsk);
			}
			update lstTasksToUpdate;

			List<Task> lstTaskInClass = [SELECT Id, Offer_Status__c FROM Task WHERE Status = 'Call Attempt' AND Offer_Status__c = 'In Class'];
			System.assert(lstTaskInClass.size() != null);

			Id batchJobId = Database.executeBatch(new MontrackUpdateInClassTasksBatch(), 200);
			String cronExpr = '0 0 1 * * ?';
			String jobId = System.schedule('MontrackUpdateInClassTasksBatchJob', cronExpr, new MontrackUpdateInClassTasksBatch());
		}
		Test.stopTest();

		List<Task> lstTaskUpdated= [SELECT Id, Offer_Status__c FROM Task WHERE Status = 'Call Attempt' AND Offer_Status__c = 'In Class'];
		System.assert(lstTaskUpdated.isEmpty(), true);
	}
}