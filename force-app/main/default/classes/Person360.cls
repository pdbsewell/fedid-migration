/**
 * @author Nick Guia
 * @date 07-09-2020
 * @group Person 360
 * @description responsible for building Person360 object records
 * @revision
 *   10.03.2022  Ibrahim Rumi    - EPBBS-2473 set AccountId as mandotory on  withAffiliation method
 *   04.07.2023  Nick Guia       - Added option to not create CPAs by default
 *   10.07.2023  Vinothraja      - Added logic to handle multiple CP & CPA creation, for a Contact Point. ex. Home & MobilePhone both using Phone__c
 *   17.07.2023  Nick Guia       - Removed CPA creation for Name__c
 *   26.02.2024  SMendu          - Added utility methods to build CPA for Email__c , Phone__c, Address__c contact points
 **/
public inherited sharing class Person360 {

    @TestVisible
    private final Account accRec;
    @TestVisible
    private final Contact conRec;
    @TestVisible
    private final Affiliation__c affRec;
    @TestVisible
    private final Map<String, List<Contact_Point_Affiliation__c>> cpaMap; // contact point sobject type => record
    @TestVisible
    private final Map<String, List<SObject>> contactPointMap; // sobject type => record

    @TestVisible
    private Person360(Person360Builder builder) {
        this.accRec = builder.accRec;
        this.conRec = builder.conRec;
        this.affRec = builder.affRec;
        this.cpaMap = builder.cpaMap;
        this.contactPointMap = builder.contactPointMap;
    }

    public Account getAccount() {
        return this.accRec;
    }

    public Contact getContact() {
        return this.conRec;
    }

    public Affiliation__c getAffiliation() {
        return this.affRec;
    }

    public Map<String, List<Contact_Point_Affiliation__c>> getContactPointAffiliationMap() {
        return this.cpaMap;
    }

    public Map<String, List<SObject>> getContactPointMap() {
        return this.contactPointMap;
    }

    public List<SObject> getContactPoint(String strObjType) {
        return this.contactPointMap.get(strObjType);
    }

    public virtual class Person360Builder {

        @TestVisible
        protected Account accRec;
        @TestVisible
        protected Contact conRec;
        @TestVisible
        protected Affiliation__c affRec;
        @TestVisible
        protected final Map<String, List<Contact_Point_Affiliation__c>> cpaMap; // contact point sobject type => record
        @TestVisible
        protected Map<String, List<SObject>> contactPointMap; // sobject type => record
        @TestVisible
        private final String AFFILIATION_CLASSIFICATION_DEFAULT = 'Private';
        @TestVisible
        private Boolean isCreateCPA = true; // option to not create CPAs by default

        public Person360Builder(Contact con) {
            this.conRec = con;
            this.accRec = getHouseHoldAccount();
            this.contactPointMap = new Map<String, List<SObject>>();
            this.cpaMap = new Map<String, List<Contact_Point_Affiliation__c>>();
        }

        public Person360Builder createContactPointAffiliations(Boolean isCreate) {
            this.isCreateCPA = isCreate;
            return this;
        }

        /**
        * @description for manually assigning an Affiliation record for the Contact
        * @param affRec : Affiliation record
        * @return Person360Builder 
        **/
        public Person360Builder withAffiliation(Affiliation__c affRec) {
            this.affRec = affRec;
            return this;
        }

        /**
        * @description build an Affiliation record for the Contact.
        *   Defaults classification to Private, and Start Date to current date.
        * @param affRecTypeDevName : String developer name of the affiliation record type
        * @param accountId: Id accountid for the related affiliation record
        **/
        public Person360Builder withAffiliation(Id accountId, String affRecTypeDevName) {
            return withAffiliation(accountId, affRecTypeDevName, Date.today());
        }

        /**
        * @description build an Affiliation record for the Contact
        * @param affRecTypeDevName : String developer name of the affiliation record type
        * @param accountId: Id accountid for the related affiliation record
        * @param startDate : start date of the affiliation
        * @return Person360Builder 
        * @revision
        *   04-07-2023  Nick Guia   - stopped auto creation of CPA by default
        **/
        public Person360Builder withAffiliation(Id accountId, String affRecTypeDevName, Date startDate) {

            Id recTypeId = Schema.SObjectType.Affiliation__c
                            .getRecordTypeInfosByDeveloperName()
                            .get(affRecTypeDevName)
                            .getRecordTypeId();
            this.affRec = new Affiliation__c(
                Account__c = accountId,
                RecordTypeId = recTypeId,
                Start_Date__c = startDate
            );
            return this;
        }

        /**
         * @description TODO
         * @param cp  
         * @return Person360Builder
         */
        public Person360Builder withAddress(Address__c cp) {
            addContactPoint(cp);
            createContactPointAffiliation('Address__c');
            return this;
        }

        /**
         * @description TODO
         * @param cp  
         * @return Person360Builder
         */
        public Person360Builder withEmail(Email__c cp) {
            addContactPoint(cp);
            createContactPointAffiliation('Email__c');
            return this;
        }

        /**
         * @description TODO
         * @param cp  
         * @return Person360Builder
         */
        public Person360Builder withPhone(Phone__c cp) {
            addContactPoint(cp);
            createContactPointAffiliation('Phone__c');
            return this;
        }

        /**
         * @description TODO
         * @param cp  
         * @return Person360Builder
         */
        public void withSocial(Social__c cp) {
            addContactPoint(cp);
            createContactPointAffiliation('Social__c');
            //return builder;
        }

        /**
        * @description generates an AddressContactPointBuilder to further
        *   build the Address record details
        * @return AddressContactPointBuilder 
        **/
        public ContactPointBuilderFactory.AddressContactPointBuilder buildAddress() {
            //contact ID may be null at this stage. if it is, the Person360BuilderDirector should resolve the dependencies
            ContactPointBuilderFactory factory = new ContactPointBuilderFactory(this.conRec.Id, new Address__c());
            ContactPointBuilderFactory.AddressContactPointBuilder builder = (ContactPointBuilderFactory.AddressContactPointBuilder) factory.createContactPoint();
            addContactPoint(builder.getContactPoint());
            // create a CPA for Address__c
            createContactPointAffiliation('Address__c');
            return builder;
        }

        /**
        * @description generates an EmailContactPointBuilder to further
        *   build the Email record details
        * @return EmailContactPointBuilder 
        **/
        public ContactPointBuilderFactory.EmailContactPointBuilder buildEmail() {
            // contact ID may be null at this stage. if it is, the Person360BuilderDirector should resolve the dependencies
            ContactPointBuilderFactory factory = new ContactPointBuilderFactory(this.conRec.Id, new Email__c());
            ContactPointBuilderFactory.EmailContactPointBuilder builder = (ContactPointBuilderFactory.EmailContactPointBuilder) factory.createContactPoint();
            addContactPoint(builder.getContactPoint());
            // create a CPA for Email__c
            createContactPointAffiliation('Email__c');
            return builder;
        }

        /**
        * @description generates an PhoneContactPointBuilder to further
        *   build the Phone record details
        * @return PhoneContactPointBuilder 
        **/
        public ContactPointBuilderFactory.PhoneContactPointBuilder buildPhone() {
            // contact ID may be null at this stage. if it is, the Person360BuilderDirector should resolve the dependencies
            ContactPointBuilderFactory factory = new ContactPointBuilderFactory(this.conRec.Id, new Phone__c());
            ContactPointBuilderFactory.PhoneContactPointBuilder builder = (ContactPointBuilderFactory.PhoneContactPointBuilder) factory.createContactPoint();
            addContactPoint(builder.getContactPoint());
            // create a CPA for Phone__c
            createContactPointAffiliation('Phone__c');
            return builder;
        }

        /**
        * @description generates an SocialContactPointBuilder to further
        *   build the Social record details
        * @return SocialContactPointBuilder 
        **/
        public ContactPointBuilderFactory.SocialContactPointBuilder buildSocial() {
            // contact ID may be null at this stage. if it is, the Person360BuilderDirector should resolve the dependencies
            ContactPointBuilderFactory factory = new ContactPointBuilderFactory(this.conRec.Id, new Social__c());
            ContactPointBuilderFactory.SocialContactPointBuilder builder = (ContactPointBuilderFactory.SocialContactPointBuilder) factory.createContactPoint();
            addContactPoint(builder.getContactPoint());
            // create a CPA for Social__c
            createContactPointAffiliation('Social__c');
            return builder;
        }

        /**
        * @description generates an NameContactPointBuilder to further
        *   build the Name record details
        * @return NameContactPointBuilder 
        **/
        public ContactPointBuilderFactory.NameContactPointBuilder buildName() {
            // contact ID may be null at this stage. if it is, the Person360BuilderDirector should resolve the dependencies
            ContactPointBuilderFactory factory = new ContactPointBuilderFactory(this.conRec.Id, new Name__c());
            ContactPointBuilderFactory.NameContactPointBuilder builder = (ContactPointBuilderFactory.NameContactPointBuilder) factory.createContactPoint();
            addContactPoint(builder.getContactPoint());
            // we don't create CPAs for Name
            return builder;
        }
        
        /**
        * @description builds an immutable class of Person360 records
        * @return Person360 : immutable Person360 class instance 
        **/
        public virtual Person360 build() {
            return new Person360(this);
        }
        
        /**
        * @description for storing the created Contact Point record
        * @param cp : the Contact Point record to be stored
        **/
        @TestVisible
        protected void addContactPoint(SObject cp) {
            if(cp==null) return;
            String devName = cp.getSObjectType().getDescribe().getName();
            List<SObject> cpList = this.contactPointMap.containsKey(devName) ? this.contactPointMap.get(devName) : new List<SObject> ();
            cpList.add(cp);
            this.contactPointMap.put(devName, cpList);
        }

        /**
        * @description create a Contact Point Affiliation record
        **/
        @TestVisible
        protected void createContactPointAffiliation(String contactPointDevName) {
            if(isCreateCPA) {
                //contact ID may be null at this stage. if it is, the Person360BuilderDirector should resolve the dependencies
                Contact_Point_Affiliation__c cpa = new Contact_Point_Affiliation__c(Contact__c = this.conRec.Id);
                addContactPointAffiliation(cpa, contactPointDevName);
            }
        }

        /**
        * @description adds the contact point affiliation in the collection
        **/
        @TestVisible
        protected void addContactPointAffiliation(Contact_Point_Affiliation__c cpa, String contactPointDevName) {
            List<SObject> cpaList = this.cpaMap.containsKey(contactPointDevName) ? this.cpaMap.get(contactPointDevName) : new List<SObject> ();   
            cpaList.add(cpa);
            cpaMap.put(contactPointDevName, cpaList);
        }

        /**
        * @description if the account already has a linked Account, creates an instance
        *   of that account. Otherwise, create a new HouseHold account
        * @author Nick Guia | 09-08-2020 
        * @return Account 
        **/
        @TestVisible
        protected virtual Account getHouseHoldAccount() {
            Account acc;
            Id recTypeHouseHold = Schema.SObjectType.Account
                                .getRecordTypeInfosByDeveloperName()
                                .get('Household_Account')
                                .getRecordTypeId();
            if(this.conRec.AccountId == null) {
                //contact doesn't have an account yet, create a household account
                acc = new Account(Name = this.conRec.FirstName + ' ' + this.conRec.LastName);
            } else {
                //else, get existing Contact's account
                acc = new Account(Id = conRec.AccountId);
            }
            acc.RecordTypeId = recTypeHouseHold;
            return acc;
        }
    }
}