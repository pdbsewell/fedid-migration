/**
 * @Description        : Responsible for bulkifying SPS details. Provides the heavy-lifting
 *                       of collecting SPS details, and querying any records that already exists.
 * @Author             : Nick Guia
 * @Group              : Lead Management
 * @revision
 *  SEPT.28.2022    Nick Guia   - Moved SOQL to ExplodingLeadsSelector to run in without sharing
 */
public class BulkSPSDAO {

	@TestVisible
	private List<Staged_Prospective_Student__c> spsList;
	@TestVisible
	private Map<Id, StagedProspectiveStudentDAO> spsDAOByContactId;

   	@TestVisible
    private ExplodingLeadsSelector selector;

	/**  COLLECTED UNIQUE IDENTIFIERS TO DETERMINE EXISTING RECORDS **/

	//campaign keys
	@TestVisible
	private Set<Id> subscriptionListIDs;
	@TestVisible
	private Set<Id> eventCampaignIDs;
	@TestVisible
	private Set<Id> aSourceCampaignIDs;

	//contact qualification keys
	@TestVisible
	private Set<String> qualificationNameSet;
	@TestVisible
	private Set<String> qualificationInstitutionNameSet;

	//course interest keys
	@TestVisible
	private Set<String> interestedCourseSet;

	/**  IDENTIFIED EXISTING RECORDS **/

	//existing campaign keys
	@TestVisible
	private Map<Id, Campaign> existingCampaignMap;

	//existing Course Masters
	@TestVisible
	private Map<String, Course_Master__c> courseByCode;
	@TestVisible
	private Map<Id, Course_Master__c> courseById;

	//existing Cases
	@TestVisible
	private Map<Id, Case> existingCaseMap;

	//for partial error
	@TestVisible
	private Map<Id, Staged_Prospective_Student__c> partialErrorSps;


	public BulkSPSDAO(List<Staged_Prospective_Student__c> spsRecords) {
		init();
		collectSPSInfo(spsRecords);
		retrieveExistingRecords();
	}

	/**
	 * @description returns the SPS Data Access Objects based on collected bulk information
	 * @return List<StagedProspectiveStudentDAO> : List of SPS Data Access Objects
	 */
	public List<StagedProspectiveStudentDAO> getBulkCollectionResult() {
		return spsDAOByContactId.values();
	}

	/**
	 * @description returns the SPS Data Access Objects based in a map format
	 * @return Map<Id, StagedProspectiveStudentDAO> : Map of SPS Data Access Objects, with Contact ID key
	 */
	public Map<Id, StagedProspectiveStudentDAO> getBulkCollectionResultMap() {
		return spsDAOByContactId;
	}

	/**
	 * @description for getting Course record based on either ID or Course Code
	 * @param Object courseKey : either a Course ID, or Course Code in String/Id format
	 * @return Course_Master__c : existing Course Master record
	 */
	public Course_Master__c getCourseMaster(Object courseKey) {
		Course_Master__c cm;
		if(courseKey instanceof Id) {
			//check first by ID if ever course Code isn't unique
			cm = this.courseById.get(Id.valueOf(String.valueOf(courseKey)));
		} else {
			cm = this.courseByCode.get(String.valueOf(courseKey));
		}
		return cm;
	}

	/**
	 * @description returns the queried Campaign record based on provided ID
	 * @param Id campaignId : campaign ID
	 * @return Campaign : existing Campaign record
	 */
	public Campaign getExistingCampaign(Id campaignId) {
		return this.existingCampaignMap.get(campaignId);
	}

	/**
	 * @description returns the queried Case record based on provided ID
	 * @param Id caseId : Case ID
	 * @return Case : existing Case record
	 */
	public Case getExistingCase(Id caseId) {
		return this.existingCaseMap.get(caseId);
	}

    public List<Staged_Prospective_Student__c> getPartialErrorSps() {
		return this.partialErrorSps.values();
	}

	/**
	 * @description initialise all member variables
	 * @return void
	 */
	private void init() {
		this.spsList = new List<Staged_Prospective_Student__c>();
		this.spsDAOByContactId = new Map<Id, StagedProspectiveStudentDAO>();
        this.selector = new ExplodingLeadsSelector();

		this.subscriptionListIDs = new Set<Id>();
		this.eventCampaignIDs = new Set<Id>();
		this.aSourceCampaignIDs = new Set<Id>();

		this.qualificationNameSet = new Set<String>();
		this.qualificationInstitutionNameSet = new Set<String>();

		this.interestedCourseSet = new Set<String>();

		this.existingCampaignMap = new Map<Id, Campaign>();

		this.courseByCode = new Map<String, Course_Master__c>();
		this.courseById = new Map<Id, Course_Master__c>();

		this.existingCaseMap = new Map<Id, Case>();
        this.partialErrorSps = new Map<Id, Staged_Prospective_Student__c>();
	}

	/**
	 * @description collect all information from SPS records
	 * @param List<Staged_Prospective_Student__c> spsRecords : input SPS List
	 * @return void
	 */
	private void collectSPSInfo(List<Staged_Prospective_Student__c> spsRecords) {
		for(Staged_Prospective_Student__c spsRec : spsRecords) {
			collectSPSInfo(spsRec);
		}
	}

	/**
	 * @description collect all information from SPS record
	 * @param Staged_Prospective_Student__c spsRec : input SPS (single record)
	 * @return void
	 */
	private void collectSPSInfo(Staged_Prospective_Student__c spsRec) {
		this.spsList.add(spsRec);
		collectContactIds(spsRec);
		collectSubListIds(spsRec);
		collectEventCampaignIds(spsRec);
		collectAcqSrcIds(spsRec);
		collectContactQualification(spsRec);
		collectCourseInterests(spsRec);
		collectEnquiryDetails(spsRec);
	}

	/**
	 * @description query any existing records within CRM based on provided key identifiers in the SPS records
	 * @return void
	 */
	private void retrieveExistingRecords() {
		retrievePersonInformation();
		retrieveLeadInformation();
		retrieveExistingCampaignMember();
		retrieveExistingContactQualifications();
		retrieveExistingCases();
	}

	/**
	 * @description collects all Contact IDs provided in Exploded_Target__c field
	 * @param Staged_Prospective_Student__c spsRec
	 * @return void
	 */
	@TestVisible
	private void collectContactIds(Staged_Prospective_Student__c spsRec) {
		if(spsRec.Exploded_Target__c != null) {
			StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(spsRec.Exploded_Target__c);
			if(spsDAO == null) {
				spsDAO = new StagedProspectiveStudentDAO(spsRec);
			} else {
				spsDAO.addSps(spsRec);
			}
			this.spsDAOByContactId.put(spsRec.Exploded_Target__c, spsDAO);
		}
	}

	/**
	 * @description collects all campaign IDs provided in Subscription_Lists__c delimited by special characters
	 * @param Staged_Prospective_Student__c sps
	 * @return void
	 */
	@TestVisible
	private void collectSubListIds(Staged_Prospective_Student__c sps) {
        try {
            for(String strId : StagedProspectiveStudentUtil.collectIdsFromString(sps.Subscription_Lists__c)) {
                this.subscriptionListIDs.add(strId);
            }
        } catch(Exception e) {
            LogUtilityException.logException(e, sps.Id);
            this.partialErrorSps.put(sps.Id, sps);
        }
	}

	/**
	 * @description collects all campaign IDs provided in Event_Campaigns__c delimited by special characters
	 * @param Staged_Prospective_Student__c sps
	 * @return void
	 */
	@TestVisible
	private void collectEventCampaignIds(Staged_Prospective_Student__c sps) {
        try {
            for(String strId : StagedProspectiveStudentUtil.collectIdsFromString(sps.Event_Campaigns__c)) {
                this.eventCampaignIDs.add(strId);
            }
        } catch(Exception e) {
            LogUtilityException.logException(e, sps.Id);
            this.partialErrorSps.put(sps.Id, sps);
        }
	}

	/**
	 * @description collects the Acquisition Source campaign ID
	 * @param Staged_Prospective_Student__c sps
	 * @return void
	 */
	@TestVisible
	private void collectAcqSrcIds(Staged_Prospective_Student__c sps) {
		if(sps.Acquisition_Source_Campaign__c != null) {
			aSourceCampaignIDs.add(sps.Acquisition_Source_Campaign__c);
		}
	}

	/**
	 * @description collects all Contact Qualification JSON string and deserialize them into SObjects
	 * @param Staged_Prospective_Student__c sps
	 * @return void
	 */
	@TestVisible
	private void collectContactQualification(Staged_Prospective_Student__c spsRec) {
		if(String.isNotBlank(spsRec.Contact_Qualification_JSON__c)) {
			try {
				List<Contact_Qualification__c> cqList =
					(List<Contact_Qualification__c>) JSON.deserializeStrict(spsRec.Contact_Qualification_JSON__c,
					                                                        List<Contact_Qualification__c>.class);
				for(Contact_Qualification__c cq : cqList) {
					this.qualificationNameSet.add(cq.Other_Qualification__c);
					this.qualificationInstitutionNameSet.add(cq.Institution_Name__c);
				}
			} catch(Exception e) {
				LogUtilityException.logException(e, spsRec.Id);
                this.partialErrorSps.put(spsRec.Id, spsRec);
            }
        }
    }

    /**
    * @description collects all course IDs / course Codes provided in Interested_Course_List__c 
    *   which is delimited by special characters
    * @param Staged_Prospective_Student__c spsRec
    * @return void
    */
    @TestVisible
    private void collectCourseInterests(Staged_Prospective_Student__c spsRec) {
        this.interestedCourseSet.addAll(StagedProspectiveStudentUtil.collectCourseIdsFromString(spsRec.Interested_Course_List__c));
    }

    /**
    * @description collects Enquiry ID provided in Exploded_Enquiry__c
    * @param Staged_Prospective_Student__c spsRec
    * @return void
    */
    @TestVisible
    private void collectEnquiryDetails(Staged_Prospective_Student__c spsRec) {
        //process enquiry only if DNO = false
        if(!spsRec.Do_Not_Overwrite__c) {
            Case caseRec;
            if(spsRec.Exploded_Enquiry__c != null) {
                //if enquiry already exists, collect for future query and populating Lead field
                caseRec = new Case(Id = spsRec.Exploded_Enquiry__c, ContactId = spsRec.Exploded_Target__c);
                this.existingCaseMap.put(caseRec.Id, caseRec);
            }
        }
    }

    /**
    * @description retrieves all information about the Person that exists within CRM
    * @return void
    */
    private void retrievePersonInformation() {
        retrieveExistingContacts();
        retrieveExistingRolesAndChannels();
    }

    /**
     * @description retrieve all Leads related to contact.
     *  We need to use a dynamic query since getting all fields is required for the
     *  'Do not Overwrite' feature to consider all the current values
     * @return void
     */
    @TestVisible
    private void retrieveLeadInformation() {
        //assign filters to variables since dynamic query cannot process 'this'
        Set<Id> conIds = this.spsDAOByContactId.keySet();
        Set<Id> existingLeadIdSet = new Set<Id>();
        List<Lead> leadList = this.selector.selectExistingLeads(conIds);

        for (Lead iLead : leadList) {
            StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(iLead.Active_Lead_Contact_Id__c);
            //if a Lead already exists for the same contact, pop it
            Lead existingLead = spsDAO.getLead();
            if(existingLead != null) {
                existingLeadIdSet.remove(existingLead.Id);
            }
            spsDAO.setLead(iLead);
            existingLeadIdSet.add(iLead.Id);
        }
        retrieveExistingLCA(existingLeadIdSet);
        retrieveCourseMasters();
    }

    /**
    * @description queries all existing Contact within CRM based on collected IDs
    * @return void
    */
    @TestVisible
    private void retrieveExistingContacts() {
        List<Contact> conList = this.selector.selectExistingContacts(this.spsDAOByContactId.keySet());
        for(Contact iCon : conList) {
            StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(iCon.Id);
            spsDAO.setPerson(iCon);
        }
    }

    /**
     * @description queries all Prospective Student related Roles and Channels
     *  if query finds multiple 'current' roles: latest, greatest.
     * @return void
     */
    @TestVisible
    private void retrieveExistingRolesAndChannels() {
        Set<Id> existingRoleIdSet = new Set<Id>();
        //query is ordered by ascending so that we would retain the latest ones
        List<Roles__c> roleList = this.selector.selectContactRolesByContactId(this.spsDAOByContactId.keySet());

        for (Roles__c iRole : roleList) {
            StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(iRole.Contact__c);
            //if a role already exists for the same contact, pop it
            Roles__c existingRole = spsDAO.getPersonRole();
            if(existingRole != null) {
                existingRoleIdSet.remove(existingRole.Id);
            }
            //set latest Role
            spsDAO.setPersonRole(iRole);
            existingRoleIdSet.add(iRole.Id);
        }

        retrieveExistingChannels(existingRoleIdSet);
    }

    /**
     * @description Retrieve all Channels related to contact. We need to use a dynamic query 
     *  since getting all fields is required for the 'Do not Overwrite' feature to know if 
     *  there are current values.
     * @return void
     */
    @TestVisible
    private void retrieveExistingChannels(Set<Id> roleIds) {
        //build query String
        List<Channel__c> chList = this.selector.selectContactChannelByRoleId(roleIds);

        for (Channel__c iChannel : chList) {
            StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(iChannel.Contact__c);
            spsDAO.setPersonChannel(iChannel);
        }
    }

    /**
     * @description for retrieving existing Lead Course Associations based on the collected
     *  Course IDs and/or Course Codes + Lead IDs
     * @return void
     */
    @TestVisible
    private void retrieveExistingLCA(Set<Id> existingLeadIdSet) {
        List<Lead_Course_Association__c> lcaList = this.selector.selectExistingLCA(existingLeadIdSet, this.interestedCourseSet);
        for(Lead_Course_Association__c lca : lcaList) {
            StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(lca.Lead__r.Active_Lead_Contact_Id__c);
            spsDAO.addCourseInterest(lca);
        }
    }

    /**
     * @description retrieve all existing Courses and map by course code and ID
     * @return void
     */
    @TestVisible
    private void retrieveCourseMasters() {
        List<Course_Master__c> cmList = this.selector.selectCourseMasters(this.interestedCourseSet);
        for(Course_Master__c iCourse : cmList) {
            this.courseByCode.put(iCourse.Course_Code__c, iCourse);
            this.courseById.put(iCourse.Id, iCourse);
        }
    }

    /**
     * @description retrieve all existing campaign members for contacts
     * @return void
     */
    @TestVisible
    private void retrieveExistingCampaignMember() {
        Set<Id> campaignIds = new Set<Id>();
        campaignIds.addAll(this.subscriptionListIDs);
        campaignIds.addAll(this.eventCampaignIDs);
        campaignIds.addAll(this.aSourceCampaignIDs);

        List<Campaign> campList = this.selector.selectExistingCampaignMember(this.spsDAOByContactId.keySet(), campaignIds);
        for (Campaign iCamp : campList) {
            this.existingCampaignMap.put(iCamp.Id, iCamp);
            addPersonCampaignMembers(iCamp.CampaignMembers);
        }
    }

    /**
     * @description retrieve all Contact Qualifications related to contact
     * @return void
     */
    @TestVisible
    private void retrieveExistingContactQualifications() {
        List<Contact_Qualification__c> cqList = this.selector.selectExistingContactQualifications(this.spsDAOByContactId.keySet(), this.qualificationNameSet, this.qualificationInstitutionNameSet);
        for (Contact_Qualification__c iCQ : cqList) {
            StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(iCQ.Contact__c);
            spsDAO.addPersonContactQualification(iCQ);
        }
    }

    /**
     * @description for retrieving existing Cases linked to the SPS. 
     *  This is for updating blank Lead lookup in Enquiry
     * @return void
     */
    @TestVisible
    private void retrieveExistingCases() {
        List<Case> caseList = this.selector.selectCases(this.spsDAOByContactId.keySet(), this.existingCaseMap.keySet());
        if(!this.existingCaseMap.isEmpty()) {
            for(Case iCase : caseList) {
                StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(iCase.ContactId);
                spsDAO.addProspectiveStudentEnquiry(iCase);
                this.existingCaseMap.put(iCase.Id, iCase);
            }
        }
    }

    /**
    * @description adds any existing campaign member records to it's corresponding SPS Data Access Object 
    * @param List<CampaignMember> cmList : List of Campaign Member records to be added
    * @return void
    */
    @TestVisible
    private void addPersonCampaignMembers(List<CampaignMember> cmList) {
        for(CampaignMember iCm : cmList) {
            addPersonCampaignMember(iCm);
        }
    }

    /**
    * @description adds any existing campaign member records to it's corresponding SPS Data Access Object 
    * @param CampaignMember cm : Campaign Member record to be added
    * @return void
    */
    @TestVisible
    private void addPersonCampaignMember(CampaignMember cm) {
        StagedProspectiveStudentDAO spsDAO = this.spsDAOByContactId.get(cm.ContactId);
        if(this.subscriptionListIDs.contains(cm.CampaignId)) {
            spsDAO.addSubscriptionMember(cm);
        } else if(this.eventCampaignIDs.contains(cm.CampaignId)) {
            spsDAO.addEventMembers(cm);
        } else if(this.aSourceCampaignIDs.contains(cm.CampaignId)) {
            spsDAO.addAcquisitionSource(cm);
        }
    }
}