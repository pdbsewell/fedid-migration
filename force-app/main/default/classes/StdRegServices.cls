public without sharing class StdRegServices {
/**
* @author Ken McGuire
* @date 24.05.2021
* @group Recruitment
* @description Provides System Mode Access required for the processing of Course Enquiries, Course Registration
* and Course Payments.
* @revision 17.05.2021 - Initial Create
*           Ken McGuire - 24.05.2021 - PRODEV-687 - Added Comments
*           P.Victoriano - 26 May 2021 - update getMagentoURL
*           Cartick Sub - 27 May 2021 - PRODEV-700 Fix ACP Course Type Text field value
**/
    // ***************************** string constants *********************************** //
    private final static string COUNTRY_AUSTRALIA = 'Australia';
    private final static string STUDENT_TYPE_DOMESTIC = 'Domestic';
    private final static string STUDENT_TYPE_INTERNATIONAL = 'International';
    private final static string ONLINE_COURSE_REGISTRATION = 'Online Course Registration';
    private final static string ORIGIN_WEB = 'Web';
    private final static string ENQUIRY_TYPE_FUTURE_COURSE = 'Future Course';
    private final static string SOBJECT_APINAME_CASE = 'Case';
    private final static string CASE_STATUS_OPEN = 'Open';
    private final static string CASE_DESCRIPTION_VALIDATE_CONCESSION = 'Concession user - please validate eligibility';
    private final static string SOBJECT_APINAME_APPLICATION = 'Application__c';
    private final static string RECORD_TYPE_NAME_PROFESSIONAL_DEVELOPMENT = 'Professional Development';
    private final static string STATUS_SOLVED = 'Solved';
    private final static string ERROR_INVALID_REQUEST = 'Invalid Request';
    private final static string ERROR_DATA_NOT_FOUND = 'Could not find the data requested';
    private final static string APPLICATON_STATUS_NOT_PAID = 'Registered - Not paid';
    private final static string APPLICATION_STATUS_PENDING_APPROVAL = 'Registered - Pending Approval';
    private final static string APPLICATION_STATUS_TO_BE_UPDATED = 'To be updated';
    private final static string APPLICATION_STATUS_NOT_PROCESSED = 'Registered - Invoice not processed';
    private final static string APPLICATION_STATUS_REGISTERED = 'Registered - CCFund';
    private final static string APPLICATION_STATUS_WAITLISTED = 'Waitlisted';
    private final static string APPLICATION_COURSE_PREFERANCE_TEMPORARY_NAME = 'PD-ACP-TEMPNAME';
    private final static string EVIDENCE_TYPE_NOT_REQUIRED = 'NotRequired';
    private final static string EVIDENCE_TYPE_NONE = 'None';
    private final static string PAYMENT_TYPE_INVOICE = 'Invoice';
    private final static string PAYMENT_STATUS_NOT_PROCESSED = 'Not Processed';
    
    // ***************************** data structures *********************************** //
    
    /**
    * @description Data structures that are pased into Requests should impliment this interface.
    */
    public interface Request {
        // Determines whether the request is valid.
        boolean isInvalid();
    }
    /**
    * @description Data structures that are returned as a response should extend this base class.
    */
    public virtual class Response {
        // populated in the case that an error occurs whilst processing a request
        @AuraEnabled public string errorMessage {get; private set;}
        // Used to enforce any relevant data security measures
        public virtual void enforceSecurity() {
        }
    }
    /**
    * @description Data structures that may be passed in as a Request and also returned as a Response 
    * should extend this base class.
    */
    public virtual class RequestAndResponse extends Response implements Request {
        public virtual boolean isInvalid() {
            return false;
        }
    }
    public class CourseEnquiry implements Request {
        @AuraEnabled public Contact applicant {get; set;}
        @AuraEnabled public Id courseOfferingId {get; set;}
        @AuraEnabled public string heardAboutFrom {get; set;}
        public boolean isInvalid() {
            return	this.applicant == null || 
            		String.isBlank(this.courseOfferingId) ||
                	String.isBlank(this.applicant.FirstName) ||
                	String.isBlank(this.applicant.LastName) ||
                	String.isBlank(this.applicant.Email);
        }
    }
    public class CourseRegistration extends RequestAndResponse  {
        @AuraEnabled public Contact applicant {get; set;}
        @AuraEnabled public Id courseOfferingId {get; set;}
        @AuraEnabled public Id enquiryId {get; set;}
        @AuraEnabled public Id applicationId {get; set;}
        public CourseRegistration(){
            this.errorMessage = null;
        }
        public CourseRegistration(string errorMessage) {
            this.errorMessage = errorMessage;
        }
        public CourseRegistration(Contact applicant, Id courseOfferingId, Id enquiryId, Id applicationId) {
            this.applicant = applicant;
            this.courseOfferingId = courseOfferingId;
            this.enquiryId = enquiryId;
            this.applicationId = applicationId;
        }
        public override void enforceSecurity() {
            if (this.applicant == null) return;
            List<SObject> dataToEnforce = new List<SObject>{this.applicant};
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE,dataToEnforce);
			this.applicant = (Contact) securityDecision.getRecords()[0];
        }
        public override boolean isInvalid() {
             return	this.applicant == null || 
            		String.isBlank(this.courseOfferingId) ||
                 	String.isBlank(this.enquiryId) ||
                 	String.isBlank(this.applicationId);
        }
    }
    public class CoursePaymentRequest implements Request {
        @AuraEnabled public Id paymentId {get; set;}
        @AuraEnabled public PaymentOrganisation organisation {get; set;}
        @AuraEnabled public Id applicantId {get; set;}
        @AuraEnabled public Id courseOfferingId {get; set;}
        @AuraEnabled public Id courseOfferingPricingId {get; set;}
        @AuraEnabled public Id applicationId {get; set;}
        @AuraEnabled public Id enquiryId {get; set;}
        @AuraEnabled public string paymentTypeCode {get; set;}
        @AuraEnabled public string costCentre {get; set;}
        @AuraEnabled public string fund {get; set;}
        @AuraEnabled public string evidenceId {get; set;}
        @AuraEnabled public string evidenceType {get; set;}
        @AuraEnabled public string envLink {get; set;}
        @AuraEnabled public boolean isSelective {get; set;}
        public boolean hasOrganisation() {
            return this.organisation != null;
        }
        public boolean isInvalid() {
            return String.isBlank(this.applicantId) ||
                String.isBlank(this.courseOfferingId) ||
                String.isBlank(this.courseOfferingPricingId) ||
                String.isBlank(this.applicationId) ||
                String.isBlank(this.paymentTypeCode) ||
                String.isBlank(this.enquiryId) ||
                isSelective == null ||
                (this.hasOrganisation() && this.organisation.isInvalid()); 
        }
    }
    public class CoursePayment extends RequestAndResponse {
        @AuraEnabled public Id paymentId {get; set;}
        @AuraEnabled public string paymentReceiptURL {get; set;}
        @AuraEnabled public string paymentStatus {get; private set;}
        @AuraEnabled public string paymentCode {get; set;}
        @AuraEnabled public Id coursePreferenceId {get; set;}
        public CoursePayment(string errorMessage) {
            this.errorMessage = errorMessage;
        }
        // Constructor used to return information in response to Processing a Payment Request
        public CoursePayment(Id coursePreferenceId,Payment__c payment,string paymentCode) {
            this.coursePreferenceId = coursePreferenceId;
            this.paymentReceiptURL = paymentReceiptURL;
            this.paymentCode = paymentCode;
            this.populatePaymentData(payment);
        }
        // Constructor used to return information in response to a wait listed Payment Request
        public CoursePayment(Id coursePreferenceId) {
            this.coursePreferenceId = coursePreferenceId;
        }
        // Constructor used to return an existing payment record
        public CoursePayment(Payment__c payment) {
            this.populatePaymentData(payment);
        }
        // Empty constructor for use in requests.
        public CoursePayment() {
            this.errorMessage = null;
        }
        public override boolean isInvalid() {
            return	this.paymentId == null || 
            	String.isBlank(this.coursePreferenceId);
        }
        private void populatePaymentData(Payment__c payment) {
       		this.paymentReceiptURL = payment.MagentoURL__c;
            this.paymentStatus = payment.Payment_Status__c;
            this.paymentId = payment.id;
        }
    }
    public class CourseEnqiryAttachments extends RequestAndResponse { 
        @AuraEnabled public Id enquiryId {get; set;}
        @AuraEnabled public id applicantId {get ;set;}
        @AuraEnabled public List<Attachment> attachments {get; set;}
        public CourseEnqiryAttachments() {
            this.errorMessage = null;
        }
        public CourseEnqiryAttachments(string errorMessage) {
            this.errorMessage = errorMessage;
        }
        public override void enforceSecurity() {
            if (this.attachments == null || this.attachments.size() == 0) return;
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE,this.attachments);
			this.attachments = (List<Attachment>) securityDecision.getRecords();
        }
        public override boolean isInvalid() {
            return	this.attachments == null || 
    				this.attachments.size()==0 ||
                	String.isBlank(this.enquiryId) ||
            		String.isBlank(this.applicantId);
        }
    }
    public class PaymentOrganisation implements Request {
        @AuraEnabled public string abn {get; set;}
        @AuraEnabled public string contactDepartment {get; set;}
        @AuraEnabled public string contactEmail {get; set;}
        @AuraEnabled public string contactName {get; set;}
        @AuraEnabled public string contactPhone {get; set;}
        @AuraEnabled public string addressCountry {get; set;}
        @AuraEnabled public string name {get; set;}
        @AuraEnabled public string addressPostcode {get; set;}
        @AuraEnabled public string addressState {get; set;}
        @AuraEnabled public string addressStreet {get; set;}
        @AuraEnabled public string addressSuburb {get; set;}
        @AuraEnabled public string poNumber {get; set;}
        public boolean isInvalid() {
            return (String.isBlank(this.abn) && (String.valueOf(this.addressCountry).toLowerCase() == 'au' || String.valueOf(this.addressCountry).toLowerCase() == 'australia')) ||
                String.isBlank(this.contactEmail) ||
                String.isBlank(this.contactName) ||
                String.isBlank(this.contactPhone) ||
                String.isBlank(this.addressCountry) ||
                String.isBlank(this.name) ||
                String.isBlank(this.addressPostcode) ||
                String.isBlank(this.addressState) ||
                String.isBlank(this.addressStreet) ||
                String.isBlank(this.addressSuburb);
       }         
    }

    // ***************************** public methods *********************************** //
    
    /*******************************************************************************************************
    * @description Creates a Course Registration from a Course Enquiry
    * @param enquiry the Course Enquiry data poplulated with 
    * the Applicants FirstName, LastName, Email and a Course Offering Id
    * @return the Course Registration crated from the Course Enquiry
    * @example
    * CourseRegistration registration  = createCourseRegistration(enquiry);
    */
    public CourseRegistration createCourseRegistration(CourseEnquiry enquiry) {
        // validate request data object
        if (isInvalid(enquiry)) return new CourseRegistration(ERROR_INVALID_REQUEST);
        Course_Offering__c offering = getCourseOffering(enquiry.courseOfferingId);
        if (isInvalid(offering)) return new CourseRegistration(ERROR_DATA_NOT_FOUND);
        // create or update applicant info
        enquiry.applicant.id =  getExistingContactId(enquiry.applicant);
        upsertRecord(enquiry.applicant);
        // Create Enquiry
        id enquiryId = createEnquiry(enquiry.applicant,offering,enquiry.heardAboutFrom);
        // Create Application
        Id applicationId = createApplication(enquiryId, enquiry.applicant.Id);
        // Return result
        CourseRegistration reg = new CourseRegistration(enquiry.applicant, offering.Id, enquiryId, applicationId);
        return reg;
    }
    /* @description Updates an existing Course Registration with revised applicant information.
    * @param registration the Course Registration Data to update, containing
    * revised applicant data and a courseOfferingId, enquiryId and applicationId.
    * @return the updated Course Registration Data
    * @example
    * CourseRegistration registration  = updateCourseRegistration(registration);
    */
    public CourseRegistration updateCourseRegistration(CourseRegistration registration) {
        // validate request data object
        if (isInvalid(registration)) return new CourseRegistration(ERROR_INVALID_REQUEST);
        Course_Offering__c offering = getCourseOffering(registration.courseOfferingId);
        Application__c application = getApplication(registration.applicationId);
        if (isInvalid(offering,application)) return new CourseRegistration(ERROR_DATA_NOT_FOUND);
        // Update the applicant data
        updateRecord(registration.applicant);
        // return results
        return registration;
    }
    /* @description Processes a payment for a Course Registration.
    * @param paymentRequest the data required in order to process a payment
    * @return the Course Payment data
    * @example
    * CoursePayment payment  = processCoursePayment(paymentRequest);
    */
    public CoursePayment processCoursePayment(CoursePaymentRequest paymentRequest) {
        // validate request data object
        if (isInvalid(paymentRequest)) return new CoursePayment(ERROR_INVALID_REQUEST);
        Application__c application = getApplication(paymentRequest.applicationId);
        Course_Offering_Pricing__c pricing = getCourseOfferingPricing(paymentRequest.courseOfferingPricingId, paymentRequest.courseOfferingId);
        if (isInvalid(application,pricing)) return new CoursePayment(ERROR_DATA_NOT_FOUND);
        // process payment request
        CoursePayment result;
        Application_Course_Preference__c coursePreference = createApplicationCoursePreference(paymentRequest, pricing);
        Case caseRec = getCase(paymentRequest.enquiryId);
        if (coursePreference.Status__c == APPLICATION_STATUS_WAITLISTED) {
            // Wait listed - no payment
            result = new CoursePayment(coursePreference.id);
        } else {
            // Not wait listed, make payment.
            result = createPayment(application,pricing,paymentRequest,coursePreference.Id);
            // update payment link and enquiry after payment
            updatePaymentCheckURL(coursePreference, paymentRequest.envLink, result.paymentId);
            if(isConcession(paymentRequest.evidenceType))
            {
                caseRec.Status = CASE_STATUS_OPEN;
                caseRec.Description =CASE_DESCRIPTION_VALIDATE_CONCESSION;
            }
        }
        // update enquiry
        if(String.isNotBlank(paymentRequest.evidenceId)) caseRec.Discount_Evidence_ID__c = paymentRequest.evidenceId;
        reassignEnquiry(caseRec);
        return result;
    }
    /* @description Used to retrieve existing payment data made against a Course Registration.
    * @param CoursePayment the course payment to check. Must contain the 
    * paymentId and coursePreferenceId
    * @return the requested Course Payment data
    * @example
    * CoursePayment payment  = confirmCoursePayment(coursePayment);
    */   
    public CoursePayment confirmCoursePayment(CoursePayment coursePayment) {
        // validate request data object
        if (isInvalid(coursePayment)) return new CoursePayment(ERROR_INVALID_REQUEST);
        Payment__c existingPaymentRecord = getPayment(coursePayment.paymentId);
        // return data
        return new CoursePayment(existingPaymentRecord);
    }
    /* @description deletes one or more attachments associated with a Course Enquiry.
    * @param enquiryAttachments containing the applicantId , enquiryId and
    *  one or more attachments to delete (populated with an Id, ParentId and EnquiryId)
    * @return the remaining attachments for the Enquiry after the removal process
    * @example
    * CourseEnqiryAttachments remainingAttachments  = deleteAttachments(attachmentsToDelete);
    */ 
    public CourseEnqiryAttachments deleteAttachments(CourseEnqiryAttachments enquiryAttachments) {
        if (isInvalid(enquiryAttachments)) return new CourseEnqiryAttachments(ERROR_INVALID_REQUEST);
        Case enquiry = getCase(enquiryAttachments.enquiryId);
        if (isInvalid(enquiryAttachments,enquiry)) return new CourseEnqiryAttachments(ERROR_DATA_NOT_FOUND);
        deleteRecords(enquiryAttachments.attachments);
        enquiryAttachments.attachments = getAttachments(enquiryAttachments.enquiryId);
        return enquiryAttachments;
    }
    // ***************************** private data helper methods *********************************** //
    
    private Application_Course_Preference__c createApplicationCoursePreference(CoursePaymentRequest paymentRequest, Course_Offering_Pricing__c pricing) {
        map<string,PaymentCode> paymentCodeMap = constructPaymentCodeMap();
        //Determining ACP status from Payment Type/Registration Type
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Applicant__c = paymentRequest.applicantId;
        acp.Application__c = paymentRequest.applicationId;
        acp.Course_Offering__c = pricing.Course_Offering__c;
        acp.Course_Title__c = pricing.Course_Offering__r.Course__r.Course_Description__c;
        acp.Course_Code__c = pricing.Course_Offering__r.Course_Code_F__c;
        acp.Status__c = paymentRequest.isSelective ? APPLICATION_STATUS_PENDING_APPROVAL : paymentCodeMap.containsKey(paymentRequest.paymentTypeCode) ? paymentCodeMap.get(paymentRequest.paymentTypeCode).acpStatus : null;
        acp.PaymentCheckURL__c =  acp.Status__c == APPLICATION_STATUS_WAITLISTED ? APPLICATION_STATUS_PENDING_APPROVAL : APPLICATION_STATUS_TO_BE_UPDATED;
        acp.Course__c = pricing.Course_Offering__r.Course__c;
        acp.Managing_Faculty_Text__c = pricing.Course_Offering__r.Course__r.Managing_Faculty__c;
        acp.Course_Type_Text__c = pricing.Course_Offering__r.Course__r.Type__c;
        acp.COPricing__c = paymentRequest.courseOfferingPricingId;
        acp.Name = APPLICATION_COURSE_PREFERANCE_TEMPORARY_NAME;
        if (String.isNotBlank(SystemAdminUserId)) acp.OwnerId = SystemAdminUserId;
        insertRecord(acp);
        return acp;            
    } 
    private static CoursePayment createPayment(Application__c application,Course_Offering_Pricing__c pricing, CoursePaymentRequest paymentRequest, id coursePreferenceId ) {   
        map<string,PaymentCode> paymentCodeMap = constructPaymentCodeMap();
        Payment__c payment =  new Payment__c();
        payment.id = null;
        payment.Application__c = paymentRequest.applicationId;
        payment.Contact__c = application.Applicant__c;
        payment.Course_Offering__c = pricing.Course_Offering__c;
        payment.Application_Course_Preference__c = coursePreferenceId;
        if(String.isBlank(application.Applicant__c ) || String.isBlank(application.applicant__r.OtherStreet) || String.isBlank(application.applicant__r.OtherCity) || 
           String.isBlank(application.applicant__r.OtherState) || String.isBlank(application.applicant__r.OtherCountry) || String.isBlank(application.applicant__r.OtherPostalCode)) {
               payment.Street__c = application.applicant__r.MailingStreet;
               payment.Suburb__c = application.applicant__r.MailingCity;
               payment.State__c = application.applicant__r.MailingState;
               payment.Country__c = application.applicant__r.MailingCountry;
               payment.Postcode__c = application.applicant__r.MailingPostalCode;
           }else {
               payment.Street__c = application.applicant__r.OtherStreet;
               payment.Suburb__c = application.applicant__r.OtherCity;
               payment.State__c =  application.applicant__r.OtherState;
               payment.Country__c = application.applicant__r.OtherCountry;
               payment.Postcode__c = application.applicant__r.OtherPostalCode; 
           }
        if (paymentCodeMap.containsKey(paymentRequest.paymentTypeCode)) {
            paymentCode code = paymentCodeMap.get(paymentRequest.paymentTypeCode);
            payment.Payment_Type__c = code.paymentType;
            payment.Payment_Status__c = code.paymentStatus;
        }
        payment.Send_Receipt__c = false;
        payment.Quantity__c = 1;
        payment.Online_Registration__c = true;
        payment.Payment_Amount__c = pricing.fee__c;
        //PRODEV-582
        payment.Cost_Centre__c = paymentRequest.CostCentre;
        payment.Fund__c = paymentRequest.fund;
        if (String.isNotBlank(SystemAdminUserId)) {
            payment.OwnerId = SystemAdminUserId;
        }
        if (paymentRequest.hasOrganisation()) {
       		payment.Organisation_ABN__c = paymentRequest.organisation.abn;
            payment.Organisation_Contact_Department__c = paymentRequest.organisation.contactDepartment;
            payment.Organisation_Contact_Email__c = paymentRequest.organisation.contactEmail;
            payment.Organisation_Contact_Full_Name__c = paymentRequest.organisation.contactName;
            payment.Organisation_Contact_Phone__c = paymentRequest.organisation.contactPhone;
            payment.Organisation_Country__c = paymentRequest.organisation.addressCountry;
            payment.Organisation_Name__c = paymentRequest.organisation.name;
            payment.Organisation_Postcode__c = paymentRequest.organisation.addressPostcode;
            payment.Organisation_State__c = paymentRequest.organisation.addressState;
            payment.Organisation_Street_Address__c = paymentRequest.organisation.addressStreet;
            payment.Organisation_Suburb__c = paymentRequest.organisation.addressSuburb;
            payment.Payment_Document_Cheque_MO_PO_Number__c = paymentRequest.organisation.poNumber;
        }
        insertRecord(payment);
        // Encrypt Id using HMAC key
        Magento_Settings__c magentoSettings = Magento_Settings__c.getValues(PaymentServices.MAGENTO_SETTINGS_DATASET_NAME);
        String magentoURL = magentoSettings == null ? '' : magentoSettings.MagentoURL__c;
        String hmac_Key = magentoSettings == null ? '' : magentoSettings.MagentoHMACKey__c;
        Blob dataCode = Crypto.generateMac('HmacSHA256', Blob.valueOf(payment.Id), Blob.valueOf(hmac_Key));
        String encryptedParam = EncodingUtil.base64Encode(dataCode);
        // Build URL
        String paymentReceiptURL = magentoURL+payment.Id+'&code='+EncodingUtil.urlEncode(encryptedParam, 'UTF-8');
        // Insert then update? there has to be a better way! 
        Payment__c payRec = getPayment(payment.Id);
        payRec.MagentoURL__c = paymentReceiptURL;
        updateRecord(payRec);
        //String encodedURL = EncodingUtil.urlEncode(strURL, 'UTF-8');
        return new CoursePayment(coursePreferenceId, payRec, paymentRequest.paymentTypeCode);
    }
    private static Id createEnquiry(Contact applicant, Course_Offering__c offering, String heardAboutFrom) {
        triggerCommon.disableTrigger(SOBJECT_APINAME_CASE);                
        Map<string,string> facultyManagementMap  = consructFacultyManagementMap();
        Case enquiry = new Case();
        enquiry.ContactId = applicant.Id;
        enquiry.Subject = ONLINE_COURSE_REGISTRATION;
        enquiry.Description = ONLINE_COURSE_REGISTRATION;
        enquiry.Heard_About_From__c = heardAboutFrom;
        enquiry.Origin = ORIGIN_WEB;
        enquiry.Course__c = offering.Course__c;
        enquiry.Student_Type__c = getStudentType(formatCountry(applicant.MailingCountry));
        enquiry.Enquiry_Type__c = ENQUIRY_TYPE_FUTURE_COURSE;
        enquiry.Status = STATUS_SOLVED;
        enquiry.RecordTypeId = getRecordTypes(SOBJECT_APINAME_CASE).get(RECORD_TYPE_NAME_PROFESSIONAL_DEVELOPMENT).Id;
        enquiry.Managing_Faculty__c = facultyManagementMap.containsKey(offering.Course__r.Managing_Faculty__c) ? facultyManagementMap.get(offering.Course__r.Managing_Faculty__c) : null;
        // depreciated method
        if (String.isNotBlank(SystemAdminUserId)) {
            enquiry.OwnerId = SystemAdminUserId;
        }
        insertRecord(enquiry);
        return enquiry.Id;
    }
    private static Id createApplication(Id enquiryId, Id applicantId) {
        triggerCommon.disableTrigger(SOBJECT_APINAME_APPLICATION);
        Application__c application = new Application__c();
        application.Status__c = APPLICATON_STATUS_NOT_PAID;
        application.Enquiry_Number__c = enquiryId;
        application.Applicant__c = applicantId;
        if (String.isNotBlank(SystemAdminUserId)) {
            application.OwnerId = SystemAdminUserId;
        }
        insertRecord(application);
        return application.Id;
    }
  	// ***************************** DML Operations *********************************** //
 	// public methods //
    public static Id createAttachment(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Attachment oAttachment = new Attachment();
        oAttachment.parentId = parentId;
        oAttachment.Body = EncodingUtil.base64Decode(base64Data);
        oAttachment.Name = fileName;
        oAttachment.ContentType = contentType;
        if (String.isNotBlank(SystemAdminUserId)) {
            oAttachment.OwnerId = SystemAdminUserId;
        }
        insert oAttachment;
        return oAttachment.Id;
    } 
    public static List<Attachment> getAttachments(Id parentId) {
        return [SELECT Id, Name, ContentType, ParentId, Description 
                FROM Attachment 
                WHERE ParentId = :parentId];
    }
    public static String retrieveMagentoURL(Id paymentId){
        Payment__c paymntRec = getPayment(paymentId);
        if(paymntRec != null){
            return paymntRec.MagentoURL__c;
        }
        return null;
    }
    // private methods //
    //To enforece case assignment rules to run when creating case programatically
    private void reassignEnquiry(Case caseToReassign) {          
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.AssignmentRuleHeader.useDefaultRule = true;
        caseToReassign.setOptions(dml);
        upsert caseToReassign;
    }
    private void updatePaymentCheckURL(Application_Course_Preference__c acpRet, String envLink, String payListStr){
        try{
            acpRet.PaymentCheckURL__c = 'https://'+envLink+'/CourseRegistration/PaymentHandleVF?booking_id='+payListStr;
            update acpRet;
        } catch(Exception e) {                
            System.debug('***** EXCEPTION FROM savePricingInfoForRegister-PaymentCheckURL__c *****'+e.getMessage()+'**Line Number**'+e.getLineNumber());
        } 
    }
    private static Payment__c getPayment(String paymentId) {
        List<Payment__c> payments = [
            SELECT Id, MagentoURL__c,Application_Course_Preference__c,Payment_Status__c
            FROM Payment__c 
            WHERE id=:paymentId];
        return payments.size() == 1 ? payments[0] : null;
    }
    private static Case getCase(Id CaseId) {
        List<Case> cases = [
            SELECT Status,Description,Discount_Evidence_ID__c, ContactId 
            FROM Case 
            WHERE id=:CaseId];
        return cases.size() == 1 ? cases[0] : null;
    }
    private static Application_Course_Preference__c getApplicationCoursePreference(Id coursePreferenceId) {
        List<Application_Course_Preference__c> coursePreferences = [
            SELECT Id, Status__c 
            FROM Application_Course_Preference__c 
            WHERE Id =:coursePreferenceId
        	LIMIT 1];
        return coursePreferences.size() == 1 ? coursePreferences[0] : null;
    }
    private static Course_Offering_Pricing__c getCourseOfferingPricing(Id courseOfferingPricingId, Id courseOfferingId) {
        List<Course_Offering_Pricing__c> pricingList = [
            SELECT Id,Fee__c,Course_Offering__c,
            Course_Offering__r.Course__c, Course_Offering__r.Course__r.Managing_Faculty__c, Course_Offering__r.Course__r.Course_Description__c,
            Course_Offering__r.Course_Code_F__c, Course_Offering__r.Course__r.Course_Type__c, Course_Offering__r.Course__r.Type__c
            FROM Course_Offering_Pricing__c
            WHERE Id = :courseOfferingPricingId 
            AND Course_Offering__c = :courseOfferingId
            LIMIT 1];
        return pricingList.size() == 1 ? pricingList[0] : null;
    }    
    private static Course_Offering__c getCourseOffering(Id courseOfferingId) {
        List<Course_Offering__c> offerings = [
            SELECT Id,Course__c, Course__r.Managing_Faculty__c, Course__r.Course_Description__c,Course_Code_F__c, Course__r.Course_Type__c
            FROM Course_Offering__c
            WHERE Id = :courseOfferingId
            LIMIT 1];
        return offerings.size() == 1 ? offerings[0] : null;
    }
    private static Application__c getApplication(Id applicationId) {
        List<Application__c> applications = [
               SELECT Id, Enquiry_Number__c,Enquiry_Number__r.Course__c,Applicant__c,
            		applicant__r.OtherStreet, applicant__r.OtherCity,applicant__r.OtherState,applicant__r.OtherCountry,applicant__r.OtherPostalCode,
        			applicant__r.MailingStreet,applicant__r.MailingCity,applicant__r.MailingState,applicant__r.MailingCountry,applicant__r.MailingPostalCode
               FROM Application__c
               WHERE Id = :applicationId
               LIMIT 1];
        return applications.size() == 1 ? applications[0] : null;
    }
    private static Id getExistingContactId(Contact contact) {
        system.debug('contact.id' +contact.id);
        if (String.isNotBlank(contact.id)) return contact.id;
        List<Contact> contacts = [SELECT Id 
                                  FROM Contact 
                                  WHERE FirstName = :contact.FirstName 
                                  AND LastName = :contact.LastName 
                                  AND Email = :contact.Email
                                  LIMIT 1];
        return contacts.size() == 1 ? contacts[0].Id : null;
    }
    private static Contact getContact(Id contactId) {
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Preferred_Name__c, Company__c, Title, Email, HomePhone, Phone, MobilePhone, MailingStreet, MailingCity, MailingState,MailingCountry, MailingPostalCode, OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry 
            FROM Contact 
            WHERE Id =:contactId];
        return contacts.size() == 1 ? contacts[0] : null;
    }
    private static void updateRecord(Sobject record) {
        try{
            update record;
        } catch(Exception ex) {                
            System.debug('***** EXCEPTION FROM upsertRecord*****'+ex.getMessage()+'**Line Number**'+ex.getLineNumber());
        }
    }
    private static void upsertRecord(Sobject record) {
        try{
            upsert record;
        } catch(Exception ex) {                
            System.debug('***** EXCEPTION FROM upsertRecord*****'+ex.getMessage()+'**Line Number**'+ex.getLineNumber());
        }
    }
    private static void insertRecord(Sobject record) {
        try{
            insert record;
        } catch(Exception ex) {                
            System.debug('***** EXCEPTION FROM insertRecord*****'+ex.getMessage()+'**Line Number**'+ex.getLineNumber());
        }
    }
    private static void deleteRecords(List<Sobject> records) {
        try{
            delete records;
        } catch(Exception ex) {                
            System.debug('***** EXCEPTION FROM insertRecord*****'+ex.getMessage()+'**Line Number**'+ex.getLineNumber());
        }
    }
    // ***************************** BUSINESS LOGIC OPERATIONS *********************************** //
    private static boolean isInvalid(Request request) {
        return request == null || request.isInvalid();
    }
    private static boolean isInvalid(Course_Offering__c offering) {
            return offering == null;
    }
    private static boolean isInvalid(Course_Offering_Pricing__c coursePricing) {
        return coursePricing == null;
    }
    private static boolean isInvalid(Contact applicant) {
        return applicant == null;
    }
    private static boolean isInvalid(Application__c application) {
        return application == null;
    }
    private static boolean isInvalid(Application_Course_Preference__c coursePreference) {
        return coursePreference == null;
    }
    private static boolean isInvalid(Payment__c payment) {
        return payment == null;
    } 
    private static boolean isInvalid(Case enquiry) {
        return enquiry == null ||
               enquiry.contactId == null;
    }
    private static boolean isInvalid(Course_Offering__c offering, Application__c application) {
        return 	isInvalid(offering) ||
            	isInvalid(application) ||
            	application.Enquiry_Number__r.Course__c != offering.Course__c;
    }
    private static boolean isInvalid(Application__c application, Course_Offering_Pricing__c pricing) {
        return  isInvalid(application) ||
                isInvalid(pricing) ||
            	application.Enquiry_Number__r.Course__c != pricing.Course_Offering__r.Course__c;
    }
    private static boolean isInvalid(CourseEnqiryAttachments enquiryAttachments,Case enquiry) {
        return 	isInvalid(enquiry) ||
            	isInvalid(enquiryAttachments.attachments,enquiryAttachments.enquiryId) ||
            	enquiry.ContactId != enquiryAttachments.applicantId;
    }
    private static boolean isInvalid(List<Attachment> attachments, Id enquiryId) {
        if (attachments == null || attachments.size()== 0) return false;
        for (Attachment nextAttachment : attachments)
            if (nextAttachment.parentId != enquiryId) return true;
        return false;
    } 
    private static boolean isConcession(string evidenceType) {
        return evidenceType != EVIDENCE_TYPE_NOT_REQUIRED  && evidenceType != EVIDENCE_TYPE_NONE; 
    }
    // ***************************** Utilities *********************************** //
    // A Property to retrieve the System Admin User Id
    private static String SystemAdminUserId {
        get {
            return Environment_Settings__c.getOrgDefaults().System_Admin_User_Id__c;
        }
    }
    //Retrieve all record types of any object
    private static Map<String,RecordType> getRecordTypes(String obj) {
        System.debug('inside-getRecordTypes');
        
        //Query for the record types of an object
        List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType= :obj and isActive=true];
        
        //Create a map between the RecordType Name and RecordType
        Map<String,RecordType> recordTypes = new Map<String,RecordType>{};
            for(RecordType rt: rtypes)
            recordTypes.put(rt.Name,rt);
        return recordTypes;
    }  
    private static Map<string,string> consructFacultyManagementMap() {
        return new Map<string,string> {
            'Faculty of Education' => 'Education',
            'Faculty of Medicine, Nursing & Health Sciences' => 'Medicine, Nursing and Health Sciences',
            'Faculty of Business & Economics' =>'Business and Economics',
            'Faculty of Arts' => 'Arts',
            'Monash Sustainable Development Institute' => 'Monash Sustainable Development Institute', 
            'Monash Centre for Professional Development' => 'Monash Centre for Professional Development' 
        };
    }

    private static string getStudentType (string country) {
        return  country == COUNTRY_AUSTRALIA ? STUDENT_TYPE_DOMESTIC :  STUDENT_TYPE_INTERNATIONAL;  
    }
    private static string formatCountry(string country) {
        switch on country.toLowerCase() {
            when 'au','australia' {
                return COUNTRY_AUSTRALIA;
            }
            when else {
                return null;
            }
        }
    }
    private static Map<string,PaymentCode> constructPaymentCodeMap() {
        return new Map<string,PaymentCode> {
            'register' => new PaymentCode('Credit_Card','Initiated', APPLICATON_STATUS_NOT_PAID),
            'register-invoice' => new PaymentCode('Invoice','Not Processed', APPLICATION_STATUS_NOT_PROCESSED),
            'register-ccfund' => new PaymentCode('Cost_Centre_Fund','Not Processed',APPLICATION_STATUS_REGISTERED),
            'waitlist' => new PaymentCode('','',APPLICATION_STATUS_WAITLISTED)
            };
    }
    public class PaymentCode {
        public string paymentType  {get;set;}
        public string paymentStatus {get; set;}
        public string acpStatus {get; set;}
        public PaymentCode(string paymentType, string paymentStatus, string acpStatus) {
            this.paymentType = paymentType;
            this.paymentStatus = paymentStatus;
            this.acpStatus = acpStatus;
        }
    }
}