/**
 * @description       : Abstract Applicant Validations class
 * @author            : Ben Greenland
 * @group             : admissions
 * @last modified on  : 2024-11-26
 * @last modified by  : Ben Greenland
 **/
public abstract class ApplicantWSValidations {
  /**
   * @description Validates the request object.
   * @param requestObj The request object to validate.
   * @return exceptions The exception object to add validation errors to.
   */
  public static RESTlib_Ex.InvalidRequestException validate(
    RESTlib_Payload.Request requestObj
  ) {
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

    if (requestObj instanceof OESApplicantPayload.PostRequest) {
      new OESApplicantValidations().validateRequest(requestObj, exceptions);
    } else if (requestObj instanceof APNGApplicantPayload.PostRequest) {
      new APNGApplicantValidations().validateRequest(requestObj, exceptions);
    }

    return exceptions;
  }

  /**
   * @description Validates the patch request for updating applicant information
   * @param requestObj The request object containing the update data
   * @return RESTlib_Ex.InvalidRequestException containing any validation errors
   */
  public static RESTlib_Ex.InvalidRequestException validatePatchRequest(
    RESTlib_Payload.Request requestObj
  ) {
    RESTlib_Ex.InvalidRequestException exceptions = new RESTlib_Ex.InvalidRequestException();

    if (requestObj instanceof OESApplicantPayload.PatchRequest) {
      new OESApplicantValidations()
        .validatePatchRequest(requestObj, exceptions);
    } else if (requestObj instanceof APNGApplicantPayload.PatchRequest) {
      new APNGApplicantValidations()
        .validatePatchRequest(requestObj, exceptions);
    }

    return exceptions;
  }

  // Abstract methods to be implemented by subclasses
  /**
   * @description Validates the request object.
   * @param requestObj The request object to validate.
   * @param exceptions The exception object to add validation errors to.
   */
  protected abstract void validateRequest(
    RESTlib_Payload.Request requestObj,
    RESTlib_Ex.InvalidRequestException exceptions
  );

  /**
   * @description Validates the patch request object.
   * @param requestObj The request object to validate.
   * @param exceptions The exception object to add validation errors to.
   */
  protected abstract void validatePatchRequest(
    RESTlib_Payload.Request requestObj,
    RESTlib_Ex.InvalidRequestException exceptions
  );

  /**
   * @description Validates if the non-pronoun fields are updated.
   * @param requestObj The request object to validate.
   * @return Boolean indicating if the non-pronoun fields are updated.
   */
  protected abstract Boolean isNonPronounFieldUpdated(Object requestObj);

  // Common validation methods
  /**
   * @description Validates the last name.
   * @param lastName The last name to validate.
   * @param exceptions The exception object to add validation errors to.
   */
  protected void validateLastName(
    String lastName,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (String.isBlank(lastName)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Applicant\'s Last Name cannot be empty'
        )
      );
    }
  }

  /**
   * @description Validates the date of birth.
   * @param dateOfBirth The date of birth to validate.
   * @param exceptions The exception object to add validation errors to.
   */
  protected virtual void validateDateOfBirth(
    String dateOfBirth,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (String.isBlank(dateOfBirth)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Applicant\'s Date of Birth cannot be empty'
        )
      );
    } else {
      try {
        Date d = Date.valueOf(dateOfBirth);
        if (
          d.daysBetween(Date.today()) / 365 <
          AgentPortalConstants.MINIMUM_AGE_FOR_APPLYING
        ) {
          exceptions.addException(
            new RESTlib_Ex.InvalidRequestException(
              'Applicant should be minimum 10 yrs old'
            )
          );
        }
      } catch (Exception e) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException(
            'Applicant\'s Date of Birth is of invalid format. Only yyyy-MM-dd format is accepted'
          )
        );
      }
    }
  }

    /**
   * @description Validates the common patch fields for the patch request
   * @param req The request object
   * @param exceptions The exceptions object
   */
  @testVisible
  public virtual void validateCommonPatchFields(
    OESApplicantPayload.PatchRequest req,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (req.lastName != null && String.isEmpty(req.lastName)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Applicant\'s Last Name cannot be empty'
        )
      );
    }
    if (
      req.Email != null &&
      String.isEmpty(CommonWSPayload.getEmail(req.Email, 'Personal'))
    ) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Applicant\'s email cannot be empty'
        )
      );
    }
    validateGender(req.gender, exceptions);
    if (req.dateOfBirth != null) {
      validateDateOfBirth(String.valueOf(req.dateOfBirth), exceptions);
    }
  }


  /**
   * @description Validates the email list.
   * @param emails The list of emails to validate.
   * @param exceptions The exception object to add validation errors to.
   */
  public virtual void validateEmails(
    List<CommonWSPayload.Email> emails,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    for (CommonWSPayload.Email email : emails) {
      if (String.isBlank(email.email)) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException(
            'Applicant\'s Email cannot be empty'
          )
        );
      }
    }
  }

  /**
   * @description Validates the gender.
   * @param gender The gender to validate.
   * @param exceptions The exception object to add validation errors to.
   */
  protected void validateGender(
    String gender,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    // Add null/empty check
    if (String.isBlank(gender)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Applicant\'s Gender cannot be empty'
        )
      );
      return;
    }

    // Existing validation
    if (AgentPortalConstants.CON_UNUSED_GENDERS.contains(gender)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Applicant\'s Gender cannot be P or U'
        )
      );
    }
  }

  /**
   * @description Validates address details
   * @param addresses List of addresses to validate
   * @param exceptions The exceptions object
   */
  @testVisible
  protected virtual void validateAddresses(
    List<CommonWSPayload.Address> addresses,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    if (addresses == null || addresses.isEmpty()) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException('At least one address is required')
      );
      return;
    }

    Boolean hasPostalAddress = false;
    for (CommonWSPayload.Address address : addresses) {
      if (address.type.equalsIgnoreCase('Postal')) {
        hasPostalAddress = true;
        break;
      }
    }

    for (CommonWSPayload.Address address : addresses) {
      // Validate address type
      if (String.isBlank(address.type)) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException('Address type is required')
        );
        continue;
      }

      // Validate address fields based on type
      if (address.type.equalsIgnoreCase('Postal')) {
        validatePostalAddress(address, exceptions);
      } else if (address.type.equalsIgnoreCase('Other')) {
        validateOtherAddress(address, exceptions);
      } else if (
        !address.type.equalsIgnoreCase('Other') &&
        !address.type.equalsIgnoreCase('Postal')
      ) {
        exceptions.addException(
          new RESTlib_Ex.InvalidRequestException(
            'Invalid address type. Must be either Postal or Other'
          )
        );
      }
    }
    if (!hasPostalAddress) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException('Postal address is required')
      );
    } 
  }

  /**
   * @description Validates postal address fields
   * @param address The address to validate
   * @param exceptions The exceptions object
   */
  protected virtual void validatePostalAddress(
    CommonWSPayload.Address address,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    // Required fields for postal address
    if (String.isBlank(address.street)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Street is required for postal address'
        )
      );
    }
    if (String.isBlank(address.city)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'City is required for postal address'
        )
      );
    }
    if (String.isBlank(address.country)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Country is required for postal address'
        )
      );
    }
    if (String.isBlank(address.postalCode)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'Postal code is required for postal address'
        )
      );
    }
    if (String.isBlank(address.state)) {
      exceptions.addException(
        new RESTlib_Ex.InvalidRequestException(
          'State is required for postal address'
        )
      );
    }
  }

  /**
   * @description Validates other address fields
   * @param address The address to validate
   * @param exceptions The exceptions object
   */
  protected virtual void validateOtherAddress(
    CommonWSPayload.Address address,
    RESTlib_Ex.InvalidRequestException exceptions
  ) {
    // By default, use same validation as postal address
    validatePostalAddress(address, exceptions);
  }
}