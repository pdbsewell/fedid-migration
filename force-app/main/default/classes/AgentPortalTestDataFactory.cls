/**
 * @description Test Data Factory for AgentPortal group (Admissions)
 * @author      Nick Guia
 * @date        18/09/2023       
 * @group       Admissions
 */
@SuppressWarnings('PMD.ClassNamingConventions')
@isTest (isParallel = false)
public without sharing class AgentPortalTestDataFactory {
    
    public static AgentPortalTestDataFactoryUtil util { //NOPMD
        get {
            if(util == null) {
                util = new AgentPortalTestDataFactoryUtil();
            }
            return util;
        } set;
    }

    // cache the agent PSG
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public static PermissionSetGroup AGENT_PERMISSIONSET_GROUP { //NOPMD
        get {
            if(AGENT_PERMISSIONSET_GROUP == null) {
                AGENT_PERMISSIONSET_GROUP = [SELECT Id, Status 
                                            FROM PermissionSetGroup 
                                            WHERE DeveloperName = :AgentPortalConstants.AGENT_PERMISSION_SET_GROUP
                                            LIMIT 1];
                if (AGENT_PERMISSIONSET_GROUP.Status != 'Updated') {
                    Test.calculatePermissionSetGroup(AGENT_PERMISSIONSET_GROUP.Id);
                }
            }
            return AGENT_PERMISSIONSET_GROUP;
        } set;
    }

    // cache the agent profile
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public static Profile AGENT_PROFILE { //NOPMD
        get {
            if(AGENT_PROFILE == null) {
                User usr = new User();
                usr.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1].Id;                   
                usr.LastName = 'Test';
                usr.Email = 'test@test.com';
                usr.Username = 'test@test.com' + System.currentTimeMillis();
                usr.CompanyName = 'Salesforce';
                usr.Title = 'Title';
                usr.Alias = 'Roger';
                usr.TimeZoneSidKey ='Australia/Sydney';
                usr.LocaleSidKey ='en_AU';
                usr.EmailEncodingKey ='ISO-8859-1';
                usr.LanguageLocaleKey ='en_US';

                System.runAs(usr) {
                    AGENT_PROFILE = [SELECT Id 
                                    FROM Profile 
                                    WHERE Name = :AgentPortalConstants.AGENT_PROFILE];
                }
            }
            return AGENT_PROFILE;
        } set;
    }

    /**
     * @description generate a country attribute record
     * @param callistaCode 
     * @param countryName  
     * @return `Country_Attribute__c`
     * @example
     *  Country_Attribute__c country = factory.createCountryAttribute(BDPConstants.AUSTRALIA_CALLISTA_CODE, 'Australia');
     */
    public Country_Attribute__c createCountryAttribute(String callistaCode, String countryName) {
        return new Country_Attribute__c (
            Name = countryName,
            Country__c = countryName,
            Callista_Code__c = callistaCode,
            Callista_Country__c = countryName // assumed to keep test straightforward
        );
    }

    /**
     * @description create an Agency Account. Typically required to create an Agent Contact
     * @param country related country
     * @return      `Account`
     */
    public Account createAgencyAccount(Country_Attribute__c country) {
        return new Account(
            Name = 'TestAgencyAccount', 
            Callista_Org_Unit_Code__c = util.generateRandomString(10),
            Monash_AM_Campus__c = 'Australia', 
            Status__c = 'Appointed', 
            City__c = 'Perth',
            Country_Lookup__c = country.id,
            Post_Code__c = '2170', 
            Email__c = 'Agent@TestAgencyAccount.com.domain',
            Record_Type_Dup__c = 'Agency',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency').getRecordTypeId()
        );
    }

    /**
     * @description create an Agent Contact. Typically required to create an Agent User
     * @param agencyAccount
     * @return `Contact`
     */
    public Contact createAgentContact(Account agencyAccount) {
        return new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Agency_Contact').getRecordTypeId(),
            FirstName = 'TestFirstName', 
            LastName = 'TestLastName', 
            AccountId = agencyAccount.Id, 
            Email = 'TestEmail@testemail.com', 
            Agency_Contact_Roles__c = 'Branch Manager; Delegated Admin'
        );
    }

    /**
     * @description create an Applicant contact
     * @return `Contact`
     */
    public Contact createApplicantContact() {
        Integer currentCount = util.counter;
        return new Contact(
            LastName = 'ApplicantLName' + currentCount,
            FirstName = 'ApplicantFName'+ currentCount,
            Email = 'testEmail' + currentCount+ '@test.edu',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId(),
            Person_ID_unique__c = util.generateRandomString(9),
			Personal_email__c = 'testEmail' + currentCount+ '@test.edu',
            Birthdate = Date.today().addYears(- 20),
            Gender__c = 'M',
            Last_Name__c = 'ApplicantLName' + currentCount,
            Phone = '11112222',
            MailingStreet = '123 Test St',
            MailingCity = 'Melbourne',
            MailingCountry = 'Australia',
            MailingState = 'Victoria',
            MailingPostalCode = '3000',
            Residency_Status__c = 'DOM-AUS',
            Mobilephone = '04444444444'
        );
    }


    /**
     * @description create an Applicant type Affiliation
     * @param applicant related contact
     * @param agency    related Agency
     * @return `Affiliation__c`
     */
    public Affiliation__c createApplicantAffiliation(Contact applicant, Account agency) {
        return new Affiliation__c(
            Contact__c = applicant.Id,
            Account__c = agency.Id,
            RecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName().get('Applicant').getRecordTypeId(),
            Start_Date__c = Date.today(),
            Share_Contact_to_Account_Role__c = 'Edit'
        );
    }

    /**
     * @description create an Agent User.
     * @param agentContact 
     * @return `User`
     */
    public User createAgentUser(Contact agentContact) {
        User agentUser = new User();
        agentUser.ContactId = agentContact.Id; 
        agentUser.ProfileId = AGENT_PROFILE.Id;
        agentUser.Username = util.makeUsernameUnique('testAgentLastName@TestEmail.com.domain');
        agentUser.email = 'testAgentLastName@TestEmail.com';
        agentUser.LastName ='test';
        agentUser.Alias ='test';
        agentUser.isActive = true;
        agentUser.TimeZoneSidKey ='Australia/Sydney';
        agentUser.LocaleSidKey ='en_AU';
        agentUser.EmailEncodingKey ='ISO-8859-1';
        agentUser.LanguageLocaleKey ='en_US';
        return agentUser;
    }

    /**
     * @description create a MyApp User.
     * @param applicant 
     * @return `User`
     */
    public User createMyAppUser(Contact applicant) {
        return new ApplicationService().generateMyAppUser(applicant);
    }

    /**
     * @description assigns the required permission set group to the agent
     * @param agentUser 
     * @return `PermissionSetAssignment`
     */
    public PermissionSetAssignment createAgentPermissionSetAssignment(User agentUser) {
        return new PermissionSetAssignment(
            AssigneeId = agentUser.Id,
            PermissionSetGroupId = AGENT_PERMISSIONSET_GROUP.Id
        );
    }

    /**
     * @description create test course
     * @return `Course__c`
     */
    public static Course__c createCourse() {
        Course__c course = new Course__c();
        course.Name = 'E6001';
        course.Type__c = 'Course-All';
        course.Course_Code__c = 'E6001_11';
        course.Version__c = '11';
        return course;
    }

    /**
     * @description create test course offering
     * @param course parent course
     * @return `Course_Offering__c`
     */
    public Course_Offering__c createCourseOffering(Course__c course) {
        Course_Offering__c courseOffering = new Course_Offering__c();
        courseOffering.Course__c = course.Id;
        courseOffering.Course_Code__c = course.Course_Code__c;
        courseOffering.Academic_CI_Sequence_Number__c = 1;
        courseOffering.Academic_Calendar_Type__c = '2019';
        courseOffering.Admission_CI_Sequence_Number__c = 1;
        courseOffering.Admission_Calendar_Type__c = 'ADM';
        courseOffering.Attendance_Mode__c = 'SCG';
        courseOffering.Attendance_Type__c = 'PT';
        courseOffering.Course_Title__c = 'Master Of Something';
        courseOffering.Course_Version_Number__c = 1;
        courseOffering.Admission_Calendar_Description__c = 'July-2019';
        courseOffering.Attendance_Mode_Description__c = 'On Campus';
        courseOffering.Attendance_Type_Description__c = 'FULL TIME';
        courseOffering.Citizenship_Type__c = 'DOM-AUS';
        courseOffering.Course_Type_Group__c = 'OPG';
        courseOffering.Location_Code__c = 'CLAYTON';
        courseOffering.Type_of_Place_Description__c = 'Test type of place';
        courseOffering.Type_of_Place_Code__c = 'PC001';
        courseOffering.Unit_Set_Code__c = 'MM00000';
        courseOffering.Unit_Set_Description__c = 'set description';
        courseOffering.Active__c = true;
        return courseOffering;
    }
    
    /**
     * @description create a test application record
     * // TODO : the quality of this test data can further be improved
     * @param contactId 
     * @return `Application__c`
     */
    public Application__c createApplication(Id contactId) {
        return new Application__c(
            Source_System__c =  ApplicationService.getSourceSystem(), 
            Status__c = 'Draft', 
            Agent_Org_Unit_Code__c = 'TSTAG',
            Applicant__c = contactId,
            Disability_Opt_In__c = 'Yes'
        );
    }

    /**
     * @description create a test ACP record
     * @param applicationId    
     * @param contactId 
     * @param courseOfferingId 
     * @return `Application_Course_Preference__c`
     */
    public Application_Course_Preference__c createACP(Id applicationId, Id contactId, Id courseOfferingId) {
        return new Application_Course_Preference__c (
            Name = 'ACP-' + util.counter,
            Application__c = applicationId,
            Applicant__c = contactId,
            Course_Offering__c = courseOfferingId
        );
    }
    
    /**
     * @description create an ACP   
     * @param applicationId parent Application Id
     * @return `Application_Course_Preference__c`
     */
    public Application_Course_Preference__c createACP(Id applicationId) {
        return new Application_Course_Preference__c (
            Name = 'ACP-' + util.counter,
            Application__c = applicationId
        );
    }
    
    /**
     * @description create the environment settings record
     * @return `Environment_Setting__c`
     */
    public Environment_Settings__c createEnvironmentSettings() {
        return new Environment_Settings__c(
            AgentPortal_Affiliation__c = true, // Enables APNG Affiliations
            CampusLocation_Australia__c = true, // Allows Australia Applications
            CampusLocation_Malaysia__c = true, // Allows Malaysia Applications
            CampusLocation_Indonesia__c = true, // Allows Indonesia Applications
            StudyType_Australia__c = 'Coursework, Exchange', // Allowed Study Types for Australian Applications
            StudyType_Malaysia__c = 'Coursework', // Allowed Study Types for Malaysian Applications
            StudyType_Indonesia__c = 'Coursework',  // Allowed Study Types for Indonesian Applications
            ResidencyStatus_DOMAUS__c =true // Allowed Citizenship Type
        );
    }
    
    /**
     * @description create the Feature Switch record
     * @return `Feature_Switch__c`
     */
    public Feature_Switch__c createFeatureSwitch() {
        return new Feature_Switch__c(
        	Align_Application_Owner__c = true, // Enables setting of Application's Owner to the Agent
        	Align_ACP_Owner__c = true // Enables setting of ACP's owner to the Agent
        );
    }
    
    /**
     * @description create the Data Owners records
     * @return List `SystemDataOwnersSetting__c`
     */
    public List<SystemDataOwnersSetting__c> createDataOwners() {
        List<SystemDataOwnersSetting__c> dataOwnerList = new List<SystemDataOwnersSetting__c>();
        // Account Data Owner
        SystemDataOwnersSetting__c accountDataOwner = new SystemDataOwnersSetting__c();
        accountDataOwner.Name = 'Account System Data Owner';
        accountDataOwner.FederationId__c = 'randomacc123';
        accountDataOwner.object__c = 'Account'; 
        dataOwnerList.add(accountDataOwner);
        // Contact Data Owner
        SystemDataOwnersSetting__c contactDataOwner = new SystemDataOwnersSetting__c();
        contactDataOwner.Name = 'Contact System Data Owner';
        contactDataOwner.FederationId__c = 'randomacc345';
        contactDataOwner.object__c = 'Contact';
        dataOwnerList.add(contactDataOwner);
        // System Owner
        SystemDataOwnersSetting__c systemownerDetail = new SystemDataOwnersSetting__c();
        systemownerDetail.Name = 'SystemOwnerDetail';
        systemownerDetail.ValidRecordTypes__c = 'applicant';
        systemownerDetail.ByPassUser__c = '0012A00000abcde'; 
        DataOwnerList.add(systemownerDetail);
        return DataOwnerList;
    }
    
    /**
     * @description create the Agent Onboarding Settings record
     * @return `Agent_Onboarding_Settings__c`
     */
    public Agent_Onboarding_Settings__c createAgentOnboardingSettings() {
        return new Agent_Onboarding_Settings__c(
            Role_RT_Developer_Name__c = 'Agency_Contact_Role' // Enables Role Object Base PB to update the Agency's (Account) related object Role__c based on this record type (Agencies)
        );
    }    
    
    /**
     * @description create the Agent Payload
     * @return `AgentPortalPayload.CDM_Agent`
     */
    public AgentPortalPayload.CDM_Agent createAgentPayload() {
        AgentPortalPayload.CDM_Agent agentPayload = new AgentPortalPayload.CDM_Agent();
        agentPayload.firstName = 'frank';
        agentPayload.lastName = 'Seven';
        AgentPortalPayload.Email officialEmail = new AgentPortalPayload.Email();
        officialEmail.type = 'Official';
        officialEmail.email = 'frrank.7@testemail.com';
        agentPayload.email= new List<AgentPortalPayload.Email> {officialEmail};
        agentPayload.roles = new List<String> {'Counsellor'};
        return agentPayload;
    }
    /**
     * @description createAgentPayload creates a REST Request Payload based on AgentPortalPayload.CreateAgentRequest
     * @return  return AgentPortalPayload.CreateAgentRequest
     */
    public AgentPortalPayload.CreateAgentRequest createAgentRequest(){
        Map<String, String> params = new Map<String, String> ();
        params.put('requestType','createContact');
        AgentPortalPayload.CreateAgentRequest car = new AgentPortalPayload.CreateAgentRequest(params);
        car.agent = createAgentPayload();
        return car;
    }
    /**
     * @description manageAgentPayload creates a REST Request Payload based on AgentPortalPayload.ManageAgentRequest
     * @param  agentRecordID agentRecordID the Agent's Contact or User ID which has to be updated
     * @return  return AgentPortalPayload.ManageAgentRequest
     */
    public AgentPortalPayload.ManageAgentRequest manageAgentRequest(String agentRecordID){
        AgentPortalPayload.ManageAgentRequest mar = new AgentPortalPayload.ManageAgentRequest();
        mar.agent = new AgentPortalPayload.CDM_Agent();
        mar.agent.crmRecordId = agentRecordID;
        return mar;
    }  
    /**
     * @description     create an Agent Enquiry test data
     *  Assumptions:
     *  - External_Stakeholder__c will be populated by the Case Trigger
     * @param applicant applicant Contact record
     * @param agent     the Agent contact
     * @param acp       ACP of the applicant
     * @return          `Case`
     */
    public Case createAgentEnquiry(Contact applicant, Contact agent, Application_Course_Preference__c acp) {
        return new Case(
            Origin = 'Web - Agent Portal',
            Status = 'Open',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admissions').getRecordTypeId(),
            Enquiry_Type__c = 'Future Course',
            Category_Level_1__c = 'Request',
            Category_Level_2__c = 'Packaged courses',
            Description = 'Test Enquiry about a Client Question',
            ContactId = applicant.Id,
            Application_Course_Preference__c = acp?.Id,
            Initiated_By__c = agent.Id
        );
    }

    /**
     * @description create test CaseFeeds
     * @param parentCase the parent Case of the CaseFeeds
     * @param num : number of CaseFeeds to be created
     * @return `List<FeedItem>`
     */
    public List<FeedItem> createCaseFeeds(Case parentCase, Integer num) {
        List<FeedItem> recList = new List<FeedItem>();
        for(Integer i = 0; i < num; i++) {
            FeedItem rec = new FeedItem();
            rec.Body = '<p>sample agent post</p>'+util.counter;
            rec.Visibility = 'AllUsers';
            rec.Type = 'TextPost';
            rec.ParentId = parentCase.Id;
            recList.add(rec);
        }
        return recList;
    }

    /**
     * @description Utility class for the test data factory. Contains various
     * methods to help with setting up test data
     */
    public without sharing class AgentPortalTestDataFactoryUtil {

        public Integer counter {
            get {
                counter = (counter == null) ? 0 : (counter+1); // for some reason, counter++ doesn't work
                return counter;
            } set;
        }
        private User adminUser;

        private final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        
        @SuppressWarnings('PMD.EmptyStatementBlock')
        @TestVisible
        private AgentPortalTestDataFactoryUtil() { }

        /**
         * @description adds a unique prefix to the provided username to prevent DUPLICATE_USERNAME errors on test classes
         *  - an arbitrary counter + org ID + Datetime.now().getTime()
         * @param userName 
         * @return `String`
         */
        public String makeUsernameUnique(String userName) {
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now().getTime());
            String uniqueUser = '' + counter + orgId + dateString + userName;
            return uniqueUser;
        }

        /**
         * @description  generates a random string
         * @param len : number of characters in the generated string
         * @return `String`
         */
        public String generateRandomString(Integer len) {
            String randStr = '';
            while (randStr.length() < len) {
                Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
                randStr += chars.substring(idx, idx+1);
            }
            return randStr;
        }

        /**
         * @description Utility method for querying created user from test setup.
         * TODO : the filters here / setup data can be further enhanced
         * @return `User`
         */
        public User getAgentUser() {
            return [SELECT Id, Username, Contact.Id, Contact.Email, Contact.AccountId 
                    FROM User 
                    WHERE Username LIKE '%testAgentLastName@TestEmail.com.domain%' 
                    AND ProfileId = :AGENT_PROFILE.Id
                    LIMIT 1 ];
        }

        /**
         * @description utility class to query and cache an admin user.
         * Typically required for creating up setup objects
         * @return `User`
         */
        public User getAdminUser() {
            if(this.adminUser == null) {
                List<User> admins = [SELECT Id FROM User 
                                WHERE Profile.Name = 'System Administrator' 
                                AND IsActive = true 
                                LIMIT 1];
            
                if(admins.size() > 0) {
                    this.adminUser = admins[0];
                } else {
                    Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
                    User adminUser = (User)TestDataFactory.createSObject(new User());
                    adminUser.ProfileId = profileId;
                    adminUser.Username = 'agentPortalSystemAdmin@example.com';
                    System.runAs(new User(Id = UserInfo.getUserId())) {  // to avoid mixed DML
                        insert adminUser;
                    }
                    this.adminUser = adminUser;
                }
            }
            return this.adminUser;
        }
    }
}