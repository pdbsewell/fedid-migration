@SuppressWarnings('PMD.ApexDoc, PMD.ExcessivePublicCount,PMD')
/**
 * @author            Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-09-20   Ben Greenland   Initial Version
 * @group             APNG Application Webservice v3
 **/
// Cannot be avoided public method as wrapper is shared. PMD is suppressed. Limited time to refactor.
public inherited sharing class APNGApplicationPayload extends ApplicationWSWrapper {
	public class ApplicationException extends RESTlib_Ex.ListException {
	}
	/**
	 * @description Request payload for HTTP Get
	 */
	public class GetRequest extends RESTlib_Payload.Request {
		/**
		 * @description corresponds to Application.CRM_ID__c
		 */
		public String applicationId { get; set; }
		/**
		 * @description  null or qualifications or experiences
		 */
		public String related {
			get {
				if (String.isEmpty(related)) {
					related = '';
				}
				return related;
			}
			set;
		}
	}

	/**
	 * @description Response payload for HTTP Get
	 */
	public class GetResponseApplication extends RESTlib_Payload.Response {
		/**
		 * @description result for GET Applicant by CRM Id
		 */
		public ApplicationDetails application { get; set; }
		/**
		 * @description message - message String to send in response
		 */
		public String message { get; set; }
	}

	/**
	 * @description Response payload for HTTP Get
	 */
	public class GetResponseQualifications extends RESTlib_Payload.Response {
		/**
		 * @description result for GET Applicant by CRM Id
		 */
		public Qualifications application { get; set; }
		/**
		 * @description message - message String to send in response
		 */
		public String message { get; set; }
	}

	/**
	 * @description Response payload for HTTP Get
	 */
	public class GetResponseWorkExperiences extends RESTlib_Payload.Response {
		/**
		 * @description result for GET Applicant by CRM Id
		 */
		public WorkExperiences application { get; set; }
		/**
		 * @description message - message String to send in response
		 */
		public String message { get; set; }
	}

	/**
	 * @description Request payload for HTTP POST
	 */
	public class PostRequest extends RESTlib_Payload.Request {
		public String campusLocation { get; set; }

		/** @description The residency status of the applicant */
		public String residencyStatus { get; set; }

		/** @description The contact ID of the applicant */
		public String contactId { get; set; }

		/** @description List of phone numbers for the applicant */
		public List<CommonWSPayload.Phone> phone { get; set; }

		/** @description External reference ID for the application */
		public String externalReferenceId { get; set; }

		/** @description Notes from the agent */
		public String agentNotes { get; set; }

		/** @description List of email addresses for the applicant */
		public List<CommonWSPayload.Email> email { get; set; }

		/** @description The delegator org unit code */
		public String delegatorOrgUnitCode { get; set; }
	}

	/**
	 * @description Response payload for HTTP POST
	 */
	public class PostResponse extends RESTlib_Payload.Response {
		/**
		 * @description The created application details
		 */

		//todo update this
		public ApplicationPostResponse application { get; set; }

		/**
		 * @description Response message
		 */
		public String message { get; set; }
	}
/**
	 * @description Custom exception class for application-related exceptions.
	 */
	public class PatchRequest extends RESTlib_Payload.Request {
		public APNGApplicationPayload.CDM_Application application { get; set; }
		@TestVisible
		public ApplicationWSService.PatchApplicationService patchApplicationService {
			get {
				if (patchApplicationService == null) {
					patchApplicationService = new ApplicationWSService.PatchApplicationService(application);
				}
				return patchApplicationService;
			}
			set;
		}
		public PatchRequest() {
			this.application = new CDM_Application();
			this.application = application;
		}
		public PatchRequest(CDM_Application application) {
			this.application = new CDM_Application();
			this.application = application;
		}
		/**
		 * @description Process the PATCH request. This method will update the application and only OES specific use case
		 * This inherits the process method from ApplicationWSService.PatchApplicationService service class
		 * which has the shared processing logic for APNG and OES both
		 */
		public ApplicationWSWrapper.ApplicationResponseWrapper process() {
			try {
				Nebula.Logger.info('APNGApplicationPayload PatchRequest process():' + JSON.serialize(this.application));
				return this.patchApplicationService.process();
			} catch (Exception e) {
				Nebula.Logger.error('Exception occured while APNGApplicationPayload.process()', e);
				throw new RESTlib_Ex.WebServiceException(e.getMessage());
			}
		}
	}
	/**
	 * @description Creates an Application__c record from the PostRequest data
	 * @param req The PostRequest containing the application data
	 * @return Application__c The created Application__c record (not yet inserted)
	 */
	public static Application__c createApplicationRecord(PostRequest req) {
		Application__c app = new Application__c(
			Agent__c = CommonWSPayload.runningUser?.Contact.AccountId,
			Agent_Org_Unit_Code__c = CommonWSPayload.runningUser?.contact.Account.Callista_Org_Unit_Code__c,
			Applicant__c = req.contactId,
			status__c = AgentPortalConstants.APP_CREATE_STATUS,
			//Populate Source_System__c based on the calling client
			Source_System__c = AgentPortalConstants.APP_CREATE_SOURCE,
			Campus_Location__c = req.campusLocation,
			External_Reference_Id__c = req.externalReferenceId,
			Agent_Notes__c = req.agentNotes,
			Delegator_Org_Unit_Code__c = req.delegatorOrgUnitCode,
			Type_of_Study__c = AgentPortalConstants.APP_CREATE_TYPE
		);

		// Handle residency status
		if (req.residencyStatus != null && req.residencyStatus.contains('.')) {
			app.Residency_Sub_status__c = req.residencyStatus; // e.g., DOM-SUN.A
			app.Residency_Status__c = req.residencyStatus.split('\\.')[0]; // e.g., DOM-SUN
		} else {
			app.Residency_Status__c = req.residencyStatus;
		}

		return app;
	}
	/**
	 * @description ApplicationPostResponse payload
	 */
	public class ApplicationPostResponse {
		public String id;
		public String name;
		public String applicantId;
		public String status;
		public String sourceSystem;
		public String campusLocation;
		public String residencySubStatus;
		public String residencyStatus;

		/**
		 * @description Populates the ApplicationPostResponse from an Application__c record
		 * @param application The Application__c record to populate from
		 */
		public void populateFromApplication(Application__c application) {
			this.id = application.Id;
			this.name = application.Name;
			this.applicantId = application.Applicant__c;
			this.status = application.Status__c;
			this.sourceSystem = application.Source_System__c;
			this.campusLocation = application.Campus_Location__c;
			this.residencySubStatus = application.Residency_Sub_status__c;
			this.residencyStatus = application.Residency_Status__c;
		}
	}
	/**
	 * @description Request payload for HTTP patch
	 */
	public class PatchResponse extends RESTlib_Payload.Response {
		public Object application { get; set; }
		public String message { get; set; }
	}

	/** @description ApplicationDetails payload*/
	public virtual class ApplicationDetails {
		public ApplicationWrapper details;
		public Qualifications applicationQualifications;
		public WorkExperiences workExperiences;
		public List<ApplicationCoursePreference> coursePreferences;
	}

	/** @description Qualifications payload*/
	public class Qualifications {
		public List<ApplicationWSWrapper.ContactQualificationWrapper> applicationQualifications;
		public String applicationId;
		public String applicantId;
		public Integer recordCount;
	}

	/** @description WorkExperiences payload*/
	public class WorkExperiences {
		public String applicationId; // Name
		public String applicantId;
		/**
		 * @description recordCount
		 * @return Integer
		 **/
		public Integer recordCount {
			get {
				return (applicationExperiences == null || applicationExperiences.isEmpty() ? 0 : applicationExperiences.size());
			}
		}
		public List<WorkExperienceWrapper> applicationExperiences;
	}
	/**
	 * @description ApplicationWrapper
	 */
	public class ApplicationWrapper {
		public String id { get; set; }
		public String name { get; set; }
		public String campusLocation { get; set; }
		public String callistaApplicationId { get; set; }
		public String status { get; set; }
		public String applicationType { get; set; }
		public Boolean creditIntention { get; set; }
		public String lastModifiedDate { get; set; }
		public Applicant applicant { get; set; }
		public String sentToStudentForReviewTimestamp { get; set; }
		public String studentAcceptedTimestamp { get; set; }
		public String agentAcceptedTimestamp { get; set; }
		public String agentName { get; set; }
		public Country citizenshipCountry { get; set; }
		public Country singleEntryVisa { get; set; }
		public String visaType { get; set; }
		public String australianImmigrationOfficeIssued { get; set; }
		public String passportNumber { get; set; }
		public String visaNumber { get; set; }
		public Date visaStartDate { get; set; }
		public Date visaEndDate { get; set; }
		public String studentPassAvailability { get; set; }
		public String refusedEntryVisaToAnyCountry { get; set; }
		public String breachedVisaCondition { get; set; }
		public String medicalHealthPreventVisa { get; set; }
		public String protectionVisaInAnyCountry { get; set; }
		public String convictedOfCrimeOffence { get; set; }
		public String callistaApplicantId { get; set; }
		public Boolean englishLanguageProficiency { get; set; }
		public String englishProficiencyRequirement { get; set; }
		public String optInMonashEnglishProgram { get; set; }
		public String residencyStatus { get; set; }
		public String residencySubStatus { get; set; }
		public String sourceSystem { get; set; }
		public String hasDisabilities { get; set; }
		public String existingAusDisabilitySupport { get; set; }
		public Boolean isPrincipalCourseTransfer { get; set; }
		public Boolean isSponsored { get; set; }
		public String sponsorName { get; set; }
		public String sponsorshipStatus { get; set; }
		public String sponsorshipType { get; set; }
		public String sponsorScholarshipOrganisation { get; set; }
		public String feePaymentMode { get; set; }
		public Decimal feeAmount { get; set; }
		public Boolean feePayment { get; set; }
		public Decimal transactionAmount { get; set; }
		public Date transactionDate { get; set; }
		public String transactionReference { get; set; }
		public String transactionSource { get; set; }
		public String feeWaiverCode { get; set; }
		public String feeWaiverRedeemed { get; set; }
		public Owner owner { get; set; }
		public String ownerId { get; set; }
		public String agentNotes { get; set; }
		public String myAppUserStatus { get; set; }
		public String externalReferenceId;
		public String delegatorOrgUnitCode { get; set; }
		public ApplicationWrapper() {
			this.delegatorOrgUnitCode = '';
		}
		/**
		 * @description ApplicationWrapper constructor
		 * @author Ben Greenland | 2024-10-02
		 * @param  app Application__c
		 **/
		public ApplicationWrapper(Application__c app) {
			// NOPMD
			this.id = app.Id;
			this.name = app.Name;
			this.campusLocation = app.Campus_Location__c;
			this.callistaApplicationId = app.Callista_Application_Id__c;
			this.status = app.Status__c;
			this.applicationType = app.Application_Type__c;
			this.creditIntention = app.Credit_Intention__c;
			this.lastModifiedDate = app?.LastModifiedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

			// Map Applicant
			if (app.Applicant__r != null) {
				this.applicant = new Applicant();
				this.applicant.Id = app.Applicant__r.Id;
				this.applicant.crmContactId = app.Applicant__r.CRM_ID__c;
			}

			this.sentToStudentForReviewTimestamp = app
				?.Sent_to_student_for_review_Timestamp__c
				?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.studentAcceptedTimestamp = app?.Student_Accepted_Timestamp__c?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.agentAcceptedTimestamp = app?.Agent_Accepted_Timestamp__c?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.agentName = app.AgentName__c;

			// Map Citizenship Country
			if (app.Citizenship_Country__r != null) {
				this.citizenshipCountry = new Country();
				this.citizenshipCountry.uniqueCountryExternalId = app.Citizenship_Country__r?.uniqueCountryExternalId__c;
				this.citizenshipCountry.crmRecordId = app.Citizenship_Country__r?.Id;
				this.citizenshipCountry.isoalpha2 = app.Citizenship_Country__r?.ISO_Alpha_2__c;
				this.citizenshipCountry.name = app.Citizenship_Country__r?.Name;
				this.citizenshipCountry.country = app.Citizenship_Country__r?.Country__c;
				this.citizenshipCountry.isoalpha3 = app.Citizenship_Country__r?.ISO_Alpha_3__c;
				this.citizenshipCountry.callistaCode = app.Citizenship_Country__r?.Callista_Code__c;
			}

			// Map Single Entry Visa
			if (app.Single_Entry_Visa__r != null) {
				this.singleEntryVisa = new Country();
				this.singleEntryVisa.uniqueCountryExternalId = app.Single_Entry_Visa__r?.uniqueCountryExternalId__c;
				this.singleEntryVisa.crmRecordId = app.Single_Entry_Visa__r?.Id != null ? app.Single_Entry_Visa__r.Id : null;
				this.singleEntryVisa.isoalpha2 = app.Single_Entry_Visa__r?.ISO_Alpha_2__c;
				this.singleEntryVisa.name = app.Single_Entry_Visa__r?.Name;
				this.singleEntryVisa.country = app.Single_Entry_Visa__r?.Country__c;
				this.singleEntryVisa.isoalpha3 = app.Single_Entry_Visa__r?.ISO_Alpha_3__c;
				this.singleEntryVisa.callistaCode = app.Single_Entry_Visa__r?.Callista_Code__c;
			}

			this.visaType = app.Visa_Type__c;
			this.australianImmigrationOfficeIssued = app.Australian_Immigration_Office_Issued__c;
			this.passportNumber = app.Passport_Number__c;
			this.visaNumber = app.Visa_Number__c;
			this.visaStartDate = app.Visa_Start_Date__c;
			this.visaEndDate = app.Visa_End_Date__c;
			this.studentPassAvailability = app.Student_Pass_Availability__c;
			this.refusedEntryVisaToAnyCountry = app.Refused_Entry_Visa_To_Any_Country__c;
			this.breachedVisaCondition = app.Breached_Visa_Condition__c;
			this.medicalHealthPreventVisa = app.Medical_Health_Prevent_Visa__c;
			this.protectionVisaInAnyCountry = app.Protection_Visa_In_Any_Country__c;
			this.convictedOfCrimeOffence = app.Convicted_Of_Crime_Offence__c;
			this.callistaApplicantId = app.Callista_Applicant_Id__c;
			this.englishLanguageProficiency = app.English_Language_Proficiency__c == 'Yes' ? true : false;
			this.englishProficiencyRequirement = app.English_Proficiency_Requirement__c;
			this.optInMonashEnglishProgram = app.English_Program_Consideration__c;
			this.residencyStatus = app.Residency_Status__c;
			this.residencySubStatus = app.Residency_Sub_status__c;
			if (String.isNotBlank(app.Residency_Sub_status__c)) {
				//Not sure why this is in AgentPortalPayload
				this.residencyStatus = app.Residency_Sub_status__c;
				this.residencySubStatus = '';
			}
			this.sourceSystem = app.Source_System__c;
			this.hasDisabilities = app.HasDisabilities__c;
			this.existingAusDisabilitySupport = app.Existing_Aus_disability_support__c;
			this.isPrincipalCourseTransfer = app.is_Principal_Course_Transfer__c;
			this.isSponsored = app.Is_Sponsored__c;
			this.sponsorName = app.Sponsor_Name__c;
			this.sponsorshipStatus = app.Sponsorship_Status__c;
			this.sponsorshipType = app.Sponsorship_Type__c;
			this.sponsorScholarshipOrganisation = app.Sponsor_Scholarship_organisation__c;
			this.feePaymentMode = app.Fee_Payment_Mode__c;
			this.feeAmount = app.Fee_Amount__c;
			this.feePayment = app.Fee_Payment__c;
			this.transactionAmount = app.Transaction_Amount__c;
			this.transactionDate = app.Transaction_Date__c;
			this.transactionReference = app.Transaction_Reference__c;
			this.transactionSource = app.Transaction_Source__c;
			this.feeWaiverCode = app.Fee_Waiver_Code__c;
			this.feeWaiverRedeemed = app.Fee_Waiver_Redeemed__c;
			this.ownerId = app?.Owner?.Id;
			if (app.Owner != null) {
				this.owner = new Owner();
				this.owner.Id = app.Owner.Id;
				this.owner.name = app.Owner.Name;
			}
			this.agentNotes = app.Agent_Notes__c;
			this.myAppUserStatus = app.MyApp_User_Status__c;
			this.delegatorOrgUnitCode = app.Delegator_Org_Unit_Code__c;
		}
	}

	/**
	 * @description The Applicant class represents an applicant in the context of an application.
	 *              It contains the Id and CRM Contact Id of the applicant.
	 */
	public class Applicant {
		// invalid error reported
		// The instance property name 'Id' doesn't match '[a-z][a-zA-Z0-9]*' (rule: Code Style-PropertyNamingConventions)apex pmdPropertyNamingConventions
		@SuppressWarnings('PMD.PropertyNamingConventions')
		public String Id { get; set; }
		public String crmContactId { get; set; }
	}

	/** @description CDM_Country*/
	public class Country {
		public String uniqueCountryExternalId;
		public String crmRecordId;
		public String isoalpha2;
		public String isoalpha3;
		public String callistaCode;
		public String name;
		public String country;
	}
	/**
	 * @description owner id and name of owner
	 */
	public class Owner {
		String Id;
		String Name;
	}

	/**
	 * @description  Work Experience wrapper
	 */
	public class WorkExperienceWrapper {
		public String id { get; set; }
		public String externalId { get; set; }
		public String position { get; set; }
		public String employerName { get; set; }
		public Date startDate { get; set; }
		public Date endDate { get; set; }
		public Country country { get; set; }
		public String contactPersonFirstName { get; set; }
		public String contactPersonLastName { get; set; }
		public String contactPersonEmail { get; set; }
		public String contactPersonPhone { get; set; }
		public WorkExperienceWrapper() {
			this.country = new Country();
			// Default constructor
		}
		/**
		 * @description WorkExperienceWrapper construcor taking Work_Experience__c record as param
		 * @author Ben Greenland | 2024-10-02
		 * @param  workExperience Work_Experience__c
		 **/
		public WorkExperienceWrapper(Work_Experience__c workExperience) {
			this.id = workExperience.Id;
			this.externalId = workExperience.External_ID__c;
			this.position = workExperience.Position__c;
			this.employerName = workExperience.Employer_Name__c;
			this.startDate = workExperience.Start_Date__c;
			this.endDate = workExperience.End_Date__c;
			if (workExperience.Country__r != null) {
				this.country = new Country();
				this.country.uniqueCountryExternalId = workExperience?.Country__r?.uniqueCountryExternalId__c;
				this.country.crmRecordId = workExperience.Country__r.Id != null ? workExperience.Country__r.Id : null;
				this.country.isoalpha2 = workExperience.Country__r != null ? workExperience.Country__r.ISO_Alpha_2__c : null;
				this.country.name = workExperience.Country__r.Name;
			}
			this.contactPersonFirstName = workExperience.Contact_Person_First_Name__c;
			this.contactPersonLastName = workExperience.Contact_Person_Last_Name__c;
			this.contactPersonEmail = workExperience.Contact_Person_Email__c;
			this.contactPersonPhone = workExperience.Contact_Person_Phone__c;
		}
		/**
		 * @description Converts a list of Work_Experience__c records to a list of WorkExperienceWrapper objects.
		 * @param workExperienceList The list of Work_Experience__c records to convert.
		 * @return A list of WorkExperienceWrapper objects.
		 */
		public List<WorkExperienceWrapper> fromWorkExperienceList(List<Work_Experience__c> workExperienceList) {
			List<WorkExperienceWrapper> wrapperList = new List<WorkExperienceWrapper>();
			for (Work_Experience__c workExperience : workExperienceList) {
				wrapperList.add(new WorkExperienceWrapper(workExperience));
			}
			return wrapperList;
		}
	}

	/**
	 * @description Contact Qualification Wrapper
	 */
	public class ContactQualificationWrapper extends ApplicationWSWrapper.ContactQualificationWrapper {
		// public String id { get; set; }
		// public Boolean isDeleted { get; set; }
		// public String name { get; set; }
		// public String currencyIsoCode { get; set; }
		// public String recordTypeId { get; set; }
		// public String createdDate { get; set; }
		// public String createdById { get; set; }
		// public String lastModifiedDate { get; set; }
		// public String lastModifiedById { get; set; }
		// public String systemModstamp { get; set; }
		// public String lastViewedDate { get; set; }
		// public String lastReferencedDate { get; set; }
		// public String contact { get; set; }
		// public Date dateAchieved { get; set; }
		// public Boolean isEnglishInstruction { get; set; }
		// public String qualificationName { get; set; }
		// public String qualificationType { get; set; }
		// public String qualification { get; set; }
		// public String score { get; set; }
		// public Boolean isTestCompleted { get; set; }
		// public Double referenceCount { get; set; }
		// public String listening { get; set; }
		// public String reading { get; set; }
		// public String speaking { get; set; }
		// public String writing { get; set; }
		// public String verificationStatus { get; set; }
		// public Boolean honoraryDegree { get; set; }
		// public Boolean primary { get; set; }
		// public Boolean deletedOnSource { get; set; }
		// public String relevantQualificationName { get; set; }
		// public Boolean usaAccredited { get; set; }
		// public String externalId { get; set; }
		// public String crmId { get; set; }
		// public String tertiaryQualificationLevel { get; set; }
		// public String qualificationCountry { get; set; }
		// public String otherQualification { get; set; }
		// public String otherQualificationComments { get; set; }
		// public String institutionName { get; set; }
		// public String title { get; set; }
		// public String testOfWrittenEnglish { get; set; }
		// public String yearOfCompletion { get; set; }
		// public String monashEquivalentGPA { get; set; }
		// public String gpaScale { get; set; }
		// public String gpaCalcMethod { get; set; }
		// public String honoryDegree { get; set; }
		// public String relevantInstitutionName { get; set; }
		// public String status { get; set; }
		// public String state { get; set; }
		// public String institutionCode { get; set; }
		// public String otherInstitution { get; set; }
		// public String firstYearEnrolled { get; set; }
		// public String stateProvince { get; set; }
		// public Date expectedCompletionDate { get; set; }
		// public String lastYearEnrolled { get; set; }
		// public ContactQualificationWrapper() {
		// 	this.qualificationCountry = '';
		// 	// Default constructor
		// }

		/**
		 * @description ContactQualificationWrapper constructor taking Contact_Qualification__c record as param
		 * @param  contactQualification Contact_Qualification__c
		 */
		public ContactQualificationWrapper() {
         super();
      }
		public ContactQualificationWrapper(Contact_Qualification__c contactQualification) {
			super(contactQualification);
				}		// 	this.id = contactQualification.Id;
		// 	this.isDeleted = contactQualification.IsDeleted;
		// 	this.name = contactQualification.Name;
		// 	this.currencyIsoCode = contactQualification.CurrencyIsoCode;
		// 	this.recordTypeId = contactQualification.RecordTypeId;
		// 	this.createdDate = contactQualification?.CreatedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
		// 	this.createdById = contactQualification.CreatedById;
		// 	this.lastModifiedDate = contactQualification?.LastModifiedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
		// 	this.lastModifiedById = contactQualification?.LastModifiedById;
		// 	this.systemModstamp = contactQualification?.SystemModstamp?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
		// 	this.lastViewedDate = contactQualification?.LastViewedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
		// 	this.lastReferencedDate = contactQualification?.LastReferencedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
		// 	this.contact = contactQualification.Contact__c;
		// 	this.dateAchieved = contactQualification.Date_Achieved__c;
		// 	this.isEnglishInstruction = contactQualification.Instruction_in_English__c;
		// 	this.qualificationName = contactQualification.Qualification_Name__c;
		// 	this.qualificationType = contactQualification.Qualification_Type__c;
		// 	this.qualification = contactQualification.Qualification__c;
		// 	this.score = contactQualification.Score__c;
		// 	this.isTestCompleted = contactQualification.isTestCompleted__c;
		// 	this.referenceCount = contactQualification.Reference_Count__c;
		// 	this.listening = contactQualification.Listening__c;
		// 	this.reading = contactQualification.Reading__c;
		// 	this.speaking = contactQualification.Speaking__c;
		// 	this.writing = contactQualification.Writing__c;
		// 	this.verificationStatus = contactQualification.Verification_Status__c;
		// 	this.honoraryDegree = contactQualification.Honorary_Degree__c;
		// 	this.primary = contactQualification.Primary__c;
		// 	this.deletedOnSource = contactQualification.deleted_on_source__c;
		// 	this.relevantQualificationName = contactQualification.Relevant_Qualification_Name__c;
		// 	this.usaAccredited = contactQualification.USA_Accredited__c;
		// 	this.externalId = contactQualification.External_ID__c;
		// 	this.crmId = contactQualification.CRM_Id__c;
		// 	this.tertiaryQualificationLevel = contactQualification.Tertiary_Qualification_Level__c;
		// 	this.qualificationCountry = contactQualification.Qualification_Country__c;
		// 	this.otherQualification = contactQualification.Other_Qualification__c;
		// 	this.otherQualificationComments = contactQualification.Other_Qualification_Comments__c;
		// 	this.institutionName = contactQualification.Institution_Name__c;
		// 	this.title = contactQualification.Title__c;
		// 	this.testOfWrittenEnglish = contactQualification.Test_of_Written_English__c;
		// 	this.yearOfCompletion = contactQualification.Year_of_Completion__c;
		// 	this.monashEquivalentGPA = contactQualification.Monash_Equivalent_GPA__c;
		// 	this.gpaScale = contactQualification.Qualification_GPA_Scale__c;
		// 	this.gpaCalcMethod = contactQualification.Qualification_GPA_Calc_Method__c;
		// 	this.honoraryDegree = contactQualification.Honorary_Degree__c;
		// 	this.status = contactQualification.Status__c;
		// 	this.state = contactQualification.State__c;
		// 	this.institutionCode = contactQualification.Institution_Code__c;
		// 	this.otherInstitution = contactQualification.Other_Institution__c;
		// 	this.firstYearEnrolled = contactQualification.First_Year_Enrolled__c;
		// 	this.relevantInstitutionName = contactQualification.Relevant_Institution_Name__c;
		// 	this.stateProvince = contactQualification.State_Province__c;
		// 	this.expectedCompletionDate = contactQualification.Expected_date_of_completion__c;
		// 	this.lastYearEnrolled = contactQualification.Last_Year_Enrolled__c;
		// }

		/**
		 * @description Converts a list of Contact_Qualification__c records to a list of ContactQualificationWrapper objects.
		 * @param contactQualifications The list of Contact_Qualification__c records to convert.
		 * @return A list of ContactQualificationWrapper objects.
		 */
	// 	public override List<ApplicationWSWrapper.ContactQualificationWrapper> fromObjectList(List<Contact_Qualification__c> contactQualifications) {
	// 		List<ApplicationWSWrapper.ContactQualificationWrapper> wrapperList = new List<ApplicationWSWrapper.ContactQualificationWrapper>();
	// 		for (Contact_Qualification__c conQual : contactQualifications) {
	// 			 wrapperList.add(new APNGApplicationPayload.ContactQualificationWrapper(conQual));
	// 		}
	// 		return wrapperList;
	//   }
	
	}

	/** @description ApplicationCoursePreference wrapper */
	public class ApplicationCoursePreference {
		public Id id { get; set; }
		public Boolean courseOfferingActive { get; set; }
		public Integer courseStartYear { get; set; }
		public Date calendarStartDate { get; set; }
		public Id applicationId { get; set; }
		public String applicationName { get; set; }
		public Id courseId { get; set; }
		public Id courseOfferingCourseId { get; set; }
		public String courseCode { get; set; }
		public Integer courseVersionNumber { get; set; }
		public String courseTitle { get; set; }
		public String unitSetCode { get; set; }
		public String locationCode { get; set; }
		public String documentationStatusSystemCode { get; set; }
		public String documentationStatusValue { get; set; }
		public String entryQualificationStatusSystemCode { get; set; }
		public String entryQualificationStatusValue { get; set; }
		public String outcomeStatusSystemCode { get; set; }
		public String outcomeStatusValue { get; set; }
		public String offerResponseStatusValue { get; set; }
		public String offerCondition { get; set; }
		public Date offerDate { get; set; }
		public Date offerResponseDate { get; set; }
		public String offerResponseStatusSystemCode { get; set; }
		public Date actualOfferResponseDate { get; set; }
		public String defermentStatusSystemCode { get; set; }
		public String admissionCalendarType { get; set; }
		public String commencementPeriod { get; set; }
		public String managingFaculty { get; set; }
		public String unitSetDescription { get; set; }
		public String status { get; set; }
		public String preferenceNumber { get; set; }
		public String lastModifiedDate { get; set; }
		public String conditionalOfferStatusValue { get; set; }
		public String defermentStatusValue { get; set; }
		public Date conditionalOfferSatisfiedDate { get; set; }
		public String acpId { get; set; }
		public String externalId { get; set; }
		public Boolean isStudentPassAvailable { get; set; }
		public ApplicationCoursePreference() {
			this.isStudentPassAvailable = false;
			// Default constructor
		}
		/**
		 * @description ApplicationCoursePreference constructor
		 * @param acpRecord Application_Course_Preference__c
		 * @author Ben Greenland | 2024-10-02
		 **/
		public ApplicationCoursePreference(Application_Course_Preference__c acpRecord) {
			this.id = acpRecord.Id;
			this.courseOfferingActive = acpRecord.Course_Offering__r.Active__c;
			this.courseStartYear = acpRecord.Course_Start_Year__c != null
				? Integer.valueOf(acpRecord.Course_Start_Year__c)
				: null;
			this.calendarStartDate = acpRecord.Calendar_Start_Date__c;
			this.applicationId = acpRecord.application__c;
			this.applicationName = acpRecord.Application__r.Name;
			this.courseId = acpRecord.Course__c;
			this.courseOfferingCourseId = acpRecord.Course_Offering__r.Course__r.id;
			this.courseCode = acpRecord.Course_Code__c;
			this.courseVersionNumber = acpRecord.Course_Version_Number__c != null
				? Integer.valueOf(acpRecord.Course_Version_Number__c)
				: null;
			this.courseTitle = acpRecord.Course_Title__c;
			this.unitSetCode = acpRecord.Unit_Set_Code__c;
			this.locationCode = acpRecord.Location_Code__c;
			this.documentationStatusSystemCode = acpRecord.Documentation_Status_LOV__r.System_Code__c;
			this.documentationStatusValue = acpRecord.Documentation_Status_LOV__r.Value__c;
			this.entryQualificationStatusSystemCode = acpRecord.Entry_Qualification_Status_LOV__r.System_Code__c;
			this.entryQualificationStatusValue = acpRecord.Entry_Qualification_Status_LOV__r.Value__c;
			this.outcomeStatusSystemCode = acpRecord.Outcome_Status_LOV__r.System_Code__c;
			this.outcomeStatusValue = acpRecord.Outcome_Status_LOV__r.Value__c;
			this.offerResponseStatusValue = acpRecord.Offer_Response_Status_LOV__r.Value__c;
			this.offerCondition = acpRecord.Offer_Condition__c;
			this.offerDate = acpRecord.Offer_Date__c;
			this.offerResponseDate = acpRecord.Offer_Response_Date__c;
			this.offerResponseStatusSystemCode = acpRecord.Offer_Response_Status_LOV__r.System_Code__c;
			this.actualOfferResponseDate = acpRecord.Actual_Offer_Response_Date__c;
			this.defermentStatusSystemCode = acpRecord.Deferment_Status_LOV__r.System_Code__c;
			this.admissionCalendarType = acpRecord.Admission_Calendar_Type__c;
			this.commencementPeriod = acpRecord.Commencement_Period__c;
			this.managingFaculty = acpRecord.Managing_Faculty__c;
			this.unitSetDescription = acpRecord.Unit_Set_Description__c;
			this.status = acpRecord.Status__c;
			this.preferenceNumber = acpRecord.Preference_Number__c;
			this.lastModifiedDate = acpRecord.LastModifiedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.conditionalOfferStatusValue = acpRecord.Conditional_Offer_Status_LOV__r.Value__c;
			this.defermentStatusValue = acpRecord.Deferment_Status_LOV__r.Value__c;
			this.conditionalOfferSatisfiedDate = acpRecord.Conditional_Offer_Satisfied_Date__c;
			this.acpId = acpRecord.ACP_ID__c;
			this.externalId = acpRecord.External_Id__c;
		}
		/**
		 * @description Converts a list of Application_Course_Preference__c records to a list of ApplicationCoursePreference objects.
		 * @param acpList The list of Application_Course_Preference__c records to convert.
		 * @return A list of ApplicationCoursePreference objects.
		 */
		public List<ApplicationCoursePreference> fromObjectList(List<Application_Course_Preference__c> acpList) {
			List<ApplicationCoursePreference> wrapperList = new List<ApplicationCoursePreference>();
			for (Application_Course_Preference__c acp : acpList) {
				wrapperList.add(new ApplicationCoursePreference(acp));
			}
			return wrapperList;
		}
	}
	
	/**
	 * CDM_Application extends ApplicationWSWrapper.CDM_Application and all the properties are same as CDM_Application
	 */
	public class CDM_Application extends ApplicationWSWrapper.CDM_Application {
		public CDM_Application() {
			super();
			Nebula.logger.info('CDM_Application constructor called');
			this.coursePreferences = new List<CDM_ApplicationCoursePreference>{};
		}
	}
}