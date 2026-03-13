/**
 * @description Constants for Agent Portal processes
 * @author      Vinoth
 * @revision
 *  APR.23.2024     Shalini     -   ???
 *  JUL.30.2024     Nick Guia   -   deprecated existing values not using a getter/setter pattern
 *
 * NOTE:
 *  ALL FIELD-RELATED CONSTANTS NOT USING GETTER/SETTER + SETS ARE CONSIDERED DEPRECATED.
 *  REFRAIN FROM UPDATING THEM, CONVERT THEM INTO A SET INSTEAD.
 *  --
 *  ALL CONSTANTS MUST USE GETTER/SETTER
 */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class AgentPortalConstants {
	// constants
	public static final String SUCCESS = 'Success';
	public static final String ERROR = 'Error';
	public static final String STATUS = 'status';
	public static final String MESSAGE = 'message';
	public static final String DESCRIPTION = 'description';
	public static final String SUCCESS_FLAG = 'success';

	public static final String SUCCESS_MESSAGE = 'Success';
	public static final String NO_ERROR = '';
	public static final Integer MINIMUM_AGE_FOR_APPLYING = 10;
	public static final Integer DEFAULT_SEARCH_LIMIT = 20;
	public static final Integer MAX_SEARCH_LIMIT = 500;
	public static final Integer DEFAULT_SEARCH_OFFSET = 0;
	public static final String USER_CONTEXT = 'USER';
	public static final String SYSTEM_CONTEXT = 'SYSTEM';
	public static final String APPLICANT_PERSONA = 'APPLICANT';
	public static final String AGENT_PERSONA = 'AGENT';
	public static final String CONTACT_ROLE_ALLOWED_TO_CREATE_USERS = 'Delegated Admin';
	public static final String BRANCH_MANAGER_ROLE = 'Branch Manager';
	public static final String PRINCIPAL_AGENT_ROLE = 'Principal Agent';
	public static final String AGENCY_CONTACT_RECORD_TYPE = 'Agency_Contact';
	public static final String AGENT_PORTAL_USER_SUFFIX = '.apng';
	public static final String SEND_DRAFT_APPLICATION_TO_APPLICANT = 'Sent Draft Application to Applicant';
	public static final String STUDENT_DECLARATION_ACCEPTED = 'Applicant Declaration Accepted';
	public static final String AGENT_DECLARATION_ACCEPTED = 'Agent Declaration Accepted';
	public static final String DATA_VALIDATION_READY = 'Data validation Ready';
	public static final String SUBMISSION_READY = 'Submission Ready';
	public static final Set<String> SUBMISSION_READY_STATUS = new Set<String>{
		'Agent Declaration Accepted',
		'Submission Ready'
	};
	public static final Set<String> AGENT_PORTAL_MANAGERS = new Set<String>{ 'Branch Manager' };
	public static final Set<String> AGENT_PORTAL_USERS = new Set<String>{
		'Counsellor',
		'Delegated Admin',
		'Principal Agent'
	};
	public static final String AGENT_PROFILE = 'Agent Portal Next Gen User';
	public static final String AGENT_PROFILE_ID { //NOPMD
		get {
			return [SELECT id FROM Profile WHERE Name = :AGENT_PROFILE LIMIT 1]?.id;
		}
	}
	public static final String AGENT_PERMISSION_SET = 'Agent_Portal_Next_Gen_Portal_Member';
	public static final String AGENT_PERMISSION_SET_ID { //NOPMD
		get {
			return [SELECT id FROM PermissionSet WHERE Name = :AGENT_PERMISSION_SET LIMIT 1]?.id;
		}
	}
	public static final String AGENT_PERMISSION_SET_GROUP = 'Agent_Portal_Next_Gen_Agent_User_PSG';
	public static final String AGENT_PERMISSION_SET_GROUP_ID { //NOPMD
		get {
			return [SELECT id FROM PermissionSetGroup WHERE DeveloperName = :AGENT_PERMISSION_SET_GROUP LIMIT 1]?.id;
		}
	}
	public static final String AGENT_COMMUNITY = 'Agent Portal Next Gen';
	public static final String AGENT_COMMUNITY_ID { //NOPMD
		get {
			return [SELECT Id FROM Network WHERE NAME = :AGENT_COMMUNITY LIMIT 1]?.id;
		}
	}
	public static final String EXPERIAN_PERMISSION_SET = 'Experian';

	// fieldsets
	// DEPRECATED - START
	public static final String SEARCH_FIELDS_AGENCY_CONTACT = 'Id,AccountId,Account.IsPartner,First_Name__c,Last_Name__c,Email,Agency_Contact_Roles__c';
	public static final String SEARCH_FIELDS_APPLICANT = 'id,First_Name__c,Last_Name__c,CRM_Id__c,Person_ID__c,Salutation,Pronouns_V2__c,Suffix,Preferred_Name__c,Is_Mononymous_Name__c,Gender__c,Birthdate,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode,MobilePhone,HomePhone,Personal_Email__c,Previous_Surname__c,Previous_Firstname__c,Previous_Monash_ID__c,Previously_Studied_at_Monash__c,CountryOfBirth__r.id,CountryOfBirth__r.Name,CountryOfBirth__r.Callista_Code__c,CountryOfBirth__r.Callista_Country__c,Country_of_Birth__c,Aboriginal_or_Torres_Strait_Islander__c';
	public static final String SEARCH_FIELDS_APPLICATION = 'Id,Name,Campus_Location__c,Callista_Application_Id__c,Status__c,Application_Type__c,Credit_Intention__c,LastModifiedDate,Applicant__r.CRM_ID__c,Sent_to_student_for_review_Timestamp__c,Student_Accepted_Timestamp__c,Agent_Accepted_Timestamp__c,AgentName__c,Citizenship_Country__c,Citizenship_Country__r.Callista_Code__c,Citizenship_Country__r.uniqueCountryExternalId__c,Citizenship_Country__r.ISO_Alpha_3__c,Citizenship_Country__r.id,Citizenship_Country__r.Country__c,Citizenship_Country__r.Name,Citizenship_Country__r.ISO_Alpha_2__c,Single_Entry_Visa__r.id,Single_Entry_Visa__r.Callista_Code__c,Single_Entry_Visa__r.uniqueCountryExternalId__c,Single_Entry_Visa__r.Country__c,Single_Entry_Visa__r.Name,Single_Entry_Visa__r.ISO_Alpha_2__c,Single_Entry_Visa__r.ISO_Alpha_3__c,Visa_Type__c,Australian_Immigration_Office_Issued__c,Passport_Number__c,Visa_Number__c,Visa_Start_Date__c,Visa_End_Date__c,Student_Pass_Availability__c,Refused_Entry_Visa_To_Any_Country__c,Breached_Visa_Condition__c,Medical_Health_Prevent_Visa__c,Protection_Visa_In_Any_Country__c,Convicted_Of_Crime_Offence__c,Callista_Applicant_Id__c,English_Language_Proficiency__c,English_Proficiency_Requirement__c,English_Program_Consideration__c,Residency_Status__c,Residency_Sub_status__c,Source_System__c,HasDisabilities__c,Existing_Aus_disability_support__c,is_Principal_Course_Transfer__c,Is_Sponsored__c,Sponsor_Name__c,Sponsorship_Status__c,Sponsorship_Type__c,Sponsor_Scholarship_organisation__c,Fee_Payment_Mode__c,Fee_Amount__c,Fee_Payment__c,Transaction_Amount__c,Transaction_Date__c,Transaction_Reference__c,Transaction_Source__c,Fee_Waiver_Code__c,Fee_Waiver_Redeemed__c,Owner.Name,Agent_Notes__c,MyApp_User_Status__c,Delegator_Org_Unit_Code__c';
	public static final String SEARCH_FIELDS_WORKEXPERIENCE = 'Id,External_ID__c,Position__c,Employer_Name__c,Start_Date__c,End_Date__c,Country__r.uniqueCountryExternalId__c,Country__r.ISO_Alpha_2__c,Country__r.Name,Country__r.Id,Contact_Person_First_Name__c,Contact_Person_Last_Name__c,Contact_Person_Email__c,Contact_Person_Phone__c';
	public static final String SEARCH_FIELDS_ACP = 'id,Course_Offering__r.Active__c,Course_Start_Year__c,Calendar_Start_Date__c,application__c,Application__r.Name,Course__c,Course_Offering__r.Course__r.id,Course_Code__c,Course_Version_Number__c,Course_Title__c,Unit_Set_Code__c,Location_Code__c,Documentation_Status_LOV__r.System_Code__c,Documentation_Status_LOV__r.Value__c,Entry_Qualification_Status_LOV__r.System_Code__c,Entry_Qualification_Status_LOV__r.Value__c,Outcome_Status_LOV__r.System_Code__c,Outcome_Status_LOV__r.Value__c,Offer_Response_Status_LOV__r.Value__c,Offer_Condition__c,Offer_Date__c,Offer_Response_Date__c,Offer_Response_Status_LOV__r.System_Code__c,Actual_Offer_Response_Date__c,Deferment_Status_LOV__r.System_Code__c,Admission_Calendar_Type__c,Commencement_Period__c,Managing_Faculty__c,Unit_Set_Description__c,Status__c,Preference_Number__c,LastModifiedDate,Conditional_Offer_Status_LOV__r.Value__c,Deferment_Status_LOV__r.Value__c,Conditional_Offer_Satisfied_Date__c,ACP_ID__c,External_Id__c';
	public static final String SEARCH_FIELDS_COURSEOFFERINGS = 'Id,Course_Offering_UID__c,Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Admission_Calendar_Type__c,Admission_CI_Sequence_Number__c,Attendance_Type__c,Attendance_Type_Description__c,Admission_Calendar_Description__c,Course_Code__c,Course_Title__c,Course_Version_Number__c,Location_Code__c,Location_Description__c,Attendance_Mode__c,Attendance_Mode_Description__c,Type_of_Place_Code__c,Type_of_Place_Description__c,Unit_Set_Code__c,Unit_Set_Description__c,Unit_Set_Version__c';
	public static final String CREATE_FIELDS_APPLICANT = 'id,CRM_Id__c,First_Name__c,Last_Name__c,Birthdate,Personal_Email__c,Phone,HomePhone,MobilePhone,Previous_Surname__c,Previous_Firstname__c,Previous_Monash_ID__c,Previously_Studied_at_Monash__c';
	public static final String CREATE_FIELDS_APPLICATION = 'id,Name,Applicant__c,Status__c,Source_System__c,Campus_Location__c,Residency_Sub_status__c,Residency_Status__c';
	public static final String UPDATE_ALLOWED_FIELDS_AFTER_SUBMIT = 'Id,Pronouns_v2__c';
	public static final String SEARCH_FIELDS_USER = 'Id,FirstName,LastName,Email,Contact.Id,Contact.AccountId,contact.Account.Callista_Org_Unit_Code__c,Contact.Agency_Contact_Roles__c,contact.Account.Campus__c';
	// DEPRECATED - END

	public static final Set<String> GET_APPLICANT_FIELDS { //NOPMD
		get {
			if (GET_APPLICANT_FIELDS == null) {
				GET_APPLICANT_FIELDS = new Set<String>{
					'Id',
					'First_Name__c',
					'Last_Name__c',
					'CRM_Id__c',
					'Person_ID__c',
					'Salutation',
					'Pronouns_V2__c',
					'Suffix',
					'Preferred_Name__c',
					'Is_Mononymous_Name__c',
					'Gender__c',
					'Birthdate',
					'MailingStreet',
					'MailingCity',
					'MailingState',
					'MailingCountry',
					'MailingPostalCode',
					'OtherStreet',
					'OtherCity',
					'OtherState',
					'OtherCountry',
					'OtherPostalCode',
					'MobilePhone',
					'HomePhone',
					'Personal_Email__c',
					'Previous_Surname__c',
					'Previous_Firstname__c',
					'Previous_Monash_ID__c',
					'Previously_Studied_at_Monash__c',
					'CountryOfBirth__r.Id',
					'CountryOfBirth__r.Name',
					'CountryOfBirth__r.Callista_Code__c',
					'CountryOfBirth__r.Callista_Country__c',
					'Country_of_Birth__c',
					'Aboriginal_or_Torres_Strait_Islander__c'
				};
			}
			return GET_APPLICANT_FIELDS;
		}
		set;
	}

	// CPA related constants
	public static final String CONTACT_PHONE_TYPE_MOBILE = 'Mobile';
	public static final String CONTACT_PHONE_TYPE_LANDLINE = 'Landline';
	public static final String CONTACT_ADDRESS_TYPE_MAILING = 'Mailing';
	public static final String CONTACT_ADDRESS_TYPE_OTHER = 'Billing';
	public static final String CONTACT_CLASSIFICATION = 'Private';
	public static final String CONTACT_SOURCE = 'Contact supplied';
	public static final String SUB_QUERY_PHONE = 'SELECT phone__r.name, start_date__c, primary_on_contact__c, shown_on_contact__c, contact__c FROM contact_point_affiliation__c WHERE type__c = \'Phone\' AND classification__c = \'Mobile\' AND Contact_Point_Active__c = true AND Affiliation_active__c = true AND affiliation__r.account__r.callista_org_unit_code__c = \'\'{0}\'\' AND contact__r.id IN (\'\'{1}\'\') ORDER BY primary_on_Contact__c DESC, shown_on_contact__c desc, start_date__c DESC';
	public static final String SUB_QUERY_EMAIL = 'SELECT email__r.name, start_date__c, primary_on_contact__c, shown_on_contact__c, contact__c FROM contact_point_affiliation__c WHERE type__c = \'Email\' AND classification__c = \'Private\' AND Contact_Point_Active__c = true AND Affiliation_active__c = true AND affiliation__r.account__r.callista_org_unit_code__c = \'\'{0}\'\' AND contact__r.id IN (\'\'{1}\'\') ORDER BY primary_on_Contact__c DESC, shown_on_contact__c desc, start_date__c DESC';

	public static final String SEARCH_FIELDS_CONTACT_POINT = 'type__c,classification__c,phone__r.name,phone__r.type__c,email__r.name,address__r.type__c,address__r.address__c,address__r.Street_Name__c,address__r.City__c,address__r.State__c,address__r.Country2__c,address__r.Post_Code__c,start_date__c,primary_on_contact__c,shown_on_contact__c,contact__c';
	public static final String PRIVATE_CONTACT_FIELDS = 'Phone,MobilePhone,HomePhone,OtherPhone,Personal_Email__c,Email,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode'; // case-sensitive

	// Application related constants
	public static final String APP_CREATE_STATUS = 'Draft'; // Creation status
	public static final Set<String> APP_SUBMITTED_STATUS = new Set<String>{
		'Submitted',
		'Submission on Hold (Duplicate Contact)',
		'Sent for Submission',
		'Review'
	}; // Allowed statuses for Enquiry creation
	public static final Set<String> DRAFT_STATUSES = new Set<String>{ APP_CREATE_STATUS };
	public static final Set<String> STATUSES_REVERTIBLE_TO_DRAFT = new Set<String>{
		SEND_DRAFT_APPLICATION_TO_APPLICANT,
		STUDENT_DECLARATION_ACCEPTED
	};
	public static final String OES_SOURCE_SYSTEM_CUSTOM_PERMISSION = 'OES_Source_System';
	public static final String APP_CREATE_SOURCE = 'AgentPortal'; // Source
	public static final String OES_CREATE_SOURCE = 'OES'; // Source
	public static final String APP_CREATE_TYPE = 'Coursework'; // Creation type

	// Applicant related constants
	public static final Set<String> CON_UNUSED_GENDERS = new Set<String>{ 'P', 'U' };

	// Enquiry related constants
	public static final String DEFAULT_ENQUIRY_TYPE = 'Future Course';
	public static final Id STUDENT_REC_POST_APP_QUEUE_ID { //NOPMD
		get {
			if (STUDENT_REC_POST_APP_QUEUE_ID == null) {
				STUDENT_REC_POST_APP_QUEUE_ID = [
					SELECT Id
					FROM Group
					WHERE DeveloperName = 'Student_Rec_Enquiries_Post_Application' AND Type = 'Queue'
					LIMIT 1
				]
				?.Id;
			}
			return STUDENT_REC_POST_APP_QUEUE_ID;
		}
		set;
	}
	public static final Id MUA_ADMISSIONS_QUEUE_ID { //NOPMD
		get {
			if (MUA_ADMISSIONS_QUEUE_ID == null) {
				MUA_ADMISSIONS_QUEUE_ID = [SELECT Id FROM GROUP WHERE DeveloperName = 'SRA_IA_MU_Docs' AND Type = 'Queue']?.Id;
			}
			return MUA_ADMISSIONS_QUEUE_ID;
		}
		set;
	}
	public static final Id MUM_ADMISSIONS_QUEUE_ID { //NOPMD
		get {
			if (MUM_ADMISSIONS_QUEUE_ID == null) {
				MUM_ADMISSIONS_QUEUE_ID = [SELECT Id FROM GROUP WHERE DeveloperName = 'Monash_Malaysia_MUM' AND Type = 'Queue']
				?.Id;
			}
			return MUM_ADMISSIONS_QUEUE_ID;
		}
		set;
	}
	public static final Set<String> ALLOWED_REC_TYPES_FOR_SUMMARY_FILE_GENERATION = new Set<String>{
		'Admissions',
		'MUM_Admissions'
	};
	public static final String APNG_WEB_ORIGIN = 'Web - Agent Portal';
	public static final String SEARCH_FIELDS_ENQUIRY = 'Id,Origin';
	//CaseNumber,Status,Subject,RecordTypeId,RecordType.name,Enquiry_type__c,Category_Level_1__c,Category_Level_2__c,Owner.Name,Flag_Owner_is_Queue__c,Application_Course_Preference__r.name,Application_Course_Preference__r.Application__r.name,isclosed,CreatedDate,CreatedBy.Name,LastModifiedDate,UUID__c,contact.crm_id__c
	// Request related constants
	public static final String RESIDENCY_STATUS = 'residencystatus';
	public static final String CONTACT_QUALIFICATIONS = 'qualifications';
	public static final String WORK_EXPERIENCE = 'workexperience';

	// Response related constants
	public static final String RESP_TYPE_CREATE = 'CREATE';
	public static final String RESP_TYPE_UPDATE = 'UPDATE';
	public static final String RESP_TYPE_SEARCH = 'SEARCH';
	public static final String RESP_TYPE_GET = 'GET';
	public static final String RESP_TYPE_DELETE = 'DELETE';
	// Error Messages
	public static final String BAD_REQUEST = '';
	public static final String ERROR_MSG_PREFIX = '';
	public static final String NO_CONTACTS_FOUND = 'No Applicant(s) found matching the criteria';
	public static final String NO_APPLICATIONS_FOUND = 'No Application(s) found matching the criteria';
	public static final String ACP_NOT_FOUND = 'ACP not found';
	public static final String ENQUIRY_CREATED = 'Enquiry is created';
	public static final String APPLICATION_STATUS_DID_NOT_MATCH = 'Application status should be in Submitted status to create an Enquiry';
	public static final String APPLICATION_STATUS_MATCHED = 'Application status matched';
	public static final String NO_DOCUMENTS_FOUND = 'No Application Document(s) found matching the criteria';
}