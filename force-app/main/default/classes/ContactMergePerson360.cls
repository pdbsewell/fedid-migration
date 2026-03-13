/**
 * @description       : Responsible doing the merge logic to Affiliation, CPAs, and Contact Points
 * @author            : Nick Guia
 * @date              : 11-07-2023
 * @group             : Contact Merge
 * @last modified on  : 04-09-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/286688267/Contact+Merge+Person+360
 * @revision
 *  04-08-2023  Nick Guia   - updated code structure to cater for bulk merging of multiple contact IDs
 *  04-09-2023  Nick Guia   - defaults Share_Force_Recalculation__c to System.now() everytime we do a merge
 * @example
 * 
 *  // merges everything within the P360 data structure
 *  Boolean isSucess = new ContactMergePerson360(Set<Id> contactIds).mergePerson360();
 * 
 *  OR
 *  
 *  // only touches Affiliations and CPAs related to Applicant
 *  Boolean isSucess = new ContactMergePerson360(Set<Id> contactIds).byAffiliation('Applicant').mergePerson360();
**/
public virtual inherited sharing class ContactMergePerson360 {

    @TestVisible
    private Map<Id, ContactMergePerson360DAO> conMergeP360ByContactId;
    @TestVisible
    private ContactMergeSelector selector;
    @TestVisible
    private ContactMergeP360Director director;

    // options
    @TestVisible
    private Boolean shouldRecalculatePrimary = true;
    @TestVisible
    private String affRecType;

    public ContactMergePerson360(Id contactId) {
        this(new Set<Id> { contactId }, new ContactMergeSelector(new Set<Id> { contactId }), new ContactMergeP360Director());
    }

    public ContactMergePerson360(Set<Id> contactIds) {
        this(contactIds, new ContactMergeSelector(contactIds), new ContactMergeP360Director());
    }

    /**
    * @description Use this if you want to merge P360 records only for a specific Affiliation
    * @author Nick Guia | 11-07-2023 
    * @param String recTypeDevName : Affiliation record type (developer name)
    * @return ContactMergePerson360 
    **/
    public ContactMergePerson360 byAffiliation(String recTypeDevName) {
        this.affRecType = recTypeDevName;
        return this;
    }

    /**
    * @description if set to true, the contact merge will also calculate the new primary contact points
    * @author Nick Guia | 03-08-2023 
    * @param Boolean shouldRecalc 
    * @return ContactMergePerson360 
    **/
    public ContactMergePerson360 recalculatePrimaryContactPoints(Boolean shouldRecalc) {
        this.shouldRecalculatePrimary = shouldRecalc;
        return this;
    }
    
    /**
    * @description runs the steps for merging multiple P360 instances
    * @author Nick Guia | 18-07-2023 
    * @throws BaseClass.BaseClassException
    * @return Boolean : returns true if the records commit is successful
    **/
    public BaseClass.ResultSet mergePerson360() {
        
        buildDAOMap();
        buildPerson360ListForDAO();

        // merge all Person 360 List for each DAO class
        for(ContactMergePerson360DAO dao : this.conMergeP360ByContactId.values()) {
            // resolve all dependencies
            this.director.resolveDependencies(dao.p360List); 
            if(this.shouldRecalculatePrimary) {
                // recalculate the new primary
                this.director.calculatePrimaryContactPoints(dao.con.Is_Student__c); 
            }
        }

        // commit records
        BaseClass.ResultSet rs = this.director.commitRecordsPartial();
        
        // convert the set of IDs to Set of String because it's what to roll up accepts
        Set<String> contactIdStrSet = new Set<String>( (List<String>)new List<Id>( this.conMergeP360ByContactId.keySet() ) );
        // roll up the new primaries
        Person360RollUpServices.invokeRollUp(
            contactIdStrSet,
            new List<String>{
                'Address__c',
                'Email__c',
                'Phone__c',
                'Name__c'
            }
        );
        
        return rs;
    }

    /**
    * @description query all P360 records and build a DAO class for each unique Contact
    * @author Nick Guia | 11-07-2023 
    * @throws ContactMergePerson360DeveloperException
    **/
    @TestVisible
    private Map<Id, ContactMergePerson360DAO> buildDAOMap() {

        if(this.conMergeP360ByContactId != null && !this.conMergeP360ByContactId.isEmpty()) {

            // collect all records
            Map<Id, Contact> contactMap = this.selector.selectContacts(); // this is required to get is_student__c for primary calculation
            Map<Id, List<Affiliation__c>> affiliationsByContactId = selector.selectAffiliationsGroupedByContactId(this.affRecType);
            Map<Id, List<Name__c>> namesByContactId = selector.selectNamesGroupedByContactId();
            Map<Id, List<Phone__c>> phonesByContactId = selector.selectPhonesGroupedByContactId();
            Map<Id, List<Address__c>> addressesByContactId = selector.selectAddressesGroupedByContactId();
            Map<Id, List<Email__c>> emailByContactId = selector.selectEmailsGroupedByContactId();
            Map<Id, List<Contact_Point_Affiliation__c>> cpaByContactId = selector.selectCPAsGroupedByContactId();

            // store all related records in their own DAO maps
            for(Id conId : contactMap.keySet()) {
                ContactMergePerson360DAO dao = this.conMergeP360ByContactId.get(conId);
                dao.con = contactMap.get(conId); // put the full context of the contact record

                // set affiliation
                dao.setAffiliation(affiliationsByContactId.get(conId));
                
                // set contact points
                dao.contactPointMap.put('Name__c', namesByContactId.get(conId));
                dao.contactPointMap.put('Phone__c', phonesByContactId.get(conId));
                dao.contactPointMap.put('Address__c', addressesByContactId.get(conId));
                dao.contactPointMap.put('Email__c', emailByContactId.get(conId));

                // set CPAs
                dao.setCPAByAffiliation(cpaByContactId.get(conId));
            }

        } else {
            throw new ContactMergePerson360DeveloperException('Unable to query child records because the DAO map is null or empty');
        }
        return this.conMergeP360ByContactId;
    }

    /**
    * @description for each ContactMergePerson360DAO, build a List of Person360 data structure
    *   Each instance of the Person 360 is based on a unique Affiliation.
    * @author Nick Guia | 11-07-2023 
    * @return List<Person360> 
    **/
    @TestVisible
    private Map<Id, ContactMergePerson360DAO> buildPerson360ListForDAO() {

        for(ContactMergePerson360DAO dao : this.conMergeP360ByContactId.values()) {

            List<Person360> iP360List = new List<Person360>();
            ContactMergePerson360Builder builder; 

            /**
             * first, create a person 360 instance with just the contact points
             * this covers the scenario of when the Contact simply doesn't have
             * any affiliations or CPAs
             */
            builder = new ContactMergePerson360Builder(dao.con);
            addAllContactPointsToBuilder(builder, dao);
            iP360List.add(builder.build());

            // then, create a P360 instance for each Affiliation
            for(Id iAffId : dao.affiliationMap.keySet()) {
            
                Affiliation__c affRec = dao.affiliationMap.get(iAffId);
                List<Contact_Point_Affiliation__c> cpaList = dao.cpaMapByAffiliationId.get(affRec.Id);
    
                builder = new ContactMergePerson360Builder(dao.con);
                builder.withAffiliation(affRec);
    
                // add all CPAs and CPs related to this affiliation
                if(cpaList != null) {
                    for(Contact_Point_Affiliation__c iCPA : cpaList) {
                        Id cpId = ContactPointUtility.getContactPointIdFromCPA(iCPA);
                        builder.withContactPointAffiliation(iCPA, cpId.getSObjectType().getDescribe().getName());
                    }
                }
                // add all contact points
                addAllContactPointsToBuilder(builder, dao);
                // build a p360 instance
                iP360List.add(builder.build());
            }
            dao.p360List = iP360List;
        }
        return this.conMergeP360ByContactId;
    }

    /**
    * @description Adds all contact points within the P360 instance
    * @author Nick Guia | 19-07-2023 
    * @param ContactMergePerson360Builder builder 
    **/
    @TestVisible
    private void addAllContactPointsToBuilder(ContactMergePerson360Builder builder, ContactMergePerson360DAO dao) {
        // add all contact points. The List types should retain the order of survivorship
        for(String sObjKey : dao.contactPointMap.keySet()) {
            List<SObject> contactPoints = dao.contactPointMap.get(sObjKey);
            if(contactPoints != null) {
                builder.withContactPoints(contactPoints);
            }
        }
    }

    /**
    * @description instantiates a new ContactMergePerson360DAO for each unique contact
    * @author Nick Guia | 04-08-2023 
    * @param Set<Id> contactIds 
    * @return Map<Id, ContactMergePerson360DAO> 
    **/
    @TestVisible
    private Map<Id, ContactMergePerson360DAO> buildContactMergeP360DAO(Set<Id> contactIds) {
        Map<Id, ContactMergePerson360DAO> cmP360ByContactId = new Map<Id, ContactMergePerson360DAO>();

        for(Id conId : contactIds) {
            ContactMergePerson360DAO dao = new ContactMergePerson360DAO(conId);
            cmP360ByContactId.put(conId, dao);
        }

        return cmP360ByContactId;
    }

    @TestVisible // inject dependencies for mocking
    private ContactMergePerson360(Set<Id> contactIds, ContactMergeSelector sel, ContactMergeP360Director dir) {
        if(contactIds == null || contactIds.isEmpty()) {
            throw new ContactMergePerson360Exception('Contact IDs cannot be null or empty');
        }
        this.selector = sel;
        this.director = dir;
        this.conMergeP360ByContactId = buildContactMergeP360DAO(contactIds);
    }

    /**
     * @description responsible for putting together a P360 model based on the existing records
     * @author Nick Guia | 11-07-2023 
    **/
    public class ContactMergePerson360Builder extends Person360.Person360Builder {

        public ContactMergePerson360Builder(Contact con) {
            super(con);
        }

        /**
        * @description recalculate keys, then generate the P360 instance
        * @author Nick Guia | 12-07-2023 
        * @return Person360 
        **/
        public override Person360 build() {
            recalculateKeys();
            forceSharingRecalculationOnAffiliation();
            return super.build();
        }

        /**
        * @description adds a contact point affiliation in the collection
        * @author Nick Guia | 11-07-2023 
        * @param Contact_Point_Affiliation__c cpa 
        * @param String contactPointType : contact point developer name
        * @return ContactMergePerson360Builder 
        **/
        public ContactMergePerson360Builder withContactPointAffiliation(Contact_Point_Affiliation__c cpa, String contactPointType) {
            super.addContactPointAffiliation(cpa, contactPointType);
            return this;
        }

        /**
        * @description adds a contact point in the collection
        * @author Nick Guia | 11-07-2023 
        * @param SObject contactPoint 
        * @return ContactMergePerson360Builder 
        **/
        public ContactMergePerson360Builder withContactPoint(SObject contactPoint) {
            super.addContactPoint(contactPoint);
            return this;
        }

        /**
        * @description adds a List of contact point in the collection
        * @author Nick Guia | 11-07-2023 
        * @param SObject contactPoint 
        * @return ContactMergePerson360Builder 
        **/
        public ContactMergePerson360Builder withContactPoints(List<SObject> contactPointList) {
            for(Sobject contactPoint : contactPointList) {
                withContactPoint(contactPoint);
            }
            return this;
        }

        /**
        * @description recalculate Affiliation Key and Contact Points hash
        * @author Nick Guia | 12-07-2023 
        **/
        @TestVisible
        private void recalculateKeys() {
            // repopulate hash key of affiliation
            recalculateAffiliationKey();
            // repopulate hash key of all contact points
            recalculateContactPointHash();
            // CPA keys won't be recalculated at this stage, the director class will handle that
        }

        /**
        * @description timestamps the Share_Force_Recalculation__c field to recalculate sharing upon merge.
        *   This is to make sure that sharing to Partner accounts get recalculated in the event that the previously
        *   shared Contact record loses the merge.
        * @author Nick Guia | 04-09-2023 
        **/
        @TestVisible
        private void forceSharingRecalculationOnAffiliation() {
            if(super.affRec != null) {
                super.affRec.Share_Force_Recalculation__c = System.now();
            }
        }

        /**
        * @description recalculate Affiliation Key
        * @author Nick Guia | 12-07-2023 
        **/
        @TestVisible
        private void recalculateAffiliationKey() {
            if(super.affRec != null) {
                super.affRec.Composite_Key__c = ContactPointUtility.getAffiliationKey(super.affRec);
            }
        }

        /**
        * @description recalculate hash key of all contact points
        * @author Nick Guia | 12-07-2023 
        **/
        @TestVisible
        private void recalculateContactPointHash() {
            for(String key : super.contactPointMap.keySet()) {
                List<SObject> cpList = super.contactPointMap.get(key);

                for(SObject iSObj : cpList) {
                    Set<String> keySet = ContactPointUtility.getContactPointSObjectKey(iSObj);
                    String hashKey = Person360Helper.generatePerson360Key(keySet);
                    iSObj.put('Key_UID__c', hashKey); // assumption : API name of hash keys for ALL contact points are the same
                }
            }
        }

        // I don't need Account here, so overriding super class constructor-referenced method
        protected override Account getHouseHoldAccount() {
            return null;
        }
    }

    /**
     * @description this DAO class serves as a 'helper' to bulkify processing
     * of P360 merge for multiple contact records
     */
    public class ContactMergePerson360DAO {
        public Contact con { get; set; }
        public Map<Id, Affiliation__c> affiliationMap { get; set; }
        public Map<String, List<SObject>> contactPointMap { get; set; } // SObject Type => List<SObjects>
        public Map<Id, List<Contact_Point_Affiliation__c>> cpaMapByAffiliationId {get; set;} // Affiliation ID => List<Contact_Point_Affiliation__c>
        public List<Person360> p360List { get; set; }

        public ContactMergePerson360DAO(Id contactId) {
            this.con = new Contact(Id = contactId);
            this.affiliationMap = new Map<Id,Affiliation__c>();
            this.contactPointMap = new Map<String, List<SObject>>();
            this.cpaMapByAffiliationId = new Map<Id, List<Contact_Point_Affiliation__c>>();
            this.p360List = new List<Person360>();
        }

        public void setAffiliation(List<Affiliation__c>  affList) {
            if(affList != null) {
                this.affiliationMap = new Map<Id, Affiliation__c>(affList);
            }
        }

        // create a map of Affiliation ID => CPA
        public void setCPAByAffiliation(List<Contact_Point_Affiliation__c> cpaList) {
            this.cpaMapByAffiliationId = new Map<Id, List<Contact_Point_Affiliation__c>>();

            if(cpaList != null) {
                for(Contact_Point_Affiliation__c iCPA : cpaList) {
                    List<Contact_Point_Affiliation__c> iList = this.cpaMapByAffiliationId.get(iCPA.Affiliation__c);
                    if(iList == null) {
                        iList = new List<Contact_Point_Affiliation__c>();
                    }
                    iList.add(iCPA);
                    this.cpaMapByAffiliationId.put(iCPA.Affiliation__c, iList);
                }
            }
        }
    }

    public class ContactMergePerson360Exception extends Exception { }

    public class ContactMergePerson360DeveloperException extends Exception { }
}