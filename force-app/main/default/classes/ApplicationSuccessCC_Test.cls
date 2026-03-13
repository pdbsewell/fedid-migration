/*******************************************************************************
* @author		Ant Custodio
* @date         24.May.2017        
* @description  test class for ApplicationSuccessCC
* @revision     
 * 19/07/2023 Ken McGuire enhanced security
*******************************************************************************/
@isTest
public with sharing class ApplicationSuccessCC_Test {
	/*******************************************************************************
	* @author       Ant Custodio
	* @date         24.May.2017        
	* @description  test the application success page
	* @revision     
	*******************************************************************************/
	static testMethod void test_retrieveApplicationCommunityUser() {
		
		//create a community user
		User communityUserRec = StudFirst_TestHelper.createCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');
		test.startTest();
		//only run if there is a Domestic Applicant Profile User
		if (communityUserRec != null) {
			System.runAs(communityUserRec) {
				//create a new draft application
				Application__c appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
				insert appRecord;

				Application__c appRetrieved = ApplicationSuccessCC.retrieveApplication(appRecord.Id);
				System.assertEquals(appRecord.Id, appRetrieved.Id, 'Application not retrieved');
			}
		}
		test.stopTest();
	}
    
    static testMethod void test_retrieveApplicationOtherUser() {
		
		//create a community user
		User communityUserRec = StudFirst_TestHelper.createCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');
		test.startTest();
		//only run if there is a Domestic Applicant Profile User
		if (communityUserRec != null) {
            //create a new draft application
            Application__c appRecord = StudFirst_TestHelper.createApplication(communityUserRec.ContactId);
            insert appRecord;
            
            Application__c appRetrieved = ApplicationSuccessCC.retrieveApplication(appRecord.Id);
            System.assertEquals(appRecord.Id, appRetrieved.Id, 'Application not retrieved');
		}
		test.stopTest();
	}
}