/**
 * @description Payload class for APNGApplicantImpl
 *              Refactored from AgentPortalPayload
 * @author      Nick Guia
 * @since       JUL.30.2024
 */
public inherited sharing class APNGApplicantPayload {
  /**
   * @description Request payload for HTTP Get
   */
  public class GetRequest extends RESTlib_Payload.Request {
    /**
     * @description corresponds to Contact.CRM_ID__c
     * @returns String
     */
    public String crmContactId { get; set; }
    /**
     * @description  mainly used for "Search applicant" functionality
     */
    public String applicantName { get; set; }
    /**
     *@description  TODO : check with MIX if this is being used
     */
    public Integer pageSize { get; set; } // search limit
    /**
     *@description TODO : check with MIX if this is being used
     */
    public Integer pageOffset { get; set; } // search offset
  }

  /**
   * @description Response payload for HTTP Get
   */
  public class GetResponse extends RESTlib_Payload.Response {
    /**
     * @description count of resulting Contact records
     */
    public Integer noOfRecords { get; set; }
    /**
     * @description result for GET Applicant by CRM Id
     */
    public ApplicantDetails applicant { get; set; }
    /**
     * @description result for search Applicants by name
     */
    public List<ApplicantDetails> applicants { get; set; }
    /**
     *@description TODO : check with MIX if this is being used
     */
    public Integer pageSize { get; set; }
    /**
     * @description TODO : check with MIX if this is being used
     */
    public Integer pageOffset { get; set; }
    /**
     * @description message - message String to send in response
     */
    public String message { get; set; }
  }

  /**
   * @description Request payload for HTTP POST
   */
  public class PostRequest extends RESTlib_Payload.Request {
    /** 
         @description Applicant object
        */
    public Applicant applicant { get; set; }
  }

  /**
   * @description Request payload for HTTP POST
   */
  public class PostResponse extends RESTlib_Payload.Response {
    /** 
         @description ApplicantResponse
        */
    public ApplicantResponse applicant { get; set; }
    /** 
         @description response message
        */
    public String message { get; set; }
  }

  /**
   * @description Request payload for HTTP PATCH
   */
  public class PatchRequest extends RESTlib_Payload.Request {
    /**
     * @description applicant object
     */
    // public PatchApplicant applicant {get;set;}
    public String aboriginalTorresIslander;
    public String aboriginalOrTorresStraitIslander;
    public String lastName;
    public List<CommonWSPayload.Address> address;
    public Boolean hasMononymousName;
    public String gender;
    public Id contactId;
    public String previousName;
    public String previousFirstName;
    public String dateOfBirth;
    public String title;
    public String previousMonashId;
    public String firstName;
    public String pronoun;
    public List<CommonWSPayload.Phone> phone;
    public CommonWSPayload.Country countryOfBirth;
    public String preferredName;
    public Boolean isPreviousMonashStudent;
    public List<CommonWSPayload.Email> email;

    //NOT sure these are required for patch
    public String crmContactId; // CRM_ID__c (not used in AgentPortalPayload.CDM_Applicant.asContact())
    public String smsContactId; // Person_id_unique__c (not used in AgentPortalPayload.CDM_Applicant.asContact())
    public String countryOfResidence;
    public Boolean isDeceased;
    public String broadAreaOfInterest;
    public String highestEducationLevel;
    public String leadSource;//not used in AgentPortalPayload.CDM_Applicant.asContact()
    public String sourceSystem;//not used in AgentPortalPayload.CDM_Applicant.asContact()
    public String specificAreaOfInterest;
    // disallowedFieldUpdated is an internal field used to track if a disallowed field has been updated
    //isNonPronounFieldUpdated method in OESApplicantValidations.cls does the check for disallowed fields on update
    public Boolean disallowedFieldUpdated;


    public Contact createContactFromPatchRequest() {
      Contact cont = new Contact();
      if(this.contactId != null) {
        cont.Id = this.contactId;
      }
      if(this.lastName != null) {
        cont.LastName = this.lastName;
        cont.Last_Name__c = this.lastName;
      }
      if(this.firstName != null) {
        cont.FirstName = this.firstName;
        cont.First_Name__c = this.firstName;
      }
      if(this.title != null) {
        cont.Salutation = this.title;
      }
      if(this.dateOfBirth != null) {
        cont.Birthdate = Date.valueOf(this.dateOfBirth);
      }
      if(this.isPreviousMonashStudent != null) {
        cont.Previously_Studied_at_Monash__c = this.isPreviousMonashStudent;
      }
      if(this.preferredName != null) {
        cont.Preferred_Name__c = this.preferredName;
      }
      if(this.aboriginalOrTorresStraitIslander != null) {
        cont.Aboriginal_or_Torres_Strait_Islander__c = this.aboriginalOrTorresStraitIslander;
      }
      if(this.previousName != null) {
        cont.Previous_Surname__c = this.previousName;
      }
      if(this.previousFirstName != null) {
        cont.Previous_Firstname__c = this.previousFirstName;
      }
      if(this.previousMonashId != null) {
        cont.Previous_Monash_ID__c = this.previousMonashId;
      }
      if(this.pronoun != null) {
        cont.Pronouns_V2__c = this.pronoun;
      }
      if(this.gender != null) {
        cont.Gender__c = this.gender;
      }
      if (this.phone != null) {
        for (CommonWSPayload.Phone phone : this.phone) {
          if (phone.type == 'Mobile') {
            cont.MobilePhone = phone.phoneNumber;
          } else if (phone.type == 'Home') {
            cont.HomePhone = phone.phoneNumber;
          }
        }
      }

      if (this.email != null) {
        for (CommonWSPayload.Email email : this.email) {
          if (email.type == 'Personal') {
            cont.Personal_Email__c = email.email;
          }
        }
      }
      if (this.address != null) {
        for (CommonWSPayload.Address address : this.address) {
          if (address.type == 'Postal') {
            cont.MailingStreet = address.street;
            cont.MailingCity = address.city;
            cont.MailingState = address.state;
            cont.MailingCountry = address.country;
            cont.MailingPostalCode = address.postalCode;
          } else  if (address.type == 'Other') {
            cont.OtherStreet = address.street;
            cont.OtherCity = address.city;
            cont.OtherState = address.state;
            cont.OtherCountry = address.country;
            cont.OtherPostalCode = address.postalCode;
          }
        }
      }
      if (this.countryOfBirth != null && this.countryOfBirth?.crmRecordId != null) {
        cont.CountryOfBirth__c = this.countryOfBirth?.crmRecordId;
      }
      //Additional fields not in the payload
      // this.crmContactId; not mapped in AgentPortalPayload.CDM_Applicant.asContact()
      // this.smsContactId; not mapped in AgentPortalPayload.CDM_Applicant.asContact()
      // this.leadSource; not mapped in AgentPortalPayload.CDM_Applicant.asContact()
      // this.sourceSystem; not mapped in AgentPortalPayload.CDM_Applicant.asContact()
      if (this.countryOfResidence != null) {
        cont.Country_of_Residence__c = this.countryOfResidence;
      }
      if (this.isDeceased != null) {
        cont.Deceased__c = this.isDeceased;
      }
      if (this.broadAreaOfInterest != null) {
        cont.Broad_area_s_of_interest__c = this.broadAreaOfInterest;
      }
      if (this.highestEducationLevel != null) {
        cont.Highest_level_of_education_to_date__c = this.highestEducationLevel;
      }
      if (this.specificAreaOfInterest != null) {
        cont.Specific_area_s_of_interest__c = this.specificAreaOfInterest;
      }

      return cont;
    }
  }

  /**
   * @description Request payload for HTTP patch
   */
  public class PatchResponse extends RESTlib_Payload.Response {
    /**
         @description ApplicantResponse
        */
    public ApplicantPatchResponse applicant { get; set; }
    /**
         @description response message
        */
    public String message { get; set; }
  }

  /** @description Applicant details wrapper*/
  public class ApplicantDetails {
    /** @description isEditable*/
    public Boolean isEditable { get; set; }
    /** @description remove??*/
    public Id contactId { get; set; }
    /** @description Salutation */
    public String salutation { get; set; }
    /** @description First_Name__c*/
    public String firstName { get; set; }
    /** @description Last_Name__c*/
    public String lastName { get; set; }
    /** @description Suffix*/
    public String suffix { get; set; }
    /** @description Preferred_Name__c*/
    public String preferredName { get; set; }
    /** @description Previous_Surname__c*/
    public String previousSurname { get; set; }
    /** @description Previous_Firstname__c*/
    public String previousFirstName { get; set; }
    /** @description Is_Mononymous_Name__c*/
    public Boolean isMononymousName { get; set; }
    /** @description Pronouns_V2__c*/
    public String pronouns { get; set; }
    /** @description Gender__c*/
    public String gender { get; set; }
    /** @description CRM_Id__c*/
    public String externalId { get; set; }
    /** @description Person_ID__c*/
    public String personId { get; set; }
    /** @description Previous_Monash_ID__c*/
    public String previousMonashId { get; set; }
    /**@description Birthdate */
    public Date birthdate { get; set; }
    /**@description MailingStreet */
    public String mailingStreet { get; set; }
    /**@description MailingCity */
    public String mailingCity { get; set; }
    /**@description MailingState */
    public String mailingState { get; set; }
    /**@description MailingCountry */
    public String mailingCountry { get; set; }
    /**@description MailingPostalCode */
    public String mailingPostalCode { get; set; }
    /**@description OtherStreet */
    public String otherStreet { get; set; }
    /**@description OtherCity */
    public String otherCity { get; set; }
    /**@description OtherState */
    public String otherState { get; set; }
    /**@description OtherCountry */
    public String otherCountry { get; set; }
    /**@description OtherPostalCode */
    public String otherPostalCode { get; set; }
    /**@description MobilePhone */
    public String mobilePhone { get; set; }
    /**@description HomePhone */
    public String homePhone { get; set; }
    /**@description Personal_Email__c */
    public String personalEmail { get; set; }
    /**@description Previously_Studied_at_Monash__c */
    public Boolean previouslyStudiedAtMonash { get; set; }
    /**@description */
    public Boolean isPreviousMonashStudent { get; set; }
    /**@description Country_Of_Birth__c (picklist) TODO : is this being used? */
    public String countryOfBirthStr { get; set; }
    /**@description CountryOfBirth__c (lookup) */
    public CommonWSPayload.Country countryOfBirth { get; set; }
    /**@description Aboriginal_or_Torres_Strait_Islander__c */
    public String aboriginalOrTorresStraitIslander { get; set; }
    /**@description do we need this?? */
    public String recordTypeId { get; set; }
    /**@description recordId*/
    public String id;

    /**
     * @description transposes a Contact SObject into an ApplicantDetails wrapper.
     * Assumptions:
     *  - Relationship query to CountryOfBirth__r (and fields) are in the Contact instance. Otherwise,
     *    set them manually after initializing
     * @param con
     */
    public ApplicantDetails(Contact con) {
      this.contactId = con.id;
      this.firstName = con.First_Name__c;
      this.lastName = con.Last_Name__c;
      this.externalId = con.CRM_Id__c;
      this.personId = con.Person_ID__c;
      this.salutation = con.Salutation;
      this.pronouns = con.Pronouns_V2__c;
      this.suffix = con.Suffix;
      this.preferredName = con.Preferred_Name__c;
      this.isMononymousName = con.Is_Mononymous_Name__c;
      this.gender = con.Gender__c;
      this.birthdate = con.Birthdate;
      this.mailingStreet = con.MailingStreet;
      this.mailingCity = con.MailingCity;
      this.mailingState = con.MailingState;
      this.mailingCountry = con.MailingCountry;
      this.mailingPostalCode = con.MailingPostalCode;
      this.otherStreet = con.OtherStreet;
      this.otherCity = con.OtherCity;
      this.otherState = con.OtherState;
      this.otherCountry = con.OtherCountry;
      this.otherPostalCode = con.OtherPostalCode;
      this.mobilePhone = con.MobilePhone;
      this.homePhone = con.HomePhone;
      this.personalEmail = con.Personal_Email__c;
      this.previousSurname = con.Previous_Surname__c;
      this.previousFirstName = con.Previous_Firstname__c;
      this.previousMonashId = con.Previous_Monash_ID__c;
      this.previouslyStudiedAtMonash = con.Previously_Studied_at_Monash__c;
      this.countryOfBirthStr = con.Country_Of_Birth__c;
      this.aboriginalOrTorresStraitIslander = con.Aboriginal_or_Torres_Strait_Islander__c;
      this.recordTypeId = con.RecordTypeId;

      if (this.countryOfBirth == null) {
        this.countryOfBirth = new CommonWSPayload.Country();
      }

      this.countryOfBirth.id = con.CountryOfBirth__r?.Id;
      this.countryOfBirth.name = con.CountryOfBirth__r?.Name;
      this.countryOfBirth.callistaCode = con.CountryOfBirth__r
              ?.Callista_Code__c;
      this.countryOfBirth.callistaCountry = con.CountryOfBirth__r
              ?.Callista_Country__c;
    }
  }
  // /** @description Email Wrapper */
  // public class Email {
  //   public String type;
  //   public String email;
  // }
  // /** @description Phone Wrapper */
  // public class Phone {
  //   public String type;
  //   public String phoneNumber;
  // }
  /** @description Applicant  Wrapper */
  public class Applicant {
    public String firstName;
    public String lastName;
    public String dateOfBirth;
    public List<CommonWSPayload.Email> email;
    public List<CommonWSPayload.Phone> phone;
    public Boolean isPreviousMonashStudent;
    public String previousMonashId;
    public String previousName;
    public String previousFirstName;
  }

  /** @description ApplicantRespinse Wrapper */
  public class ApplicantResponse {
    public String firstName;
    public String lastName;
    public String dateOfBirth;
    public String email;
    public String phone;
    public Boolean isPreviousMonashStudent;
    public String previousMonashId;
    public String previousName;
    public String previousFirstName;
    public String externalId;
    public String Id;
    public String salutation;
    public String preferredName;
    // public String accountId;
    public String gender;
    // public String middleName;
  }

  /** @description ApplicantRespinse Wrapper */
  public class ApplicantPatchResponse {
    public String firstName;
    public String lastName;
    public String dateOfBirth;
    public String email;
    public String phone;
    public Boolean isPreviousMonashStudent;
    public String previousMonashId;
    public String previousName;
    public String previousFirstName;
    public String externalId;
    public String Id;
    public String salutation;
    public String preferredName;
    public String accountId;
    public String gender;
    public String middleName;
    public String aboriginalOrTorresStraitIslander;
  }

  /**
   * @description Parse JSON to Contact
   * @param  applicant record
   * @return Contact
   **/
  public static Contact parseApplicantToContact(Applicant applicant) {
    Contact con = new Contact();
    con.First_Name__c = applicant.firstName;
    con.Last_Name__c = applicant.lastName;
    con.FirstName = applicant.firstName;
    con.LastName = applicant.lastName;
    con.Birthdate = Date.valueOf(applicant.dateOfBirth);
    con.Previous_Surname__c = applicant.previousName;
    con.Previous_Firstname__c = applicant.previousFirstName;
    con.Previous_Monash_ID__c = applicant.previousMonashId;
    con.Previously_Studied_at_Monash__c = applicant.isPreviousMonashStudent;
    con.MobilePhone = CommonWSPayload.getPhoneNumber(applicant.phone, 'Mobile');
    con.Personal_Email__c = CommonWSPayload.getEmail(applicant.email, 'Personal');
    return con;
  }

  /**
 * @description contact to Applicant response wrapper
 * @author Ben Greenland
 * @param  con Contact
 * @return ApplicantResponse
 **/
  public static ApplicantPatchResponse parseApplicantToPatchResponse(Contact con) {
    ApplicantPatchResponse response = new ApplicantPatchResponse();
    response.firstName = con?.First_Name__c;
    response.lastName = con?.Last_Name__c;
    Datetime tempdate = con?.Birthdate;
    if(tempdate != null) {
      response.dateOfBirth = tempdate.format('yyyy-MM-dd');
    }
    response.previousName = con?.Previous_Surname__c;
    response.previousFirstName = con?.Previous_Firstname__c;
    response.previousMonashId = con?.Previous_Monash_ID__c;
    response.isPreviousMonashStudent = con?.Previously_Studied_at_Monash__c;
    response.phone = con?.MobilePhone;
    response.email = con?.Personal_Email__c;
    response.externalId = con?.CRM_Id__c;
    response.Id = con?.Id;
    response.middleName = con?.MiddleName;
    response.accountId = con?.AccountId!=null?con?.AccountId:null;
    response.preferredName = con?.Preferred_Name__c;
    response.gender = con?.Gender__c;
    response.aboriginalOrTorresStraitIslander = con?.Aboriginal_or_Torres_Strait_Islander__c;
    return response;
  }

  /**
 * @description contact to Applicant response wrapper
 * @author Ben Greenland
 * @param  con Contact
 * @return ApplicantResponse
 **/
  public static ApplicantResponse parseApplicantToResponse(Contact con) {
    ApplicantResponse response = new ApplicantResponse();
    response.firstName = con?.First_Name__c;
    response.lastName = con?.Last_Name__c;
    Datetime tempdate = con?.Birthdate;
    response.dateOfBirth = tempdate.format('yyyy-MM-dd');
    response.previousName = con?.Previous_Surname__c;
    response.previousFirstName = con?.Previous_Firstname__c;
    response.previousMonashId = con?.Previous_Monash_ID__c;
    response.isPreviousMonashStudent = con?.Previously_Studied_at_Monash__c;
    response.phone = con?.MobilePhone;
    response.email = con?.Personal_Email__c;
    response.externalId = con?.CRM_Id__c;
    response.Id = con?.Id;
    return response;
  }
}