/**
 * @description       : Validations for the OES Applicant
 * @author            : Ben Greenland
 * @group             : admissions
 * @last modified on  : 2024-11-26
 * @last modified by  : Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-21   Ben Greenland   Initial Version
 **/
public class OESApplicantValidations extends ApplicantWSValidations {
  /**
   * @description Validates the post request for the applicant
   * @param requestObj The request object
   * @param exceptions The exceptions object
   */
  public override void validateRequest(
    RESTlib_Payload.Request requestObj,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    OESApplicantPayload.PostRequest req = (OESApplicantPayload.PostRequest) requestObj;
    validateLastName(req.applicant.lastName, exceptions);
    validateEmails(req.applicant.email, exceptions);
    validatePhone(req.applicant.phone, exceptions);
    validateDateOfBirth(req.applicant.dateOfBirth, exceptions);
    validatePreviousMonashDetails(
      req.applicant.isPreviousMonashStudent,
      req.applicant.previousMonashId,
      exceptions
    );
  }
  /**
   * @description Validates the patch request for the applicant
   * @param requestObj The request object
   * @param exceptions The exceptions object
   */
  public override void validatePatchRequest(
    RESTlib_Payload.Request requestObj,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    OESApplicantPayload.PatchRequest req = (OESApplicantPayload.PatchRequest) requestObj;
    if (String.isBlank(req.externalId)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException('Request without a valid externalId')
      );
    } else {
      //Commenting submitted applciation validation to allow OES to update contacts on 2nd application
      //NOTE:CRM will accept Contact updates, to get it updated in CRM, student has to contact Monash Connect
      //validateSubmittedApplications(req.externalId, req, exceptions);
      validateCommonPatchFields(req, exceptions);
      validateLastName(req.lastName, exceptions);
      validateEmails(req.email, exceptions);
      validatePhone(req.phone, exceptions);
      validateDateOfBirth(String.valueOf(req.dateOfBirth), exceptions);
      validateGender(req.gender, exceptions);
      validateAddresses(req.address, exceptions);
      validatePreviousMonashDetails(
        req.isPreviousMonashStudent,
        req.previousMonashId,
        exceptions
      );
      validateAddresses(req.address, exceptions);
      checkCountryOfBirthExists(req.countryOfBirth, exceptions);
    }
  }
  /**
   * @description Validates the non-pronoun fields for the patch request
   * @param req The request object
   * @return Boolean
   */
  @testVisible
  protected override Boolean isNonPronounFieldUpdated(Object req) {
    OESApplicantPayload.PatchRequest oesReq = (OESApplicantPayload.PatchRequest) req;
    return oesReq.aboriginalOrTorresStraitIslander != null ||
      oesReq.lastName != null ||
      oesReq.address != null ||
      oesReq.hasMononymousName != null ||
      oesReq.gender != null ||
      oesReq.contactId != null ||
      oesReq.previousName != null ||
      oesReq.dateOfBirth != null ||
      oesReq.title != null ||
      oesReq.previousMonashId != null ||
      oesReq.firstName != null ||
      oesReq.phone != null ||
      oesReq.countryOfBirth != null ||
      oesReq.preferredName != null ||
      oesReq.isPreviousMonashStudent != null ||
      (oesReq.Email != null && !oesReq.Email.isEmpty()) ||
      (oesReq.phone != null && !oesReq.phone.isEmpty()) ||
      //Additional fields not in the payload
      oesReq.aboriginalOrTorresStraitIslander != null ||
      oesReq.countryOfResidence != null ||
      oesReq.isDeceased != null ||
      oesReq.broadAreaOfInterest != null ||
      oesReq.highestEducationLevel != null ||
      oesReq.specificAreaOfInterest != null;

  }


  /**
   * @description Validates phone numbers
   * @param phones The list of phone numbers
   * @param exceptions The exceptions object
   */
  @testVisible
  private void validatePhone(
    List<CommonWSPayload.Phone> phones,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (phones == null || phones.isEmpty()) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'At least one phone number is required'
        )
      );
      return;
    }

    Boolean hasMobilePhone = false;

    for (CommonWSPayload.Phone phone : phones) {
      // Validate phone type
      if (String.isBlank(phone.type)) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException('Phone type is required')
        );
        continue;
      }

      // Validate mobile phone
      if (phone.type.equalsIgnoreCase('Mobile')) {
        hasMobilePhone = true;
        validateMobilePhone(phone.phoneNumber, exceptions);
      }
    }

    // Validate that at least one mobile phone is provided
    if (!hasMobilePhone) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'At least one mobile phone number is required'
        )
      );
    }
  }

  /**
   * @description Validates a mobile phone number
   * @param phoneNumber The phone number to validate
   * @param exceptions The exceptions object
   */
  @testVisible
  private void validateMobilePhone(
    String phoneNumber,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (String.isBlank(phoneNumber)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Mobile phone number is required'
        )
      );
    }
  }

  /**
   * @description Validates the email list for OES applicants
   * @param emails The list of emails to validate
   * @param exceptions The exceptions object
   */
  public override void validateEmails(
    List<CommonWSPayload.Email> emails,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (emails == null || emails.isEmpty()) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'At least one email address is required'
        )
      );
      return;
    }

    Boolean hasPersonalEmail = false;

    for (CommonWSPayload.Email email : emails) {
      // Validate email type
      if (String.isBlank(email.type)) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException('Email type is required')
        );
        continue;
      }

      // Validate personal email
      if (email.type.equalsIgnoreCase('Personal')) {
        hasPersonalEmail = true;
        validatePersonalEmail(email.email, exceptions);
      }
    }

    // Validate that at least one personal email is provided
    if (!hasPersonalEmail) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'At least one personal email address is required'
        )
      );
    }
  }

  /**
   * @description Validates a personal email address
   * @param emailAddress The email address to validate
   * @param exceptions The exceptions object
   */
  @testVisible
  private void validatePersonalEmail(
    String emailAddress,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (String.isBlank(emailAddress)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Personal email address cannot be empty'
        )
      );
      return;
    }

    // Validate email format
    if (
      !Pattern.matches(
        '^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$',
        emailAddress
      )
    ) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException('Invalid email format')
      );
    }

    // Validate not a Monash email
    if (
      emailAddress.toLowerCase().endsWith('@monash.edu') ||
      emailAddress.toLowerCase().endsWith('@student.monash.edu')
    ) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Monash email addresses are not allowed'
        )
      );
    }
  }
  /**
   * @description Validates previous Monash student details
   * @param isPreviousMonashStudent Boolean indicating if applicant is previous Monash student
   * @param previousMonashId Previous Monash ID if applicable
   * @param exceptions The exceptions object
   */
  @testVisible
  private void validatePreviousMonashDetails(
    Boolean isPreviousMonashStudent,
    String previousMonashId,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    // Validate previousMonashId when isPreviousMonashStudent is true
    if (isPreviousMonashStudent == true) {
      if (String.isBlank(previousMonashId)) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException(
            'Previous Monash ID is required when applicant is a previous Monash student'
          )
        );
      } else if (previousMonashId.length() > 20) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException(
            'Previous Monash ID must not exceed 20 characters'
          )
        );
      }
    }
    if(isPreviousMonashStudent == null) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'isPreviousMonashStudent is required'
        )
      );
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
    if(country == null || String.isBlank(country.uniqueCountryExternalId)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException('Country of birth is required')
      );
      return;
    }
    List<Country_Attribute__c> countryAttributes = [
        SELECT Id
        FROM Country_Attribute__c
        WHERE uniqueCountryExternalId__c = :country.uniqueCountryExternalId
        LIMIT 1 
      ];
      if(countryAttributes.isEmpty()) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException('Country of birth does not exist')
        );
      }
    }
  }