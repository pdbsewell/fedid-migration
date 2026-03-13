/**
 * @description The handler which invokes actions when a recipient has signed 
 * a DocuSign document for offers.
 * @group Offers Signed Trigger Handler
 */
public inherited sharing class OffersRecipientSignedTriggerHandler 
        extends TriggerAbstract {
    
    private final String APPLICANT_ROLE = 'APPLICANT';
    private final String GUARDIAN_ROLE = 'GUARDIAN';

    @testVisible
    private QuotesSelector quotesSelector;
    
    @testVisible
    private Dao quotesDao;

    public OffersRecipientSignedTriggerHandler() {
        this.quotesSelector = new QuotesSelector();
        this.quotesDao = new SObjectDao();
    }

    /**
     * @description Updates the related quote for the offer depending on the 
     * recipient's role when the recipient signs the DocuSign offer document.
     * If the recipient is an applicant, the Quote's substatus will be updated 
     * to "Signed Recipient 1". If the recipient is a guardian, the Quote's 
     * substatus will be updated to "Signed Recipient 2"
     */
    public override void execute(){
        // platform event is already specific enough to not have to do any 
        // filtering
        List<Offers_Recipient_Signed_Event__e> signedEvents = 
            (Offers_Recipient_Signed_Event__e[]) records;
        
        Set<String> envelopIds = findQuoteIdsFromEvent(signedEvents);
        
        // find associated quotes
        Map<String, SBQQ__Quote__c> associatedQuotes = 
            this.quotesSelector
            .selectQuotesByPrimaryDocuSignEnvelopIdWithEnvelopId(envelopIds);

        Map<String, String> recipientRoleByEnvelopId = 
            this.findRecipientRoleByEnvelopIdFromEvent(signedEvents);
        
        // update quote substatus
        this.updateQuoteSubstatusBasedOnRecipientRole(
            associatedQuotes, 
            recipientRoleByEnvelopId);
    }

    private void updateQuoteSubstatusBasedOnRecipientRole(
            Map<String, SBQQ__Quote__c> associatedQuotes, 
            Map<String, String> recipientRoleByEnvelopId) {
        
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();

        for (String envelopId : associatedQuotes.keySet()) {

            String role = recipientRoleByEnvelopId.get(envelopId);
            if (APPLICANT_ROLE.equalsIgnoreCase(role)) {
                quotesToUpdate.add(new SBQQ__Quote__c(ID = associatedQuotes.get(envelopId).Id, Recipient_Signature_Status__c = 'Signed Recipient 1'));
            } else if (GUARDIAN_ROLE.equalsIgnoreCase(role)) {
                quotesToUpdate.add(new SBQQ__Quote__c(ID = associatedQuotes.get(envelopId).Id, Recipient_Signature_Status__c = 'Signed Recipient 2'));
            }
        }
        
        SBQQ.TriggerControl.disable();
        // Quote trigger disabled to reduce risk of unintended updates to the 
        // quote as this trigger is only expected to do a field update
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        
        this.quotesDao.updateRecords(quotesToUpdate);
    }

    private Set<String> findQuoteIdsFromEvent(
            List<Offers_Recipient_Signed_Event__e> signedEvents) {
        
        Set<String> envelopIds = new Set<String>();

        for (Offers_Recipient_Signed_Event__e event : signedEvents) {
            envelopIds.add(event.Envelop_Id__c);
        }

        return envelopIds;
    }

    private Map<String, String> findRecipientRoleByEnvelopIdFromEvent(
            List<Offers_Recipient_Signed_Event__e> signedEvents) {

        Map<String, String> recipientRoleByEnvelopId = new Map<String, String>();

        for (Offers_Recipient_Signed_Event__e event : signedEvents) {
            recipientRoleByEnvelopId.put(
                event.Envelop_Id__c, event.Recipient_Role__c);
        }

        return recipientRoleByEnvelopId;
    }

}