/***********************************************************************
** Author: Ryan Wilson (OAKTON)
** Created Date: 13.AUG.2017
** Description: Response wrapper class for Admissions_AgentPortalCommsService
** @revision
 * 	17-08-2025	Sachin Shetty	Added constructors
***********************************************************************/
global without sharing class ObdAgentPortalCommsResponse {
    global String status;
    global String enquiryRecordId;
    global String error;

    // Default constructor
    global ObdAgentPortalCommsResponse() {
        this.status = null;
        this.enquiryRecordId = null;
        this.error = null;
    }

    // Overloaded constructor
    global ObdAgentPortalCommsResponse(String status, String enquiryRecordId, String error) {
        this.status = status;
        this.enquiryRecordId = enquiryRecordId;
        this.error = error;
    }
}