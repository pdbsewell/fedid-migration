/**
 * @description Implementation class for Digitary-specific Application Documents
 * @author      Nick Guia
 * @since       MAY.20.2024
 * @revision
 * 08/08/2024 - Kai-Fan Hsieh
 *  - Split deliver metadata and deliver content to separate end point
 *  - Add HTTP PATCH handler for adding new documents to existing deliver
 */
public with sharing class DigitaryApplicationDocumentImpl implements RESTlib_IClientImpl {
    public static final String CONTACT_DOC_DOC_TYPE_OTHER = 'OTHERDCTYP';
    // Digitary error codes that are listed in their API specification v1.5
    public static final String DIGITARY_ERROR_CODE_INVALID_PARAMETERS = 'Invalid_parameters';
    public static final String DIGITARY_ERROR_CODE_DUPLICATE_DELIVERY = 'duplicate_delivery';
    public static final String DIGITARY_ERROR_CODE_UNKNOWN_DELIVERY = 'unknown_delivery';
    public static final String DIGITARY_ERROR_CODE_DUPLICATE_DOCUMENT = 'duplicate_document';
    public static final String DIGITARY_ERROR_CODE_PARSE_ERROR = 'parse_error';
    @TestVisible
    private static Messaging.SendEmailResult[] emailResults;

    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandleGet() {
        return null; // Not implemented yet
    }
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePost() {
        return new HandlePost();
    }
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePut() {
        return null; // Not implemented yet
    }
    /**
     * @description should return the concrete handler class of the client implementation
     * @return `RESTlib_ClientImplHandler`
     */
    public RESTlib_ClientImplHandler getHandlePatch() {
        return new HandlePatch();
    }

    /**
     * @description Processes POST requests for create contact documents for new delivery
     * @author      Kai-Fan Hsieh
     * @since       08/08/2024
     */
    public with sharing virtual class HandlePost extends RESTlib_ClientImplHandler {
        private final Utils utils = new Utils();
        /**
         * @description set request type
         * @return `Type`
         */
        public override Type getRequestType() {
            return DigitaryApplicationDocumentPayload.PostRequest.class;
        }
        /**
         * @description set response type
         * @return `Type`
         */
        public override Type getResponseType() {
            return DigitaryApplicationDocumentPayload.PostResponse.class;
        }

        /**
         * @description  validation rules
         * @param reqObj Request
         * @throws RESTlib_Ex.InvalidRequestException Custom exception
         */
        public override void validate(RESTlib_Payload.Request reqObj) {
            DigitaryApplicationDocumentPayload.PostRequest req = (DigitaryApplicationDocumentPayload.PostRequest) reqObj;
            nebula.Logger.finest('postRequest details').setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI);

            if (String.isBlank(req.issuerDeliveryId)) {
                utils.logErrorWithRequest('issuerDeliveryId cannot be blank');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
            }

            if (String.isBlank(req.channel)) {
                utils.logErrorWithRequest('channel cannot be blank');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
            }

            if (String.isBlank(req.issuerDocumentOwnerName)) {
                utils.logErrorWithRequest('document owner name cannot be blank');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
            }

            if (String.isBlank(req.issuerDocumentOwnerEmail)) {
                utils.logErrorWithRequest('document owner email cannot be blank');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
            }

            // check required document properties
            utils.validateDocumentProperties(req.documents, req);

            if (String.isBlank(req.parameters?.monash_reference_id)) {
                utils.logErrorWithRequest('monash_reference_id cannot be blank');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_PARAMETERS);
            }

            // Retrieve a list of contact documents based on the issuer delivery ID
            List<Contact_Document__c> contactDocuments = new ElevatedContactDocumentSelector().selectByIssuerDeliveryId(req.issuerDeliveryId);

            /**
             * Check if any contact documents were found with the same issuer delivery ID.
             * If documents are found, log an error and throw a duplicate delivery exception.
             */
            if (!contactDocuments.isEmpty()) {
                utils.logErrorWithRequest('A delivery with the same ID has already been received');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_DUPLICATE_DELIVERY);
            }
        }

        /**
         * @description create Content Document(s) based on the payload request
         * @param reqObj Request
         * @param responseObj Response
         * @return `RESTlib_Payload.Response`
         * @throws RESTlib_Ex.InvalidRequestException Custom exception
         */
        public virtual override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            DigitaryApplicationDocumentPayload.PostRequest req = (DigitaryApplicationDocumentPayload.PostRequest) reqObj;
            DigitaryApplicationDocumentPayload.PostResponse resp = (DigitaryApplicationDocumentPayload.PostResponse) responseObj;

            /**
             * STEP 1 : query the application record or document checklist record and throw an error if not found
             */
            Application__c appRecord;
            Id documentChecklistId;
            List<Application__c> applications = new ElevatedApplicationSelector().selectByName(req?.parameters?.monash_reference_id);
            if (!applications.isEmpty()) {
                appRecord = applications.get(0);
            } else {
                List<Document_Checklist__c> documentChecklists = new ElevatedDocumentChecklistSelector().selectByName(req?.parameters?.monash_reference_id);
                if (!documentChecklists.isEmpty()) {
                    appRecord = new Application__c(
                        Id = documentChecklists.get(0).Application__c,
                        Applicant__c = documentChecklists.get(0).Application__r.Applicant__c
                    );
                    documentChecklistId = documentChecklists.get(0).Id;
                } else {
                    utils.logErrorWithRequest('Application Id or document checklist Id does not exist');
                    emailResults = utils.sentEmailToExternalDocumentOwner(req.issuerDocumentOwnerName, req.issuerDocumentOwnerEmail);
                    throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_INVALID_PARAMETERS);
                }
            }
            // Get contact record and email address history to match document owner
            appRecord.Applicant__r = new ElevatedContactSelector().selectById(appRecord.Applicant__c).get(0);
            /**
             * STEP 2 : create contact document(s) for a new delivery
             */
            List<Contact_Document__c> contactDocuments = createContactDocumentsForNewDelivery(req, appRecord, documentChecklistId);
            ElevatedDAO elevatedDAO = new ElevatedDAO();
            elevatedDAO.insertRecords(contactDocuments);
            /**
             * STEP 3: Set the filename for the contact document(s) after the insert operation.
             * The contact document name (auto number) is generated post-insert, and it is needed to create a unique filename.
             */
            utils.updateFilenames(contactDocuments);
            // framework updates the response status
            return resp;
        }

        /**
         * @description     creates a contact document record for the application and applicant
         * @param req       Request payload
         * @param appRecord related application record
         * @param documentChecklistId related Id for Document_Checklist__c record
         * @return `Contact_Document__c`
         */
        protected virtual List<Contact_Document__c> createContactDocumentsForNewDelivery(
            DigitaryApplicationDocumentPayload.PostRequest req, Application__c appRecord, Id documentChecklistId) {
            utils.checkRequiredFieldsCreateable();
            List<Contact_Document__c> contactDocumentsToInsert = new List<Contact_Document__c>();
            for (DigitaryApplicationDocumentPayload.Document document : req.documents) {
                contactDocumentsToInsert.add(new Contact_Document__c(
                    Contact__c = appRecord.Applicant__c,
                    Application__c = appRecord.Id,
                    Document_Type__c = CONTACT_DOC_DOC_TYPE_OTHER,
                    Document_Checklist__c = documentChecklistId,
                    Internal_Only__c = false,
                    Channel__c = req.channel,
                    Issuer_Delivery_Id__c = req.issuerDeliveryId,
                    Issuer_Name__c = document.issuerName,
                    Issuer_Document_Type__c = document.issuerDocumentType,
                    Inception_Date__c = document.issuerDate,
                    Issuer_Document_Id__c = document.issuerDocumentId,
                    Issuer_Document_Owner_Name__c = req.issuerDocumentOwnerName,
                    Issuer_Document_Owner_Email__c = req.issuerDocumentOwnerEmail,
                    Document_Owner_Mismatch__c = isDocumentOwnerMismatch(req, appRecord),
                    Verified__c = true));
            }
            return contactDocumentsToInsert;
        }

        private String getContactLegalFullName(Application__c appRecord) {
            if (String.isBlank(appRecord.Applicant__r.First_Name__c)) {
                return appRecord.Applicant__r.Last_Name__c;
            } else {
                return appRecord.Applicant__r.First_Name__c + ' ' + appRecord.Applicant__r.Last_Name__c;
            }
        }

        /**
         * @description This method compares the document owner's name and email provided by the issuer with the contact details stored in the CRM.
         * It checks for any mismatch between the provided name and email with the CRM contact's name and historical email addresses.
         * @param req The request payload containing the document owner's name and email.
         * @param appRecord The application record containing the CRM contact's details, including the applicant's legal name and email history.
         * @return true if there is a mismatch for both name and email address between the document owner details and the CRM contact, false otherwise.
         */
        private Boolean isDocumentOwnerMismatch(DigitaryApplicationDocumentPayload.PostRequest req, Application__c appRecord) {
            // Flag to indicate if a mismatch exists
            Boolean isDocumentOwnerMismatch = false;
            // Compare document owner's name with CRM contact's legal full name
            Boolean isDocumentOwnerNameMatch = req.issuerDocumentOwnerName.equalsIgnoreCase(getContactLegalFullName(appRecord));
            // Initially set email match flag to false
            Boolean isDocumentOwnerEmailAddressMatch = false;
            // Only check email addresses if the name does not match
            if (!isDocumentOwnerNameMatch) {
                // Loop through the applicant's historical email addresses
                for (Email__c emailAddressHistory : appRecord.Applicant__r.Emails__r) {
                    // Check if the document owner's email matches any of the historical email addresses
                    if (req.issuerDocumentOwnerEmail.equalsIgnoreCase(emailAddressHistory.Name)) {
                        isDocumentOwnerEmailAddressMatch = true;
                        break; // Exit loop once a match is found
                    }
                }
            }
            // Set mismatch flag to true if both name and email do not match
            if (!isDocumentOwnerNameMatch && !isDocumentOwnerEmailAddressMatch) {
                isDocumentOwnerMismatch = true;
            }
            // Return the mismatch status
            return isDocumentOwnerMismatch;
        }
    }

    /**
     * @description Processes POST requests for create contact documents for existing delivery
     * @author      Kai-Fan Hsieh
     * @since       08/08/2024
     */
    public with sharing virtual class HandlePatch extends RESTlib_ClientImplHandler {
        private final Utils utils = new Utils();
        private Contact_Document__c exisingContactDocumentWithSameDeliveryId;

        /**
         * @description set request type
         * @return `Type`
         */
        public override Type getRequestType() {
            return DigitaryApplicationDocumentPayload.PatchRequest.class;
        }
        /**
         * @description set response type
         * @return `Type`
         */
        public override Type getResponseType() {
            return DigitaryApplicationDocumentPayload.PatchResponse.class;
        }

        /**
         * @description  validation rules
         * @param reqObj
         * @throws RESTlib_Ex.InvalidRequestException
         */
        public override void validate(RESTlib_Payload.Request reqObj) {
            // Cast the request object to a specific type for further processing
            DigitaryApplicationDocumentPayload.PatchRequest req = (DigitaryApplicationDocumentPayload.PatchRequest) reqObj;
            nebula.Logger.finest('patchRequest details').setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI);

            if (String.isBlank(req.issuerDeliveryId)) {
                utils.logErrorWithRequest('issuerDeliveryId cannot be blank');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_UNKNOWN_DELIVERY);
            }

            // check required document properties
            utils.validateDocumentProperties(req.documents, req);

            // Retrieve a list of contact documents based on the issuer delivery ID
            List<Contact_Document__c> contactDocuments = new ElevatedContactDocumentSelector().selectByIssuerDeliveryId(req.issuerDeliveryId);

            // Check if no contact documents were found with the given issuer delivery ID
            if (contactDocuments.isEmpty()) {
                // Log an error and throw an exception if the delivery ID does not refer to an existing delivery
                nebula.Logger.error('The delivery ID does not refer to an existing delivery').addTag(RestContext.request.requestURI);
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_UNKNOWN_DELIVERY);
            }

            // Iterate through the contact documents
            for (Contact_Document__c c : contactDocuments) {
                // Iterate through the documents in the request
                for (DigitaryApplicationDocumentPayload.Document document : req.documents) {
                    // Check if any document in the request has the same issuer document ID as an existing contact document
                    if (c.Issuer_Document_Id__c == document.issuerDocumentId) {
                        // Log an error and throw an exception if a duplicate document is found
                        utils.logErrorWithRequest('A document with the same ID is already associated with the delivery');
                        nebula.Logger.finest('Contact_Document__c ' + c).addTag(RestContext.request.requestURI);
                        throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_DUPLICATE_DOCUMENT);
                    }
                }
            }

            // get one of contact from existing delivery so we can clone the properties (e.g. channel, application Id, document checklist Id).
            exisingContactDocumentWithSameDeliveryId = contactDocuments.get(0);
        }

        /**
         * @description create Content Document(s) based on the payload request
         * @param reqObj Request
         * @param responseObj Response
         * @return `RESTlib_Payload.Response`
         * @throws RESTlib_Ex.InvalidRequestException Custom exception
         */
        public virtual override RESTlib_Payload.Response process(RESTlib_Payload.Request reqObj, RESTlib_Payload.Response responseObj) {
            DigitaryApplicationDocumentPayload.PatchRequest req = (DigitaryApplicationDocumentPayload.PatchRequest) reqObj;
            DigitaryApplicationDocumentPayload.PatchResponse resp = (DigitaryApplicationDocumentPayload.PatchResponse) responseObj;

            /**
             * STEP 1 : create contact document(s) for an existing delivery
             */
            List<Contact_Document__c> contactDocuments = createContactDocumentsForExistingDelivery(req, exisingContactDocumentWithSameDeliveryId);
            ElevatedDAO elevatedDAO = new ElevatedDAO();
            elevatedDAO.insertRecords(contactDocuments);
            /**
             * STEP 2: Set the filename for the contact document(s) after the insert operation.
             * The contact document name (auto number) is generated post-insert, and it is needed to create a unique filename.
             */
            utils.updateFilenames(contactDocuments);
            // framework updates the response status
            return resp;
        }

        /**
         * @description     creates a contact document record for the application and applicant
         * @param req       Request payload
         * @param exisingContactDocument related exising contact document
         * @return `Contact_Document__c`
         */
        protected virtual List<Contact_Document__c> createContactDocumentsForExistingDelivery(DigitaryApplicationDocumentPayload.PatchRequest req, Contact_Document__c exisingContactDocument) {
            utils.checkRequiredFieldsCreateable();
            List<Contact_Document__c> contactDocumentsToInsert = new List<Contact_Document__c>();
            for (DigitaryApplicationDocumentPayload.Document document : req.documents) {
                contactDocumentsToInsert.add(new Contact_Document__c(
                    Contact__c = exisingContactDocument.Contact__c,
                    Application__c = exisingContactDocument.Application__c,
                    Document_Type__c = CONTACT_DOC_DOC_TYPE_OTHER,
                    Document_Checklist__c = exisingContactDocument.Document_Checklist__c,
                    Internal_Only__c = false,
                    Channel__c = exisingContactDocument.Channel__c,
                    Issuer_Delivery_Id__c = req.issuerDeliveryId,
                    Issuer_Name__c = document.issuerName,
                    Issuer_Document_Type__c = document.issuerDocumentType,
                    Inception_Date__c = document.issuerDate,
                    Issuer_Document_Id__c = document.issuerDocumentId,
                    Issuer_Document_Owner_Name__c = exisingContactDocument.Issuer_Document_Owner_Name__c,
                    Issuer_Document_Owner_Email__c = exisingContactDocument.Issuer_Document_Owner_Email__c,
                    Document_Owner_Mismatch__c = exisingContactDocument.Document_Owner_Mismatch__c,
                    Verified__c = true));
            }
            return contactDocumentsToInsert;
        }
    }

    /**
     * @description Classes for helper methods.
     */
    public with sharing class Utils {
        final String noReplyEmail = 'noreply@f.e.monash.edu';
        /**
         * @description Sends an email notification to the external document owner when a verified document reference ID is not found.
         * This method retrieves an email template and replaces tokens with the document owner's name and the application portal URL.
         * It then sends the email to the specified external document owner using an Org-Wide Email Address.
         * @param documentOwnerName The name of the document owner to be used in the email content.
         * @param documentOwnerEmail The email address of the document owner to whom the email will be sent.
         * @return `Messaging.SendEmailResult[]`
         */
        private Messaging.SendEmailResult[] sentEmailToExternalDocumentOwner(String documentOwnerName, String documentOwnerEmail) {
            String emailTemplateName = 'Notify_Verified_Document_Reference_Id_Not_Found_To_External_Document_Owner';
            String[] recipientEmails = new String[]{documentOwnerEmail};
            EmailTemplate emailTemplate = [SELECT HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = :emailTemplateName LIMIT 1];
            OrgWideEmailAddress orgWideEmail = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :noReplyEmail LIMIT 1];
            Environment_Settings__c envSettings = Environment_Settings__c.getOrgDefaults();

            // Replace the token with the documentOwnerName in the email body
            String emailBody = emailTemplate.HtmlValue;
            emailBody = emailBody.replace('{!Contact.Name}', documentOwnerName);
            emailBody = emailBody.replace('{!$Setup.Environment_Settings__c.MyAppPortalURL__c}', envSettings.MyAppPortalURL__c);
            String emailSubject = emailTemplate.Subject.replace('{!Contact.Name}', documentOwnerName);

            // Create the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(recipientEmails);
            email.setHtmlBody(emailBody);
            email.setSubject(emailSubject);
            email.setOrgWideEmailAddressId(orgWideEmail.Id);

            // Send the email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email}, false);
            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        logErrorWithRequest(error.getStatusCode() + ': ' + error.getMessage());
                    }
                }
            }
            return results;
        }

        /**
         * @description  log error with request
         * @param message error message
         */
        private void logErrorWithRequest(String message) {
            nebula.Logger.error(message).setRestRequestDetails(RestContext.request).addTag(RestContext.request.requestURI);
        }

        /**
         * @description  validate required document properties
         * @param documents List of DigitaryApplicationDocumentPayload.Document
         * @param request request
         */
        private void validateDocumentProperties(List<DigitaryApplicationDocumentPayload.Document> documents, Object request) {
            // documents cannot be blank
            if (documents == null || documents.isEmpty()) {
                logErrorWithRequest('documents cannot be null or empty');
                throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
            }

            for (DigitaryApplicationDocumentPayload.Document document : documents) {
                if (String.isBlank(document.issuerDocumentId)) {
                    logErrorWithRequest('issuerDocumentId cannot be blank');
                    throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
                }
                if (String.isBlank(document.issuerDocumentType)) {
                    logErrorWithRequest('issuerDocumentType cannot be blank');
                    throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
                }
                if (String.isBlank(document.issuerName)) {
                    logErrorWithRequest('issuerName cannot be blank');
                    throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
                }
                if (document.issuerDate == null) {
                    logErrorWithRequest('issuerDate cannot be null');
                    throw new RESTlib_Ex.InvalidRequestException(DIGITARY_ERROR_CODE_PARSE_ERROR);
                }
            }
        }

        /**
         * @description Checks if the necessary fields on Contact_Document__c are createable.
         * @throws DmlException if the object or any required field is not createable.
         */
        public void checkRequiredFieldsCreateable() {
            if (!Schema.SObjectType.Contact_Document__c.isCreateable()) {
                throw new DmlException('Operation failed due to object being inaccessible on SObject Contact_Document__c');
            }

            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Contact_Document__c.fields.getMap();
            List<String> requiredFields = new List<String>{
                'Contact__c',
                'Application__c',
                'Document_Type__c',
                'Document_Checklist__c',
                'Comments__c',
                'Filename__c',
                'Internal_Only__c',
                'Channel__c',
                'Issuer_Name__c',
                'Issuer_Document_Type__c',
                'Inception_Date__c',
                'Issuer_Delivery_Id__c',
                'Issuer_Document_Id__c',
                'Issuer_Document_Owner_Name__c',
                'Issuer_Document_Owner_Email__c',
                'Document_Owner_Mismatch__c',
                'Verified__c'
            };

            for (String field : requiredFields) {
                if (!fieldMap.get(field).getDescribe().isCreateable()) {
                    throw new DmlException('Operation failed due to one or more fields being inaccessible on SObject Contact_Document__c');
                }
            }
        }

        /**
         * @description Set the filename for the contact document(s) using the contact document name (auto number) to ensure uniqueness.
         * Note that Callista does not accept files with duplicate names. If a student has more than one qualification from the same university,
         * including the contact document name (auto number) will make the filename unique.
         * @param contactDocuments List of inserted Contact_Document__c records.
         */
        public void updateFilenames(List<Contact_Document__c> contactDocuments) {
            Map<Id, Contact_Document__c> contactDocumentIdMap = new Map<Id, Contact_Document__c>(contactDocuments);
            Map<Id, Contact_Document__c> contactDocumentsWithAutoNumbers =
                new Map<Id, Contact_Document__c>(new ElevatedContactDocumentSelector().selectByIds(contactDocumentIdMap.keySet()));
            for (Contact_Document__c contactDocument : contactDocumentIdMap.values()) {
                Contact_Document__c ContactDocumentWithAutoNumber = contactDocumentsWithAutoNumbers.get(contactDocument.Id);
                contactDocument.Filename__c =
                    ContactDocumentWithAutoNumber.Issuer_Name__c + ' - ' +
                    ContactDocumentWithAutoNumber.Issuer_Document_Type__c +
                    ' (' + ContactDocumentWithAutoNumber.Name + ').pdf';

            }
            ElevatedDAO elevatedDAO = new ElevatedDAO();
            elevatedDAO.updateRecords(contactDocuments);
        }
    }

    /**
     * @description Classes for elevated access selectors utilizing DynamicSoqlBuilder for Contact SObject queries without sharing enforcement.
     */
    private without sharing class ElevatedContactSelector {
        private final DynamicSoqlBuilder soqlBuilder;
        private final Set<String> contactFields = new Set<String>{
            'First_Name__c',
            'Last_Name__c',
            '(SELECT Name FROM Emails__r)'
        };

        /**
         * @description constructor. Initialises soql builder to not enforce security (given this is for elevated access)
         * and not have to validate fields given that fields will be static.
         */
        public ElevatedContactSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                .setEnforced(false) // do not enforce sharing for elevated access
                .validateFields(false); // no need to validate fields, they are static.
        }

        /**
         * @description query Contact record
         * @param contactId : Id of the contact
         * @return `List<Contact>`
         */
        public List<Contact> selectById(Id contactId) {
            String whereClause = 'Id = :contactId';
            String soqlStr = this.soqlBuilder.querySObject('Contact')
                .queryFields(contactFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }
    }

    /**
     * @description Classes for elevated access selectors utilizing DynamicSoqlBuilder for Application__c SObject queries without sharing enforcement.
     */
    private without sharing class ElevatedApplicationSelector {
        private final DynamicSoqlBuilder soqlBuilder;
        private final Set<String> applicationFields = new Set<String>{
            'Applicant__c'
        };

        /**
         * @description constructor. Initialises soql builder to not enforce security (given this is for elevated access)
         * and not have to validate fields given that fields will be static.
         */
        public ElevatedApplicationSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                .setEnforced(false) // do not enforce sharing for elevated access
                .validateFields(false); // no need to validate fields, they are static.
        }

        /**
         * @description query Application record
         * @param applicationName : Name of the application
         * @return `List<Application__c>`
         */
        public List<Application__c> selectByName(String applicationName) {
            String whereClause = 'Name = :applicationName';
            String soqlStr = this.soqlBuilder.querySObject('Application__c')
                .queryFields(applicationFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }
    }

    /**
     * @description Classes for elevated access selectors utilizing DynamicSoqlBuilder for Document_Checklist__c SObject queries without sharing enforcement.
     */
    private without sharing class ElevatedDocumentChecklistSelector {
        private final DynamicSoqlBuilder soqlBuilder;
        private final Set<String> documentChecklistFields = new Set<String>{
            'Application__c',
            'Application__r.Applicant__c'
        };

        /**
         * @description constructor. Initialises soql builder to not enforce security (given this is for elevated access)
         * and not have to validate fields given that fields will be static.
         */
        public ElevatedDocumentChecklistSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                .setEnforced(false) // do not enforce sharing for elevated access
                .validateFields(false); // no need to validate fields, they are static.
        }

        /**
         * @description query Document_Checklist__c record
         * @param documentChecklistName : Name of the document checklist
         * @return `List<Document_Checklist__c>`
         */
        public List<Document_Checklist__c> selectByName(String documentChecklistName) {
            String whereClause = 'Name = :documentChecklistName';
            String soqlStr = this.soqlBuilder.querySObject('Document_Checklist__c')
                .queryFields(documentChecklistFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }
    }

    /**
     * @description Classes for elevated access selectors utilizing DynamicSoqlBuilder for Contact Document SObject queries without sharing enforcement.
     */
    private without sharing class ElevatedContactDocumentSelector {
        private final DynamicSoqlBuilder soqlBuilder;
        private final Set<String> contactDocumentFields = new Set<String>{
            'Id',
            'Issuer_Delivery_Id__c',
            'Issuer_Document_Id__c',
            'Issuer_Name__c',
            'Issuer_Document_Type__c',
            'Issuer_Document_Owner_Name__c',
            'Issuer_Document_Owner_Email__c',
            'Document_Owner_Mismatch__c',
            'Application__c',
            'Application__r.Status__c',
            'Document_Checklist__c',
            'Filename__c',
            'Contact__c',
            'Channel__c',
            'Name'
        };

        /**
         * @description constructor. Initialises soql builder to not enforce security (given this is for elevated access)
         * and not have to validate fields given that fields will be static.
         */
        public ElevatedContactDocumentSelector() {
            this.soqlBuilder = DynamicSoqlBuilder.getInstance()
                .setEnforced(false) // do not enforce sharing for elevated access
                .validateFields(false); // no need to validate fields, they are static.
        }

        /**
         * @description query Contact_Document__c record by issuer delivery id
         * @param issuerDeliveryId : issuer delivery id
         * @return `List<Contact_Document__c>`
         */
        public List<Contact_Document__c> selectByIssuerDeliveryId(String issuerDeliveryId) {
            String whereClause = 'Issuer_Delivery_Id__c = :issuerDeliveryId AND Issuer_Delivery_Id__c != NULL';
            String soqlStr = this.soqlBuilder.querySObject('Contact_Document__c')
                .queryFields(contactDocumentFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }

        /**
         * @description query Contact_Document__c records by list of contact document Ids
         * @param contactDocumentIds : List of contact document Ids
         * @return `List<Contact_Document__c>`
         */
        public List<Contact_Document__c> selectByIds(Set<Id> contactDocumentIds) {
            String whereClause = 'Id IN :contactDocumentIds';
            String soqlStr = this.soqlBuilder.querySObject('Contact_Document__c')
                .queryFields(contactDocumentFields)
                .getQuery(whereClause);
            return Database.query(soqlStr);
        }
    }


}