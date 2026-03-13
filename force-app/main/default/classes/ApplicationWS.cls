/**
 * @description Centralised API for managing Applications
 * Refactored from ApplicationWebService
 * @author      Ben Greenland
 * @since       2019/06/21
 * @group Application Webservice v3

 */
@RestResource(urlMapping='/v3/ApplicationWebService')
global with sharing class ApplicationWS implements RESTlib_IClientFactory {
	/**
	 * @description HTTP Get Handler
	 */
	@HttpGet
	global static void handleGet() {
		RESTlib_ClientFactoryUtility.getInstance().setSourceFactory(new ApplicationWS()).getHandleGet().execute();
	}

	/**
	 * @description HTTP POST Handler
	 */
	@HttpPost
	global static void handlePost() {
		//System.debug(JSON.deserializeUntyped(RestContext.request.requestBody.toString()));
		RESTlib_ClientFactoryUtility.getInstance().setSourceFactory(new ApplicationWS()).getHandlePost().execute();
	}

	/**
	 * @description HTTP PATCH Handler
	 * @example
	 *{ @code { "application": { "crmContactId": "C-A122902", "applicationId": "A-122902", "smsApplicantId": "SMS-123456", "applicationStatus": "Submitted", "agentNotes": "Important application notes", "applicationType": "Default", "residencyStatus": "INTRNTNL", "accessAndEquityQuestion": "Yes", "passportNumber": "A12345678", "hasDisability": { "code": "Yes" }, "existingDisabilitySupport": { "code": "Yes" }, "isPrincipalCourseTransfer": true, "hasRequestForScholarship": true, "hasRequestForAdvancedStanding": false, "englishLanguageProficiency": true, "sponsorScholarship": "E. Everage Award", "isStudentPassAvailable": true, "visa": { "citizenship": { "crmRecordId": "CRM-123", "code": "AU", "value": "Australia", "uniqueCountryExternalId": "7103-IND-356-0" }, "type": { "code": "010", "value": "010 - BRIDGING A THAT APPLY FOR OTHER SUBCLASSES" }, "visaNumber": "123456543", "hasRefusedEntry": { "code": "No" }, "hasBreachedVisa": { "code": "No" }, "hasMedicalIssues": { "code": "No" }, "hasProtectionVisa": { "code": "No" }, "hasConvictedOfCrime": { "code": "No" }, "immigrationOfficeIssued": "Sydney", "singleEntryVisaCountry": { "crmRecordId": "CRM-456", "uniqueCountryExternalId": "1101-AUS-36-0", "code": "AU", "value": "Australia" } }, "coursePreferences": [ { "externalId": "CP-001", "crmRecordId": "CRM-001", "basisForAdmissionType": "401: WORK AND LIFE EXPERIENCE", "outcomeStatus": "Offer", "documentationStatus": "Satisfied", "entryQualificationStatus": "Qualified", "offerResponseStatus": "Pending", "courseOffering": { "crmRecordId": "CO-001", "courseOfferingUid": "UID-001" }, "preference": 1, "offerDate": "2024-10-01", "actualOfferResponseDate": "2024-10-15" }, { "externalId": "CP-002", "crmRecordId": "CRM-002", "basisForAdmissionType": "401: WORK AND LIFE EXPERIENCE", "outcomeStatus": "Offer", "documentationStatus": "Satisfied", "entryQualificationStatus": "Qualified", "offerResponseStatus": "Pending", "courseOffering": { "crmRecordId": "CO-002", "courseOfferingUid": "UID-002" }, "preference": 2, "offerDate": "2024-10-01", "actualOfferResponseDate": "2024-10-15" } ], "qualifications": [ { "crmRecordId": "QUAL-001", "type": { "qualificationUid": "QUAL-UID-001", "crmCode": "QUAL-263", "name": "English Test", "qualificationName": "Cambridge Certificate in Advanced English" }, "name": { "crmCode": "QUAL-263", "value": "Cambridge Certificate in Advanced English" }, "startDate": "2020-09-14", "endDate": "2025-09-14", "countryObtained": { "crmRecordId": "CRM-003", "uniqueCountryExternalId": "7103-IND-356-0", "code": "AU", "value": "Australia" }, "stateObtained": "VIC", "institution": { "crmRecordId": "INST-001", "code": "123", "value": "QINGDAO WEIMING SCHOOL" }, "scores": [ { "name": "listening", "value": "9.0" }, { "name": "reading", "value": "4.0" }, { "name": "writing", "value": "12.0" }, { "name": "speaking", "value": "8.0" } ], "score": "8.5", "conferredDate": "2025-10-10", "expectedDateOfCompletion": "2025-04-02", "status": "ATTEMPTED BUT WAS NOT COMPLETED", "resultType": "Pass", "verificationStatus": "Verified", "instructionInEnglish": true, "qualificationComments": "Test qualification comment", "uniqueExternalId": "QUAL-EXT-001" } ], "workExperiences": [ { "externalId": "WE-001", "crmRecordId": "CRM-WE-001", "position": "CEO", "employer": "Infosys", "startDate": "2000-01-01", "endDate": "2000-01-02", "countryObtained": { "crmRecordId": "CRM-004", "uniqueCountryExternalId": "7103-IND-356-0", "code": "AU", "value": "Australia" }, "contactPerson": { "firstName": "Cesare", "lastName": "Papi" }, "contactAddress": "boss@job.com", "contactPhone": "078 04985435", "isHistoric": false } ], "payment": { "mode": "Western Union", "amount": "100.00", "transactionAmount": "100.00", "datePaid": "2024-10-26", "transactionSource": "WU", "transactionReference": "lkcc98udf98dfvk3497jcod093", "isPaid": true, "feeWaiverCode": { "code": 1212 } } } }
	}
	**/
	@HttpPatch
	global static void handlePatch() {
		RESTlib_ClientFactoryUtility.getInstance().setSourceFactory(new ApplicationWS()).getHandlePatch().execute();
	}

	/**
	 * @description Implementation Factory getter
	 * @return `RESTlib_ClientImplFactory`
	 */
	public RESTlib_ClientImplFactory getClientImplFactory() {
		return new ApplicationImplFactory();
	}
}