/**
 * Virtual class for Application Web Service Validations and common validations across different application types.
 * @author Ben Greenland
 * @group Application Webservice v3
 * @since 10 SEP 2024
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public virtual class ApplicationWSValidations {
	/**
	 * The list of exceptions encountered during validation.
	 */
	public RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();
	/**
	 * qualification validator inner class.
	 */
	protected QualificationValidations qualificationValidator = new QualificationValidations(this);
	/**
	 * visa validator inner class.
	 */
	protected VisaValidations visaValidator = new VisaValidations(this);
	/**
	 * work experience validator inner class.
	 */
	protected WorkExperienceValidations workExperienceValidator = new WorkExperienceValidations(this);
	/**
	 * Set of qualification names that DO NOT requires sub scores scores for each skill. Except these all require sub scores.
	 */
	private static final Map<String, String> NON_SUB_SCORE_QUALIFICATIONS = new Map<String, String>{
		'PTOEFL0' => 'Paper based TOEFL (Test of English as a Foreign Language)',
		'MEPT0' => 'Monash English Language Placement test - MUELC only',
		'CLINGUASKL0' => 'Cambridge Linguaskill',
		'LOI0' => 'LOI (Language of Instruction)',
		'DUOLINGO0' => 'Duolingo Placement test',
        'VCE-YR120' => '25 in Units 3 & 4 VCE English or Equivalent'
	};

	/**
	 * Map of API validation response messages.
	 */
	public static final Map<String, String> API_VALIDATION_RESPONSE_MESSAGES = new Map<String, String>{
		// Qualification Messages
		'INSTITUTION_EMPTY' => 'Awarding Body/Institution is empty',
		'LEVEL_OF_COMPLETION_EMPTY' => 'Level of completion is empty',
		'QUALIFICATION_TYPE_EMPTY' => 'Qualification Type cannot be empty',
		'DATE_ACHIEVED_INVALID_FORMAT' => 'Date Achieved is of invalid format. Only yyyy-MM-dd format is accepted',
		'EXPECTED_DATE_OF_COMPLETION_INVALID_FORMAT' => 'Expected date of completion is of invalid format. Only yyyy-MM-dd format is accepted',
		'INVALID_DATE' => 'Invalid date format. Only yyyy-MM-dd format is accepted',
		'START_DATE_INVALID_FORMAT' => 'Start date is of invalid format. Only yyyy-MM-dd format is accepted',
		'QUALIFICATION_TYPE_INVALID' => 'Qualification Type invalid.',
		'QUALIFICATION_COUNTRY_EMPTY' => 'Qualification country is empty',
		'STATE_EMPTY' => 'State is empty',
		'QUALIFICATION_NAME_EMPTY' => 'Qualification Name is empty',
		'INVALID_YEAR_OF_COMPLETION' => 'Invalid Year of completion',
		'YEAR_OF_COMPLETION_EMPTY' => 'Year of completion is empty',
		'SCHOOL_INSTITUTION_EMPTY' => 'School/Institution is empty',
		'YEAR_OF_COMPLETION_FUTURE' => 'Year of completion cannot be in the future',
		'EXPECTED_COMPLETION_DATE_PAST' => 'Expected completion date is in the past',
		'INVALID_SCORE' => 'Invalid Score',
		'RESULT_TYPE_EMPTY' => 'Result Type cannot be empty',
		'RESULT_TYPE_STATUS_INVALID' => 'Result Type Status must be Satisfactory or Unsatisfactory',
		'VERIFICATION_STATUS_EMPTY' => 'Verification Status is empty',
		'VERIFICATION_STATUS_INVALID' => 'Verification Status must be Satisfactory or Unsatisfactory',
		'DATE_OBTAINED_OR_COMPLETION_MANDATORY' => 'Either Date obtained/Expected completion date to be filled',
		'LAST_YEAR_ENROLMENT_EARLIER' => 'Last year of enrolment is earlier than First year of enrolment',
		'FIRST_YEAR_ENROLMENT_EMPTY' => 'First year of enrolment is empty',
		'LAST_YEAR_ENROLMENT_EMPTY' => 'Last year of enrolment is empty',
		'INVALID_LAST_YEAR_ENROLMENT' => 'Invalid Last year of enrolment',
		'INVALID_FIRST_YEAR_ENROLMENT' => 'Invalid First year of enrolment',
		'SCORE_EMPTY' => 'Either Score is empty or invalid value',
		'SUB_SCORE_EMPTY' => 'Either Sub-Score is empty or invalid value',
		'ENGLISH_LANGUAGE_EMPTY' => 'English language of instruction is empty.',
		// WORK EXP Messages
		'WORK_EXPERIENCE_EMPTY' => 'Work Experience is empty',
		'POSITION_EMPTY' => 'Position cannot be empty',
		'EMPLOYER_EMPTY' => 'Employer cannot be empty',
		'START_DATE_EMPTY' => 'Start Date is empty',
		'START_DATE_INVALID_FORMAT' => 'Start Date is of invalid format. Only yyyy-MM-dd format is accepted',
		'END_DATE_INVALID_FORMAT' => 'End Date is of invalid format. Only yyyy-MM-dd format is accepted',
		'COUNTRY_EMPTY' => 'Work Exp Country cannot be empty',
		'COUNTRY_EXTERNAL_ID_EMPTY' => 'countryObtained.uniqueCountryExternalId cannot be empty',
		// Applicant Messages
		'INVALID_APP_APPLICANT' => 'Invalid Application or Applicant Id',
		'INVALID_APP' => 'Invalid Application Id',
		'APPLICANT_ID_EMPTY' => 'Applicant\'s ID cannot be empty',
		'INVALID_APPLICANT_ID' => 'Invalid Applicant ID or Applicant doesn’t exist!',
		'MULTIPLE_DRAFT_APPLICATIONS_FOR_CAMPUS_NOT_ALLOWED' => 'Applicant cannot have more than one draft application for this campus.',
		// Campus Location Messages
		'CAMPUS_LOCATION_EMPTY' => 'Campus Location cannot be empty',
		'AGENCY_NOT_ALLOWED' => 'Your agency is not allowed to apply for this Campus location',
		'RESIDENCY_STATUS_EMPTY' => 'Residency Status cannot be empty',
		// Email Messages
		'EMAIL_EMPTY' => 'Applicant email cannot be empty',
		'EMAIL_REQUIRED' => 'At least one email address is required',
		'EMAIL_TYPE_REQUIRED' => 'Email type is required',
		'PERSONAL_EMAIL_REQUIRED' => 'At least one personal email address is required',
		'PERSONAL_EMAIL_EMPTY' => 'Personal email address cannot be empty',
		'INVALID_EMAIL_FORMAT' => 'Invalid email format',
		'MONASH_EMAIL_NOT_ALLOWED' => 'Monash email addresses are not allowed',
		// Phone Messages
		'MOBILE_PHONE_EMPTY' => 'Applicant mobilePhone cannot be empty	',
		'PHONE_NUMBER_EMPTY' => 'Applicant Phone Number is empty',
		'PHONE_TYPE_REQUIRED' => 'Applicant Phone type must be Mobile or Personal',
		'PHONE_EMPTY' => 'Applicant Phone cannot be empty',
		// Visa Messages
		'VISA_START_DATE_INVALID' => 'Visa Start Date is of invalid format. Only yyyy-MM-dd format is accepted',
		'VISA_END_DATE_INVALID' => 'Visa End Date is of invalid format. Only yyyy-MM-dd format is accepted',
		'VISA_APPLICANT_CITIZENSHIP_UNIQUE_EXTID_MISSING' => 'Applicant\'s Visa citizenship field is blank',
		// 'VISA_CITIZENSHIP_COUNTRY_EMPTY' => 'Visa citizenship country is required.',
		// 'VISA_CITIZENSHIP_CODE_EMPTY' => 'Visa citizenship code is required.',
		'SINGLE_ENTRY_VISA_COUNTRY_EMPTY' => 'Applicant\'s Visa singleEntryVisaCountry field is Blank',
		'EXPECTED_COMPLETION_DATE_MISSING' => 'Either Year of completion/Expected completion date to be filled',
		'VERIFICATION_STATUS_CANNOT EMPTY' => 'verification Status cannot be empty',
		'INVALID_PAYMENT_AMOUNT' => 'Fee Amount is of invalid format. Only Decimal values are accepted',
		'INVALID_PAID_DATE' => 'Date Paid (Transaction Date) is of invalid format. Only yyyy-MM-dd format is accepted'
	};
	/**
	 * Validates the given request object.
	 *
	 * @param reqObj The request object to be validated.
	 * @return A list of exceptions if validation fails, otherwise an empty list.
	 */
	public virtual RESTlib_Ex.InvalidRequestException validate(RESTlib_Payload.Request reqObj) {
		return null; // Should be overridden in subclasses
	}
	/**
	 *
	 * @param reqObj The request object to be validated.
	 * @return       `Boolean`
	 */
	@testVisible
	protected virtual Boolean isValidRequestType(RESTlib_Payload.Request reqObj) {
		return false; // Should be overridden in subclasses
	}

	@testVisible
	protected virtual String getContactId(RESTlib_Payload.Request reqObj) {
		return null; // Should be overridden in subclasses
	}

	@testVisible
	protected virtual String getCampusLocation(RESTlib_Payload.Request reqObj) {
		return null; // Should be overridden in subclasses
	}

	@testVisible
	protected virtual String getResidencyStatus(RESTlib_Payload.Request reqObj) {
		return null; // Should be overridden in subclasses
	}

	@testVisible
	protected virtual List<CommonWSPayload.Email> getEmail(RESTlib_Payload.Request reqObj) {
		return null; // Should be overridden in subclasses
	}

	@testVisible
	protected virtual List<CommonWSPayload.Phone> getPhone(RESTlib_Payload.Request reqObj) {
		return null; // Should be overridden in subclasses
	}

	@testVisible /**
	 * Validates on the given contact ID and adds any
	 * validation errors to the provided exceptions list.
	 *
	 * @param contactId The ID of the contact to be validated.
	 * @param exceptions A list to collect any validation exceptions encountered.
	 *
	 */
	protected virtual void validateContactId(String contactSFIdOrCRMId) {
		if (String.isBlank(contactSFIdOrCRMId)) {
			addInvalidException('INVALID_APPLICANT_ID', '');
		}
	}
	/**
	 *  Validates the given campus location and adds any validation errors to the provided exceptions list.
	 *
	 * @param campusLocation     The campus location to be validated.
	 * @param contactSFIdOrCRMId
	 */
	@testVisible
	protected virtual void validateCampusLocation(String campusLocation, String contactSFIdOrCRMId) {
		Nebula.Logger.debug('Super call: Application.validateCampusLocation() Running user' + CommonWSPayload.runningUser);
		if (String.isEmpty(campusLocation) || CommonWSPayload.runningUser.contact == null) {
			addInvalidException('CAMPUS_LOCATION_EMPTY', '');
			return;
		}
		if (!CommonWSPayload.runningUser.contact?.Account.Campus__c.containsIgnoreCase(campusLocation)) {
			addInvalidException('AGENCY_NOT_ALLOWED', '');
			return;
		}
		if (
			ApplicationWSService.doOtherDraftsExistForSameCampus(
				contactSFIdOrCRMId,
				campusLocation,
				new Set<String>{ CommonWSPayload.runningUser.contact.Account.Callista_Org_Unit_Code__c }
			)
		) {
			addInvalidException('MULTIPLE_DRAFT_APPLICATIONS_FOR_CAMPUS_NOT_ALLOWED', '');
		}
	}
	/**
	 * Validates the given residency status and adds any validation errors to the provided exceptions list.
	 *
	 * @param residencyStatus The residency status to be validated.
	 */
	@testVisible
	protected virtual void validateResidencyStatus(String residencyStatus) {
		validateEmptyAttribute(residencyStatus, 'RESIDENCY_STATUS_EMPTY');
	}
	/**
	 * Validates the given emails and adds any validation errors to the provided exceptions list.
	 *
	 * @param emails The list of emails to be validated.
	 */
	@testVisible
	protected virtual void validateEmail(List<CommonWSPayload.Email> emails) {
		if (emails == null || String.isBlank(CommonWSPayload.getEmail(emails, 'Personal'))) {
			addInvalidException('EMAIL_EMPTY', '');
		}
	}
	/**
	 * Validates the given emails and adds any validation errors to the provided exceptions list.
	 *
	 * @param emails The list of emails to be validated.
	 */
	@testVisible
	protected virtual void validateEmails(List<CommonWSPayload.Email> emails) {
		Boolean hasPersonalEmail = false;
		if (emails == null || emails.isEmpty()) {
			addInvalidException('EMAIL_REQUIRED', '');
			return;
		}

		for (CommonWSPayload.Email email : emails) {
			if (String.isBlank(email.type)) {
				addInvalidException('EMAIL_TYPE_REQUIRED', '');
				continue;
			}

			if (email.type.equalsIgnoreCase('Personal')) {
				hasPersonalEmail = true;
				validatePersonalEmail(email.email);
			}
		}
		if (!hasPersonalEmail) {
			addInvalidException('PERSONAL_EMAIL_REQUIRED', '');
		}
	}
	/**
	 *
	 * Validates the given personal email address.
	 * @param emailAddress The email address to be validated.
	 */
	@testVisible
	private void validatePersonalEmail(String emailAddress) {
		if (String.isBlank(emailAddress)) {
			addInvalidException('PERSONAL_EMAIL_EMPTY', '');
			return;
		}
		if (!Pattern.matches('^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', emailAddress)) {
			addInvalidException('INVALID_EMAIL_FORMAT', '');
		}
		if (
			emailAddress.toLowerCase().endsWith('@monash.edu') || emailAddress.toLowerCase().endsWith('@student.monash.edu')
		) {
			addInvalidException('MONASH_EMAIL_NOT_ALLOWED', '');
		}
	}

	@testVisible
	protected virtual void validatePhone(List<CommonWSPayload.Phone> phones) {
		if (phones == null || String.isBlank(CommonWSPayload.getPhoneNumber(phones, 'Mobile'))) {
			addInvalidException('MOBILE_PHONE_EMPTY', '');
		}
		if (phones == null || phones.isEmpty()) {
			validateEmptyPhones(phones);
			return;
		}

		for (CommonWSPayload.Phone phone : phones) {
			if (!(phone.type.toLowerCase() == 'personal' || phone.type.toLowerCase() == 'mobile')) {
				addInvalidException('PHONE_TYPE_REQUIRED', '');
			}
			if (String.isEmpty(phone?.phoneNumber)) {
				addInvalidException('PHONE_NUMBER_EMPTY', '');
			}
		}
	}
	private void validateEmptyPhones(List<CommonWSPayload.Phone> phones) {
		if (
			phones == null ||
			(String.isBlank(CommonWSPayload.getPhoneNumber(phones, 'Mobile')) &&
			String.isBlank(CommonWSPayload.getPhoneNumber(phones, 'Personal')))
		) {
			addInvalidException('PHONE_EMPTY', '');
		}
	}

	/**
	 * Validates the given date of birth.
	 *
	 * @param dob The date of birth to be validated.
	 * @return `Boolean`
	 */
	@testVisible
	private boolean validateYear(String year) {
		try {
			if (!year.isNumeric()) {
				return false;
			}
			Integer i = Integer.valueOf(year);
			if (i < 1900 || i > 2099) {
				return false;
			}
		} catch (Exception e) {
			return false;
		}
		return true;
	}
	/**
	 * Validates if blank.
	 *
	 * @param dob String of birth to be validated.
	 * @return `Boolean`
	 */
	protected Boolean isBlank(String value) {
		return String.isBlank(value);
	}
	/**
	 * Validates if blank.
	 *
	 * @param Object to be validated.
	 * @return `Boolean`
	 */
	protected Boolean isBlank(Object value) {
		return value == null;
	} /**
	 * Checks if the given string is a valid decimal number.
	 *
	 * @param str The string to check.
	 * @return Boolean indicating whether the string is a valid decimal number.
	 */
	public Boolean isValidDecimal(String str) {
		if (String.isBlank(str)) {
			return false;
		}
		try {
			Decimal.valueOf(str);
			return true;
		} catch (Exception e) {
			return false;
		}
	}

	/**
	 *
	 *
	 * @param applicationName The application name to be validated.
	 */
	protected void isValidApplication(String applicationName) {
		if (String.isBlank(applicationName) || ApplicationWSService.getApplicationByName(applicationName).isEmpty()) {
			addInvalidException(API_VALIDATION_RESPONSE_MESSAGES.get('INVALID_APP'));
		}
	}
	/**
	 *
	 *
	 * @param payloadAttribute The attribute to be validated.
	 * @param errorMessage 	The error message to be added to the exceptions list.
	 */
	protected void validateEmptyAttribute(Object payloadAttribute, String errorMessage) {
		if (isBlank(payloadAttribute)) {
			addInvalidException(errorMessage);
		}
	}
	/**
	 *
	 *
	 * @param payloadAttribute The attribute to be validated.
	 * @param messageKey 		The message key to be used to get the error message.
	 * @param errorAttribute 	The attribute to be added to the error message.
	 */
	protected void validateEmptyAttribute(String payloadAttribute, String errorMessage) {
		if (String.isBlank(payloadAttribute)) {
			addInvalidException(errorMessage);
		}
	}
	/**
	 * @param payloadAttribute String attribute to be validated.
	 * @param messageKey 		The message key to be used to get the error message.
	 * @param errorAttribute 	The attribute to be added to the error message.
	 */
	public void validateEmptyAttribute(String payloadAttribute, String messageKey, String errorAttribute) {
		if (isBlank(payloadAttribute)) {
			addInvalidException(messageKey, errorAttribute);
		}
	}
	/**
	 * @param payloadAttribute Object The attribute to be validated.
	 * @param messageKey
	 * @param errorAttribute
	 */
	public void validateEmptyAttribute(Object payloadAttribute, String messageKey, String errorAttribute) {
		if (isBlank(payloadAttribute)) {
			addInvalidException(messageKey, errorAttribute);
		}
	}
	/**
	 * Adds an invalid exception to the exceptions list.
	 *
	 * @param errorMessage The error message to be added to the exceptions list.
	 */
	public void addInvalidException(String errorMessage) {
		exceptions.addException(new RESTlib_Ex.InvalidRequestException(errorMessage));
	}
	/**
	 * Adds an invalid exception to the exceptions list.
	 *
	 * @param key           The key to be used to get the error message.
	 * @param errorAttribute The attribute to be added to the error message.
	 */
	public void addInvalidException(String key, String errorAttribute) {
		exceptions.addException(new RESTlib_Ex.InvalidRequestException(getAPIResponseMessages(key, errorAttribute)));
	}

	/**
	 * @param dateStr The date string to be validated.
	 * @return        `Boolean`
	 */
	public Boolean isValidDate(String dateStr) {
		try {
			return String.isNotBlank(dateStr) && String.isNotBlank(String.valueOf(Date.valueOf(dateStr))) ? true : false;
		} catch (Exception e) {
			return false;
		}
	}
	/**
	 * Validates the date format of the given date string.
	 *
	 * @param dateStr
	 * @param errorMessage
	 */
	public void validateDateFormat(String dateStr, String errorMessage) {
		if (!isValidDate(dateStr)) {
			exceptions.addException(new RESTlib_Ex.InvalidRequestException(errorMessage));
		}
	}
	public String getErrorPrefix(String name) {
		return name + ' : ';
	}
	/**
	 * Returns the error message for the given key. If the attribute is not blank, it is added to the error message.
	 *
	 * @param key       The key to be used to get the error message from the map API_VALIDATION_RESPONSE_MESSAGES.
	 * @param attribute The attribute to be added to the error message.
	 * @return          `String`
	 */
	public String getAPIResponseMessages(String key, String attribute) {
		return String.isBlank(attribute)
			? API_VALIDATION_RESPONSE_MESSAGES.get(key)
			: attribute + ':' + API_VALIDATION_RESPONSE_MESSAGES.get(key);
	}
	/**
	 * Validates the qualification details of an application.
	 *
	 * This class checks the provided qualification details to ensure they meet
	 * the required criteria for the application process.
	 *
	 * @throws SomeExceptionType if the qualification details are invalid
	 */
	public class QualificationValidations {
		private ApplicationWSValidations parent;
		public QualificationValidations(ApplicationWSValidations parent) {
			this.parent = parent;
			// this.exceptions = new RESTlib_Ex.ListException();
		}
		/**
		 * Validates the qualification details of an application.
		 *
		 * This method checks the provided qualification details to ensure they meet
		 * the required criteria for the application process.
		 *
		 * @throws SomeExceptionType if the qualification details are invalid
		 */
		public void validateQualification(List<ApplicationWSWrapper.CDM_Qualification> submittedQualifications) {
			for (ApplicationWSWrapper.CDM_Qualification qual : submittedQualifications) {
				Nebula.Logger.info('ApplicationWSValidation validateQualification() check' + qual);
				// IF type is null, then all other attributes are invalid, no need to validate
				if (parent.isBlank(qual.type)) {
					parent.getAPIResponseMessages('QUALIFICATION_TYPE_EMPTY', '');
					continue;
				}
				if (
					String.isBlank(qual.type.name) ||
					(String.isNotBlank(qual.type.name) &&
					String.isBlank(
						Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName()
							.get(qual.type.name)
							?.getRecordTypeId()
					))
				) {
					parent.addInvalidException('QUALIFICATION_TYPE_INVALID', getErrorPrefix(qual));
				}
				if (qual.conferredDate != null) {
					parent.validateDateFormat(
						qual.conferredDate,
						parent.getAPIResponseMessages('DATE_ACHIEVED_INVALID_FORMAT', getErrorPrefix(qual))
					);
				}
				// // Tertiary Qualification does not have expectedDateOfCompletion
				if (qual.expectedDateOfCompletion != null) {
					parent.validateDateFormat(
						qual.expectedDateOfCompletion,
						parent.getAPIResponseMessages('EXPECTED_DATE_OF_COMPLETION_INVALID_FORMAT', getErrorPrefix(qual))
					);
				}
			}
		}
		/**
		 * Validates the secondary qualification details of an application.
		 *
		 * This method checks the provided secondary qualification details to ensure they meet
		 * the required criteria for the application process.
		 *
		 * @param qual The qualification to be validated.
		 */
		public void validateSecondaryQualification(ApplicationWSWrapper.CDM_Qualification qual) {
			if (
				parent.isBlank(qual.institution) ||
				(String.isBlank(qual.institution?.value) &&
				(String.isBlank(qual.institution?.institutionCode) && String.isBlank(qual.institution?.code)))
			) {
				parent.addInvalidException('SCHOOL_INSTITUTION_EMPTY', getErrorPrefix(qual));
			}
			if (String.isBlank(qual.endDate) && String.isBlank(qual.expectedDateOfCompletion)) {
				parent.addInvalidException('EXPECTED_COMPLETION_DATE_MISSING', getErrorPrefix(qual));
			} else {
				if (String.isNotBlank(qual.endDate) && !parent.validateYear(qual.endDate)) {
					parent.addInvalidException('INVALID_YEAR_OF_COMPLETION', getErrorPrefix(qual));
				} else {
					if (String.isNotBlank(qual.endDate) && Integer.valueOf(qual.endDate) > Date.today().year()) {
						parent.addInvalidException('YEAR_OF_COMPLETION_FUTURE', getErrorPrefix(qual));
					}
				}
				if (
					String.isNotBlank(qual.expectedDateOfCompletion) &&
					parent.isValidDate(qual.expectedDateOfCompletion) &&
					Date.valueOf(qual.expectedDateOfCompletion) < Date.today()
				) {
					parent.addInvalidException('EXPECTED_COMPLETION_DATE_PAST', getErrorPrefix(qual));
				}
			}
		}
		/**
		 * Validates the tertiary qualification details of an application.
		 *
		 * This method checks the provided tertiary qualification details to ensure they meet
		 * the required criteria for the application process.
		 *
		 * @throws SomeExceptionType if the tertiary qualification details are invalid
		 */
		public void validateTertiaryQualification(ApplicationWSWrapper.CDM_Qualification qual) {
			if (
				parent.isBlank(qual.institution) ||
				(String.isBlank(qual.institution?.value) &&
				(String.isBlank(qual.institution?.institutionCode) && String.isBlank(qual.institution?.code)))
			) {
				parent.addInvalidException('INSTITUTION_EMPTY', getErrorPrefix(qual));
			}
			parent.validateEmptyAttribute(qual.status, 'LEVEL_OF_COMPLETION_EMPTY', getErrorPrefix(qual));
			parent.validateEmptyAttribute(qual.startDate, 'FIRST_YEAR_ENROLMENT_EMPTY', getErrorPrefix(qual));
			parent.validateEmptyAttribute(qual.endDate, 'LAST_YEAR_ENROLMENT_EMPTY', getErrorPrefix(qual));

			if (string.isNotBlank(qual.startDate) && !parent.validateYear(qual.startDate)) {
				parent.addInvalidException('INVALID_FIRST_YEAR_ENROLMENT', getErrorPrefix(qual));
			}
			if (String.isNotBlank(qual.endDate) && !parent.validateYear(qual.endDate)) {
				parent.addInvalidException('INVALID_LAST_YEAR_ENROLMENT', getErrorPrefix(qual));
			}
			if (
				String.isNotBlank(qual.startDate) &&
				String.isNotBlank(qual.endDate) &&
				parent.validateYear(qual.endDate) &&
				parent.validateYear(qual.startDate) &&
				Integer.valueOf(qual.endDate) < Integer.valueOf(qual.startDate)
			) {
				parent.addInvalidException('LAST_YEAR_ENROLMENT_EARLIER', getErrorPrefix(qual));
			}
		}
		/**
		 * validateEnglishTest
		 *
		 * @param qual       The qualification to be validated.
		 * @param exceptions
		 */
		public void validateEnglishTest(ApplicationWSWrapper.CDM_Qualification qual) {
		
			// below are UUIDs equivalent to qualificationNames. OES expects UUIDs
			if (
				(String.isNotBlank(qual.conferredDate)) &&
				(String.isNotBlank(qual.type.qualificationName) || String.isNotBlank(qual.type.qualificationUid))
			) {
				if (
					(NON_SUB_SCORE_QUALIFICATIONS.values().contains(qual.type.qualificationName) ||
					NON_SUB_SCORE_QUALIFICATIONS.keySet().contains(qual.type.qualificationUid)) &&
					(String.isBlank(qual.score) || !parent.isValidDecimal(qual.score))
				) {
					parent.addInvalidException('SCORE_EMPTY', getErrorPrefix(qual));
				} else if (
					(!NON_SUB_SCORE_QUALIFICATIONS.values().contains(qual.type.qualificationName) &&
					!NON_SUB_SCORE_QUALIFICATIONS.keySet().contains(qual.type.qualificationUid))
				) {
					validateScores(qual);
				}
			}
			if (String.isBlank(qual.expectedDateOfCompletion) && String.isBlank(qual.conferredDate)) {
				parent.addInvalidException('DATE_OBTAINED_OR_COMPLETION_MANDATORY', getErrorPrefix(qual));
			} else {
				if (
					parent.isValidDate(qual.expectedDateOfCompletion) &&
					Date.valueOf(qual.expectedDateOfCompletion) < Date.today()
				) {
					parent.addInvalidException('EXPECTED_COMPLETION_DATE_PAST', getErrorPrefix(qual));
				}
			}
		}
		/**
		 * validateOtherQualification
		 *
		 * @param qual       The qualification to be validated.
		 * @param exceptions
		 */
		public void validateOtherQualification(ApplicationWSWrapper.CDM_Qualification qual) {
			if (String.isBlank(qual.expectedDateOfCompletion) && String.isBlank(qual.conferredDate)) {
				parent.addInvalidException('DATE_OBTAINED_OR_COMPLETION_MANDATORY', getErrorPrefix(qual));
			}
			parent.validateEmptyAttribute(qual.type.qualificationName, 'QUALIFICATION_NAME_EMPTY', getErrorPrefix(qual));
			if (
				String.isNotBlank(qual.expectedDateOfCompletion) &&
				parent.isValidDate(qual.expectedDateOfCompletion) &&
				Date.valueOf(qual.expectedDateOfCompletion) < Date.today()
			) {
				parent.addInvalidException('EXPECTED_COMPLETION_DATE_PAST', getErrorPrefix(qual));
			}
		}

		/**
		 * @description getScore
		 * @param scores
		 * @param  type
		 * @return String
		 **/
		public void validateScores(ApplicationWSWrapper.CDM_Qualification qual) {
			// Define the required scores
			Set<String> requiredScores = new Set<String>{ 'listening', 'reading', 'writing', 'speaking' };
			Map<String, String> scoreMap = new Map<String, String>();
			List<ApplicationWSWrapper.CDM_QualificationScore> scores = qual.scores;
			if (qual.scores == null || qual.scores.isEmpty()) {
				parent.addInvalidException('SUB_SCORE_EMPTY', qual.type.qualificationUId);
				return;
			}
			// Populate the scoreMap with the provided scores
			for (ApplicationWSWrapper.CDM_QualificationScore score : scores) {
				scoreMap.put(score.name.toLowerCase(), score.value);
			}

			// Check for missing or invalid scores
			for (String requiredScore : requiredScores) {
				if (!scoreMap.containsKey(requiredScore) && OESApplicationService.isOESUser) {
					parent.addInvalidException(getErrorPrefix(qual) + ':' + requiredScore.capitalize() + ' score is missing');
				} else {
					String scoreValue = scoreMap.get(requiredScore);
					if (String.isBlank(scoreValue) && OESApplicationService.isOESUser) {
						parent.addInvalidException(getErrorPrefix(qual) + ':' + requiredScore.capitalize() + ' score is empty');
					} else {
						try {
							Decimal d = Decimal.valueOf(scoreValue);
							if (d < 0.0 || d >= 1000.0) {
								// SFTG-3688 Allow english scores between 0 & 1000 only
								parent.addInvalidException(
									getErrorPrefix(qual) + ':' + 'Invalid ' + requiredScore + ' score: ' + scoreValue
								);
							}
						} catch (Exception e) {
							// Handle invalid decimal format
							parent.addInvalidException(
								getErrorPrefix(qual) + ':' + 'Invalid ' + requiredScore + ' score format: ' + scoreValue
							);
						}
					}
				}
			}
		}
		/**
		 *
		 * Get Error prefix using the qualification payload and sned menainful message to idenify erroring out payload object
		 * @param qual
		 * @return     `string`
		 */
		public string getErrorPrefix(ApplicationWSWrapper.CDM_Qualification qual) {
			String qualificationIdentifierPrefix = String.isNotBlank(qual.type.qualificationName)
				? qual.type.name + ':' + qual.type.qualificationName
				: qual.type.name;
			return String.isNotBlank(qual.uniqueExternalId)
				? qual.uniqueExternalId + ':' + qualificationIdentifierPrefix
				: qualificationIdentifierPrefix;
		}
	}

	/**
	 * validate the workexperience payload
	 */
	public class WorkExperienceValidations { //NOPMD
		private ApplicationWSValidations parent;
		WorkExperienceValidations(ApplicationWSValidations parent) {
			this.parent = parent;
		}
		public void validateWorkExperience(List<ApplicationWSWrapper.CDM_WorkExperience> workExperiences) {
			for (ApplicationWSWrapper.CDM_WorkExperience workExp : workExperiences) {
				this.validateWorkExperience(workExp);
			}
		}
		/**
		 * Validates the experience of an application.
		 *
		 * This method performs necessary checks to ensure that the experience
		 * provided in the application meets the required criteria.
		 *
		 * @throws SomeExceptionType if the experience validation fails
		 */
		public void validateWorkExperience(ApplicationWSWrapper.CDM_WorkExperience workExperience) {
			if (workExperience == null) {
				parent.validateEmptyAttribute(workExperience, 'WORK_EXPERIENCE_EMPTY', workExperience.position);
				return;
			}
			parent.validateEmptyAttribute(workExperience.position, 'POSITION_EMPTY', workExperience.employer);
			parent.validateEmptyAttribute(workExperience.employer, 'EMPLOYER_EMPTY', workExperience.externalId);
			this.validateEndDates(workExperience);
			if (String.isNotBlank(workExperience.endDate) && !parent.isValidDate(workExperience.endDate)) {
				parent.addInvalidException('END_DATE_INVALID_FORMAT', workExperience.position + ' ' + workExperience.employer);
			}

			if (!OESApplicationService.isOESUser) {
				parent.validateEmptyAttribute(
					workExperience.countryObtained,
					'COUNTRY_EMPTY',
					workExperience.position + ' ' + workExperience.employer
				);
			}
		}
		/**
		 * Validates the end dates of the given work experience.
		 *
		 * @param workExperience The work experience to be validated.
		 */
		private void validateEndDates(ApplicationWSWrapper.CDM_WorkExperience workExperience) {
			if (String.isBlank(workExperience.startDate)) {
				parent.addInvalidException('START_DATE_EMPTY', workExperience.position + ' ' + workExperience.employer);
			} else {
				if (!parent.isValidDate(workExperience.startDate)) {
					parent.addInvalidException(
						'START_DATE_INVALID_FORMAT',
						workExperience.position + ' ' + workExperience.employer
					);
				}
			}
		}
	}
	/**
	 * @description VisaValidations
	 * validateVisa
	 */
	public class VisaValidations {
		private ApplicationWSValidations parent;
		public VisaValidations(ApplicationWSValidations parent) {
			this.parent = parent;
		}
		public void validateVisa(ApplicationWSWrapper.CDM_Visa visa) {
			if (visa != null && String.isNotBlank(visa.startDate) && !parent.isValidDate(visa.startDate)) {
				parent.addInvalidException('VISA_START_DATE_INVALID', '');
			}
			if (visa != null && String.isNotBlank(visa.endDate) && !parent.isValidDate(visa.endDate)) {
				parent.addInvalidException('VISA_END_DATE_INVALID', '');
			}
		}
	}
	/**
	 *
	 * @param payment The payment to be validated.
	 */
	public void validatePayment(ApplicationWSWrapper.CDM_Payment payment) {
		if (!isBlank(payment.datePaid)) {
			validateDateFormat(payment.datePaid, getAPIResponseMessages('INVALID_PAID_DATE', payment.mode));
		}
		try {
			if (payment.amount != null) {
				Decimal amount = Decimal.valueOf(payment.amount);
			}
		} catch (Exception e) {
			addInvalidException('INVALID_PAYMENT_AMOUNT', payment.mode);
		}
	}
}