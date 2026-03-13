/**
 * @Class              : AgentPortalPayload.cls
 * @description        : Wrapper class for all Agent Portal V2 Payloads 
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 2023-02-14     Vinothraja   Created 
 * @Modification log
 * Date         Author                  Modification
 * 2024-05-07   Kai-Fan Hsieh           SFTG-3814/EPCP-3430 Updated code to populate agent contact's firstname and lastname OOTB fields
 * 2023-03-21   BGreenalnd   SFTG-3704 Added  ContactQualification.Verification_Status__c
 */
 

 global class AgentPortalPayload {
    // BASE CLASSES -- START
    /**
     * @description AgentPortalRequest wrapper  
     */
    global abstract class AgentPortalRequest {
        private String pageSize;
        private String pageOffset;
        /**
         * @description Running user  
         */
        public User runningUser {
            get {
                if(runningUser == null) {
                    runningUser = AgentPortalServices.getUser(UserInfo.getUserId());
                }
                return runningUser;
            }
            private set;
        }

        /**
         * @description search limit 
         */
        global Integer searchLimit {
            get {
                if (String.isBlank(this.pageSize)) { return AgentPortalConstants.DEFAULT_SEARCH_LIMIT; }
                return Integer.valueOf(this.pageSize);
            } set;
        }
        /**
         * @description search offset 
         */
        global Integer searchOffset {
            get {
                if (String.isBlank(this.pageOffset)) { return AgentPortalConstants.DEFAULT_SEARCH_OFFSET; }
                return Integer.valueOf(this.pageOffset);
            } set;
        }
        /**
         * @description valiation response
         */
        global Boolean isValid {
            get {
                try{
                    return this.validate();
                } catch(Exception e) {
                    throw e;
                }
            }
            set;
        }
        /**
         * @description call validate
         * @return Bool
         */
        global abstract Boolean validate();
    }

    /**
     * @description AgentPortalResponse wrapper
     */
    global abstract class AgentPortalResponse {
        @TestVisible
        private Object response;
        @TestVisible
        private String responseType = AgentPortalConstants.RESP_TYPE_GET;
        @TestVisible
        private String responseMessage;
        @TestVisible
        public String successMessage = AgentPortalConstants.SUCCESS_MESSAGE;
        @TestVisible
        public String description;
        @TestVisible
        public Boolean success;

        @TestVisible
        private Exception ex;

        global Integer noOfRecords = 0;
        global Integer pageSize = AgentPortalConstants.DEFAULT_SEARCH_LIMIT;
        global Integer pageOffset = AgentPortalConstants.DEFAULT_SEARCH_OFFSET;

        /**
         * @description status string
         */
        global String status {
            get {
                if (this.ex != null) {
                    return AgentPortalConstants.ERROR;
                }
                return AgentPortalConstants.SUCCESS;
            }
            set;
        }
        /**
         * @description error message
         */
        global String message {
            get {
                if (this.ex != null) {
                    return AgentPortalConstants.ERROR_MSG_PREFIX + this.ex.getMessage();
                }
                return this.successMessage;
            }
            set;
        }
        /**
         * @description exception
         */
        global Exception exceptionRecord {
            set {
                this.ex = value;
            }
        }
        /**
         * @description create JSON string
         * @return String
         */
        global virtual String toJSONString() {
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject(); 
            gen.writeStringField(AgentPortalConstants.STATUS, this.status);    
            gen.writeStringField(AgentPortalConstants.MESSAGE, this.message);
            
            if(this.description!=null){
                gen.writeStringField(AgentPortalConstants.DESCRIPTION, this.description);
            }

            if(this.success!=null){
                gen.writeBooleanField(AgentPortalConstants.SUCCESS_FLAG, this.success);
            }

            if (this.ex == null && this.responseMessage != null && this.response != null) {
                gen.writeObjectField(this.responseMessage, this.response);
            } 
            // SEARCH requests will need count and pagination details as part of the response, apart from the actual records
            if (this.responseType == AgentPortalConstants.RESP_TYPE_SEARCH) {
                gen.writeNumberField('recordsFound', this.noOfRecords);
                gen.writeNumberField('pageSize', this.pageSize);
                gen.writeNumberField('pageOffset', this.pageOffset);
            }
            gen.writeEndObject();   
            return gen.getAsString();   
        }
        /**
         * @description get blob
         * @return blob
         */
        global Blob responseBody {
            get {
                return Blob.valueOf(this.toJSONString());
            }
            set;
        }
    }
    // BASE CLASSES -- END

    // APPLICANT MANAGEMENT RELATED PAYLOADS -- START
    /**
     * @description CreateApplicantRequest validations
     */
    global class CreateApplicantRequest extends AgentPortalRequest{
        global CDM_Applicant applicant;
        global override Boolean validate() {
            List<String> exceptions = new List<String> ();
            if (String.isBlank(applicant.lastName)) {
                exceptions.add('Applicant\'s Last Name cannot be empty');
            }
            if (applicant.email == null || applicant.email.isEmpty()) {
                exceptions.add('Applicant\'s email cannot be empty');
            }
            if (String.isBlank(applicant.dateOfBirth)) {
                exceptions.add('Applicant\'s Date of Birth cannot be empty');
            } else {
                try {
                    Date d = Date.valueOf(applicant.dateOfBirth);
                    if (d.daysBetween(date.today()) / 365 < AgentPortalConstants.MINIMUM_AGE_FOR_APPLYING) {
                        exceptions.add('Applicant should be minimum 10 yrs old');
                    }
                } catch(Exception e) {
                    exceptions.add('Applicant\'s Date of Birth is of invalid format. Only yyyy-MM-dd format is accepted');
                }
            }
            if(!exceptions.isEmpty()) {
                throw new ApplicantException(String.join(exceptions, ', '));
            }
            return true;
        }
        /**
         * @description contact object
         * @return Contact
         */
        global Contact asContact() {
            Contact con = new Contact();
            con.First_name__c = applicant.firstName;
            con.Last_name__c = applicant.lastName;
            con.Firstname = applicant.firstName;
            con.Lastname = applicant.lastName;
            con.Birthdate = Date.valueOf(applicant.dateOfBirth);
            con.Previous_Surname__c = applicant.previousName;
            con.Previous_Monash_ID__c = applicant.previousMonashId;
            con.Previously_Studied_at_Monash__c = applicant.isPreviousMonashStudent;
            con.MobilePhone = AgentPortalServices.getPhoneNumber(applicant.phone, 'Mobile');
            con.Personal_Email__c = AgentPortalServices.getEmail(applicant.email, 'Personal');
            return con;
        }
    }

    /**
     * @description get respnse wrapper
     */
    global class CreateApplicantResponse extends AgentPortalResponse {
        /**
         * @description create response
         */
        global CreateApplicantResponse() {
            // iniitialise response variables
            this.responseMessage = 'applicant';
            this.responseType = AgentPortalConstants.RESP_TYPE_CREATE;
            this.successMessage = 'Applicant created successfully!';
        }
        /**
        * @description get contact record
        */
        global Contact contactRecord {
            set {
                this.response = value;
            }
        }
    }
    /**
    * @description This class handles the request for getting applicant details.
    */
    global class GetApplicantDetailsRequest extends AgentPortalRequest {
        global String crmContactId; //CRM_ID__c
        global String applicantName; 
        /**
        * @description Constructor to initialize the request with parameters.
        * @param params A map containing request parameters.
        */
        global GetApplicantDetailsRequest(Map <String, String> params) {
            if (params != null && !params.isEmpty()) {
                crmContactId = params.get('crmContactId');
                this.pageOffset = params.get('pageOffset');
                this.pageSize = params.get('pageSize');
                applicantName = params.get('applicantName');
            }
        }
        /**
        * @description Validates the request parameters.
        * @return Boolean indicating whether the validation was successful.
        */
            global override Boolean validate() {
            if (this.crmContactId == null && applicantName == null)   {
                throw new BadRequestException('Query Params not set');
            } 
            return true;
        }
    }
    /**
    * @description This class handles the response for getting applicant details.
    */
    global class GetApplicantDetailsResponse extends AgentPortalResponse {
        /**
        * @description Constructor to initialize the response.
        */
        global GetApplicantDetailsResponse() {
            this.responseType = AgentPortalConstants.RESP_TYPE_GET;
            this.responseMessage = 'contact'; 
            this.successMessage = 'Applicant found!';
        }
        /**
        * @description Sets the applicant details in the response.
        * @param value The applicant details to be set.
        */
        global ApplicantDetails applicant {
            set {
                if (value != null) {
                    this.response = value;
                    this.noOfRecords = 1;
                } else {
                    this.response = new Contact();                    
                    this.successMessage = 'No Applicant(s) found matching the criteria';
                }
            }
        }
        /**
        * @description Sets the list of applicants in the response.
        * @param value The list of applicants to be set.
        */
        global List<Contact> applicants {
            set {
                this.responseType = AgentPortalConstants.RESP_TYPE_SEARCH;
                this.successMessage = 'Applicant(s) found!';
                if (value != null) {
                    this.noOfRecords = value.size();
                    List<Contact> pagedApplicants = new List<Contact> ();
                    Integer start = this.pageOffset;
                    Integer finish = (start + this.pageSize) > this.noOfRecords ? this.noOfRecords : (start + this.pageSize);
                    for (Integer i = start; i < finish; i++) {
                        pagedApplicants.add(value.get(i));
                    }

                    this.response = pagedApplicants;
                } else {
                    this.response = new List<Contact> ();
                    this.successMessage = 'No Applicant(s) found matching the criteria';
                }
            }
        }
    }
/**
* @description This class handles the update request for an applicant.
*/
    global class UpdateApplicantRequest extends AgentPortalRequest {
        global Contact contactRecord;
        private CDM_Applicant applicant;
        /**
        * @description Constructor that initializes the UpdateApplicantRequest with the request body.
        * @param reqBody The request body in JSON format.
        */
        global UpdateApplicantRequest(String reqBody) {
            if (String.isNotBlank(reqBody)) {
                applicant = (CDM_Applicant) JSON.deserialize(reqBody, CDM_Applicant.class);
                contactRecord = applicant.asContact;
            }
        }
        // global String orgId;
        /**
        * @description Validates the update request for the applicant.
        * @return Boolean indicating whether the request is valid.
        * @throws ApplicantException if the request is invalid.
        */
        global override Boolean validate() {
            List<String> exceptions = new List<String> ();
            if (contactRecord.Id == null) {
                throw new ApplicantException('Request without a valid Id');
            } else {
                List<Application__c> allApplicationsForContact = AgentPortalServices.getSubmittedApplicationsForApplicant(contactRecord.Id, new Set<Id> ());
                if (!allApplicationsForContact.isEmpty() && applicant.disallowedFieldUpdated) {
                    throw new ApplicantException('Applicant has submitted Applications. Request contains fields which cannot be updated');
                }
            }
            if (contactRecord.last_Name__c != null && String.isEmpty(contactRecord.last_Name__c)) {
                exceptions.add('Applicant\'s Last Name cannot be empty');
            }
            if (contactRecord.personal_email__c != null && String.isEmpty(contactRecord.personal_email__c)) {
                exceptions.add('Applicant\'s email cannot be empty');
            }
            if (String.isNotBlank(contactRecord.Gender__c) && AgentPortalConstants.CON_UNUSED_GENDERS.contains(contactRecord.Gender__c)) {
                exceptions.add('Applicant\'s Gender cannot be P or U');
            }
            if (contactRecord.BirthDate != null) {
                if (contactRecord.BirthDate.daysBetween(date.today()) / 365 < AgentPortalConstants.MINIMUM_AGE_FOR_APPLYING) {
                    exceptions.add('Applicant should be minimum 10 yrs old');
                }
            }
            if(!exceptions.isEmpty()) {
                throw new ApplicantException(String.join(exceptions, ', '));
            }
            return true;
        }
        /** 
        * @description Converts the applicant to a Contact record.
        * @return Contact record of the applicant.
        */
        global Contact asContact() {
            return contactRecord;
        }
    }

    /** 
    * @description This class handles the response for updating an applicant in the Agent Portal.
    */
    global class UpdateApplicantResponse extends AgentPortalResponse {
        
        /** 
        * @description Constructor for UpdateApplicantResponse. Initializes response message, type, and success message.
        */
        global UpdateApplicantResponse() {
            this.responseMessage = 'contact';
            this.responseType = AgentPortalConstants.RESP_TYPE_UPDATE;
            this.successMessage = 'Applicant updated successfully!';
        }

        /** 
        * @description Sets the contact record for the response.
        * @param value The contact record to be set.
        * @return void
        */
        global Contact contactRecord {
            set {
                this.response = value;
            }
        }
    }
    // APPLICANT MANAGEMENT RELATED PAYLOADS -- END

    // APPLICATION MANAGEMENT RELATED PAYLOADS -- START
    /**
    * @description This class handles the creation of application requests in the Agent Portal.
    */
    global class CreateApplicationRequest extends AgentPortalRequest{
		global String contactId;
        global String campusLocation;
        global String residencyStatus;
        global String agentNotes;
        global String delegatorOrgUnitCode;
        global List<Email> email;
        global List<Phone> phone;
        global String externalReferenceId;
        /**
        * @description Retrieves the applicant's email from the list of emails.
        * @return The applicant's personal email.
        */
        global String applicantEmail {
            get { return AgentPortalServices.getEmail(email, 'Personal'); }
        }
        /**
        * @description Retrieves the applicant's phone number from the list of phones.
        * @return The applicant's mobile phone number.
        */
        global String applicantPhone {
            get { return AgentPortalServices.getPhoneNumber(phone, 'Mobile'); }
        }
        /**
        * @description Validates the application request.
        * @return True if the request is valid, otherwise throws an ApplicationException.
        */
        global override Boolean validate() {
            List<String> exceptions = new List<String> ();
            if (String.isBlank(this.contactId)) {
                exceptions.add('Applicant\'s ID cannot be empty');
            } else {
                this.contactId = AgentPortalServices.getContact(this.contactId, AgentPortalConstants.APPLICANT_PERSONA, AgentPortalConstants.SYSTEM_CONTEXT)?.Id;
                if (this.contactId == null) {
                    exceptions.add('Invalid Applicant ID or Applicant doesn\'t exist!');
                }
            }
            if (String.isBlank(campusLocation)) {
                exceptions.add('Campus Location cannot be empty');
            } else if (!runningUser.contact.Account.Campus__c.containsIgnoreCase(campusLocation)) {
                throw new ApplicationException('Your agency is not allowed to apply for this Campus location');
            } else if (AgentPortalServices.doOtherDraftsExistForSameCampus(this.contactId, this.campusLocation, new Set<String> {runningUser.contact.Account.Callista_Org_Unit_Code__c})) {
                throw new ApplicationException('Applicant cannot have more than one draft application for this campus.');
            }
            if (String.isBlank(residencyStatus)) {
                exceptions.add('Residency Status cannot be empty');
            }
            if (email == null || String.isBlank(applicantEmail)) {
                exceptions.add('Applicant email cannot be empty');
            }
            if (phone == null || String.isBlank(applicantPhone)) {
                exceptions.add('Applicant mobilePhone cannot be empty');
            }
            if(!exceptions.isEmpty()) {
                throw new ApplicationException(String.join(exceptions, ', '));
            } 
            return true;
        }
        /**
        * @description Converts the application request to an Application__c object.
        * @return The Application__c object representing the application request.
        */
        global Application__c asApplication() {
            Application__c app = new Application__c();
        

            app.Agent__c = runningUser?.Contact.AccountId;
            app.Agent_Org_Unit_Code__c = runningUser?.contact.Account.Callista_Org_Unit_Code__c;
            app.Applicant__c = this.contactId;
            app.status__c = AgentPortalConstants.APP_CREATE_STATUS;
            //Populate Source_System__c based on the calling client
            app.Source_System__c = ApplicationService.getSourceSystem();
            app.Campus_Location__c = this.campusLocation;
            app.Type_of_Study__c = AgentPortalConstants.APP_CREATE_TYPE;
            // Handle Residency sub-statuses if any. ex. I am a Malaysian Citizen or a Malaysian Permanent Resident (i.e. I hold a Malaysian PR visa) 
            //  I am a Malaysian Citizen (DOM-SUN.A) will be saved as Residency_Status__c = DOM-SUN and Residency_Sub_status__c = DOM-SUN.A   
            if (this.residencyStatus.contains('.')) {
                app.Residency_Sub_status__c = this.residencyStatus; // DOM-SUN.A
            } 
            app.Residency_Status__c = this.residencyStatus.split('\\.')[0]; // DOM-SUN   
            app.Agent_Notes__c = this.agentNotes;
            app.Delegator_Org_Unit_Code__c = this.delegatorOrgUnitCode;
            app.External_Reference_Id__c = this.externalReferenceId;
            return app;
        }
    }
    /** 
     * @description        CreateApplicationResponse
     */
    global class CreateApplicationResponse extends AgentPortalResponse {
    /** 
     * @description        CreateApplicationResponse
     */
        global CreateApplicationResponse() {
            this.responseMessage = 'application';
            this.responseType = AgentPortalConstants.RESP_TYPE_CREATE;
            this.successMessage = 'Application created successfully!';
        }
        /** 
         * @description  get application recored
         */
        global Object applicationRecord {
            set {
                this.response = value;
            }
        }
    }
    /** 
     * @description This class handles the request for getting application details.
     */
    global class GetApplicationDetailsRequest extends AgentPortalRequest {
        global String applicationId;
        global String requestType;
    /** 
     * @description Constructor to initialize the request with parameters.
     * @param params A map containing the request parameters.
     */
        global GetApplicationDetailsRequest(Map<String, String> params) { 
            if (params != null && !params.isEmpty()) {
                this.applicationId = params.get('applicationId');
                this.requestType = params.containsKey('related') ? params.get('related') : '';
            } 
        }
        /**
        * @description 
        * @return Boolean 
        **/
        global override Boolean validate() {
            if (String.isBlank(this.applicationId)) {
                throw new ApplicationException('Application Id cannot be empty');
            }
            if (!String.isBlank(this.requestType) && !(this.requestType.equalsIgnoreCase('qualifications') || this.requestType.equalsIgnoreCase('experiences'))) {
                throw new AgentPortalPayload.BadRequestException('Request Type: '+ this.requestType + ' is not recognised');
            }
            return true;
        }
    }
/**
* @description This class handles the response for getting application details.
*/
    global class GetApplicationDetailsResponse extends AgentPortalResponse {

        /** 
        * @description Constructor to initialize the response message and type.
        */
        global GetApplicationDetailsResponse() {
            this.responseMessage = 'application';
            this.responseType = AgentPortalConstants.RESP_TYPE_GET;
        }
        /**
        * @description 
        * @param value != 
        * @return ApplicationDetails 
        **/
        global ApplicationDetails details {
            set {
                if (value != null) {
                    this.response = value;
                    this.noOfRecords = 1;
                    this.successMessage = 'Application(s) found!';
                } else {
                    this.response = new ApplicationDetails();
                    this.successMessage = 'No Application(s) found matching the criteria';
                }
            }
        }
        /**
        * @description 
        * @param value 
        * @return Qualifications 
        **/
        global Qualifications qualifications {
            set {
                if (value != null) {
                    this.response = value;
                    this.noOfRecords = value.recordCount;
                    this.successMessage = 'Qualification(s) found!';
                } else {
                    this.response = new Qualifications();
                    this.noOfRecords = 0;
                    this.successMessage = 'No Qualification(s) found matching the criteria';
                }
            }
        }
        /**
        * @description 
        * @param value
        * @return WorkExperiences 
        **/
        global WorkExperiences workExperiences {
            set {
                if (value != null) {
                    this.response = value;
                    this.noOfRecords = value.recordCount;
                    this.successMessage = 'Work Experience(s) found!';
                } else {
                    this.response = new WorkExperiences();
                    this.noOfRecords = 0;
                    this.successMessage = 'No Work Experience(s) found matching the criteria';
                }
            }
        }
    }
    /**
    * @description UpdateApplicationRequest wrapper
    */
    global class UpdateApplicationRequest extends AgentPortalRequest {
        global CDM_Application application;
        @TestVisible
        private Application__c applicationDetails;
        @TestVisible
        private List<Application_Course_Preference__c> applicationCoursePreferences;
        @TestVisible
        private List<Contact_Qualification__c> applicationQualifications;
        @TestVisible
        private List<Work_Experience__c> applicationWorkExperiences;
        private List<String> errorMessages;
        private Boolean postSubmitPaymentUpdate;

        @TestVisible
        private Map<String, Application_Course_Preference__c> acpByExternalId;

        /**
        * @description 
        * @author Ben Greenland | 2024-09-11 
        **/
        global void init() {

            // Init Values
            errorMessages = new List<String> ();
            postSubmitPaymentUpdate = false;
            applicationDetails = application.asApplicationRecord();

            /**
             * for OES, if the Application is already in a submitted state, it implies that
             * This is a subsequent update call post-transfer job in order to recover the
             * previous ACP statuses that may have been overwritten.
             * 
             * In this case, we simply return the current state of the Application and only
             * allow updates on ACP
             */
            if(OESApplicationService.isOESUser && applicationDetails.Status__c == 'Submitted') {
                Set<String> acpExtIds = new Set<String>();
                this.acpByExternalId = new Map<String, Application_Course_Preference__c>();

                for (CDM_ApplicationCoursePreference icdm : application.coursePreferences) {
                    // collect external IDs
                    if(String.isNotBlank(icdm.externalId)) {
                        acpExtIds.add(icdm.externalId);
                    } else {
                        throw new ApplicationException('Invalid null external ID for Applicant Course Preference');
                    }
                }
                // query IDs of ACPs so we can run an update in the process() method
                for(Application_Course_Preference__c iAcp : [SELECT Id, ACP_ID__c
                                                            FROM Application_Course_Preference__c
                                                            WHERE ACP_ID__c IN :acpExtIds])
                {
                    this.acpByExternalId.put(iAcp.ACP_ID__c, iAcp);
                }
                
            } else {
            applicationDetails.Agent__c = runningUser?.Contact.AccountId;

            if (AffiliationCheckService.SUBMITTED_STATUSES.contains(applicationDetails.Status__c)) {
                postSubmitPaymentUpdate = true;
            }

                if(String.isNotBlank(application.errorMessage.trim())) {
                    errorMessages.add(application.errorMessage);
                }

            if (application.coursePreferences != null && !postSubmitPaymentUpdate) {
                applicationCoursePreferences = new List<Application_Course_Preference__c> ();
                for (CDM_ApplicationCoursePreference acp : application.coursePreferences) {
                    acp.applicationRecord = applicationDetails;
                    applicationCoursePreferences.add(acp.asACPRecord());
                }
            }

            if (application.qualifications != null && !postSubmitPaymentUpdate) {
                applicationQualifications = new List<Contact_Qualification__c> ();
                for (CDM_Qualification qual : application.qualifications) {

                        if(!qual.isHistoric) {
                            // exclude historic qualfiications
                        qual.applicantRecord = new Contact(id = applicationDetails.Applicant__c);
                        applicationQualifications.add(qual.asQualificationRecord());

                            if(String.isNotBlank(qual.errorMessage.trim())) {
                                errorMessages.add(qual.errorMessage);
                    }
                }
            }
                }

            if (application.workExperiences != null && !postSubmitPaymentUpdate) {
                applicationWorkExperiences = new List<Work_Experience__c> ();

                for (CDM_WorkExperience workExp : application.workExperiences) {
                        if(!workExp.isHistoric) {
                            // exclude historic work experiences
                        workExp.applicantRecord = new Contact(id = applicationDetails.Applicant__c);
                        applicationWorkExperiences.add(workExp.asExperienceRecord());

                            if(String.isNotBlank(workExp.errorMessage.trim())) {
                                errorMessages.add(workExp.errorMessage);
                    }
                }
            }
        }
            }
        }

        /**
        * @description 
        * @return Boolean 
        **/
        global override Boolean validate() {
            List<String> exceptions = new List<String> ();
            if (String.isNotBlank(String.join(this.errorMessages, ''))) {
                throw new ApplicationException(String.join(this.errorMessages, '. '));
            }
            return true;
        }

        /**
        * @description 
        * @return Map<String, Object> 
        **/
        global Map<String, Object> process() {
            Map<String, Object> resultMap = new Map<String, Object> ();

            /**
             * for OES, if the Application is already in a submitted state, it implies that
             * This is a subsequent update call post-transfer job in order to recover the
             * previous ACP statuses that may have been overwritten.
             * 
             * In this case, we simply return the current state of the Application and only
             * allow updates on ACP
             */
            if(OESApplicationService.isOESUser && applicationDetails.Status__c == 'Submitted') {
                
                /**
                 * update ACPs and simplify response with only success messages
                 * rather than requerying everything again.
                 */
                if(this.acpByExternalId != null && !this.acpByExternalId.isEmpty()) {
                    List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
                    for(CDM_ApplicationCoursePreference icdm : application.coursePreferences) {
                        Application_Course_Preference__c iAcp = OESApplicationImpl.parseCdmToAcp(icdm);
                        iAcp.Id = this.acpByExternalId.get(icdm.externalId)?.Id;
                        acpList.add(iAcp);
                    }
                    update acpList; // implied never empty if acpByExternalId is not empty
                }

            } else {
            Savepoint updateApplicationSavePoint;
            try {
                    //Allow Application updates as long as the status is not 'Agent Declaration Accepted' value
                    if (String.isNotBlank(application.applicationStatus) && !application.applicationStatus.equalsIgnoreCase(AgentPortalConstants.AGENT_DECLARATION_ACCEPTED)) {                  
                       
                    if (postSubmitPaymentUpdate) {
                        resultMap.put('Details', AgentPortalServices.getApplicationDetails(application.applicationREF));
                        return resultMap;
                    }
                    if (applicationWorkExperiences != null) {
                        AgentPortalServices.updateApplicationWorkExperiences(applicationDetails.Id, applicationWorkExperiences);
                    }               
                    if (applicationCoursePreferences != null) { 
                        AgentPortalServices.updateApplicationCoursePreferences(applicationDetails.Id, applicationCoursePreferences);
                    }
                    if (applicationQualifications != null) { 
                        AgentPortalServices.updateApplicationQualifications(applicationDetails.Id, applicationQualifications);
                    }
                    updateApplicationSavePoint = Database.setSavepoint();
                    AgentPortalServices.updateApplication(applicationDetails);
                }
                resultMap.put('Details', AgentPortalServices.getApplicationDetails(application.applicationREF));
                resultMap.put('Qualifications', applicationQualifications != null ? AgentPortalServices.getContactQualificationsByApplicationId(application.applicationREF) : null);
                resultMap.put('WorkExperiences', applicationWorkExperiences != null ? AgentPortalServices.getWorkExperiencesByApplicationId(application.applicationREF) : null);
                // Application submission specific code -- START
                Boolean isAppnReviewSuccessful = false;
                List<String> reviewErrors = new List<String> ();
                    //Allow application to progress when Status = 'Agent Declaration Accepted' 
                    if (String.isNotBlank(application.applicationStatus) && application.applicationStatus.equalsIgnoreCase(AgentPortalConstants.AGENT_DECLARATION_ACCEPTED)) {
                    //Run validations for APNG applications only                    // Run Affilication check
                    Map<Date, List<Id>> mapIntakeACPs = new Map<Date, List<Id>> ();
                    List<Application_Course_Preference__c> appACPs = ((ApplicationDetails) resultMap.get('Details')).coursePreferences;
                    AffiliationCheckService.AffiliationResult affiliationResult = new AffiliationCheckService(applicationDetails.Applicant__c, applicationDetails.Agent__c, applicationDetails.Campus_Location__c, appACPs).result;
                    // Review the Application, if Affiliation check is successful
                    if (affiliationResult.canSubmitApplications) {
                       //Run validations for APNG applica`tions only
                       if(!ApplicationService.isOESUser()){
                        // reviewErrors = AgentPortalServices.reviewApplicationForSubmit(applicationDetails, applicationCoursePreferences, applicationQualifications, applicationWorkExperiences);
                        for (Map<String, Object> reviewErrorsBySection : AppDeclarationFormCC.getValidationErrors(applicationDetails.Id, true)) {
                            reviewErrors.add(reviewErrorsBySection.get('label') + ' - ' + String.join(((List<String>) reviewErrorsBySection.get('errors')),'; '));
                        }
                        }
                    } else {
                        throw new ApplicationException(affiliationResult.message);
                    }
                    updateApplicationSavePoint = Database.setSavepoint();                        
                    if (reviewErrors.isEmpty()) {
                        applicationDetails.Status__c = MyApplicationUtilities.APP_PENDING_MERGE_STATUS;
                        applicationDetails.Submitted_Date__c = Date.today();
                        AgentPortalServices.updateApplication(applicationDetails);
                        resultMap.put('Details', AgentPortalServices.getApplicationDetails(application.applicationREF));
                    } else {
                        throw new ApplicationException('Application review failed: ' + String.join(reviewErrors, ', '));
                    }
                } 
                // Application submission specific code -- END
            } catch(Exception ex) {
                if (updateApplicationSavePoint != null){
                    Database.rollback(updateApplicationSavePoint);
                }
                throw ex;
            }
        }
            
            return resultMap;
        }
    }
    /**
     * @description UpdateApplicationResponse wrapper
     */
    global class UpdateApplicationResponse extends AgentPortalResponse {
        /**
        * @description 
        **/
        global UpdateApplicationResponse() {
            this.successMessage = 'Application updated successfully!';
            this.responseMessage = 'application';
            this.responseType = AgentPortalConstants.RESP_TYPE_UPDATE;
        }
        /**
        * @description 
        * @param value
        * @return Map<String, Object> 
        **/
        global Map<String, Object> updateStatus {
            set {
                this.response = value;
                if (value == null) {
                    this.response = new Map<String, Object> ();                    
                    this.successMessage = 'Application update failed!';
                }
            }
        }
    }
    // APPLICATION MANAGEMENT RELATED PAYLOADS -- END

    // AFFILIATION CHECK RELATED PAYLOADS -- START
    /**
     * @description CheckAffiliationRequest wrapper
     */
    global class CheckAffiliationRequest extends AgentPortalRequest {
        global String contactId;
        global String agencyId;
        global String campusLocation;

        /**
        * @description 
        * @param params
        **/
        global CheckAffiliationRequest(Map <String, String> params) {
            if (params != null && !params.isEmpty()) {
                this.contactId = params.get('contactId');
                this.contactId = AgentPortalServices.getContact(this.contactId, AgentPortalConstants.APPLICANT_PERSONA, AgentPortalConstants.SYSTEM_CONTEXT)?.Id;
                this.agencyId = runningUser?.Contact.AccountId;
                this.campusLocation = params.get('campusLocation');
            } 
        }
        /**
        * @description 
        * @return Boolean 
        **/
        global override Boolean validate() {
            List<String> exceptions = new List<String> ();
            if (String.isBlank(this.contactId)) {
                exceptions.add('Invalid Applicant ID or Applicant doesn\'t exist!');
            }
            if (String.isBlank(agencyId)) {
                exceptions.add('Invalid Agent ID');
            } 
            if (String.isBlank(campusLocation)) {
                exceptions.add('Campus Location cannot be empty');
            } 
            if(!exceptions.isEmpty()) {
                throw new BadRequestException(String.join(exceptions, ', '));
            } 
            return true;
        }
    }
    /**
     *@description CheckAffiliationResponse
     */
    global class CheckAffiliationResponse extends AgentPortalResponse {
        /**
        * @description 
        **/
        global CheckAffiliationResponse() {
            this.responseType = AgentPortalConstants.RESP_TYPE_GET;
            this.responseMessage = 'affiliationStatus';
            this.successMessage = 'Affiliation check service successfully ran!';
        }
        /**
        * @description 
        **/
        global Object affiliationStatus {
            set {
                this.response = value;
            }
        }
    }
    // AFFILIATION CHECK RELATED PAYLOADS -- END
    // REFERENCE DATA RELATED PAYLOADS -- START
    /**
     * @description ReferenceDataRequest wrapper
     */
    global class ReferenceDataRequest extends AgentPortalRequest {
        global String requestType;
        /**
        * @description 
        * @param params
        **/
        global ReferenceDataRequest(Map <String, String> params) {
            if (params != null && !params.isEmpty()) {
                this.requestType = params.get('requestType');
            } 
        }
        /**
        * @description 
        * @return Boolean 
        **/
        global override Boolean validate() {
            if (String.isBlank(this.requestType)) {
                throw new AgentPortalPayload.BadRequestException('Request Type not set');
            } else if (!this.requestType.equalsIgnoreCase('residencystatus')) {
                throw new AgentPortalPayload.BadRequestException('Request Type: '+ this.requestType + ' is not recognised');
            }
            return true;
        }
    }
    /**
     * @description ReferenceDataResponse wrapper
     */
    global class ReferenceDataResponse extends AgentPortalResponse {
         /**
     * @description ReferenceDataResponse wrapper
     */
        global Object referenceDataRecords {
            set {
                this.response = value;
            }
            get;
        }

        /**
        * @description 
        * @param requestType  
        **/
        global ReferenceDataResponse(String requestType) {
            this.responseMessage = requestType;
            this.responseType = AgentPortalConstants.RESP_TYPE_GET;
            this.successMessage = 'Record(s) found for request: ' + this.responseMessage ;
        }
    }
    // REFERENCE DATA RELATED PAYLOADS -- END

    // AGENT MANAGEMENT RELATED PAYLOADS -- START
    /**
     * @description CreateAgentRequest wrapper
     */
    global class CreateAgentRequest extends AgentPortalRequest {
        global CDM_Agent agent;
        global String requestType;
        global String contactId;
        /**
        * @description 
        * @param params
        **/
        global CreateAgentRequest(Map<String, String> params) {
            if (params != null && !params.isEmpty()) {
                this.requestType = params.get('requestType');
                this.contactId = params.get('contactId');
            } 
        }
        /**
        * @description 
        * @author Ben Greenland | 2024-09-11 
        * @return Contact 
        **/
        global Contact asContact() {
                return new Contact(
                        First_Name__c = this.agent.firstName,
                        Last_Name__c = this.agent.lastName,
                        FirstName = this.agent.firstName,
                        LastName = this.agent.lastName,
                        Email = this.agent.agentEmail,
                        Agency_Contact_Roles__c = String.join(this.agent.roles, ';'),
                        RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Agency Contact').getRecordTypeId(),
                        AccountId = this.agency.Id
                    );
        }
        /**
        * @description 
        * @return User 
        **/
        global User asUser() {
            return new User(
                        FirstName = this.agentContact.First_Name__c,
                        LastName = this.agentContact.Last_Name__c,
                        // CommunityNickname = this.agent.nickname,
                        Email = this.agentContact.Email,
                        Username = this.agentContact.Email,
                        ContactId = this.contactId,
                        ProfileId = AgentPortalConstants.AGENT_PROFILE_ID
            );
        }
        /**
         * @description agentContact wrapper
         */
        global Contact agentContact {
            get {
                if (agentContact == null && this.contactId != null) {
                    // Fetch the Contact
                    agentContact = AgentPortalServices.getContact(this.contactId, AgentPortalConstants.AGENT_PERSONA, AgentPortalConstants.USER_CONTEXT);
                }
                return agentContact;
            } set;
        }
        private Account agency {
            get {
                if (agency == null) {
                    if (this.requestType.equalsIgnoreCase('createContact')) {
                        agency = new Account(id = runningUser.Contact.AccountId, Is_Insurance_Stakeholder__c=true);
                    }
                    if (this.requestType.equalsIgnoreCase('enableAsUser')) {
                        if (agentContact != null){
                            agency = new Account(id = this.agentContact.AccountId, IsPartner = this.agentContact.Account.IsPartner, Is_Insurance_Stakeholder__c=true);
                        }
                    }
                }
                return agency;
            } set;
        }
        global override Boolean validate() {
            if (String.isBlank(this.requestType)) {
                throw new AgentPortalPayload.BadRequestException('Request Type not set');
            } else if (!this.requestType.equalsIgnoreCase('createContact') && !this.requestType.equalsIgnoreCase('enableAsUser')) {
                throw new AgentPortalPayload.BadRequestException('Request Type: '+ this.requestType + ' is not recognised');
            }
            if (!runningUser.Contact.Agency_Contact_Roles__c.split(';').contains(AgentPortalConstants.CONTACT_ROLE_ALLOWED_TO_CREATE_USERS)) {
                throw new AgentPortalPayload.BadRequestException('You are not authorised to create Users under this Agency');
            }
            String possibleUsername;
            System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
            String suffix = AgentPortalConstants.AGENT_PORTAL_USER_SUFFIX + (d.getSandboxName() != null ? '.' + d.getSandboxName() : '');
            if (this.requestType.equalsIgnoreCase('createContact')) {
                if (this.agent.roles.contains('Branch Manager') || this.agent.roles.contains('Principal Agent')) {
                    throw new AgentPortalPayload.BadRequestException('Branch Managers and Principal Agents cannot be created from Portal');
                }
                List<Contact> agencyContactsWithSameEmail = [SELECT id FROM Contact WHERE email = :this.asContact().Email];
                if (agencyContactsWithSameEmail != null && !agencyContactsWithSameEmail.isEmpty()) {
                    throw new AgentPortalPayload.BadRequestException('Another agent with the same email already exists');
                } else {
                    possibleUsername = this.asContact().Email + suffix;
                }
            } else if (this.requestType.equalsIgnoreCase('enableAsUser')) {
                possibleUsername = this.asUser().username + suffix;
            }
            if (AgentPortalServices.doesUserExist(possibleUsername)) {
                throw new AgentPortalPayload.BadRequestException('Email/Username already exists');
            }
            return true;
        }
    }
    /**
     * @description CreateAgentResponse wrapper
     */
    global class CreateAgentResponse extends AgentPortalResponse {
        /**
     * @description contactRecord wrapper
     */
        global Object contactRecord {
            set {
                if (value != null){
                    this.response = value;
                } else {
                    this.response = new Contact();
                    this.successMessage = 'Contact could not be created!' ;
                }
            }
            get;
        }
    /**
     * @description userRecord wrapper
     */
        global Object userRecord {
            set {
                if (value != null){
                    this.response = value;
                } else {
                    this.response = new User();
                    this.successMessage = 'User could not be created!' ;
                }
            }
            get;
        }

        /**
        * @description 
        * @param requestType 
        **/
        global CreateAgentResponse(String requestType) {
            this.responseType = AgentPortalConstants.RESP_TYPE_CREATE;
            this.responseMessage = 'AgentManagement';
            this.successMessage = requestType + ' successfully created!' ;
        }
    }
     /**
        * @description ManageAgentRequest wrapper
        **/
    global class ManageAgentRequest extends AgentPortalRequest {
        global CDM_Agent agent;
             /**
        * @description requestType wrapper
        **/
        public String requestType {
            get {
                if (requestType == null){
                    try {   
                        Id contactorUserId = Id.valueOf(this.agent.crmRecordId);
                        if (Schema.Contact.SObjectType == contactorUserId.getSobjectType()) {
                            List<User> associatedUser = [SELECT id FROM User WHERE ContactId = :contactorUserId LIMIT 1];
                            if (associatedUser == null || associatedUser.isEmpty()) {
                                requestType = 'updateContact';
                            } else {
                                requestType = 'changeRole';
                            }
                        } else if (Schema.User.SObjectType == contactorUserId.getSobjectType()) {
                            requestType = 'updateUser';
                        }
                    } catch(Exception ex) {
                        throw new AgentManagementException('Invalid ID');
                    }
                }
                return requestType;
            } set;
        }
        /**
        * @description 
        * @return Boolean 
        **/
        global override Boolean validate() {
            if (!runningUser.Contact.Agency_Contact_Roles__c.split(';').contains(AgentPortalConstants.CONTACT_ROLE_ALLOWED_TO_CREATE_USERS)) {
                throw new AgentPortalPayload.BadRequestException('You are not authorised to edit Users under this Agency');
            }

            if (this.requestType.equalsIgnoreCase('updateContact') || this.requestType.equalsIgnoreCase('changeRole')) {
                Contact agentContact = [SELECT Agency_contact_roles__c FROM Contact WHERE id = :this.agent.crmRecordId LIMIT 1]; 
                if (this.agent.roles == null) {
                    throw new AgentPortalPayload.BadRequestException('Agent Contact roles cannot be blank');
                } else if (agentContact.Agency_contact_roles__c.containsIgnoreCase('Branch Manager') || agentContact.Agency_contact_roles__c.containsIgnoreCase('Principal Agent') || this.agent.roles.contains('Branch Manager') || this.agent.roles.contains('Principal Agent')) {
                    Boolean bmCheck = null;
                    Boolean paCheck = null;
                    if (agentContact.Agency_contact_roles__c.containsIgnoreCase('Branch Manager')) { 
                        bmCheck = this.agent.roles.contains('Branch Manager');
                    } 
                    if (agentContact.Agency_contact_roles__c.containsIgnoreCase('Principal Agent')) {
                        paCheck = this.agent.roles.contains('Principal Agent');
                    } 
                    if ((bmCheck == null || bmCheck == false) || (paCheck == null || paCheck == false)) {
                        throw new AgentPortalPayload.BadRequestException('Branch Managers and Principal Agents cannot be updated');
                    }
                }
            }
            if (this.requestType.equalsIgnoreCase('changeRole') || this.requestType.equalsIgnoreCase('updateUser')) {
                if (this.agent.email != null) {
                    throw new AgentPortalPayload.BadRequestException('User already exists for this contact. Email cannot be updated');
                }
            } 
            return true;
        }
    }
    /**
     * @description ManageAgentResponse wrapper
     */
    global class ManageAgentResponse extends AgentPortalResponse {
    /**
     * @description result wrapper
     */
        global Object result {
            set {
                if (value != null){
                    this.response = value;
                } else {
                    this.response = new Contact();
                    this.successMessage = 'Agent could not be updated!' ;
                }
            } get;
        }


        /**
        * @description ManageAgentResponse string
        **/
        global ManageAgentResponse() {
            this.responseType = AgentPortalConstants.RESP_TYPE_UPDATE;
            this.responseMessage = 'AgentManagement';
            this.successMessage = 'Agent successfully updated!' ;
        }
    }
    // AGENT MANAGEMENT RELATED PAYLOADS -- END
	// APPLICATION DOCUMENT MANAGEMENT RELATED PAYLOADS -- START
        /**
     * @description ListApplicationDocumentsRequest wrapper
     */
    global class ListApplicationDocumentsRequest extends AgentPortalRequest {
        global String applicationId;
        global String orgId;
        global Integer pageSize;
        global Integer pageOffset;
        /**
        * @description 
        * @param params 
        **/
        global ListApplicationDocumentsRequest(Map<String, String> params) { 
            if (params != null && !params.isEmpty()) {
                this.applicationId = params.get('applicationId');
            } 
        }
        /**
        * @description Application__c wrapper
        * @return Application__c 
        **/
        global Application__c application {
            get {
                List<Application__c> apps = [SELECT Id, Name FROM Application__c WHERE name = :applicationId LIMIT 1];
                if (apps != null & !apps.isEmpty()) {
                    return apps[0];
                }
                return null;
            }
        }
        /**
        * @description 
        * @return Boolean 
        **/
        global override Boolean validate() {
            if (String.isBlank(applicationId)) {
                throw new ApplicationDocumentException('Application ID cannot be empty!');
            } else {
                if (application == null) { throw new ApplicationDocumentException('Invalid Application ID!'); }
            }
            return true;
        }
        /**
        * @description 
        * @return List<DocumentChecklistItem> 
        **/
        global List<DocumentChecklistItem> process() {
            Map<String, String> checklistItemLabels = new Map<String, String> ();
            for (Schema.PicklistEntry p : Document_Checklist__c.Allowed_Document_Type__c.getDescribe().getPicklistValues()) {
                checklistItemLabels.put(p.getValue(), p.getLabel());
            }
            List<AgentPortalPayload.DocumentChecklistItem> documentationChecklist = new List<AgentPortalPayload.DocumentChecklistItem>();
            Map<id, Document_Checklist__c> documentChecklist = new Map<id, Document_Checklist__c> ([SELECT id,Checklist_Requirement__c,Name,Sort_Order__c,Status__c,Allowed_Document_Type__c, Applicant_Instructions_UI__c FROM Document_Checklist__c WHERE application__c = : this.application.id]);
            // retrieve contact documents
            List<Contact_Document__c> contactDocuments = [SELECT Id,Document_Type__c,Document_Checklist__c,Comments__c,Filename__c, Type__c,LastModifiedDate FROM Contact_Document__c WHERE Application__c = :this.application.id];
            // build contact document map
            Map<String, Map<String,List<Contact_Document__c>>> contactDocumentMap = new Map<String, Map<String,List<Contact_Document__c>>>();
            for (Contact_Document__c currentDocument : contactDocuments) {
                Map<String,List<Contact_Document__c>> currentDocMap;
                String checklistItemKey = String.isNotBlank(currentDocument.Document_Checklist__c) ? '' + currentDocument.Document_Checklist__c : 'Other Documents';
                    if (!contactDocumentMap.containsKey(checklistItemKey)) {
                        contactDocumentMap.put(checklistItemKey, new Map<String,List<Contact_Document__c>>());
                    }
                    currentDocMap = contactDocumentMap.get(checklistItemKey);
                if (!currentDocMap.containsKey(currentDocument.Document_Type__c)) {
                    currentDocMap.put(currentDocument.Document_Type__c, new List<Contact_Document__c>());
                }
                List<Contact_Document__c> currentDocList = currentDocMap.get(currentDocument.Document_Type__c);
                currentDocList.add(currentDocument);
            }
            // build response;
            for (Document_Checklist__c currentItem : documentChecklist.values()) {
                    AgentPortalPayload.DocumentChecklistItem currentChecklistItem = new AgentPortalPayload.DocumentChecklistItem(currentItem);
                    Map<String,List<Contact_Document__c>> contentDocumentsInChecklist = contactDocumentMap.containsKey(currentItem.id) ? contactDocumentMap.get(currentItem.id) : new Map<String,List<Contact_Document__c>>();
                    for (String currentTypeString : currentItem.Allowed_Document_Type__c.split(';')) {
                        AgentPortalPayload.SupportedDocumentType currentType = new AgentPortalPayload.SupportedDocumentType();
                        currentType.typeCode = currentTypeString;
                        currentType.typeName = checklistItemLabels.get(currentTypeString);
                        currentType.instances = new List<AgentPortalPayload.DocumentInstance>();
                        List<Contact_Document__c> contentDocumentsInType = contentDocumentsInChecklist.containsKey(currentTypeString) ? contentDocumentsInChecklist.get(currentTypeString) : new List<Contact_Document__c>();
                        for (Contact_Document__c currentContactDocument : contentDocumentsInType) {
                            AgentPortalPayload.DocumentInstance currentInstance = new AgentPortalPayload.DocumentInstance(currentContactDocument);
                            currentType.instances.add(currentInstance);
                        }
                        currentChecklistItem.supportedDocumentTypes.add(currentType);
                    }
                documentationChecklist.add(currentChecklistItem);
            }
            // Adding Other Documents section
            AgentPortalPayload.DocumentChecklistItem currentChecklistItem = new AgentPortalPayload.DocumentChecklistItem();
            if (contactDocumentMap.containsKey('Other Documents')) {
                Map<String,List<Contact_Document__c>> contentDocumentsInChecklist = contactDocumentMap.get('Other Documents');
                    for (String currentTypeString : contentDocumentsInChecklist.keySet()) {
                        AgentPortalPayload.SupportedDocumentType currentType = new AgentPortalPayload.SupportedDocumentType();
                        currentType.typeCode = currentTypeString;
                        currentType.typeName = checklistItemLabels.get(currentTypeString);
                        currentType.instances = new List<AgentPortalPayload.DocumentInstance>();
                        List<Contact_Document__c> contentDocumentsInType = contentDocumentsInChecklist.containsKey(currentTypeString) ? contentDocumentsInChecklist.get(currentTypeString) : new List<Contact_Document__c>();
                        for (Contact_Document__c currentContactDocument : contentDocumentsInType) {
                            AgentPortalPayload.DocumentInstance currentInstance = new AgentPortalPayload.DocumentInstance(currentContactDocument);
                            currentType.instances.add(currentInstance);
                        }
                        currentChecklistItem.supportedDocumentTypes.add(currentType);
                    }
            }
            documentationChecklist.add(currentChecklistItem);
            return documentationChecklist;
        }
    }
    /**
     * @description ListDocumentChecklistResponse wrapper
     */ 
    global class ListDocumentChecklistResponse extends AgentPortalResponse {
        /**
        * @description 
        **/
        global ListDocumentChecklistResponse() {
            this.responseType = AgentPortalConstants.RESP_TYPE_GET;
            this.responseMessage = 'Documents';
            this.successMessage = 'Document Checklist Found!';
        }
        /**
        * @description 
        **/
        global List<DocumentChecklistItem> DocumentationChecklist {
            set {
                if (value != null && !value.isEmpty()) {
                    this.response = value;
                    this.noOfRecords = value.size();
                } else {
                    this.successMessage = 'No Document checklists found for this Application!';
                }
            }
        }
    }
    /** @description DocumentChecklistItem*/
    global class DocumentChecklistItem {
        /** @description id **/
        global string id { get; set; }
        /** @description desc**/
        global string description { get; set; }
        /** @description name**/
        global string name { get; set; }
        /** @description sortorder **/
        global integer sortOrder { get; set; }
        /** @description status**/
        global string status { get; set; }
        /** @description supportedDocumentTypes**/
        global List<SupportedDocumentType> supportedDocumentTypes { get; set; }

        /**
        * @description 
        * @param  checklistItem 
        **/
        global DocumentChecklistItem (Document_Checklist__c checklistItem) {
            this.id = checklistItem.id;
            this.description = checklistItem.Applicant_Instructions_UI__c;
            this.name = checklistItem.Checklist_Requirement__c;
            this.sortOrder = (Integer) checklistItem.Sort_Order__c;
            this.status = checklistItem.Status__c;
            this.supportedDocumentTypes = new List<AgentPortalPayload.SupportedDocumentType>();
        }
        
        /**
        * @description 
        **/
        global DocumentChecklistItem () {
            this.name = 'Other';
            this.description = 'Other Documents';
            this.supportedDocumentTypes = new List<AgentPortalPayload.SupportedDocumentType>();
        }
    }
    /**
     * @description SupportedDocumentType wrapper
     */
    global class SupportedDocumentType {
         /** @description typeCode**/
        global string typeCode { get; set; }
         /** @description typeName**/
        global string typeName { get; set; }
         /** @description typeCode**/
        global List<DocumentInstance> instances { get; set; }
    }
        /**
     * @description DocumentInstance wrapper
     */
    global class DocumentInstance {
        /** @description id**/
        global string id { get; set; }
        /** @description contentType**/
        global string contentType { get; set; }
        /** @description filename**/
        global string filename { get; set; }
        /** @description comments**/
        global string comments { get; set; }
        /** @description lastUpdateDate**/
        global DateTime lastUpdateDate { get; set; }
        
        /**
        * @description 
        * @param  contactDoc 
        **/
        global DocumentInstance(Contact_Document__c contactDoc) {
            this.id = contactDoc.Id;
            this.contentType = contactDoc.Type__c;
            this.filename = contactDoc.Filename__c;
            this.comments = contactDoc.Comments__c;
            this.lastUpdateDate = contactDoc.LastModifiedDate;
        }
    }
    
    // APPLICATION DOCUMENT MANAGEMENT RELATED PAYLOADS -- END


    // ENQUIRY MANAGEMENT RELATED PAYLOADS -- START
    /**
    * @description  CreateEnquiryRequest wrapper
    **/
    global class CreateEnquiryRequest extends AgentPortalRequest {
         /** @description enquiry**/
        global CDM_Enquiry enquiry { get; set;}
        
        global override Boolean validate() {
            return true;
        }
    }
    /** @description CreateEnquiryResponse wrapper*/
    global class CreateEnquiryResponse extends AgentPortalResponse {

       
            /**
            * @description CreateEnquiryResponse
            **/
        global CreateEnquiryResponse() {
            this.responseType = AgentPortalConstants.RESP_TYPE_CREATE;
            this.responseMessage = 'Enquiry';
        }
         /**
        * @description caseRecord
        **/
        global Case caseRecord {
            set {
                if (value != null) {
                    this.response = value;
                } 
            }
        }
    }
    // ENQUIRY MANAGEMENT RELATED PAYLOADS -- END
    // MIX COMMON DATA MODEL BASED CLASSES
    /**
     * @description CDM_Agent wrapper
     */
    global class CDM_Agent {
        global string firstName;
        global string lastName;
        global List<Email> email;
        global string crmRecordId; // MiX sends ContactId or UserId depending on the context
        global List<string> roles;
        global Boolean isActive;
        global Boolean isFrozen;
        /**
         * @description agentEmail
         */
        global String agentEmail {
            get { return email != null ? AgentPortalServices.getEmail(this.email, 'Official') : null;}
        }
    }
    /**
     * @description Address wrapper
     */
    global class Address {
        global string street;
        global string city;
        global string country;
        global string geoCodeAccuracy;
        global string latitude;
        global string longitude;
        global string postalCode;
        global string state;
        global string type;
    }
        /**
     * @description Phone wrapper
     */
    global class Phone {
        global string type;
        global string phoneNumber;
    }
    /** @description Phone wrapper*/
    global class Email {
        global string type;
        global string email;
    }
    /** @description Phone wrapper*/
    global class ResidencyStatus {
        global string code;
        /** @description description*/
        global string description {get;set;}
    }
    /** @description Phone wrapper*/
    global class Qualifications {
        global String applicationId; // Name
        global String applicantId;
        /**
        * @description recordCount
        * @return Integer 
        **/
        global Integer recordCount {
            get { return (applicationQualifications == null || applicationQualifications.isEmpty() ? 0 : applicationQualifications.size()); }
        }
        global List<Contact_Qualification__c> applicationQualifications;
    }
    /** @description Phone wrapper*/
    global class WorkExperiences {
        global String applicationId; // Name
        global String applicantId;
                /**
        * @description recordCount
        * @return Integer 
        **/
        global Integer recordCount {
            get { return (applicationExperiences == null || applicationExperiences.isEmpty() ? 0 : applicationExperiences.size()); }
        }
        global List<Work_Experience__c> applicationExperiences;
    }
    /** @description Phone wrapper*/
    global class ApplicationDetails {
        /**
        * @description details
        * @return details 
        **/
        global Application__c details {
            set {
                Application__c app = value;
                // translate Residency Status from sub status
                if (app != null && String.isNotBlank(app.Residency_Sub_status__c)) {
                    app.Residency_Status__c = app.Residency_Sub_status__c;
                    app.Residency_Sub_status__c = '';
                }
                details = app;
            } get;
        }
        global List<Application_Course_Preference__c> coursePreferences;
    }
    /** @description Phone wrapper*/
    global class ApplicantDetails {
        global contact details;
        global Boolean isEditable;
    }
    /** @description Phone wrapper*/
    global class CDM_Applicant {
        global string crmContactId; // CRM_ID__c
        global string smsContactId; // Person_id_unique__c
        global string contactId; // record Id
        global string title;
        global string firstName;
        global string lastName;
        global string preferredName;
        global string pronoun;
        global string previousName;
        global string gender;
        global CDM_Country countryOfBirth;
        global string countryOfResidence;
        global string dateOfBirth;
        global Boolean isDeceased;
        global List<Phone> phone;
        global List<Email> email;
        global List<Address> address;
        global string broadAreaOfInterest;
        global string highestEducationLevel;
        global boolean isPreviousMonashStudent;
        global string previousMonashId;
        global string leadSource;
        global string sourceSystem;
        global string specificAreaOfInterest;
        global Boolean disallowedFieldUpdated;
        global String aboriginalTorresIslander;//SFTG-3860

        /**
        * @description  asContact
        * @return Contact 
        **/
        global Contact asContact {
            get {
                Contact contactRecord = new Contact();
                disallowedFieldUpdated = false;
                contactRecord.MiddleName = null;
                if (contactId != null) {contactRecord.Id = contactId;}
                if (title != null) {contactRecord.Salutation = title; disallowedFieldUpdated = true;}
                if (firstName != null) {contactRecord.First_Name__c = firstName; contactRecord.FirstName = firstName; disallowedFieldUpdated = true;}
                if (lastName != null) {contactRecord.Last_Name__c = lastName; contactRecord.LastName = lastName; disallowedFieldUpdated = true;}
                if (preferredName != null) {contactRecord.Preferred_Name__c = preferredName; disallowedFieldUpdated = true;}
                if (pronoun != null) {contactRecord.Pronouns_V2__c = pronoun;}
                if (previousName != null) {contactRecord.Previous_Surname__c = previousName; disallowedFieldUpdated = true;}
                if (gender != null) {contactRecord.Gender__c = gender; disallowedFieldUpdated = true;}
                if(aboriginalTorresIslander != null) {contactRecord.Aboriginal_or_Torres_Strait_Islander__c = aboriginalTorresIslander; disallowedFieldUpdated = true;}
                //Populate CountryOfBirth__c field depending on the running user
                if(OESApplicationService.isOESUser){
                    if (countryOfBirth != null || String.isNotBlank(countryOfBirth.uniqueCountryExternalId )) {
                        contactRecord.CountryOfBirth__r = new Country_Attribute__c(uniqueCountryExternalId__c = countryOfBirth.uniqueCountryExternalId); 
                        disallowedFieldUpdated = true;
                    }else{
                        throw new ApplicantException('Applicant\'s countryOfBirth.uniqueCountryExternalId field is Blank');
                    }
                }else{
                if (countryOfBirth != null) {contactRecord.CountryOfBirth__c = countryOfBirth.crmRecordId; disallowedFieldUpdated = true;}
                }
                if (countryOfResidence != null) {contactRecord.Country_of_Residence__c = countryOfResidence; disallowedFieldUpdated = true;}
                if (isDeceased != null) {contactRecord.Deceased__c = isDeceased; disallowedFieldUpdated = true;}
                if (broadAreaOfInterest != null) {contactRecord.Broad_area_s_of_interest__c = broadAreaOfInterest; disallowedFieldUpdated = true;}
                if (highestEducationLevel != null) {contactRecord.Highest_level_of_education_to_date__c = highestEducationLevel; disallowedFieldUpdated = true;}
                if (isPreviousMonashStudent != null) {contactRecord.Previously_Studied_at_Monash__c = isPreviousMonashStudent; disallowedFieldUpdated = true;}
                if (previousMonashId != null) {contactRecord.Previous_Monash_ID__c = previousMonashId; disallowedFieldUpdated = true;}
                if (specificAreaOfInterest != null) {contactRecord.Specific_area_s_of_interest__c = specificAreaOfInterest; disallowedFieldUpdated = true;}
                if (phone != null) {
                    for (Phone ph : phone) {
                        if (ph.type.equalsIgnoreCase('Home')) {contactRecord.HomePhone = AgentPortalServices.getPhoneNumber(phone, 'Home'); disallowedFieldUpdated = true;}
                        if (ph.type.equalsIgnoreCase('Mobile')) {contactRecord.MobilePhone = AgentPortalServices.getPhoneNumber(phone, 'Mobile'); disallowedFieldUpdated = true;}
                        if (ph.type.equalsIgnoreCase('Other')) {contactRecord.OtherPhone = AgentPortalServices.getPhoneNumber(phone, 'Other'); disallowedFieldUpdated = true;}
                    }
                } 
                if (email != null) {
                    for (Email eml : email) {
                        if (eml.type.equalsIgnoreCase('Personal')) {contactRecord.Personal_Email__c = AgentPortalServices.getEmail(email, 'Personal'); disallowedFieldUpdated = true;}
                    }
                }
                if (address != null) {
                    for (Address addr : address) {
                        if (addr.type.equalsIgnoreCase('Postal')) {
                            if (addr.street != null) {contactRecord.MailingStreet = addr.street; disallowedFieldUpdated = true;}
                            if (addr.city != null) {contactRecord.MailingCity = addr.city; disallowedFieldUpdated = true;}
                            if (addr.state != null) {contactRecord.MailingState = addr.state; disallowedFieldUpdated = true;}
                            if (addr.country != null) {contactRecord.MailingCountry = addr.country; disallowedFieldUpdated = true;}
                            if (addr.postalCode != null) {contactRecord.MailingPostalCode = addr.postalCode; disallowedFieldUpdated = true;}
                            if (addr.geoCodeAccuracy != null) {contactRecord.MailingGeocodeAccuracy = addr.geoCodeAccuracy; disallowedFieldUpdated = true;}
                            if (addr.latitude != null) {contactRecord.MailingLatitude = Decimal.valueOf(addr.latitude); disallowedFieldUpdated = true;}
                            if (addr.longitude != null) {contactRecord.MailingLongitude = Decimal.valueOf(addr.longitude); disallowedFieldUpdated = true;}
                        }
                        if (addr.type.equalsIgnoreCase('Other')) {
                            if (addr.street != null) {contactRecord.OtherStreet = addr.street; disallowedFieldUpdated = true;}
                            if (addr.city != null) {contactRecord.OtherCity = addr.city; disallowedFieldUpdated = true;}
                            if (addr.state != null) {contactRecord.OtherState = addr.state; disallowedFieldUpdated = true;}
                            if (addr.country != null) {contactRecord.OtherCountry = addr.country; disallowedFieldUpdated = true;}
                            if (addr.postalCode != null) {contactRecord.OtherPostalCode = addr.postalCode; disallowedFieldUpdated = true;}
                            if (addr.geoCodeAccuracy != null) {contactRecord.OtherGeocodeAccuracy = addr.geoCodeAccuracy; disallowedFieldUpdated = true;}
                            if (addr.latitude != null) {contactRecord.OtherLatitude = Decimal.valueOf(addr.latitude); disallowedFieldUpdated = true;}
                            if (addr.longitude != null) {contactRecord.OtherLongitude = Decimal.valueOf(addr.longitude); disallowedFieldUpdated = true;}
                        }
                    }
                } 
                if (dateOfBirth != null) {
                    try {
                        contactRecord.BirthDate = Date.valueOf(dateOfBirth);
                    } catch(Exception e) {
                        throw new ApplicantException('Applicant\'s Date of Birth is of invalid format. Only yyyy-MM-dd format is accepted');
                    }
                } 
                return contactRecord;
            }
        }
    }
    /** @description CDM_Application wrapperer */
    global class CDM_Application {
        global String applicationId; //Name
        global String applicationREF;
        global String crmContactId; // CRM_ID__c
        global String applicationStatus;
        global String applicationType;
        global Boolean isPrincipalCourseTransfer;
        global Boolean hasRequestForScholarship;
        global Boolean hasRequestForAdvancedStanding;
        global Boolean isStudentPassAvailable;
        global Boolean englishLanguageProficiency;
        global String residencyStatus;
        global String sponsorScholarship;
        global String passportNumber;
        global String agentNotes;
        global CDM_Status sponsorStatus;
        global CDM_Status hasDisability;
        global CDM_Status existingDisabilitySupport;
        global CDM_Visa visa;
		global List<CDM_Qualification> qualifications;
		global List<CDM_WorkExperience> workExperiences;
        global List<CDM_ApplicationCoursePreference> coursePreferences;
        global CDM_Payment payment;
        global String externalReferenceId;
        global String delegatorOrgUnitCode;

        private List<String> validationErrors {
            get {
                if (validationErrors == null) {
                    validationErrors = new List<String> ();
                }
                return validationErrors;
            } set;
        }
        
        /**
        * @description error message
        * @return String 
        **/
        global String errorMessage {
            get {
                String detailsErrors = validationErrors.isEmpty() ? '' : String.join(validationErrors, ', ');
                if (visa != null ) { detailsErrors += ' ' + visa.errorMessage; }
                if (payment != null) { detailsErrors += ' ' + payment.errorMessage; }
                if (String.isNotBlank( detailsErrors.trim() )) { 
                    return 'DETAILS SECTION ERRORS - ' + detailsErrors; 
                }
                return '';
            }
        }
        /**
        * @description asApplicationRecord
        * @return Application__c
        */
        global Application__c asApplicationRecord() {
            Application__c app = [SELECT id, Name, Sent_to_student_for_review_Timestamp__c, Agent_Edits_After_Applicant_Acceptance__c, Campus_Location__c, Applicant__c, Agent__c, Status__c FROM Application__c WHERE NAME = :applicationId LIMIT 1];

            /**
             * for OES, if the Application is already in a submitted state, it implies that
             * This is a subsequent update call post-transfer job in order to recover the
             * previous ACP statuses that may have been overwritten.
             * 
             * In this case, we simply return the current state of the Application and only
             * allow updates on ACP
             */
            if(OESApplicationService.isOESUser && app.Status__c == 'Submitted') {
                return app;
            }

            Contact applicant = AgentPortalServices.getContact(crmContactId, AgentPortalConstants.APPLICANT_PERSONA, AgentPortalConstants.USER_CONTEXT);
            if (app != null && applicant != null) {
                applicationREF = app.Name;
                // SFTG-3691 - Application may be reverted to Draft anytime before Agent Declaration, even after Student Acceptance
                if (AgentPortalConstants.DRAFT_STATUSES.contains(this.applicationStatus) 
                    && AgentPortalConstants.STATUSES_REVERTIBLE_TO_DRAFT.contains(app.Status__c)) {
                        app.Status__c = this.applicationStatus;
                        return app;
                }

                if (String.isNotBlank(app.Status__c) && AffiliationCheckService.SUBMITTED_STATUSES.contains(app.Status__c)) {
                    // For submitted applications, only Payments can be updated
                    if (payment != null && this.applicationStatus.equalsIgnoreCase(app.Status__c) ) { 
                        payment.applicationRecord = app;
                        payment.addPaymentDetailsToApplication();
                        return app;
                    } else {
                        throw new ApplicationException('Application is already in one of the Submitted statuses and cannot be edited');
                    }
                }
                app.applicant__c = applicant.Id;
                if (String.isNotBlank(applicationStatus) && !AffiliationCheckService.SUBMITTED_STATUSES.contains(applicationStatus)) {
                    app.status__c = applicationStatus;

                    // No changes other than timestamp allowed during Agent Declaration
                    if (applicationStatus.equalsIgnoreCase('Agent Declaration Accepted')) { 
                        app.Agent_Accepted_Timestamp__c = Datetime.now(); 
                        return app; 
                    }   
                }
                app.Application_Type__c = applicationType;
                app.is_Principal_Course_Transfer__c = isPrincipalCourseTransfer != null ? isPrincipalCourseTransfer : false;
                app.Student_Pass_Availability__c = resolveYesNoPicklist(isStudentPassAvailable);
                app.English_Language_Proficiency__c = resolveYesNoPicklist(englishLanguageProficiency);
                if (residencyStatus != null) {
                    if (residencyStatus.contains('.')) {
                        app.Residency_Sub_status__c = residencyStatus; // DOM-SUN.A
                    } else {
                        app.Residency_Sub_status__c = ''; 
                    }
                    app.Residency_Status__c = residencyStatus.split('\\.')[0]; // DOM-SUN
                }
                app.Sponsor_Name__c = sponsorScholarship;
                app.Sponsor_Scholarship_organisation__c = sponsorScholarship;
                app.Sponsorship_Status__c = sponsorStatus != null ? sponsorStatus.code : null;
                app.Credit_Intention__c = hasRequestForAdvancedStanding != null ? hasRequestForAdvancedStanding : false;
                app.Is_Sponsored__c = hasRequestForScholarship != null ? hasRequestForScholarship : false;
                app.Sponsorship_Type__c = app.Is_Sponsored__c ? 'Sponsorship' : 'No';
                app.Passport_Number__c = passportNumber;
                app.HasDisabilities__c = hasDisability != null ? hasDisability.code : null;
                app.Existing_Aus_disability_support__c = existingDisabilitySupport != null ? existingDisabilitySupport.code : null;
                app.External_Reference_Id__c = externalReferenceId;
                app.Delegator_Org_Unit_Code__c = delegatorOrgUnitCode;
                if (visa != null) {
                    visa.applicationRecord = app;
                    visa.addVisaDetailsToApplication();
                }
                if (!OESApplicationService.isOESUSer && payment != null) {
                    payment.applicationRecord = app;
                    payment.addPaymentDetailsToApplication();
                }else if (OESApplicationService.isOESUSer){
                    app.Fee_Payment__c = false;
                }
                app.Agent_Notes__c = agentNotes;
            } else {
                validationErrors.add('Invalid Application or Applicant Id');
            }
            return app;
        }
    }
    /**
    * @description CDM_Visa wrapper
    **/
    global class CDM_Visa {
        global CDM_Country citizenship; //Country of Citizenship
        global String visaNumber;
        global CDM_VisaType type;
        global String startDate;
        global String endDate;
        global CDM_Status hasRefusedEntry;
        global CDM_Status hasBreachedVisa;
        global CDM_Status hasMedicalIssues;
        global CDM_Status hasProtectionVisa;
        global CDM_Status hasConvictedOfCrime;
        global String immigrationOfficeIssued;
        global CDM_Country singleEntryVisaCountry;
        global Application__c applicationRecord;
        private List<String> validationErrors {
            get {
                if (validationErrors == null) { validationErrors = new List<String> (); }
                return validationErrors;
            } set;
        }
        /**
        * @description errorMessage 
        * @return String 
        **/
        global String errorMessage {
            get {
                if (validationErrors.isEmpty()) { return '';}
                return 'VISA SECTION ERRORS - ' + String.join(validationErrors, ', ');
            }
        }
        /**
        * @description addVisaDetailsToApplication
        **/
        global void addVisaDetailsToApplication() {
            if(OESApplicationService.isOESUser){//SFTG-3745
                if(String.isNotBlank(citizenship.uniqueCountryExternalId) ){
                    applicationRecord.Citizenship_Country__r = new Country_Attribute__c(uniqueCountryExternalId__c = citizenship.uniqueCountryExternalId);
                }
                else{
                    validationErrors.add('Applicant\'s Visa citizenship.uniqueCountryExternalId field is Blank');
                }
                if(singleEntryVisaCountry!=null && String.isNotBlank(singleEntryVisaCountry.uniqueCountryExternalId)){
                    applicationRecord.Single_Entry_Visa__r = new Country_Attribute__c(uniqueCountryExternalId__c = singleEntryVisaCountry.uniqueCountryExternalId);
                }else{
                    validationErrors.add('Applicant\'s Visa singleEntryVisaCountry.uniqueCountryExternalId field is Blank');
                }
            } else {
                applicationRecord.Citizenship_Country__c = citizenship != null? citizenship.crmRecordId : null;
                applicationRecord.Single_Entry_Visa__c = singleEntryVisaCountry != null ? singleEntryVisaCountry.crmRecordId : null;
            }
            applicationRecord.Visa_Number__c = visaNumber;
            applicationRecord.Visa_Type__c = type != null ? type.code : null;
            try {
                applicationRecord.Visa_Start_Date__c = startDate != null ? Date.valueOf(startDate) : null; 
            } catch(Exception e) {
                validationErrors.add('Visa Start Date is of invalid format. Only yyyy-MM-dd format is accepted');
            }
            try {
                applicationRecord.Visa_End_Date__c = endDate != null ? Date.valueOf(endDate) : null;
            } catch(Exception e) {
                validationErrors.add('Visa End Date is of invalid format. Only yyyy-MM-dd format is accepted');
            }
            applicationRecord.Refused_entry_visa_to_any_country__c = hasRefusedEntry != null ? hasRefusedEntry.code : null;
            applicationRecord.Breached_visa_condition__c = hasBreachedVisa != null ? hasBreachedVisa.code : null;
            applicationRecord.Medical_health_prevent_visa__c = hasMedicalIssues != null ? hasMedicalIssues.code : null;
            applicationRecord.Protection_visa_in_any_country__c = hasProtectionVisa != null ? hasProtectionVisa.code : null;
            applicationRecord.Convicted_of_crime_offence__c = hasConvictedOfCrime != null ? hasConvictedOfCrime.code : null;
            applicationRecord.Australian_Immigration_Office_Issued__c = immigrationOfficeIssued;
           
        } 


    }
    /** @description CDM_Qualification wrapper */
    global class CDM_Qualification {
        global String crmRecordId;
        global CDM_QualificationType type;
        global CDM_QualificationName name;
        global String startDate;
        global String endDate;
        global CDM_Country countryObtained;
        global String stateObtained;
        global CDM_Institution institution;
        global List<CDM_QualificationScore> scores;
        global String score;
        // global String statusKey;
        // global String levelOfCompletion;
        global String conferredDate;
        global String expectedDateOfCompletion;
        global String status;
        global String resultType;//SFTG-3704
        global String verificationStatus;//SFTG-3704
        global Boolean instructionInEnglish;
        global String qualificationComments;
        global String uniqueExternalId;
        /** @description isHistoric */
        global Boolean isHistoric {
            get {
                return isHistoric != null ? isHistoric : false;
            } set;
        }
        global Contact applicantRecord;
        private List<String> validationErrors {
            get {
                if (validationErrors == null) { validationErrors = new List<String> (); }
                return validationErrors;
            } set;
        }
        /** @description errorMessage */
        global String errorMessage {
            get {
                if (validationErrors.isEmpty()) { return ''; }
                return 'QUALIFICATION ERRORS - ' + String.join(validationErrors, ', ');
            }
        }
        /**
        * @description asQualificationRecord
        * @return Contact_Qualification__c 
        **/
        global Contact_Qualification__c asQualificationRecord() {
            Contact_Qualification__c conqual = new Contact_Qualification__c();
            if(OESApplicationService.isOESUser){//SFTG-3745
                conqual.Unique_External_Id__c = uniqueExternalId;//type.qualificationUid;
                if(countryObtained != null){
                    conqual.Qualification_Country__r = new Country_Attribute__c(uniqueCountryExternalId__c = countryObtained.uniqueCountryExternalId);
                }else{
                    validationErrors.add('countryObtained.uniqueCountryExternalId field is Blank for '+uniqueExternalId);
                }
            }else{
                conqual.Id = crmRecordId;
                conqual.Qualification_Country__c = countryObtained != null ? countryObtained.crmRecordId : null;
            }
            if (String.isBlank(crmRecordId)){ 
                conqual.Contact__c = applicantRecord.Id; 
            }
            
            if (institution != null) {
                if(OESApplicationService.isOESUser){
                    conqual.Institution_Code__c = institution.institutionCode; //SFTG-3745
                }else{
                    conqual.Institution_Code__c = institution.code;
                }
               
                if (String.isBlank(conqual.Institution_Code__c)) {
                    conqual.Other_Institution__c = institution.value;
                } else {
                    conqual.Institution_Name__c = institution.value;
                }
            }
            if (scores != null) {
                conqual.Listening__c = getScore(scores, 'Listening');
                conqual.Reading__c = getScore(scores, 'Reading');
                conqual.Writing__c = getScore(scores, 'Writing');
                conqual.Speaking__c = getScore(scores, 'Speaking');
            }
            conqual.Score__c = score;
            conqual.Status__c = status;
            if(OESApplicationService.isOESUser){
                conqual.Result_Type__c = resultType;//SFTG-3704
                conqual.Verification_Status__c = verificationStatus;//SFTG-3704
            }
            conqual.Instruction_in_English__c = instructionInEnglish != null ? instructionInEnglish : false;
            conqual.Other_Qualification_Comments__c = qualificationComments;
            try {
                if (conferredDate != null){
                    conqual.Date_Achieved__c = Date.valueOf(conferredDate);
                    conqual.isTestCompleted__c = true;
                } else {
                    conqual.Date_Achieved__c = null;
                    conqual.isTestCompleted__c = false;
                }
            } catch(Exception e) {
                validationErrors.add('Date Achieved is of invalid format. Only yyyy-MM-dd format is accepted');
            }
            try {
                conqual.Expected_date_of_completion__c = expectedDateOfCompletion != null ? Date.valueOf(expectedDateOfCompletion) : null;
            } catch(Exception e) {
                validationErrors.add('Expected date of completion is of invalid format. Only yyyy-MM-dd format is accepted');
            }
            if (type != null) {
                conqual.RecordTypeId = Schema.SObjectType.Contact_Qualification__c.getRecordTypeInfosByName().get(type.name).getRecordTypeId();
                if (conqual.RecordTypeId == null) {
                    validationErrors.add('Qualification Type invalid');
                } else {
                    if(!OESApplicationService.isOESUSer){
                        if (String.isBlank(type.crmRecordId)){
                            conqual.Other_Qualification__c = type.qualificationName;
                        } else {
                            conqual.Qualification__c = type.crmRecordId;
                        } 
                    }
                    if(OESApplicationService.isOESUSer){
                        if (String.isBlank(type.qualificationUid)){
                            conqual.Other_Qualification__c = type.qualificationName;
                        } else {
                            conqual.Qualification__r = new Qualification__c(Qualification_UID__c = type.qualificationUid);
                        } 
                    }

                    switch on type.name {
                        when 'Tertiary Education'{
                            conqual.First_Year_Enrolled__c = startDate;
                            conqual.Last_Year_Enrolled__c = endDate;
                            validateTertiaryQualification(conqual);
                        }
                        when 'Secondary Education' {
                            conqual.Score__c = '0';
                            conqual.State__c = stateObtained != null ? stateObtained : null;
                            if (endDate != null){ // SFTG-3700 Null Check, as Applicants may enter 'Expected Completion date' in My.App, which clears endDate
                            if (validateYear(endDate)) {
                                conqual.Year_of_Completion__c = endDate;
                            } else {
                                validationErrors.add('Invalid Year of completion');
                            }
                            }
                            validateSecondaryQualification(conqual);
                        }
                        when 'English Test' {
                            validateEnglishTest(conqual);
                        }
                        when 'Other Qualification' {
                            validateOtherQualification(conqual);
                        }
                    }
                }
            } else {
                validationErrors.add('Qualification Type cannot be empty');
            }
            return conqual;
        }
        /**
        * @description getScore
        * @param scores 
        * @param  type 
        * @return String 
        **/
        private String getScore(List<CDM_QualificationScore> scores, String type) {
            for (CDM_QualificationScore score: scores) {
                if (score.name.equalsIgnoreCase(type)) {
                    try{
                        if (String.isNotBlank(score.value)) {
                            Decimal d = Decimal.valueOf(score.value);
                            if (d < 0.0 || d >= 1000.0) { // SFTG-3688 Allow english scores between 0 & 1000 only
                                validationErrors.add('Invalid ' + score.name + ' score');
                            }
                        } 
                    } catch (Exception e) {
                        validationErrors.add('Invalid ' + score.name + ' score');
                    }
                    return score.value;
                }
            }
            return null;
        }
        private void validateTertiaryQualification(Contact_Qualification__c qual) {
            if (String.isBlank(qual.Qualification_Country__c) && !OESApplicationService.isOESUser) {
                validationErrors.add('Qualification country is empty');
            } else if(String.isBlank(qual.Qualification_Country__r.uniqueCountryExternalId__c  ) && OESApplicationService.isOESUser) {
                validationErrors.add('Qualification country is empty OES');
            }
 			if (String.isBlank(qual.Qualification__c) && String.isBlank(qual.Other_Qualification__c) && !OESApplicationService.isOESUser ) {
                validationErrors.add('Qualification Name is empty');
            }
            if (String.isBlank(qual.Institution_Code__c) && String.isBlank(qual.Other_Institution__c)) {
                validationErrors.add('Awarding Body/Institution is empty');
            }
            Integer firstYear;
            Integer lastYear;
            if (String.isBlank(qual.First_Year_Enrolled__c)) {
                validationErrors.add('First year of enrolment is empty ');
            } else {
                if (validateYear(qual.First_Year_Enrolled__c)) {
                    firstYear = Integer.valueOf(qual.First_Year_Enrolled__c);
                } else {
                    validationErrors.add('Invalid First year of enrolment');
                }
                
            }
            if (String.isBlank(qual.Last_Year_Enrolled__c)) {
                validationErrors.add('Last year of enrolment is empty');
            } else {
                if (validateYear(qual.Last_Year_Enrolled__c)) {
                    lastYear = Integer.valueOf(qual.Last_Year_Enrolled__c);
                } else {
                    validationErrors.add('Invalid Last year of enrolment');
                }
            }
            if (firstYear != null && lastYear != null && lastYear < firstYear) {
                validationErrors.add('Last year of enrolment is earlier than First year');
            }
            if (String.isBlank(qual.Status__c)) {
                validationErrors.add('Level of completion is empty');
            }
        }
        private void validateSecondaryQualification(Contact_Qualification__c qual) {
            if(String.isBlank(qual.Qualification_Country__c) && !OESApplicationService.isOESUser) {
                validationErrors.add('Qualification country is empty');
            } else {
                if (!OESApplicationService.isOESUser && countryObtained != null && countryObtained.value.equalsIgnoreCase('Australia') && String.isBlank(qual.State__c)) {
                    validationErrors.add('State is empty');
                }
            }

            if (String.isBlank(qual.Qualification__c) && String.isBlank(qual.Other_Qualification__c) && !OESApplicationService.isOESUser ) {
                validationErrors.add('Qualification Name is empty');
            }else if(OESApplicationService.isOESUser && String.isBlank(qual.Qualification__r.Qualification_UID__c)){
                validationErrors.add('Qualification Qualification_UID__c empty OES Secondary');
            }
            if (String.isBlank(qual.Institution_Code__c) && String.isBlank(qual.Other_Institution__c)) {
                validationErrors.add('School/Institution is empty');
            }
            if (String.isBlank(qual.Year_of_Completion__c) && qual.Expected_date_of_completion__c == null) {
                validationErrors.add('Either Year of completion/Expected completion date to be filled');
            } else {
                if (!String.isBlank(qual.Year_of_Completion__c) && Integer.valueOf(qual.Year_of_Completion__c) > Date.today().year()) {
                    validationErrors.add('Year of completion cannot be in the future');
                }
                if (qual.Expected_date_of_completion__c != null && qual.Expected_date_of_completion__c < Date.today()) {
                    validationErrors.add('Expected completion date is in the past');
                }
            }
        }
        private void validateEnglishTest(Contact_Qualification__c qual) {
            Set<String> setCumulativeScoreTests = new Set<String> {'IELTS (International English Language Testing Service)', 'Paper based TOEFL (Test of English as a Foreign Language)', 'Cambridge Linguaskill'};
            if (String.isBlank(qual.Qualification__c) && !OESApplicationService.isOESUser) {
                validationErrors.add('Qualification Name empty');
            }else if(OESApplicationService.isOESUser && String.isBlank(qual.Qualification__r.Qualification_UID__c)){
                validationErrors.add('Qualification Qualification_UID__c empty OES');
            }
            if (qual.Date_Achieved__c != null) {
                if (type.qualificationName != null 
                        && (setCumulativeScoreTests.contains(type.qualificationName))) {
                    if (qual.Score__c == null) { 
                        validationErrors.add('Score is empty');
                    } else {
                        try {
                            Decimal d = Decimal.valueOf(qual.Score__c);
                            if (d < 0.0 || d >= 1000.0) { // SFTG-3688 Allow english scores between 0 & 1000 only
                                validationErrors.add('Invalid Score');
                            }
                        } catch (Exception e) {
                            validationErrors.add('Invalid Score');
                        }
                    }
                }
                if (type.qualificationName != null 
                        && (!type.qualificationName.equalsIgnoreCase('Paper based TOEFL (Test of English as a Foreign Language)') && !type.qualificationName.equalsIgnoreCase('Monash English Language Placement test - MUELC only') && !type.qualificationName.equalsIgnoreCase('Cambridge Linguaskill'))) {
                    if (qual.Listening__c == null) { 
                        validationErrors.add('Listening Score is empty');
                    }
                    if (qual.Reading__c == null) { 
                        validationErrors.add('Reading Score is empty');
                    }
                    if (qual.Writing__c == null) { 
                        validationErrors.add('Writing Score is empty');
                    }
                    if (qual.Speaking__c == null) { 
                        validationErrors.add('Speaking Score is empty');
                    }
                }
            } else {
                if (qual.Expected_date_of_completion__c == null) {
                    validationErrors.add('Either Date obtained/Expected completion date to be filled');
                } else {
                    if (qual.Expected_date_of_completion__c < Date.today()) {
                        validationErrors.add('Expected completion date is in the past');
                    }
                }
            }
            if(OESApplicationService.isOESUSer){
                if(qual.Result_Type__c == null){
                    validationErrors.add('Result Type is empty');
                } else {
                    if(!qual.Result_Type__c.equalsIgnoreCase('Satisfactory')
                        && !qual.Result_Type__c.equalsIgnoreCase('Unsatisfactory')) {
                        validationErrors.add('Result Type Status must be Satisfactory or Unsatisfactory');
                    }
                }
                if(qual.Verification_Status__c == null){
                    validationErrors.add('Verification Status is empty');
                } else {
                    if (!qual.Verification_Status__c.equalsIgnoreCase('Verified')
                        && !qual.Verification_Status__c.equalsIgnoreCase('Unverified')
                        && !qual.Verification_Status__c.equalsIgnoreCase('Unknown')
                        && !qual.Verification_Status__c.equalsIgnoreCase('Invalid')
                        && !qual.Verification_Status__c.equalsIgnoreCase('Expired')) {
                        validationErrors.add('Verification Status must be Satisfactory or Unsatisfactory');
                    }
                }
            }
        }
        private void validateOtherQualification(Contact_Qualification__c qual) {
            if (String.isBlank(qual.Other_Qualification__c)) {
                validationErrors.add('Qualification Name is empty');
            }
            if (qual.Date_Achieved__c == null && qual.Expected_date_of_completion__c == null) {
                validationErrors.add('Either Date obtained/Expected completion date to be filled');
            } else {
                if (qual.Expected_date_of_completion__c < Date.today()) {
                    validationErrors.add('Expected completion date is in the past');
                }
            }
        }
        private boolean validateYear(String year) {
            try {
            	if (!year.isNumeric()) { return false; }
                Integer i = Integer.valueOf(year);
                if (i <1900 || i > 2099) { return false; } 
            } catch (Exception e) {
                return false;
            }
            return true;
        }
    }
    /** @description CDM_WorkExperience wrapper*/
    global class CDM_WorkExperience {
        global String crmRecordId;
        global String position;
        global String employer;
        global String startDate;
        global String endDate;
        global CDM_Country countryObtained;
        global CDM_Referee contactPerson;
        global String contactAddress;
        global String contactPhone;
        global String externalId;
        /** @description isHistoric */
        global Boolean isHistoric{
            get {
                return isHistoric != null ? isHistoric : false;
            }
        }
        private List<String> validationErrors {
            get {
                if (validationErrors == null) { validationErrors = new List<String> (); }
                return validationErrors;
            } set;
        }
        /** @description errorMessage */
        global String errorMessage {
            get {
                if (validationErrors.isEmpty()) { return ''; }
                return 'WORK EXPERIENCE ERRORS - ' + String.join(validationErrors, ', ');
            }
        }
        global Contact applicantRecord;
        /**
        * @description asExperienceRecord
        * @return Work_Experience__c 
        **/
        global Work_Experience__c asExperienceRecord() {
            Work_Experience__c workExp = new Work_Experience__c();
            workExp.Id = crmRecordId;
            if(OESApplicationService.isOESUser) {
                workExp.External_ID__c = externalId;
            }
            if (String.isBlank(crmRecordId)){
                workExp.Contact__c = applicantRecord.Id;
            }
            if (position != null) {
                workExp.Position__c = position;
            } else { 
                validationErrors.add('Position cannot be empty');
            }
            if (employer != null) {
                workExp.Employer_Name__c = employer;
            } else {
                validationErrors.add('Employer cannot be empty');
            }
            if (startDate != null){
                try {
                    workExp.Start_Date__c = Date.valueOf(startDate); 
                } catch(Exception e) {
                    validationErrors.add('Start Date is of invalid format. Only yyyy-MM-dd format is accepted');
                }
            } else {
                validationErrors.add('Start Date empty');
            }
            if (endDate != null){
                try {
                    workExp.End_Date__c = Date.valueOf(endDate);
                    if (workExp.Start_Date__c != null && workExp.End_Date__c < workExp.Start_Date__c) {
                        validationErrors.add('Start Date should not be later to the End Date.');
                    }
                } catch(Exception e) {
                    validationErrors.add('End Date is of invalid format. Only yyyy-MM-dd format is accepted');
                }
            }
            if(!OESApplicationService.isOESUser){
            if (countryObtained != null) {
                workExp.Country__c = countryObtained.crmRecordId;
            } else {
                validationErrors.add('Country cannot be empty');
            }
            }
            if(OESApplicationService.isOESUser){
                if(countryObtained != null){
                    workExp.Country__r = new Country_Attribute__c(uniqueCountryExternalId__c = countryObtained.uniqueCountryExternalId);
                }else{
                    validationErrors.add('countryObtained.uniqueCountryExternalId cannot be empty for '+externalId);
                }
            }
            workExp.Contact_Person_First_Name__c = contactPerson != null ? contactPerson.firstName : null;
            workExp.Contact_Person_Last_Name__c = contactPerson != null ? contactPerson.lastName : null;
            workExp.Contact_Person_Email__c = contactAddress;
            workExp.Contact_Person_Phone__c = contactPhone;
            return workExp;
        }
    }
        /**
        * @description CDM_ApplicationCoursePreference wrapper
        */
    global class CDM_ApplicationCoursePreference {
        /** @description crmRecordId */
        global String crmRecordId { get; set; }
        /** @description externalId */
        global String externalId { get; set; }
        /** @description courseOffering*/
        global CDM_CourseOffering courseOffering { get; set; }
        /** @description preference*/
        global Integer preference { get; set; }
        /** @description applicationRecord*/
        global Application__c applicationRecord { get; set; }

        /**
         * OES SCOPE - start
         */
        /** @description basisForAdmissionType*/
        global String basisForAdmissionType { get; set; }
        /** @description documentationStatus */
        global String documentationStatus { get; set; }
        /** @description outcomeStatus*/
        global String outcomeStatus { get; set; }
        /** @description entryQualificationStatus*/
        global String entryQualificationStatus { get; set; }
        /** @description offerResponseStatus*/
        global String offerResponseStatus { get; set; }
        /** @description offerDate*/
        global Date offerDate { get; set; }
        /** @description actualOfferResponseDate*/
        global Date actualOfferResponseDate { get; set; }
        /**
         * OES SCOPE - end
         */
        /** 
         * @description asACPRecord
         * @return Application_Course_Preference__c
        */
        global Application_Course_Preference__c asACPRecord() {

            Application_Course_Preference__c acp = new Application_Course_Preference__c();

            /**
             * OES SCOPE - start
             */
            if(OESApplicationService.isOESUser) {
                OESApplicationImpl.validateCdmAcp(this);
                acp = OESApplicationImpl.parseCdmToAcp(this);
            }
            /**
             * OES SCOPE - end
             */

            if (String.isNotBlank(crmRecordId)) {
                acp.id = crmRecordId;
            } 
            if (courseOffering != null) {
                if(OESApplicationService.isOESUser){
                    acp.Course_Offering__r = new Course_Offering__c( Course_Offering_UID__c = courseOffering.courseOfferingUid);
                }else{
                    acp.Course_Offering__c = courseOffering.crmRecordId;
                }
            } else {
                throw new ApplicantException('Course Offering cannot be empty.');
            }
            acp.Application__c = applicationRecord.id;
            acp.Applicant__c = applicationRecord.Applicant__c;
            acp.Preference_Number__c = '' + preference;
            return acp;
        }
    }
    /** @description CDM_CourseOffering*/
    global class CDM_CourseOffering {
        global String crmRecordId;
        global Application__c applicationRecord;
        global String courseOfferingUid;
    }
     /** @description CDM_QualificationScore*/
    global class CDM_QualificationScore {
        global String name;
        global String value;
    }
     /** @description CDM_QualificationType*/
    global class CDM_QualificationType {
        global String crmRecordId;
        global String code;
        global String name;
        global String qualificationName;
        global String qualificationUid;//SFTG-3745 uid for Contact Qualification
    }
     /** @description CDM_QualificationName*/
    global class CDM_QualificationName {
        global String code;
        global String name;
    }
     /** @description CDM_Country*/
    global class CDM_Country {
        global String uniqueCountryExternalId;
        global String crmRecordId;
        global String code;
        global String value;
    }
     /** @description CDM_VisaType*/
    global class CDM_VisaType {
        global String code;
        global String value;
    }
     /** @description CDM_Status*/
    global class CDM_Status {
        global String code;
        global String value;
    }
     /** @description CDM_Institution*/
    global class CDM_Institution {
        global String crmRecordId;
        global String code;
        global String value;
        global String institutionCode;
    }
    /** @description CDM_Referee*/
    global class CDM_Referee {
        global String firstName;
        global String lastName;
    }
    /** @description CDM_Payment*/
    global class CDM_Payment {
        global String mode;
        global String amount;
        global String transactionAmount;
        global String datePaid;
        global String transactionSource;
        global String transactionReference;
        global Boolean isPaid;
        global CDM_FeeWaiverCode feeWaiverCode;
        global Application__c applicationRecord;
        private List<String> validationErrors {
            get {
                if (validationErrors == null) { validationErrors = new List<String> (); }
                return validationErrors;
            } set;
        }
        /** @description errorMessage*/
        global String errorMessage {
            get {
                if (validationErrors.isEmpty()) { return '';}
                return 'PAYMENT SECTION ERRORS - ' + String.join(validationErrors, ', ');
            }
        }
        /**
        * @description addPaymentDetailsToApplication
        **/
        global void addPaymentDetailsToApplication() {
            if (mode != null){ applicationRecord.Fee_Payment_Mode__c = mode;}
            if (transactionSource != null){applicationRecord.Transaction_Source__c = transactionSource;}
            if (transactionReference != null){applicationRecord.Transaction_Reference__c = transactionReference;}
            if (isPaid != null){applicationRecord.Fee_Payment__c = isPaid;}
            if (feeWaiverCode != null){applicationRecord.Fee_Waiver_Code__c = feeWaiverCode.code;}
            try {
                if (datePaid != null){applicationRecord.Transaction_Date__c = Date.valueOf(datePaid);} 
            } catch(Exception e) {
                validationErrors.add('Date Paid (Transaction Date) is of invalid format. Only yyyy-MM-dd format is accepted');
            }
            try {
                if (amount != null){applicationRecord.Fee_Amount__c = Decimal.valueOf(amount);}
            } catch(Exception e) {
                validationErrors.add('Fee Amount is of invalid format.');
            }
            try {
                if (transactionAmount != null){applicationRecord.Transaction_Amount__c = Decimal.valueOf(transactionAmount); }
            } catch(Exception e) {
                validationErrors.add('Transaction Amount is of invalid format');
            }
        } 
    }
     /** @description CDM_FeeWaiverCode*/
    global class CDM_FeeWaiverCode {
        global String code;
        global String redeemed;
        global CDM_ValidityPeriod periodOfValidity;
    }
    /** @description CDM_ValidityPeriod*/
    global class CDM_ValidityPeriod {
        global String startDate;
        global String endDate;
    }
    /** @description CDM_Enquiry*/
    global class CDM_Enquiry {
        global string categoryLevel1;
        global string categoryLevel2;
        global string subject;
        global string content;
        global string origin;
        global string recordtypeDeveloperName;
        global string enquiryType;
        global List<CDM_Reference> references;
    }
    /** @description CDM_Reference*/
    global class CDM_Reference {
        global String key;
        global List<CDM_Value> value;
    }
    /** @description errorCDM_ValueMessage*/
    global class CDM_Value {
        global String id;
        global String description;
    }
    // Helper methods
    /** 
     * @description resolveYesNoPicklist
     * @return String
     * @param value 
     */
    global static String resolveYesNoPicklist(Boolean value) {
        return value != null ? (value ? 'Yes' : 'No') : null;
    }

    // Custom Exceptions
    /** @description ApplicantException*/
    public virtual class ApplicantException extends Exception {}
    /** @description ApplicationException*/
    public virtual class ApplicationException extends Exception {}
    /** @description ApplicationDocumentException*/
    public virtual class ApplicationDocumentException extends Exception {}
    /** @description AgentManagementException*/
    public virtual class AgentManagementException extends Exception {}
    /** @description BadRequestException*/
    public virtual class BadRequestException extends Exception {}
    
}