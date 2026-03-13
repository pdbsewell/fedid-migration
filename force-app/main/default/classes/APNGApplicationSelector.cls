/**
 * @description       APNG Application Selector class. This class is responsible for selecting application details. cerates wrapper for
 *                     application details, course preferences, qualifications, work experiences.
 * @author            Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-09-20   Ben Greenland   Initial Version
 * @group            APNG Application Webservice v3
 **/
public inherited sharing class APNGApplicationSelector {
	/**
	 * @description Gets Application details based on Id
	 * @param       applicationName  String
	 * @return      AgentPortalPayload.ApplicationDetails Wrapper containing Application details & ACPs
	 * @since       24/04/2023
	 * @revision    24/04/2023 - Vinothraja - Created
	 */
	public static APNGApplicationPayload.ApplicationDetails getApplicationDetails(String applicationName) {
		APNGApplicationPayload.ApplicationDetails appWrapper = new APNGApplicationPayload.ApplicationDetails();
		// Generate application query
		Set<String> applicationFieldSet = new Set<String>(AgentPortalConstants.SEARCH_FIELDS_APPLICATION.split(','));
		applicationFieldSet.add('Citizenship_Country__r.uniqueCountryExternalId__c');
		applicationFieldSet.add('Single_Entry_Visa__r.uniqueCountryExternalId__c');
		String clause = 'name = \'' + applicationName + '\'';
		String applicationQuery = DynamicSoqlBuilder.getInstance()
			.showSOQLStatement(true)
			.setEnforced(true)
			.querySObject(String.escapeSingleQuotes('Application__c'))
			.queryFields(applicationFieldSet)
			.getQuery(clause);
		applicationQuery += ' LIMIT 1';
		List<Application__c> lstApplications = Database.query(applicationQuery);
		if (!lstApplications.isEmpty()) {
			appWrapper.details = new APNGApplicationPayload.ApplicationWrapper(lstApplications[0]); //
			appWrapper.coursePreferences = getApplicationCoursePreferences(applicationName);
			return appWrapper;
		}
		return null;
	}

	/**
	 * @author      BGreenalnd
	 * @description Gets Contact Qualifications based on Application Name refactored from agentportalservices
	 * @param       applicationName
	 * @return      AgentPortalPayload.Qualifications Wrapper containing current Application's and historical Qualifications
	 * @revision    September 2024
	 */
	public static APNGApplicationPayload.Qualifications getContactQualificationsByApplicationId(String applicationName) {
		APNGApplicationPayload.Qualifications qualifications = new APNGApplicationPayload.Qualifications();
		// Fetch current Application's applicant
		Set<String> applicationFieldSet = new Set<String>{ 'id', 'Applicant__c', 'Applicant__r.CRM_id__c', 'Name' };
		String clause = 'name = \'' + applicationName + '\'';
		String applicationQuery = DynamicSoqlBuilder.getInstance()
			.showSOQLStatement(true)
			.setEnforced(true)
			.querySObject(String.escapeSingleQuotes('Application__c'))
			.queryFields(applicationFieldSet)
			.getQuery(clause);
		applicationQuery += ' LIMIT 1';
		List<Application__c> lstApplications = Database.query(applicationQuery);
		if (!lstApplications.isEmpty()) {
			Application__c currentApplication = lstApplications[0];
			qualifications.applicationId = currentApplication.Name;
			qualifications.applicantId = currentApplication.Applicant__r.CRM_id__c;

			// Fetch Qualifications for Current Application
			ContactQualificationsSelector contactQualifications = new ContactQualificationsSelector();
			List<Contact_Qualification__c> currentApplicationQualfications = contactQualifications.selectByApplicationId(
				new Set<Id>{ currentApplication.id }
			);

			qualifications.applicationQualifications = new APNGApplicationPayload.ContactQualificationWrapper()
				.fromObjectList(currentApplicationQualfications);
			qualifications.recordCount = qualifications.applicationQualifications.size();
			return qualifications;
		} else {
			throw new RESTlib_Ex.NotFoundException('Application not found');
		}
	}

	public static List<APNGApplicationPayload.ApplicationCoursePreference> getApplicationCoursePreferences(
		String applicationName
	) {
		List<Application_Course_Preference__c> acpList = AgentPortalServices.getApplicationCoursePreferences(
			applicationName
		);
		return new APNGApplicationPayload.ApplicationCoursePreference().fromObjectList(acpList);
	}

	public static APNGApplicationPayload.WorkExperiences getWorkExperiencesByApplicationId(String applicationName) {
		APNGApplicationPayload.WorkExperiences experiences = new APNGApplicationPayload.WorkExperiences();
		// Fetch current Application's applicant
		Set<String> applicationFieldSet = new Set<String>{ 'id', 'Applicant__c', 'Applicant__r.CRM_id__c', 'Name' };
		String clause = 'name = \'' + applicationName + '\'';
		String applicationQuery = DynamicSoqlBuilder.getInstance()
			.showSOQLStatement(true)
			.setEnforced(true)
			.querySObject(String.escapeSingleQuotes('Application__c'))
			.queryFields(applicationFieldSet)
			.getQuery(clause);
		applicationQuery += ' LIMIT 1';
		List<Application__c> lstApplications = Database.query(applicationQuery);
		if (!lstApplications.isEmpty()) {
			Application__c currentApplication = lstApplications[0];
			experiences.applicationId = currentApplication.Name;
			experiences.applicantId = currentApplication.Applicant__r.CRM_id__c;
			// Fetch Work Experiences for Current Application
			String workExperienceSelect = 'Id,External_ID__c,Position__c,Employer_Name__c,Start_Date__c,End_Date__c,Country__r.ISO_Alpha_2__c,Country__r.Name,Country__r.Id,Country__r.uniqueCountryExternalId__c,Contact_Person_First_Name__c,Contact_Person_Last_Name__c,Contact_Person_Email__c,Contact_Person_Phone__c';
			Set<String> workExpFieldSet = new Set<String>(workExperienceSelect.split(','));
			clause =
				'id IN (SELECT Work_Experience__c FROM Application_Work_Experience_Provided__c WHERE Application__c = \'' +
				currentApplication.id +
				'\')';
			String currAppnWorkExpQuery = DynamicSoqlBuilder.getInstance()
				.showSOQLStatement(true)
				.setEnforced(true)
				.querySObject(String.escapeSingleQuotes('Work_Experience__c'))
				.queryFields(workExpFieldSet)
				.getQuery(clause);

			List<Work_Experience__c> currentApplicationWorkExperiences = Database.query(currAppnWorkExpQuery);
			experiences.applicationExperiences = new APNGApplicationPayload.WorkExperienceWrapper()
				.fromWorkExperienceList(currentApplicationWorkExperiences);

			return experiences;
		} else {
			throw new RESTlib_Ex.NotFoundException('Application not found');
		}
	}
}