/**
 * @author      Kristian Vegerano
 * @description Service class for acceptance offer document checklist object
 * @group       Service
 * @revision    17/02/2020 - Kristian Vegerano - Created
 */
public with sharing class DocumentChecklistAcceptanceServices {

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the user record relevant to the quote's applicant contact record
     * @param       String offerId
     * @return      Object
     * @revision    17/02/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled(cacheable=true)
    public static Object retrieveApplicantCommunityUser(Id opportunityId) {
        User communityUser = [SELECT Id FROM User WHERE ContactId IN (SELECT PrimaryContact__c FROM Opportunity WHERE Id = :opportunityId) LIMIT 1];
        return communityUser;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the offer record
     * @param       String opportunityId
     * @return      Object
     * @revision    17/02/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> retrieveOffer(String opportunityId){
        Map<String, Object> resultMap = new Map<String, Object>();

        Boolean hasAcceptanceChecklistNewAccess = FeatureManagement.checkPermission('AcceptanceChecklistNew');
        resultMap.put('hasAcceptanceChecklistNewAccess', hasAcceptanceChecklistNewAccess);
        resultMap.put('Opportunity', [SELECT Id, Name, PrimaryContact__c, StageName, Offer_Type__c, Offer_Start_Date__c, Pricebook2Id, Pricebook2.Name,
                                             (SELECT Id, Name, Application_Course_Preference__r.Location_Code__c, Product2.Family, Product2.Name, Product2Id 
                                                FROM OpportunityLineItems 
                                                ORDER BY Application_Course_Preference__r.Course_Start_Date_Updated__c DESC 
                                                NULLS LAST)
                                      FROM Opportunity 
                                      WHERE Id = :opportunityId 
                                      LIMIT 1][0]);
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the checklist item to be shown
     * @param       String checklistId
     * @return      Object
     * @revision    17/02/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled(cacheable=true)
    public static Object retrieveChecklistItem(Id checklistId) {
        Document_Checklist__c checklist = [SELECT Id, Checklist_Requirement__c, Applicant_Instructions_UI__c, Contact__c, Allowed_Document_Type__c,
                                                  Application__c, Contact_Qualification__c, Work_Experience__c, Rule_DeveloperName__c, Opportunity__c, Status__c
                                           FROM Document_Checklist__c 
                                           WHERE Id = :checklistId 
                                           LIMIT 1];
        return checklist;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the checklist records related to the quote id on the parameter
     * @param       String requestOfferId
     * @return      Object
     * @revision    17/02/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object retrieveChecklistItems(String requestOfferId){
        Object result;
        try{
            //Query items
            List<Document_Checklist__c> applicationChecklistList = new List<Document_Checklist__c>();
            for(Document_Checklist__c loopChecklistItem : new DocumentChecklistsSelector(true).selectOfferAcceptanceByQuoteIds(new Set<Id>{requestOfferId})){
                //Include if not cancelled
                if(loopChecklistItem.status__c != System.Label.Application_Checklist_Auto_Cancelled){
                    applicationChecklistList.add(loopChecklistItem);
                }
            }

            result = applicationChecklistList;
        } catch(Exception e){
            ExLog.add('DocumentChecklistAcceptanceServices', 'Document Checklist', 'retrieveChecklistItems', e);
            result = e.getMessage();
        }

        return result;
    }

    /**
     * @author      Kristian Vegerano
     * @description Runs the rules evaluation service
     * @param       String category
     *              String requestOfferId
     * @return      Object
     * @revision    17/02/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object runRules(String category, String requestOfferId){
        Object result;
        try{
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{requestOfferId});
            rulesDocChecklistEngine.evaluateRules(category);

            //Commit records
            List<Document_Checklist__c> resultChecklistItemsList = new List<Document_Checklist__c>();
            if(rulesDocChecklistEngine.resultChecklistItemsMap != null){
                if(rulesDocChecklistEngine.resultChecklistItemsMap.containsKey(requestOfferId)){
                    resultChecklistItemsList = rulesDocChecklistEngine.resultChecklistItemsMap.get(requestOfferId).values();
                    upsert resultChecklistItemsList Unique_ID__c;
                }
            }

            result = resultChecklistItemsList;
        } catch(Exception e){
            ExLog.add('DocumentChecklistAcceptanceServices', 'Document Checklist', 'runRules', e);
            result = e.getMessage();
        }

        return result;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the ContentDocument records related to the checklist via ContentDocumentLink
     * @param       String checklistItemId
     * @return      Object
     * @revision    10/06/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object retrieveChecklistFiles(String checklistItemId, String applicantId, String opportunityId){
        Map<String, Object> resultMap = new Map<String, Object>();
    
        try{
            //Initialize Variables
            Set<Id> notesIds = new Set<Id>();
            List<ChecklistNote> notesList = new List<ChecklistNote>();
            List<ChecklistDocument> checklistDocumentItemList = new List<ChecklistDocument>();
            Map<Id, Contact_Document__c> contentToContactDocumentMap = new Map<Id, Contact_Document__c>();
            
            //Retrieve documents
            //Collect contact document ids related to the checklist  
            if(opportunityId != null){      
                for(Contact_Document__c loopContactDocument : [SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c, Document_Checklist__r.Rule_DeveloperName__c, Document_Checklist__r.Status__c, Application__c,
                                                                      Internal_Only__c, Comments__c, Document_Assessment_Status__c, Document_Status__c, Opportunity__c, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks) 
                                                            FROM Contact_Document__c 
                                                            WHERE Document_Checklist__c = :checklistItemId 
                                                                    AND Contact__c = :applicantId
                                                                    AND Contact__c != null
                                                                    AND Opportunity__c = :opportunityId]){
                    //Collect document links
                    if(loopContactDocument.ContentDocumentLinks != null){
                        for(ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks){
                            contentToContactDocumentMap.put(loopLink.ContentDocumentId, loopContactDocument);
                        }
                    }
                }
            }else{
                for(Contact_Document__c loopContactDocument : [SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c, Document_Checklist__r.Rule_DeveloperName__c, Document_Checklist__r.Status__c, Application__c,
                                                                      Internal_Only__c, Opportunity__c, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks) 
                                                            FROM Contact_Document__c 
                                                            WHERE Document_Checklist__c = :checklistItemId 
                                                                    AND Contact__c = :applicantId
                                                                    AND Contact__c != null
                                                                    AND Opportunity__c = :opportunityId]){
                    //Collect document links
                    if(loopContactDocument.ContentDocumentLinks != null){
                        for(ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks){
                            contentToContactDocumentMap.put(loopLink.ContentDocumentId, loopContactDocument);
                        }
                    }
                }
            }

            //Check if there are document links
            if(!contentToContactDocumentMap.isEmpty()){
                //Query content document records
                for(ContentDocument loopContentDocument : [SELECT Id, Description, FileExtension, FileType, Title 
                                                           FROM ContentDocument 
                                                           WHERE Id IN :contentToContactDocumentMap.keySet()
                                                           ORDER BY CreatedDate DESC]){
                    checklistDocumentItemList.add(new ChecklistDocument(loopContentDocument, contentToContactDocumentMap.get(loopContentDocument.Id)));
                }
            }
            resultMap.put('documents', checklistDocumentItemList);

            //Retrieve notes
            for(Document_Checklist_Comment__c loopComment : [SELECT Id, Document_Checklist__c, Content__c, CreatedDate, CreatedBy.Name, NotesSeen__c
                                                             FROM Document_Checklist_Comment__c 
                                                             WHERE Document_Checklist__c = :checklistItemId
                                                             ORDER BY CreatedDate DESC]){
                notesList.add(new ChecklistNote(loopComment));
            }
            
            resultMap.put('notes', notesList);
        } catch(Exception e){
            ExLog.add('DocumentChecklistAcceptanceServices', 'Document Checklist', 'retrieveChecklistFiles', e);
            resultMap.put('error', e.getMessage());
        }
        return resultMap;
    }
    
    /**
     * @author      Kristian Vegerano
     * @description Updates the checklist item to not required. And inserts a content note if necessary
     * @param       String checklistId
     *              String commentTitle
     *              String commentContent
     *              String noteOwnerId
     * @return      Object
     * @revision    11/07/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> writeNotes(Id checklistId, String commentContent, String noteOwnerId){
        Map<String, Object> resultMap = new Map<String, Object>();
        try{
            Document_Checklist_Comment__c newComment = new Document_Checklist_Comment__c();
            newComment.Content__c = commentContent;
            newComment.Document_Checklist__c = checklistId;
            insert newComment;
        } catch(Exception e){
            ExLog.add('DocumentChecklistAcceptanceServices', 'Document Checklist', 'writeNotes', e);
            resultMap.put('error', e.getMessage());
        }
        return resultMap;
    }    
    
    /**
     * @author      Kristian Vegerano
     * @description Runs all document checklist rules related to offer acceptance
     * @param       String quoteIds
     * @revision    10/06/2019 - Kristian Vegerano - Created
     */
    public static void runAcceptanceChecklistRules(Set<Id> quoteIds){
        //Initialize variables
        List<Document_Checklist__c> resultChecklistItemsList = new List<Document_Checklist__c>();

        //Run document checklist engine for offer acceptance
        DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(quoteIds);
        rulesDocChecklistEngine.evaluateRules('Offer Acceptance');

        //Add all resulting document checklist records
        for(Id quoteId : quoteIds){   
            if(rulesDocChecklistEngine.resultChecklistItemsMap.containsKey(quoteId)){
                for(Document_Checklist__c loopChecklist : rulesDocChecklistEngine.resultChecklistItemsMap.get(quoteId).values()){
                    resultChecklistItemsList.add(loopChecklist);
                }
            }
        }

        if(!resultChecklistItemsList.isEmpty()){
            upsert resultChecklistItemsList Unique_ID__c;
        }
    }

    public class ChecklistDocument {
        @AuraEnabled
        public Id contactDocumentId {get; set;}
        @AuraEnabled
        public Id contentDocumentId {get; set;}
        @AuraEnabled
        public Contact_Document__c contactDocument {get; set;}
        @AuraEnabled
        public ContentDocument contentDocument {get; set;}
        @AuraEnabled
        public String fileName {get; set;}
        @AuraEnabled
        public String fileType {get; set;}
        @AuraEnabled
        public String formattedCreatedDateTime {get; set;}
        @AuraEnabled
        public String iconURL {get; set;}
        @AuraEnabled
        public String documentType {get; set;}

        public ChecklistDocument(){
        }

        public ChecklistDocument(ContentDocument newContentDocument, Contact_Document__c newContactDocument){
            this.contentDocumentId = newContentDocument.Id;
            this.contentDocument = newContentDocument;
            this.contactDocumentId = newContactDocument.Id;
            this.contactDocument = newContactDocument;

            //Set document type
            documentType = this.contactDocument.Document_Type__c;
            if(this.contactDocument.Document_Checklist__r.Rule_DeveloperName__c != null){
                if(this.contactDocument.Document_Checklist__r.Rule_DeveloperName__c.containsIgnoreCase('visa_check')){
                    documentType = 'Personal: Supplementary VISA documentation';
                }
            }

            //Get file name without the extension
            if(newContactDocument.Filename__c != null){
                List<String> fileNameComponents = newContactDocument.Filename__c.split('\\.');
                fileNameComponents.remove(fileNameComponents.size() - 1);
                this.fileName = String.join(fileNameComponents, '.');
            }

            //Access static resource
            this.iconURL = '';
            String customLogoLink = PageReference.forResource('CustomFileIcons').getUrl();
            if(customLogoLink.contains('?')){
                customLogoLink = customLogoLink.subString(0, customLogoLink.indexOf('?'));
            }else{
                customLogoLink = customLogoLink;
            }

            //Set proper file type
            String fileExtension = this.contentDocument.FileExtension;
            switch on this.contentDocument.FileExtension {
                when 'pdf' {
                    fileExtension = 'pdf';
                    this.iconURL = customLogoLink + '/CustomFileIcons/pdf.svg';
                }
                when 'png' {
                    fileExtension = 'png';
                    this.iconURL = customLogoLink + '/CustomFileIcons/png.svg';
                }
                when 'jpg' {
                    fileExtension = 'jpg';
                    this.iconURL = customLogoLink + '/CustomFileIcons/jpg.svg';
                }
                when 'gif' {
                    fileExtension = 'unknown';
                    this.iconURL = customLogoLink + '/CustomFileIcons/unknown.svg';
                }
                when 'doc' {
                    fileExtension = 'word';
                    this.iconURL = customLogoLink + '/CustomFileIcons/doc.svg';
                }
                when 'docx' {
                    fileExtension = 'word';
                    this.iconURL = customLogoLink + '/CustomFileIcons/doc.svg';
                }
                when 'rtf' {
                    fileExtension = 'unknown';
                    this.iconURL = customLogoLink + '/CustomFileIcons/unknown.svg';
                }
                when 'txt' {
                    fileExtension = 'txt';
                    this.iconURL = customLogoLink + '/CustomFileIcons/txt.svg';
                }
                when else {
                    fileExtension = 'unknown';
                    this.iconURL = customLogoLink + '/CustomFileIcons/unknown.svg';
                }
            }

            this.fileType = 'doctype:' + fileExtension;
            this.formattedCreatedDateTime = this.contactDocument.CreatedDate.format('dd/MM/yyyy', 'Australia/Sydney');
        }
    }

    public class ChecklistNote {
        @AuraEnabled
        public Document_Checklist_Comment__c contentNote {get; set;}
        @AuraEnabled
        public String noteDetails {get; set;}

        public ChecklistNote(Document_Checklist_Comment__c newComment){
            this.contentNote = newComment;
            this.noteDetails = '';
            if(newComment.Content__c != null){
                this.noteDetails = newComment.Content__c;
            }
        }
    }
    
    public static String FIELD_CONTACT_ID = 'contactId';
    public static String FIELD_USER = 'user';
    public static String FIELD_CONTACT_DOCUMENTS = 'contactDocuments';
    public static String FIELD_DOCUMENT_TYPES = 'documentTypes';
    public static String FIELD_MAP_DOCUMENT_TYPES = 'documentMapOfTypes';
    public static String FIELD_APPLICATION_CHECKLIST = 'applicationChecklist';
    public static String FIELD_VALUE = 'value';
    public static String FIELD_LABEL = 'label';
    public static String FIELD_DELETE_STATUS = 'deleteStatus';
    public static String FIELD_SAVE_STATUS = 'saveStatus';
    public static String FIELD_MESSAGE = 'message';
    public static String SUCCESS = 'success';
    public static String FAILED = 'failed';
    public static String CHECKLIST_STATUS_REQUESTED = 'Requested';
    public static String CHECKLIST_STATUS_SUBMITTED = 'Submitted';
    public static String CHECKLIST_STATUS_INSUFFICIENT = 'Insufficient';
    public static String CHECKLIST_STATUS_NOT_REQUIRED = 'Not Required';

    @AuraEnabled
    public static Map<String, Object> saveFileAndContactDocumentChecklist(Id fileId, Id contactId, Id opportunityId, String docTypeValue, String docSubTypeValue, String docComments,
                                                                          Id checklistId, Boolean internalOnly) {
                                
        Map<String, Object> mapResult = new Map<String, Object>();

        if(fileId != null && contactId != null && opportunityId != null) {

            // get the file to update the Title
            List<ContentDocument> listFiles = [SELECT Id, Title, FileExtension FROM ContentDocument WHERE Id = :fileId];
            
            if(listFiles.size() < 1) {
                // EARLY OUT
                mapResult.put(FIELD_SAVE_STATUS, FAILED);
                mapResult.put(FIELD_MESSAGE, 'File not found for Id = ' + fileId);
                return mapResult;
            }
            
            for(ContentDocument cdVar: listFiles) {
                if(cdVar.Title.length() + cdVar.FileExtension.length() > 100) {
                    mapResult.put(FIELD_SAVE_STATUS, FAILED);
                    mapResult.put(FIELD_MESSAGE, 'Filename is too long for Id = ' + cdVar.Title.length());
                    return mapResult;
                }    
            }
            
            ContentDocument file = listFiles[0];
            String fileNameNoPrefix = file.Title;
            String docTypeLabel = getDocTypeLabel(docTypeValue);
            file.Title = docTypeLabel + '_' + file.Title;
            update file;
            
            // create contact document
            Contact_Document__c conDoc = new Contact_Document__c();
            conDoc.Contact__c = contactId;
            conDoc.Document_Type__c = docTypeValue;
            conDoc.Type__c = docSubTypeValue;
            conDoc.Comments__c = docComments;
            conDoc.Filename__c = fileNameNoPrefix + '.' + file.FileExtension;
            conDoc.Opportunity__c = opportunityId;
            conDoc.Internal_Only__c = internalOnly;
            conDoc.Submitted__c = true;
            conDoc.Post_Submission__c = true;

            if(!string.isBlank(checklistId)) conDoc.Document_Checklist__c = checklistId;
            insert conDoc;

            List<ContentDocumentLink> listLinks = new List<ContentDocumentLink>();
            
            // create checklist link
            if(!string.isBlank(checklistId)){
                ContentDocumentLink checklistLink = new ContentDocumentLink();
                checklistLink.ContentDocumentId = fileId;
                checklistLink.LinkedEntityId = checklistId;
                checklistLink.ShareType = 'I';
                checklistLink.Visibility = 'AllUsers';
                listLinks.add(checklistLink);
                
                Document_Checklist__c[] Checklist = [SELECT Id, Status__c 
                                                     FROM Document_Checklist__c
                                                     WHERE Id = :checklistId];
                
                if (Checklist.size() > 0){
                    if(!internalOnly){
                        if (Checklist[0].Status__c == CHECKLIST_STATUS_REQUESTED || Checklist[0].Status__c == CHECKLIST_STATUS_INSUFFICIENT){
                            Checklist[0].Status__c = CHECKLIST_STATUS_SUBMITTED;

                            try{
                                update Checklist;
                            }catch(Exception e){
                                ExLog.add('Apex Class', 'DocumentChecklistAcceptanceServices', 'saveFileAndContactDocumentChecklist', e.getMessage());
                                return null;
                            }

                        }
                    }
                }                
            }

            // create CD link
            ContentDocumentLink cdLink = new ContentDocumentLink();
            cdLink.ContentDocumentId = fileId;
            cdLink.LinkedEntityId = conDoc.Id;
            cdLink.ShareType = 'I';
            cdLink.Visibility = 'AllUsers';
            listLinks.add(cdLink);

            // create app-link
            ContentDocumentLink appLink = new ContentDocumentLink();
            appLink.ContentDocumentId = fileId;
            appLink.LinkedEntityId = opportunityId;
            appLink.ShareType = 'I';
            appLink.Visibility = 'AllUsers';
            listLinks.add(appLink);

            try{
                insert listLinks;
            }catch(Exception e ){
                ExLog.add('Apex Class', 'DocumentChecklistAcceptanceServices', 'saveFileAndContactDocumentChecklist', e.getMessage());
                return null;
            }           

            mapResult.put(FIELD_SAVE_STATUS, SUCCESS);
            String sMessage = '';
            sMessage += 'contact document ' + conDoc.Id;
            sMessage += ', cdlink ' + cdLink.Id;
            sMessage += ', appLink ' + appLink.Id;
            mapResult.put(FIELD_MESSAGE, sMessage);
        }
        else
        {
            mapResult.put(FIELD_SAVE_STATUS, FAILED);
            mapResult.put(FIELD_MESSAGE, 'Error in arguments: fileId = ' + fileId + ', contactId = '+contactId + ', oppId = ' + opportunityId);
        }


        // retrieve the latest list of documents again
        List<Contact_Document__c> listDocs = GetContactDocuments(opportunityId);
        mapResult.put(FIELD_CONTACT_DOCUMENTS, listDocs);

        return mapResult;
    }

    private static List<Contact_Document__c> GetContactDocuments(Id opportunityId) {

        List<Opportunity> listOpportunity = [
                SELECT Id, PrimaryContact__c
                FROM Opportunity
                WHERE Id = :opportunityId
        ];

        if(listOpportunity.size() > 0) {
            Opportunity opportunity = listOpportunity[0];
            Contact_Document__c[] documents = [
                    SELECT d.Id, toLabel(d.Document_Type__c), d.LastModifiedDate, d.Contact__c, d.Type__c, d.Comments__c, d.Filename__c, d.Submitted__c
                    FROM Contact_Document__c d
                    WHERE d.Contact__c = :opportunity.PrimaryContact__c
                    ORDER BY d.Submitted__c DESC
            ];

            return documents;
        }
        return new List<Contact_Document__c>();
    }

    @TestVisible
    private static String getDocTypeLabel(String docTypeValue){
        Schema.DescribeFieldResult fieldResult = Contact_Document__c.Document_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Map<String,String>> options = new List<Map<String,String>> ();
        for( Schema.PicklistEntry f : ple)
        {
            if(f.getValue() == docTypeValue)
            {
                return f.getLabel();
            }
        }
        return '';
    }
}