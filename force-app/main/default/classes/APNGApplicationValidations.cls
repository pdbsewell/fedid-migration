/**
 * @description       : Validations for APNG Application
 * @author            Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-22   Ben Greenland   Initial Version
 * @group             APNG Application Webservice v3
 **/
public inherited sharing class APNGApplicationValidations extends ApplicationWSValidations {
	@TestVisible
	private APNGApplicationPayload.CDM_Application application;
	public APNGApplicationValidations() {
		super();
	}
	public APNGApplicationValidations(APNGApplicationPayload.PatchRequest reqObj) {
		super();
		this.application = reqObj.application;
	}
	// Exceptions
	@testVisible
	protected override Boolean isValidRequestType(RESTlib_Payload.Request reqObj) {
		return reqObj instanceof APNGApplicationPayload.PostRequest;
	}

	/**
	 *
	 * Get contact ID from request object.
	 * @param reqObj `RESTlib_Payload.Request`
	 * @return       `String`
	 */
	@testVisible
	protected override String getContactId(RESTlib_Payload.Request reqObj) {
		// below query created affiliations for contact when an Agent tries to use same contact in APNG
		return AgentPortalServices.getContact(
				((APNGApplicationPayload.PostRequest) reqObj).contactId,
				AgentPortalConstants.APPLICANT_PERSONA,
				AgentPortalConstants.SYSTEM_CONTEXT
			)
			?.Id;
	}
	/**
	 *
	 *	Get campus location from request object.
	 * @param reqObj `RESTlib_Payload.Request`
	 * @return       `String`
	 */
	@testVisible
	protected override String getCampusLocation(RESTlib_Payload.Request reqObj) {
		return ((APNGApplicationPayload.PostRequest) reqObj).campusLocation;
	}
	/**
	 *
	 * Get residency status from request object.
	 * @param reqObj `RESTlib_Payload.Request`
	 * @return       `String`
	 */
	@testVisible
	protected override String getResidencyStatus(RESTlib_Payload.Request reqObj) {
		return ((APNGApplicationPayload.PostRequest) reqObj).residencyStatus;
	}
	/**
	 *
	 * Get email from request object.
	 * @param reqObj `RESTlib_Payload.Request`
	 * @return       `List<CommonWSPayload.Email>`
	 */
	@testVisible
	protected override List<CommonWSPayload.Email> getEmail(RESTlib_Payload.Request reqObj) {
		return ((APNGApplicationPayload.PostRequest) reqObj).email;
	}
	/**
	 *
	 * Get phone from request object.
	 * @param reqObj `RESTlib_Payload.Request`
	 * @return       `List<CommonWSPayload.Phone>`
	 */
	@testVisible
	protected override List<CommonWSPayload.Phone> getPhone(RESTlib_Payload.Request reqObj) {
		return ((APNGApplicationPayload.PostRequest) reqObj).phone;
	}
	/**
	 * @description Validates a post request.
	 * @param reqObj APNG-specific post request.
	 * @return RESTlib_Ex.InvalidRequestException if validation fails; null otherwise.
	 */
	public override RESTlib_Ex.InvalidRequestException validate(RESTlib_Payload.Request reqObj) {
		if (!isValidRequestType(reqObj)) {
			exceptions.addException(new RESTlib_Ex.InvalidRequestException('Invalid request object type'));
			return exceptions;
		}
		// call common validations from parent class
		super.validateContactId(getContactId(reqObj));
		super.validateCampusLocation(getCampusLocation(reqObj), getContactId(reqObj));
		super.validateResidencyStatus(getResidencyStatus(reqObj));
		super.validatePhone(getPhone(reqObj));
		super.validateEmails(getEmail(reqObj));
		if (exceptions?.getExceptions() != null) {
			return exceptions;
		}
		return null;
	}

	/**
	 * @description Validates a patch request.
	 * @param reqObj APNG-specific patch request.
	 * @return RESTlib_Ex.InvalidRequestException if validation fails; null otherwise.
	 */
	public RESTlib_Ex.InvalidRequestException validatePatch(APNGApplicationPayload.PatchRequest reqObj) {
		this.application = reqObj.application;
		super.validateContactId(reqObj.application.crmContactId);
		super.isValidApplication(reqObj.application.applicationId);
		// return if there are any exceptions as Applicant and Application for patch requiest are not valid
		if (exceptions?.getExceptions()?.size() > 0) {
			return exceptions;
		}
		this.validatePatchApplications();
		if (exceptions?.getExceptions() != null) {
			return exceptions;
		}
		return null;
	}
	/* =====================================================================================
		VALIDATION METHODS
	===================================================================================== */
	/**
	 * @description Validates patch applications for APNG.
	 * @param reqObj Patch request object.
	 */
	public void validatePatchApplications() {
		Application__c application = ApplicationWSService.getApplicationByName(this.application.applicationId)[0];
		Boolean postSubmitPaymentUpdate;
		try {
			if (this.application.applicationStatus.equalsIgnoreCase(AgentPortalConstants.AGENT_DECLARATION_ACCEPTED)) {
				// This will check if the agent has any applications that are in the Agent Declaration Accepted status
				// If they do, it will throw an exception
				ApplicationWSService.checkAgentDeclarationAcceptedApplications(this.application.applicationId);
			}
			// Irrespective of the status, coming from payload we need to check if the application record in SF is in one of the submitted statuses
			postSubmitPaymentUpdate = AffiliationCheckService.SUBMITTED_STATUSES.contains(application.Status__c);
			// Validations
			if (!postSubmitPaymentUpdate) {
				if (this.application.qualifications != null) {
					this.validateQualification();
				}
				if (this.application.workExperiences != null) {
					super.workExperienceValidator.validateWorkExperience(this.application.workExperiences);
				}
				if (this.application.visa != null) {
					super.visaValidator.validateVisa(this.application.visa);
				}
				if (this.application.payment != null) {
					super.validatePayment(this.application.payment);
				}
			} else {
				// For submitted applications, only Payments can be updated
				if (this.application.payment == null) {
					throw new RestLib_Ex.InvalidRequestException(
						'Application is already in one of the Submitted statuses and cannot be edited'
					);
				}
			}
		} catch (Exception e) {
			Nebula.Logger.error('Exception: APNGApplicationValidations.validatePatchApplications:', e);
			throw new RestLib_ex.WebServiceException(e.getMessage());
		}
	}

	/**
	 * @description Validates a list of qualifications.
	 * @param submittedQualifications List of qualifications to validate.
	 */
	public void validateQualification() {
		if (this.application.qualifications == null) {
			return;
		}
		// validate common qualification attributes
		super.qualificationValidator.validateQualification(this.application.qualifications);
		for (ApplicationWSWrapper.CDM_Qualification qual : this.application.qualifications) {
			// error message for empty type is added in parent class
			if (super.isBlank(qual.type)) {
				super.getAPIResponseMessages('QUALIFICATION_TYPE_EMPTY', '');
				continue;
			}
			// Switch validation based on qualification type
			switch on qual.type?.name {
				when 'Secondary Education' {
					super.qualificationValidator.validateSecondaryQualification(qual);
					if (
						qual.countryObtained != null &&
						qual.countryObtained.value.equalsIgnoreCase('Australia') &&
						String.isBlank(qual.stateObtained)
					) {
						super.addInvalidException('STATE_EMPTY', super.qualificationValidator.getErrorPrefix(qual));
					}
					if (qual.countryObtained == null || String.isBlank(qual.countryObtained?.crmRecordId)) {
						super.addInvalidException('QUALIFICATION_COUNTRY_EMPTY', super.qualificationValidator.getErrorPrefix(qual));
					}
					if (String.isBlank(qual.type.crmRecordId)) {
						super.addInvalidException('QUALIFICATION_NAME_EMPTY', super.qualificationValidator.getErrorPrefix(qual));
					}
				}
				when 'Tertiary Education' {
					super.qualificationValidator.validateTertiaryQualification(qual);
					if (qual.countryObtained == null || String.isBlank(qual.countryObtained?.crmRecordId)) {
						super.addInvalidException('QUALIFICATION_COUNTRY_EMPTY', super.qualificationValidator.getErrorPrefix(qual));
					}
					if (String.isBlank(qual.type.qualificationName) && String.isBlank(qual.type.crmRecordId)) {
						super.addInvalidException('QUALIFICATION_NAME_EMPTY', super.qualificationValidator.getErrorPrefix(qual));
					}
				}
				// English test is also reffered as 'Admission Test' in OES
				when 'English Test' {
					super.qualificationValidator.validateEnglishTest(qual);
				}
				when 'Other Qualification' {
					super.qualificationValidator.validateOtherQualification(qual);
				}
			}
		}
	}
}