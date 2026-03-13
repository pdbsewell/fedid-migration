/**
 * @description       : Test classes for APNGApplicationSelector
 * @author            : Ben Greenland
 * @group             :
 * @last modified on  : 2024-10-04
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-03   Ben Greenland   Initial Version
 **/

@isTest(isparallel=true)
private class APNGApplicationSelector_Test {
	@TestSetup
	static void makeData() {
		TriggerCommon.disableTrigger('Country_Attribute__c');
		TriggerCommon.disableTrigger('Account');
		TriggerCommon.disableTrigger('Contact');
		TriggerCommon.disableTrigger('User');
		AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
		System.runAs(portalUser.testUser) {
			Country_Attribute__c country = new Country_Attribute__c(
				Name = 'INDIA',
				Callista_Code__c = '7103',
				Country__c = 'INDIA'
			);
			insert country;

			Country_Attribute__c country1 = new Country_Attribute__c(
				Name = 'AUSTRALIA',
				Callista_Code__c = BDPConstants.AUSTRALIA_CALLISTA_CODE,
				Country__c = 'Australia'
			);
			insert country1;

			insert new Bypass_Mute_Request__c(Bypass_All_Flows__c = false);
			Contact applicant = StudFirst_TestHelper.createInternationalApplicant();
			insert applicant;
			Application__c application = StudFirst_TestHelper.createInternationalApplication(applicant, country);
			insert application;
			Course__c course = StudFirst_TestHelper.createCourse();
			insert course;
			Course_Offering__c courseOffering = StudFirst_TestHelper.createCourseOffering(course);
			insert courseOffering;
			Qualification__c qual = StudFirst_TestHelper.createQualification('Master of puppets');
			insert qual;
			Contact_Qualification__c contactQual = StudFirst_TestHelper.createContactQualification(
				applicant,
				qual,
				'Tertiary Education'
			);
			insert contactQual;
			// create the apq
			Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c(
				Contact_Qualification__c = contactQual.Id,
				Application__c = application.id
			);
			insert aqp;

			Application_Course_Preference__c acp = StudFirst_TestHelper.createCoursePreferences(
				application,
				applicant,
				courseOffering,
				course
			);
			insert acp;

			Work_Experience__c wex = StudFirst_TestHelper.createWorkExperience(applicant);
			wex.Position__c = 'Cat';
			wex.Employer_Name__c = 'Bunnings';
			wex.Contact_Person_First_Name__c = 'Bobo';
			insert wex;
			Application_Work_Experience_Provided__c awep = new Application_Work_Experience_Provided__c(
				Application__c = application.Id,
				Work_Experience__c = wex.Id
			);
			insert awep;
		}
		TriggerCommon.enableTrigger('Country_Attribute__c');
		TriggerCommon.enableTrigger('Account');
		TriggerCommon.enableTrigger('Contact');
		TriggerCommon.enableTrigger('User');
	}

	@IsTest
	static void testgetApplicationDetails() {
		//GIVEN : an application with Course Preferences
		Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
		Test.startTest();
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			//WHEN : I retrieve the Course Preference wrapper as agent
			APNGApplicationPayload.ApplicationDetails ApplicationDetails = APNGApplicationSelector.getApplicationDetails(
				app.Name
			);
			//THEN : the Course Preference wrapper should contain the Course Preferences
			Assert.areEqual(app.Id, ApplicationDetails.details.id, 'Id does not match');
			Assert.isNotNull(ApplicationDetails.coursePreferences, 'Course Preferences should not be null');
		}
		Test.stopTest();
	}

	@IsTest
	static void testgetApplicationDetailsNotFound() {
		//GIVEN : an application with Course Preferences
		Test.startTest();
		//WHEN : AGENT user retrieves the Course Preference wrapper with a nonexistant name
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			try {
				APNGApplicationSelector.getApplicationDetails('Somthingbad');
				//THEN : the Course Preference wrapper should be null
			} catch (Exception e) {
				Assert.isTrue(
					e.getMessage().contains('Application not found'),
					'Application not found exception should be thrown'
				);
			}
		}
		Test.stopTest();
	}

	@IsTest
	static void getContactQualificationsByApplicationId() {
		//GIVEN : an application with qualifications
		Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
		Test.startTest();
		//WHEN : I retrieve the Qualification wrapper as agent
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			APNGApplicationPayload.Qualifications quals = APNGApplicationSelector.getContactQualificationsByApplicationId(
				app.Name
			);
			//THEN : the Qualification wrapper should contain the Qualification data
			Assert.isTrue(quals.recordCount > 0, 'There should be at least one Qualifications');
		}
		Test.stopTest();
	}

	@IsTest
	static void getContactQualificationsByApplicationIdException() {
		Test.startTest();
		//GIVEN an getAgentUser requesting qualifications with a bad Application Name
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			try {
				//WHEN : I retrieve the Qualification wrapper as agent
				APNGApplicationSelector.getContactQualificationsByApplicationId('oops');
			}
			//THEN  : an Exception should be thrown
			catch (Exception e) {
				Assert.isTrue(
					e.getMessage().contains('Application not found'),
					'Application not found exception should be thrown'
				);
			}
		}
		Test.stopTest();
	}

	@IsTest
	static void getWorkExperiencesByApplicationIdTest() {
		//GIVEN : an application with Work Experience Records
		Application__c app = [SELECT Id, Name FROM Application__c LIMIT 1];
		Test.startTest();
		//WHEN : I retrieve the Work Experience wrapper as agent
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			APNGApplicationPayload.WorkExperiences quals = APNGApplicationSelector.getWorkExperiencesByApplicationId(
				app.Name
			);
			//THEN : the Work Experience wrapper should contain the Work Experience data
			Assert.isTrue(quals.recordCount > 0, 'There should be at least one Qualifications');
		}
		Test.stopTest();
	}

	@IsTest
	static void getWorkExperiencesByApplicationIdException() {
		Test.startTest();
		//GIVEN an getAgentUser requesting qualifications with a bad Application Name
		System.runAs(new AgentPortalTestDataFactory.AgentPortalTestDataFactoryUtil().getAgentUser()) {
			try {
				//WHEN : I retrieve the Work Experience records as agent
				APNGApplicationSelector.getWorkExperiencesByApplicationId('oops');
			}
			//THEN  : an Exception should be thrown
			catch (Exception e) {
				Assert.isTrue(
					e.getMessage().contains('Application not found'),
					'Application not found exception should be thrown'
				);
			}
		}
		Test.stopTest();
	}
}