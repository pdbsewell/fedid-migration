/**
 * @description Test class for AgentPortalConstants
 * @author      Vinoth Raja
 */
@isTest(isParallel=true)
public with sharing class AgentPortalConstants_Test {
	/**
	 * @description test constants - no functional testing
	 */
	@isTest
	private static void testConstants() {
		Test.startTest();

		// constants
		Assert.isTrue(AgentPortalConstants.SUCCESS == 'Success', 'SUCCESS Constant test');
		Assert.isTrue(AgentPortalConstants.ERROR == 'Error', 'ERROR Constant test');
		Assert.isTrue(AgentPortalConstants.STATUS == 'status', 'STATUS Constant test');
		Assert.isTrue(AgentPortalConstants.MESSAGE == 'message', 'MESSAGE Constant test');
		Assert.isTrue(AgentPortalConstants.SUCCESS_MESSAGE == 'Success', 'SUCCESS_MESSAGE Constant test');
		Assert.isTrue(AgentPortalConstants.NO_ERROR == '', 'NO_ERROR Constant test');
		Assert.isTrue(AgentPortalConstants.MINIMUM_AGE_FOR_APPLYING == 10, 'MINIMUM_AGE_FOR_APPLYING Constant test');
		Assert.isTrue(AgentPortalConstants.DEFAULT_SEARCH_LIMIT == 20, 'DEFAULT_SEARCH_LIMIT Constant test');
		Assert.isTrue(AgentPortalConstants.MAX_SEARCH_LIMIT == 500, 'MAX_SEARCH_LIMIT Constant test');
		Assert.isTrue(AgentPortalConstants.DEFAULT_SEARCH_OFFSET == 0, 'DEFAULT_SEARCH_OFFSET Constant test');
		Assert.isTrue(AgentPortalConstants.USER_CONTEXT == 'USER', 'USER_CONTEXT Constant test');
		Assert.isTrue(AgentPortalConstants.SYSTEM_CONTEXT == 'SYSTEM', 'SYSTEM_CONTEXT Constant test');
		Assert.isTrue(AgentPortalConstants.APPLICANT_PERSONA == 'APPLICANT', 'SYSTEM_CONTEXT Constant test');
		Assert.isTrue(AgentPortalConstants.AGENT_PERSONA == 'AGENT', 'SYSTEM_CONTEXT Constant test');
		Assert.isTrue(
			AgentPortalConstants.CONTACT_ROLE_ALLOWED_TO_CREATE_USERS == 'Delegated Admin',
			'CONTACT_ROLE_ALLOWED_TO_CREATE_USERS Constant test'
		);

		Assert.isTrue(
			AgentPortalConstants.AGENT_PORTAL_MANAGERS.contains('Branch Manager'),
			'AGENT_PORTAL_MANAGERS Constant test'
		);
		Assert.isTrue(AgentPortalConstants.AGENT_PORTAL_USERS.contains('Counsellor'), 'AGENT_PORTAL_USERS Constant test');
		Assert.isTrue(
			AgentPortalConstants.AGENT_PROFILE == 'Agent Portal Next Gen User',
			'AGENT_PORTAL_PROFILE Constant test'
		);
		Assert.isTrue(AgentPortalConstants.AGENT_PROFILE_ID != null, 'AGENT_PORTAL_PROFILE doesn\'t exist');
		Assert.isTrue(
			AgentPortalConstants.AGENT_PERMISSION_SET == 'Agent_Portal_Next_Gen_Portal_Member',
			'AGENT_PERMISSION_SET Constant test'
		);
		Assert.isTrue(AgentPortalConstants.AGENT_PERMISSION_SET_ID != null, 'AGENT_PERMISSION_SET doesn\'t exist');
		Assert.isTrue(
			AgentPortalConstants.AGENT_PERMISSION_SET_GROUP == 'Agent_Portal_Next_Gen_Agent_User_PSG',
			'AGENT_PERMISSION_SET_GROUP Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.AGENT_PERMISSION_SET_GROUP_ID != null,
			'AGENT_PERMISSION_SET_GROUP doesn\'t exist'
		);
		Assert.isTrue(AgentPortalConstants.AGENT_COMMUNITY == 'Agent Portal Next Gen', 'AGENT_COMMUNITY Constant test');
		Assert.isTrue(AgentPortalConstants.AGENT_COMMUNITY_ID != null, 'AGENT_COMMUNITY doesn\'t exist');
		Assert.isTrue(AgentPortalConstants.EXPERIAN_PERMISSION_SET == 'Experian', 'EXPERIAN_PERMISSION_SET Constant test');
		// Assert.isTrue(AgentPortalConstants.EXPERIAN_PERMISSION_SET_ID != null, 'EXPERIAN_PERMISSION_SET doesn\'t exist');

		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_AGENCY_CONTACT ==
			'Id,AccountId,Account.IsPartner,First_Name__c,Last_Name__c,Email,Agency_Contact_Roles__c',
			'SEARCH_FIELDS_AGENCY_CONTACT Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_APPLICANT ==
			'id,First_Name__c,Last_Name__c,CRM_Id__c,Person_ID__c,Salutation,Pronouns_V2__c,Suffix,Preferred_Name__c,Is_Mononymous_Name__c,Gender__c,Birthdate,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode,MobilePhone,HomePhone,Personal_Email__c,Previous_Surname__c,Previous_Firstname__c,Previous_Monash_ID__c,Previously_Studied_at_Monash__c,CountryOfBirth__r.id,CountryOfBirth__r.Name,CountryOfBirth__r.Callista_Code__c,CountryOfBirth__r.Callista_Country__c,Country_of_Birth__c,Aboriginal_or_Torres_Strait_Islander__c',
			'SEARCH_FIELDS_APPLICANT Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_APPLICATION ==
			'Id,Name,Campus_Location__c,Callista_Application_Id__c,Status__c,Application_Type__c,Credit_Intention__c,LastModifiedDate,Applicant__r.CRM_ID__c,Sent_to_student_for_review_Timestamp__c,Student_Accepted_Timestamp__c,Agent_Accepted_Timestamp__c,AgentName__c,Citizenship_Country__c,Citizenship_Country__r.Callista_Code__c,Citizenship_Country__r.uniqueCountryExternalId__c,Citizenship_Country__r.ISO_Alpha_3__c,Citizenship_Country__r.id,Citizenship_Country__r.Country__c,Citizenship_Country__r.Name,Citizenship_Country__r.ISO_Alpha_2__c,Single_Entry_Visa__r.id,Single_Entry_Visa__r.Callista_Code__c,Single_Entry_Visa__r.uniqueCountryExternalId__c,Single_Entry_Visa__r.Country__c,Single_Entry_Visa__r.Name,Single_Entry_Visa__r.ISO_Alpha_2__c,Single_Entry_Visa__r.ISO_Alpha_3__c,Visa_Type__c,Australian_Immigration_Office_Issued__c,Passport_Number__c,Visa_Number__c,Visa_Start_Date__c,Visa_End_Date__c,Student_Pass_Availability__c,Refused_Entry_Visa_To_Any_Country__c,Breached_Visa_Condition__c,Medical_Health_Prevent_Visa__c,Protection_Visa_In_Any_Country__c,Convicted_Of_Crime_Offence__c,Callista_Applicant_Id__c,English_Language_Proficiency__c,English_Proficiency_Requirement__c,English_Program_Consideration__c,Residency_Status__c,Residency_Sub_status__c,Source_System__c,HasDisabilities__c,Existing_Aus_disability_support__c,is_Principal_Course_Transfer__c,Is_Sponsored__c,Sponsor_Name__c,Sponsorship_Status__c,Sponsorship_Type__c,Sponsor_Scholarship_organisation__c,Fee_Payment_Mode__c,Fee_Amount__c,Fee_Payment__c,Transaction_Amount__c,Transaction_Date__c,Transaction_Reference__c,Transaction_Source__c,Fee_Waiver_Code__c,Fee_Waiver_Redeemed__c,Owner.Name,Agent_Notes__c,MyApp_User_Status__c,Delegator_Org_Unit_Code__c',
			'Invalid SEARCH_FIELDS_APPLICATION values'
		);
		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_WORKEXPERIENCE ==
			'Id,External_ID__c,Position__c,Employer_Name__c,Start_Date__c,End_Date__c,Country__r.uniqueCountryExternalId__c,Country__r.ISO_Alpha_2__c,Country__r.Name,Country__r.Id,Contact_Person_First_Name__c,Contact_Person_Last_Name__c,Contact_Person_Email__c,Contact_Person_Phone__c',
			'SEARCH_FIELDS_WORKEXPERIENCE Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_ACP ==
			'id,Course_Offering__r.Active__c,Course_Start_Year__c,Calendar_Start_Date__c,application__c,Application__r.Name,Course__c,Course_Offering__r.Course__r.id,Course_Code__c,Course_Version_Number__c,Course_Title__c,Unit_Set_Code__c,Location_Code__c,Documentation_Status_LOV__r.System_Code__c,Documentation_Status_LOV__r.Value__c,Entry_Qualification_Status_LOV__r.System_Code__c,Entry_Qualification_Status_LOV__r.Value__c,Outcome_Status_LOV__r.System_Code__c,Outcome_Status_LOV__r.Value__c,Offer_Response_Status_LOV__r.Value__c,Offer_Condition__c,Offer_Date__c,Offer_Response_Date__c,Offer_Response_Status_LOV__r.System_Code__c,Actual_Offer_Response_Date__c,Deferment_Status_LOV__r.System_Code__c,Admission_Calendar_Type__c,Commencement_Period__c,Managing_Faculty__c,Unit_Set_Description__c,Status__c,Preference_Number__c,LastModifiedDate,Conditional_Offer_Status_LOV__r.Value__c,Deferment_Status_LOV__r.Value__c,Conditional_Offer_Satisfied_Date__c,ACP_ID__c,External_Id__c'
		);
		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_COURSEOFFERINGS ==
			'Id,Course_Offering_UID__c,Academic_Calendar_Type__c,Academic_CI_Sequence_Number__c,Admission_Calendar_Type__c,Admission_CI_Sequence_Number__c,Attendance_Type__c,Attendance_Type_Description__c,Admission_Calendar_Description__c,Course_Code__c,Course_Title__c,Course_Version_Number__c,Location_Code__c,Location_Description__c,Attendance_Mode__c,Attendance_Mode_Description__c,Type_of_Place_Code__c,Type_of_Place_Description__c,Unit_Set_Code__c,Unit_Set_Description__c,Unit_Set_Version__c',
			'SEARCH_FIELDS_COURSEOFFERINGS Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.CREATE_FIELDS_APPLICANT ==
			'id,CRM_Id__c,First_Name__c,Last_Name__c,Birthdate,Personal_Email__c,Phone,HomePhone,MobilePhone,Previous_Surname__c,Previous_Firstname__c,Previous_Monash_ID__c,Previously_Studied_at_Monash__c',
			'CREATE_FIELDS_APPLICANT Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.CREATE_FIELDS_APPLICATION ==
			'id,Name,Applicant__c,Status__c,Source_System__c,Campus_Location__c,Residency_Sub_status__c,Residency_Status__c',
			'CREATE_FIELDS_APPLICATION Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.UPDATE_ALLOWED_FIELDS_AFTER_SUBMIT == 'Id,Pronouns_v2__c',
			'UPDATE_ALLOWED_FIELDS_AFTER_SUBMIT Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_USER ==
			'Id,FirstName,LastName,Email,Contact.Id,Contact.AccountId,contact.Account.Callista_Org_Unit_Code__c,Contact.Agency_Contact_Roles__c,contact.Account.Campus__c',
			'SEARCH_FIELDS_USER Constant test'
		);

		// CPA related constants
		Assert.isTrue(
			AgentPortalConstants.SEARCH_FIELDS_CONTACT_POINT ==
			'type__c,classification__c,phone__r.name,phone__r.type__c,email__r.name,address__r.type__c,address__r.address__c,address__r.Street_Name__c,address__r.City__c,address__r.State__c,address__r.Country2__c,address__r.Post_Code__c,start_date__c,primary_on_contact__c,shown_on_contact__c,contact__c',
			'SEARCH_FIELDS_CONTACT_POINT Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.PRIVATE_CONTACT_FIELDS ==
			'Phone,MobilePhone,HomePhone,OtherPhone,Personal_Email__c,Email,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,OtherStreet,OtherCity,OtherState,OtherCountry,OtherPostalCode',
			'PRIVATE_CONTACT_FIELDS Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.CONTACT_PHONE_TYPE_MOBILE == 'Mobile',
			'CONTACT_PHONE_TYPE_MOBILE Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.CONTACT_PHONE_TYPE_LANDLINE == 'Landline',
			'CONTACT_PHONE_TYPE_LANDLINE Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.CONTACT_ADDRESS_TYPE_MAILING == 'Mailing',
			'CONTACT_ADDRESS_TYPE_MAILING Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.CONTACT_ADDRESS_TYPE_OTHER == 'Billing',
			'CONTACT_ADDRESS_TYPE_OTHER Constant test'
		);
		Assert.isTrue(AgentPortalConstants.CONTACT_CLASSIFICATION == 'Private', 'CONTACT_CLASSIFICATION Constant test');
		Assert.isTrue(AgentPortalConstants.CONTACT_SOURCE == 'Contact supplied', 'CONTACT_SOURCE Constant test');
		// Application related constants
		Assert.isTrue(AgentPortalConstants.APP_CREATE_STATUS == 'Draft', 'APP_CREATE_STATUS Constant test');
		Assert.isTrue(AgentPortalConstants.APP_CREATE_SOURCE == 'AgentPortal', 'APP_CREATE_SOURCE Constant test');
		Assert.isTrue(
			AgentPortalConstants.DRAFT_STATUSES.contains(AgentPortalConstants.APP_CREATE_STATUS),
			'DRAFT_STATUSES Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.STATUSES_REVERTIBLE_TO_DRAFT.contains(
				AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT
			),
			'STATUSES_REVERTIBLE_TO_DRAFT Constant test'
		);
		Assert.isTrue(AgentPortalConstants.APP_CREATE_TYPE == 'Coursework', 'APP_CREATE_TYPE Constant test');
		Assert.isTrue(AgentPortalConstants.CON_UNUSED_GENDERS.contains('P'), 'CON_UNUSED_GENDERS Constant test');
		Assert.isTrue(AgentPortalConstants.DEFAULT_ENQUIRY_TYPE == 'Future Course', 'DEFAULT_ENQUIRY_TYPE Constant test');
		Assert.areEqual(
			[SELECT Id FROM Group WHERE DeveloperName = 'Student_Rec_Enquiries_Post_Application' AND Type = 'Queue' LIMIT 1]
			?.Id,
			AgentPortalConstants.STUDENT_REC_POST_APP_QUEUE_ID
		);
		Assert.areEqual(
			[SELECT Id FROM Group WHERE DeveloperName = 'SRA_IA_MU_Docs' AND Type = 'Queue' LIMIT 1]?.Id,
			AgentPortalConstants.MUA_ADMISSIONS_QUEUE_ID
		);
		Assert.areEqual(
			[SELECT Id FROM Group WHERE DeveloperName = 'Monash_Malaysia_MUM' AND Type = 'Queue' LIMIT 1]?.Id,
			AgentPortalConstants.MUM_ADMISSIONS_QUEUE_ID
		);
		Assert.isTrue(AgentPortalConstants.APNG_WEB_ORIGIN == 'Web - Agent Portal', 'APNG_WEB_ORIGIN Constant test');
		Assert.isTrue(
			AgentPortalConstants.ALLOWED_REC_TYPES_FOR_SUMMARY_FILE_GENERATION.containsAll(
				new Set<String>{ 'Admissions', 'MUM_Admissions' }
			),
			'ALLOWED_REC_TYPES_FOR_SUMMARY_FILE_GENERATION Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.APP_SUBMITTED_STATUS.containsAll(
				new Set<String>{ 'Submitted', 'Submission on Hold (Duplicate Contact)', 'Sent for Submission', 'Review' }
			),
			'APP_SUBMITTED_STATUS Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.DATA_VALIDATION_READY == 'Data validation Ready',
			'DATA_VALIDATION_READY Constant test'
		);
		Assert.isTrue(AgentPortalConstants.SUBMISSION_READY == 'Submission Ready', 'SUBMISSION_READY Constant test');
		Assert.isTrue(
			AgentPortalConstants.SUBMISSION_READY_STATUS.contains('Submission Ready'),
			'SUBMISSION_READY_STATUS Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.SUBMISSION_READY_STATUS.contains('Agent Declaration Accepted'),
			'SUBMISSION_READY_STATUS Constant test'
		);
		// Request related constants
		Assert.isTrue(AgentPortalConstants.RESIDENCY_STATUS == 'residencystatus', 'RESIDENCY_STATUS Constant test');

		Assert.isTrue(AgentPortalConstants.RESP_TYPE_CREATE == 'CREATE', 'RESP_TYPE_CREATE Constant test');
		Assert.isTrue(AgentPortalConstants.RESP_TYPE_UPDATE == 'UPDATE', 'RESP_TYPE_UPDATE Constant test');
		Assert.isTrue(AgentPortalConstants.RESP_TYPE_SEARCH == 'SEARCH', 'RESP_TYPE_SEARCH Constant test');
		Assert.isTrue(AgentPortalConstants.RESP_TYPE_GET == 'GET', 'RESP_TYPE_GET Constant test');
		Assert.isTrue(AgentPortalConstants.RESP_TYPE_DELETE == 'DELETE', 'RESP_TYPE_DELETE Constant test');
		// Error Messages
		Assert.isTrue(AgentPortalConstants.BAD_REQUEST == '', 'BAD_REQUEST Constant test');
		Assert.isTrue(AgentPortalConstants.ERROR_MSG_PREFIX == '', 'ERROR_MSG_PREFIX Constant test');
		Assert.isTrue(
			AgentPortalConstants.NO_CONTACTS_FOUND == 'No Applicant(s) found matching the criteria',
			'NO_CONTACTS_FOUND Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.NO_APPLICATIONS_FOUND == 'No Application(s) found matching the criteria',
			'NO_APPLICATIONS_FOUND Constant test'
		);
		Assert.isTrue(
			AgentPortalConstants.NO_DOCUMENTS_FOUND == 'No Application Document(s) found matching the criteria',
			'NO_DOCUMENTS_FOUND Constant test'
		);
		Assert.isTrue(!AgentPortalConstants.GET_APPLICANT_FIELDS.isEmpty(), 'Unable to get Applicant fields');
		Test.stopTest();
	}
}