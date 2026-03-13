/**
 * @description Test Data Builder for AgentPortal group (Admissions). This is responsible
 *              for assembling the test data dependencies.
 *              - One weakness of this design is that certain (similar) SObjects may be inserted repetitively
 *              depending on how it's being invoked from the test class. Use with caution and highly recommend
 *              to mute the Triggers (whenever possible) when running these test builds. 
 *              - Avoid running in loops since this class inserts the records immediately.
 * @author      Nick Guia
 * @date        18/09/2023       
 * @group       Admissions
 * @example 
 *  AgentPortalTestDataBuilder.AgentPortalUser portalUser = new AgentPortalTestDataBuilder.AgentPortalUser().build();
 */

@isTest(isParallel = false)
public class AgentPortalTestDataBuilder {

    @SuppressWarnings('PMD')
    public static AgentPortalTestDataFactory factory {
        get {
            if(factory == null) {
                factory = new AgentPortalTestDataFactory();
            }
            return factory;
        }
        set;
    }

    /**
     * @description for a "quick create" of a single Agent Portal User.
     */
    public class AgentPortalUser {

        public Country_Attribute__c country { get; set; }
        public Account acc { get; set; }
        public Contact con { get; set; }
        public User testUser { get; set; }
        public PermissionSetAssignment psa { get; set; }

        /**
         * @description Build and resolve dependencies
         * @return `AgentPortalUser`
         */
        public AgentPortalUser build() {

            this.country = factory.createCountryAttribute(BDPConstants.AUSTRALIA_CALLISTA_CODE, 'AUSTRALIA');
            upsert this.country; // do not create duplicates based on Callista_Code__c

            this.acc = factory.createAgencyAccount(this.country);
            insert this.acc;

            this.con = factory.createAgentContact(this.acc);
            insert this.con;

            // use runAs to avoid DML exception
            System.runAs(new User(Id = UserInfo.getUserId())) {
                this.testUser = factory.createAgentUser(this.con);
                insert this.testUser;

                this.psa = factory.createAgentPermissionSetAssignment(this.testUser);
                insert psa;
            }

            return this;
        }
    }

    /**
     * @description create an Applicant => Application => ACP relationship
     * dependent on:
     *  -   Agency account
     */
    public class Application {

        public Account applicantAccount { get; set; }
        public Contact applicant { get; set; }
        public Affiliation__c applicantAffiliation { get; set; }
        public Course_offering__c courseOffering { get; set; }
        public Application_Course_Preference__c acp { get; set; }
        public User myAppUser { get; set; }
        public Application__c app { get; set; }

        /**
         * dependencies
         */
        @TestVisible
        private AgentPortalUser apUser {    
            get {
            if(apUser == null) {
                apUser = new AgentPortalUser().build();
            }
            return apUser;
            } set; }
        
        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Application() { }

        /**
         * @description inject own AgentPortalUser
         * @param apUser AgentPortalUser
         * @return `Application`
         */
        public Application withAgent(AgentPortalUser apUser) {
            this.apUser = apUser;
            return this;
        }
        /**
         * @description inject own contact
         * @param con Contact
         * @return `Application`
         */
        public Application withApplicant(Contact con) {
            this.applicant = con;
            return this;
        }
        /**
         * @description inject own Application
         * @param a Application__c
         * @return `Application`
         */
        public Application withApplication(Application__c a) {
            this.app = a;
            return this;
        }
        /**
         * @description assigns course offerings. Implies that an ACP will have to be created too
         * @param co Course_Offering__c
         * @return `Application`
         */
        public Application withCourseOffering(Course_Offering__c co) {
            this.courseOffering = co;
            return this;
        }

        /**
         * @description Build and resolve dependencies
         * @return `Application`
         */
        public Application build() {

            /**
             * STEP 1 : build contact
             */
            if(this.applicant == null) {
                this.applicant = factory.createApplicantContact();
            }

            /**
             * STEP 2 : build account and affiliation as a System Admin
             */
            System.runAs(AgentPortalTestDataFactory.util.getAdminUser()) { // to avoid Error: 'Portal account owner must have a role'
                // create account for the applicant contact and assign an admin user as the owner
                this.applicantAccount = new Account(
                    Name = applicant.FirstName + ' ' + applicant.LastName,
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                    .get(AccountServices.ACCOUNT_INDIVIDUAL_TYPE)
                                    .getRecordTypeId(),
                    OwnerId = AgentPortalTestDataFactory.util.getAdminUser().Id
                );
                insert this.applicantAccount;

                // link account and contact
                this.applicant.accountId = this.applicantAccount.Id;
                insert this.applicant;

                // link parent contact, and account (agency) affiliation
                this.applicantAffiliation = factory.createApplicantAffiliation(this.applicant, this.apUser.acc);
                insert this.applicantAffiliation;
            }

            /**
             * STEP 3 : AgentPortalUser DAO
             */
            if(this.apUser == null) {
                this.apUser = new AgentPortalUser().build();
            }

            /**
             * STEP 4 : build Application as an Agent
             */
            System.runAs(this.apUser.testUser) {

                if(this.app == null) {
                    app = factory.createApplication(this.applicant.Id);
                }
                // link related agency and agent
                app.Agent_Org_Unit_Code__c = this.apUser.acc.Callista_Org_Unit_Code__c;
                app.Agent__c = this.apUser.acc.Id;

                if(this.app.Id == null) {
                    insert this.app;
                }

                /**
                 * STEP 5 : Build Course Offerings and ACPs
                 */
                if(this.courseOffering != null) {
                    
                    if(this.courseOffering.Id == null) {
                        insert this.courseOffering;
                    }

                    // create an ACP
                    this.acp = factory.createACP(this.app.Id, this.applicant.Id, this.courseOffering.Id);
                    insert this.acp;
                }
            }
            return this;
        }

        /**
         * @description option to enable MyApp User access of the applicant
         * @return `Application`
         */
        public Application enableMyAppUser() {
            // use runAs to avoid DML exception
            System.runAs(new User(Id = UserInfo.getUserId())) {
                this.myAppUser = factory.createMyAppUser(this.applicant);
                insert myAppUser;
            }
            return this;
        }
    }

    /**
     * @description simulates the creation of Enquiry records
     * with reference to its dependencies within the APNG Enquiry management process
     * dependent on:
     *  -   Agency account
     */
    public class AgentEnquiry {

        public Case caseRec { get; set; }
        public List<FeedItem> caseFeedList { get; set; }
        public Integer caseFeedNumber = 1;

        // dependencies
        @TestVisible
        private AgentPortalUser apUser {
            get {
                if(apUser == null) {
                    apUser = new AgentPortalUser().build();
                }
                return apUser;
            }
            set;
        }
        @TestVisible
        private Application applicationDetails {
            get {
                if(applicationDetails == null) {
                    applicationDetails = new Application().withAgent(this.apUser).build();
                }
                return applicationDetails;
            }
            set;
        }
        /**
         * @description constructor
         */
        public AgentEnquiry() {
            this.caseFeedList = new List<FeedItem>();
        }
        /**
         * @description add case feed
         * @param num number of case feeds to be created
         * @return `AgentEnquiry`
         */
        public AgentEnquiry withCaseFeed(Integer num) {
            this.caseFeedNumber = num;
            return this;
        }
        /**
         * @description agent details are required to link with an Enquiry + insert the Enquiry as the Agent
         * @return `AgentEnquiry`
         */
        public AgentEnquiry withAgent(AgentPortalUser apUser) {
            this.apUser = apUser;
            return this;
        }
        /**
         * @description applicant is required to link with an Enquiry
         * of providing applicant details outside this class, ensure that
         * the dependent Agent has record access to the applicant contact
         * so it can be linked to the enquiry
         * @return `AgentEnquiry`
         */
        public AgentEnquiry withApplication(Application application) {
            this.applicationDetails = application;
            return this;
        }
        /**
         * @description Build and resolve dependencies
         * @return `AgentEnquiry`
         */
        public AgentEnquiry build() {

            // insert the enquiry as the agent
            System.runAs(this.apUser.testUser) {

                // link applicant, agent, and ACP to the enquiry
                this.caseRec = factory.createAgentEnquiry(this.applicationDetails.applicant, this.apUser.con, this.applicationDetails.acp);
                this.caseRec.External_Stakeholder__c = this.apUser.acc.Id;
                this.caseRec.Initiated_by__c = this.apUser.con.Id;
                this.caseRec.is_Visible_to_External_Stakeholder__c = true;
                insert this.caseRec;

                // link casefeed to case
                this.caseFeedList = factory.createCaseFeeds(this.caseRec, this.caseFeedNumber);
                insert this.caseFeedList;
            }

            return this;
        }
    }


    /**
     * @description Class for creating REST Request/Response 
     */
    public class AgentPayload {
        RestRequest request {get; set;}
        RestResponse response {get; set;}
        public AgentPayload() {
            this.request = new RestRequest();
            this.response = new RestResponse();
            RestContext.request = this.request;
            RestContext.response = this.response;
        }
        /**
         * @description setHttpMethod sets the HttpMethod parameter of the REST Request
         * @param  httpMethod String - can be POST or PATCH or any HttpMethod
         * @return return this instance
         */
        public AgentPayload setHttpMethod(String httpMethod) {
            this.request.httpMethod = httpMethod;
            return this;
        }
        /**
         * @description setParam sets the Parameters for the REST Request
         * @param  key   key for the request parameter
         * @param  value value for the request parameter
         * @return       return this instance
         */
        public AgentPayload setParam(String key, String value) {
            this.request.params.put(key, value);
            return this;
        }
        /**
         * @description setRequestBody set the REST request's body
         * @param  requestBody requestBody Any Request/Response payload from Factory
         * @return             return this instance
         */
        public AgentPayload setRequestBody(Object requestBody) {
            this.request.requestBody = Blob.valueOf(JSON.serialize(requestBody, true));
            return this;
        }
        /**
         * @description getResponse sets the HttpMethod parameter of the REST Request
         * @return return the REST response as a String
         */
        public string getResponse() {
            return this.response?.responseBody.toString();
        }
    }
}