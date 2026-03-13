/**
 * @File Name          : ProspectiveStudentWebService.cls
 * @Description        : Webservice class for Staged Prospective Student object
 * @Author             : Nick Guia
 * @Group              : Lead Management
 * @Revision
 * 	MAY.01.2018 	Nick Guia 	- Added exception logging
 *								- created put method
 * 	JUL.08.2019 	Nick Guia  	- Modified logic to insert Contact synchronously first, then insert SPS
 * 								  asynchronously. This is to further enhance CPU processing time.
 * 	DEC.03.2019		Nick Guia 	- Updated method for creating Contact to use new Exploding Leads classes
 */
@RestResource(urlMapping='/ProspectiveStudentWebService')
global without sharing class ProspectiveStudentWebService {

	/**
	 * @description inserts an sps record
	 * @param JSON that can be strictly serialized into an SPS object
	 * @return InsertSPSResponse
	 */
	@HttpPost
	global static PSWebService_Wrappers.InsertSPSResponse doPost(Staged_Prospective_Student__c prospectiveStudent) {

		PSWebService_Wrappers.InsertSPSResponse response =
			new PSWebService_Wrappers.InsertSPSResponse();

		if(prospectiveStudent != null) {
			response = insertSPS(prospectiveStudent);
		} else {
			//log exception with invalid payload
			LogUtilityException.logException(new System.IllegalArgumentException(PSWebService_Wrappers.INVALID_PAYLOAD));
			response.error = PSWebService_Wrappers.INVALID_PAYLOAD;
			response.description = PSWebService_Wrappers.INVALID_PAYLOAD;
			response.success = false;
		}

		return response;
	}

	/**
	 * @description inserts an sps record with provided 'Target Contact' indicated.
	 * 	In this scenario, we skip the 'matching criteria' using first name, last name, and email,
	 * 	and directly find the contact through the specified target contact instead. This will reduce
	 * 	the amount of processing time required. If 'Exploded Target' (Contact ID) is null in the payload,
	 * 	return an error response with invalid parameter
	 * @param JSON that can be strictly serialized into an SPS object. Must contact 'Exploded Target' (Contact ID)
	 * @return InsertSPSResponse
	 */
	@HttpPut
	global static PSWebService_Wrappers.InsertSPSResponse doPut(Staged_Prospective_Student__c prospectiveStudent) {
		PSWebService_Wrappers.InsertSPSResponse response =
			new PSWebService_Wrappers.InsertSPSResponse();

		if(prospectiveStudent != null && prospectiveStudent.Exploded_Target__c != null) {
			response = insertSPS(prospectiveStudent);
		} else {
			LogUtilityException.logException(new System.IllegalArgumentException(PSWebService_Wrappers.INVALID_PAYLOAD));
			response.error = PSWebService_Wrappers.INVALID_PAYLOAD;
			response.description = PSWebService_Wrappers.INVALID_PAYLOAD;
			response.success = false;
		}
		return response;
	}

	/**
	 * @description re-usable method for processing SPS insert and building appropriate
	 * 	response object.
	 * @param JSON that can be strictly serialized into an SPS object
	 * @return InsertSPSResponse
	 */
	private static PSWebService_Wrappers.InsertSPSResponse insertSPS(Staged_Prospective_Student__c prospectiveStudent) {
		Staged_Prospective_Student__c processedSPS;
		PSWebService_Wrappers.InsertSPSResponse response =
			new PSWebService_Wrappers.InsertSPSResponse();
		Contact conRec;

		try {
			if(prospectiveStudent.Exploded_Target__c == null) {
				//initialise Exploding Leads Service and generate a Contact
				StagedProspectiveStudentServices service = new StagedProspectiveStudentServices(prospectiveStudent);
				List<Staged_Prospective_Student__c> spsListWithContact = service.processProspectiveStudentContact();

				if(!spsListWithContact.isEmpty()) {
					prospectiveStudent = spsListWithContact[0];
				}
			}

			conRec = new Contact(Id = prospectiveStudent.Exploded_Target__c);

			//insert SPS asynchronously
			prospectiveStudent.is_Synchronous__c = false;
			insert prospectiveStudent;

		} catch(Exception e) {
			LogUtilityException.logException(e, prospectiveStudent);
			response.error = e.getStackTraceString();
		} finally {
			//update response

			//check if contact was successfully created / assigned to SPS
			if(conRec != null && conRec.Id != null) {
				response.contactId = conRec.Id;
				response.description = PSWebService_Wrappers.INSERT_CONTACT_SUCCESS;
				response.success = true;
			} else {
				response.description = PSWebService_Wrappers.INSERT_CONTACT_FAILED;
				response.success = false;
			}
		}
 		return response;
 	}
 }