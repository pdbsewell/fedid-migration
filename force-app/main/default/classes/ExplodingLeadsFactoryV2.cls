/**
 * @author Nick Guia
 * @date 14-09-2020
 * @group Lead Management
 * @description Utility class for Exploding Leads (V2)
 * @revision
 *  03-07-2023    Nick Guia   - added defaulting Account_Record_Type_Name__c = 'Household_Account' on contact creation
 **/
public without sharing virtual class ExplodingLeadsFactoryV2 {
    
    private Staged_Prospective_Student__c sps;

    public ExplodingLeadsFactoryV2(Staged_Prospective_Student__c spsRec) {
        this.sps = spsRec;
    }

    public ExplodingLeadsFactoryV2() { }

    /**
     * @description create an instance of SPS Dao per Contact ID 
     * @param spsList 
     * @return Map<Id, StagedProspectiveStudentDAOV2> 
     */
    public Map<Id, StagedProspectiveStudentDAOV2> createSpsDAO(List<Staged_Prospective_Student__c> spsList) {
        Map<Id, StagedProspectiveStudentDAOV2> spsDAOByContactId = new Map<Id, StagedProspectiveStudentDAOV2>();
        
        for(Staged_Prospective_Student__c spsRec : spsList) {

            if(spsRec.Exploded_Target__c != null) {
                StagedProspectiveStudentDAOV2 spsDao = spsDAOByContactId.get(spsRec.Exploded_Target__c);
                
                if(spsDAO == null) {
                    spsDAO = new StagedProspectiveStudentDAOV2(spsRec);
                } else {
                    spsDAO.addSps(spsRec);
                }

                spsDAOByContactId.put(spsRec.Exploded_Target__c, spsDAO);
            }
        }
        return spsDAOByContactId;
    }

    /**
     * @description For building a Prospective Student Contact. Field mapping
     *  is based on Staging_Object_Mapping__mdt metadata records
     * @param sps : sps record where we're basing the information on
     * @return Contact : prospective Student contact
     */
    public Contact buildProspectiveContact() {
        Contact newContact = new Contact();
        List<Staging_Object_Mapping__mdt> contactMapping = new List<Staging_Object_Mapping__mdt>();
        contactMapping = StagedProspectiveStudentUtil.mappingByTargetObject.get(Contact.SObjectType.getDescribe().getName());

        for(Staging_Object_Mapping__mdt iMap : contactMapping) {
            String spsField = String.valueOf(iMap.Staging_SObject_Field__c);
            String contactField = String.valueOf(iMap.Target_SObject_Field__c);
            newContact.put(contactField, sps.get(spsField));
        }
        newContact.RecordTypeId = StagedProspectiveStudentUtil.CONTACT_RECTYPE_PROPECTIVESTUDENT;
        newContact.Account_Record_Type_Name__c = 'Household_Account';
        return newContact;
    }

    /**
     * @description Merges information of the existing contact with the "in-memory" contact
     *  which was derived from sps record. Each field update has specific conditions for update
     * @param existingCon : Existing contact found
     * @param newCon : new built contact based on SPS record
     * @return Contact : merged version of the two contacts
     */
    public Contact mergeProspectiveContact(Contact existingCon, Contact newCon) {

        //update only the below fields in contact
        if(newCon.Birthdate != null && existingCon.Birthdate == null) {
            existingCon.Birthdate = newCon.Birthdate;
        }

        if(!String.isBlank(newCon.Birth_year__c) && String.isBlank(existingCon.Birth_year__c)) {
            existingCon.Birth_year__c = newCon.Birth_year__c;
        }

        if(!String.isBlank(newCon.Gender__c) && String.isBlank(existingCon.Gender__c)) {
            existingCon.Gender__c = newCon.Gender__c;
        }

        if(!String.isBlank(newCon.Country_of_Residence__c) && String.isBlank(existingCon.Country_of_Residence__c) ) {
            existingCon.Country_of_Residence__c = newCon.Country_of_Residence__c;    
        }

        if(!String.isBlank(newCon.Nationality__c)) {
            existingCon.Nationality__c = newCon.Nationality__c;    
        }
        return existingCon;
    }

    public class ProspectiveLeadBuilder {

        private List<Staged_Prospective_Student__c> spsList;
        private Lead existingLead;
        private List<Staging_Object_Mapping__mdt> leadMapping = 
            StagedProspectiveStudentUtil.mappingByTargetObject
                .get(Lead.SObjectType.getDescribe().getName());
        private Set<String> baoi = new Set<String>(); //broad area(s) of interest
        private Lead newLead;

        public ProspectiveLeadBuilder(Staged_Prospective_Student__c sps) {
            this.spsList = new List<Staged_Prospective_Student__c> { sps };
        }

        public ProspectiveLeadBuilder(List<Staged_Prospective_Student__c> spsList) {
            this.spsList = spsList;
        }

        /**
         * @description in cases where there is an existing Lead
         * and an existing BAOI has to be considered for Append vs Overwrite condition
         */
        public ProspectiveLeadBuilder setExistingLead(Lead ld) {
            if(ld != null) {
                this.existingLead = ld;
                this.baoi = splitBaoi(ld.Broad_area_s_of_interest__c);
            }
            return this;
        }

        /**
         * @description consumes all SPS information to create/update a Lead record
         */
        public ProspectiveLeadBuilder build() {
            Lead leadRec = new Lead(); //newLead outcome
            for(Staged_Prospective_Student__c iSps : spsList) {

                for(Staging_Object_Mapping__mdt fieldMap : leadMapping) {

                    String spsField = String.valueOf(fieldMap.Staging_SObject_Field__c);
                    String leadField = String.valueOf(fieldMap.Target_SObject_Field__c);
                    String spsVal = String.valueOf(iSps.get(spsField));

                    if(String.isNotBlank(spsVal)) {
                        //This is for checking Text fields being parsed to checkboxes
                        if(fieldMap.is_Text_to_Boolean__c) {
                            Boolean bool = StagedProspectiveStudentUtil.getBooleanFromText(spsVal);
                            leadRec.put(leadField, bool);
                        } else {
                            leadRec.put(leadField, spsVal);
                        }
                    }

                    //get lead Acquisition Source - latest greatest, if not null
                    if(iSps.Acquisition_Source_Campaign__c != null) {
                        leadRec.Acquisition_Source__c = iSps.Acquisition_Source_Campaign__c;
                    }
                    //consume SPS broad area(s) of interest
                    this.baoi= consumeBAOI(iSps);
                }
            }

            //consider moving this to lead trigger
            if(String.isBlank(leadRec.Company)) {
                leadRec.Company = 'N/A';
            }

            //assign consumed BAOI's
            if(!this.baoi.isEmpty()) {
                leadRec.Broad_area_s_of_interest__c = String.join(new List<String>(this.baoi), ';');
            }

            //assign constants
            leadRec.Status = 'Open';
            leadRec.RecordTypeId = StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT;

            leadRec = mergeWithExistingLead(leadRec);
            this.newLead = leadRec;
            return this;
        }

        /**
         * @description 
         * @return Lead 
         */
        public Lead getLead() {
            return this.newLead;
        }

        /**
        * @description consumes the Broad Area(s) of interest of each sps record
        * considering the Append vs Overwrite "update mode"
        * @param sps SPS record to be consumed
        * @return Set<String>  updated Broad area(s) of interest Set
        **/
        private Set<String> consumeBAOI(Staged_Prospective_Student__c sps) {

            Set<String> broadAreaSet = new Set<String>();

            if(String.isNotBlank(sps.Broad_area_s_of_interest__c)) {
                /*
                 * check if BAOI updatemode is 'Overwrite'. 
                 * if not provided, default to Overwrite
                 */
                if(String.isBlank(sps.Broad_Area_of_Interest_Update_Mode__c) ||
                    sps.Broad_Area_of_Interest_Update_Mode__c.equalsIgnoreCase(Label.SPS_Update_Mode_Overwrite))
                {
                    //update mode is overwrite
                    broadAreaSet.addAll(splitBaoi(sps.Broad_area_s_of_interest__c));
                } else {
                    //update mode is append
                    this.baoi.addAll(sps.Broad_area_s_of_interest__c.split(';'));
                    broadAreaSet = this.baoi;
                }
            }
            return broadAreaSet;
        }

        /**
        * @description merge new lead details into existing
        * Lead, ensuring that Acquisition Source is retained
        * i.e. shouldn't be updated once set
        * @param newLead new Lead record built from SPS details
        * @return Lead merged Lead record of existing + new
        **/
        private Lead mergeWithExistingLead(Lead newLead) {
            if(this.existingLead != null) {
                if(this.existingLead.Id != null) {
                    newLead.Id = this.existingLead.Id;
                }

                //retain acquisition source of existing Lead
                if(this.existingLead.Acquisition_Source__c != null) {
                    newLead.Acquisition_Source__c = this.existingLead.Acquisition_Source__c;
                }
            }
            return newLead;
        }

        /**
        * @description converts Broad Area(s) of interest value into a Set
        * @param strBaoi  broad area of interest string
        * @return Set<String> collection of delimited BAOI
        */
        private Set<String> splitBaoi(String strBaoi) {
            Set<String> rtrnBaoi = new Set<String>();
            if(String.isNotBlank(strBaoi)) {
                rtrnBaoi.addAll(strBaoi.split(';'));
            }
            return rtrnBaoi;
        }
    }

    public class LeadCourseAssociationBuilder {
        
        private List<Course_Master__c> courseInterests;
        private Map<Id, Lead_Course_Association__c> latestLCAByCourseId;
        private Map<Id, Lead_Course_Association__c> existingLCAByCourseId;

        public LeadCourseAssociationBuilder(List<Course_Master__c> cmList) {
            this.courseInterests = cmList;
            this.latestLCAByCourseId = new Map<Id, Lead_Course_Association__c>();
            this.existingLCAByCourseId = new Map<Id, Lead_Course_Association__c>();
        }

        /**
         * @description for considering existing LCA records
         */
        public LeadCourseAssociationBuilder setExistingLca(List<Lead_Course_Association__c> lcaList) {
            if(lcaList != null) {
                for(Lead_Course_Association__c iLca : lcaList) {
                    this.existingLCAByCourseId.put(iLca.Course_Master__c, iLca);
                }
            }
            return this;
        }

        /**
         * @description create new LCA records, and update ranking of those that already exists
         */
        public LeadCourseAssociationBuilder build() {
            if(this.courseInterests != null && !this.courseInterests.isEmpty()) {
                Integer rank = 1;
                //process all course master (in this specific order)
                for(Course_Master__c iCm : this.courseInterests) {
                    if(!this.latestLCAByCourseId.containsKey(iCm.Id)) {
                        //if LCA already existing for this course, just update the ranking
                        Lead_Course_Association__c lcaRec = this.existingLCAByCourseId.get(iCm.Id);
                        if(lcaRec == null) {
                            //otherwise, create a new LCA
                            lcaRec = new Lead_Course_Association__c(
                                        Course_Master__c = iCm.Id,
                                        Associated_Date__c = System.now()
                                    );
                        }
                        //update ranking
                        lcaRec.Last_Associated_Rank__c = rank;
                        this.latestLCAByCourseId.put(iCm.Id, lcaRec);
                    }
                    rank++;
                }
            }
            return this;
        }

        /**
         * @description return new LCA list
         */
        public List<Lead_Course_Association__c> getLCA() {
            return this.latestLCAByCourseId.values();
        }
    }

    public abstract class CampaignMemberBuilder {

        protected Id contactId;
        protected Campaign campRec;
        protected CampaignMember cMem;

        public CampaignMemberBuilder(Campaign camp, Id conId) {
            this.contactId = conId;
            this.campRec = camp;
        }

        /**
         * @description set existing campaign member (if any)
         */
        public CampaignMemberBuilder withExistingMember(CampaignMember cm) {
            this.cMem = cm;
            return this;
        }

        /**
         * @description process of creating the specific campaign member type
         */
        public abstract CampaignMemberBuilder build(Object param);

        /**
         * @description returns the final output of the campaign member
         */
        public CampaignMember getMember() {
            return this.cMem;
        }

        /**
         * @description validates all data within the instance to determine
         * whether a campaign member can be built
         */
        protected Boolean isBuildable() {
            Boolean isBuild = false;
            //make sure campaign record exists
            if(this.campRec != null && this.campRec.Id != null) {
                isBuild = true;
                //check if campaign member exists
                if(this.cMem == null) {
                    //if not, create new instance
                    this.cMem = new CampaignMember(
                        ContactId = this.contactId,
                        CampaignId = this.campRec.Id
                    );
                }
            }
            return isBuild;
        }
    }

    public class SubscriptionListMemberBuilder extends CampaignMemberBuilder {

        public SubscriptionListMemberBuilder(Campaign camp, Id conId) {
            super(camp, conId);
        }

        /**
         * @description opt in to subscription list campaign
         * @param param : could either be a String or Campaign ID lead source
         */
        public override CampaignMemberBuilder build(Object param) {
            if(super.isBuildable()) {
                String source = (String) param;
                super.cMem = CampaignMemberServices.subscribeToEmail(super.campRec, super.cMem, source);
                super.cMem = CampaignMemberServices.subscribeToSMS(super.campRec, super.cMem, source);
            }
            return this;
        }
    }

    public class EventMemberBuilder extends CampaignMemberBuilder {

        public EventMemberBuilder(Campaign camp, Id conId) {
            super(camp, conId);
        }

        /**
         * @description creates an event campaign member whose details is based on
         * the merged version of SPS
         * @param param : merged SPS records
         */
        public override CampaignMemberBuilder build(Object param) {
            if(super.isBuildable()) {
                Staged_Prospective_Student__c spsRec = (Staged_Prospective_Student__c) param;
                super.cMem.Active__c = true;
                super.cMem.Web_Lead_Source__c = spsRec.Web_Lead_Source__c;
                super.cMem.Number_of_Attendees__c = spsRec.Number_of_Attendees__c;
                super.cMem.Dietary_Requirements__c = spsRec.Dietary_Requirements__c;
                super.cMem.Session__c = spsRec.Session__c;
            }
            return this;
        }
    }

    public class AcquisitionMemberBuilder extends CampaignMemberBuilder {

        public AcquisitionMemberBuilder(Campaign camp, Id conId) {
            super(camp, conId);
        }

        /**
         * @description adds a member to an acquisition source campaign
         * @param param : (String) web lead source
         */
        public override CampaignMemberBuilder build(Object param) {
            if(super.isBuildable()) {
                super.cMem.Active__c = true;
                super.cMem.Web_Lead_Source__c = (String) param;
            }
            return this;
        }
    }
}