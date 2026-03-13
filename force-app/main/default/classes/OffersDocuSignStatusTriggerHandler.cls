/**
 * @description Trigger handler for Offers DocuSign Status
 * This trigger handler processes Offers Docusign Status records (records that 
 * are relevant to Offers) for any follow up actions.
 * @group Offers Signed Trigger Handler
 */
public inherited sharing class OffersDocuSignStatusTriggerHandler 
        extends TriggerAbstract {
    
    private final String DOCUSIGN_RECIPIENT_COMPLETED_STATUS = 'Completed';

    @testVisible
    private QuotesSelector quotesSelector;

    public OffersDocuSignStatusTriggerHandler() {
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

    public override void process(SObject rec, SObject old){

        // Cannot filter here because this TriggerAbstract trigger framework
        // doesn't support bulkification during this process method
        // Records will be filtered in the execute() method instead
        records.add(rec);
    }

    /**
     * @description Creates the platform event notification when an offers 
     * document/envelop has been signed. Any non-offers records will be ignored
     */
    public override void execute(){

        Set<String> envelopIds = new Set<String>();
        for (dsfs__DocuSign_Status__c envelopStatus : 
                (dsfs__DocuSign_Status__c[]) records) {
            envelopIds.add(envelopStatus.dsfs__DocuSign_Envelope_ID__c.toLowerCase());
        }

        // filter out any records that are do not have a related quote
        // find associated quotes
        Map<String, SBQQ__Quote__c> associatedQuotes = 
            this.quotesSelector
            .selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId(envelopIds);

        List<dsfs__DocuSign_Status__c> offersSignedEnvelopStatuses = 
            new List<dsfs__DocuSign_Status__c>();

        for (dsfs__DocuSign_Status__c envelopStatus : 
                (dsfs__DocuSign_Status__c[]) records) {
            if (associatedQuotes.containsKey(
                    envelopStatus.dsfs__DocuSign_Envelope_ID__c.toLowerCase())
                    && DOCUSIGN_RECIPIENT_COMPLETED_STATUS.equals(
                    envelopStatus.dsfs__Envelope_Status__c)) {
                
                offersSignedEnvelopStatuses.add(envelopStatus);
            
            }
        }

        createEnvelopSignedPlatformEvents(offersSignedEnvelopStatuses);

    }

    private void createEnvelopSignedPlatformEvents(
            List<dsfs__DocuSign_Status__c> signedEnvelopStatuses) {

        List<Offers_Envelop_Signed_Event__e> offersEnvelopSignedEvents = 
            new List<Offers_Envelop_Signed_Event__e>();

        for (dsfs__DocuSign_Status__c signedEnvelopStatus : signedEnvelopStatuses) {

            Offers_Envelop_Signed_Event__e event = new Offers_Envelop_Signed_Event__e();
            
            // Convert envelop id to lower case as DocuSign connect's envelop Id
            // is in upper case, but DocuSign envelops are created with 
            // envelop id in lower case
            event.Envelop_Id__c = signedEnvelopStatus.dsfs__DocuSign_Envelope_ID__c.toLowerCase();
            
            offersEnvelopSignedEvents.add(event);
        }

        List<Database.SaveResult> results = EventBus.publish(offersEnvelopSignedEvents);
        System.debug(results);
    }
}