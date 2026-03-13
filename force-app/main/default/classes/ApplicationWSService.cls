/**
 * Service layer for Application Webservice. Utility and shared methods are implemented in this class.
 * Used in Application Webservice v3.0 onwards
 *
 * @author Girish P
 * @date 2022-01-05
 * @version 1.0
 * @group Application Webservice v3
 * @since
 */
public inherited sharing class ApplicationWSService {
	public class ApplicationException extends RestLib_Ex.ListException {
	}
	// public static RESTlib_Ex.ListException exceptions = new RESTlib_Ex.ListException();
	/**
	 * PatchApplicationService processing is done in this class. This is shared for application submission and update.
	 * APNG and OES applications are processed differently and they are in their respective payload classes
	 */
	public inherited sharing class PatchApplicationService extends ApplicationWSWrapper {
		public CDM_Application application;
		@TestVisible
		public Application__c applicationDetails;
		ApplicationResponseWrapper applicationResponseWrapper = new ApplicationResponseWrapper();
		Map<String, Object> resultMap = new Map<String, Object>();
		Boolean isAppnReviewSuccessful = false;
		List<String> reviewErrors = new List<String>();
		Savepoint updateApplicationSavePoint;
		private Boolean postSubmitPaymentUpdate {
			get {
				return AffiliationCheckService.SUBMITTED_STATUSES.contains(applicationDetails.Status__c);
			}
			set;
		}
		/**
		 * Based on the application type, the service is instantiated with correct payload for APNG or OES
		 *
		 * @param application `CDM_Application`
		 */
		public PatchApplicationService(CDM_Application application) {
			Nebula.Logger.info('ApplicationWSService.PatchApplicationService.constructor()' + application);
			if (application instanceof APNGApplicationPayload.CDM_Application) {
				this.application = (APNGApplicationPayload.CDM_Application) application;
			} else {
				this.application = (OESApplicationPayload.CDM_Application) application;
			}
			this.applicationDetails = application.asApplicationRecord();
			this.applicationDetails.Agent__c = CommonWSPayload.runningUser?.Contact.AccountId;
		}

		/**
		 * @description
		 * @return List<Application_Course_Preference__c>
		 **/
		public List<Work_Experience__c> workExperiences {
			get {
				if (workExperiences == null) {
					List<Work_Experience__c> applicationWorkExperiences = new List<Work_Experience__c>();
					if (application.workExperiences != null && !postSubmitPaymentUpdate) {
						for (CDM_WorkExperience workExp : application.workExperiences) {
							if (!workExp.isHistoric) {
								// exclude historic work experiences
								workExp.applicantRecord = new Contact(id = applicationDetails.Applicant__c);
								// This method parses the work experiences and returns Work Experience record
								applicationWorkExperiences.add(workExp.asExperienceRecord());
							}
						}
					}
					return applicationWorkExperiences;
				}
				return workExperiences;
			}
			set;
		}
		/**
		 * @description qualifications getter
		 * @return List<Application_Course_Preference__c>
		 **/
		public List<Contact_Qualification__c> qualifications {
			get {
				if (qualifications == null) {
					List<Contact_Qualification__c> applicationQualifications = new List<Contact_Qualification__c>();
					if (application.qualifications != null && !postSubmitPaymentUpdate) {
						for (CDM_Qualification qual : application.qualifications) {
							qual.applicantRecord = new Contact(id = applicationDetails.Applicant__c);
							// This method parses the qualifications and returns Contact qualification record
							applicationQualifications.add(qual.asQualificationRecord());
						}
					}
					return applicationQualifications;
				}
				return qualifications;
			}
			set;
		}
		/**
		 * @description coursePreferences getter
		 */
		public List<Application_Course_Preference__c> listCoursePreferences {
			get {
				if (listCoursePreferences == null) {
					// For OES applications, course preferences has more fields than APNG applications, so payload has t be type casted to
					// OESApplicationPayload.CDM_Application
					if (application instanceof OESApplicationPayload.CDM_Application) {
						application.coursePreferences = ((OESApplicationPayload.CDM_Application) application).coursePreferences;
					}
					List<Application_Course_Preference__c> applicationCoursePreferences = new List<Application_Course_Preference__c>();
					if (application.coursePreferences != null && !postSubmitPaymentUpdate) {
						for (CDM_ApplicationCoursePreference acp : application.coursePreferences) {
							acp.applicationRecord = applicationDetails;
							// This method parses the course preferences and returns Application course preference record
							applicationCoursePreferences.add(acp.asACPRecord());
						}
					}
					return applicationCoursePreferences;
				}
				return listCoursePreferences;
			}
			set;
		}

		/**
		 * Process the PATCH request. This method will update the application and common use case for APNG and OES.
		 * This method is shared for both APNG and OES applications
		 * APNG and OES applications are processed differently and they are in their respective payload classes
		 * @return Map<String, Object>
		 **/
		public ApplicationResponseWrapper process() {
			Nebula.Logger.info('ApplicationWSService.PatchApplicationService.process()' + applicationDetails);
			applicationResponseWrapper.application = new ApplicationWrapper(
				ApplicationWSService.geApplicationById(applicationDetails.Id)
			);
			try {
				//Allow Application updates as long as the status is not 'Agent Declaration Accepted' value
				// return the application as is if the status is 'Agent Declaration Accepted' and the application is already submitted
				if (
					(postSubmitPaymentUpdate &&
					application.applicationStatus.equalsIgnoreCase(AgentPortalConstants.AGENT_DECLARATION_ACCEPTED)) ||
					(String.isBlank(application.applicationStatus))
				) {
					return applicationResponseWrapper;
				}
				// Upsert Application Work Experiences
				if (!workExperiences.isEmpty()) {
					Nebula.Logger.info(
						'Processing ApplicationWSService.PatchApplicationService.process().workExperiences START' + workExperiences
					);
					AgentPortalServices.updateApplicationWorkExperiences(applicationDetails.Id, workExperiences);
					applicationResponseWrapper.application.workExperiences = new WorkExperienceWrapper()
						.fromWorkExperienceList(ApplicationWSService.getWorkExperiencesByApplicationId(applicationDetails.Id));
				}
				// Upsert Application Course Preferences
				if (!listCoursePreferences.isEmpty()) {
					AgentPortalServices.updateApplicationCoursePreferences(applicationDetails.Id, listCoursePreferences);
					// Get the updated course preferences and set it to the response
					applicationResponseWrapper.application.coursePreferences = new ApplicationCoursePreference()
						.fromObjectList(ApplicationWSService.getApplicationCoursePreferences(applicationDetails.Id));
				}
				// Upsert Application Qualifications
				if (!qualifications.isEmpty()) {
					Nebula.Logger.info(
						'Processing Course qualifications: ApplicationWSService.PatchApplicationService.process().qualifications' +
						qualifications
					);
					AgentPortalServices.updateApplicationQualifications(applicationDetails.Id, qualifications);
					// Get the updated qualifications and set it to the response
					applicationResponseWrapper.application.qualifications = new ContactQualificationWrapper()
						.fromObjectList(
							new ContactQualificationsSelector().selectByApplicationId(new Set<Id>{ applicationDetails.Id })
						);
				}
				// Update Application savepoint, if there is a need to revert back the transaction in case of exception
				updateApplicationSavePoint = Database.setSavepoint();
				// process application differently when the status is 'Agent Declaration Accepted'
				if (application.applicationStatus.equalsIgnoreCase(AgentPortalConstants.AGENT_DECLARATION_ACCEPTED)) {
					this.processAgentDeclarationAcceptedApplications();
				} else {
					// Update Application
					AgentPortalServices.updateApplication(applicationDetails);
				}
				Nebula.Logger.info('ApplicationWSService.PatchApplicationService.process().updateApplication successful');
			} catch (Exception ex) {
				Nebula.Logger.exception(
					'Exception ApplicationWSService.PatchApplicationService.process():' + ex.getMessage(),
					ex
				);
				if (updateApplicationSavePoint != null) {
					Database.rollback(updateApplicationSavePoint);
				}
				// WebServiceException sends exact message to the client
				throw new RESTlib_Ex.WebServiceException(ex.getMessage());
			}
			// finally {
			// 	applicationResponseWrapper.application = new ApplicationWrapper(
			// 		ApplicationWSService.geApplicationById(applicationDetails.Id)
			// 	);
			// }
			return applicationResponseWrapper;
		}
		/**
		 * process Applications when the status is 'Agent Declaration Accepted'
		 * checks for affiliation and review errors
		 *
		 * @exception
		 */
		private void processAgentDeclarationAcceptedApplications() {
			// Application submission specific code -- START
			updateApplicationSavePoint = Database.setSavepoint();
			applicationDetails.Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
			applicationDetails.Submitted_Date__c = Date.today();
			AgentPortalServices.updateApplication(applicationDetails);
			// get the application details for the response
			applicationResponseWrapper.application = new ApplicationWrapper(
				ApplicationWSService.geApplicationById(applicationDetails.Id)
			);
			// Application submission specific code -- END
		}
	}
	/*** HELPER METHODS */
	/**
	 * check if any existing draft application exists for the same campus
	 *
	 * @param applicantSFIdOrCRMId `String`
	 * @param campus
	 * @param agencyOrgCodes
	 * @return                     `Boolean`
	 */
	public static Boolean doOtherDraftsExistForSameCampus(
		String applicantSFIdOrCRMId,
		String campus,
		Set<String> agencyOrgCodes
	) {
		List<Application__c> existingDraftApps = [
			SELECT Id
			FROM Application__c
			WHERE
				Status__c = 'Draft'
				AND (Applicant__c = :applicantSFIdOrCRMId
				OR Applicant__r.CRM_ID__c = :applicantSFIdOrCRMId)
				AND Campus_Location__c = :campus
				AND Agent_Org_Unit_Code__c IN :agencyOrgCodes
			WITH SECURITY_ENFORCED
		];
		if (existingDraftApps.isEmpty()) {
			return false;
		}
		return true;
	}
	/**
	 *  Check if the contact is valid
	 *
	 * @param applicantSFIdOrCRMId `String`
	 * @return                     `Boolean`
	 */
	public static Boolean isValidContact(String applicantSFIdOrCRMId) {
		return ![SELECT id FROM Contact WHERE CRM_ID__c = :applicantSFIdOrCRMId OR ID = :applicantSFIdOrCRMId].isEmpty();
	}
	/**
	 *  get application by Name
	 *
	 * @param applicantSFIdOrCRMId `String` - SF ID or CRM ID
	 * @return                     `Boolean`
	 */
	public static List<Application__c> getApplicationByName(String applicationIdorName) {
		return [
			SELECT
				Id,
				Name,
				Sent_to_student_for_review_Timestamp__c,
				Agent_Edits_After_Applicant_Acceptance__c,
				Campus_Location__c,
				Applicant__c,
				Agent__c,
				Status__c
			FROM Application__c
			WHERE NAME = :applicationIdorName
		];
	}
	/**
	 *  Check if the application is valid
	 *
	 * @param applicationIdorName `String` - Application Name
	 * @return                   `Boolean`
	 */
	public static Boolean isValidApplication(String applicationIdorName) {
		return !getApplicationByName(applicationIdorName).isEmpty();
	}

	/**
	 * Check application review before submission
	 *
	 * @param `String` applicationId application SF Id
	 * @return `List<String>`
	 */
	public static List<String> checkApplicationReviewErrors(String applicationSFId) {
		List<String> reviewErrors = new List<String>();
		List<Map<String, Object>> reviewErrorsBySection;
		//Run validations for APNG applications only
		reviewErrorsBySection = AppDeclarationFormCC.getValidationErrors(applicationSFId, true);
		// reviewErrors = AgentPortalServices.reviewApplicationForSubmit(applicationDetails, applicationCoursePreferences, applicationQualifications, applicationWorkExperiences);
		for (Map<String, Object> eachReviewErrorsBySection : reviewErrorsBySection) {
			reviewErrors = new List<String>();
			reviewErrors.add(
				eachReviewErrorsBySection.get('label') +
					' - ' +
					String.join(((List<String>) eachReviewErrorsBySection.get('errors')), '; ')
			);
		}
		return reviewErrors;
	}
	/**
	 * Run validations for APNG applications Run Affilication check
	 * @param applicationName Application Name
	 * @return Map<String, Object>
	 **/
	public static AffiliationCheckService.AffiliationResult checkAffiliationApplications(Application__c application) {
		List<Application_Course_Preference__c> appACPs = ApplicationWSService.getApplicationCoursePreferences(
			application.Id
		);
		AffiliationCheckService.AffiliationResult affiliationResult = new AffiliationCheckService(
				application.Applicant__c,
				application.Agent__c,
				application.Campus_Location__c,
				appACPs
			)
			.result;
		return affiliationResult;
	}

	/**
	 *
	 *	Check if the agent is allowed to submit the application and if there are any affiliate errors
	 * @param applicationName `String`
	 * @return `void` throws ApplicationException
	 */
	public static void checkAgentDeclarationAcceptedApplications(String applicationName) {
		Application__c application = [
			SELECT
				id,
				Name,
				Sent_to_student_for_review_Timestamp__c,
				Agent_Edits_After_Applicant_Acceptance__c,
				Campus_Location__c,
				Applicant__c,
				Agent__c,
				Status__c
			FROM Application__c
			WHERE NAME = :applicationName
			LIMIT 1
		];
		AffiliationCheckService.AffiliationResult affiliationResult = checkAffiliationApplications(application);
		if (!affiliationResult.canSubmitApplications) {
			throw new ApplicationException(affiliationResult.message);
		}
		List<String> reviewErrors = checkApplicationReviewErrors(application.Id);
		// Application submission specific code -- START
		if (!reviewErrors.isEmpty()) {
			throw new ApplicationException('Application review failed:' + String.join(reviewErrors, '; '));
		}
	}
	/**
	 * get work experiences by application Id
	 *
	 * @param applicationId `String`
	 * @return              `List<Work_Experience__c>`
	 */
	public static List<Work_Experience__c> getWorkExperiencesByApplicationId(Id applicationId) {
		Set<String> workExpFieldSet = new Set<String>(AgentPortalConstants.SEARCH_FIELDS_WORKEXPERIENCE.split(','));
		String whereClause =
			'id IN (SELECT Work_Experience__c FROM Application_Work_Experience_Provided__c WHERE Application__c = \'' +
			applicationId +
			'\')';
		String currAppnWorkExpQuery = DynamicSoqlBuilder.getInstance()
			.showSOQLStatement(true)
			.setEnforced(true)
			.querySObject(String.escapeSingleQuotes('Work_Experience__c'))
			.queryFields(workExpFieldSet)
			.getQuery(whereClause);

		return Database.query(currAppnWorkExpQuery);
	}
	/**
	 * get application by Id
	 *
	 * @param applicationId `String`
	 * @return              `Application__c`
	 */
	public static Application__c geApplicationById(Id applicationId) {
		Set<String> applicationFieldSet = new Set<String>(AgentPortalConstants.SEARCH_FIELDS_APPLICATION.split(','));
		String whereClause = 'id=:applicationId';
		return (Application__c) Database.query(
			DynamicSoqlBuilder.getInstance()
				.showSOQLStatement(true)
				.setEnforced(true)
				.querySObject(String.escapeSingleQuotes('Application__c'))
				.queryFields(applicationFieldSet)
				.getQuery(whereClause)
		)[0];
	}
	/**
	 * get course preferences by application Id
	 *
	 * @param applicationId `String`
	 * @return              `List<Application_Course_Preference__c>`
	 */
	public static List<Application_Course_Preference__c> getApplicationCoursePreferences(String applicationId) {
		// Generate ACP sub query
		Set<String> acpFieldSet = new Set<String>(AgentPortalConstants.SEARCH_FIELDS_ACP.split(','));
		String clause = 'Application__c = \'' + applicationId + '\'';
		String acpQuery = DynamicSoqlBuilder.getInstance()
			.showSOQLStatement(true)
			.setEnforced(false)
			.querySObject(String.escapeSingleQuotes('Application_Course_Preference__c'))
			.queryFields(acpFieldSet)
			.getQuery(clause);
		return Database.query(acpQuery);
	}
}