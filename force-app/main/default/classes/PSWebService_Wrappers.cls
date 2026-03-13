/**
 * @author 	Nick Guia
 * @date APR.18.2018
 * @description Contains all request and response wrappers for ProspectiveStudentWebService
 * @revision
 *  JUL.08.2019     Nick Guia   - added INSERT_CONTACT_SUCCESS, and INSERT_CONTACT_FAILED, 
 * 								  removed UNABLE_TO_INSERT_ERROR, and INSERT_SUCCESS_WITH_STATUS.
 * 								- Modified InsertSPSResponse
 */
global class PSWebService_Wrappers {

	//these messages are to be assigned as the description of the response
	public static final String INVALID_PAYLOAD = 'ERROR: Invalid payload with NULL parameter';
	public static final String INSERT_CONTACT_SUCCESS = 'Contact record successfully created';
	public static final String INSERT_CONTACT_FAILED = 'An error occurred while trying to create a Contact record';
	// public static final String UNABLE_TO_INSERT_ERROR = 'ERROR: An error occurred while trying to insert Staged Prospective Student Record';
	// public static final String INSERT_SUCCESS_WITH_STATUS = 'Staged Prospective Student record successfully created with Status : ';

	/**
	 * @description contains response wrapper for webservice
	 * 	classes that inserts SPS into Salesforce
	 */
	global class InsertSPSResponse {
		global Boolean success {get;set;}
        global String description {get;set;}
        global String error {get; set;}
		global Id contactId {get; set;}
	}
}