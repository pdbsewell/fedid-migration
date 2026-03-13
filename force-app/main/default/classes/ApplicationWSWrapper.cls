/**
 * @description Application Webservice wrapper virtual class. This contains the shared payload classes for the Application Webservice.
 * Client speicifc for OES or APNG are in their respective
 * Payload classes and overrides the properties as required.
 * @author      Girish P
 * @since       NOV 12.2024
 * @group Application Webservice v3
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount')

// workaround to block requiring ApexDoc for getter/setters
public inherited sharing virtual class ApplicationWSWrapper {//NOPMD
	/** @description ApplicationException*/
	public class ApplicationException extends RestLib_Ex.ListException {
	}
	public RESTlib_Ex.InvalidRequestException exceptions;
	/**
	 * @description Application__c related data for the Application Webservice
	 */
	@SuppressWarnings('PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount')

	public abstract class CDM_Application {
		/**
		 * @description Reference for the application.
		 */
		public String applicationREF { get; set; }

		/**
		 * @description SMS Applicant ID.
		 */
		public String smsApplicantId { get; set; }

		/**
		 * @description CRM Contact ID (CRM_ID__c). This is the unique identifier for the applicant eg C-A122902
		 */
		public String crmContactId { get; set; } // CRM_ID__c

		/**
		 * @description Application ID (Name). This is the unique identifier for the application eg A-122902
		 */
		public String applicationId { get; set; } // Name

		/**
		 * @description Status of the application. eg. Draft, Submitted, Agent Declaration Accepted
		 */
		public String applicationStatus { get; set; }

		/**
		 * @description Notes from the agent.
		 */
		public String agentNotes { get; set; }

		/**
		 * @description Type of the application. eg. New, Transfer, Re-Admit
		 */
		public String applicationType { get; set; }

		/**
		 * @description Residency status of the applicant. eg. Domestic, International
		 */
		public String residencyStatus { get; set; }

		/**
		 * @description Access and equity question response. eg. Yes, No
		 */
		public String accessAndEquityQuestion { get; set; }

		/**
		 * @description Passport number of the applicant.
		 */
		public String passportNumber { get; set; }

		/**
		 * @description Indicates if the applicant has a disability.
		 */
		public Code hasDisability { get; set; }

		/**
		 * @description Status of existing disability support.
		 */
		public Status existingDisabilitySupport { get; set; }

		/**
		 * @description Indicates if this is a principal course transfer.
		 */
		public Boolean isPrincipalCourseTransfer { get; set; }

		/**
		 * @description Indicates if the applicant has requested a scholarship.
		 */
		public Boolean hasRequestForScholarship { get; set; }

		/**
		 * @description Indicates if the applicant has requested advanced standing.
		 */
		public Boolean hasRequestForAdvancedStanding { get; set; }

		/**
		 * @description Indicates if the applicant has English language proficiency.
		 */
		public Boolean englishLanguageProficiency { get; set; }
		/** @descitption how english profoicent requirements are met */
		public String englishProficiencyRequirement { get; set; }
		/**
		 * @description Indicates if the applicant has opted in for the Monash English program.
		 */
		public String optInMonashEnglishProgram { get; set; }
		/**
		 * @description Scholarship sponsor information.
		 */
		public String sponsorScholarship { get; set; }

		/**
		 * @description Indicates if the student pass is available.
		 */
		public Boolean isStudentPassAvailable { get; set; }

		/**
		 * Status of the sponsor
		 */
		public Status sponsorStatus { get; set; }
		// This field is only used for OES and APNG does not rely on this
		// This is populated by OES when application is created and has opportunity ID from their system
		public String externalReferenceId;
		public String delegatorOrgUnitCode { get; set; }
		/**
		 * @description Visa details of the applicant.
		 */
		public CDM_Visa visa { get; set; }

		/**
		 * @description List of course preferences for the application.
		 */
		public List<CDM_ApplicationCoursePreference> coursePreferences { get; set; }

		/**
		 * @description List of qualifications of the applicant.
		 */
		public List<CDM_Qualification> qualifications { get; set; }

		/**
		 * @description List of work experiences of the applicant.
		 */
		public List<CDM_WorkExperience> workExperiences { get; set; }

		/**
		 * @description Payment details for the application.
		 */
		public CDM_Payment payment { get; set; } /**
		 * @description asApplicationRecord method parse all the application data and return Application__c record
		 * @return Application__c
		 */
		@TestVisible
		public virtual Application__c asApplicationRecord() {
			Application__c app;
			try {
				app = [
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
						WHERE NAME = :this.applicationId
						LIMIT 1
				];
			} catch (QueryException e) {
				throw new RestLib_Ex.WebServiceException('Application record not found or not accessible.');
			}
			try {
				Nebula.Logger.info('CDM_Application.asApplicationRecord Processing: ' + applicationId);
				/**
				 * for OES, if the Application is already in a submitted state, it implies that
				 * This is a subsequent update call post-transfer job in order to recover the
				 * previous ACP statuses that may have been overwritten.
				 *
				 * In this case, we simply return the current state of the Application and only
				 * allow updates on ACP
				 */
				if (OESApplicationService.isOESUser && app.Status__c == 'Submitted') {
					return app;
				}

				Contact applicant = AgentPortalServices.getContact(
						crmContactId,
						AgentPortalConstants.APPLICANT_PERSONA,
						AgentPortalConstants.USER_CONTEXT
				);
				applicationREF = app.Name;
				// SFTG-3691 - Application may be reverted to Draft anytime before Agent Declaration, even after Student Acceptance
				if (
						AgentPortalConstants.DRAFT_STATUSES.contains(this.applicationStatus) &&
								AgentPortalConstants.STATUSES_REVERTIBLE_TO_DRAFT.contains(app.Status__c)
				) {
					app.Status__c = this.applicationStatus;
					return app;
				}

				if (String.isNotBlank(app.Status__c) && AffiliationCheckService.SUBMITTED_STATUSES.contains(app.Status__c)) {
					// For submitted applications, only Payments can be updated
					if (payment != null && this.applicationStatus.equalsIgnoreCase(app.Status__c)) {
						payment.applicationRecord = app;
						payment.addPaymentDetailsToApplication();
						return app;
					}
				}
				app.applicant__c = applicant?.Id;
				if (
						String.isNotBlank(applicationStatus) &&
								!AffiliationCheckService.SUBMITTED_STATUSES.contains(applicationStatus)
				) {
					app.status__c = applicationStatus;

					// No changes other than timestamp allowed during Agent Declaration
					if (applicationStatus.equalsIgnoreCase('Agent Declaration Accepted')) {
						app.Agent_Accepted_Timestamp__c = Datetime.now();
						return app;
					}
				}
				app.Application_Type__c = applicationType;
				app.is_Principal_Course_Transfer__c = isPrincipalCourseTransfer != null ? isPrincipalCourseTransfer : false;
				app.Student_Pass_Availability__c = resolveYesNoPicklist(isStudentPassAvailable);
				app.English_Language_Proficiency__c = resolveYesNoPicklist(englishLanguageProficiency);
				app.English_Proficiency_Requirement__c = englishProficiencyRequirement;
				app.English_Program_Consideration__c = optInMonashEnglishProgram;
				if (residencyStatus != null) {
					app.Residency_Sub_status__c = residencyStatus.contains('.') ? residencyStatus : ''; // DOM-SUN
					app.Residency_Status__c = residencyStatus.split('\\.')[0]; // DOM-SUN
				}
				app.Sponsor_Name__c = sponsorScholarship;
				app.Sponsor_Scholarship_organisation__c = sponsorScholarship;
				app.Sponsorship_Status__c = sponsorStatus != null ? this.sponsorStatus.code : null;
				app.Credit_Intention__c = hasRequestForAdvancedStanding != null ? hasRequestForAdvancedStanding : false;
				app.Is_Sponsored__c = hasRequestForScholarship != null ? hasRequestForScholarship : false;
				app.Sponsorship_Type__c = app.Is_Sponsored__c ? 'Sponsorship' : 'No';
				app.Passport_Number__c = passportNumber;
				app.HasDisabilities__c = hasDisability != null ? hasDisability.code : null;
				app.Existing_Aus_disability_support__c = existingDisabilitySupport != null
						? existingDisabilitySupport.code
						: null;
				// 
				// app.External_Reference_Id__c = externalReferenceId;
				app.Delegator_Org_Unit_Code__c = delegatorOrgUnitCode;
				if (visa != null) {
					visa.applicationRecord = app;
					visa.addVisaDetailsToApplication();
				}
				if (!OESApplicationService.isOESUSer && payment != null) {
					payment.applicationRecord = app;
					payment.addPaymentDetailsToApplication();
				} else if (OESApplicationService.isOESUSer) {
					app.Fee_Payment__c = false;
				}
				app.Agent_Notes__c = agentNotes;
				return app;
			} catch (Exception ex) {
				Nebula.Logger.error('Exception in CDM_Application.asApplicationRecord: ', ex)
						.addTag('ApplicationWebservice:' + applicationId);
				throw new RestLib_Ex.WebServiceException(ex.getMessage());
			}
		}
	}
	/** @description ApplicationDetails response payload for PATCH*/

	public virtual class ApplicationResponseWrapper {
		public ApplicationWrapper application;
	}

	/** @description ApplicationDetails response payload for PATCH*/
	public virtual class ApplicationWrapper {
		public List<ContactQualificationWrapper> qualifications;
		public List<WorkExperienceWrapper> workExperiences;
		public List<ApplicationCoursePreference> coursePreferences;
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
		// This field is only used for OES and APNG does not rely on this
		// This is populated by OES when application is created and has opportunity ID from their system
		public String externalReferenceId;
		public String delegatorOrgUnitCode { get; set; }
		public ApplicationWrapper() {
			this.qualifications = new List<ContactQualificationWrapper>();
			this.workExperiences = new List<WorkExperienceWrapper>();
			this.coursePreferences = new List<ApplicationCoursePreference>();
		}
		/**
		 * @description ApplicationWrapper constructor
		 * @author Ben Greenland | 2024-10-02
		 * @param  app Application__c
		 **/
		public ApplicationWrapper(Application__c app) {
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
			}

			// Map Single Entry Visa
			if (app.Single_Entry_Visa__r != null) {
				this.singleEntryVisa = new Country();
				this.singleEntryVisa.uniqueCountryExternalId = app.Single_Entry_Visa__r?.uniqueCountryExternalId__c;
				this.singleEntryVisa.crmRecordId = app.Single_Entry_Visa__r?.Id != null ? app.Single_Entry_Visa__r.Id : null;
				this.singleEntryVisa.isoalpha2 = app.Single_Entry_Visa__r?.ISO_Alpha_2__c;
				this.singleEntryVisa.name = app.Single_Entry_Visa__r?.Name;
				this.singleEntryVisa.country = app.Single_Entry_Visa__r?.Country__c;
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
	 * @description Apex version of the Country attribute object
	 */
	public virtual class Country {
		public Id id { get; set; } // record Id
		public String name { get; set; } // Name
		public String callistaCode { get; set; } // Callista_Code__c
		public String callistaCountry { get; set; } // Callista_Country__c
		public String uniqueCountryExternalId { get; set; } // uniqueCountryExternalId__c
		public String crmRecordId { get; set; } // crmRecordId__c
		public String isoalpha2;
		public String country;
	}
	// 	/** @description CDM_Country*/
	public virtual class CDM_Country {
		public String uniqueCountryExternalId;
		public String crmRecordId;
		public String isoalpha2;
		public String name;
		public String code;
		public String value;
		public String country;
	}

	/**
	 * @description The Applicant virtual class represents an applicant in the context of an application.
	 *              It contains the Id and CRM Contact Id of the applicant.
	 */
	public virtual class Applicant {
		@SuppressWarnings('PMD.PropertyNamingConventions')
		public String Id { get; set; }
		public String crmContactId { get; set; }
	}

	/**
	 * @description owner id and name
	 */
	public virtual class Owner {
		String Id;
		String Name;
	}
	/**
	 * @description  Work Experience wrapper
	 */
	public virtual class WorkExperienceWrapper {
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

		/**
		 * @description WorkExperienceWrapper constructor
		 * @author Ben Greenland | 2024-10-02
		 **/
		public WorkExperienceWrapper() {
			this.id = '';
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
		public virtual List<WorkExperienceWrapper> fromWorkExperienceList(List<Work_Experience__c> workExperienceList) {
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
	public virtual class ContactQualificationWrapper {
		public String id { get; set; }
		// public Boolean isDeleted { get; set; }
		public String name { get; set; }
		public String currencyIsoCode { get; set; }
		public String recordTypeId { get; set; }
		public String createdDate { get; set; }
		public String createdById { get; set; }
		public String lastModifiedDate { get; set; }
		public String lastModifiedById { get; set; }
		public String systemModstamp { get; set; }
		public String lastViewedDate { get; set; }
		public String lastReferencedDate { get; set; }
		public String contact { get; set; }
		public Date dateAchieved { get; set; }
		public Boolean isEnglishInstruction { get; set; }
		public String qualificationName { get; set; }
		public String qualificationType { get; set; }
		public String qualification { get; set; }
		public String score { get; set; }
		public Boolean isTestCompleted { get; set; }
		public Double referenceCount { get; set; }
		public CDM_DocumentDetails documentDetails { get; set; }
		public String listening { get; set; }
		public String reading { get; set; }
		public String speaking { get; set; }
		public String writing { get; set; }
		public String verificationStatus { get; set; }
		public Boolean honoraryDegree { get; set; }
		public Boolean primary { get; set; }
		public Boolean deletedOnSource { get; set; }
		public String relevantQualificationName { get; set; }
		public Boolean usaAccredited { get; set; }
		public String externalId { get; set; }
		public String crmId { get; set; }
		public String tertiaryQualificationLevel { get; set; }
		public String qualificationCountry { get; set; }
		public String otherQualification { get; set; }
		public String otherQualificationComments { get; set; }
		public String institutionName { get; set; }
		public String title { get; set; }
		public String testOfWrittenEnglish { get; set; }
		public String yearOfCompletion { get; set; }
		public String monashEquivalentGPA { get; set; }
		public String gpaScale { get; set; }
		public String gpaCalcMethod { get; set; }
		public String honoryDegree { get; set; }
		public String relevantInstitutionName { get; set; }
		public String status { get; set; }
		public String state { get; set; }
		public String institutionCode { get; set; }
		public String otherInstitution { get; set; }
		public String firstYearEnrolled { get; set; }
		public String stateProvince { get; set; }
		public Date expectedCompletionDate { get; set; }
		public String lastYearEnrolled { get; set; }
		/**
		 * @description ContactQualificationWrapper constructor
		 */
		public ContactQualificationWrapper() {
			this.qualificationCountry = '';
			//Constructor
		}

		/**
		 * @description ContactQualificationWrapper constructor taking Contact_Qualification__c record as param
		 * @param  contactQualification Contact_Qualification__c
		 */
		public ContactQualificationWrapper(Contact_Qualification__c contactQualification) {
			this.documentDetails = new CDM_DocumentDetails();
			this.id = contactQualification.Id;
			// this.isDeleted = contactQualification.IsDeleted;
			this.name = contactQualification.Name;
			// this.currencyIsoCode = contactQualification.CurrencyIsoCode;
			// this.recordTypeId = contactQualification.RecordTypeId;
			this.createdDate = contactQualification?.CreatedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.createdById = contactQualification.CreatedById;
			this.lastModifiedDate = contactQualification?.LastModifiedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.lastModifiedById = contactQualification?.LastModifiedById;
			this.systemModstamp = contactQualification?.SystemModstamp?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.lastViewedDate = contactQualification?.LastViewedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.lastReferencedDate = contactQualification?.LastReferencedDate?.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
			this.contact = contactQualification.Contact__c;
			this.dateAchieved = contactQualification.Date_Achieved__c;
			this.isEnglishInstruction = contactQualification.Instruction_in_English__c;
			this.qualificationName = contactQualification.Qualification_Name__c;
			this.qualificationType = contactQualification.Qualification_Type__c;
			this.qualification = contactQualification.Qualification__c;
			this.score = contactQualification.Score__c;
			this.isTestCompleted = contactQualification.isTestCompleted__c;
			this.referenceCount = contactQualification.Reference_Count__c;
			// Document details. Generally they will be available for English test via automated verification in my.app or agent portal
			this.documentDetails.documentIdentifier = contactQualification.English_Test_Number__c;
			this.documentDetails.documentExpiryDate = contactQualification.English_Test_Expiry_Date__c;
			this.documentDetails.documentSource = contactQualification.Source_Channel__c;
			this.listening = contactQualification.Listening__c;
			this.reading = contactQualification.Reading__c;
			this.speaking = contactQualification.Speaking__c;
			this.writing = contactQualification.Writing__c;
			this.verificationStatus = contactQualification.Verification_Status__c;
			this.honoraryDegree = contactQualification.Honorary_Degree__c;
			this.primary = contactQualification.Primary__c;
			this.deletedOnSource = contactQualification.deleted_on_source__c;
			this.relevantQualificationName = contactQualification.Relevant_Qualification_Name__c;
			this.usaAccredited = contactQualification.USA_Accredited__c;
			this.externalId =contactQualification.External_ID__c!=null?contactQualification.External_ID__c:contactQualification.name;
			this.crmId = contactQualification.CRM_Id__c;
			this.tertiaryQualificationLevel = contactQualification.Tertiary_Qualification_Level__c;
			this.qualificationCountry = contactQualification.Qualification_Country__c;
			this.otherQualification = contactQualification.Other_Qualification__c;
			this.otherQualificationComments = contactQualification.Other_Qualification_Comments__c;
			this.institutionName = contactQualification.Institution_Name__c;
			this.title = contactQualification.Title__c;
			this.testOfWrittenEnglish = contactQualification.Test_of_Written_English__c;
			this.yearOfCompletion = contactQualification.Year_of_Completion__c;
			this.monashEquivalentGPA = contactQualification.Monash_Equivalent_GPA__c;
			this.gpaScale = contactQualification.Qualification_GPA_Scale__c;
			this.gpaCalcMethod = contactQualification.Qualification_GPA_Calc_Method__c;
			this.honoraryDegree = contactQualification.Honorary_Degree__c;
			this.status = contactQualification.Status__c;
			this.state = contactQualification.State__c;
			this.institutionCode = contactQualification.Institution_Code__c;
			this.otherInstitution = contactQualification.Other_Institution__c;
			this.firstYearEnrolled = contactQualification.First_Year_Enrolled__c;
			this.relevantInstitutionName = contactQualification.Relevant_Institution_Name__c;
			this.stateProvince = contactQualification.State_Province__c;
			this.expectedCompletionDate = contactQualification.Expected_date_of_completion__c;
			this.lastYearEnrolled = contactQualification.Last_Year_Enrolled__c;
		}
		// Factory method to allow subclassing
		protected virtual ContactQualificationWrapper createInstance(Contact_Qualification__c record) {
			return new ContactQualificationWrapper(record);
		}
		/**
		 * @description Converts a list of Contact_Qualification__c records to a list of ContactQualificationWrapper objects.
		 * @param contactQualifications The list of Contact_Qualification__c records to convert.
		 * @return A list of ContactQualificationWrapper objects.
		 */
		public virtual List<ContactQualificationWrapper> fromObjectList(
				List<Contact_Qualification__c> contactQualifications
		) {
			List<ContactQualificationWrapper> wrapperList = new List<ContactQualificationWrapper>();
			for (Contact_Qualification__c conQual : contactQualifications) {
				wrapperList.add(createInstance(conQual));
			}
			return wrapperList;
		}
	}

	/** @description ApplicationCoursePreference wrapper */
	public virtual class ApplicationCoursePreference {
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

		/**
		 * @description ApplicationCoursePreference constructor
		 * @author Ben Greenland | 2024-10-02
		 **/
		public ApplicationCoursePreference() {
			this.isStudentPassAvailable=false;
			//constructor
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
		public virtual List<ApplicationCoursePreference> fromObjectList(List<Application_Course_Preference__c> acpList) {
			List<ApplicationCoursePreference> wrapperList = new List<ApplicationCoursePreference>();
			for (Application_Course_Preference__c acp : acpList) {
				wrapperList.add(new ApplicationCoursePreference(acp));
			}
			return wrapperList;
		}
	}
	/**
	 * @description Apex version of the Email object
	 */
	public virtual class Email {
		public String type { get; set; }
		public String email { get; set; }
	}

	/**
	 * @description Apex version of the Phone object
	 */
	public virtual class Phone {
		public String type { get; set; }
		public String phoneNumber { get; set; }
	}

	public virtual class Status {
		public String code;
		public String value;
	}
	public virtual class Code {
		public String code { get; set; }
	}

	public virtual class ContactPerson {
		public String firstName { get; set; }
		public String lastName { get; set; }
	}

	public virtual class CDM_Payment {
		public String mode;
		public String amount;
		public String transactionAmount;
		public String datePaid;
		public String transactionSource;
		public String transactionReference;
		public Boolean isPaid;
		public FeeWaiverCode feeWaiverCode;
		public Application__c applicationRecord;
		/**
		 * @description addPaymentDetailsToApplication
		 **/
		public void addPaymentDetailsToApplication() {
			if (mode != null) {
				applicationRecord.Fee_Payment_Mode__c = mode;
			}
			if (transactionSource != null) {
				applicationRecord.Transaction_Source__c = transactionSource;
			}
			if (transactionReference != null) {
				applicationRecord.Transaction_Reference__c = transactionReference;
			}
			if (isPaid != null) {
				applicationRecord.Fee_Payment__c = isPaid;
			}
			if (feeWaiverCode != null) {
				applicationRecord.Fee_Waiver_Code__c = feeWaiverCode.code;
			}
			if (datePaid != null) {
				applicationRecord.Transaction_Date__c = Date.valueOf(datePaid);
			}
			if (amount != null) {
				applicationRecord.Fee_Amount__c = Decimal.valueOf(amount);
			}
			if (transactionAmount != null) {
				applicationRecord.Transaction_Amount__c = Decimal.valueOf(transactionAmount);
			}
		}
	}
	/** @description FeeWaiverCode*/
	public virtual class FeeWaiverCode {
		public String code;
		public String redeemed;
		public ValidityPeriod periodOfValidity;
	}

	/** @description ValidityPeriod*/
	public virtual class ValidityPeriod {
		public String startDate;
		public String endDate;
	}

	// Helper methods
	/**
	 * @description resolveYesNoPicklist
	 * @return String
	 * @param value
	 */
	public static String resolveYesNoPicklist(Boolean value) {
		return value != null ? (value ? 'Yes' : 'No') : null;
	}
	public virtual class CDM_ApplicationCoursePreference {
		/** @description crmRecordId */
		public String crmRecordId { get; set; }
		/** @description externalId */
		public String externalId { get; set; }
		/** @description courseOffering*/
		public CDM_CourseOffering courseOffering { get; set; }
		/** @description preference*/
		public Integer preference { get; set; }
		/** @description applicationRecord*/
		public Application__c applicationRecord { get; set; }
		public Contact applicantRecord;
		/**
		 * @description asACPRecord
		 * @return Application_Course_Preference__c
		 */
		public Application_Course_Preference__c asACPRecord() {
			Nebula.Logger.info('ApplicationCoursePreference.asACPRecord: ' + applicationRecord);
			Application_Course_Preference__c acp = new Application_Course_Preference__c();

			if (String.isNotBlank(crmRecordId)) {
				acp.id = crmRecordId;
			}
			if (courseOffering != null) {
				if (OESApplicationService.isOESUser) {
					acp.Course_Offering__r = new Course_Offering__c(Course_Offering_UID__c = courseOffering.courseOfferingUid);
				} else {
					acp.Course_Offering__c = courseOffering.crmRecordId;
				}
			} else {
				throw new RESTlib_Ex.InvalidRequestException('Course Offering cannot be empty.');
			}
			acp.Application__c = applicationRecord.id;
			acp.Applicant__c = applicationRecord.Applicant__c;
			acp.Preference_Number__c = '' + preference;
			return acp;
		}
	}
	/** @description CDM_CourseOffering*/
	public virtual class CDM_CourseOffering {
		public String crmRecordId;
		public Application__c applicationRecord;
		public String courseOfferingUid;
	}
	/**
	 * @description CDM_QualificationScore contains the score value and the score name
	 * and is used to represent the score of a qualification.
	 * This class has nested objects for score,
	 * qualification type - e.g. IELTS, TOEFL, PTE, etc. English language proficiency test
	 * and qualificationname - e.g. Listening, Reading, Writing, Speaking, etc.
	 */
	// NOPMD
	@SuppressWarnings('PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount')
	public virtual class CDM_Qualification {//NOPMD
		/**
		 * The CRM record ID of the qualification.
		 */
		public String crmRecordId;

		/**
		 * The type of the qualification.
		 */
		public CDM_QualificationType type;

		/**
		 * The name of the qualification.
		 */
		public CDM_QualificationName name;

		/**
		 * The start date of the qualification.
		 */
		public String startDate;

		/**
		 * The end date of the qualification.
		 */
		public String endDate;

		/**
		 * The country where the qualification was obtained.
		 */
		public CDM_Country countryObtained;

		/**
		 * The state where the qualification was obtained.
		 */
		public String stateObtained;

		/**
		 * The institution where the qualification was obtained.
		 */
		public CDM_Institution institution;

		/**
		 * The list of scores for the qualification.
		 */
		public List<CDM_QualificationScore> scores;

		/**
		 * The overall score for the qualification.
		 */
		public String score;

		/**
		 * The date when the qualification was conferred.
		 * Note: This field is not applicable for all tests.
		 */
		public String conferredDate;

		/**
		 * The expected date of completion for the qualification.
		 */
		public String expectedDateOfCompletion;

		/**
		 * The status of the qualification.
		 */
		public String status;

		/**
		 * The result type of the qualification.
		 * Example: Pass, Fail, etc.
		 */
		public String resultType; // SFTG-3704

		/**
		 * The verification status of the qualification.
		 * Example: Verified, Unverified, etc.
		 */
		public String verificationStatus; // SFTG-3704

		/**
		 * Indicates if the instruction was in English.
		 */
		public Boolean isEnglishInstruction;

		/**
		 * Additional comments about the qualification.
		 */
		public String qualificationComments;

		/**
		 * The unique external ID of the qualification.
		 */
		public String uniqueExternalId;

		/**
		 * The applicant record associated with the qualification.
		 */
		public Contact applicantRecord;
		// Document details for qualifications
		public CDM_DocumentDetails documentDetails;
		public CDM_Qualification() {
			this.documentDetails=new CDM_DocumentDetails();
		}
		public Boolean isHistoric {
			get {
				return isHistoric != null ? isHistoric : false;
			}
			set;
		}
		/**
		 * parse qualification to Contact_Qualification__c record
		 *
		 * @return  `Contact_Qualification__c`
		 */
		@SuppressWarnings('PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount')
		public Contact_Qualification__c asQualificationRecord() {
			Contact_Qualification__c conqual = new Contact_Qualification__c();
			if (String.isBlank(crmRecordId)) {
				conqual.Contact__c = applicantRecord.Id;
			}
			if (institution != null) {
				if (OESApplicationService.isOESUser) {
					conqual.Institution_Code__c = institution.institutionCode; //SFTG-3745
				} else {
					conqual.Institution_Code__c = institution.code;
				}
				if (String.isBlank(conqual.Institution_Code__c)) {
					conqual.Other_Institution__c = institution.value;
				} else {
					conqual.Institution_Name__c = institution.value;
				}
			}
			if (scores != null) {
				conqual = getScore(scores, conqual);
			}
			conqual.Score__c = score;
			conqual.Status__c = status;
			conqual.Instruction_in_English__c = isEnglishInstruction != null ? isEnglishInstruction : false;
			conqual.Other_Qualification_Comments__c = qualificationComments;
			conqual.Date_Achieved__c = String.isNotBlank(conferredDate) ? Date.valueOf(conferredDate) : null;
			conqual.isTestCompleted__c = String.isNotBlank(conferredDate) ? true : false;
			conqual.Expected_date_of_completion__c = expectedDateOfCompletion != null
					? Date.valueOf(expectedDateOfCompletion)
					: null;
			conqual.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName()
					.get(type.name)
					.getRecordTypeId();

			if (OESApplicationService.isOESUSer) {
				//SFTG-3745
				conqual.Unique_External_Id__c = uniqueExternalId; //type.qualificationUid;
				conqual.Qualification_Country__r = new Country_Attribute__c(
						uniqueCountryExternalId__c = countryObtained.uniqueCountryExternalId
				);
				conqual.Result_Type__c = resultType; //SFTG-3704
				conqual.Verification_Status__c = verificationStatus; //SFTG-3704
				if (String.isBlank(type.qualificationUid)) {
					conqual.Other_Qualification__c = type.qualificationName;
				} else {
					conqual.Qualification__r = new Qualification__c(Qualification_UID__c = type.qualificationUid);
				}
			} else {
				conqual.Id = crmRecordId;
				conqual.Qualification_Country__c = countryObtained != null ? countryObtained.crmRecordId : null;
				if (String.isBlank(type.crmRecordId)) {
					conqual.Other_Qualification__c = type.qualificationName;
				} else {
					conqual.Qualification__c = type.crmRecordId;
				}
			}
			if (documentDetails != null) {
				conqual.English_Test_Number__c = documentDetails.documentIdentifier;
				conqual.Source_Channel__c = documentDetails.documentSource;
				conqual.Verification_Status__c = (expectedDateOfCompletion != null)
						? 'Unknown'
						: (documentDetails.documentSource != null &&
								(documentDetails.documentSource.equalsIgnoreCase('IELTS') ||
										documentDetails.documentSource.equalsIgnoreCase('TOEFL')))
								? 'Score Verified'
								: 'Unverified';
			}

			switch on type.name {
				when 'Tertiary Education' {
					conqual.First_Year_Enrolled__c = startDate;
					conqual.Last_Year_Enrolled__c = endDate;
				}
				when 'Secondary Education' {
					conqual.Score__c = '0';
					conqual.State__c = stateObtained != null ? stateObtained : null;
					if (endDate != null) {
						// SFTG-3700 Null Check, as Applicants may enter 'Expected Completion date' in My.App, which clears endDate
						conqual.Year_of_Completion__c = endDate;
					}
				}
			}
			return conqual;
		}
		/**
		 * @description getScore for English language proficiency test
		 * @param scores english test scores
		 * @param conqual Contact Qualifications
		 * @return String
		 **/
		private Contact_Qualification__c getScore(List<CDM_QualificationScore> scores, Contact_Qualification__c conqual) {
			for (CDM_QualificationScore score : scores) {
				conqual.Listening__c = score.name?.equalsIgnoreCase('listening') ? score.value : conqual.Listening__c;
				conqual.Reading__c = score.name?.equalsIgnoreCase('reading') ? score.value : conqual.Reading__c;
				conqual.Writing__c = score.name?.equalsIgnoreCase('writing') ? score.value : conqual.Writing__c;
				conqual.Speaking__c = score.name?.equalsIgnoreCase('speaking') ? score.value : conqual.Speaking__c;
			}
			return conqual;
		}
	}
	/** @description CDM_QualificationScore*/
	public virtual class CDM_QualificationScore {
		public String name;
		public String value;
	}
	/** @description CDM_QualificationType*/
	public virtual class CDM_QualificationType {
		public String crmRecordId;
		public String code;
		public String name;
		public String qualificationName;
		public String qualificationUid; //SFTG-3745 uid for Contact Qualification
	}
	/** @description CDM_QualificationName*/
	public virtual class CDM_QualificationName {
		public String code;
		public String name;
	}
	/** @description CDM_Institution*/
	public virtual class CDM_Institution {
		public String crmRecordId;
		public String code;
		public String value;
		public String institutionCode;
	}
	/** @description CDM_Referee*/
	public virtual class CDM_Referee {
		public String firstName;
		public String lastName;
	}
	/**
	 * CDM_WorkExperience contains the work experience details of an applicant.
	 */
	public virtual class CDM_WorkExperience {
		public String crmRecordId;
		public String position;
		public String employer;
		public String startDate;
		public String endDate;
		public CDM_Country countryObtained;
		public CDM_Referee contactPerson;
		public String contactAddress;
		public String contactPhone;
		public String externalId;
		public Contact applicantRecord;
		public CDM_WorkExperience() {
			this.isHistoric = false;
		}
		// /** @description isHistoric */
		public Boolean isHistoric {
			get {
				return isHistoric != null ? isHistoric : false;
			}
			set;
		}
		/**
		 * Parse work experience to Work_Experience__c record
		 * @return Work_Experience__c
		 **/
		public Work_Experience__c asExperienceRecord() {
			Work_Experience__c workExp = new Work_Experience__c();
			workExp.Id = crmRecordId;
			workExp.Contact_Person_First_Name__c = contactPerson != null ? contactPerson.firstName : null;
			workExp.Contact_Person_Last_Name__c = contactPerson != null ? contactPerson.lastName : null;
			workExp.Contact_Person_Email__c = contactAddress;
			workExp.Contact_Person_Phone__c = contactPhone;
			workExp.Contact__c = applicantRecord.Id;
			workExp.Position__c = position;
			workExp.Employer_Name__c = employer;
			if (startDate != null) {
				workExp.Start_Date__c = Date.valueOf(startDate);
			}
			if (endDate != null) {
				workExp.End_Date__c = Date.valueOf(endDate);
			}
			// for OES user set the external id and country. OES user does not have salesforce IDs
			if (OESApplicationService.isOESUser) {
				workExp.External_ID__c = externalId;
				if (countryObtained != null) {
					workExp.Country__r = new Country_Attribute__c(
							uniqueCountryExternalId__c = countryObtained.uniqueCountryExternalId
					);
				}
			} else {
				if (countryObtained != null) {
					workExp.Country__c = countryObtained.crmRecordId;
				}
			}

			return workExp;
		}
	}
	/** @description CDM_VisaType*/
	public virtual class CDM_VisaType {
		public String code;
		public String value;
	} /** @description CDM_Status*/
	public virtual class CDM_Status {
		public String code;
		public String value;
	}
	/**
	 * @description CDM_Visa contains the visa details of an applicant.
	 */
	@SuppressWarnings('PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount')
	public virtual class CDM_Visa {
		public CDM_Country citizenship; //Country of Citizenship
		public String visaNumber;
		public CDM_VisaType type;
		public String startDate;
		public String endDate;
		public CDM_Status hasRefusedEntry;
		public CDM_Status hasBreachedVisa;
		public CDM_Status hasMedicalIssues;
		public CDM_Status hasProtectionVisa;
		public CDM_Status hasConvictedOfCrime;
		public String immigrationOfficeIssued;
		public CDM_Country singleEntryVisaCountry;
		public Application__c applicationRecord;
		public void addVisaDetailsToApplication() {
			// Only applicable for OES user
			//SFTG-3745
			if (String.isNotBlank(citizenship?.uniqueCountryExternalId)) {
				applicationRecord.Citizenship_Country__r = new Country_Attribute__c(
						uniqueCountryExternalId__c = citizenship.uniqueCountryExternalId
				);
			} else {
				applicationRecord.Citizenship_Country__c = citizenship != null ? citizenship.crmRecordId : null;
			}
			// Only applicable for OES user
			if (singleEntryVisaCountry != null && String.isNotBlank(singleEntryVisaCountry.uniqueCountryExternalId)) {
				applicationRecord.Single_Entry_Visa__r = new Country_Attribute__c(
						uniqueCountryExternalId__c = singleEntryVisaCountry.uniqueCountryExternalId
				);
			} else {
				applicationRecord.Single_Entry_Visa__c = singleEntryVisaCountry != null
						? singleEntryVisaCountry.crmRecordId
						: null;
			}
			applicationRecord.Visa_Number__c = visaNumber;
			applicationRecord.Visa_Type__c = type != null ? type.code : null;
			applicationRecord.Visa_Start_Date__c = startDate != null ? Date.valueOf(startDate) : null;
			applicationRecord.Visa_End_Date__c = endDate != null ? Date.valueOf(endDate) : null;
			applicationRecord.Refused_entry_visa_to_any_country__c = hasRefusedEntry != null ? hasRefusedEntry.code : null;
			applicationRecord.Breached_visa_condition__c = hasBreachedVisa != null ? hasBreachedVisa.code : null;
			applicationRecord.Medical_health_prevent_visa__c = hasMedicalIssues != null ? hasMedicalIssues.code : null;
			applicationRecord.Protection_visa_in_any_country__c = hasProtectionVisa != null ? hasProtectionVisa.code : null;
			applicationRecord.Convicted_of_crime_offence__c = hasConvictedOfCrime != null ? hasConvictedOfCrime.code : null;
			applicationRecord.Australian_Immigration_Office_Issued__c = immigrationOfficeIssued;
		}
	}
	/** @description CDM_FeeWaiverCode*/
	public virtual class CDM_FeeWaiverCode {
		public String code;
		public String redeemed;
		public CDM_ValidityPeriod periodOfValidity;
	}
	/** @description CDM_ValidityPeriod*/
	public virtual class CDM_ValidityPeriod {
		public String startDate;
		public String endDate;
	}
	/** @description CDM_Enquiry*/
	public virtual class CDM_Enquiry {
		public String categoryLevel1;
		public String categoryLevel2;
		public String subject;
		public String content;
		public String origin;
		public String recordtypeDeveloperName;
		public String enquiryType;
		public List<CDM_Reference> references;
	}
	/** @description CDM_Reference*/
	public virtual class CDM_Reference {
		public String key;
		public List<CDM_Value> value;
	}
	/** @description errorCDM_ValueMessage*/
	public virtual class CDM_Value {
		public String id;
		public String description;
	}
	/** @description Document details wrapper for qualifications*/
	public virtual class CDM_DocumentDetails {
		/** Unique identifier of document that is coming in API calls or payloads **/
		public String documentIdentifier;
		/** source where it is verifed or origin of incoming document */
		public String documentSource;
		/** Automatically caluclated based on test date, read only for APIs, just sent on response */
		public Date documentExpiryDate;
	}
}