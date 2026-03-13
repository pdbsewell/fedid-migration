/**
 * @description     		OES Application Validations extends core validations from ApplicationWSValidations.
 *                      OES-specific validation rules and logic are implemented here.
 * @author            Ben Greenland
 * @group             OES Application Webservice v3
 *
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-23   Ben Greenland   Initial Version
 * 1.0   2024-12-03   Girish P   Modifed and optimized further
 **/
public inherited sharing class OESApplicationValidations extends ApplicationWSValidations { //NOPMD
	@TestVisible
	private OESApplicationPayload.PatchRequest reqObj;
	@TestVisible
	private OESApplicationPayload.CDM_Application application;
	Application__c applicationDetails {
		get {
			return applicationDetails == null
				? ApplicationWSService.getApplicationByName(this.application.applicationId)[0]
				: applicationDetails;
		}
	}

	public OESApplicationValidations() {
		super();
	}
	public OESApplicationValidations(OESApplicationPayload.PatchRequest applicationPatchRequest) {
		super();
		this.application = applicationPatchRequest.application;
	}
	final set<String> residencyStatusCheckEnforced = new Set<String>{ 'INT-TEP', 'INTRNTNL.A' };
	set<String> acceptableVerificationStatuses = new Set<String>{
		'verified',
		'unverified',
		'unknown',
		'invalid',
		'expired'
	};

	// Constants
	public static final Map<String, String> OES_API_RESPONSE_MESSAGES = new Map<String, String>{
		'VISA_APPLICANT_CITIZENSHIP_UNIQUE_EXTID_MISSING' => 'Applicant\'s Visa citizenship.uniqueCountryExternalId field cannot be empty',
		'SINGLE_ENTRY_VISA_COUNTRY_EMPTY' => 'Applicant\'s Visa singleEntryVisaCountry.uniqueCountryExternalId field is Blank',
		'VISA_START_DATE_EMPTY' => 'Visa start date cannot be empty.',
		'VISA_END_DATE_EMPTY' => 'Visa end date cannot be empty.',
		'VISA_NUMBER_EMPTY' => 'Visa number cannot be empty.',
		'VISA_EMPTY' => 'Visa detials cannot be empty.',
		'VISA_TYPE_EMPTY' => 'Visa type cannot be empty.',
		'VISA_CODE_EMPTY' => 'Visa code cannot be empty.',
		'VISA_CITIZENSHIP_CODE_EMPTY' => 'Visa citizenship code cannot be empty.',
		'COURSE_OFFERING_EMPTY' => 'Course Offering cannot be empty.',
		'APPLICATION_PREFERENCE_EMPTY' => 'Application Preference cannot be empty.',
		'COURSE_OFFERING_UID_EMPTY' => 'Course Offering UID cannot be empty.',
		'VERICATION_STATUS_EMPTY' => 'Verification Status cannot be empty.',
		'RESULT_TYPE_INVALID' => 'Result Type Status must be Satisfactory or Unsatisfactory.',
		'DATE_ACHIEVED_EMPTY' => 'Date Achieved cannot be empty',
		'START_DATE_EMPTY' => 'Start date cannot be empty',
		'QUALIFICATION_NAME_EMPTY' => 'Qualification name cannot be empty',
		'QUALIFICATION_UID_EMPTY' => 'QualificationUid cannot be empty',
		'SCORE_EMPTY' => 'Score cannot be empty',
		'RESIDENCY_EMPTY' => 'Residency status cannot be empty.',
		'INVALID_RESIDENCY_STATUSE' => 'Invalid residency status',
		'ENGLISH_LANGUAGE_PROFICIENCY_EMPTY' => 'English language proficiency empty or invalid',
		'PASSPORT_NUMBER_EMPTY' => 'Passport number cannot be empty.',
		'INSTITUTION_EMPTY' => 'Institution cannot be empty.',
		'LEVEL_OF_COMPLETION_EMPTY' => 'Level of completion is empty',
		'VISA_IMMIGRATION_OFFICE_EMPTY' => 'Visa immigration office cannot be empty',
		'INVALID_ACP_EXTERNAL_ID' => 'Invalid null external ID for Applicantion Course Preference',
		// Other messages...
		'VERIFICATION_STATUS_INVALID' => 'Verification Status must be Satisfactory or Unsatisfactory',
		'COURSE_OFFERING_EMPTY' => 'Course Offering cannot be empty.',
		'COURSE_OFFERING_UID_EMPTY' => 'Course Offering UID cannot be empty.',
		'ACP_OFFER_DATE_EMPTY' => 'Offer Date cannot be empty.',
		'ACP_ACTUAL_OFFER_RESPONSE_DATE_EMPTY' => 'Actual Offer Response Date cannot be empty.',
		'ACP_OFFER_RESPONSE_STATUS_EMPTY' => 'ACP_OFFER_RESPONSE_STATUS_EMPTY',
		'QUALIFICATION_WORK_EX_EMPTY' => 'Either Qualification or work experience should be there to submit the application',
		'EMPTY_REFERENCE_ID' => 'External Reference ID cannot be empty'
	};

	@TestVisible
	public static final Set<String> ACP_VALID_BASIS_FOR_ADMISSION_TYPE = new Set<String>{
		'311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)',
		'312: TWO SINGLE HIGHER EDUCATION UNITS',
		'401: WORK AND LIFE EXPERIENCE'
	};
	// List_of_Values__c starts These value are stored in List_of_Values__c object and Value__c field
	@TestVisible
	public static final Set<String> ACP_VALID_DOCUMENTATION_STATUS = new Set<String>{ 'SATISFIED' };
	@TestVisible
	public static final Set<String> ACP_VALID_OUTCOME_STATUS = new Set<String>{ 'OFFER' };
	@TestVisible
	public static final Set<String> ACP_VALID_ENTRY_QUAL_STATUS = new Set<String>{ 'QUALIFIED' };
	@TestVisible
	public static final Set<String> ACP_VALID_OFFER_RESPONSE_STATUS = new Set<String>{ 'PENDING' };
	// List_of_Values__c ends
	/* =====================================================================================
		OVERRIDDEN METHODS
	===================================================================================== */

	/**
	 * @description Validates the provided request object.
	 * @param reqObj Request object to validate.
	 * @return RESTlib_Ex.InvalidRequestException if validation fails; null otherwise.
	 */
	public override RESTlib_Ex.InvalidRequestException validate(RESTlib_Payload.Request reqObj) {
		if (!isValidRequestType(reqObj)) {
			exceptions.addException(new RESTlib_Ex.InvalidRequestException('Invalid request object type'));
			return exceptions;
		}
		Nebula.Logger.info('Validating request for application:validate() ' + reqObj);
		// Parent class common validations
		super.validateContactId(getContactId(reqObj));
		super.validateCampusLocation(getCampusLocation(reqObj), getContactId(reqObj));
		super.validateResidencyStatus(getResidencyStatus(reqObj));
		super.validatePhone(getPhone(reqObj));
		super.validateEmails(getEmail(reqObj));

		return exceptions?.getExceptions() != null ? exceptions : null;
	}

	/**
	 * @description Validates a patch request.
	 * @param reqObj OES-specific patch request.
	 * @return RESTlib_Ex.InvalidRequestException if validation fails; null otherwise.
	 */
	public RESTlib_Ex.InvalidRequestException validatePatch(OESApplicationPayload.PatchRequest applicationPatchRequest) {
		Nebula.Logger.info('Validating request for application:validatePatch() ' + applicationPatchRequest);
		this.reqObj = applicationPatchRequest;
		this.application = applicationPatchRequest.application;
		super.validateContactId(applicationPatchRequest.application.crmContactId);
		super.isValidApplication(reqObj.application.applicationId);
		// return if there are any exceptions as Applicant and Application for patch requiest are not valid
		if (exceptions?.getExceptions()?.size() > 0) {
			return exceptions;
		}
		this.validatePatchApplications();
		if (exceptions != null && exceptions.getExceptions() != null) {
			return exceptions;
		}
		return null;
	}
	/**
	 *  @description Validates a post request.
	 *
	 * @param reqObj Request object to validate.
	 * @return       `Boolean`
	 */
	protected override Boolean isValidRequestType(RESTlib_Payload.Request reqObj) {
		return reqObj instanceof OESApplicationPayload.PostRequest;
	}
	/**
	 *
	 *	@description Get the contact ID from the request object.
	 * @param reqObj Request object to validate.
	 * @return       `String`
	 */
	protected override String getContactId(RESTlib_Payload.Request reqObj) {
		return ((OESApplicationPayload.PostRequest) reqObj).contactId;
	}
	/**
	 *  @description Get the campus location from the request object.
	 *
	 * @param reqObj Request object to validate.
	 * @return       `String`
	 */
	protected override String getCampusLocation(RESTlib_Payload.Request reqObj) {
		return ((OESApplicationPayload.PostRequest) reqObj)?.campusLocation;
	}
	/**
	 *
	 * @description Get the residency status from the request object.
	 * @param reqObj Request object to validate.
	 * @return       `String`
	 */
	protected override String getResidencyStatus(RESTlib_Payload.Request reqObj) {
		return ((OESApplicationPayload.PostRequest) reqObj)?.residencyStatus;
	}
	/**
	 *
	 * @description Get the email from the request object.
	 * @param reqObj Request object to validate.
	 * @return       `List<CommonWSPayload.Email>`
	 */
	protected override List<CommonWSPayload.Email> getEmail(RESTlib_Payload.Request reqObj) {
		return ((OESApplicationPayload.PostRequest) reqObj)?.email;
	}
	/**
	 * @description Get the phone from the request object.
	 *
	 * @param reqObj Request object to validate.
	 * @return       `List<CommonWSPayload.Phone>`
	 */
	protected override List<CommonWSPayload.Phone> getPhone(RESTlib_Payload.Request reqObj) {
		return ((OESApplicationPayload.PostRequest) reqObj)?.phone;
	}
	/**
	 * @description Get the API response error messages read from OES_API_RESPONSE_MESSAGES map from current class or API_VALIDATION_RESPONSE_MESSAGES map
	 *  from parent class.
	 *
	 * @param key 	  `String` the key to get the error message.
	 * @param attribute `String` the payload`s attribute to get the error message for
	 * @return          `String` the error message that corresponds to the key and sent to the client.
	 */
	public String getAPIResponseErrorMessages(String key, String attribute) {
		String message = (OES_API_RESPONSE_MESSAGES.containsKey(key)
			? OES_API_RESPONSE_MESSAGES.get(key)
			: API_VALIDATION_RESPONSE_MESSAGES.get(key));
		return String.isBlank(attribute) ? message : attribute + ':' + message;
	}
	/* =====================================================================================
		VALIDATION METHODS
	===================================================================================== */
	/**
	 * @description Validates patch applications for OES.
	 * @param reqObj Patch request object.
	 */
	public void validatePatchApplications() {
		try {
			// Initialization and extraction
			Nebula.Logger.info('Validating request for application:validatePatchApplications() ' + this.application);
			Boolean postSubmitPaymentUpdate = AffiliationCheckService.SUBMITTED_STATUSES.contains(
				applicationDetails.Status__c
			);
			this.validateCdmAcp();
			this.validateApplicationStatus();
			if (!postSubmitPaymentUpdate) {
				this.validateVisa();
				this.validateQualification();
				this.validateWorkExperience();
				this.validateApplicant();
			} else {
				/**
				 * for OES, if the Application is already in a submitted state, it implies that
				 * This is a subsequent update call post-transfer job in order to recover the
				 * previous ACP statuses that may have been overwritten.
				 *
				 * In this case, we simply return the current state of the Application and only
				 * allow updates on ACP
				 */
				if (this.application.coursePreferences == null) {
					throw new RestLib_Ex.InvalidRequestException(
						'Application is already in one of the Submitted statuses and cannot be edited'
					);
				}
			}
			// Either qualification or work experience should be there to submit the application
			if (
				this.application.applicationStatus == 'Data Validation Ready' &&
				AffiliationCheckService.DRAFT_STATUSES.contains(applicationDetails.Status__c) &&
				(this.application.qualifications == null || this.application.qualifications.isEmpty()) &&
				(this.application.workExperiences == null || this.application.workExperiences.isEmpty())
			) {
				super.addInvalidException(getAPIResponseErrorMessages('QUALIFICATION_WORK_EX_EMPTY', ''));
			}
		} catch (RESTlib_Ex.InvalidRequestException e) {
			Nebula.Logger.error('Exception validating patch applications:', e);
			throw e;
		}
	}
	/**
	 * @description Validates the status of an application.
	 * OES can only update the status of an application if it is in a Draft or Failed Data Validation status
	 * and the applicationStatus cannot be changed if the application is already in one of the Submitted statuses.
	 * @method validateApplicationStatus
	 */
	public void validateApplicationStatus() {
		switch on applicationDetails.Status__c {
			when 'Draft' {
				if (this.application.applicationStatus != 'Data Validation Ready') {
					throw new RESTlib_Ex.InvalidRequestException('Invalid status transition from Draft');
				}
			}
			// Update to Failed Data validation
			when 'Failed Data validation' {
				if (this.application.applicationStatus != 'Data Validation Ready') {
					throw new RESTlib_Ex.InvalidRequestException('Invalid status transition from Failed Data Validation');
				}
			}
			when 'Submitted' {
				if (this.application.applicationStatus != 'Submitted' && this.application.coursePreferences == null) {
					throw new RESTlib_Ex.InvalidRequestException(
						'Application is already in one of the Submitted statuses and cannot be edited'
					);
				}
			}
			when else {
				throw new RESTlib_Ex.InvalidRequestException('Invalid application status');
			}
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
			if (qual.type == null) {
				super.addInvalidException(getAPIResponseErrorMessages('QUALIFICATION_TYPE_EMPTY', ''));
				continue;
			}
			// validate qualification reference id when ACP status are being update during the patch request and
			if (AffiliationCheckService.SUBMITTED_STATUSES.contains(applicationDetails.Status__c)) {
				validateEmptyAttribute(qual.uniqueExternalId, getAPIResponseErrorMessages('EMPTY_REFERENCE_ID', ''));
			}

			// this.validateQualificationUID(qual);
			// when qualification type is not empty, validate all the attributes
			// if (String.isNotBlank(qual.type?.qualificationUid)) {
			// 	// TODO:GIRISH  New Change
			// 	// super.validateEmptyAttribute(
			// 	// 	qual.type?.qualificationName,
			// 	// 	getAPIResponseErrorMessages('QUALIFICATION_NAME_EMPTY', super.qualificationValidator.getErrorPrefix(qual))
			// 	// );

			// }
			// Switch validation based on qualification type
			switch on qual.type?.name {
				when 'Tertiary Education' {
					if (qual.countryObtained == null || qual.countryObtained?.uniqueCountryExternalId == null) {
						super.addInvalidException('COUNTRY_EXTERNAL_ID_EMPTY', super.qualificationValidator.getErrorPrefix(qual));
					}
					super.validateEmptyAttribute(
						qual.type?.qualificationName,
						getAPIResponseErrorMessages('QUALIFICATION_NAME_EMPTY', super.qualificationValidator.getErrorPrefix(qual))
					);

					super.validateEmptyAttribute(
						qual.isEnglishInstruction,
						getAPIResponseErrorMessages('ENGLISH_LANGUAGE_EMPTY', super.qualificationValidator.getErrorPrefix(qual))
					);
					super.qualificationValidator.validateTertiaryQualification(qual);
				}
				when 'Secondary Education' {
					this.validateQualificationSecondary(qual);
				}
				// English test is also reffered as 'Admission Test' in OES
				when 'English Test' {
					super.qualificationValidator.validateEnglishTest(qual);
					this.validateEnglishTest(qual);
				}
				when 'Other Qualification' {
					this.validateOtherQualification(qual);
				}
			}
		}
	}

	/* =====================================================================================
		HELPER METHODS
	===================================================================================== */
	/**
	 * @description Validates the applicant details.
	 *
	 **/
	@TestVisible
	private void validateApplicant() {
		super.validateEmptyAttribute(this.application.residencyStatus, getAPIResponseErrorMessages('RESIDENCY_EMPTY', ''));
		super.validateEmptyAttribute(
			this.application.englishLanguageProficiency,
			getAPIResponseErrorMessages('ENGLISH_LANGUAGE_PROFICIENCY_EMPTY', '')
		);
	}
	/**
	 * @description Validates English test qualifications.
	 * @param qual Qualification to validate.
	 */
	private void validateEnglishTest(ApplicationWSWrapper.CDM_Qualification qual) {
		// qualificationUID is only applicable to English test and secondary qualifications
		this.validateQualificationUID(qual);
		this.validateResultTypeAndVerificationStatus(qual);
	}
	/**
	 * @description validates the secondary qualification
	 * @param qual
	 */
	@TestVisible
	private void validateQualificationSecondary(ApplicationWSWrapper.CDM_Qualification qual) {
		// qualificationUID is only applicable to English test and secondary qualifications
		this.validateQualificationUID(qual);
		if (qual.countryObtained == null || qual.countryObtained?.uniqueCountryExternalId == null) {
			super.addInvalidException('COUNTRY_EXTERNAL_ID_EMPTY', super.qualificationValidator.getErrorPrefix(qual));
		}
		super.validateEmptyAttribute(
			qual.isEnglishInstruction,
			getAPIResponseErrorMessages('ENGLISH_LANGUAGE_EMPTY', super.qualificationValidator.getErrorPrefix(qual))
		);
		super.qualificationValidator.validateSecondaryQualification(qual);
		this.validateResultTypeAndVerificationStatus(qual);
	}
	/**
	 * validates the other qualification
	 *
	 * @param qual Qualification to validate.
	 */
	private void validateOtherQualification(ApplicationWSWrapper.CDM_Qualification qual) {
		super.qualificationValidator.validateOtherQualification(qual);
	}
	/**
	 * @description Validates the qualification UID. is only applicable to English test and secondary qualifications
	 * @param qual Qualification to validate.
	 */
	private void validateQualificationUID(ApplicationWSWrapper.CDM_Qualification qual) {
		if (String.isBlank(qual.type.qualificationUid)) {
			super.addInvalidException(
				getAPIResponseErrorMessages('QUALIFICATION_UID_EMPTY', super.qualificationValidator.getErrorPrefix(qual))
			);
		}
	}

	/**
	 * @description Validates result type and verification status,
	 * Only applicable for English Test qualification and secondary qualifications.
	 * @param qual Qualification to validate.
	 */
	private void validateResultTypeAndVerificationStatus(ApplicationWSWrapper.CDM_Qualification qual) {
		if (String.isBlank(qual.type?.qualificationUid)) {
			return;
		}
		super.validateEmptyAttribute(
			qual.resultType,
			getAPIResponseErrorMessages('RESULT_TYPE_EMPTY', super.qualificationValidator.getErrorPrefix(qual))
		);
		super.validateEmptyAttribute(
			qual.verificationStatus,
			getAPIResponseErrorMessages('VERICATION_STATUS_EMPTY', super.qualificationValidator.getErrorPrefix(qual))
		);
		if (
			String.isNotBlank(qual.resultType) &&
			!qual.resultType?.equalsIgnoreCase('Satisfactory') &&
			!qual.resultType?.equalsIgnoreCase('Unsatisfactory')
		) {
			super.addInvalidException(
				getAPIResponseErrorMessages('RESULT_TYPE_INVALID', super.qualificationValidator.getErrorPrefix(qual))
			);
		}
		if (
			String.isNotBlank(qual.verificationStatus) &&
			!acceptableVerificationStatuses.contains(qual.verificationStatus.toLowerCase())
		) {
			super.addInvalidException(
				getAPIResponseErrorMessages('VERIFICATION_STATUS_INVALID', super.qualificationValidator.getErrorPrefix(qual))
			);
		}
	}

	/**
	 * @description Validates work experiences.
	 * @param applicationWorkExperiences List of work experiences to validate.
	 */
	@testVisible
	private void validateWorkExperience() {
		if (this.application.workExperiences == null) {
			return;
		}
		for (ApplicationWSWrapper.CDM_WorkExperience workExperience : application.workExperiences) {
			super.workExperienceValidator.validateWorkExperience(workExperience);
			super.validateEmptyAttribute(workExperience.countryObtained, 'COUNTRY_EMPTY', workExperience.externalId);
			if (
				(workExperience.countryObtained != null &&
				String.isBlank(workExperience.countryObtained.uniqueCountryExternalId))
			) {
				super.addInvalidException('COUNTRY_EXTERNAL_ID_EMPTY', workExperience.position + ' ' + workExperience.employer);
			}
		}
	}

	/**
	 * @description Validates visa details in the application.
	 * @param application Application containing visa details to validate.
	 */
	@TestVisible
	private void validateVisa() {
		super.visaValidator.validateVisa(application.visa);
		// validate visa details only if the residency status requires a visa
		if (residencyStatusCheckEnforced.contains(application.residencyStatus) && application.visa == null) {
			super.addInvalidException(getAPIResponseErrorMessages('VISA_EMPTY', ''));
			return;
		}
		if (application.visa != null && String.isBlank(application.visa.citizenship?.code)) {
			super.addInvalidException(getAPIResponseErrorMessages('VISA_CITIZENSHIP_CODE_EMPTY', ''));
		}
		if (application.visa != null && String.isBlank(application.visa.citizenship?.uniqueCountryExternalId)) {
			super.addInvalidException(getAPIResponseErrorMessages('VISA_APPLICANT_CITIZENSHIP_UNIQUE_EXTID_MISSING', ''));
		}
		if (
			application.visa?.singleEntryVisaCountry != null &&
			String.isBlank(application.visa.singleEntryVisaCountry?.uniqueCountryExternalId)
		) {
			super.addInvalidException(getAPIResponseErrorMessages('SINGLE_ENTRY_VISA_COUNTRY_EMPTY', ''));
		}
		// Validate visa details only if the residency status requires a visa
		if (residencyStatusCheckEnforced.contains(application.residencyStatus)) {
			if (application.visa.type != null) {
				super.validateEmptyAttribute(
					this.application.passportNumber,
					getAPIResponseErrorMessages('PASSPORT_NUMBER_EMPTY', '')
				);
			}
			super.validateEmptyAttribute(
				application.visa.startDate,
				getAPIResponseErrorMessages('VISA_START_DATE_EMPTY', '')
			);
			super.validateEmptyAttribute(application.visa.endDate, getAPIResponseErrorMessages('VISA_END_DATE_EMPTY', ''));
			super.validateEmptyAttribute(application.visa.visaNumber, getAPIResponseErrorMessages('VISA_NUMBER_EMPTY', ''));
			super.validateEmptyAttribute(application.visa?.type, getAPIResponseErrorMessages('VISA_TYPE_EMPTY', ''));
			super.validateEmptyAttribute(application.visa.type?.code, getAPIResponseErrorMessages('VISA_CODE_EMPTY', ''));
			super.validateEmptyAttribute(
				application.visa.immigrationOfficeIssued,
				getAPIResponseErrorMessages('VISA_IMMIGRATION_OFFICE_EMPTY', '')
			);
		}
	}

	/**
	 * @description Validates application course preferences when applicationStatus=Submitted
	 * @param coursePreferences List of course preferences to validate.
	 */
	public void validateCdmAcp() {
		if (application.coursePreferences == null) {
			return;
		}
		for (OESApplicationPayload.CDM_ApplicationCoursePreference cdm : application.coursePreferences) {
			super.validateEmptyAttribute(
				cdm.courseOffering,
				getAPIResponseErrorMessages('COURSE_OFFERING_EMPTY', cdm.externalId)
			);
			super.validateEmptyAttribute(
				cdm.preference,
				getAPIResponseErrorMessages('APPLICATION_PREFERENCE_EMPTY', cdm.externalId)
			);
			super.validateEmptyAttribute(
				cdm.courseOffering?.courseOfferingUid,
				getAPIResponseErrorMessages('COURSE_OFFERING_UID_EMPTY', cdm.externalId)
			);
			// validate qualification reference id when ACP status are being update during the patch request
			if (AffiliationCheckService.SUBMITTED_STATUSES.contains(application.applicationStatus)) {
				validateEmptyAttribute(
					cdm.externalId,
					getAPIResponseErrorMessages('INVALID_ACP_EXTERNAL_ID', cdm.courseOffering.courseOfferingUid)
				);
			}
			if (
				String.isNotBlank(cdm.basisForAdmissionType) ||
				AffiliationCheckService.SUBMITTED_STATUSES.contains(application.applicationStatus)
			) {
				validateBasisForAdmissionType(cdm.basisForAdmissionType);
			}

			if (
				String.isNotBlank(cdm.documentationStatus) ||
				AffiliationCheckService.SUBMITTED_STATUSES.contains(application.applicationStatus)
			) {
				validateDocumentationStatus(cdm.documentationStatus);
			}

			if (
				String.isNotBlank(cdm.outcomeStatus) ||
				AffiliationCheckService.SUBMITTED_STATUSES.contains(application.applicationStatus)
			) {
				validateOutcomeStatus(cdm.outcomeStatus);
			}

			if (
				String.isNotBlank(cdm.entryQualificationStatus) ||
				AffiliationCheckService.SUBMITTED_STATUSES.contains(application.applicationStatus)
			) {
				validateEntryQualificationStatus(cdm.entryQualificationStatus);
			}

			if (
				String.isNotBlank(cdm.offerResponseStatus) ||
				AffiliationCheckService.SUBMITTED_STATUSES.contains(application.applicationStatus)
			) {
				validateOfferResponseStatus(cdm.offerResponseStatus);
			}
			if (AffiliationCheckService.SUBMITTED_STATUSES.contains(application.applicationStatus)) {
				super.validateEmptyAttribute(
					cdm.offerDate,
					getAPIResponseErrorMessages(
						'ACP_OFFER_DATE_EMPTY',
						String.isNotBlank(cdm.externalId) ? cdm.externalId : cdm.courseOffering.courseOfferingUid
					)
				);
				super.validateEmptyAttribute(
					cdm.actualOfferResponseDate,
					getAPIResponseErrorMessages(
						'ACP_ACTUAL_OFFER_RESPONSE_DATE_EMPTY',
						String.isNotBlank(cdm.externalId) ? cdm.externalId : cdm.courseOffering.courseOfferingUid
					)
				);
				return;
			}
			if (null != cdm.offerDate && null != cdm.actualOfferResponseDate) {
				validateOfferAndResponseDate(cdm.offerDate, cdm.actualOfferResponseDate);
			}
		}
	}

	/**
	 * @description Validates the basis for admission type.
	 * @param basisForAdmissionType Basis for admission type to validate.
	 */
	@TestVisible
	private void validateBasisForAdmissionType(String basisForAdmissionType) {
		if (
			String.isBlank(basisForAdmissionType) ||
			!ACP_VALID_BASIS_FOR_ADMISSION_TYPE.contains(basisForAdmissionType.toUpperCase())
		) {
			super.addInvalidException('Invalid Basis for Admission Type: ' + basisForAdmissionType);
		}
	}

	/**
	 * @description Validates the documentation status.
	 * @param documentationStatus Documentation status to validate.
	 */
	@TestVisible
	private void validateDocumentationStatus(String documentationStatus) {
		if (
			String.isBlank(documentationStatus) || !ACP_VALID_DOCUMENTATION_STATUS.contains(documentationStatus.toUpperCase())
		) {
			super.addInvalidException('Invalid Documentation Status: ' + documentationStatus);
		}
	}

	/**
	 * @description Validates the outcome status.
	 * @param outcomeStatus Outcome status to validate.
	 */
	@TestVisible
	private void validateOutcomeStatus(String outcomeStatus) {
		if (String.isBlank(outcomeStatus) || !ACP_VALID_OUTCOME_STATUS.contains(outcomeStatus.toUpperCase())) {
			super.addInvalidException('Invalid Outcome Status: ' + outcomeStatus);
		}
	}

	/**
	 * @description Validates offer response status.
	 * @param offerResponseStatus Offer response status to validate.
	 */
	@TestVisible
	private void validateOfferResponseStatus(String offerResponseStatus) {
		if (
			String.isBlank(offerResponseStatus) ||
			!ACP_VALID_OFFER_RESPONSE_STATUS.contains(offerResponseStatus.toUpperCase())
		) {
			super.addInvalidException('Invalid Offer Response Status: ' + offerResponseStatus);
		}
	}
	/**
	 * @description validation rules for offer date and actual offer response date
	 * @param offerDate
	 * @param actualOfferResponseDate
	 */
	@TestVisible
	private void validateOfferAndResponseDate(Date offerDate, Date actualOfferResponseDate) {
		if (actualOfferResponseDate < offerDate) {
			super.addInvalidException('Actual Offer Response Date must be greater than Offer Date');
		}
	}
	/**
	 * @description validation rules for entry qualification status
	 * @param entryQualStatus
	 */
	@TestVisible
	private void validateEntryQualificationStatus(String entryQualStatus) {
		if (String.isBlank(entryQualStatus) || !ACP_VALID_ENTRY_QUAL_STATUS.contains(entryQualStatus.toUpperCase())) {
			super.addInvalidException('Invalid Entry Qualification Status: ' + entryQualStatus);
		}
	}
}