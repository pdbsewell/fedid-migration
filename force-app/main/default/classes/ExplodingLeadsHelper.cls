/**
 * @description       : Helper class for ExplodingLeadsServiceV2
 * @author            : Nick Guia
 * @date              : 17-09-2020
 * @group             : Lead Management
 * @last modified on  : 05-07-2023
 * @last modified by  : Nick Guia
 * @revision 
 *   21.06.2021   Ibrahim Rumi    - EPBBS-2007 modified method buildCampaignMemberInfo step 4 to create an acquistion campaign member only when Do_Not_Create_Acquisition_Camp_Member__c is set to false
 *   15.12.2021   Ibrahim Rumi    - EPBBS-2064 modified method partialCommitRecords to skip logging exceptions when error type DUPLICATE_VALUE in Person 360 or Contact Qualification(case 2)
 *   04.07.2023   Nick Guia       - stopped the creation of CPAs for Prospective Students
**/
public abstract inherited sharing class ExplodingLeadsHelper {

    @TestVisible
    protected List<Staged_Prospective_Student__c> spsListInp;
    @TestVisible
    protected Map<Id, StagedProspectiveStudentDAOV2> spsDAOByContactId;
    @TestVisible
    protected Map<Id, Affiliation__c> existingAffByConId;
	@TestVisible
    private Map<String, Course_Master__c> courseByCode; //existing Course Masters
    @TestVisible
    private Map<Id, Map<String, Contact_Qualification__c>> cqMapByContactId;
    @TestVisible
    private Map<Id, Campaign> campaignMapById;
    @TestVisible
	private Map<Id, Case> existingCaseMap;
    @TestVisible
    protected ExplodingLeadsSelector selector;

    //identifier to know if Person360 build was ran
    @TestVisible
    protected Boolean isCreatePerson360 = false;

    public ExplodingLeadsHelper(List<Staged_Prospective_Student__c> spsRecords) {
        init();
        this.spsListInp = spsRecords;
        //create an SPS DAO for each unique Contact ID
        this.spsDAOByContactId = new ExplodingLeadsFactoryV2().createSpsDAO(this.spsListInp);
    }

    /**
     * @description link all related records together
     */
    protected BaseClass resolveDependencies(BaseClass bc) {
        List<Person360> p360List = new List<Person360>();
        for(Id iConId : this.spsDAOByContactId.keySet()) {

            StagedProspectiveStudentDAOV2 iDao = this.spsDAOByContactId.get(iConId);

            //STEP 1 : resolve dependencies for Person360
            Contact con = new Contact(Id = iConId);
            if(this.isCreatePerson360) {
                //build person360 data
                Person360 iP360 = iDao.buildPerson360();
                con = iP360.getContact();
                p360List.add(iP360);
                
                //push cached Phone record
                Phone__c phoneRec = iDao.getCachedPhone();
                if(phoneRec != null) {
                    bc.push(phoneRec);
                }
            }
            
            //STEP 2 : resolve dependencies for Leads and Course Interests
            iDao.leadDao.resolveDependencies(bc, con);
            Lead ldRec = iDao.leadDao.prospectiveLead;
            
            //STEP 3 :  resolve Contact Qualifications
            for(Contact_Qualification__c iCq : iDao.contactQualificationList) {
                //we only create new cq's and never update them
                if(iCQ.Id == null) {
                    bc.push(iCQ, Contact_Qualification__c.Contact__c, con);
                }
            }

            //STEP 4: resolve Campaign Members - this process is dependent on having a
            //Lead record included in this context, otherwise, the campaign member changes won't commit.
            if(ldRec != null) {
                iDao.campaignDAO.resolveDependencies(bc, ldRec);
            }
        }

        if(!p360List.isEmpty()) {
            bc = new Person360BuilderDirector(bc)
                    .resolveContactPointsWithExternalId()
                    .resolveDependencies(p360List)
                    .getBaseClass();
        }
        return bc;
    }

    /**
     * @description Partial commit all records that were processed by Exploding Leads
     */
    protected Set<Id> partialCommitRecords(BaseClass bc) {
        Set<Id> partialErrorContacts = new Set<Id>();
		BaseClass.ResultSet rs = bc.commitRecordsPartial();
        list<BaseClass.ErrorRecord> errorRecList;

		for (String sObjectType : rs.errorMap.keySet()) {
            errorRecList = new list<BaseClass.ErrorRecord>();
            errorRecList = rs.errorMap.get(sObjectType);
			for(Integer i = errorRecList.size() - 1; i >= 0 ; --i) {
				SObject sObj = errorRecList[i].record;
				String contactId;

				switch on sObjectType {
					//CASE 1: Error occurred in Lead
					when 'Lead' {
						contactId = String.valueOf(sObj.get('Contact__c'));
					}
					// CASE 2: Error occurred in Person 360 or Contact Qualification
					when 'Affiliation__c', 'Address__c', 'Email__c', 'Phone__c', 'Social__c', 'Name__c', 'Contact_Point_Affiliation__c', 'Contact_Qualification__c' {
                        /**
                         * only update to Partial error when error type is not duplicate value
                         * we always attempt to insert new contact points and let it
                         * error if it already exists
                         */
                        String errorType = errorRecList[i].getErrorType();
                        if(!errorType.equalsIgnoreCase('DUPLICATE_VALUE')) {
                            contactId = String.valueOf(sObj.get('Contact__c'));
                        }else if(errorType.equalsIgnoreCase('DUPLICATE_VALUE')){
                            errorRecList.remove(i);
                        }
					}
					//CASE 3: Error occurred in Campaign Member, or Enquiry
					when 'CampaignMember', 'Case' {
						contactId = String.valueOf(sObj.get('ContactId'));
					}
					when else {
						System.debug(LoggingLevel.ERROR, 'Partial Error on Unexpected SObjectType : ' + sObjectType);
					}
				}

				if(String.isNotBlank(contactId)) {
					partialErrorContacts.add(contactId);
				}
			}
		}
		//log exceptions from base class
		LogUtilityException.logCommitRecords(rs);
		return partialErrorContacts;
    }

    /**
     * @description Updates the SPS records after all the processing.
	 *  - Updates Exploded Target field with the resulting Contact record
	 *  - Updates the Exploded Lead field with the resulting Lead record
	 *  - Updates the Exploded Enquiry with the resulting Case record
	 *  - Updates SPS Status to 'Partial Error' if any errors occurred after creating the Contact
	 *  - Updates SPS Status to 'Success' if there are zero errors.
     */
    protected List<Staged_Prospective_Student__c> updateSPSRecords(Set<Id> partialErrorContacts) {
        /**
         * create a map of SPS records that contains a new instance of each record for update
         * this is to prevent record locking due to currently running Triggers
         */
        Map<Id, Staged_Prospective_Student__c> spsMap = new Map<Id, Staged_Prospective_Student__c>();

        for(Id iConId : this.spsDAOByContactId.keySet()) {
            StagedProspectiveStudentDAOV2 iDao = this.spsDAOByContactId.get(iConId);
            Map<Id, Staged_Prospective_Student__c> spsErrorMap = iDao.spsErrorMap;
            Lead ldRec = iDao.leadDao.prospectiveLead;

            //link Exploded Lead into SPS
            for(Staged_Prospective_Student__c iSps : iDao.getSpsList()) {

                Staged_Prospective_Student__c upSpsRec = spsMap.get(iSps.Id);

                //instantiate new sps instance to work around read-only locks
                if(upSpsRec == null) {
                    upSpsRec = new Staged_Prospective_Student__c(
                        Id = iSps.Id,
                        Exploded_Target__c = iConId);
                }

                if(ldRec != null) {
                    upSpsRec.Exploded_Lead__c = ldRec.Id;
                }
                
                if(!iSps.Status__c.equalsIgnoreCase(Label.SPS_Status_Fatal_Error)) {
                    if(!iSps.Status__c.equalsIgnoreCase(Label.SPS_Status_Partial_Error) &&
                       !spsErrorMap.containsKey(iSps.Id) &&
                       !partialErrorContacts.contains(iConId)) 
                    {
                        //if no error was detected in both partial commit and data collection, update to Success
                        upSpsRec.Status__c = Label.SPS_Status_Success;
                    } else {
                        //else, update to Partial Error
                        upSpsRec.Status__c = Label.SPS_Status_Partial_Error;
                    }
                    spsMap.put(upSpsRec.Id, upSpsRec);
                }
            }
        }

        if(!spsMap.isEmpty()) {
            try {
                update spsMap.values();
            } catch(Exception e) {
                LogUtilityException.addException(e);
            }
        }
        return spsMap.values();
    }

    /***** BUILD PROCESSES *****/

    /**
     * @description create / update Affiliation, Contact Points
     */
    @TestVisible
    protected ExplodingLeadsHelper buildProspectInfo() {
        for(Id conId : this.spsDAOByContactId.keySet()) {
            StagedProspectiveStudentDAOV2 dao = this.spsDAOByContactId.get(conId);
            Affiliation__c affRec = this.existingAffByConId.get(conId);

            dao.setAffiliation(affRec)
                .setAddress()
                .setEmail()
                .setMobile()
                .setPhone();
        }
        return this;
    }

    /**
     * @description create/update : Lead, Lead Course Association
     */
    @TestVisible
    protected ExplodingLeadsHelper buildLeadInfo() {

        for(StagedProspectiveStudentDAOV2 iDao : this.spsDAOByContactId.values()) {
            
            // create/update Lead for SPS DAO
            List<Staged_Prospective_Student__c> daoSpsList = iDao.getSpsList();
            Lead existingLead;

            if(iDao.leadDao != null) {
                //if Lead DAO exists, see if it picked up an existing Lead from retrieve process
                existingLead = iDao.leadDao.prospectiveLead;
            } else {
                //otherwise, create new instance with null Lead
                iDao.leadDao = new ProspectiveStudentLeadDAO(existingLead);
            }

            Lead psLead = new ExplodingLeadsFactoryV2.ProspectiveLeadBuilder(daoSpsList)
                            .setExistingLead(existingLead)
                            .build()
                            .getLead();
            //set new lead in the Lead DAO
            iDao.leadDao.prospectiveLead = psLead;
            
            // create/update Lead Course Association (Course Interests)

            //get existing course master records from the retrieve
            List<Course_Master__c> newCourseInterests = new List<Course_Master__c>();
            for(String iCode : iDao.getCourseInterests()) {
                if(this.courseByCode.containsKey(iCode)) {
                    newCourseInterests.add(this.courseByCode.get(iCode));
                }
            }

            if(!newCourseInterests.isEmpty()) {
                List<Lead_Course_Association__c> existingLca = iDao.leadDao.lcaList;
                List<Lead_Course_Association__c> lcaList = 
                    new ExplodingLeadsFactoryV2.LeadCourseAssociationBuilder(newCourseInterests)
                        .setExistingLca(existingLca)
                        .build()
                        .getLCA();
                iDao.leadDao.lcaList = lcaList;
            }
        }
        return this;
    }

    /**
     * @description create a new Contact Qualification if it doesn't exist yet
     * based on Name + Institution Name
     */
    @TestVisible
    protected ExplodingLeadsHelper buildCQ() {
        for(Id iConId : this.spsDAOByContactId.keySet()) {
            StagedProspectiveStudentDAOV2 dao = this.spsDAOByContactId.get(iConId);

            //get new Contact Qualifications from SPS
            Map<String, Contact_Qualification__c> cqMap = dao.getContactQualificationMap();
            Map<String, Contact_Qualification__c> existingCqMap = this.cqMapByContactId.get(iConId);
            for(String iCqKey : cqMap.keySet()) {
                //check if it already exists
                if(existingCqMap != null && existingCqMap.containsKey(iCqKey)) {
                    continue;
                } else {
                    //create new
                    dao.contactQualificationList.add(cqMap.get(iCqKey));
                }
            }
        }
        return this;
    }

    /**
     * @description Create/update Campaign Member records for each campaign type
     */
    @TestVisible
    protected ExplodingLeadsHelper buildCampaignMemberInfo() {

        for(Id iConId : this.spsDAOByContactId.keySet()) {

            StagedProspectiveStudentDAOV2 iDao = this.spsDAOByContactId.get(iConId);

            //STEP 1: get collected Campaign IDs
            Set<Id> subListIds = iDao.getSubscriptionListIds();
            Set<Id> eventIds = iDao.getEventCampaignIds();
            Set<Id> acSourceIds = iDao.getAcquisitionSourceIds();

            Staged_Prospective_Student__c spsRec = iDao.getmergedSps();

            //STEP 2: create campaign members for Subscription List
            for(Id iSubId : subListIds) {
                Campaign campRec = this.campaignMapById.get(iSubId);
                CampaignMember cm = iDao.campaignDAO.subscriptionListMembers.get(iSubId);
                //get lead source: either acquisition source ID or Lead Source field
                String leadSource = (String) spsRec.Acquisition_Source_Campaign__c;
                if(String.isBlank(leadSource)) {
                    leadSource = spsRec.Lead_Source__c;
                }
                CampaignMember subMember = new ExplodingLeadsFactoryV2.SubscriptionListMemberBuilder(campRec, iConId)
                                            .withExistingMember(cm)
                                            .build(leadSource)
                                            .getMember();
                if(subMember != null) {
                    iDao.campaignDAO.subscriptionListMembers.put(subMember.CampaignId, subMember);
                }

                //fail-safe remove the campaign ID from the other set, in case they exist
                eventIds.remove(iSubId);
                acSourceIds.remove(iSubId);
            }

            //STEP 3: create campaign members for Event Campaigns
            for(Id iEventId : eventIds) {
                Campaign campRec = this.campaignMapById.get(iEventId);
                CampaignMember cm = iDao.campaignDAO.eventMembers.get(iEventId);
                CampaignMember eventMember = new ExplodingLeadsFactoryV2.EventMemberBuilder(campRec, iConId)
                                                .withExistingMember(cm)
                                                .build(spsRec)
                                                .getMember();
                if(eventMember != null) {
                    iDao.campaignDAO.eventMembers.put(eventMember.CampaignId, eventMember);
                }

                //fail-safe remove the campaign ID from the other set, in case they exist
                acSourceIds.remove(iEventId);
            }

            //STEP 4: create campaign members for Acquisition Source Campaigns
            for(Id iASource : acSourceIds) {
                Campaign campRec = this.campaignMapById.get(iASource);
                CampaignMember cm = iDao.campaignDAO.acquisitionSourceMembers.get(iASource);
                CampaignMember aSourceMember = new ExplodingLeadsFactoryV2.AcquisitionMemberBuilder(campRec, iConId)
                                                .withExistingMember(cm)
                                                .build(spsRec.Web_Lead_Source__c)
                                                .getMember();
                //Only create an acquistion campaign member when Do_Not_Create_Acquisition_Camp_Member__c is set to false                                
                if(aSourceMember != null && !spsRec.Do_Not_Create_Acquisition_Camp_Member__c) {
                    iDao.campaignDAO.acquisitionSourceMembers.put(aSourceMember.CampaignId, aSourceMember);
                }
            }
        }
        return this;
    }

    /***** RETRIEVE PROCESSES *****/

    /**
     * @description retrieves existing Person Information :
     * Contact, Affiliation, Contact Point Affiliation
     */
    @TestVisible
    protected ExplodingLeadsHelper retrieveProspectInfo() {

        Set<Id> conIds = this.spsDAOByContactId.keySet();

        //STEP 1: store existing Contacts in DAO class
        for(Contact iCon : this.selector.selectExistingContacts(conIds)) {
            StagedProspectiveStudentDAOV2 spsDAO = this.spsDAOByContactId.get(iCon.Id);
            spsDAO.p360Builder = new Person360.Person360Builder(iCon).createContactPointAffiliations(false);
        }

        //STEP 2: collect existing Affiliation
        for(Affiliation__c iAff : this.selector.selectProspectAffiliation(conIds)) {
            this.existingAffByConId.put(iAff.Contact__c, iAff);
        }

        return this;
    }

    /**
     * @description retrieve all infromation about the Lead :
     * existing Lead data, existing Lead Course Interests (LCA),
     * and existing Course Master records
     */
    @TestVisible
    protected ExplodingLeadsHelper retrieveLeadInfo() {
        Set<Id> conIds = this.spsDAOByContactId.keySet();
        Set<Id> existingLeadIdSet = new Set<Id>();

        //STEP 1: retrieve all existing Lead details
        for(Lead iLead :selector.selectExistingLeads(conIds)) {

            StagedProspectiveStudentDAOV2 spsDAO = this.spsDAOByContactId.get(iLead.Active_Lead_Contact_Id__c);
            /**
             * fail-safe : if multiple "active" lead exists 
             * for the same Contact, pop it from the set so
             * we don't add course interests against the duplicates
             */
            if(spsDAO.leadDao != null && spsDAO.leadDao.prospectiveLead.Id != null) {
                existingLeadIdSet.remove(spsDAO.leadDao.prospectiveLead.Id);
            }

            spsDAO.leadDao = new ProspectiveStudentLeadDAO(iLead);
            existingLeadIdSet.add(iLead.Id);
        }

        //STEP 2: retrieve all existing Lead Course Interests (LCA)

        //get all course codes collected by each SPS DAO classes
        Set<String> interestedCourseSet = new Set<String>();
        for(StagedProspectiveStudentDAOV2 iDao : this.spsDAOByContactId.values()) {
            interestedCourseSet.addAll(iDao.getCourseInterests());
        }
        //query all existing LCAs
        for(Lead_Course_Association__c lca : selector.selectExistingLCA(existingLeadIdSet, interestedCourseSet)) {
            StagedProspectiveStudentDAOV2 spsDAO = this.spsDAOByContactId.get(lca.Lead__r.Active_Lead_Contact_Id__c);
            spsDAO.leadDao.lcaList.add(lca);
        }

        //STEP 3: retrieve all existing Course Master records
        for(Course_Master__c iCourse : selector.selectCourseMasters(interestedCourseSet)) {
            this.courseByCode.put(iCourse.Course_Code__c, iCourse);
        }

        return this;
    }

    /**
     * @description retrieve existing Contact Qualification records
     * of the Contact
     */
    @TestVisible
    protected ExplodingLeadsHelper retrieveCQInfo() {
        Set<Id> conIds = this.spsDAOByContactId.keySet();
        Set<String> qualificationNameSet = new Set<String>();
        Set<String> qualificationInstitutionNameSet = new Set<String>();

        //consolidate all qualification / institution names for each DAO
        for(StagedProspectiveStudentDAOV2 iDao : this.spsDAOByContactId.values()) {
            qualificationNameSet.addAll(iDao.getQualificationNames());
            qualificationInstitutionNameSet.addAll(iDao.getQualificationInstitutionNames());
        }

        //store all existing contact qualification records for each Contact
        for(Contact_Qualification__c iCq : this.selector.selectExistingContactQualifications(
            conIds, qualificationNameSet, qualificationInstitutionNameSet)) 
        {
            Map<String, Contact_Qualification__c> cqMap = this.cqMapByContactId.get(iCq.Contact__c);
            if(cqMap == null) {
                cqMap = new Map<String, Contact_Qualification__c>();
            }
            String key = StagedProspectiveStudentUtil.buildContactQualificationKey(iCq);
            cqMap.put(key, iCq);
            this.cqMapByContactId.put(iCq.Contact__c, cqMap);
        }
        return this;
    }

    /**
     * @description retrieve existing Campaign Member information
     */
    @TestVisible
    protected ExplodingLeadsHelper retrieveCampaignInfo() {
        //get all campaign IDs
        Set<Id> campaignIds = new Set<Id>();
        for(StagedProspectiveStudentDAOV2 iDao : this.spsDAOByContactId.values()) {
            campaignIds.addAll(iDao.getSubscriptionListIds());
            campaignIds.addAll(iDao.getEventCampaignIds());
            campaignIds.addAll(iDao.getAcquisitionSourceIds());
        }

        if(!campaignIds.isEmpty()) {
            for(Campaign iCamp : this.selector.selectExistingCampaignMember(
                this.spsDAOByContactId.keySet(), campaignIds)) 
            {
                this.campaignMapById.put(iCamp.Id, iCamp);
                for(CampaignMember iCm : iCamp.CampaignMembers) {
                    StagedProspectiveStudentDAOV2 spsDAO = this.spsDAOByContactId.get(iCm.ContactId);
                    spsDao.addCampaignMember(iCm);
                }
            }
        }
        return this;
    }

    /**
     * @description initialise variables and create instances of SPS DAO
     *  per Contact ID
     */
    private void init() {
        this.spsDAOByContactId = new Map<Id, StagedProspectiveStudentDAOV2>();
        this.existingAffByConId = new Map<Id, Affiliation__c>();
        this.courseByCode = new Map<String, Course_Master__c>();
        this.cqMapByContactId = new Map<Id, Map<String, Contact_Qualification__c>>();
        this.campaignMapById = new Map<Id, Campaign>();
        this.selector = new ExplodingLeadsSelector();
    }
}