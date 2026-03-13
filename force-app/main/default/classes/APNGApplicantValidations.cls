/**
 * @description       :
 * @author            : Ben Greenland
 * @group             : admissions
 * @last modified on  : 2024-12-13
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-21   Ben Greenland   Initial Version
 **/
public class APNGApplicantValidations extends ApplicantWSValidations {
	private static final String LOGGER_TAG = 'APNG.Applicant.Validations';

	/**
	 * @description Validates the post request.
	 * @param requestObj The request object to validate.
	 * @param exceptions The exception object to add validation errors to.
	 */
	public override void validateRequest(
		RESTlib_Payload.Request requestObj,
		RESTlib_Ex.InvalidRequestException exceptions
	) {
		Nebula.Logger.info('Starting APNG applicant validation').addTag(LOGGER_TAG);

		APNGApplicantPayload.PostRequest req = (APNGApplicantPayload.PostRequest) requestObj;
		validateLastName(req.applicant.lastName, exceptions);
		validateEmails(req.applicant.email, exceptions);
		validateDateOfBirth(req.applicant.dateOfBirth, exceptions);

		if (exceptions.getExceptions() != null) {
			Nebula.Logger.error('APNG validation failed: \n' + JSON.serializePretty(exceptions.getExceptions()))
				.addTag(LOGGER_TAG);
		}
	}

	/**
	 * @description Validates the patch request.
	 * @param requestObj The request object to validate.
	 * @param exceptions The exception object to add validation errors to.
	 */
	public override void validatePatchRequest(
		RESTlib_Payload.Request requestObj,
		RESTlib_Ex.InvalidRequestException exceptions
	) {
		APNGApplicantPayload.PatchRequest req = (APNGApplicantPayload.PatchRequest) requestObj;

		Nebula.Logger.info('Starting APNG PATCH validation for contactId: ' + req.contactId).addTag(LOGGER_TAG);

		if (req.contactId == null) {
			Nebula.Logger.error('PATCH validation failed: Missing contactId').addTag(LOGGER_TAG);
			exceptions.addException(new RESTlib_Ex.InvalidRequestException('Request without a valid Id'));
		} else {
			validateSubmittedApplications(req.contactId, req, exceptions);
		}
	}

	@TestVisible /**
	 * @description Validates if the non-pronoun fields are updated.
	 * @param requestObj The request object to validate.
	 * @return Boolean indicating if the non-pronoun fields are updated.
	 */
	protected override Boolean isNonPronounFieldUpdated(Object req) {
		APNGApplicantPayload.PatchRequest apngReq = (APNGApplicantPayload.PatchRequest) req;
		Boolean isUpdated =
			apngReq.aboriginalOrTorresStraitIslander != null ||
			apngReq.lastName != null ||
			apngReq.address != null ||
			apngReq.hasMononymousName != null ||
			apngReq.gender != null ||
			apngReq.previousName != null ||
			apngReq.dateOfBirth != null ||
			apngReq.title != null ||
			apngReq.previousMonashId != null ||
			apngReq.firstName != null ||
			apngReq.phone != null ||
			apngReq.countryOfBirth != null ||
			apngReq.preferredName != null ||
			apngReq.isPreviousMonashStudent != null ||
			(apngReq.Email != null && !apngReq.Email.isEmpty()) ||
			(apngReq.phone != null && !apngReq.phone.isEmpty()) ||
			apngReq.countryOfResidence != null ||
			apngReq.isDeceased != null ||
			apngReq.broadAreaOfInterest != null ||
			apngReq.highestEducationLevel != null ||
			apngReq.specificAreaOfInterest != null;

		Nebula.Logger.info('Non-pronoun fields updated: ' + isUpdated).addTag(LOGGER_TAG);
		return isUpdated;
	}

	/**
	 * @description Validates the submitted applications for the patch request
	 * @param contactId The contact ID
	 * @param req The request object
	 * @param exceptions The exceptions object
	 */
	@TestVisible
	private void validateSubmittedApplications(
		String contactId,
		APNGApplicantPayload.PatchRequest req,
		RESTlib_Ex.InvalidRequestException exceptions
	) {
		List<Application__c> allApplicationsForContact = AgentPortalServices.getSubmittedApplicationsForApplicant(
			contactId,
			new Set<Id>()
		);

		if (!allApplicationsForContact.isEmpty() && isNonPronounFieldUpdated(req)) {
			Nebula.Logger.error('Cannot update non-pronoun fields for applicant with submitted applications')
				.addTag(LOGGER_TAG);
			exceptions.addException(
				new RESTlib_Ex.InvalidRequestException(
					'Applicant has submitted Applications. Request contains fields which cannot be updated'
				)
			);
		} else if (allApplicationsForContact.isEmpty()) {
			validateCommonPatchFields(req, exceptions);
			checkCountryOfBirthExists(req.countryOfBirth, exceptions);
		}
	}

	@TestVisible
	private void validateCommonPatchFields(
		APNGApplicantPayload.PatchRequest req,
		RESTlib_Ex.InvalidRequestException exceptions
	) {
		if (req.lastName != null && String.isEmpty(req.lastName)) {
			Nebula.Logger.error('Last name validation failed: Last name cannot be empty').addTag(LOGGER_TAG);
			exceptions.addException(new RESTlib_Ex.InvalidRequestException('Applicant\'s Last Name cannot be empty'));
		}
		if (req.Email != null && String.isEmpty(CommonWSPayload.getEmail(req.Email, 'Personal'))) {
			Nebula.Logger.error('Email validation failed: Email cannot be empty').addTag(LOGGER_TAG);
			exceptions.addException(new RESTlib_Ex.InvalidRequestException('Applicant\'s email cannot be empty'));
		}
		validateGender(req.gender, exceptions);
		if (req.dateOfBirth != null) {
			validateDateOfBirth(String.valueOf(req.dateOfBirth), exceptions);
		}
	}

	/**
	 * @description Checks if the country of birth exists
	 * @param country The country to check
	 * @param exceptions The exceptions object
	 */
	@testVisible
	private void checkCountryOfBirthExists(
		CommonWSPayload.Country country,
		RESTlib_Ex.InvalidRequestException exceptions
	) {
		if (country != null && String.isBlank(country.crmRecordId)) {
			Nebula.Logger.error('Country validation failed: Country of birth is required').addTag(LOGGER_TAG);
			exceptions.addException(new RESTlib_Ex.InvalidRequestException('Country of birth is required'));
			return;
		}
		if (country?.crmRecordId != null) {
			List<Country_Attribute__c> countryAttributes = [
				SELECT Id
				FROM Country_Attribute__c
				WHERE Id = :country.crmRecordId
				LIMIT 1
			];
			if (countryAttributes.isEmpty()) {
				Nebula.Logger.error('Country validation failed: Country of birth does not exist').addTag(LOGGER_TAG);
				exceptions.addException(new RESTlib_Ex.InvalidRequestException('Country of birth does not exist'));
			}
		}
	}
}