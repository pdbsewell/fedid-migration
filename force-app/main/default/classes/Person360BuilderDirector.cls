/**
 * @author Nick Guia
 * @date 08-09-2020
 * @group Person 360
 * @description : responsible for assembling the person360 objects together (resolving IDs and relationships)
 * @revision
 *   OCT.03.2022  Ibrahim Rumi    - EPBBS-2473 remove resolving of Affiliation and account dependency on resolveDependencies()
 *   OCT.07.2023  Vinothraja      - SFTG-3397 Handle a Multiple Contact Points & their affiliations on resolveDependencies()
 *   MAR.04.2024  Nick Guia       - Introduced the Options class; deprecated resolveContactPointsWithExternalId()
 **/
public virtual class Person360BuilderDirector {

    @TestVisible
    private Options opt;
    @TestVisible
    protected BaseClass bc;
    //for caching sobject field maps
    @TestVisible
    private Map<String, Map<String, Schema.SObjectField>> sObjFields;
    // cache for sobject ID to prevent duplicate commits
    @TestVisible
    private Map<Id, SObject> sObjRegister;
    //stores the order on how the sobjects should be committed in the database
    @TestVisible
    private final List<Schema.SObjectType> commitOrder = 
        new List<Schema.SObjectType> {
            Account.SObjectType,
            Contact.SObjectType,
            Affiliation__c.SObjectType,
            Address__c.SObjectType,
            Email__c.SObjectType,
            Phone__c.SObjectType,
            Social__c.SObjectType,
            Name__c.SObjectType,
            Contact_Point_Affiliation__c.SObjectType
        };
    //list of Contact Points which are not linked to Contact Point Affiliation (CPA)
    @TestVisible
    private final Set<String> cpaSkippedContactPoints = 
        new Set<String>{
            'Name__c'
        };
    @TestVisible
    private Boolean isLinkCpaExtId = false; // deprecated
    
    // initialise with existing BaseClass instance
    public Person360BuilderDirector(BaseClass bc) {
        this.bc = bc;
        init();
    }

    // initialise with default commit order
    public Person360BuilderDirector() {
        this.bc = new BaseClass(commitOrder);
        init();
    }
    
    // initialise with specific commit order
    public Person360BuilderDirector(List<Schema.SObjectType> cOrder) {
        this.bc = new BaseClass(cOrder);
        init();
    }

    /**
    * @description resolves the Person360 relationship (bulk processing)
    * @param p360List : List of Person360 class instance
    **/
    public virtual Person360BuilderDirector resolveDependencies(List<Person360> p360List) {
        for(Person360 iP360 : p360List) {
            resolveDependencies(iP360);
        }
        return this;
    }

    /**
    * @description resolves the Person360 relationship (bulk processing)
    * @param p360List : List of Person360 class instance
    **/
    public virtual Person360BuilderDirector resolveDependencies(List<Person360> p360List, Options op) {
        this.opt = op;
        for(Person360 iP360 : p360List) {
            resolveDependencies(iP360);
        }
        return this;
    }

    /**
     * @description resolves the Person360 relationship
     * @param p360  a Person360 instance
     * @param op    allows altering the behaviour of resolving object relationship
     */
    public virtual Person360BuilderDirector resolveDependencies(Person360 p360, Options op) {
        this.opt = op;
        resolveDependencies(p360);
        return this;
    }

    /**
    * @description resolves the Person360 relationship
    * @param p360 : Person360 class instance
    **/
    public virtual Person360BuilderDirector resolveDependencies(Person360 p360) {

        // STEP 1 : resolve Account => Contact dependency
        resolveAccount(p360.getAccount(), p360.getContact());
        resolveContact(p360.getContact());

        // STEP 2 : resolve Affiliation => Contact dependency
        resolveAffiliation(p360.getContact(), p360.getAffiliation());
        
        /**
         * STEP 3 : 
         * - resolve Affiliation => Contact dependency
         * - resolve Contact Point Affiliations =>
         *  - Contact
         *  - Affiliation
         *  - Contact Points
         */
        resolveContactPointsAndCPAs(p360);

        return this;
    }

    /**
    * @description commit records (all or none).
    * @return Boolean 
    **/
    public Boolean commitRecords() {
        return this.bc.commitRecords();
    }

    /**
    * @description partial commit records (all or none).
    * @return BaseClass.ResultSet 
    **/
    public BaseClass.ResultSet commitRecordsPartial() {
        return this.bc.commitRecordsPartial();
    }

    /**
    * @description returns instance of BaseClass if needed for further processing
    * @return BaseClass 
    **/
    public BaseClass getBaseClass() {
        return this.bc;
    }

    /**
     * @description link Contact Points with Contact Point Affiliations using External ID (Key_UID__c)
     * This is for use cases where the context isn't aware if the Contact Points already exists or not
     * @deprecated (MAR.04.204): use Options class instead
     */
    public virtual Person360BuilderDirector resolveContactPointsWithExternalId() {
        this.isLinkCpaExtId = true;
        return this;
    }

    /**
     * @description commit the account record. A Household Account is required
     * hence, will be pushed as required if the contact doesn't have one linked yet.
     * @param acc   
     * @param con   
     */
    @TestVisible
    private void resolveAccount(Account acc, Contact con) {
        if(acc.Id == null) {
            // if account doesn't exist yet, commit - (required)
            this.bc.push(acc);
            this.bc.relate(con, Contact.AccountId, acc);
        }
    }

    /**
     * @description commit the contact record
     * @param con   
     */
    @TestVisible
    private void resolveContact(Contact con) {
        if(this.opt.commitContact) {
            this.bc.push(con);
        }
    }

    /**
     * @description commit the Affiliation record and resolve lookup with Contact
     * @param aff   
     * @param con   
     */
    @TestVisible
    private void resolveAffiliation(Contact con, Affiliation__c aff) {
        if(aff != null && this.opt.commitAffiliation) {
            this.bc.relate(aff, Affiliation__c.Contact__c, con);
            this.bc.push(aff);
        }
    }

    /**
     * @description commit the Contact Points and (optionally) resolve the CPA relationship between
     * each contact point and affiliation (CPA).
     * If CPAs exist as part of the builder class, it is implied that they will be committed.
     * Otherwise, set the createContactPointAffiliations() to false in Person360.Person360Builder
     * @param p360   
     */
    @TestVisible
    private void resolveContactPointsAndCPAs(Person360 p360) {

        Map<String, List<Contact_Point_Affiliation__c>> cpaMap = p360.getContactPointAffiliationMap();
        Map<String, List<SObject>> contactPointMap = p360.getContactPointMap();
        Contact con = p360.getContact();
        Affiliation__c aff = p360.getAffiliation();
        
        for(String cpSObjType : contactPointMap.keySet()) {
            /**
             * Multiple contact points may exist of the same sObject. 
             * ex. 2 Phone__c records, 1 for each of Mobile and Landline
             */
            List<SObject> lstSObj = contactPointMap.get(cpSObjType);

            // shallow clone the sObject's list of CPA records -- will be used as a stack 
            List<Contact_Point_Affiliation__c> lstCPA = cpaMap.get(cpSObjType)?.clone(); 

            // resolve Contact Points => Contact
            for (SObject iSObj : lstSObj) {

                if(this.opt.commitContactPoints) {
                    if(con.Id == null) {
                        /**
                         * if contact does not have an ID yet, the ContactPointBuilder wouldn't have been able to link the records.
                         * We'll need to link it here instead
                         */
                        Schema.SObjectField contactField = getSObjectField(iSObj, 'Contact__c');
                        this.bc.relate(iSobj, contactField, con);
                    }
    
                    this.bc.push(iSobj);
                }

                /**
                 * resolve Contact Point Affiliations =>
                 * - Contact
                 * - Affiliation
                 * - Contact Points
                 */
				if(aff != null && lstCPA != null && !cpaSkippedContactPoints.contains(cpSObjType)) {
                    /**
                     * Pop the top most CPA record for linking
                     * Note: This relies on the order of CPA records
                     */
                    Contact_Point_Affiliation__c cpa = lstCPA.remove(0); 
                    this.bc.relate(cpa, Contact_Point_Affiliation__c.Contact__c, con);
                    this.bc.relate(cpa, Contact_Point_Affiliation__c.Affiliation__c, aff);
                    linkContactPointAffiliation(cpa, iSObj);
                    this.bc.push(cpa);
                }
            }
        }
    }

    /**
     * @description link Contact Point Affiliation record to Contact Point. If isLinkCpaExtId
     * is set, use External Id (Key_UID__c) to link the records. Otherwise, link via record ID
     * @param cpa : Contact Point Affiliation record to be linked to Contact Point
     * @param contactPoint : Contact Point record to be linked to Contact Point Affiliation
     */
    protected virtual void linkContactPointAffiliation(Contact_Point_Affiliation__c cpa, SObject contactPoint) {
        String cpSObjType = contactPoint.getSObjectType().getDescribe().getName();
        String lookupFieldName; //lookup field to Contact Point

        switch on cpSObjType {
            when 'Address__c' {
                if(this.isLinkCpaExtId || this.opt.useExternalId) {
                    //link via external ID
                    String uid = (String) contactPoint.get('Key_UID__c');
                    if(String.isBlank(uid)) {
                        new AddressTriggerHandler.PopulateHash().process(contactPoint);
                        uid = (String) contactPoint.get('Key_UID__c');
                    }
                    cpa.Address__r = new Address__c(Key_UID__c = uid);
                } else {
                    //link via ID
                    lookupFieldName = 'Address__c';
                }
            }
            when 'Email__c' {
                if(this.isLinkCpaExtId || this.opt.useExternalId) {
                    //link via external ID
                    String uid = (String) contactPoint.get('Key_UID__c');
                    if(String.isBlank(uid)) {
                        new EmailTriggerHandler.PopulateHash().process(contactPoint);
                        uid = (String) contactPoint.get('Key_UID__c');
                    }
                    cpa.Email__r = new Email__c(Key_UID__c = uid);
                } else {
                    //link via ID
                    lookupFieldName = 'Email__c';
                }
            }
            when 'Phone__c' {
                if(this.isLinkCpaExtId || this.opt.useExternalId) {
                    //link via external ID
                    String uid = (String) contactPoint.get('Key_UID__c');
                    if(String.isBlank(uid)) {
                        new PhoneTriggerHandler.PopulateHash().process(contactPoint);
                        uid = (String) contactPoint.get('Key_UID__c');
                    }
                    cpa.Phone__r = new Phone__c(Key_UID__c = uid);
                } else {
                    //link via ID
                    lookupFieldName = 'Phone__c';
                }
            }
            when 'Social__c' {
                if(this.isLinkCpaExtId || this.opt.useExternalId) {
                    //link via external ID
                    String uid = (String) contactPoint.get('Key_UID__c');
                    if(String.isBlank(uid)) {
                        new SocialTriggerHandler.PopulateHash().process(contactPoint);
                        uid = (String) contactPoint.get('Key_UID__c');
                    }
                    cpa.Social__r = new Social__c(Key_UID__c = uid);
                } else {
                    //link via ID
                    lookupFieldName = 'Social__c';
                }
            }
            when else {
                //do nothing
                System.debug(LoggingLevel.WARN, 'Unsupported Contact Point SObject Type : ' + cpSObjType);
            }
        }

        if(String.isNotBlank(lookupFieldName) && !this.isLinkCpaExtId && !this.opt.useExternalId) {
            Schema.SObjectField cpaField = getSObjectField(cpa, lookupFieldName);
            this.bc.relate(cpa, cpaField, contactPoint);
        }
    }
    
    /**
    * @description for getting the Schema.SObjectField from the cached map
    * @param sobj : the SObject record
    * @param sObjFieldName : API name of the SObject field
    * @return Schema.SObjectField 
    **/
    protected Schema.SObjectField getSObjectField(SObject sobj, String sObjFieldName) {
        String sObjName = sobj.getSObjectType().getDescribe().getName();
        Map<String, Schema.SObjectField> fieldMap = sObjFields.get(sObjName);
        if(fieldMap == null) {
            fieldMap = sobj.getSObjectType().getDescribe().fields.getMap();
            sObjFields.put(sObjName, fieldMap);
        }
        return fieldMap.get(sObjFieldName);
    }

    /**
     * @description initialise
     */
    private void init() {
        this.opt = new Options();
        this.sObjFields = new Map<String, Map<String, Schema.SObjectField>>();
        this.sObjRegister = new Map<Id, SObject>();
    }

    /**
     * @description class to allow more options to alter the default 
     * behaviour of the builder
     */
    public class Options {
        /**
         * if set to false, the contact record will not be
         * inserted or updated
         */
        public Boolean commitContact { get; set; }
        /**
         * if set to false, the affiliation record will not be
         * inserted or updated
         */
        public Boolean commitAffiliation { get; set; }
        /**
         * if set to false, the contact point records will not be
         * inserted or updated
         */
        public Boolean commitContactPoints { get; set; }
        /**
         * if set to true, external IDs will be used to link
         * CPAs and contact points
         */
        public Boolean useExternalId { get; set; }

        public Options() {
            // set default behaviours
            this.commitContact = true;
            this.commitAffiliation = true;
            this.commitContactPoints = true;
            this.useExternalId = false;
        }
    }
}