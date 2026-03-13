/**
 * @author      Kristian Vegerano
 * @description Service class for document checklist object
 * @group       Service
 * @revision    10/06/2019 - Kristian Vegerano - Created
 *              21/07/2023 - Peter Sewell - Added support for archived documents 
 * 				17/04/2024 - Peter Sewell - Dont set archived flag if document has recovered flag set 
 *              16/04/2024 - Inderpal Dhanoa - SMSTA-57 Document Checklist for Qualification assessments
 *              8/10/2024 - Kai-Fan Hsieh - DANO-274 Show document placeholder for potential document owner mismatched documents
 *              4/11/2024 - Vishal Gupta - MGROI-536 document request cancelled comments should not be visible on the UI
 */
public with sharing class DocumentChecklistAssessmentServices {
    public static final String PROXY_DOC_RECORD_TYPE = 'Archive_Proxy'; // API name for Proxy Docs ContentVersion record type
    public static final String LOG_TAG = 'Admissions';
    /**
     * @author      Kristian Vegerano
     * @description Retrieves the user record relevant to the application's applicant contact record
     * @param       applicationId application Id
     * @return      Object
     * @revision    12/07/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled(cacheable=true)
    public static Object retrieveApplicantCommunityUser(Id applicationId) {
        User communityUser;
        for (User loopUser : [SELECT Id FROM User WHERE ContactId IN (SELECT Applicant__c FROM Application__c WHERE Id = :applicationId) LIMIT 1]) {
            communityUser = loopUser;
        }
        if (communityUser == null) {
            for (User loopUser : [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]) {
                communityUser = loopUser;
            }
        }
        return communityUser;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the application record relevant for the document checklist component
     * @param       applicationId Applicaiton Id
     * @return      Object
     * @revision    13/09/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object retrieveApplicationRecord(Id applicationId) {
        Application__c applicationRecord = [
            SELECT Id, Name, AgentEmailAddress__c, Sponsor_Email_Address__c, Proxy_Email_Address__c, Applicant__c,
                Checklist_Ad_Hoc_Email_Status__c, Checklist_output__c, Checklist_output_completed__c, Source_System__c
            FROM Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        return applicationRecord;
    }

    /**
     * @author      Kristian Vegerano
     * @description Runs the rules evaluation service
     * @param       category Category of the rules
     * @param       requestApplicationId Application Id
     * @return      Object
     * @revision    10/06/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object runRules(String category, String requestApplicationId) {
        Object result;
        try {
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{requestApplicationId});
            rulesDocChecklistEngine.evaluateRules(category);

            //Commit records
            List<Document_Checklist__c> resultChecklistItemsList = rulesDocChecklistEngine.resultChecklistItemsMap.get(requestApplicationId).values();
            upsert resultChecklistItemsList;

            result = resultChecklistItemsList;
        } catch (Exception e) {
            //ExLog.add('DocumentChecklistAssessmentServices', 'Document Checklist', 'runRules', e);
            result = e.getMessage();
        }

        return result;
    }

    /**
     * @author      Kristian Vegerano
     * @description Runs the rules evaluation service
     * @param       category Category of the rules
     * @param       requestApplicationId Application Id
     * @return      Object
     * @revision    10/06/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object runRulesUpdateEmailResults(String category, String requestApplicationId) {
        Object result;
        Map<String, Object> outputResult = new Map<String, Object>();
        try {
            DocumentChecklistRuleServices rulesDocChecklistEngine = new DocumentChecklistRuleServices(new Set<Id>{requestApplicationId});
            rulesDocChecklistEngine.evaluateRules(category);

            //Save output results
            outputResult.put('PENDING', String.join(rulesDocChecklistEngine.retrieveChecklistItemsEmailInstructions(requestApplicationId), ''));
            outputResult.put('COMPLETED', String.join(rulesDocChecklistEngine.retrieveCompleteChecklistItemsEmailInstructions(requestApplicationId), ''));

            Boolean hasIncomplete = false;
            for (Document_Checklist__c loopChecklist : rulesDocChecklistEngine.resultChecklistItemsMap.get(requestApplicationId).values()) {
                if (loopChecklist.Status__c == 'Insufficient' || loopChecklist.Status__c == 'Requested') {
                    hasIncomplete = true;
                }
            }
            outputResult.put('HASINCOMPLETE', hasIncomplete);

            result = outputResult;
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            result = e.getMessage();
        }

        return result;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the checklist records related to the application id on the parameter
     * @param       requestApplicationId Application Id
     * @return      Object
     * @revision    10/06/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object retrieveChecklistItems(String requestApplicationId) {
        Object result;
        try {
            //Query items
            List<Document_Checklist__c> applicationChecklistList = new List<Document_Checklist__c>();
            for (Document_Checklist__c loopChecklistItem : new DocumentChecklistsSelector().selectApplicationAssessmentByApplicationIds(new Set<Id>{requestApplicationId})) {
                //Include if not cancelled
                if (loopChecklistItem.status__c != System.Label.Application_Checklist_Auto_Cancelled) {
                    applicationChecklistList.add(loopChecklistItem);
                }
            }

            result = applicationChecklistList;
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            result = e.getMessage();
        }

        return result;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the ContentDocument records related to the checklist via ContentDocumentLink
     * @param       checklistItemId Document checklist item Id
     * @param       applicantId Applicant Id
     * @param       applicationId Application Id
     * @return      Object
     * @revision    10/06/2019 - Kristian Vegerano - Created
     *              18/09/2024 - Kai-Fan Hsieh - DANO-243 Show document placeholder for potential document owner mismatched documents
     */
    @AuraEnabled
    public static Object retrieveChecklistFiles(String checklistItemId, String applicantId, String applicationId) {
        Map<String, Object> resultMap = new Map<String, Object>();

        try {
            //Initialize Variables
            List<ChecklistNote> notesList = new List<ChecklistNote>();
            List<ChecklistDocument> checklistDocumentItemList = new List<ChecklistDocument>();
            Map<Id, Contact_Document__c> contentToContactDocumentMap = new Map<Id, Contact_Document__c>();
            Map<Id, Contact_Document__c> mismatchContactDocumentMap = new Map<Id, Contact_Document__c>();

            //Retrieve documents
            //Collect contact document ids related to the checklist  
            if (applicationId != null) {
                for (Contact_Document__c loopContactDocument : [
                    SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c,
                        Document_Checklist__r.Rule_DeveloperName__c, Document_Checklist__r.Status__c, Application__c,
                        Internal_Only__c, Comments__c, Document_Assessment_Status__c, Document_Owner_Mismatch__c,
                        Document_Status__c, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks)
                    FROM Contact_Document__c
                    WHERE Document_Checklist__c = :checklistItemId
                    AND Contact__c = :applicantId
                    AND Contact__c != null
                    AND Application__c = :applicationId
                ]) {
                    //Collect document links
                    if (!loopContactDocument.ContentDocumentLinks.isEmpty()) {
                        for (ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks) {
                            contentToContactDocumentMap.put(loopLink.ContentDocumentId, loopContactDocument);
                        }
                    } else {
                        // DANO-274
                        // When there is no content document link visible to current user and document owner mismatch is true,
                        // it means this document is under review and only internal users can access it.
                        // We only show the document placeholder so current My.App user cannot view or download the document.
                        if (loopContactDocument.Document_Owner_Mismatch__c) {
                            mismatchContactDocumentMap.put(loopContactDocument.Id, loopContactDocument);
                        }
                    }
                }
            } else {
                //Retrieve contact documents for contact qualification records
                for (Contact_Document__c loopContactDocument : [
                    SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c, Document_Checklist__r.Rule_DeveloperName__c, Document_Checklist__r.Status__c, Application__c,
                        Internal_Only__c, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks)
                    FROM Contact_Document__c
                    WHERE Document_Checklist__c = :checklistItemId
                    AND Contact__c = :applicantId
                    AND Contact__c != null
                ]) {
                    //Collect document links
                    if (loopContactDocument.ContentDocumentLinks != null) {
                        for (ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks) {
                            contentToContactDocumentMap.put(loopLink.ContentDocumentId, loopContactDocument);
                        }
                    }
                }
            }

            //Check if there are document links
            if (!contentToContactDocumentMap.isEmpty()) {
                //Query content document records
                for (ContentDocument loopContentDocument : [
                    SELECT Id, Description, FileExtension, FileType, Title
                    FROM ContentDocument
                    WHERE Id IN :contentToContactDocumentMap.keySet()
                    ORDER BY CreatedDate DESC
                ]) {
                    checklistDocumentItemList.add(new ChecklistDocument(loopContentDocument, contentToContactDocumentMap.get(loopContentDocument.Id)));
                }
            }

            for (Contact_Document__c contactDocument : mismatchContactDocumentMap.values()) {
                checklistDocumentItemList.add(new ChecklistDocument(new ContentDocument(), contactDocument));
            }

            resultMap.put('documents', checklistDocumentItemList);
            //Retrieve notes
            for (Document_Checklist_Comment__c loopComment : [
                SELECT Id, Document_Checklist__c, Content__c, CreatedDate, CreatedBy.Name, NotesSeen__c
                FROM Document_Checklist_Comment__c
                WHERE Document_Checklist__c = :checklistItemId
                AND Cancelled__c = false //MGROI-536 document request cancelled comments should not be visible on the UI
                ORDER BY CreatedDate DESC
            ]) {
                notesList.add(new ChecklistNote(loopComment));
            }
            resultMap.put('notes', notesList);
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('error', e.getMessage());
        }
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Updates the checklist item to not required. And inserts a content note if necessary
     * @param       checklistId Document Checklist Id
     * @param       commentContent Content of the comment
     * @param       noteOwnerId Owner Id of the note
     * @return      Object
     * @revision    11/07/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> writeNotes(Id checklistId, String commentContent, String noteOwnerId) {
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
            Document_Checklist_Comment__c newComment = new Document_Checklist_Comment__c();
            newComment.Content__c = commentContent;
            newComment.Document_Checklist__c = checklistId;
            insert newComment;
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('error', e.getMessage());
        }
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the checklist item related to the contact qualification
     * @param       contactQualificationId Id of the contact qualification
     * @return      Map<String, Object>
     * @revision    08/08/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> retrieveContactQualificationChecklistItem(Id contactQualificationId) {
        Map<String, Object> resultMap = new Map<String, Object>();

        try {
            //Initialize Variables
            Document_Checklist__c contextChecklist;
            for (Document_Checklist__c loopChecklist : [
                SELECT Id, Contact__c
                FROM Document_Checklist__c
                WHERE Contact_Qualification__c = :contactQualificationId
                AND Status__c != 'Auto Cancelled'
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ]) {
                contextChecklist = loopChecklist;
            }

            if (contextChecklist != null) {
                resultMap.put('Status', 'Success');
                resultMap.put('ChecklistId', contextChecklist.Id);
                resultMap.put('ContactId', contextChecklist.Contact__c);
            } else {
                resultMap.put('Status', 'No Checklist Found');
            }
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('error', e.getMessage());
        }
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Retrieves the checklist item related to the application's task 
     * @param       applicationTaskType Type of the application task
     * @return      Map<String, Object>
     * @revision    08/08/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> retrieveTaskTypeChecklistItem(String applicationTaskType) {
        Map<String, Object> resultMap = new Map<String, Object>();

        try {
            List<String> keyList = applicationTaskType.split(':::');
            Id applicationId = keyList[0];
            String taskType = keyList[1];

            //Initialize Variables
            Document_Checklist__c contextChecklist;
            for (Document_Checklist__c loopChecklist : [
                SELECT Id, Contact__c
                FROM Document_Checklist__c
                WHERE Application__c = :applicationId
                AND Type__c = :taskType
                AND Status__c != 'Auto Cancelled'
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ]) {
                contextChecklist = loopChecklist;
            }

            if (contextChecklist != null) {
                resultMap.put('Status', 'Success');
                resultMap.put('ChecklistId', contextChecklist.Id);
                resultMap.put('ContactId', contextChecklist.Contact__c);
            } else {
                resultMap.put('Status', 'No Checklist Found');
            }
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('error', e.getMessage());
        }
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the email template used for sending out ad hoc email templates
     * @return      Object
     * @revision    03/09/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> retrieveAssessmentAdHocEmailTemplate() {
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
            //Query items
            EmailTemplate adHocReminderTemplate;
            for (EmailTemplate loopTemplate : [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Assessment_Document_Checklist_Ad_Hoc' LIMIT 1]) {
                adHocReminderTemplate = loopTemplate;
            }
            //Retrieve document items
            String headerImage;
            String footerImage;
            for (StaticResource loopResource : [
                SELECT Id, Name, SystemModStamp
                FROM StaticResource
                WHERE Name IN ('ApplicationAssessmentDocumentReminderHeader', 'ApplicationAssessmentDocumentReminderFooter')
                LIMIT 2
            ]) {
                if (loopResource.Name == 'ApplicationAssessmentDocumentReminderHeader') {
                    headerImage = '/resource/' + String.valueOf(((DateTime) loopResource.get('SystemModStamp')).getTime()) + '/' + loopResource.get('Name');
                }
                if (loopResource.Name == 'ApplicationAssessmentDocumentReminderFooter') {
                    footerImage = '/resource/' + String.valueOf(((DateTime) loopResource.get('SystemModStamp')).getTime()) + '/' + loopResource.get('Name');
                }
            }

            resultMap.put('Template', adHocReminderTemplate);
            resultMap.put('HeaderImage', headerImage);
            resultMap.put('FooterImage', footerImage);
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('Error', e.getMessage());
        }

        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Sends an email message and creates an admissions enquiry to receive the reply
     * @param       applicationId Application ID
     * @param       emailContent Email content
     * @param       ccAddresses CC email address
     * @param       emailSubject Email subject
     * @param       fromEmail From email address
     * @param       acpId Id of application course preference record
     * @param       emailTextContent Email content
     * @return      Map<String, Object>
     * @revision    05/09/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> submitAdmissionsEnquiryEmail(String applicationId, String emailContent, String ccAddresses, String emailSubject, String fromEmail, String acpId, String emailTextContent) {
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
            //Query relevant application details
            Application__c relevantApplication;
            for (Application__c loopApplication : [
                SELECT Id, AgentEmailAddress__c, Sponsor_Email_Address__c, Proxy_Email_Address__c, Applicant__c, Applicant__r.Email, (SELECT Id FROM Application_Course_Preferences__r WHERE Preference_Number__c = '1' LIMIT 1)
                FROM Application__c
                WHERE Id = :applicationId
            ]) {
                relevantApplication = loopApplication;
            }

            //Build enquiry and email
            if (relevantApplication != null) {
                //Retrieve MU Docs Queue
                Group muDocsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SRA_IA_MU_Docs' LIMIT 1];
                //Retrieve MU Docs org-wide address
                OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'mu.documents@f.e.monash.edu' LIMIT 1];

                //Insert admissions enquiry
                Case agentEnquiry = new Case();
                agentEnquiry.Subject = emailSubject;
                agentEnquiry.ContactId = relevantApplication.Applicant__c;
                agentEnquiry.Description = emailTextContent.stripHtmlTags();
                agentEnquiry.Notify_Agent__c = true;
                agentEnquiry.Enquiry_Type__c = 'Future Course';
                agentEnquiry.Category_Level_1__c = 'New Application';
                agentEnquiry.Status = 'Solved';
                agentEnquiry.Origin = 'Email - mu.documents';
                agentEnquiry.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId();
                agentEnquiry.OwnerId = muDocsQueue.Id;

                //Check if there are known acp, get the application's first acp if not known
                if (acpId == null || acpId == '') {
                    //Get application's first preference
                    if (relevantApplication.Application_Course_Preferences__r != null) {
                        for (Application_Course_Preference__c loopACP : relevantApplication.Application_Course_Preferences__r) {
                            agentEnquiry.Application_Course_Preference__c = loopACP.Id;
                        }
                    }
                } else {
                    agentEnquiry.Application_Course_Preference__c = acpId;
                }
                insert agentEnquiry;

                //Retrieve enquiry details
                Case resultEnquiry = [SELECT Id, CaseNumber FROM Case WHERE Id = :agentEnquiry.Id];
                resultMap.put('Enquiry', resultEnquiry);

                //Retrieve community login url to access image static resource outside salesforce
                Network communityNetwork = [SELECT Id, Name FROM Network WHERE Name = 'my.application' LIMIT 1];
                String communityUrl = Network.getLoginUrl(communityNetwork.Id);
                communityUrl = communityUrl.replace('/admissions/s/login', '');

                //Replace image url to use community to access static resource
                emailContent = emailContent.replace('/resource', communityUrl + '/resource');
                //Add email thread
                emailContent = emailContent.replace('<thread></thread>', 'System information please do not delete: ' + EmailMessages.getFormattedThreadingToken(agentEnquiry.Id));

                //Build email message
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setPlainTextBody(emailTextContent);
                message.setHtmlBody(emailContent);
                message.setSubject(emailSubject);
                message.setReplyTo(fromEmail);
                message.setOrgWideEmailAddressId(orgWideAddress.Id);
                message.setToAddresses(new List<String>{relevantApplication.Applicant__r.Email});
                message.setWhatId(agentEnquiry.Id);

                //Build ccaddresses
                List<String> ccAddressesList = new List<String>();
                if (ccAddresses != '' && ccAddresses != null) {
                    for (String loopCcEmailAddress : ccAddresses.split(',')) {
                        ccAddressesList.add(loopCcEmailAddress);
                    }
                }
                //Add agent email
                if (relevantApplication.AgentEmailAddress__c != null) {
                    ccAddressesList.add(relevantApplication.AgentEmailAddress__c);
                }
                //Add proxy email
                if (relevantApplication.Sponsor_Email_Address__c != null) {
                    ccAddressesList.add(relevantApplication.Sponsor_Email_Address__c);
                }
                //Add proxy email
                if (relevantApplication.Proxy_Email_Address__c != null) {
                    ccAddressesList.add(relevantApplication.Proxy_Email_Address__c);
                }
                if (!ccAddressesList.isEmpty()) {
                    message.setCcAddresses(ccAddressesList);
                }

                //Send email message
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
                Messaging.sendEmail(messages);
                resultMap.put('Status', 'Success');
            } else {
                resultMap.put('Status', 'ApplicationMissing');
            }
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('Status', 'Error');
        }

        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the date time when last document reminder has been sent out
     * @param applicationId Application Id
     * @param applicantId Applicant Id
     * @param applicationSourceSystem Source system of the application
     * @return      Object
     * @revision    03/10/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> retrieveLastReminderSentDateTime(String applicationId, String applicantId, String applicationSourceSystem) {
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
            //Query items
            DateTime lastDocumentReminderSent;

            //Retrieve last sent documents reminder enquiry for non my.app applications
            if (applicationSourceSystem != 'my.app') {
                for (Case loopCase : [
                    SELECT Id, CreatedDate
                    FROM Case
                    WHERE ContactId = :applicantId
                    AND Origin = 'Email - mu.documents'
                    AND Subject LIKE '%Monash University needs your documents!'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ]) {
                    lastDocumentReminderSent = loopCase.CreatedDate;
                }
            }

            //Retrieve last sent documents reminder individual email results for my.app applications
            if (applicationSourceSystem == 'my.app') {
                for (Application__History loopHistory : [
                    SELECT Id, OldValue, NewValue, CreatedDate
                    FROM Application__History
                    WHERE ParentId = :applicationId
                    AND Field = 'Checklist_Ad_Hoc_Email_Status__c'
                    ORDER BY CreatedDate DESC
                    LIMIT 50
                ]) {
                    //Evaluates to true if SFMC updates the field from send to mc to email sent
                    if ((loopHistory.OldValue == 'Send to MC' && loopHistory.NewValue == 'Email Sent')) {
                        lastDocumentReminderSent = loopHistory.CreatedDate;
                        break;
                    }
                }

                //When test is running. Query to Application__History returns nothing on test class.
                if (Test.isRunningTest()) {
                    lastDocumentReminderSent = System.NOW();
                }
            }

            //Handle null returns correctly
            if (lastDocumentReminderSent != null) {
                resultMap.put('LastSentDateTime', lastDocumentReminderSent.format());
            } else {
                resultMap.put('LastSentDateTime', lastDocumentReminderSent);
            }
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('Error', e.getMessage());
        }

        return resultMap;
    }

    /**
     * @description  This class represents a form for a Contact Qualification Field Set.
     *               It is used to hold details such as the API Name, Label, and the related
     *               Contact Qualification Record ID.
     */
    public class ContactQualFieldSetForm {
        /**
         * @description The API name of the field.
         */
        @AuraEnabled
        public String APIName { get;set; }
        /**
         * @description The field label.
         */
        @AuraEnabled
        public String Label { get;set; }
        /**
        * @description The record Id.
        */
        @AuraEnabled
        public String contactQualRecdId { get;set; }
    }

    /**
     * @description  This wrapper class represents a document of a checklist item.
     *               It is used for managing and displaying various types of documents
     *               related to a contact, including file names, types, and metadata
     *               like creation date and archival status.
     */
    public class ChecklistDocument {
        /**
        * @description Contact document Id
        */
        @AuraEnabled
        public Id contactDocumentId { get; set; }
        /**
         * @description Content document Id
         */
        @AuraEnabled
        public Id contentDocumentId { get; set; }
        /**
         * @description Contact document record
         */
        @AuraEnabled
        public Contact_Document__c contactDocument { get; set; }
        @AuraEnabled
        /**
         * @description Content document record
         */
        public ContentDocument contentDocument { get; set; }
        /**
         * @description Document file name
         */
        @AuraEnabled
        public String fileName { get; set; }
        /**
         * @description Contact file type
         */
        @AuraEnabled
        public String fileType { get; set; }
        @AuraEnabled
        /**
         * @description Formatted document created date time
         */
        public String formattedCreatedDateTime { get; set; }
        /**
         * @description URL of the file icon
         */
        @AuraEnabled
        public String iconURL { get; set; }
        /**
         * @description Type of document
         */
        @AuraEnabled
        public String documentType { get; set; }
        /**
         * @description Indicates whether the record is archived.
         */
        @AuraEnabled
        public Boolean isArchived { get; set; }

        /**
         * @description  Constructor that initializes a ChecklistDocument using a ContentDocument and Contact_Document__c.
         * @param newContentDocument  The ContentDocument object representing the Salesforce content document.
         * @param newContactDocument  The Contact_Document__c object representing the contact-related document.
         */
        public ChecklistDocument(ContentDocument newContentDocument, Contact_Document__c newContactDocument) {
            this.contentDocumentId = newContentDocument.Id;
            this.contentDocument = newContentDocument;
            this.contactDocumentId = newContactDocument.Id;
            this.contactDocument = newContactDocument;
            this.isArchived = false;

            // Check if the document is a proxy document replacing the archived original
            for (ContentVersion cv : [
                SELECT Id, RecordTypeId, Is_Recovered_Version__c
                FROM ContentVersion
                WHERE ContentDocumentId = :newContentDocument.Id
                AND IsLatest = true
            ]) {
                if (recordTypeMatches(cv.RecordTypeId, PROXY_DOC_RECORD_TYPE) && !cv.Is_Recovered_Version__c) {
                    this.isArchived = true;
                }
            }

            //Set document type
            documentType = this.contactDocument.Document_Type__c;
            if (this.contactDocument.Document_Checklist__r.Rule_DeveloperName__c != null) {
                if (this.contactDocument.Document_Checklist__r.Rule_DeveloperName__c.containsIgnoreCase('visa_check')) {
                    documentType = 'Personal: Supplementary VISA documentation';
                }
            }

            //Get file name without the extension
            if (newContactDocument.Filename__c != null) {
                List<String> fileNameComponents = newContactDocument.Filename__c.split('\\.');
                fileNameComponents.remove(fileNameComponents.size() - 1);
                this.fileName = String.join(fileNameComponents, '.');
            }

            //Access static resource
            this.iconURL = '';
            String customLogoLink = PageReference.forResource('CustomFileIcons').getUrl();
            if (customLogoLink.contains('?')) {
                customLogoLink = customLogoLink.substring(0, customLogoLink.indexOf('?'));
            } else {
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

    /**
     * @description  This class represents a note associated with a document checklist.
     *               It contains details from the Document_Checklist_Comment__c object
     *               and extracts any relevant content for display or processing.
     */
    public class ChecklistNote {
        /**
         * @description  Document_Checklist_Comment__c record
         */
        @AuraEnabled
        public Document_Checklist_Comment__c contentNote { get; set; }
        @AuraEnabled
        /**
         * @description  Note details
         */
        public String noteDetails { get; set; }

        /**
         * @description  Constructor that initializes a ChecklistNote using a
         *               Document_Checklist_Comment__c object. It assigns the comment content
         *               to the noteDetails field if available.
         *
         * @param newComment  The Document_Checklist_Comment__c object representing the checklist
         *                    comment.
         */
        public ChecklistNote(Document_Checklist_Comment__c newComment) {
            this.contentNote = newComment;
            this.noteDetails = '';
            if (newComment.Content__c != null) {
                this.noteDetails = newComment.Content__c;
            }
        }
    }

    /**
     * @description  Compares the developer name (API name) of a record type to a given developer name
     *               string and returns true if they match.
     * @param recordTypeId       The Id of the record type to check.
     * @param recordTypeDevName  The developer name (API name) to compare against.
     *
     * @return  Boolean          Returns true if the developer name of the record type matches
     */
    @TestVisible
    private static Boolean recordTypeMatches(String recordTypeId, String recordTypeDevName) {

        // Bad inputs
        if (String.isBlank(recordTypeId)) {
            return false;
        }
        if (String.isBlank(recordTypeDevName)) {
            return false;
        }

        // No matches
        RecordType recordType = [SELECT DeveloperName FROM RecordType WHERE Id = :recordTypeId];
        if (recordType == null) {
            return false;
        }
        if (recordType.DeveloperName != recordTypeDevName) {
            return false;
        }

        // Matched if we get here!
        return true;
    }

    @AuraEnabled(cacheable=true)
    public static Task getTaskRecord(String recordId) {
        // SOQL to fetch the Task record
        return [SELECT Id, WhatId FROM Task WHERE Id = :recordId LIMIT 1];
    }
}