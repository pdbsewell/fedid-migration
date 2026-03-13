/**
 * @description The handler which invokes offers actions when a docusign 
 * recipient status record has been inserted or updated.
 * @group Offers Signed Trigger Handler
 */
public inherited sharing class OffersDocuSignRecStatusTriggerHand 
        extends TriggerAbstract {
    
    // Completed indicates the recipient has signed the document in DocuSign
    private final String DOCUSIGN_RECIPIENT_COMPLETED_STATUS = 'Completed';

    private final String APPLICANT_ROLE = 'APPLICANT';
    private final String GUARDIAN_ROLE = 'GUARDIAN';

    @testVisible
    private QuotesSelector quotesSelector;

    public OffersDocuSignRecStatusTriggerHand() {
        this.quotesSelector = new QuotesSelector();
    }

    /**
     * @description Filter out record for update
     * @param rec New record to evaluate
     */
    public override void process(SObject rec){

        // Cannot filter here because this TriggerAbstract trigger framework
        // doesn't support bulkification during this process method
        // Records will be filtered in the execute() method instead
        records.add(rec);
    }

    /**
     * @description Filter out record for update
     * @param rec New record to evaluate
     */
    public override void process(SObject rec, SObject old){

        // Cannot filter here because this TriggerAbstract trigger framework
        // doesn't support bulkification during this process method
        // Records will be filtered in the execute() method instead
        records.add(rec);
    }

    
    /**
     * @description Creates the platform event notification when an offers
     * recipient has signed the document. Any non-offers records will be ignored
     */
    public override void execute(){

        Set<String> envelopIds = new Set<String>();
        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : 
                (dsfs__DocuSign_Recipient_Status__c[]) records) {
            envelopIds.add(recipientStatus.dsfs__Envelope_Id__c.toLowerCase());
        }

        // filter out any records that are do not have a related quote
        // find associated quotes
        Map<String, SBQQ__Quote__c> associatedQuotes = 
            this.quotesSelector
            .selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId(envelopIds);

        List<dsfs__DocuSign_Recipient_Status__c> offersRecipientStatuses = 
            new List<dsfs__DocuSign_Recipient_Status__c>();

        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : 
                (dsfs__DocuSign_Recipient_Status__c[]) records) {
            if (associatedQuotes.containsKey(
                    recipientStatus.dsfs__Envelope_Id__c.toLowerCase())
                    && DOCUSIGN_RECIPIENT_COMPLETED_STATUS.equals(
                    recipientStatus.dsfs__Recipient_Status__c)) {
                
                offersRecipientStatuses.add(recipientStatus);
            
            }
        }

        // create Offers_Recipient_Signed_Event__e
        createOffersRecipientSignedPlatformEvents(offersRecipientStatuses);
    }

    private void createOffersRecipientSignedPlatformEvents(
            List<dsfs__DocuSign_Recipient_Status__c> signedRecipientStatuses) {

        List<Offers_Recipient_Signed_Event__e> recipientSignedEvents = 
            new List<Offers_Recipient_Signed_Event__e>();

        for (dsfs__DocuSign_Recipient_Status__c signedRecipientStatus : signedRecipientStatuses) {

            Offers_Recipient_Signed_Event__e event = new Offers_Recipient_Signed_Event__e();
            
            // Convert envelop id to lower case as DocuSign connect's envelop Id
            // is in upper case, but DocuSign envelops are created with 
            // envelop id in lower case
            event.Envelop_Id__c = signedRecipientStatus.dsfs__Envelope_Id__c.toLowerCase();
            

            // Routing order used to determine if the applicant is a guardian or 
            // applicant
            if (signedRecipientStatus.dsfs__DocuSign_Routing_Order__c == 1){
                event.Recipient_Role__c = APPLICANT_ROLE;
            } else if (signedRecipientStatus.dsfs__DocuSign_Routing_Order__c == 2) {
                event.Recipient_Role__c = GUARDIAN_ROLE;
            }
            recipientSignedEvents.add(event);
        }

        List<Database.SaveResult> results = EventBus.publish(recipientSignedEvents);
        System.debug(results);
    }

}