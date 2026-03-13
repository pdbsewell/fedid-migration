/**
 * @description This Apex class is used to for JSON serialization of the request
 *  body used to make an DocuSign Update Envelop Request.
 * It only contains the attributes that are used.
 * The relevant DocuSign documentation can be referenced:
 * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/update#envelopeUpdateSummary
 * @group DocuSign Update Envelop
 * @revision
 * 		17-08-2025	- Sachin Shetty	- Added Constructor
 */
public class DocuSignUpdateEnvelopsReqBody {

    /**
     * @description The status of the item.
     */
    public String status;

    /**
     * @description The reason the envelope or template was voided.
     */
    public String voidedReason;
    
    // Default constructor
    public DocuSignUpdateEnvelopsReqBody() { //NOPMD
    }
}