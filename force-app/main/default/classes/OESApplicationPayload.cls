/**
 * @description      OES Application Payload class. This class is responsible for handling the payload for OES Application Webservice.
 * 						Parse the request and response payload for OES Application Webservice and map to respective objects.
 * @author            Ben Greenland
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   2024-10-23   Ben Greenland   Initial Version
 * @group             OES Application Webservice v3
 **/
public inherited sharing class OESApplicationPayload extends ApplicationWSWrapper {
	public OESApplicationPayload() {
		super();
	}
	/**
	 * @description Request payload for HTTP POST
	 */
	public class PostRequest extends RESTlib_Payload.Request {
		/** @description The campus location of the applicant */
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
		public ApplicationPostResponse application { get; set; }

		/**
		 * @description Response message
		 */
		public String message { get; set; }
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
			Source_System__c = AgentPortalConstants.OES_CREATE_SOURCE,
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
	 * @description ApplicationPostResponse payload.
	 * This  wrapper class is responsible for handling the response payload for OES Application Webservice.
	 * Map the object data to response payload attributes.
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
	 * @description Request payload for HTTP PATCH
	 */
	public class PatchRequest extends RESTlib_Payload.Request {
		/** @description The application to be patched */
		public OESApplicationPayload.CDM_Application application { get; set; }
		private Boolean postSubmitPaymentUpdate;
		/** @description The patchApplicationService to be used for processing the PATCH request*/
		ApplicationWSWrapper.ApplicationResponseWrapper applicationResponseWrapper;
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
			this.applicationResponseWrapper = new ApplicationWSWrapper.ApplicationResponseWrapper();
			this.postSubmitPaymentUpdate = false;
		}
		/**
		 * @description Constructor for PatchRequest initializes the application and patchApplicationService
		 *
		 * @param application The application to be patched
		 */
		public PatchRequest(CDM_Application application) {
			this.applicationResponseWrapper = new ApplicationWSWrapper.ApplicationResponseWrapper();
			this.application = application;
			this.patchApplicationService = new ApplicationWSService.PatchApplicationService(this.application);
		}
		/**
		 * @description Process the PATCH request. This method will update the application and only OES specific use case
		 * This inherits the process method from ApplicationWSService.PatchApplicationService service class
		 * which has the shared processing logic for APNG and OES both
		 */
		public ApplicationWSWrapper.ApplicationResponseWrapper process() {
			Map<String, Application_Course_Preference__c> acpByExternalId = new Map<String, Application_Course_Preference__c>();
			try {
				if (this.patchApplicationService?.applicationDetails?.Status__c == 'Submitted') {
					/**
					 * update ACPs and simplify response with only success messages
					 * rather than requerying everything again.
					 */
					Set<String> acpExtIds = new Set<String>();
					for (CDM_ApplicationCoursePreference icdm : application.coursePreferences) {
						// collect external IDs
						if (String.isNotBlank(icdm.externalId)) {
							acpExtIds.add(icdm.externalId);
						}
					}
					for (Application_Course_Preference__c iAcp : [
						SELECT Id, ACP_ID__c
						FROM Application_Course_Preference__c
						WHERE ACP_ID__c IN :acpExtIds
					]) {
						acpByExternalId.put(iAcp.ACP_ID__c, iAcp);
					}
					List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
					for (CDM_ApplicationCoursePreference icdm : application.coursePreferences) {
						Application_Course_Preference__c acp = new Application_Course_Preference__c();
						//OES sends basis for admissiontype as key:value but we only need the key to updat it against Basis_For_Adminssion_Type__c
            			//Parse only the key before ':' and assign it to the field  
            			acp.Basis_For_Adminssion_Type__c = icdm.basisForAdmissionType!=null?icdm.basisForAdmissionType.substringBefore(':'):icdm.basisForAdmissionType;
        
						/**
						 * assign LOVs based on their designated Unique Keys
						 * this approach may not work if there will be more than
						 * one potential value on these fields.
						 * For OES these are only applicable and valid values as per the business requirement. OES only update ACPs once application
						 * is currently in submitted status and just update the ACPs with the values provided in the payload.
						 */
						acp.Documentation_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'SATISFIED-ADM_DOC_STATUS');
						acp.Outcome_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'OFFER-ADM_OUTCOME_STATUS');
						acp.Entry_Qualification_Status_LOV__r = new List_of_Values__c(
							Unique_Key__c = 'QUALIFIED-ADM_ENTRY_QUAL_STATUS'
						);
						acp.Offer_Response_Status_LOV__r = new List_of_Values__c(Unique_Key__c = 'PENDING-ADM_OFFER_RESP_STATUS');
						acp.Offer_Date__c = icdm.offerDate;
 						//OES sends Offer lapse date in actualOfferResponseDate as it was mismapped at the beginning
            			//To reduce overhead of MIX/OES changing the mapping, the value from actualOfferResponseDate is assigned to
            			//Offer_Response_Date__c and assign it to the field 
            			acp.Offer_Response_Date__c = icdm.actualOfferResponseDate;
						acp.Id = acpByExternalId?.get(icdm.externalId)?.Id;
						acpList.add(acp);
					}
					update acpList; //implied never empty if acpByExternalId is not empty
					// Get the updated course preferences and set it to the response
					applicationResponseWrapper.application = new ApplicationWSWrapper.ApplicationWrapper();
					applicationResponseWrapper.application.coursePreferences = new ApplicationWSWrapper.ApplicationCoursePreference()
						.fromObjectList(
							ApplicationWSService.getApplicationCoursePreferences(this.patchApplicationService.applicationDetails.Id)
						);
				} else {
					// call the shared processing logic for OES if Status__c is anything other than Submitted
					applicationResponseWrapper = this.patchApplicationService.process();
				}
			} catch (Exception e) {
				Nebula.Logger.error('Exception OESApplicationPayload.process()', e);
				throw e;
			}
			return applicationResponseWrapper;
		}
	}
	/**
	 * @description Request payload for HTTP patch
	 */
	public class PatchResponse extends RESTlib_Payload.Response {
		public Object application;
	}
	/**
	 * @description CDM_Application payload inherits ApplicationWSWrapper.CDM_Application.
	 * coursePreferences is dfined to handle the course preferences for OES Application Webservice and extends the base class.
	 */
	public class CDM_Application extends ApplicationWSWrapper.CDM_Application {
		public CDM_ApplicationCoursePreference[] coursePreferences;
	}
	/**
	 * @description CDM_ApplicationCoursePreference payload inherits ApplicationWSWrapper.CDM_ApplicationCoursePreference.
	 *
	 */
	public class CDM_ApplicationCoursePreference extends ApplicationWSWrapper.CDM_ApplicationCoursePreference {
		/** @description basisForAdmissionType*/
		public String basisForAdmissionType { get; set; }
		/** @description documentationStatus */
		public String documentationStatus { get; set; }
		/** @description outcomeStatus*/
		public String outcomeStatus { get; set; }
		/** @description entryQualificationStatus*/
		public String entryQualificationStatus { get; set; }
		/** @description offerResponseStatus*/
		public String offerResponseStatus { get; set; }
		/** @description offerDate*/
		public Date offerDate { get; set; }
		/** @description actualOfferResponseDate*/
		public Date actualOfferResponseDate { get; set; }
	}
	/**
	 * @description Converts the JSON string to OESApplicationPayload.PatchRequest
	 * @param jsonString The JSON string to deserialize
	 * @return OESApplicationPayload.PatchRequest
	 */
	public static OESApplicationPayload.PatchRequest fromJson(String jsonString) {
		return (OESApplicationPayload.PatchRequest) JSON.deserialize(jsonString, OESApplicationPayload.PatchRequest.class);
	}
	/**
	 *
	 * convert the JSON string to CDM_Application
	 * @param jsonString The JSON string to deserialize
	 * @return           `OESApplicationPayload.CDM_Application`
	 */
	public static OESApplicationPayload.CDM_Application fromApplicationJson(String jsonString) {
		return (OESApplicationPayload.CDM_Application) JSON.deserialize(
			jsonString,
			OESApplicationPayload.CDM_Application.class
		);
	}
}