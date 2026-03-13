/**
 * @description       APNG Application WS Implementation. This class is responsible for handling the HTTP requests for the APNG Application Web Service.
 * Implements the RESTlib_IClientImpl interface. GET, POST and PATCH requests are handled in this class.
 * @since             2024-09-20
 * @version           3.0
 * @author            Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-09-20   Ben Greenland   Initial Version
 * @group             APNG Application Webservice v3
 **/
public with sharing class APNGApplicationImpl implements RESTlib_IClientImpl {
	/**
	 * @description Get getter
	 * @return `RESTlib_ClientImplHandler`
	 */
	public RESTlib_ClientImplHandler getHandleGet() {
		return new HandleGet();
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
	 */
	public RESTlib_ClientImplHandler getHandlePatch() {
		return new HandlePatch();
	}
	/**
	 * @description Get Handler implementation
	 */
	public with sharing class HandleGet extends RESTlib_ClientImplHandler {
		/**
		 * @description Request Type getter
		 * @return `Type`
		 */
		public override Type getRequestType() {
			return APNGApplicationPayload.GetRequest.class;
		}

		/**
		 * @description Response Type getter
		 * @return `Type`
		 */
		public override Type getResponseType() {
			String jsonStr = JSON.serialize(RestContext.request.params);
			APNGApplicationPayload.GetRequest req = (APNGApplicationPayload.GetRequest) JSON.deserialize(
				jsonStr,
				APNGApplicationPayload.GetRequest.class
			);
			switch on req.related.toLowerCase() {
				when 'qualifications' {
					return APNGApplicationPayload.GetResponseQualifications.class;
				}
				when 'experiences' {
					return APNGApplicationPayload.GetResponseWorkExperiences.class;
				}
				when else {
					return APNGApplicationPayload.GetResponseApplication.class;
				}
			}
		}

		/**
		 * @description get request payload from custom params
		 * @return `RESTlib_Payload.Request`
		 */
		@TestVisible
		protected override RESTlib_Payload.Request getRequestPayload() {
			String jsonStr = JSON.serialize(RestContext.request.params);
			return (APNGApplicationPayload.GetRequest) JSON.deserialize(jsonStr, APNGApplicationPayload.GetRequest.class);
		}

		/**
		 * @description validate the request object. called before processing the request
		 * @param reqObj base request object
		 * @throws RESTlib_Ex.InvalidRequestException
		 */
		public override void validate(RESTlib_Payload.Request reqObj) {
			APNGApplicationPayload.GetRequest req = (APNGApplicationPayload.GetRequest) reqObj;
           Nebula.Logger.info('APNGApplicationImpl.HandleGet.validate Request: ' + reqObj);

			if (String.isBlank(req.applicationId)) {
				throw new RESTlib_Ex.InvalidRequestException('Application Id cannot be empty');
			}
			if (
				!String.isBlank(req.related) &&
				!(req.related.equalsIgnoreCase('qualifications') || req.related.equalsIgnoreCase('experiences'))
			) {
				throw new RESTlib_Ex.InvalidRequestException('Request Type: ' + req.related + ' is not recognised');
			}
		}

		/**
		 * @description Get Application Details.
		 * @param reqObj      base request object
		 * @param responseObj base response object
		 * @return `RESTlib_Payload.Response`
		 * @throws RESTlib_Ex.WebServiceException
		 */
		public virtual override RESTlib_Payload.Response process(
			RESTlib_Payload.Request reqObj,
			RESTlib_Payload.Response responseObj
		) {
			APNGApplicationPayload.GetRequest req = (APNGApplicationPayload.GetRequest) reqObj;
            Nebula.Logger.info('APNGApplicationImpl.HandleGet.validate process Request: ' + reqObj);
			//APNGApplicationPayload.GetResponseApplication resp = (APNGApplicationPayload.GetResponseApplication) responseObj;
			if (req?.applicationId != null) {
				try {
					switch on req.related.toLowerCase() {
						when 'qualifications' {
							APNGApplicationPayload.GetResponseQualifications resp  = populateQualificationResponse(req, responseObj);
							return resp;
						}
						when 'experiences' {
							APNGApplicationPayload.GetResponseWorkExperiences resp = populateWorkExperienceResponse(req, responseObj);
							return resp;
						}
						when else {
							// request is for Get Application by Id
							APNGApplicationPayload.GetResponseApplication resp = (APNGApplicationPayload.GetResponseApplication) responseObj;
							APNGApplicationPayload.ApplicationDetails applicationDetails = APNGApplicationSelector.getApplicationDetails(
								req.applicationId
							);
							if (applicationDetails != null) {
								resp.application = applicationDetails;
								resp.message = 'Application(s) found!';
							} else {
								throw new RESTlib_Ex.NotFoundException('Application not found');
							}
            				Nebula.Logger.info('APNGApplicationImpl.HandleGet.validate process Response: ' + resp);
							return resp;
						}
					}
				} catch (APNGApplicationPayload.ApplicationException e) {
					// rethrow
					throw new RESTlib_Ex.WebServiceException('Error retrieving application');
				}
			} else {
				throw new RESTlib_Ex.WebServiceException('Error retrieving application');
			}
		}

		/**
		 * @description Populate & return WorkExperience response
		 * @param req      APNGApplicationPayload.GetRequest
		 * @param responseObj RESTlib_Payload.Response
		 * @return `APNGApplicationPayload.GetResponseWorkExperiences`
		 */
		private APNGApplicationPayload.GetResponseWorkExperiences populateWorkExperienceResponse(APNGApplicationPayload.GetRequest req,
																							  RESTlib_Payload.Response responseObj )
		{
			APNGApplicationPayload.GetResponseWorkExperiences resp = (APNGApplicationPayload.GetResponseWorkExperiences) responseObj;
			APNGApplicationPayload.WorkExperiences workExperienceDetails = APNGApplicationSelector.getWorkExperiencesByApplicationId(
																				req.applicationId);
			resp.application = workExperienceDetails;
			if (workExperienceDetails.recordCount > 0) {
				resp.message = 'Work Experience(s) found!';
				resp.success = true;
			} else {
				resp.message = 'No Work Experience(s) found for this application.';
				resp.success = true;
			}
			return resp;
		}

		/**
		 * @description Populate & return Qualification response
		 * @param req      APNGApplicationPayload.GetRequest
		 * @param responseObj RESTlib_Payload.Response
		 * @return `APNGApplicationPayload.GetResponseQualifications`
		 */
		private APNGApplicationPayload.GetResponseQualifications  populateQualificationResponse(APNGApplicationPayload.GetRequest req,
																					RESTlib_Payload.Response responseObj)
		{
			APNGApplicationPayload.GetResponseQualifications resp = (APNGApplicationPayload.GetResponseQualifications) responseObj;
			APNGApplicationPayload.Qualifications qualificationDetails = APNGApplicationSelector.getContactQualificationsByApplicationId(
				req.applicationId
			);
			resp.application = qualificationDetails;
			if (qualificationDetails.recordCount > 0) {
				resp.message = 'Qualification(s) found!';
				resp.success = true;
			} else {
				resp.message = 'No Qualification(s) found for this application.';
				resp.success = true;
			}
			return resp;
		}
	}
	/**
	 * HandlePost request for APNG Application
	 * HTTP POST request to create a new application
	 * @group HandlePost
	 */
	public with sharing class HandlePost extends RESTlib_ClientImplHandler {
		/**
		 * @description Request Type getter
		 * @return `Type`
		 */
		public override Type getRequestType() {
			return APNGApplicationPayload.PostRequest.class;
		}

		/**
		 * @description Response Type getter
		 * @return `Type`
		 */
		public override Type getResponseType() {
			return APNGApplicationPayload.PostResponse.class;
		}

		/**
		 * @description get request payload from custom params
		 * @return `RESTlib_Payload.Request`
		 */
		@TestVisible
		protected override RESTlib_Payload.Request getRequestPayload() {
			String jsonStr = RestContext.request.requestBody.toString();
			return (APNGApplicationPayload.PostRequest) JSON.deserialize(jsonStr, APNGApplicationPayload.PostRequest.class);
		}
		/**
		 * Validate the request object. All validations are done here.
		 * @param reqObj base request object
		 */
		public override void validate(RESTlib_Payload.Request reqObj) {
			Nebula.Logger.info('APNGApplicationImpl.HandlePost.validate Request: ' + reqObj);
			APNGApplicationPayload.PostRequest req = (APNGApplicationPayload.PostRequest) reqObj;
			APNGApplicationValidations validator = new APNGApplicationValidations();
			RESTlib_Ex.InvalidRequestException exceptions = validator.validate(req);
			if (exceptions != null) {
				throw exceptions;
			}
		}
		/**
		 * Processes the POST request to create a new application
		 * @param reqObj base request object
		 * @param responseObj base response object
		 * @return `RESTlib_Payload.Response`
		 * @throws RESTlib_Ex.WebServiceException
		 */
		public override RESTlib_Payload.Response process(
			RESTlib_Payload.Request reqObj,
			RESTlib_Payload.Response responseObj
		) {
			Nebula.Logger.info('APNGApplicationImpl.HandlePost.process Request: ' + reqObj);
			APNGApplicationPayload.PostRequest req = (APNGApplicationPayload.PostRequest) reqObj;
			APNGApplicationPayload.PostResponse resp = (APNGApplicationPayload.PostResponse) responseObj;
			try {
				// get the contact id from the contact CRM_Id__c or Id depending on user
				req.contactId = AgentPortalServices.getContact(
						req.contactId,
						AgentPortalConstants.APPLICANT_PERSONA,
						AgentPortalConstants.SYSTEM_CONTEXT
					)
					?.Id;
				// Use the new method to create the Application__c record
				Application__c newApplication = APNGApplicationPayload.createApplicationRecord(req);

				// Get the email and phone from the request
				String email = CommonWSPayload.getEmail(req.email, 'personal');
				String phone = CommonWSPayload.getPhoneNumber(req.phone, 'Mobile');

				// Use AgentPortalServices to create the application
				APNGApplicationPayload.ApplicationPostResponse applicationDetails = new APNGApplicationPayload.ApplicationPostResponse();
				applicationDetails.populateFromApplication(
					(Application__c) AgentPortalServices.createApplication(newApplication, email, phone)
				);

				resp.application = applicationDetails;
				resp.message = 'Application created successfully';
				resp.success = true;
			} catch (Exception e) {
				throw new RESTlib_Ex.WebServiceException('Error creating application: ' + e.getMessage());
			}
			Nebula.Logger.info('APNGApplicationImpl.HandlePost.process Response: ' + resp);
			return resp;
		}
	}
	/**
	 * HandlePatch request for APNG Application HTTP PATCH request to update an existing application
	 */
	public with sharing class HandlePatch extends RESTlib_ClientImplHandler {
		APNGApplicationPayload.PatchRequest apngRequestPayload;
		RESTlib_Ex.InvalidRequestException exceptions;
		/**
		 * @description Request Type getter
		 * @return `Type`
		 */
		public override Type getRequestType() {
			return APNGApplicationPayload.PatchRequest.class;
		}

		/**
		 * @description Response Type getter
		 * @return `Type`
		 */
		public override Type getResponseType() {
			return APNGApplicationPayload.PatchResponse.class;
		}
		/**
		 * Validate the request object. All validations are done here.
		 * @param reqObj The request object
		 * @throws RESTlib_Ex.ListException
		 */
		public override void validate(RESTlib_Payload.Request reqObj) {
			APNGApplicationPayload.PatchRequest req = (APNGApplicationPayload.PatchRequest) super.getRequestPayload();
			Nebula.Logger.info('APNGApplicationImpl.HandlePatch.validate Request: ' + req);
			this.apngRequestPayload = req;
			exceptions = new APNGApplicationValidations().validatePatch(this.apngRequestPayload);
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
			RESTlib_Payload.Request apngPatchRequest,
			RESTlib_Payload.Response responseObj
		) {
			APNGApplicationPayload.PatchResponse patchResponse;
			try {
			   Nebula.Logger.info('APNGApplicationImpl.HandlePatch.process Request: ' + apngPatchRequest);
				APNGApplicationPayload.PatchRequest apngRequestPayload = (APNGApplicationPayload.PatchRequest) apngPatchRequest;
				apngRequestPayload = new APNGApplicationPayload.PatchRequest(apngRequestPayload.application);
				patchResponse = (APNGApplicationPayload.PatchResponse) responseObj;
				// Process the Patch Application shared application logic
				patchResponse.application = apngRequestPayload.process().application;
				patchResponse.message = 'Application updated successfully';
				patchResponse.success = true;
				patchResponse.statusCode = 200;
			    Nebula.Logger.info('APNGApplicationImpl.HandlePatch.process Response: ' + patchResponse);
			} catch (Exception e) {
				throw new RESTlib_Ex.WebServiceException('Error creating application: ' + e.getMessage());
			}
			return patchResponse;
		}
	}
}