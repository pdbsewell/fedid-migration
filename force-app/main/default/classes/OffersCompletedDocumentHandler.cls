/**
 * @description Handler to process files that are related to the completed (in
 * DocuSign terminology) or "signed" offers. This operates on
 * ContentDocumentLinks
 * @group Offers Signed Trigger Handler
 */
public inherited sharing class OffersCompletedDocumentHandler extends TriggerAbstract {

    private final String DOCUSIGN_PARENT_OBJECT_NAME = 'dsfs__DocuSign_Status__c';
    private final String DOCUSIGN_ENVELOP_COMPLETED_STATUS = 'Completed';

    @testVisible
    private DocuSignStatusSelector docuSignStatusSelector;

    @testVisible
    private ContentDocumentsSelector contentDocumentsSelector;

    @testVisible
    private QuotesSelector quotesSelector;

    public OffersCompletedDocumentHandler() {
        this.docuSignStatusSelector = new docuSignStatusSelector();
        this.contentDocumentsSelector = new ContentDocumentsSelector();
        this.quotesSelector = new QuotesSelector();
    }

    /**
     * @description Performs basic filter to only includes files where the
     * parent object is DocuSign Status
     */
    public override void process(SObject rec) {
        ContentDocumentLink contentDocumentLink = (ContentDocumentLink) rec;

        // Only basic check here to check if the parent link is a DocuSign
        // object, so other Documents are no processed
        // Cannot do other checks because this trigger abstract framework
        // support bulkification in the process method
        // Additional checks/validation will be performed in execute() instead
        if (DOCUSIGN_PARENT_OBJECT_NAME.equals(
                    String.valueOf(contentDocumentLink.LinkedEntityId.getSobjectType()))) {
            records.add(contentDocumentLink);
        }

        // Additional checks/filtering is done in the execute method
        // Parent record status = completed
        // envelop id exists on docusign object and evelop Id matches an
        // quote
    }

    /**
     * @description Creates a Offers Signed Document Attached Event for all
     * files (contentDocumentLink) that are identified as completed/signed
     * documents for an offer
     */
    public override void execute() {
        if (!records.isEmpty()) {
            // query all common data
            Set<Id> contentDocumentLinkDocuSignStatusIds = new Set<Id>();

            for (ContentDocumentLink contentDocumentLink : (ContentDocumentLink[]) records) {
                contentDocumentLinkDocuSignStatusIds.add(contentDocumentLink.LinkedEntityId);
            }

            // get an filter docusign status that are completed
            List<dsfs__DocuSign_Status__c> completedDocuSignStatuses =
                this.docuSignStatusSelector.selectByIdAndEnvelopStatus(
                    contentDocumentLinkDocuSignStatusIds,
                    DOCUSIGN_ENVELOP_COMPLETED_STATUS);
            System.debug('completedDocuSignStatuses; ' + completedDocuSignStatuses);
            // filtering based on quote
            List<dsfs__DocuSign_Status__c> completedDocuSignStatusesAndQuoteExists =
                filterDocuSignStatusesWithQuotes(completedDocuSignStatuses);
            System.debug('completedDocuSignStatusesAndQuoteExists: ' + completedDocuSignStatusesAndQuoteExists);
            // additional filtering
            List<ContentDocumentLink> filteredDocuSignStatuses =
                filterValidOffersDocuSignStatuses((ContentDocumentLink[]) records, completedDocuSignStatusesAndQuoteExists);
            System.debug('filteredDocuSignStatuses: ' + filteredDocuSignStatuses);
            // do stuff
            if (!filteredDocuSignStatuses.isEmpty()) {
                publishOfferSignedDocumentAttachedEvents(filteredDocuSignStatuses,
                        completedDocuSignStatuses);
            }
        }
    }

    private void publishOfferSignedDocumentAttachedEvents(
        List<ContentDocumentLink> contentDocumentLinksDocuSign,
        List<dsfs__DocuSign_Status__c> completedDocuSignStatuses) {

        List<Offers_Signed_Document_Attached__e> completedDocumentsAttachedEvents = new List<Offers_Signed_Document_Attached__e>();
        Map<Id, String> envelopIdByDocuSignStatusRecordId =
            new Map<Id, String>();

        // get the envelop Ids
        for (dsfs__DocuSign_Status__c completedDocuSignStatus : completedDocuSignStatuses) {
            envelopIdByDocuSignStatusRecordId.put(completedDocuSignStatus.Id,
                                                  completedDocuSignStatus.dsfs__DocuSign_Envelope_ID__c);
        }

        // get the file name
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinksDocuSign) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }

        // get all the ContentDocuments related to the document document link
        Map<Id, String> relatedDocumentsTitleById = new Map<Id, String>();
        for (ContentDocument document : this.contentDocumentsSelector.selectById(contentDocumentIds)) {
            relatedDocumentsTitleById.put(document.Id, document.Title);
        }

        for (ContentDocumentLink contentDocumentLink : contentDocumentLinksDocuSign) {

            Offers_Signed_Document_Attached__e	event = new Offers_Signed_Document_Attached__e();
            event.Content_Document_Id__c = contentDocumentLink.ContentDocumentId;

            // envelop id in system is stored as lowercase
            // converting to lower case aligns data even if DocuSign Connect
            // creates the date in uppercase
            event.Envelop_Id__c = envelopIdByDocuSignStatusRecordId.get(contentDocumentLink.LinkedEntityId).toLowerCase();
            event.File_Name__c = relatedDocumentsTitleById.get(contentDocumentLink.ContentDocumentId);
            completedDocumentsAttachedEvents.add(event);

        }

        List<Database.SaveResult> results = EventBus.publish(completedDocumentsAttachedEvents);
        System.debug(results);
    }

    private List<ContentDocumentLink> filterValidOffersDocuSignStatuses(
        List<ContentDocumentLink> unfilteredDocuSignStatuses,
        List<dsfs__DocuSign_Status__c> completedDocuSignStatuses) {

        List<ContentDocumentLink> filterValidDocuSignStatuses =
            new List<ContentDocumentLink>();

        Set<Id> completedDocuSignStatusIds = extractDocuSignStatusIds(completedDocuSignStatuses);

        for (ContentDocumentLink unfilteredDocuSignStatus : unfilteredDocuSignStatuses) {
            // if this thing is part of the completed ones, then add

            if (completedDocuSignStatusIds.contains(unfilteredDocuSignStatus.LinkedEntityId)) {
                filterValidDocuSignStatuses.add(unfilteredDocuSignStatus);
            }

        }

        return filterValidDocuSignStatuses;
    }

    private Set<Id> extractDocuSignStatusIds(List<dsfs__DocuSign_Status__c> docuSignStatuses) {
        Set<Id> recordIds = new Set<Id>();
        for (dsfs__DocuSign_Status__c docuSignStatus : docuSignStatuses) {
            recordIds.add(docuSignStatus.Id);
        }
        return recordIds;
    }

    private Set<String> extractDocuSignStatusEnvelopIds(
        List<dsfs__DocuSign_Status__c> docuSignStatuses) {
        Set<String> envelopIds = new Set<String>();
        for (dsfs__DocuSign_Status__c docuSignStatus : docuSignStatuses) {
            envelopIds.add(docuSignStatus.dsfs__DocuSign_Envelope_ID__c);
        }
        return envelopIds;
    }


    private Set<String> extractEnvelopIdsFromQuotes(List<SBQQ__Quote__c> quotes) {
        Set<String> envelopIds = new Set<String>();
        for (SBQQ__Quote__c quote : quotes) {
            if (String.isNotBlank(quote.Primary_DocuSign_Envelop_Id__c)) {
                envelopIds.add(quote.Primary_DocuSign_Envelop_Id__c);
            }
        }
        return envelopIds;
    }

    private List<dsfs__DocuSign_Status__c> filterDocuSignStatusesWithQuotes(
        List<dsfs__DocuSign_Status__c> completedDocuSignStatuses) {

        List<dsfs__DocuSign_Status__c>  completedDocuSignStatusesWithQuotes =
            new List<dsfs__DocuSign_Status__c>();
        Set<String> envelopIds = extractDocuSignStatusEnvelopIds(completedDocuSignStatuses);

        // query quotes
        List<SBQQ__Quote__c> quotesFromDocuSignStatusEnvelopIds =
            this.quotesSelector.selectQuotesByPrimaryDocuSignEnvelopId(envelopIds);

        Set<String> envelopIdsFromRelatedQuotes =
            extractEnvelopIdsFromQuotes(quotesFromDocuSignStatusEnvelopIds);

        // check which one has a quote
        for (dsfs__DocuSign_Status__c completedDocuSignStatus : completedDocuSignStatuses) {
            if (envelopIdsFromRelatedQuotes.contains(
                        completedDocuSignStatus.dsfs__DocuSign_Envelope_ID__c.toLowerCase())) {
                completedDocuSignStatusesWithQuotes.add(completedDocuSignStatus);
            }
        }
        return completedDocuSignStatusesWithQuotes;
    }

}