/**
 * @Class              : AgentPortalServices.cls
 * @Description        : Services class for all Agent Portal related communications 
 * @Author             : Vinothraja
 * @Group              : Admissions
 * @Revision           : 2023-02-21  Vinothraja - Created 
 *                       2024-02-25  Martin Cadman - Changed sharing of AgencyWrapper inner class to allow JWT users (agents) access to user records
 */
public with sharing class AgentPortalServices {

    // The branch manager will become the owner if a non-agency owner is in place    
    private static final String AGENTROLE = 'Branch Manager';
    public static final RunSystemContext systemContext = new RunSystemContext();

    /**
     * @author      Vinothraja
     * @description Creates an Account and Contact under an Agent specified by the OrgId
     * @return      The newly created Applicant (Contact)
     * @revision    2023-02-21 - Vinothraja - Created
     * 2023-07-03   Vinothraja      Enhanced to use Contact Point records, instead of directly updating the Contact = WILL NOT CREATE CPA
     */
    public static Contact createApplicant(Contact con, String agentUserId) {
        // prepare contact's account
        Account acc = new Account(Name = (String.isBlank(con.first_Name__c)?'':con.first_Name__c + ' ') + con.last_Name__c,
                                                        OwnerId = agentUserId, // Set the requesting Agent as the Owner
                                                        RecordTypeId = CommonServices.RecordTypeId('Account', AccountServices.ACCOUNT_INDIVIDUAL_TYPE));
        
        // Create savepoint - If Contact fails creation, Account also to be rolled back
        Savepoint createApplicantSavePoint = Database.setSavepoint();
        try {
            insert acc;

            // prepare contact - remove any private contact info
            String mobilePhone = con.MobilePhone;
            String email = con.Personal_Email__c;
            con = (Contact) (stripPrivateDetailsFromContact(con)).get('CONTACT');
            con.AccountId = acc.Id;
            con.OwnerId = agentUserId; // Set the requesting Agent as the Owner
            insert con;
            // create contact point records - without affiliations
            BaseClass.ResultSet rs = createCPA(con, null, email, mobilePhone, null, null, null);

            // Query inserted Contact ( mainly for CRM_ID__c ) to be used in the Response
            String clause = 'id = \'' + con.id + '\'';
            Set<String> fieldset = new Set<String> (AgentPortalConstants.CREATE_FIELDS_APPLICANT.split(','));
            String query = DynamicSoqlBuilder.getInstance()
                                                .showSOQLStatement(true)
                                                .setEnforced(true)
                                                .querySObject(String.escapeSingleQuotes('Contact'))
                                                .queryFields(fieldset)
                                                .getQuery(String.escapeSingleQuotes(clause));
            con = (Contact) (Database.query(query)[0]);
        } catch(Exception ex) {
            Database.rollback(createApplicantSavePoint);
            throw ex;
        }
        return con;
    }
    /**
     * @author      Vinothraja
     * @description Searches for Contacts(Applicants) based on search Criteria
     * @param       Contact - Contact object containing the search criteria
     * @param       PageSize - 
     * @return      String 
     * @revision    2023-03-09 - Vinothraja - Created
     */
    public static List<Contact> searchApplicants(String name, Integer pageSize, Integer pageOffset) {
        User agent = getUser(UserInfo.getUserId());
        // Query for Applicants 
        String clause = '(full_name__c LIKE  \'%' + String.escapeSingleQuotes(name) + '%\' OR Previous_Surname__c  LIKE  \'%' + String.escapeSingleQuotes(name) + '%\' OR First_name__c  LIKE  \'%' + String.escapeSingleQuotes(name) + '%\' )';
        clause += ' AND RecordType.DeveloperName NOT IN (\'Agency_Contact\', \'Partner\')';
        String query = 'SELECT {0} ';
        query += ' FROM Contact WHERE {1}';
        query += ' ORDER BY lastModifiedDate DESC ';
        query += ' LIMIT ' + pageSize;
        query += ' OFFSET ' + pageOffset;
        query = String.format(query, new List<String> {AgentPortalConstants.SEARCH_FIELDS_APPLICANT, clause});
        Map<Id, Contact> applicants = new Map<Id, Contact>((List<Contact>) Database.query(query));

        if (!applicants.isEmpty()) {
            populateContactPointsBasedOnAffiliation(applicants, agent.Contact.Account.Callista_Org_Unit_Code__c);
            return applicants.values();
        }

        return null;
    }
    /**
     * @author      Vinothraja
     * @description Searches for Contact Point Affiliation records, and populates all the Contacts contact-points
     *              with only the Affiliated values. If no Affiliation exists for the Agency, then the contact-points
     *              are blanked out
     * @param       Map<Id, Contact> - Map of Contact records with Phone, HomePhone, MobilePhone, Personal_Email__c, 
     *              Mailing & Other Address fields queried
     * @param       String - the Agency's Callista Org Unit Code whose Affiliation be used for fetching contact-point records
     * @return      void - the contact points of the Contact records sent in, will be populated. 
     * @revision    2023-07-03 - Vinothraja - Created
     */
    private static void populateContactPointsBasedOnAffiliation(Map<Id, Contact> applicants, String agencyCallistaOrgUnitCode) {
        if (!applicants.isEmpty()) {
            // Clear all applicant's phone & email details
            for (Contact con : applicants.values()) {
                applicants.put(con.Id, (Contact) (stripPrivateDetailsFromContact(con)).get('CONTACT'));
            }
            // Query for CPA Records
            String clause = ' type__c IN (\'Email\',\'Phone\',\'Address\') ';
            clause += ' AND classification__c IN (\'Mobile\',\'Landline\',\'Private\',\'Mailing\',\'Billing\') ';
            clause += ' AND Contact_Point_Active__c = true AND Affiliation_active__c = true ';
            clause += ' AND (affiliation__r.account__r.callista_org_unit_code__c = \'\'{0}\'\' OR affiliation__r.account__r.parent.callista_org_unit_code__c = \'\'{0}\'\') ';
            clause += ' AND contact__r.id IN (\'\'{1}\'\')';
            clause = String.format(clause, new List<String> {agencyCallistaOrgUnitCode, String.join(new List<Id>(applicants.keySet()), '\',\'')});
            Set<String> fieldset = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_CONTACT_POINT.split(','));
            String query = DynamicSoqlBuilder.getInstance()
                                        .showSOQLStatement(true)
                                        .setEnforced(false)
                                        .querySObject(String.escapeSingleQuotes('Contact_point_affiliation__c'))
                                        .queryFields(fieldset)
                                        .getQuery(clause);
            query += ' ORDER BY primary_on_Contact__c ASC, shown_on_contact__c ASC, start_date__c ASC, createddate ASC'; // Ordered by ASC so the latest-greatest record will be the last one
            for (Contact_Point_Affiliation__c cpa : (List<Contact_Point_Affiliation__c>) Database.query(query)) {
                // Populate with Agency's affiliated Contact Point Phone
                if (cpa.type__c != null && cpa.type__c.equalsIgnoreCase('Phone')) {
                    if (cpa.phone__r.type__c != null && cpa.phone__r.type__c.equalsIgnoreCase('Mobile')) {
                        applicants.get(cpa.contact__c).MobilePhone = cpa.phone__r.name;
                    }
                    if (cpa.phone__r.type__c != null && cpa.phone__r.type__c.equalsIgnoreCase('Landline')) {
                        applicants.get(cpa.contact__c).HomePhone = cpa.phone__r.name;
                    }
                    if (cpa.phone__r.type__c != null && cpa.phone__r.type__c.equalsIgnoreCase('Other')) {
                        applicants.get(cpa.contact__c).OtherPhone = cpa.phone__r.name;
                    }
                }
                // Populate with Agency's affiliated Contact Point Email
                if (cpa.type__c != null && cpa.type__c.equalsIgnoreCase('Email')) {
                    applicants.get(cpa.contact__c).Personal_Email__c = cpa.email__r.name;
                }
                // Populate with Agency's affiliated Contact Point Address
                if (cpa.type__c != null && cpa.type__c.equalsIgnoreCase('Address')) {
                    if (cpa.address__r.type__c != null && cpa.address__r.type__c.equalsIgnoreCase('Mailing')) {
                        applicants.get(cpa.contact__c).MailingStreet = cpa.address__r.Street_Name__c;
                        applicants.get(cpa.contact__c).MailingCity = cpa.address__r.City__c;
                        applicants.get(cpa.contact__c).MailingState = cpa.address__r.State__c;
                        applicants.get(cpa.contact__c).MailingCountry = cpa.address__r.Country2__c;
                        applicants.get(cpa.contact__c).MailingPostalCode = cpa.address__r.Post_Code__c;
                    }
                    if (cpa.address__r.type__c != null && cpa.address__r.type__c.equalsIgnoreCase('Billing')) {
                        applicants.get(cpa.contact__c).OtherStreet = cpa.address__r.Street_Name__c;
                        applicants.get(cpa.contact__c).OtherCity = cpa.address__r.City__c;
                        applicants.get(cpa.contact__c).OtherState = cpa.address__r.State__c;
                        applicants.get(cpa.contact__c).OtherCountry = cpa.address__r.Country2__c;
                        applicants.get(cpa.contact__c).OtherPostalCode = cpa.address__r.Post_Code__c;
                    }                }
            }
        }
    }
    /**
     * @author      Vinothraja
     * @description Checks whether an user already exists by the specified username
     * @return      boolean (true or false)
     * @revision    2023-02-21 - Vinothraja - Created
     */
    public static boolean doesUserExist(String username) {
        List<User> usrs = (List<User>) systemContext.query('SELECT Id FROM User WHERE username = \'' + username + '\' LIMIT 1');
        if (usrs.isEmpty()) {
            return false;
        }
        return true;
    }
    /**
     * @author      Vinothraja
     * @description Updates a Contact under an Agent specified by the OrgId
     * @return      boolean (true or false)
     * @revision    2023-02-23 - Vinothraja - Created
     */
    public static Contact updateApplicant(Contact con) {
        Map<String, Object> resultAfterPrivacyCleanup = stripPrivateDetailsFromContact(con);
        Savepoint updateContactSavepoint = Database.setSavepoint();
        try {
            con = (Contact) resultAfterPrivacyCleanup.get('CONTACT');
            con.AccountId = [SELECT AccountId 
                             FROM Contact 
                             WHERE id = :con.id]?.AccountId;
            update con;
            // retrieve Affiliation record
            Affiliation__c aff = getAffiliationRecord(con.Id); 

            // Create Contact Point records
            Map<String, String> mapStrippedFileds = (Map<String, String>) resultAfterPrivacyCleanup.get('STRIPPED_FIELDS');
            if (!mapStrippedFileds.isEmpty()){
                String email = mapStrippedFileds.containsKey('Personal_Email__c') ? mapStrippedFileds.get('Personal_Email__c') : null;
                String mobilePhone = mapStrippedFileds.containsKey('MobilePhone') ? mapStrippedFileds.get('MobilePhone') : null;
                String landline = mapStrippedFileds.containsKey('HomePhone') ? mapStrippedFileds.get('HomePhone') : null;
                AgentPortalPayload.Address mailingAddress = null;
                if (mapStrippedFileds.containsKey('MailingStreet') 
                        || mapStrippedFileds.containsKey('MailingCity')
                        || mapStrippedFileds.containsKey('MailingState')
                        || mapStrippedFileds.containsKey('MailingCountry')
                        || mapStrippedFileds.containsKey('MailingPostalCode')) {
                            mailingAddress = new AgentPortalPayload.Address();
                            mailingAddress.street = mapStrippedFileds.containsKey('MailingStreet') ? mapStrippedFileds.get('MailingStreet') : '';
                            mailingAddress.city = mapStrippedFileds.containsKey('MailingCity') ? mapStrippedFileds.get('MailingCity') : '';
                            mailingAddress.state = mapStrippedFileds.containsKey('MailingState') ? mapStrippedFileds.get('MailingState') : '';
                            mailingAddress.country = mapStrippedFileds.containsKey('MailingCountry') ? mapStrippedFileds.get('MailingCountry') : '';
                            mailingAddress.postalCode = mapStrippedFileds.containsKey('MailingPostalCode') ? mapStrippedFileds.get('MailingPostalCode') : '';
                        }
                AgentPortalPayload.Address otherAddress = null;
                if (mapStrippedFileds.containsKey('OtherStreet') 
                        || mapStrippedFileds.containsKey('OtherCity')
                        || mapStrippedFileds.containsKey('OtherState')
                        || mapStrippedFileds.containsKey('OtherCountry')
                        || mapStrippedFileds.containsKey('OtherPostalCode')) {
                            otherAddress = new AgentPortalPayload.Address();
                            otherAddress.street = mapStrippedFileds.containsKey('OtherStreet') ? mapStrippedFileds.get('OtherStreet') : '';
                            otherAddress.city = mapStrippedFileds.containsKey('OtherCity') ? mapStrippedFileds.get('OtherCity') : '';
                            otherAddress.state = mapStrippedFileds.containsKey('OtherState') ? mapStrippedFileds.get('OtherState') : '';
                            otherAddress.country = mapStrippedFileds.containsKey('OtherCountry') ? mapStrippedFileds.get('OtherCountry') : '';
                            otherAddress.postalCode = mapStrippedFileds.containsKey('OtherPostalCode') ? mapStrippedFileds.get('OtherPostalCode') : '';
                        }
                // create contact point records with affiliation
                BaseClass.ResultSet rs = createCPA(con, aff, email, mobilePhone, landline, mailingAddress, otherAddress);
            }
        } catch (Exception ex) {
            Database.rollback(updateContactSavepoint);
            throw ex;
        }
        return con;
    }
    /**
     * @author      Vinothraja
     * @description Helper method to remove all Private information from a Contact
     * @return      Map<String, Object> 
     *              Key 'CONTACT' contains the cleaned Contact
     *              Key 'STRIPPED_FIELDS' contains the removed private information as a map<string, string>
     * @revision    2023-07-05 - Vinothraja - Created
     */
    private static Map<String, Object> stripPrivateDetailsFromContact(Contact con) {
        Map<String, Object> resultMap = new Map<String, Object> ();
        Map<String, Object> contactAsMap = new Map<String, Object>(con.getPopulatedFieldsAsMap());
        Map<String, String> privateContactDetails = new Map<String, String> ();
        for (String field : AgentPortalConstants.PRIVATE_CONTACT_FIELDS.split(',')) {
            if (contactAsMap.containsKey(field)) {
                privateContactDetails.put(field, (String) contactAsMap.get(field));
                contactAsMap.remove(field);
            }
        }
        con = (Contact) JSON.deserialize( JSON.serialize( contactAsMap ), Contact.class );
        resultMap.put('CONTACT', con);
        resultMap.put('STRIPPED_FIELDS', privateContactDetails);
        return resultMap;
    }
    /**
     * @author      Vinothraja
     * @description Fetches Phone number based on Type from the Payload
     * @return      String 
     * @revision    2023-03-02 - Vinothraja - Created
     */
    public static String getPhoneNumber(List<AgentPortalPayload.Phone> phones, String type) {
        for (AgentPortalPayload.Phone phone : phones) {
            if (phone.type.equalsIgnoreCase(type)) {
                return phone.phoneNumber;
            }
        }
        return '';
    }
    /**
     * @author      Vinothraja
     * @description Fetches email address based on Type from the Payload
     * @return      String 
     * @revision    2023-03-02 - Vinothraja - Created
     */
    public static String getEmail(List<AgentPortalPayload.Email> emails, String type) {
        for (AgentPortalPayload.Email email : emails) {
            if (email.type.equalsIgnoreCase(type)) {
                return email.email;
            }
        }
        return '';
    }
    /**
     * @author      Vinothraja
     * @description Fetches Residency Statuses available based on an Agent's Agency
     * @return      Object to be serialised by Payload
     * @revision    2023-03-07 - Vinothraja - Created
     */
    public static Object getResidencyStatus(String agentUserId) {
        Map<String,List<Map<String, String>>> mapResidencyStatuses = new Map<String,List<Map<String, String>>> ();
        User agent = getUser(agentUserId);
        if (agent != null && agent.contact.Account.campus__c != null){
            List<String> agencyLocations = agent.contact.Account.campus__c?.split(';');
            for (String campus : agencyLocations) {
                mapResidencyStatuses.put(campus, StudyLocationController.getCitizenshipTypes(campus));
            }
        } else {
            throw new AgentPortalPayload.BadRequestException('Agent is not a valid Agency Contact (or) Agency does not have Campus locations set!');
        }
        return mapResidencyStatuses;
    }
    /**
     * @author      Vinothraja
     * @description Checks if an Applicant has draft Application(s) for the same campus (within the agencies provided)
     * @return      Boolean
     * @revision    2023-03-09 - Vinothraja - Created
     */
    public static Boolean doOtherDraftsExistForSameCampus(String applicantId, String campus, Set<String> agencies) {
        List<Application__c> existingDraftApps = [
                SELECT Id
                FROM Application__c
                WHERE Status__c = 'Draft' 
                    AND Applicant__c = :applicantId 
                    AND Campus_Location__c = :campus
                    AND Agent_Org_Unit_Code__c IN :agencies
        ];
        if (existingDraftApps.isEmpty()) {
            return false;
        }
        return true;
    }
    /**
     * @author      Vinothraja
     * @description Creates a draft Application 
     * @return      Object to be serialised by Payload
     * @revision    2023-03-09 - Vinothraja - Created
     */
      public static Object createApplication(Application__c app, String email, String phone) {
        Savepoint createApplication = Database.setSavepoint();
        try {
            // create application
            insert app;
            // retrieve Affiliation record
            Affiliation__c aff = getAffiliationRecord(app.Applicant__c); 
            // create contact point records with affiliation
            Contact con = [SELECT id, AccountId FROM Contact WHERE id = :app.Applicant__c LIMIT 1];

            BaseClass.ResultSet rs = createCPA(con, aff, email, phone, null, null, null);
            // Query inserted Application ( mainly for Reference Number ) to be used in the Response
            String appId = app.id;
            String clause = 'id = :appId';
            Set<String> fieldset = new Set<String> (AgentPortalConstants.CREATE_FIELDS_APPLICATION.split(','));
            String query = DynamicSoqlBuilder.getInstance()
                                                .showSOQLStatement(true)
                                                .setEnforced(true)
                                                .querySObject(String.escapeSingleQuotes('Application__c'))
                                                .queryFields(fieldset)
                                                .getQuery(String.escapeSingleQuotes(clause));
            app = (Application__c) (Database.query(query)[0]);
        } catch(Exception e) {
            Database.rollback(createApplication);
            throw e;
        }
        return app;
    }
    /**
     * @author      Shalini Mendu
     * @description Helper method to retrieve Affiliation record
     * @return      Affiliation__c 
     * @revision    2023-07-03 - Shalini Mendu - Created
     */
    private static Affiliation__c getAffiliationRecord(String applicantId) {
        User agent = getUser(UserInfo.getUserId());
        List<Affiliation__c> affList = [SELECT Id, name 
                                                FROM Affiliation__c 
                                                WHERE Account__c =:agent.Contact.AccountId 
                                                AND Contact__c = :applicantId 
                                                AND Is_Active__c = :AffiliationManageService.ACTIVE_STATUS
                                                AND Share_Contact_to_Account_Role__c = :AffiliationManageService.WRITE_ACCESS_LEVEL];
        if (!affList.isEmpty()) {
            return affList.get(0);
        } 
        return null;
    }
    /**
     * @author      Shalini Mendu
     * @description Helper method to create Contact Point record with or without Affiliations
     * @return      BaseClass.ResultSet 
     * @revision    2023-07-03 - Shalini Mendu - Created
     */
    private static BaseClass.ResultSet createCPA(Contact con,  Affiliation__c aff, String email, String mobilePhone, String landline, AgentPortalPayload.Address mailingAddress, AgentPortalPayload.Address otherAddress)
    {
       Person360.Person360Builder builder = new Person360.Person360Builder(con); 
        Set<String> contactPointsCollection = new Set<String> ();
        //Link  Affiliation__c
        if (aff != null) {
            builder.withAffiliation(aff);
        }
        
        //Link  Email__c cp
        if(String.isNotBlank(email)){
            contactPointsCollection.add('Email__c'); 
            builder.buildEmail()
                .withClassification(AgentPortalConstants.CONTACT_CLASSIFICATION)
                .withEmailId(email)
                .withSource(AgentPortalConstants.CONTACT_SOURCE);
        }
        
        //Link  Phone__c - mobile phone cp
        if(String.isNotBlank(mobilePhone)){
            contactPointsCollection.add('Phone__c');
            builder.buildPhone()
                .withClassification(AgentPortalConstants.CONTACT_CLASSIFICATION)
                .withPhoneNumber(mobilePhone)
                .withType(AgentPortalConstants.CONTACT_PHONE_TYPE_MOBILE)
                .withSource(AgentPortalConstants.CONTACT_SOURCE);
        }
        //Link  Phone__c - land line phone cp
        if(String.isNotBlank(landline)){
            contactPointsCollection.add('Phone__c');
            builder.buildPhone()
                .withClassification(AgentPortalConstants.CONTACT_CLASSIFICATION)
                .withPhoneNumber(landline)
                .withType(AgentPortalConstants.CONTACT_PHONE_TYPE_LANDLINE)
                .withSource(AgentPortalConstants.CONTACT_SOURCE);
        }
        //Link  mailing address Address__c cp
        if(mailingAddress != null){
            contactPointsCollection.add('Address__c');
            builder.buildAddress()
                .withClassification(AgentPortalConstants.CONTACT_CLASSIFICATION)
                .withStreetName(mailingAddress.street)
                .withCity(mailingAddress.city)
                .withCountry(mailingAddress.country)
                .withState(mailingAddress.state)
                .withPostCode(mailingAddress.postalCode)
                .withType(AgentPortalConstants.CONTACT_ADDRESS_TYPE_MAILING)
                .withSource(AgentPortalConstants.CONTACT_SOURCE);
        }
        //Link  other address Address__c cp
        if(otherAddress != null){
            contactPointsCollection.add('Address__c');
            builder.buildAddress()
                .withClassification(AgentPortalConstants.CONTACT_CLASSIFICATION)
                .withStreetName(otherAddress.street)
                .withCity(otherAddress.city)
                .withCountry(otherAddress.country)
                .withState(otherAddress.state)
                .withPostCode(otherAddress.postalCode)
                .withType(AgentPortalConstants.CONTACT_ADDRESS_TYPE_OTHER)
                .withSource(AgentPortalConstants.CONTACT_SOURCE);
        }
        //Call Person 360 classes to relate with the associated records and 
        //solve dependencies
        Person360 p360  = builder.build();
        BaseClass bc = new Person360BuilderDirector()
                            .resolveContactPointsWithExternalId()
                            .resolveDependencies(p360)
                            .getBaseClass();
        // Mute RollUplogic to avoid lock issues
        Triggers.bypass('RollUpLogic');
        Triggers.bypass('InvokeRollUpContactPointsAsync');
        //Partially Commit all the objects we have built - Allow failures while what succeeds succeed
        BaseClass.ResultSet rs = bc.commitRecordsPartial();
        Triggers.Clearbypass('RollUpLogic');
        Triggers.Clearbypass('InvokeRollUpContactPointsAsync');
        new Person360RollUpServices.PerformRollUp().run(new Set<String> {con.id}, null, new List<String> (contactPointsCollection), true);	
        return rs;
    }
    /*
     * @author Martin Cadman
     * @date 01.05.2023
     * @group Application
     * @description A series of classes & methods to support the change of ownership of Agent linked applications/acp that are created in Callista
     * 
     * 25.02.2024 - Martin Cadman - Changed sharing of inner class to allow JWT users (agents) access to user records
     */
    
	// Class passed back to calling methods    
	public without sharing class AgencyWrapper {
        public Map<String, List<User>> agencyUsers {get;set;} // OrgUnit + Active users within the org
        public Map<String, User> agencyManagers {get;set;}    // OrgUnit + branch manager
        public Map<Id, User> agentUsers {get; set;}           // User Id + User
        
        public AgencyWrapper() {
            this.agencyUsers    = new Map<String, List<User>>();
            this.agencyManagers = new Map<String, User>();
        	this.agentUsers     = new Map<Id, User>();
        }
    }
    
    // These are dummy agencies that do not trigger the alignment logic
    public static boolean isValidOrgUnit(String orgUnit) {
        // Fetch list of invalid Org unit codes
        List<String> invalidOrgUnits = SystemSettingsUtil.getInstance().getByKeyFeature('APNG', 'INVALID_ORG_UNIT_CODES')?.value__c?.split(',');

        If (String.isNotBlank(orgUnit)
            && (invalidOrgUnits == null || !invalidOrgUnits.contains(orgUnit.toUpperCase()))) {
               return true;
           }
        return false;
    }       
    
    // Build out the collections that link agencies, agent contacts and users
    public static AgencyWrapper buildAgencyMaps(Set<String> orgUnits) {
        Map<Id, User> agentContactUsers = new Map<Id, User>(); // Contact Id + User
		AgencyWrapper aw = new AgencyWrapper();
        
        // List of all non role-account contacts that report to an Agency
        List<Contact> agentContacts = [select id, Agency_Contact_Roles__c, account.Callista_Org_Unit_Code__c, accountid 
                                       from Contact 
                                       where Role_Account_Flag__c = false 
                                       and account.Callista_Org_Unit_Code__c in :orgUnits];
        
        // Find the active users that are related to agency contacts
        for (User u : [SELECT id, contactid FROM user WHERE contactid in :agentContacts and isactive = true]){
            aw.agentUsers.put(u.id,u);
            agentContactUsers.put(u.contactid,u);
        }
        
        for (Contact c : agentContacts) {
            String ou = c.account.Callista_Org_Unit_Code__c.toLowerCase();
            
            if (!aw.agencyUsers.containsKey(ou) ) {
                aw.agencyUsers.put(ou, new List<User>());
            }
            List<User> ul = aw.agencyUsers.get(ou);		
            ul.add(agentContactUsers.get(c.id));
            aw.agencyUsers.put(ou,ul);
            
            if (c.Agency_Contact_Roles__c != null && c.Agency_Contact_Roles__c.containsignorecase(AGENTROLE)) {
                aw.agencyManagers.put(ou, agentContactUsers.get(c.id));
            }
        }
        
        return aw;
    }
    
    /**
     * @author      Vinothraja
     * @description Creates an Agent Portal user, adds him to the Agent Portal community, and assigns the necessary Permission sets/groups
     * @param       User agentUser - user record 
     * @param       Contact agentContact - contact record for which the user is being created
     * @return      User
     * @revision    06/04/2023 - Vinothraja - Created
     */
    public static User createAgentUser(User agentUser, Contact agentContact) {
        Savepoint userCreationSavePoint = Database.setSavepoint();
        try{

            agentUser = ExperienceAuthenticationServices.createAgentUser(agentUser);
            // update user's role 
            // NOTE: portal role hierarchy is established after the first user is created
            UserRole userRole = ExperienceAuthenticationServices.getUserRole(new List<Contact>{ agentContact })
                .get(agentContact.Id);
            agentUser.UserRoleId = userRole.id;
            systemContext.patch(new List<User> {agentUser});
        } catch(Exception ex){
            // revert changes
            Database.rollback(userCreationSavePoint);
            throw ex;
        }

        return agentUser;
    }
    /**
     * @author      Vinothraja
     * @description Gets the Applicant record based on the CRM_ID__c field
     *              Runs both in with and without sharing mode
     * @param       String CRMID - CRM_ID__c or Person_ID_unique__c
     * @param       String Persona - 'APPLICANT' or 'AGENT'
     * @param       String context - 'USER' or 'SYSTEM' 
     * @return      Contact
     * @revision    24/04/2023 - Vinothraja - Created
     */
    public static Contact getContact(String CRMID, String persona, String context) {
        String clause = 'CRM_ID__c = \''+ CRMID + '\'';
        Set<String> fieldset = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_APPLICANT.split(','));
        if (String.isNotBlank(persona) && persona.equalsIgnoreCase(AgentPortalConstants.AGENT_PERSONA)) {
            clause = 'id = \''+ CRMID + '\'';
            fieldset = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_AGENCY_CONTACT.split(','));
        }
        String query = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Contact'))
                                            .queryFields(fieldset)
                                            .getQuery(clause);
        query += ' LIMIT 1';
        Map<id, Contact> contacts;
        if (String.isBlank(context) || context.equalsIgnoreCase(AgentPortalConstants.USER_CONTEXT)) {
            contacts = new Map<id, Contact> ((List<Contact>) Database.query(query));
        } else {
            contacts = new Map<id, Contact> ((List<Contact>) systemContext.query(query));
        }
        if (!contacts.isEmpty()) {
            if (String.isNotBlank(persona) && persona.equalsIgnoreCase(AgentPortalConstants.APPLICANT_PERSONA)) {
                User agent = getUser(UserInfo.getUserId());
                populateContactPointsBasedOnAffiliation(contacts, agent.contact.Account.Callista_Org_Unit_Code__c);
            } 
            return contacts.values().get(0);
        }
        return null;
    }
    /**
     * @author      Vinothraja
     * @description Gets the User record based on the id field
     * @param       String userId or UserName
     * @return      User
     * @revision    24/04/2023 - Vinothraja - Created
     */
    public static User getUser(String userIdorUserName) {
        String clause = 'id = \''+ userIdorUserName + '\'';
        if (String.isNotBlank(userIdorUserName)) {
            try {
                Id userId = Id.valueOf(userIdorUserName);
                if (Schema.User.SObjectType != userId.getSobjectType()) {
                    throw new AgentPortalPayload.BadRequestException();
                }
            } catch(Exception ex) {
                clause = 'username = \''+ userIdorUserName + '\'';
            }
        }
        Set<String> fieldset = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_USER.split(','));
        String query = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('User'))
                                            .queryFields(fieldset)
                                            .getQuery(clause);
        query += ' LIMIT 1';
        List<User> lstUsers = Database.query(query);
        if (!lstUsers.isEmpty()) {
            return lstUsers.get(0);
        } 
        return null;
    }
    /**
     * @author      Vinothraja
     * @description Gets Application details based on Id
     * @param       String applicationName 
     * @return      AgentPortalPayload.ApplicationDetails Wrapper containing Application details & ACPs
     * @revision    24/04/2023 - Vinothraja - Created
     */
    public static AgentPortalPayload.ApplicationDetails getApplicationDetails(String applicationName) {
        AgentPortalPayload.ApplicationDetails appWrapper = new AgentPortalPayload.ApplicationDetails();
        // Generate application query
        Set<String> applicationFieldSet = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_APPLICATION.split(','));
        String clause = 'name = \''+ applicationName + '\'';
        String applicationQuery = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Application__c'))
                                            .queryFields(applicationFieldSet)
                                            .getQuery(clause);
        applicationQuery += ' LIMIT 1';
        List<Application__c> lstApplications = Database.query(applicationQuery);
        if (!lstApplications.isEmpty()) {
            appWrapper.details = lstApplications.get(0);
            appWrapper.coursePreferences = getApplicationCoursePreferences(applicationName);
            return appWrapper;
        } 
        return null;
    }
    /**
     * @author      Vinothraja
     * @description Gets Application Course Preferences based on Application Id
     * @param       String applicationName 
     * @return      Application_Course_Preference__c Application Course Preferences
     * @revision    01/05/2023 - Vinothraja - Created
     */
    public static List<Application_Course_Preference__c> getApplicationCoursePreferences(String applicationName) {
        // Generate ACP sub query
        Set<String> acpFieldSet = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_ACP.split(','));
        String clause = 'Application__r.Name = \''+ applicationName + '\'';
        String acpQuery = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(false)
                                            .querySObject(String.escapeSingleQuotes('Application_Course_Preference__c'))
                                            .queryFields(acpFieldSet)
                                            .getQuery(clause);
        return Database.query(acpQuery);
    }
    /**
     * @author      Vinothraja
     * @description Gets Contact Qualifications based on Application Name
     * @param       String applicationName 
     * @return      AgentPortalPayload.Qualifications Wrapper containing current Application's and historical Qualifications
     * @revision    01/05/2023 - Vinothraja - Created
     */
    public static AgentPortalPayload.Qualifications getContactQualificationsByApplicationId(String applicationName) {
        AgentPortalPayload.Qualifications qualifications = new AgentPortalPayload.Qualifications();
        // Fetch current Application's applicant
        Set<String> applicationFieldSet = new Set<String> {'id','Applicant__c','Applicant__r.CRM_id__c','Name'};
        String clause = 'name = \''+ applicationName + '\'';
        String applicationQuery = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Application__c'))
                                            .queryFields(applicationFieldSet)
                                            .getQuery(clause);
        applicationQuery += ' LIMIT 1';
        Application__c currentApplication = Database.query(applicationQuery);
        qualifications.applicationId = currentApplication.Name;
        qualifications.applicantId = currentApplication.Applicant__r.CRM_id__c;
        // Fetch Qualifications for Current Application
        ContactQualificationsSelector contactQualifications = new ContactQualificationsSelector();
        List<Contact_Qualification__c> currentApplicationQualfications = contactQualifications.selectByApplicationId(new Set<Id> {currentApplication.id});
        qualifications.applicationQualifications = currentApplicationQualfications;

        // Fetch All Qualifications for this Applicant, and exclude Current Application's Qualifications
        // Set<Id> currentApplicationQualficationsIds = new Set<Id> ();
        // for (Contact_Qualification__c qual : currentApplicationQualfications) {
        //     currentApplicationQualficationsIds.add(qual.Id);
        // }
        // List<Contact_Qualification__c> otherApplicationQualfications = new List<Contact_Qualification__c> ();
        // for (Contact_Qualification__c qual : contactQualifications.selectByContactId(new Set<Id> {currentApplication.Applicant__c})) {
        //     if (!currentApplicationQualficationsIds.contains(qual.Id)) {
        //         otherApplicationQualfications.add(qual);
        //     }
        // }
        // qualifications.historicalQualifications = otherApplicationQualfications;
        return qualifications;
    }
    /**
     * @author      Vinothraja
     * @description Gets Work Experiences based on Application Id
     * @param       String applicationName 
     * @return      AgentPortalPayload.WorkExperiences Wrapper containing current Application's and historical Work Experiences
     * @revision    01/05/2023 - Vinothraja - Created
     */
    public static AgentPortalPayload.WorkExperiences getWorkExperiencesByApplicationId(String applicationName) {
        AgentPortalPayload.WorkExperiences experiences = new AgentPortalPayload.WorkExperiences();
        // Fetch current Application's applicant
        Set<String> applicationFieldSet = new Set<String> {'id','Applicant__c','Applicant__r.CRM_id__c','Name'};
        String clause = 'name = \''+ applicationName + '\'';
        String applicationQuery = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Application__c'))
                                            .queryFields(applicationFieldSet)
                                            .getQuery(clause);
        applicationQuery += ' LIMIT 1';
        Application__c currentApplication = Database.query(applicationQuery);
        experiences.applicationId = currentApplication.Name;
        experiences.applicantId = currentApplication.Applicant__r.CRM_id__c;
        // Fetch Work Experiences for Current Application
        Set<String> workExpFieldSet = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_WORKEXPERIENCE.split(','));
        clause = 'id IN (SELECT Work_Experience__c FROM Application_Work_Experience_Provided__c WHERE Application__c = \'' + currentApplication.id + '\')';
        String currAppnWorkExpQuery = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Work_Experience__c'))
                                            .queryFields(workExpFieldSet)
                                            .getQuery(clause);

        List<Work_Experience__c> currentApplicationWorkExperiences = Database.query(currAppnWorkExpQuery);
        experiences.applicationExperiences = currentApplicationWorkExperiences;
        // Fetch All Work Experiences for this Applicant, and exclude Current Application's Work Experiences
        // Set<Id> currentAppnWorkExpIds = new Set<Id> ();
        // for (Work_Experience__c wex : currentApplicationWorkExperiences) {
        //     currentAppnWorkExpIds.add(wex.id);
        // }
        // clause = 'Contact__c = \'' + currentApplication.Applicant__c + '\'';
        // clause += ' AND id NOT IN :currentAppnWorkExpIds';
        // String otherAppnWorkExpQuery = DynamicSoqlBuilder.getInstance()
        //                                     .showSOQLStatement(true)
        //                                     .setEnforced(true)
        //                                     .querySObject(String.escapeSingleQuotes('Work_Experience__c'))
        //                                     .queryFields(workExpFieldSet)
        //                                     .getQuery(clause);

        // experiences.historicalExperiences = Database.query(otherAppnWorkExpQuery);
        return experiences;
    }
    /**
     * @author      Vinothraja
     * @description Get details of the Applicant; Sets the isEditable flag based on whether Applicant has submitted Applications or not
     * @param       String contactId 
     * @return      AgentPortalPayload.ApplicantDetails Wrapper containing Applicant details 
     * @revision    01/05/2023 - Vinothraja - Created
     */
    public static AgentPortalPayload.ApplicantDetails getApplicantDetails(String contactId) {
        AgentPortalPayload.ApplicantDetails applicantWrapper = new AgentPortalPayload.ApplicantDetails();
        // Get contact details
        Contact applicant = getContact(contactId, AgentPortalConstants.APPLICANT_PERSONA, AgentPortalConstants.USER_CONTEXT);
        if (applicant == null) {
            throw new AgentPortalPayload.ApplicantException('No applicant found');
        }
        applicantWrapper.details = applicant;
        // Get Applicant's other applications, and check if he has any other submitted ones
        Boolean otherSubmittedApplicationExists = false;
        if (!getSubmittedApplicationsForApplicant(applicant.Id, new Set<Id> ()).isEmpty()) {
            otherSubmittedApplicationExists = true;
        }
        applicantWrapper.isEditable = !otherSubmittedApplicationExists;
        return applicantWrapper;
    }
    /**
     * @author      Vinothraja
     * @description Gets only the Submitted Applications of an Applicant; Excludes a set of certain Applications, from being checked by their Statuses
     * @param       String applicantId 
     * @param       Set<Id> excludedApplicationIds 
     * @return      List<Application__c> 
     * @revision    01/05/2023 - Vinothraja - Created
     */
    public static List<Application__c> getSubmittedApplicationsForApplicant(String applicantId, Set<Id> excludedApplicationIds) {
        List<Application__c> submittedApplications = new List<Application__c> ();
        for (Application__c app : getApplicationsForApplicant(applicantId)) {
            if (AffiliationCheckService.SUBMITTED_STATUSES.contains(app.Status__c) && !excludedApplicationIds.contains(app.Id)) {
                submittedApplications.add(app);
            }
        }
        return submittedApplications;
    }
    /**
     * @author      Vinothraja
     * @description Gets all Applications of an Applicant
     * @param       String applicantId 
     * @return      List<Application__c> 
     * @revision    01/05/2023 - Vinothraja - Created
     */
    public static List<Application__c> getApplicationsForApplicant(String applicantId) {
        String clause = 'Applicant__c = \''+ applicantId + '\'';
        Set<String> fieldset = new Set<String> {'Id', 'Status__c'};
        String query = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Application__c'))
                                            .queryFields(fieldset)
                                            .getQuery(clause);
        // (List<Application__c>)  allAppsOfApplicant = (List<Application__c>) 
        // if (allAppsOfApplicant != null){
        //     return (List<Application__c>) allAppsOfApplicant;
        // } 
        return (List<Application__c>) systemContext.query(query);
    }
    /**
     * @author      Vinothraja
     * @description Updates an Application
     * @param       Application__c record
     * @return      Application__c updated record
     * @revision    11/05/2023 - Vinothraja - Created
     */
    public static Application__c updateApplication(Application__c app) {
        update app;
        return app;
    }
    /**
     * @author      Vinothraja
     * @description Upserts Course Preferences of an Application based on the list; Removes other Course Preferences not available in the list
     * @param       List<Application_Course_Preference__c> Course Preferences records; should contain - id (opt), Application__c, Applicant__c, Course_Offering__c, Preference_Number__c
     * @return      List<Contact_Qualfication__c> updated records
     * @revision    11/05/2023 - Vinothraja - Created
     * @revision    24/05/2024 - Ben Greenland added additonal logic for OES
     */
    public static List<Application_Course_Preference__c> updateApplicationCoursePreferences(String applicationId, List<Application_Course_Preference__c> coursePreferences) {
        List<Application_Course_Preference__c> listACPsToBeUpserted = new List<Application_Course_Preference__c> ();
        List<Application_Course_Preference__c> listACPsToBeUpsertedOES = new List<Application_Course_Preference__c> ();
        // Prepare a MAP of Existing Course Preferences for the Application
        Map<String, Application_Course_Preference__c> mapOldACPsInAppn = new Map<String, Application_Course_Preference__c> ();
        Map<String, Application_Course_Preference__c> mapOldACPsInAppnOES = new Map<String, Application_Course_Preference__c> ();
        for (Application_Course_Preference__c acp : new ACPSelector().selectByApplicationId(new Set<Id> {applicationId}) ) { 
            if(OESApplicationService.isOESUser){
                mapOldACPsInAppnOES.put(acp.External_ID__c,acp);
            }else{
            mapOldACPsInAppn.put(acp.id, acp);
        }
        }
        // Upsert current Course Preferences 
        // Note: The IDs of newly inserted Course Preferences from GCP will not be present in the above map
        // Prepare a list for newly inserted Course Preferences
        Map<String, Application_Course_Preference__c> mapCOACP = new Map<String, Application_Course_Preference__c> ();
        Map<String, Application_Course_Preference__c> mapCOACPOES = new Map<String, Application_Course_Preference__c> ();
        List<Application_Course_Preference__c> listACPsToBeUpdated = new List<Application_Course_Preference__c> ();
        List<Application_Course_Preference__c> listACPsToBeUpdatedOES = new List<Application_Course_Preference__c> ();
   
        for (Application_Course_Preference__c acp : coursePreferences) { // looping through the current Course Preferences
         if(!OESApplicationService.isOESUser){
                // If ID is not present it is a new Course to be added to application. 
                if (!mapOldACPsInAppn.containsKey(acp.Id) || String.isBlank(acp.Id)){
                    mapCOACP.put(acp.Course_Offering__c, acp);
                    // If ID is present it is an Existing Course Preferences
                } else { 
                    mapOldACPsInAppn.remove(acp.Id); // remove existing Course Preferences from the map, so it finally contains only Removed-in-GCP Course Preferences
                    listACPsToBeUpdated.add(acp); // Add ACP to the upsertable ACPs
                }
            }else if(OESApplicationService.isOESUser){
                // If ID is not present it is a new Course to be added to application. 
                if (!mapOldACPsInAppnOES.containsKey(acp.External_ID__c) || String.isBlank(acp.External_ID__c) ){
                    mapCOACPOES.put(acp.Course_Offering__r.Course_Offering_UID__c, acp);
                    // If ID is present it is an Existing Course Preferences
                } else { 
                    mapOldACPsInAppnOES.remove(acp.External_ID__c); // remove existing Course Preferences from the map, so it finally contains only Removed-in-GCP Course Preferences
                    listACPsToBeUpdatedOES.add(acp); // Add ACP to the upsertable ACPs
                }
            }
        }

        if(!OESApplicationService.isOESUser){
            // Prepare ACPs based on Course Offerings and Preference Rank
            List<Application_Course_Preference__c> listACPsToBeInserted = prepareACPs(mapCOACP);
            listACPsToBeUpserted.addAll(listACPsToBeInserted);
            listACPsToBeUpserted.addAll(listACPsToBeUpdated);
            upsert listACPsToBeUpserted;
        }
        //run for OES External Id records
        if(OESApplicationService.isOESUser){
            List<Application_Course_Preference__c> listACPsToBeInsertedOES = new List<Application_Course_Preference__c>();
            // Prepare ACPs based on Course Offerings and Preference Rank
                listACPsToBeInsertedOES= prepareACPs(mapCOACPOES);
                //listACPsToBeUpsertedOES.addAll(listACPsToBeInsertedOES);
                listACPsToBeUpsertedOES.addAll(listACPsToBeUpdatedOES);
                if(!listACPsToBeInsertedOES.isEmpty()){
                    upsert listACPsToBeInsertedOES;
                    listACPsToBeUpserted.addAll(listACPsToBeInsertedOES);
                }
            
            if(!listACPsToBeUpsertedOES.isEmpty()){
                upsert listACPsToBeUpsertedOES External_ID__c;
            }
            listACPsToBeUpserted.addAll(listACPsToBeUpsertedOES);
        }
        // Delete Old ACPs which are not present in the current list from GCP
        if (!mapOldACPsInAppn.isEmpty()) {
            delete mapOldACPsInAppn.values();
        }
        if (!mapOldACPsInAppnOES.isEmpty()) {
            delete mapOldACPsInAppnOES.values();
        }
        return listACPsToBeUpserted;
    }
        /**
     * @author      Vinothraja
     * @description Prepares ACPs for an Application based on the Course Offerings; Populates all the necessary fields in ACP 
     * @param       Map<String, Application_Course_Preference__c> Map of Course Offering IDs and ACPs
     * @return      List<Application_Course_Preference__c> updated ACP records ready for insert
     * @revision    16/05/2023 - Vinothraja - Created
     * @revision    24/05/2024 - Ben Greenland added additonal logic for OES
     */
    private static List<Application_Course_Preference__c> prepareACPs(Map<String, Application_Course_Preference__c> mapCOACP) {
        // get the reference course offerings
        String clause;
        if(!OESApplicationService.isOESUser){
            clause = 'Id IN (\''+ String.join(new List<String>(mapCOACP.keySet()),'\',\'') +'\')';
        }
        if(OESApplicationService.isOESUser){
            clause = 'Course_Offering_UID__c IN (\''+ String.join(new List<String>(mapCOACP.keySet()),'\',\'') +'\')';
        }
        Set<String> fieldset = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_COURSEOFFERINGS.split(','));
        // Set<String> fieldset = new Set<String> {'Id'};
        String query = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Course_Offering__c'))
                                            .queryFields(fieldset)
                                            .getQuery(clause);
        // Set the ACP fields based on the Course Offerings
        List<Application_Course_Preference__c> preparedACPs = new List<Application_Course_Preference__c>();
        for(Course_Offering__c selectedCourse : Database.query(query)) {
            Application_Course_Preference__c appCourse = new Application_Course_Preference__c();
            if(!OESApplicationService.isOESUser){
                appCourse = mapCOACP.get(selectedCourse.Id);
            }
            if(OESApplicationService.isOESUser){
    
                    appCourse = mapCOACP.get(selectedCourse.Course_Offering_UID__c);
            }
            // appCourse.Application__c = appId; // already set in the payload
            // appCourse.Applicant__c = applicationRecord.Applicant__c; // already set in the payload
            // appCourse.Course_Offering__c = selectedCourse.Id; // already set in the payload
            // appCourse.Preference_Number__c = mapCOPreferenceRank.get(selectedCourse.Id); // already set in the payload
            appCourse.Status__c = 'Open';
            appCourse.Academic_Calendar_Type__c = selectedCourse.Academic_Calendar_Type__c;
            appCourse.Academic_CI_Sequence_Number__c = selectedCourse.Academic_CI_Sequence_Number__c;
            appCourse.Admission_Calendar_Type__c = selectedCourse.Admission_Calendar_Type__c;
            appCourse.Admission_CI_Sequence_Number__c = selectedCourse.Admission_CI_Sequence_Number__c;
            appCourse.Attendance_Type__c = selectedCourse.Attendance_Type__c;
            appCourse.Attendance_Type_Description__c = selectedCourse.Attendance_Type_Description__c;
            appCourse.Commencement_Period__c = selectedCourse.Admission_Calendar_Description__c;
            appCourse.Course_Code__c = selectedCourse.Course_Code__c;
            appCourse.Course_Title__c = selectedCourse.Course_Title__c;
            appCourse.Course_Version_Number__c = selectedCourse.Course_Version_Number__c;
            appCourse.Location_Code__c = selectedCourse.Location_Code__c;
            appCourse.Location_Description__c = selectedCourse.Location_Description__c;
            appCourse.Attendance_Mode__c = selectedCourse.Attendance_Mode__c;
            appCourse.Attendance_Mode_Description__c = selectedCourse.Attendance_Mode_Description__c;
            appCourse.Type_of_Place_Code__c = selectedCourse.Type_of_Place_Code__c;
            appCourse.Type_of_Place_Description__c = selectedCourse.Type_of_Place_Description__c;

            Boolean hasUnitSet = false;
            if(selectedCourse.Unit_Set_Code__c != null) {
                hasUnitSet = true;
            }
            appCourse.Unit_Set_Code__c = (hasUnitSet)? selectedCourse.Unit_Set_Code__c: '';
            appCourse.Unit_Set_Description__c = (hasUnitSet)? selectedCourse.Unit_Set_Description__c: '';
            appCourse.Unit_Set_Version__c = (hasUnitSet)? selectedCourse.Unit_Set_Version__c: null;

            appCourse.Admission_Category__c = null;
            appCourse.Outcome_Status_LOV__r = null;
            appCourse.Conditional_Offer_Status_LOV__r = null;
            appCourse.Deferment_Status_LOV__r = null;
            appCourse.Documentation_Status_LOV__r = null;
            appCourse.Entry_Qualification_Status_LOV__r = null;
            appCourse.Fee_Category__c = null;
            appCourse.Offer_Response_Status_LOV__r=null;

            preparedACPs.add(appCourse);
        }

        return preparedACPs;
    }
    /**
     * @author      Vinothraja
     * @description Upserts Contact Qualifications of an Application; Deletes any record not available in the list
     * @param       List<Contact_Qualfication__c> Contact Qualifcation records
     * @return      List<Contact_Qualfication__c> updated records
     * @revision    11/05/2023 - Vinothraja - Created
     */
    public static List<Contact_Qualification__c> updateApplicationQualifications(String applicationId, List<Contact_Qualification__c> qualifications) {
        // Prepare a MAP of Existing Qualificationss 
        Map<Id, Contact_Qualification__c> mapOldQualificationsInAppn = new Map<Id, Contact_Qualification__c> ();
        //*** copado issue workaround for (Application_Qualification_Provided__c aqp : [SELECT id, Application__c, Contact_Qualification__c FROM Application_Qualification_Provided__c WHERE Application__c = :applicationId WITH SECURITY_ENFORCED]) {
	    for (Application_Qualification_Provided__c aqp : [SELECT id, Application__c, Contact_Qualification__c FROM Application_Qualification_Provided__c WHERE Application__c = :applicationId]) {
            mapOldQualificationsInAppn.put(aqp.Contact_Qualification__c, new Contact_Qualification__c(id = aqp.Contact_Qualification__c));
        }
        Schema.SObjectField fieldName = Work_Experience__c.Fields.External_ID__c;
        List<Database.UpsertResult> upResults = new List<Database.UpsertResult>();
        // Note: The IDs of newly inserted Experiences from GCP will not be present in the above map
        // Upsert current Qualifications 
        upResults = upsertDataBasedOnIdType(qualifications,fieldName);  
        // // Note: The IDs of newly inserted Qualifications from GCP will not be present in the above map
        // Database.upsert(qualifications);
        // Prepare junction object for newly inserted Qualifications
        List<Application_Qualification_Provided__c> listAQP = new List<Application_Qualification_Provided__c> ();
        for (Database.UpsertResult contactQualification : upResults) { // looping through the current Qualifications
            // If ID is not present it is a new qualification, attach to current application
            if (!mapOldQualificationsInAppn.containsKey(contactQualification.getId())){
                Application_Qualification_Provided__c aqp = new Application_Qualification_Provided__c();
                aqp.Contact_Qualification__c = contactQualification.getId();
                aqp.Application__c = applicationId;
                listAQP.add(aqp); 
            // If ID is present it is an Existing Qualifications
            } else { // remove existing Qualifications from the map, so it finally contains only Removed-in-GCP Qualifications
                mapOldQualificationsInAppn.remove(contactQualification.Id);
            }
        }
        // Create Junction object records, for the newly inserted Qualifications
        if (!listAQP.isEmpty()){
            Database.insert(listAQP);
        }
        // Delete Old Qualifications which are not present in the current list from GCP 
        if (!mapOldQualificationsInAppn.isEmpty()) {
            delete mapOldQualificationsInAppn.values();
        }

        return qualifications;
    }
    /**
     * @author      Vinothraja
     * @description Upserts Work Experiences of an Application; Deletes any record not available in the list
     * @param       List<Work_Experience__c> work experience records
     * @return      List<Work_Experience__c> updated records
     * @revision    11/05/2023 - Vinothraja - Created
     */
    public static List<Work_Experience__c> updateApplicationWorkExperiences(String applicationId, List<Work_Experience__c> experiences) {
        // Prepare a MAP of Existing Experiences 
        Map<Id, Work_Experience__c> mapOldExperiencesInAppn = new Map<Id, Work_Experience__c> ();
        ////*** copado issue workaround for (Application_Work_Experience_Provided__c awxp : [SELECT id, Application__c, Work_Experience__c FROM Application_Work_Experience_Provided__c WHERE Application__c = :applicationId WITH SECURITY_ENFORCED]) {
	for (Application_Work_Experience_Provided__c awxp : [SELECT id, Application__c, Work_Experience__c FROM Application_Work_Experience_Provided__c WHERE Application__c = :applicationId]) {
            mapOldExperiencesInAppn.put(awxp.Work_Experience__c, new Work_Experience__c(id = awxp.Work_Experience__c));
        }
        List<Database.UpsertResult> upResults = new List<Database.UpsertResult>();
        Schema.SObjectField fieldName = Work_Experience__c.Fields.External_ID__c;
        // Note: The IDs of newly inserted Experiences from GCP will not be present in the above map
        upResults = upsertDataBasedOnIdType(experiences,fieldName);        
        // Prepare junction object for newly inserted Experiences
        List<Application_Work_Experience_Provided__c> listAWXP = new List<Application_Work_Experience_Provided__c> ();

        for (Database.UpsertResult workExp : upResults) { // looping through the current Experiences
            // If ID is not present it is a new experiences, attach to current application
            if (!mapOldExperiencesInAppn.containsKey(workExp.getId())){
                Application_Work_Experience_Provided__c awxp = new Application_Work_Experience_Provided__c();
                awxp.Work_Experience__c = workExp.getId();
                awxp.Application__c = applicationId;
                listAWXP.add(awxp); 
            // If ID is present it is an Existing Experience
            } else { // remove existing Experiences from the map, so it finally contains only Removed-in-GCP Experiences
                mapOldExperiencesInAppn.remove(workExp.Id);
            }
        }
        // Create Junction object records, for the newly inserted Work Experiences

        if (!listAWXP.isEmpty()){
            Database.insert(listAWXP);
        }
        // Delete Old Work Experiences which are not present in the current list from GCP 
        if (!mapOldExperiencesInAppn.isEmpty()) {
            delete mapOldExperiencesInAppn.values();
        }

        return experiences;
    }
    /**
     * @author      Vinothraja
     * @description Creates an Agency Contact
     * @param       Contact Agency Contact
     * @return      Contact the created contact record
     * @revision    05/06/2023 - Vinothraja - Created
     */
    public static Contact createAgencyContact(Contact agencyContact) {
        insert agencyContact;
        return agencyContact;
    }
    /**
     * @author      Vinothraja
     * @description Freezes/Unfreezes an Agent(User)
     * @param       String Agent's user Id
     * @return      UserLogin the updated UserLogin record
     * @revision    12/06/2023 - Vinothraja - Created
     */
    public static UserLogin freezeUnFreezeUser(String userId, Boolean isFrozen) {
        ////*** copado issue workaround UserLogin ulogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :userId WITH SECURITY_ENFORCED];
    	UserLogin ulogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :userId];
        if (isFrozen != null){
            ulogin.IsFrozen = isFrozen;
            systemContext.patch(new List<SObject> {ulogin});
        }
        return ulogin;
    }
    /**
     * @author      Vinothraja
     * @description Creates a case for an Agent
     * @param       Case Enquiry object
     * @return      Case the created Case record
     * @revision    11/09/2023 - Vinothraja - Created
     */
    public static Case createEnquiry(Case enquiry) {
        insert enquiry;
        return enquiry;
    }
    /**
     * @author      Vinothraja
     * @description Gets the details of an Enquiry
     * @param       Case Enquiry object
     * @return      Case the created Case record
     * @revision    14/09/2023 - Vinothraja - Created
     */
    public static Case getEnquiryDetails(String caseId) {
        // AgentPortalPayload.ApplicationDetails application = getApplicationDetails(enquiry.crmApplicationId);
        String clause = 'id = \''+ caseId + '\'';
        Set<String> fieldset = new Set<String> (AgentPortalConstants.SEARCH_FIELDS_ENQUIRY.split(','));
        String query = DynamicSoqlBuilder.getInstance()
                                            .showSOQLStatement(true)
                                            .setEnforced(true)
                                            .querySObject(String.escapeSingleQuotes('Case'))
                                            .queryFields(fieldset)
                                            .getQuery(clause);
        List<Case> cases = (list<Case>) systemContext.query(query);
        if (!cases.isEmpty()) {
            return cases.get(0);
        }
        return null;
    }


    /**
    * @description generic method to upsert records based on externalId or Id
    * use 
    * @author Ben Greenland | 2024-06-19 
    * @param List<SObject> records 
    * @param Schema.SObjectField externalIdField  us Schema.SObjectField fieldName = <yourObject>.Fields.<yourField__c>;
    * @return List<Database.UpsertResult> 
    **/
    public static List<Database.UpsertResult> upsertDataBasedOnIdType(List<SObject> records, Schema.SObjectField externalIdField){
        // Process the records
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
        //create Lists for upsert results based on id used
        List<SObject> upsertOnExternalId = new List<SObject>();
        List<SObject> upsertOnId = new List<SObject>();
        for(SObject obj : records){
            System.debug(obj.get(externalIdField.getDescribe().getName()));
            if(obj.get(externalIdField.getDescribe().getName()) != null){//add external Ids to upsert list if no external id is present assume either new or record has existing 
                upsertOnExternalId.add(obj);
            }else{//add id based records to upsert list
                upsertOnId.add(obj);
            }
        }
        List<Database.UpsertResult> upResults = new List<Database.UpsertResult>(); //OES changes for external IDs
        if(upsertOnExternalId.size()>0){//upsert external Id records
            upsertResults.addAll(Database.upsert(upsertOnExternalId,externalIdField,false));
        }
        if(upsertOnId.size()>0){//upsert id records
            upsertResults.addAll(Database.upsert(upsertOnId));
        }  
        return upsertResults;
    }

    /**
     * @author      Vinothraja
     * @description Inner Without Sharing class, to facilitate running certain DML operations on a System context
     * @param       String applicantId 
     * @return      List<Application__c> 
     * @revision    01/05/2023 - Vinothraja - Created
     */
    public without sharing class RunSystemContext {
        /**
         * @author      Vinothraja
         * @description Method that inserts records in without sharing context
         */
        public void create(List<SObject> objToInsert) {
            Database.insert(objToInsert, true);
        }
        /**
         * @author      Vinothraja
         * @description Method that updates records in without sharing context
         */
        public void patch(List<SObject> objToUpdate) {
            Database.update(objToUpdate, true);
        }
        /**
         * @author      Vinothraja
         * @description Method that queries for records in without sharing context
         */
        public List<Object> query(String queryString){
            return Database.query(queryString);
        }
    }
}