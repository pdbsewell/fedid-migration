/**
 * @description Payload class for GR Document Request REST API
 * @author      Vishal Gupta
 * @since       21.10.2024
 */
public inherited sharing class GRDocumentRequestPayload {
    /**
     * @description request payload of Document Request REST API
     */
    public virtual class PostRequest extends RESTlib_Payload.Request {
        public String applicantId { get; set; } //Callista application Id from application object
        public String hdrApplicationNumber { get; set; } //Callista HDR application id from ACP object
        public Integer requestSequenceNumber { get; set; }//sequence number from Application Qualification provided
        //public String studentId { get; set; }
        //public String hdrAdmApplicationNumber { get; set; }
        public String requestType { get; set; } //Qualification/Claim type not the Document File Type
        public Integer claimSequenceNumber { get; set; } //Sequence number for the claim/qualification
        public String description { get; set; }
        public String requestReason { get; set; }//Document request reason (checklist comment)
        public String requestDate { get; set; } // date of request
        public String notifyEmailAddresses { get; set; } //who to email once student has responded
        // public String smsDocumentId  { get; set; }
        // public String submittedDate { get; set; }
        public String cancelledDate { get; set; } //cancelled date time from callista
    }

    /**
     * @description response payload of Document Request REST API
     */
    public virtual class PostResponse extends RESTlib_Payload.Response {}
}