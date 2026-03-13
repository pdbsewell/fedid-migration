/**
 * @description       : Data Acccess Object for SPS
 * @author            : Nick Guia
 * @date              : 17-09-2020
 * @group             : Lead Management
 * @last modified on  : 04-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *   10.03.2022  Ibrahim Rumi    - EPBBS-2473 set AccountId as mandotory on  withAffiliation method
 *   04.07.2023  Nick Guia       - stopped the creation of CPAs for Prospective Students
**/

public virtual inherited sharing class StagedProspectiveStudentDAOV2 extends ProspectiveStudentDAOV2 {

    public Map<Id, Staged_Prospective_Student__c> spsErrorMap {get; set;}

    //list of all SPS records related to the same person
    @TestVisible
    private List<Staged_Prospective_Student__c> spsList; 

    //a merged version of spsList, which we base our processing from
    @TestVisible
    private Staged_Prospective_Student__c mergedSps;

    /**
     * this is for caching the phone contact point record.
     * Mobile will always take priority when relating to Person 360 model
     * we only use phone if mobile doesn't exist. 
     * Hence - cache this to be committed separately outside of the DAO structure
     */
    @TestVisible
    private Phone__c cachedPhoneRecord;

    /** COLLECTION OF SPS DETAILS **/
    @TestVisible
    private Map<String, Contact_Qualification__c> cqMap; 
    @TestVisible
    private Set<String> cqQualNameSet;
    @TestVisible
    private Set<String> cqInsNameSet;
    @TestVisible
    private List<String> interestedCourseCodes; 
    @TestVisible
    private Set<Id> subscriptionListIDs;
    @TestVisible
    private Set<Id> eventCampaignIDs;
    @TestVisible
    private Set<Id> aSourceCampaignIDs;

    public StagedProspectiveStudentDAOV2(Staged_Prospective_Student__c spsRec) {
        super(new Contact(Id = spsRec.Exploded_Target__c));
        initialise();
        addSps(spsRec);
    }

    /**
     * @description add related SPS record into collection
     */
    public void addSps(Staged_Prospective_Student__c spsRec) {
        this.spsList.add(spsRec);
        collectSpsDetails(spsRec);
    }

    /**
     * @description set Prospective Student Affiliation for the Contact
     * @param affRec : optionally use an existing Affiliation record
     */
    public StagedProspectiveStudentDAOV2 setAffiliation(Affiliation__c affRec) {
        id accountId = CommonUtilities.GLOBAL_MONASH_ACCOUNT_ID;
        if(affRec != null) {
            super.p360Builder.withAffiliation(affRec);
        } else {
            super.p360Builder.withAffiliation(
                accountId,
                'Prospective_Student',
                Date.today()
            );
        }
        return this;
    }

    /**
     * @description create an Address Contact Point based on the Merged SPS details
     */
    public StagedProspectiveStudentDAOV2 setAddress() {
        Staged_Prospective_Student__c sps = getmergedSps();
        if(String.isNotBlank(sps.Mailing_Street__c) ||
            String.isNotBlank(sps.Mailing_City__c) ||
            String.isNotBlank(sps.Mailing_State__c) ||
            String.isNotBlank(sps.Mailing_Postcode__c) ||
            String.isNotBlank(sps.Mailing_Country__c)) 
        {
            super.p360Builder.buildAddress()
                .withClassification('Private')
                .withStreetName(sps.Mailing_Street__c)
                .withCity(sps.Mailing_City__c)
                .withCountry(sps.Mailing_Country__c)
                .withState(sps.Mailing_State__c)
                .withPostCode(sps.Mailing_Postcode__c)
                .withType('Mailing')
                .withSource('Contact supplied')
                .buildHash();
        }
        return this;
    }

    /**
     * @description create an Email Contact Point based on the Merged SPS details
     */
    public StagedProspectiveStudentDAOV2 setEmail() {
        Staged_Prospective_Student__c sps = getmergedSps();
        if(String.isNotBlank(sps.Email__c)) {
            super.p360Builder.buildEmail()
                .withEmailId(sps.Email__c)
                .withSource('Contact supplied')
                .withClassification('Private')
                .buildHash(); //assume all email coming from SPS are private
        }
        return this;
    }

    /**
     * @description create a Mobile Contact Point based on the Merged SPS details
     */
    public StagedProspectiveStudentDAOV2 setMobile() {
        Staged_Prospective_Student__c sps = getmergedSps();
        if(String.isNotBlank(sps.Mobile__c)) {
            super.p360Builder.buildPhone()
                .withClassification('Private')
                .withPhoneNumber(sps.Mobile__c)
                .withType('Mobile')
                .withSource('Contact supplied')
                .buildHash();
        }
        return this;
    }

    /**
     * @description create a Phone Contact Point based on the Merged SPS details
     */
    public StagedProspectiveStudentDAOV2 setPhone() {
        Staged_Prospective_Student__c sps = getmergedSps();
        if(String.isNotBlank(sps.Phone__c)) {
            //only add phone in person360 if mobile is not present
            if(String.isBlank(sps.Mobile__c)) {
                super.p360Builder.buildPhone()
                    .withClassification('Private')
                    .withPhoneNumber(sps.Phone__c)
                    .withType('Undefined') //can be anything, hence - Undefined
                    .withSource('Contact supplied')
                    .buildHash();
            } else {
                //create a new phone record, and cache it within the DAO instance for future commit
                Id contactId = mergedSps.Exploded_Target__c;
                ContactPointBuilderFactory factory = new ContactPointBuilderFactory(contactId, new Phone__c());
                ContactPointBuilderFactory.PhoneContactPointBuilder builder = 
                    (ContactPointBuilderFactory.PhoneContactPointBuilder) factory.createContactPoint();
                builder.withClassification('Private')
                    .withPhoneNumber(sps.Phone__c)
                    .withType('Undefined')
                    .withSource('Contact supplied')
                    .buildHash();
                Phone__c phoneRec = (Phone__c) builder.getContactPoint();
                this.cachedPhoneRecord = phoneRec;
            }
        }
        return this;
    }

    /**
    * @description adds any existing campaign member records to DAO
    * @param CampaignMember cm : Campaign Member record to be added
    */
    public void addCampaignMember(CampaignMember cm) {
        if(this.subscriptionListIDs.contains(cm.CampaignId)) {
            super.campaignDAO.subscriptionListMembers.put(cm.CampaignId, cm);
        } else if(this.eventCampaignIDs.contains(cm.CampaignId)) {
            super.campaignDAO.eventMembers.put(cm.CampaignId, cm);
        } else if(this.aSourceCampaignIDs.contains(cm.CampaignId)) {
            super.campaignDAO.acquisitionSourceMembers.put(cm.CampaignId, cm);
        }
    }

    /**
     * @description get merged version of all SPS
     */
    public Staged_Prospective_Student__c getmergedSps() {
        if(this.mergedSps != null) {
            return this.mergedSps;
        } else if(!this.spsList.isEmpty()) {
            this.mergedSps = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordList(this.spsList);
        }
        return this.mergedSps;
    }

    /**
     * @description get the cached Phone contact point
     */
    public Phone__c getCachedPhone() {
        return this.cachedPhoneRecord;
    }

    /**
     * @description get list of SPS records related to the contact
     */
    public List<Staged_Prospective_Student__c> getSpsList() {
        return this.spsList;
    }

    /**
     * @description returns the collected course Interests
     * out of all SPS records
     */
    public Set<String> getCourseInterests() {
        return new Set<String>(this.interestedCourseCodes);
    }

    /**
     * @description returns the collected Contact Qualification Names
     */
    public Set<String> getQualificationNames() {
        return this.cqQualNameSet;
    }

    /**
     * @description returns the collected Contact Qualification Institution Names
     */
    public Set<String> getQualificationInstitutionNames() {
        return this.cqInsNameSet;
    }

    /**
     * @description returns the collected Contact Qualification map
     */
    public Map<String, Contact_Qualification__c> getContactQualificationMap() {
        return this.cqMap;
    }

    /**
     * @description get all collected Subscription List
     * Campaign IDs
     */
    public Set<Id> getSubscriptionListIds() {
        return this.subscriptionListIDs;
    }

    /**
     * @description get all collected Event
     * Campaign IDs
     */
    public Set<Id> getEventCampaignIds() {
        return this.eventCampaignIDs;
    }

    /**
     * @description get all collected Acquisition Source
     * Campaign IDs
     */
    public Set<Id> getAcquisitionSourceIds() {
        return this.aSourceCampaignIDs;
    }

    /**
     * @description initialise variables
     */
    private void initialise() {
        this.spsList = new List<Staged_Prospective_Student__c>();
        this.cqMap = new Map<String, Contact_Qualification__c>();
        this.cqQualNameSet = new Set<String>();
        this.cqInsNameSet = new Set<String>();
        this.interestedCourseCodes = new List<String>();
        this.subscriptionListIDs = new Set<Id>();
        this.eventCampaignIDs = new Set<Id>();
        this.aSourceCampaignIDs = new Set<Id>();
        this.spsErrorMap = new Map<Id, Staged_Prospective_Student__c>();
    }

    /**
     * @description collect SPS details
     */
    private void collectSpsDetails(Staged_Prospective_Student__c spsRec) {
        collectInterestedCourseIds(spsRec);
        collectSubListIds(spsRec);
        collectEventCampaignIds(spsRec);
        collectAcquisitionSourceIds(spsRec);
        collectContactQualification(spsRec);
    }

    /**
     * @description collect Course Interest IDs
     */
    @TestVisible
    private void collectInterestedCourseIds(Staged_Prospective_Student__c spsRec) {
        try {
            if(String.isNotBlank(spsRec.Interested_Course_List__c)) {
                for(String icourseId : StagedProspectiveStudentUtil.collectCourseIdsFromString(spsRec.Interested_Course_List__c)) {
                    if(!this.interestedCourseCodes.contains(icourseId)) {
                        this.interestedCourseCodes.add(icourseId);
                    }
                }
            }
        } catch(Exception e) {
            LogUtilityException.addException(e);
            spsErrorMap.put(spsRec.Id, spsRec);
        }
    }

    /**
     * @description collect Subscription List Campaign IDs
     */
    @TestVisible
    private void collectSubListIds(Staged_Prospective_Student__c spsRec) {
        try {
            this.subscriptionListIDs.addAll(
                StagedProspectiveStudentUtil.collectIdsFromStringV2(spsRec.Subscription_Lists__c)
            );
        } catch(Exception e) {
            LogUtilityException.addException(e);
            spsErrorMap.put(spsRec.Id, spsRec);
        }
    }

    /**
     * @description collect Event Campaign IDs
     */
    @TestVisible
    private void collectEventCampaignIds(Staged_Prospective_Student__c spsRec) {
        try {
            this.eventCampaignIDs.addAll(
                StagedProspectiveStudentUtil.collectIdsFromStringV2(spsRec.Event_Campaigns__c)
            );
        } catch(Exception e) {
            LogUtilityException.addException(e);
            spsErrorMap.put(spsRec.Id, spsRec);
        }
    }

    /**
     * @description collect Acquisition Source Campaign IDs
     */
    @TestVisible
    private void collectAcquisitionSourceIds(Staged_Prospective_Student__c spsRec) {
        if(spsRec.Acquisition_Source_Campaign__c != null) {
            aSourceCampaignIDs.add(spsRec.Acquisition_Source_Campaign__c);
        }
    }

    /**
     * @description collect contact qualification information by deserializing
     *  provided JSON string
     */
    @TestVisible
    private void collectContactQualification(Staged_Prospective_Student__c spsRec) {
        if(String.isNotBlank(spsRec.Contact_Qualification_JSON__c)) {
            try {
                //deserialize JSON Contact Qualification
                List<Contact_Qualification__c> cqList = 
                    (List<Contact_Qualification__c>) JSON.deserializeStrict(
                        spsRec.Contact_Qualification_JSON__c,
                        List<Contact_Qualification__c>.class);

                //add to collection
                for(Contact_Qualification__c iCq : cqList) {
                    if(String.isNotBlank(iCq.Other_Qualification__c) &&
                       String.isNotBlank(iCq.Institution_Name__c)) {
                        String cqKey = StagedProspectiveStudentUtil.buildContactQualificationKey(iCq);
                        this.cqMap.put(cqKey, iCq);
                        this.cqQualNameSet.add(iCq.Other_Qualification__c);
                        this.cqInsNameSet.add(iCq.Institution_Name__c);
                    }
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
                spsErrorMap.put(spsRec.Id, spsRec);
            }
        }
    }
}