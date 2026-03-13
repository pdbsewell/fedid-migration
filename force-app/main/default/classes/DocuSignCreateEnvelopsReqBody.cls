/**
 * @description This Apex class is used to for JSON serialization of the request
 *  body used to make an DocuSign Create Envelop Request.
 * It only contains the attributes that are used.
 * The relevant DocuSign documentation can be referenced:
 * https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
 * @group DocuSign
 */
public class DocuSignCreateEnvelopsReqBody {
    
    public String emailSubject;
    public String emailBlurb;
    public String status;
    public List<Document> documents;
    public EnvelopeRecipients recipients;
    public String allowComments;
    public String allowReassign;
    public String brandId;
    public String enableWetSign;
    
    public Notification notification;
    public Expirations expirations;

    public List<CompositeTemplates> compositeTemplates;

    public class CompositeTemplates {
        public List<InlineTemplates> inlineTemplates;
        public Document documents;
    }

    public class Document {
        public String documentBase64;
        public String documentId;
        public String fileExtension;
        public String name;
    }

    public class InlineTemplates {
        public String sequence;
        public EnvelopeRecipients recipients;
    }

    public class EnvelopeRecipients {
        public List<Signer> signers;
    }

    public class Signer {
        public String email;
        public String name;
        public String clientUserId;
        public String recipientId;
        public String routingOrder;
        public EnvelopeRecipientTabs tabs;
    }

    public class EnvelopeRecipientTabs {
        public List<SignHere> signHereTabs;
        public List<DateSigned> dateSignedTabs;
    }

    public class DateSigned {
        public String documentId;
        public String anchorString;
        public String anchorXOffSet;
        public String anchorYOffSet;
    }

    public class SignHere {
        public String documentId;
        public String anchorString;
        public String anchorXOffSet;
        public String anchorYOffSet;
    }

    public class Notification {
        public Reminders reminders;
        public Expirations expirations;
    }

    public class Reminders {
        public String reminderDelay;
        public String reminderEnabled;
        public String reminderFrequency;
    }

    /**
     * @description An element that specifies the expiration settings for envelope
     */
    public class Expirations {
        
        /**
         * @description An integer specifying the number of days that a sent 
         * envelope remains active before it expires. 
         * A negative number in a response indicates that the envelope has 
         * already expired.
         */
        public String expireAfter;
        
        /**
         * @description When set to true, the envelope expires (is no longer 
         * available for signing) after the specified number of days after it 
         * is sent (sentDateTime). Set expireAfter to set the number of days 
         * until an envelope expires. When false, the account default setting 
         * is used. If the account does not have an expiration setting, the 
         * DocuSign default value of 120 days is used.
         */
        public String expireEnabled;

        /**
         * @description An integer that specifying the number of days before 
         * the envelope expires that an expiration warning email is sent to the 
         * recipient. If set to 0 (zero), no warning email is sent.
         */
        public String expireWarn;
    }

    /**
     * @description Deserializes a string into DocuSignCreateEnvelopsReqBody
     * @param jsonString The JSON payload in string format.
     * @return Returns an instance of DocuSignCreateEnvelopsReqBody
     */
    public DocuSignCreateEnvelopsReqBody deserialize(String jsonString) {
        return (DocuSignCreateEnvelopsReqBody)JSON.deserialize(jsonString, DocuSignCreateEnvelopsReqBody.class);
    }
    
}