/*******************************************************************************
* @author		Ant Custodio
* @date         21.Jun.2017
* @description  test class for appCreditIntentionCC
* @revision     Suman Gunaganti(2018-12-20) Commented out reference to online credit components
*******************************************************************************/
@isTest
public with sharing class appCreditIntentionCC_Test {
	private static Application__c appRecord;
	/*******************************************************************************
	* @author       Ant Custodio
	* @date         21.Jun.2017
	* @description  test the application success page
	* @revision     
	*******************************************************************************/
	static testMethod void test_retrieveApplication() {
		//create a community user
		User communityUserRec = StudFirst_TestHelper.createCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');

		//create a new draft application
		appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
		appRecord.OwnerId = communityUserRec.Id;
		insert appRecord;

		test.startTest();
		//only run if there is a Domestic Applicant Profile User
		if (communityUserRec != null) {
			System.runAs(communityUserRec) {
				//retrieve the application
				System.assertNotEquals(null, appRecord.Id, 'Application not created');
				Application__c appRetrieve = appCreditIntentionCC.retrieveApplicationById(appRecord.Id);
				System.assertEquals(appRetrieve.Id, appRecord.Id, 'Application not retrieved');
				
				//user updates the credit intention
				appRetrieve.Applying_for_Credit__c = 'Yes';
				Application__c appUpdated = appCreditIntentionCC.updateApplication(appRetrieve);
				System.assertEquals('Yes', appUpdated.Applying_for_Credit__c, 'Application not updated');

				//force exception
				appUpdated.Id = null;
				Boolean hasErrors = false;
				try {
					appUpdated = appCreditIntentionCC.updateApplication(appRetrieve);
				} catch (Exception ex) {
					hasErrors = true;
				}
				
				System.assert(hasErrors, 'Class did not throw expected errors');
			}
		}
		test.stopTest();
	}
}