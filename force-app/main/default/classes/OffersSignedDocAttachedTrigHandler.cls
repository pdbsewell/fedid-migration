/**
 * @description Trigger handler for any offers functionality on 
 * Offers_Signed_Document_Attached__e trigger
 * @group Offers Signed Trigger Handler
 * @Revision @Shalini Mendu 26/10/2020 - SFTG-1629 -As a Callista/ SPM user, I want the Signed ISCA (from my.app) to be available in SPM, so that I can complete the application process
 */
public inherited sharing class OffersSignedDocAttachedTrigHandler 
        extends TriggerAbstract {
    
    private final String CERTIFICATE_IDENTIFIER_SUBSTRING = 'certificate';
    private final String  CONTACT_ISCA_DOC_COMMENTS = 'Signed ISCA document from DocuSign to kick off Callista SPM';
    private final String  CONTACT_ISCA_DOC_TYPE = 'ACCEPT-ADM';
    Map<Id,Id> quoteContentIdMap = new  Map<Id,Id>();

    @testVisible
    private QuotesSelector quotesSelector;

    @testVisible
    private ContentDocumentsSelector contentDocumentsSelector;

    @testVisible
    private Dao contentDocumentLinkDao;

    @testVisible
    private Dao contactDocumentDao;

    @testVisible
    private Dao contactDocumentLinkDao;

    @testVisible
    private Dao contentDocumentDao;

    @testVisible
    private Dao quoteDao;

    @testVisible
    private UsersSelector usersSelector;

    @testVisible
    private BulkUpdateQuoteApplicantDocuments bulkUpdateQuoteApplicantDocuments;


    public OffersSignedDocAttachedTrigHandler() {
        this.quotesSelector = new QuotesSelector();
        this.contentDocumentsSelector = new ContentDocumentsSelector();
        this.contentDocumentLinkDao = new SObjectDao();
        this.quoteDao = new SObjectDao();
        this.contentDocumentDao = new SObjectDao();
        this.contactDocumentDao = new SObjectDao();
        this.contactDocumentLinkDao = new SObjectDao();
        this.usersSelector = new UsersSelector();
        this.BulkUpdateQuoteApplicantDocuments = 
            new BulkUpdateQuoteApplicantDocuments(
                this.contentDocumentsSelector, this.contentDocumentDao,
                this.usersSelector
            );
    }

    /**
     * @description Performs the following:
     * 1. Creates content document links to relevant quotes
     * 2. Updates quote fields with files
     * 3. Update the owner of files to the applicant
     */    
    public override void execute() {
        Set<String> envelopIds = new Set<String>();
        Set<Id> contentDocumentIds = new Set<Id>();

        for (Offers_Signed_Document_Attached__e signedDocumentEvent : 
                (Offers_Signed_Document_Attached__e[]) records) {
            envelopIds.add(signedDocumentEvent.Envelop_Id__c);
            contentDocumentIds.add(Id.ValueOf(signedDocumentEvent.Content_Document_Id__c));
        }
        List<SBQQ__Quote__c> quotes = this.quotesSelector.selectQuotesByPrimaryDocuSignEnvelopId(envelopIds);
        List<ContentDocument> relatedDocuments = this.contentDocumentsSelector.selectById(contentDocumentIds); 
        // Create new Document Content Link
        createContentDocumentLinkToQuote((Offers_Signed_Document_Attached__e[]) records, 
        quotes);

        updateQuoteFilesFields((Offers_Signed_Document_Attached__e[]) records, 
            quotes, relatedDocuments);

        // update owner to applicant 
        this.BulkUpdateQuoteApplicantDocuments.updateContentDocumentOwnerToApplicant(
            (Offers_Signed_Document_Attached__e[]) records, quotes);

        
    }
  
    private void updateQuoteFilesFields(
            List<Offers_Signed_Document_Attached__e> signedDocumentEvents, 
            List<SBQQ__Quote__c> associatedQuotes, List<ContentDocument> relatedContentDocument) {
        
        Map<String, SBQQ__Quote__c> envelopIdsByQuote = mapEnvelopIdByQuote(associatedQuotes);
        Set<SBQQ__Quote__c> quotesToUpdate = new Set<SBQQ__Quote__c>();

        // get the document Id --- ContentDocument.LatestPublishedVersionId
        Map<Id, Id> latestPublishedVersionIdByContentDocumentId = 
            mapLatestPublishedVersionIdByContentDocumentId(relatedContentDocument);

        for (Offers_Signed_Document_Attached__e signedDocumentEvent : signedDocumentEvents) {

            // figure out which quote is required
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = envelopIdsByQuote.get(signedDocumentEvent.Envelop_Id__c).Id);
            // figure out the file
            Id fileId = latestPublishedVersionIdByContentDocumentId.get(
                Id.ValueOf(signedDocumentEvent.Content_Document_Id__c));
            // update the right field
            if (signedDocumentEvent.File_Name__c.containsIgnoreCase(CERTIFICATE_IDENTIFIER_SUBSTRING)) {
                // update the certificate file field
                // DocuSign_Signed_Certificate_Document_Id__c
                quote.DocuSign_Signed_Certificate_Document_Id__c = String.valueOf(fileId);
            } else {
                // update the signed offer doc field
                // Final_Signed_Document_Id__c
                quoteContentIdMap.put( quote.Id, signedDocumentEvent.Content_Document_Id__c);
                quote.Final_Signed_Document_Id__c = String.valueOf(fileId);
            }
            quotesToUpdate.add(quote); 
        }
        
        SBQQ.TriggerControl.disable();
        // Quote trigger disabled to reduce risk of unintended updates to the 
        // quote as this trigger is only expected to do a field update on Quote
        TriggerCommon.disableTrigger('SBQQ__Quote__c');
        this.quoteDao.updateRecords(new List<SBQQ__Quote__c>(quotesToUpdate));
        // Publish Signed doc to Callista
        publishSignedDocToCallista(new List<SBQQ__Quote__c>(quotesToUpdate));
    }
   
    private Map<String, SBQQ__Quote__c> mapEnvelopIdByQuote(List<SBQQ__Quote__c> quotes) {
        Map<String, SBQQ__Quote__c> envelopIdsByQuote = new Map<String, SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : quotes) {
            envelopIdsByQuote.put(quote.Primary_DocuSign_Envelop_Id__c, quote);
        }
        return envelopIdsByQuote;
    }

    private Map<Id, Id> mapLatestPublishedVersionIdByContentDocumentId(
            List<ContentDocument> contentDocuments) {
        Map<Id, Id> latestPublishedVersionIdByContentDocumentId = 
            new Map<Id, Id>();
        for (ContentDocument contentDocument : contentDocuments) {
            latestPublishedVersionIdByContentDocumentId.put(contentDocument.Id, 
                contentDocument.LatestPublishedVersionId);
        }
        return latestPublishedVersionIdByContentDocumentId;
    }

    

    private void createContentDocumentLinkToQuote(
            List<Offers_Signed_Document_Attached__e> records, 
            List<SBQQ__Quote__c> quotes) {

        Map<String, SBQQ__Quote__c> quoteByEnvelopId = new Map<String, SBQQ__Quote__c>();

        for (SBQQ__Quote__c quote : quotes) {
            quoteByEnvelopId.put(quote.Primary_DocuSign_Envelop_Id__c, quote);
        }
        List<ContentDocumentLink> contentDocumentLinksToQuote = new List<ContentDocumentLink>();

        for (Offers_Signed_Document_Attached__e signedDocumentEvent : records) {
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'InternalUsers';
            contentDocumentLink.ContentDocumentId = Id.ValueOf(signedDocumentEvent.Content_Document_Id__c); // content document
            contentDocumentLink.LinkedEntityId = quoteByEnvelopId.get(signedDocumentEvent.Envelop_Id__c).Id;    // quote
            contentDocumentLinksToQuote.add(contentDocumentLink);
        }

        this.contentDocumentLinkDao.insertRecords(contentDocumentLinksToQuote);
    }

     /**
     * @description  Method to publish signed doc to Callista
     * @param  SBQQ__Quote__c quotesList 
     * @Return void
     */
    public void publishSignedDocToCallista(List<SBQQ__Quote__c> quotesList)
    {
        List<Id> quoteIdList = new List<Id>();
        Map <Id, ContentDocumentLink>  docoLinkMap =  new Map <Id,ContentDocumentLink>();
        List <ContentDocumentLink> docLinks = new List <ContentDocumentLink> (); 
        //List all the quote Id's
        for(SBQQ__Quote__c quo:quotesList)
        {
            quoteIdList.add(quo.Id);
        }
        //Query ContentDocumentLink with the quoteId'sx
        if(quoteIdList.size()>0)
        {
            docLinks = 
                [select Id, LinkedEntityId, LinkedEntity.name, ContentDocumentId , ContentDocument.title 
                    from ContentDocumentLink WHERE LinkedEntityId in :quoteIdList ];
        }
        //Iterate the ContentDocumentLinks to find the matching document as querying is allowed on only Id field
        for(ContentDocumentLink doc:docLinks)
        {
            System.debug('quoteContentIdMap=='+quoteContentIdMap+'doc.ContentDocumentId=='+doc.ContentDocumentId);
            //Retrieve ContentDocument matching the doc that has to be published for the quote
            if(quoteContentIdMap.get(doc.LinkedEntityId) ==  doc.ContentDocumentId ) 
            {
                docoLinkMap.put(doc.LinkedEntityId, doc);
            }
                
        }
        //Retrieve Map of Id, SBQQ__Quote__c which have been signed
        Map<Id,SBQQ__Quote__c> rquoteMap = new Map<Id,SBQQ__Quote__c>([ select Id,SBQQ__Opportunity2__c,SBQQ__PrimaryContact__c,Contact_Access__c from SBQQ__Quote__c where id in :quoteIdList ]);
    
        // Create Contact_Document__c list
        List<Contact_Document__c> conDocList = new List<Contact_Document__c>();
        for(Id quId:docoLinkMap.keySet())
        {
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = rquoteMap.get(quId).SBQQ__PrimaryContact__c;
            conDoc.Document_Type__c = CONTACT_ISCA_DOC_TYPE;
            conDoc.Comments__c = CONTACT_ISCA_DOC_COMMENTS;
            conDoc.Filename__c = docoLinkMap.get(quId)!=null?docoLinkMap.get(quId).ContentDocument.title:'Signed Offer.pdf';
            conDoc.Opportunity__c =  rquoteMap.get(quId).SBQQ__Opportunity2__c;
            conDoc.Internal_Only__c = true;
            conDoc.Submitted__c = true;
            conDoc.Post_Submission__c = true;
            conDocList.add(conDoc);
        }
    
        this.contactDocumentDao.insertRecords(conDocList);
        //Retrieve Contact_Document__c
        List<Contact_Document__c> condDocListRet = [Select Contact__c,Id,Filename__c,Opportunity__c from Contact_Document__c where id in :conDocList];

        List<ContentDocumentLink> contentDocumentLinksToConDoc = new List<ContentDocumentLink>();
        for(Id docLink: docoLinkMap.keySet())
        {
                for(Contact_Document__c con:condDocListRet)
                {
                    if(con.Filename__c == docoLinkMap.get(docLink).ContentDocument.title)
                    {
                        ContentDocumentLink cdLink = new ContentDocumentLink();
                        cdLink.ContentDocumentId = docoLinkMap.get(docLink).ContentDocumentId;
                        cdLink.LinkedEntityId = con.Id;
                        cdLink.ShareType = 'I';
                        cdLink.Visibility = 'AllUsers';
                        contentDocumentLinksToConDoc.add(cdLink);
                    }
                    
                }
        }
        this.contactDocumentLinkDao.insertRecords(contentDocumentLinksToConDoc);
        
    }
}