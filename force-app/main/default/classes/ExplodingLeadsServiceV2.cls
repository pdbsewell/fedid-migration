/**
 * @author Nick Guia
 * @date 14-09-2020
 * @group Lead Management
 * @description Utility class for Exploding Leads (V2)
 **/
public virtual without sharing class ExplodingLeadsServiceV2 extends ExplodingLeadsHelper {

    @TestVisible
    protected BaseClass bc;
    
    public ExplodingLeadsServiceV2(List<Staged_Prospective_Student__c> spsList) {
        super(spsList);
        initialise();
    }

    public ExplodingLeadsServiceV2(Staged_Prospective_Student__c sps) {
        super(new List<Staged_Prospective_Student__c> { sps });
        initialise();
    }

    /**
     * @description retrieve existing person 360 information, and
     *  create those that doesn't exist
     */
    public ExplodingLeadsServiceV2 createPerson360() {
        super.isCreatePerson360 = true;
        super.retrieveProspectInfo()
            .buildProspectInfo();
        return this;
    }

    /**
     * @description retrieve existing Lead information, and
     *  create those that doesn't exist
     */
    public ExplodingLeadsServiceV2 createLeadsAndCourseInterest() {
        super.retrieveLeadInfo()
            .buildLeadInfo();
        return this;
    }

    /**
     * @description retrieve existing Contact Qualifications, and
     *  create those that doesn't exist
     */
    public ExplodingLeadsServiceV2 createContactQualifications() {
        super.retrieveCQInfo()
            .buildCQ();
        return this;
    }

    /**
     * @description retrieve existing Campaign Member information, and
     *  create those that doesn't exist. this process is dependent on having a
     *  Lead record included in this context. Otherwise, the campaign member 
     *  changes won't commit.
     */
    public ExplodingLeadsServiceV2 createCampaignMembers() {
        super.retrieveCampaignInfo()
            .buildCampaignMemberInfo();
        return this;
    }

    /**
     * @description commit all changes into the database
     */
    public List<Staged_Prospective_Student__c> save() {
        this.bc = super.resolveDependencies(this.bc);
        //partial commit records and get Contact IDs related to SPS with partial Errors
        Set<Id> partialErrorContacts = super.partialCommitRecords(this.bc);
        //link output records back to SPS, and update SPS status
        List<Staged_Prospective_Student__c> spsList = super.updateSPSRecords(partialErrorContacts);
        //publish exception logs
        LogUtilityException.publishAll();
        return spsList;
    }

    /**
     * @description returns the SPS DAO instances mapped by Contact IDs
     */
    public Map<Id, StagedProspectiveStudentDAOV2> getSpsDaoMap() {
        return super.spsDAOByContactId;
    }

    private void initialise() {
        this.bc = new BaseClass(StagedProspectiveStudentUtil.commitOrderV2);
    }
}