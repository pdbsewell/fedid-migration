/*******************************************************************************
* @author		Ant Custodio
* @date         24.May.2017        
* @description  test class for appWorkExperienceCC
* @revision     
*******************************************************************************/
@isTest
public with sharing class appWorkExperienceCC_Test {
	/*******************************************************************************
	* @author       Ant Custodio
	* @date         24.May.2017        
	* @description  test the my qualification accessed from the my details screen
	* @revision     
	*******************************************************************************/
	static testMethod void test_WorkExp_AccessedFromMyDetails() {
		//create a community user
		User communityUserRec = StudFirst_TestHelper.createCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');
		test.startTest();
		//only run if there is a Domestic Applicant Profile User
		if (communityUserRec != null) {

			System.runAs(communityUserRec) {
				//user creates a work experience record
				Work_Experience__c workExpRecord = appWorkExperienceCC.createNewWorkExpRecord();
				workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);

				Work_Experience__c workExpInserted = appWorkExperienceCC.insertNewWorkExpRecord(workExpRecord);
				System.assertNotEquals(null, workExpInserted.Id, 'No Work Experience inserted');

				List<Work_Experience__c> workExpList = appWorkExperienceCC.retrieveWorkExpList();
				System.assert(!workExpList.isEmpty(), 'No Work Experience retrieved');

				String deletedId = appWorkExperienceCC.deleteSelectedWorkExperience(workExpInserted.Id);
				System.assertEquals(workExpInserted.Id, deletedId, 'Work Experience not deleted');
			}
		}
		test.stopTest();
	}

	/*******************************************************************************
	* @author       Ant Custodio
	* @date         24.May.2017        
	* @description  test the my qualification accessed from the my details screen
	* @revision     Ant Custodio, 11.Jul.2017 - added the scenario for editing work
						experience
	*******************************************************************************/
	static testMethod void test_WorkExp_AccessedFromApplicationForm() {
		//create a community user
		User communityUserRec = StudFirst_TestHelper.createCommunityUser();
		System.assertNotEquals(null, communityUserRec.ContactId, 'Contact not found');
		test.startTest();
		//only run if there is a Domestic Applicant Profile User
		if (communityUserRec != null) {

			System.runAs(communityUserRec) {
				//user starts an application
				Application__c appRecord = new Application__c();
				appRecord.Status__c = 'Draft';
				appRecord.Applicant__c = communityUserRec.ContactId;
				insert appRecord;
				System.assertNotEquals(null, appRecord.Id, 'No application created');

				//user creates a work experience record
				Work_Experience__c workExpRecord = appWorkExperienceCC.createNewWorkExpRecord();
				workExpRecord = StudFirst_TestHelper.populateWorkExperienceRecord(workExpRecord);

				Work_Experience__c workExpInserted = appWorkExperienceCC.insertNewWorkExpRecordWithApp(workExpRecord, appRecord.Id, false);
				System.assertNotEquals(null, workExpInserted.Id, 'No Application Work Experience inserted');

				//applicant updates the work experience
				workExpInserted.Position__c = 'Testing v2';
				workExpInserted = appWorkExperienceCC.insertNewWorkExpRecordWithApp(workExpInserted, appRecord.Id, true);
				System.assertNotEquals(null, workExpInserted.Id, 'No Application Work Experience inserted');

				Work_Experience__c workExpUpdated = appWorkExperienceCC.editWorkExpRecord(workExpInserted.Id);
				System.assertNotEquals(null, workExpInserted.Id, 'No Application Work Experience inserted');

				List<Application_Work_Experience_Provided__c> appWorkExpList = appWorkExperienceCC.retrieveAppWorkExpProvidedList(appRecord.Id);
				System.assert(!appWorkExpList.isEmpty(), 'No Application Work Experience retrieved');

				String deletedId = appWorkExperienceCC.deleteSelectedAppWorkExpProvided(appWorkExpList[0].Id);
				//System.assertEquals(appWorkExpList[0].Id, deletedId, 'Application Work Experience not deleted');
			}
		}
		test.stopTest();
	}
}