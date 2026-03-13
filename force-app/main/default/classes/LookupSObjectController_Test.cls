/*******************************************************************************
* @author		Ant Custodio
* @date         26.May.2017        
* @description  test class for ApplicationHeaderCC
* @revision     
*******************************************************************************/
@isTest
public with sharing class LookupSObjectController_Test {
	/*******************************************************************************
	* @author       Ant Custodio
	* @date         24.May.2017        
	* @description  scenario 1, Qualification/Institutions found
	* @revision     
	*******************************************************************************/
	static testMethod void test_Lookup_RecordsFound() {
		//create a community user
		User communityUserRec = StudFirst_TestHelper.createCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');


		Qualification__c qualRec = StudFirst_TestHelper.createSecondaryQualification();
		insert qualRec;

		Institution__c insRec = StudFirst_TestHelper.createSecondaryInstitution();
		insert insRec;

		test.startTest();
		//only run if there is a Domestic Applicant Profile User
		if (communityUserRec != null) {
			System.runAs(communityUserRec) {

				List<LookupSObjectController.Result> qualSearchResult = LookupSObjectController.lookupWithRecordType('TRINITY', 'Qualification__c', 'Secondary Qualification', 'VIC', 'Australia');
				System.assert(!qualSearchResult.isEmpty(), 'Qualification not found');

				list<LookupSObjectController.Result> insSearchResult = LookupSObjectController.lookupWithRecordType('ST LEONARD', 'Institution__c', 'Secondary', 'VIC', 'Australia');
				System.assert(!insSearchResult.isEmpty(), 'Institution not found');

			}
		}
		test.stopTest();
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         24.May.2017        
	* @description  scenario 2, Qualification/Institutions not found
	* @revision     
	*******************************************************************************/
	static testMethod void test_Lookup_RecordsNotFound() {
		//create a community user
		User communityUserRec = StudFirst_TestHelper.createCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');


		Qualification__c qualRec = StudFirst_TestHelper.createSecondaryQualification();
		insert qualRec;

		Institution__c insRec = StudFirst_TestHelper.createSecondaryInstitution();
		insert insRec;


		test.startTest();
		//only run if there is a Domestic Applicant Profile User
		if (communityUserRec != null) {
			System.runAs(communityUserRec) {

				List<LookupSObjectController.Result> qualSearchResult = LookupSObjectController.lookupWithRecordType('TRINITY', 'Qualification__c', 'Secondary Qualification', 'Somestate', 'Philippines');
				System.assert(qualSearchResult.isEmpty(), 'Qualification found');

				list<LookupSObjectController.Result> insSearchResult = LookupSObjectController.lookupWithRecordType('ST LEONARD', 'Institution__c', 'Secondary', 'Somestate', 'Philippines');
				System.assert(insSearchResult.isEmpty(), 'Institution found');
			}
		}
		test.stopTest();
	}
	
}