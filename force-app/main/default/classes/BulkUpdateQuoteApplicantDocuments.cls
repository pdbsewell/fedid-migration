/**
 * @description Applies bulk updates to documents with Quote data
 * @group Offers
 */
public inherited sharing class BulkUpdateQuoteApplicantDocuments {

    private ContentDocumentsSelector contentDocumentsSelector;
    private Dao contentDocumentDao;
    private UsersSelector usersSelector;

    /**
     * @description Contructor to set dependencies
     * @param contentDocumentsSelector Content Documents Selector dependency
     * @param contentDocumentDao Content Document Dao dependency
     * @param usersSelector Users selector dependency
     */
    public BulkUpdateQuoteApplicantDocuments(
            ContentDocumentsSelector contentDocumentsSelector, 
            Dao contentDocumentDao, 
            UsersSelector usersSelector) {
        this.contentDocumentsSelector = contentDocumentsSelector;
        this.contentDocumentDao = contentDocumentDao;
        this.usersSelector = usersSelector;
    }

    /**
     * @description Updates Content Documents owners related to the Quote to the 
     * user listed as the primary contact on the quote based on the document Ids 
     * in the Offers Signed Document Attached events
     * @param records Signed Document Events of when this action should occur
     * Contains document ids of the documents that require ownership updates
     * @param quotes Quotes identified for the documents to be updated to
     */
    public void updateContentDocumentOwnerToApplicant(
            List<Offers_Signed_Document_Attached__e> records, 
            List<SBQQ__Quote__c> quotes) {

        Set<String> envelopIds = new Set<String>();
        Set<Id> contentDocumentIds = new Set<Id>();
        Map<String, String> envelopIdByContentDocumentId = new Map<String, String>();
        for (Offers_Signed_Document_Attached__e signedDocumentEvent : records) {
            contentDocumentIds.add(Id.ValueOf(signedDocumentEvent.Content_Document_Id__c));
            envelopIdByContentDocumentId.put(signedDocumentEvent.Content_Document_Id__c, signedDocumentEvent.Envelop_Id__c);
        }

        // find matching quotes
        Map<String, Id> envelopIdsByQuotePrimaryContactId = new Map<String, Id>();
        for (SBQQ__Quote__c quote : quotes) {
            envelopIdsByQuotePrimaryContactId.put(quote.Primary_DocuSign_Envelop_Id__c, quote.SBQQ__PrimaryContact__c);
        }

        // get the owners from the quote

        List<User> applicants = this.usersSelector.selectUsersByContactId(envelopIdsByQuotePrimaryContactId.values());

        Map<Id, Id> userIdByContactId = new Map<Id, Id>();
        for (User applicant : applicants) {
            userIdByContactId.put(applicant.ContactId, applicant.Id);
        }

        Map<String, Id> applicantUserIdByEnvelopId = new Map<String, Id>();
        for (String envelopId : envelopIdsByQuotePrimaryContactId.keySet()) {
            Id contactId = envelopIdsByQuotePrimaryContactId.get(envelopId);
            applicantUserIdByEnvelopId.put(envelopId, userIdByContactId.get(contactId));
        }

        // update the content document owner to applicant
        List<ContentDocument> relatedFiles = this.contentDocumentsSelector.selectById(contentDocumentIds); 
        List<ContentDocument> documentsToUpdate = new List<ContentDocument>();
        for (ContentDocument relatedFile : relatedFiles) {
            // get the owner
            String relatedEnvelopId = envelopIdByContentDocumentId.get(String.valueOf(relatedFile.Id));
            String applicantUserId = applicantUserIdByEnvelopId.get(relatedEnvelopId);

            relatedFile.OwnerId = Id.ValueOf(applicantUserId);
            documentsToUpdate.add(relatedFile);
        }
        this.contentDocumentDao.updateRecords(documentsToUpdate);
    }
}