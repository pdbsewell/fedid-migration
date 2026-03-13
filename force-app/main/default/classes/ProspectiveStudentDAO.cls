/**
 * @Description        : Data access object for Prospective Student.
 *                       Extend this to Person360DAO once we are ready to adapt
 *                       the Person360 model.
 * @Author             : Nick Guia
 * @Group              : Lead Management
 * TO BE DEPRECATED AFTER MOVING TO V2
 */
public virtual inherited sharing class ProspectiveStudentDAO 
    implements IContact360, IProspectiveStudentLead, IProspectiveStudentCampaign 
{
    @TestVisible
    protected Contact360 con360 {get; set;}
    @TestVisible
    protected ProspectiveStudentLeadDAO psLead;
    @TestVisible
    protected ProspectiveStudentCampaignDAO psCampaigns;
    @TestVisible
    private List<Contact_Qualification__c> contactQualifications;
    @TestVisible
    private List<Case> caseList;
    
    public ProspectiveStudentDAO() {
        this.con360 = new Contact360();
        this.psCampaigns = new ProspectiveStudentCampaignDAO();
        this.contactQualifications = new List<Contact_Qualification__c>();
        this.caseList = new List<Case>();
    }
    
    /**
    * @description Sets the Contact record related to this Prospective Student
    * @param Contact con : related Contact record
    * @return void
    */
    public void setPerson(Contact con) {
        this.con360.setPerson(con);
    }

    /**
    * @description retrieves the Contact record related to this Prospective Student
    * @return Contact : related Contact record
    */
    public Contact getPerson() {
        return this.con360.getPerson();
    }

    /**
    * @description Sets the Prospective Student Role record related to this Prospective Student
    * @param Roles__c roleRec : related Prospective Student Role
    * @return void
    */
    public void setPersonRole(Roles__c roleRec) {
        this.con360.setPersonRole(roleRec);
    }

    /**
    * @description retrieves the Prospective Student Role record related to this Prospective Student
    * @return Roles__c : related Prospective Student Role
    */
    public Roles__c getPersonRole() {
        return this.con360.getPersonRole();
    }

    /**
    * @description Sets the Prospective Student's Channel record for the Prospective Student
    * @param Channel__c channelRec : Prospective Student's Channel record
    * @return void
    */
    public void setPersonChannel(Channel__c channelRec) {
        this.con360.setPersonChannel(channelRec);
    }

    /**
    * @description retrieves the Prospective Student's Channel record for the Prospective Student
    * @return Channel__c : Prospective Student's Channel record
    */
    public Channel__c getPersonChannel() {
        return this.con360.getPersonChannel();
    }

    /**
    * @description Sets the Prospective Student Lead record
    * @param Lead leadRec : Prospective Student Lead record
    * @return void
    */
    public void setLead(Lead leadRec) {
        if(this.psLead == null) {
            this.psLead = new ProspectiveStudentLeadDAO(leadRec);
        } else {
            this.psLead.setLead(leadRec);
        }
    }

    /**
    * @description retrieves the Prospective Student Lead record
    * @return Lead : the Prospective Student Lead record
    */
    public Lead getLead() {
        Lead leadRec;
        if(this.psLead != null) {
            leadRec = this.psLead.getLead();
        }
        return leadRec;
    }

    /**
    * @description Adds a Lead Course Association record to an existing 
    *   List for this Prospective Student
    * @param Lead_Course_Association__c lca : the Lead Course Association record to be added
    * @return void
    */
    public void addCourseInterest(Lead_Course_Association__c lca) {
        if(this.psLead != null) {
            this.psLead.addCourseInterest(lca);
        } else {
            System.debug(LoggingLevel.WARN, 'Unable to add Lead Course Association. Lead not found in current context!');
        }
    }

    /**
    * @description replaces the existing List of Lead Course Association related 
    *   to this Prospective Student
    * @param List<Lead_Course_Association__c> listLca : the new List of Lead Course Association records
    * @return void
    */
    public void setCourseInterest(List<Lead_Course_Association__c> listLca) {
        this.psLead.setCourseInterest(listLca);
    }

    /**
    * @description retrieves the associated list of Lead Course Association records 
    *   for this Prospective Student
    * @return List<Lead_Course_Association__c> : list of Lead Course Association records 
    *   for this Prospective Student
    */
    public List<Lead_Course_Association__c> getCourseInterests() {
        return this.psLead.getCourseInterests();
    }

    /**
    * @description retrieves the associated list of Lead Course Association records 
    *   for this Prospective Student converted in Map
    * @return Map<Id, Lead_Course_Association__c> : map of association Lead Course Association
    *   records mapped by <Course_Master Id, LCA record>
    */
    public Map<Id, Lead_Course_Association__c> getCourseInterestsMap() {
        return this.psLead.getCourseInterestsMap();
    }

    public Map<String, Lead_Course_Association__c> getCourseInterestsMapStr() {
        return this.psLead.getCourseInterestsMapStr();
    }

    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Subscription List type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    */
    public void addSubscriptionMember(CampaignMember cm) {
        this.psCampaigns.addSubscriptionMember(cm);
    }

    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Event type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    */
    public void addEventMembers(CampaignMember cm) {
        this.psCampaigns.addEventMembers(cm);
    }

    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Acquisition Source type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    */
    public void addAcquisitionSource(CampaignMember cm) {
        this.psCampaigns.addAcquisitionSource(cm);
    }

    /**
    * @description retrieves all campaign member records from Subscription List campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    public Map<Id, CampaignMember> getSubscriptionMembers() {
        return this.psCampaigns.getSubscriptionMembers();
    }

    /**
    * @description retrieves all campaign member records from Event campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    public Map<Id, CampaignMember> getEventMembers() {
        return this.psCampaigns.getEventMembers();
    }

    /**
    * @description retrieves all campaign member records from Acquisition Source campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    public Map<Id, CampaignMember> getAcquisitionSource() {
        return this.psCampaigns.getAcquisitionSource();
    }

    /**
    * @description retrieves all campaign member records related to this Prospective Student
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    public Map<Id, CampaignMember> getAllMembers() {
        return this.psCampaigns.getAllMembers();
    }

    /**
    * @description adds a Contact Qualification record to this Prospective Student
    * @param Contact_Qualification__c cqRec : the Contact Qualification record to be added
    * @return void
    */
    public void addPersonContactQualification(Contact_Qualification__c cqRec) {
        this.contactQualifications.add(cqRec);
    }

    /**
    * @description retrieves all related Contact Qualification record with this Prospective Student
    * @return List<Contact_Qualification__c> : all related Contact Qualification record with this Prospective Student
    */
    public List<Contact_Qualification__c> getPersonContactQualification() {
        return this.contactQualifications;
    }

    /**
    * @description replaces the existing List of Cases related with this Prospective Student
    * @param List<Case> cList : new list of cases to be associated
    * @return void
    */
    public void setProspectiveStudentEnquiries(List<Case> cList){
        this.caseList = cList;
    }
    
    /**
    * @description add a case record to the existing list of cases related with this Prospective Student
    * @param Case c : the new Case record to be added
    * @return void
    */
    public void addProspectiveStudentEnquiry(Case c) {
        this.caseList.add(c);
    }

    /**
    * @description retrieves all Cases related with this Prospective Student
    * @return List<Case> : list of all Cases related with this Prospective Student
    */
    public List<Case> getProspectiveStudentEnquiries() {
        return this.caseList;
    }

    /**
    * @description resolves dependencies and object relationships of all associated
    *   records within the Data Access Object and all child objects
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @return void
    */
    public void resolveDependencies(BaseClass bc) {
        Account globalAccount = new Account(Id = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID);
        resolveDependencies(bc, globalAccount);
        resolveDependencies(bc, getPerson());
        resolveDependencies(bc, getLead());
        
        //stage commit Contact Qualifications
        for(Contact_Qualification__c iCQ : this.contactQualifications) {

            //we only create new cq's and never update them
            if(iCQ.Id == null) {
                bc.push(iCQ, Contact_Qualification__c.Contact__c, getPerson());
            }
        }

        //stage commit Cases
        for(Case iCase : this.caseList) {
            bc.push(iCase);
            if(iCase.Lead__c == null) {
                bc.relate(iCase, Case.Lead__c, getLead());
            }
        }
    }
    /**
    * @description resolve object relationship for Contact360 model
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @param Account globalAccount : Global Monash University account record
    * @return void
    */
    public void resolveDependencies(BaseClass bc, Account globalAccount) {
        this.con360.resolveDependencies(bc, globalAccount);
    }
    /**
    * @description resolve object relationship for Prospective Student Lead model
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @param Contact person : Lead's parent Contact
    * @return void
    */
    public void resolveDependencies(BaseClass bc, Contact person) {
        this.psLead.resolveDependencies(bc, person);
    }
    /**
    * @description resolve object relationship for Prospective Student Campaigns
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @param Lead leadRecord : Related prospect of Campaign member records
    * @return void
    */
    public void resolveDependencies(BaseClass bc, Lead leadRecord) {
        this.psCampaigns.resolveDependencies(bc, leadRecord);
    }

    //this is an interim model while we are yet to adapt to Person360
    public inherited sharing class Contact360 implements IContact360 {
        @TestVisible
        private Contact person {get; set;}
        @TestVisible
        private Roles__c personRole;
        @TestVisible
        private Channel__c personChannel;

        public Contact360() { }

        public Contact getPerson() {
            return this.person;
        }

        public Roles__c getPersonRole() {
            return this.personRole;
        }

        public Channel__c getPersonChannel() {
            return this.personChannel;
        }

        public void setPerson(Contact con) {
            this.person = con;
        }

        public void setPersonRole(Roles__c role) {
            this.personRole = role;
        }

        public void setPersonChannel(Channel__c channel) {
            this.personChannel = channel;
        }

        public void resolveDependencies(BaseClass bc, Account accountRec) {
            //assumption at this stage is that Contact (person) already exists and doesn't require any updates

            //link Role with Contact
            bc.push(this.personRole, Roles__c.Contact__c, this.person);
            if(accountRec != null) {
                //link Role with Global Monash Account
                bc.relate(this.personRole, Roles__c.Account__c, accountRec);
            }
            //link channel with Role
            bc.push(this.personChannel, Channel__c.Role__c, this.personRole);
            //link channel with Contact
            bc.relate(this.personChannel, Channel__c.Contact__c, this.person);
        }
    }

    public interface IContact360 {
        Contact getPerson();
        Roles__c getPersonRole();
        Channel__c getPersonChannel();
        void setPerson(Contact con);
        void setPersonRole(Roles__c role);
        void setPersonChannel(Channel__c channel);
        void resolveDependencies(BaseClass bc, Account accountRec);
    }
}