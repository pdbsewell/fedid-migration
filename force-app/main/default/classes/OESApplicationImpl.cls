/**
 * @description OES Implementation of the Application Webservice.
 * This class is responsible for handling the POST and PATCH requests for the OES Application Webservice. GET & PUT are not implemented yet.
 * @author      Nick Guia
 * @since       MAY.6.2024
 * @group      OES Application Webservice v3
 */
public with sharing class OESApplicationImpl implements RESTlib_IClientImpl {
	/**
	 * @description Get getter. CURRENTLY NOT IMPLEMENTED
	 * @return `RESTlib_ClientImplHandler`
	 */
	public RESTlib_ClientImplHandler getHandleGet() {
		return null; // new HandleGet();
	}
	/**
	 * @description Post getter
	 * @return `RESTlib_ClientImplHandler`
	 */
	public RESTlib_ClientImplHandler getHandlePost() {
		return new HandlePost();
	}
	/**
	 * @description Put getter
	 * @return `RESTlib_ClientImplHandler`
	 */
	public RESTlib_ClientImplHandler getHandlePut() {
		return null; // Not implemented yet
	}
	/**
	 * @description Patch getter
	 * @return `RESTlib_ClientImplHandler`
	 * @example
	 * OESApplicationImpl.HandlePatch patch = new OESApplicationImpl.HandlePatch();
	 */
	public RESTlib_ClientImplHandler getHandlePatch() {
		Nebula.Logger.info('OESApplicationImpl.getHandlePatch');
		return new HandlePatch();
	}
	/**
	 * @description valid values for ACP fields These are deprecated and should be removed once v3 is stable
	 */
	@TestVisible
	public static final Set<String> ACP_VALID_BASIS_FOR_ADMISSION_TYPE = new Set<String>{
		'311: HIGHER EDUCATION COURSE (COMPLETE/INCOMPLETE, AUST/OS)',
		'312: TWO SINGLE HIGHER EDUCATION UNITS',
		'401: WORK AND LIFE EXPERIENCE'
	};
	/**
	 * @description valid values for ACP fields These are deprecated and should be removed once v3 is stable
	 */
	@TestVisible
	public static final Set<String> ACP_VALID_DOCUMENTATION_STATUS = new Set<String>{ 'Satisfied' };
	/**
	 * @description valid values for ACP fields These are deprecated and should be removed once v3 is stable
	 */
	@TestVisible
	public static final Set<String> ACP_VALID_OUTCOME_STATUS = new Set<String>{ 'Offer' };
	/**
	 * @description valid values for ACP fields These are deprecated and should be removed once v3 is stable
	 */
	@TestVisible
	public static final Set<String> ACP_VALID_ENTRY_QUAL_STATUS = new Set<String>{ 'Qualified' };
	/**
	 * @description valid values for ACP fields These are deprecated and should be removed once v3 is stable
	 */
	@TestVisible
	public static final Set<String> ACP_VALID_OFFER_RESPONSE_STATUS = new Set<String>{ 'Pending' };

	/**
	 * @description converts the wrapper class an ACP SObject. Only populates
	 * the OES-specific fields (for now)
	 * TODO: change to non-static once migrated to the framework
	 * TODO : should populate all fields rather than OES-specific fields
	 * @return `Application_Course_Preference__c`
	 * @throws AgentPortalPayload.ApplicantException
	 */
	public static Application_Course_Preference__c parseCdmToAcp(AgentPortalPayload.CDM_ApplicationCoursePreference cdm) {
		Application_Course_Preference__c acp = new Application_Course_Preference__c();
		acp.Basis_For_Adminssion_Type__c = cdm.basisForAdmissionType;

		/**
		 * assign LOVs based on their designated Unique Keys
		 * this approach may not work if there will be more than
		 * one potential value on these fields.
		 */
		acp.Documentation_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'SATISFIED-ADM_DOC_STATUS');
		acp.Outcome_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'OFFER-ADM_OUTCOME_STATUS');
		acp.Entry_Qualification_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'QUALIFIED-ADM_ENTRY_QUAL_STATUS');
		acp.Offer_Response_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'PENDING-ADM_OFFER_RESP_STATUS');

		// dates
		acp.Offer_Date__c = cdm.offerDate;
		acp.Actual_Offer_Response_Date__c = cdm.actualOfferResponseDate;

		return acp;
	}

	/**
	 * @description list of validation rules for OES - ACP records
	 * TODO: change to non-static once migrated to the framework
	 * @param cdm : AgentPortalPayload.CDM_ApplicationCoursePreference
	 * @throws AgentPortalPayload.ApplicantException
	 */
	public static void validateCdmAcp(AgentPortalPayload.CDM_ApplicationCoursePreference cdm) {
		if (String.isNotBlank(cdm.basisForAdmissionType)) {
			validateBasisForAdmissionType(cdm.basisForAdmissionType);
		}

		if (String.isNotBlank(cdm.documentationStatus)) {
			validateDocumentationStatus(cdm.documentationStatus);
		}

		if (String.isNotBlank(cdm.outcomeStatus)) {
			validateOutcomeStatus(cdm.outcomeStatus);
		}

		if (String.isNotBlank(cdm.entryQualificationStatus)) {
			validateEntryQualificationStatus(cdm.entryQualificationStatus);
		}

		if (String.isNotBlank(cdm.offerResponseStatus)) {
			validateOfferResponseStatus(cdm.offerResponseStatus);
		}

		if (cdm.offerDate != null && cdm.actualOfferResponseDate != null) {
			validateOfferAndResponseDate(cdm.offerDate, cdm.actualOfferResponseDate);
		}
	}

	/**
	 * @description validation rules for basis for admission type
	 * TODO: change to non-static once migrated to the framework
	 * @param basisForAdmissionType
	 */
	@TestVisible
	private static void validateBasisForAdmissionType(String basisForAdmissionType) {
		if (!ACP_VALID_BASIS_FOR_ADMISSION_TYPE.contains(basisForAdmissionType)) {
			throw new AgentPortalPayload.ApplicantException('	 for Admission Type : ' + basisForAdmissionType);
		}
	}

	/**
	 * @description validation rules documentation status
	 * TODO: change to non-static once migrated to the framework
	 * @param documentationStatus
	 */
	@TestVisible
	private static void validateDocumentationStatus(String documentationStatus) {
		if (!ACP_VALID_DOCUMENTATION_STATUS.contains(documentationStatus)) {
			throw new AgentPortalPayload.ApplicantException('Invalid Documentation Status : ' + documentationStatus);
		}
	}

	/**
	 * @description validation rules for outcome status
	 * TODO: change to non-static once migrated to the framework
	 * @param outcomeStatus
	 */
	@TestVisible
	private static void validateOutcomeStatus(String outcomeStatus) {
		if (!ACP_VALID_OUTCOME_STATUS.contains(outcomeStatus)) {
			throw new AgentPortalPayload.ApplicantException('Invalid Outcome Status : ' + outcomeStatus);
		}
	}

	/**
	 * @description validation rules for entry qualification status
	 * TODO: change to non-static once migrated to the framework
	 * @param entryQualStatus
	 */
	@TestVisible
	private static void validateEntryQualificationStatus(String entryQualStatus) {
		if (!ACP_VALID_ENTRY_QUAL_STATUS.contains(entryQualStatus)) {
			throw new AgentPortalPayload.ApplicantException('Invalid Entry Qualification Status : ' + entryQualStatus);
		}
	}

	/**
	 * @description validation rules for offer response status
	 * TODO: change to non-static once migrated to the framework
	 * @param offerResponseStatus
	 */
	@TestVisible
	private static void validateOfferResponseStatus(String offerResponseStatus) {
		if (!ACP_VALID_OFFER_RESPONSE_STATUS.contains(offerResponseStatus)) {
			throw new AgentPortalPayload.ApplicantException('Invalid Offer Response Status : ' + offerResponseStatus);
		}
	}

	/**
	 * @description validation rules for offer date and actual offer response date
	 * TODO: change to non-static once migrated to the framework
	 * @param offerDate
	 * @param actualOfferResponseDate
	 */
	@TestVisible
	private static void validateOfferAndResponseDate(Date offerDate, Date actualOfferResponseDate) {
		if (actualOfferResponseDate < offerDate) {
			throw new AgentPortalPayload.ApplicantException('Actual Offer Response Date must be greater than Offer Date');
		}
	}
	/**
	 * @description Handle POST request for OES Application
	 */
	public with sharing class HandlePost extends RESTlib_ClientImplHandler {
		/**
		 * @description Request Type getter
		 * @return `Type`
		 */
		public override Type getRequestType() {
			Nebula.Logger.info('OESApplicationImpl.HandlePost.getRequestType');
			return OESApplicationPayload.PostRequest.class;
		}

		/**
		 * @description Response Type getter
		 * @return `Type`
		 */
		public override Type getResponseType() {
			Nebula.Logger.info('OESApplicationImpl.HandlePost.getResponseType');
			return OESApplicationPayload.PostResponse.class;
		}

		/**
		 * @description get request payload from custom params
		 * @return `RESTlib_Payload.Request`
		 */
		@TestVisible
		protected override RESTlib_Payload.Request getRequestPayload() {
			Nebula.Logger.info('OESApplicationImpl.HandlePost.getRequestPayload');
			String jsonStr = RestContext.request.requestBody.toString();
			return (OESApplicationPayload.PostRequest) JSON.deserialize(jsonStr, OESApplicationPayload.PostRequest.class);
		}
		/**
		 * @description Validate the request object
		 * @param reqObj The request object
		 * @throws RESTlib_Ex.ListException
		 */
		public override void validate(RESTlib_Payload.Request reqObj) {
			Nebula.Logger.info('OESApplicationImpl.HandlePost.validate Request:'+reqObj);
			RESTlib_Ex.InvalidRequestException exceptions;
			OESApplicationPayload.PostRequest req;
			OESApplicationValidations validator = new OESApplicationValidations();
			req = (OESApplicationPayload.PostRequest) reqObj;

			exceptions = validator.validate(req);
			if (exceptions != null) {
				throw exceptions;
			}
		}
		/**
		 * @description Processes the POST request to create a new application
		 * @param reqObj base request object
		 * @param responseObj base response object
		 * @return `RESTlib_Payload.Response`
		 * @throws RESTlib_Ex.WebServiceException
		 */
		public override RESTlib_Payload.Response process(
			RESTlib_Payload.Request reqObj,
			RESTlib_Payload.Response responseObj
		) {
			Nebula.Logger.info('OESApplicationImpl.HandlePost.process Request:'+reqObj);
			OESApplicationPayload.PostRequest req = (OESApplicationPayload.PostRequest) reqObj;
			OESApplicationPayload.PostResponse respObj = (OESApplicationPayload.PostResponse) responseObj;
			OESApplicationPayload.PostResponse resp = populatePostResponse( req, respObj);
			return resp;
		}

		/**
		 *Populate and return PostResponse
		 * @param oesRequestPayload OESApplicationPayload.PostRequest
		 * @param resp OESApplicationPayload.PostResponse 
		 * @return `OESApplicationPayload.PostResponse`
		 * @throws RESTlib_Ex.WebServiceException
		 */
		private OESApplicationPayload.PostResponse populatePostResponse(OESApplicationPayload.PostRequest req, 
																	OESApplicationPayload.PostResponse resp){
		try {
				// get the contact id from the contact CRM_Id__c or Id depending on user
				req.contactId = AgentPortalServices.getContact(
						req.contactId,
						AgentPortalConstants.APPLICANT_PERSONA,
						AgentPortalConstants.SYSTEM_CONTEXT
					)
					?.Id;
				// Use the new method to create the Application__c record
				Application__c newApplication = OESApplicationPayload.createApplicationRecord(req);

				// Get the email and phone from the request
				String email = CommonWSPayload.getEmail(req.email, 'personal');
				String phone = CommonWSPayload.getPhoneNumber(req.phone, 'Mobile');

				// Use AgentPortalServices to create the application
				OESApplicationPayload.ApplicationPostResponse applicationDetails = new OESApplicationPayload.ApplicationPostResponse();
				applicationDetails.populateFromApplication(
					(Application__c) AgentPortalServices.createApplication(newApplication, email, phone)
				);

				resp.application = applicationDetails;
				resp.message = 'Application created successfully';
				resp.success = true;
				Nebula.Logger.info('OESApplicationImpl.HandlePost.process Response:'+resp);

			} catch (Exception e) {
				throw new RESTlib_Ex.WebServiceException('Error creating application: ' + e.getMessage());
			}
			Nebula.Logger.saveLog();
			return resp;
		}
	}
	
	

	/**
	 * @description HandlePatch class
	 * This class is responsible for handling the PATCH requests for the OES Application Webservice.
	 * @author      Girish P
	 * @group 	  OES Application Webservice v3
	 */
	public with sharing class HandlePatch extends RESTlib_ClientImplHandler {
		OESApplicationPayload.PatchRequest oesRequestPayload;
		RESTlib_Ex.InvalidRequestException exceptions;
		/**
		 * @description Request Type getter
		 * @return `Type`
		 */
		public override Type getRequestType() {
			return OESApplicationPayload.PatchRequest.class;
		}

		/**
		 * @description Response Type getter
		 * @return `Type`
		 */
		public override Type getResponseType() {
			return OESApplicationPayload.PatchResponse.class;
		}
		/**
		 * @description Validate the request object
		 * @param reqObj The request object
		 * @throws RESTlib_Ex.ListException
		 */
		public override void validate(RESTlib_Payload.Request reqObj) {
			Nebula.Logger.info('OESApplicationImpl.HandlePatch.validate Request: ' + reqObj);
			RestLib_Ex.InvalidRequestException exceptions2 = new RestLib_Ex.InvalidRequestException();
			OESApplicationPayload.CDM_Application reqApp = OESApplicationPayload.fromApplicationJson(
				JSON.serialize(((OESApplicationPayload.PatchRequest) reqObj).application)
			);
			Nebula.Logger.info('OESApplicationImpl.HandlePatch.validate Response: ' + reqApp);
			OESApplicationPayload.PatchRequest req = (OESApplicationPayload.PatchRequest) reqObj;
			req.application = reqApp;
			OESApplicationValidations validator = new OESApplicationValidations(req);
			exceptions2 = validator.validatePatch(req);

			if (exceptions2 != null && String.isNotBlank(exceptions2.getListExceptionSummaryString())) {
				throw exceptions2;
			}
		}
		/**
		 * @description Processes the POST request to create a new application
		 * @param reqObj base request object
		 * @param responseObj base response object
		 * @return `RESTlib_Payload.Response`
		 * @throws RESTlib_Ex.WebServiceException
		 */
		public override RESTlib_Payload.Response process(
			RESTlib_Payload.Request reqObj,
			RESTlib_Payload.Response responseObj
		) {
				OESApplicationPayload.PatchRequest oesRequestPayload = (OESApplicationPayload.PatchRequest) reqObj;
				OESApplicationPayload.PatchResponse patchResponse = populatePatchResponse( oesRequestPayload , responseObj);

			return patchResponse;
		}
	
		/**
		 *Populate and return PatchResponse
		 * @param oesRequestPayload OESApplicationPayload.PatchRequest
		 * @param responseObj RESTlib_Payload.Response 
		 * @return `OESApplicationPayload.PatchResponse`
		 * @throws RESTlib_Ex.WebServiceException
		 */
		private OESApplicationPayload.PatchResponse populatePatchResponse(OESApplicationPayload.PatchRequest oesRequestPayload, 
															RESTlib_Payload.Response responseObj)
		{
			OESApplicationPayload.PatchResponse patchResponse = (OESApplicationPayload.PatchResponse) responseObj;
			try {
				Nebula.Logger.info('OESApplicationImpl.HandlePatch.process Request: ' + oesRequestPayload);

				// Nebula.Logger.info('OESApplicationImpl.HandlePatch.process' + reqObj);
				OESApplicationPayload.CDM_Application reqApp = OESApplicationPayload.fromApplicationJson(
					JSON.serialize(oesRequestPayload.application)
				);
				oesRequestPayload = new OESApplicationPayload.PatchRequest(reqApp);
				// Process the Patch Application shared application logic
				patchResponse.application = oesRequestPayload.process().application;
				patchResponse.message = 'Application updated successfully';
				patchResponse.success = true;
				patchResponse.statusCode = 200;
				Nebula.Logger.info('OESApplicationImpl.HandlePatch.process Response: ' + patchResponse);

			} catch (Exception e) {
				throw new RESTlib_Ex.WebServiceException(e.getMessage());
			}
			Nebula.Logger.saveLog();
			return patchResponse;
		}
	}
}