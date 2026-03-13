/**
 * @Description        : Class that contains all logic for Exploding Leads
 * @Author             : Nick Guia
 * @Group              : Lead Management
 * @revision
 *  SEPT.28.2022    Nick Guia   - Added override on FLS when merging Lead records
 */
public without sharing class ExplodingLeadsService extends ExplodingLeadsFactory {

	@TestVisible
	private BaseClass bc;
	@TestVisible
	private BulkSPSDAO collection;
	@TestVisible
	private List<Staged_Prospective_Student__c> processSPS;

	public ExplodingLeadsService(List<Staged_Prospective_Student__c> spsList) {
		this.processSPS = spsList;
    }
    
    public ExplodingLeadsService(Staged_Prospective_Student__c sps) {
        this.processSPS = new List<Staged_Prospective_Student__c> { sps };
    }
    
    /**
	 * @description for creating a Contact record based on SPS details,
	 * and linking the created record back to the SPS (Exploded_Target__c).
     * This method of creating Contact via SPS uses FN, LN and Email as unique identifiers,
     * and attempts to find existing Contact.
     * @return List<Staged_Prospective_Student__c> : List of SPS with Exploded Target (Contact ID)
	 */
	public List<StagedProspectiveStudentDAO> buildPSContact() {

		Map<String, StagedProspectiveStudentDAO> spsDAOByKey = new Map<String, StagedProspectiveStudentDAO>();

        for(Staged_Prospective_Student__c iSps : this.processSPS) {
            if(String.isNotBlank(iSps.First_Name__c) &&
                String.isNotBlank(iSps.Last_Name__c) &&
                String.isNotBlank(iSps.Email__c))
            {
                //FirstName ::: LastName ::: Email combination
                String spsKey = StagedProspectiveStudentUtil.buildMatchingKey(
                    iSps.First_Name__c,
                    iSps.Last_Name__c,
                    iSps.Email__c
                    );

                StagedProspectiveStudentDAO spsDAO = spsDAOByKey.get(spsKey);
                if(spsDAO == null) {
                    spsDAO = new StagedProspectiveStudentDAO(iSps);
                    spsDAOByKey.put(spsKey, spsDAO);
                } else {
                    spsDAO.addSps(iSps);
                }
            }
        }

		return spsDAOByKey.values();
    }
    
    /**
     * @description upserts new/found contacts based on Duplicate Rule
     * @param spsDAOList : a list of initialise SPS DAO to contain all interrelated objects
     * @return List<Staged_Prospective_Student__c> : List of SPS with Exploded Target (Contact ID)
     */
    public List<Staged_Prospective_Student__c> upsertProspectiveStudentContact(List<StagedProspectiveStudentDAO> spsDAOList) {
        DuplicateContactFinder finder;
        List<Contact> conList = new List<Contact>();

        for(StagedProspectiveStudentDAO iSpsDAO : spsDAOList) {
            Contact psCon = iSpsDAO.getPerson();

            //if PS Contact hasn't been overwridden by a process
            if(psCon == null) {
                Staged_Prospective_Student__c mergedSps = iSpsDAO.getMergedSpsRecords(true);
                psCon = buildProspectiveContact(mergedSps);
            }

            finder = new DuplicateContactFinder(psCon);
            finder.enableExplodingLeads();
            finder.mockEmailFields(); 
            finder.findDuplicates();
            Contact existingCon = finder.getLatestContact();

            if(finder.isDuplicatesFound()) {
                psCon = mergeProspectiveContact(existingCon, psCon);
            } else {
                psCon = existingCon;
            }
            
            iSpsDAO.setPerson(psCon);
            conList.add(psCon);
        }
        List<Database.UpsertResult> srList = Database.upsert(conList, false);
        return propagateContactIds(spsDAOList);
    }

	/**
	 * @description Initialise all exploding leads variables
	 */
	public void initialiseExplodingLeads() {
		try {
			this.bc = new BaseClass(StagedProspectiveStudentUtil.commitOrder);
			this.collection = new BulkSPSDAO(this.processSPS);
		} catch(Exception e) {
			LogUtilityException.logException(e);
		}
	}

	/**
	 * @description Execute the creation of Exploding Leads related records:
	 *  Role, Channel, Lead, Lead Course Interest, Campaign Member, Contact Qualification, and Cases.
	 */
	public void execute() {
		List<StagedProspectiveStudentDAO> spsDAOList = collection.getBulkCollectionResult();
		for(StagedProspectiveStudentDAO spsDAO : spsDAOList) {
			try {
				generateProspectiveRoles(spsDAO);
				generateProspectiveChannels(spsDAO);
				generateProspectiveLeads(spsDAO);
				generateLeadInterests(spsDAO);
				generateCampaignMembers(spsDAO);
				generateContactQualifications(spsDAO);
				generateCases(spsDAO);
				spsDAO.resolveDependencies(this.bc);
			} catch(Exception e) {
				LogUtilityException.logException(e);
			}
		}
	}

	/**
	 * @description Partial commit all records that were processed by Exploding Leads.
	 * @return Set<Id> Ids of Contacts whose SPS records got a 'Partial Error'
	 */
	public Set<Id> commitRecords() {
		Set<Id> partialErrorContacts = new Set<Id>();
		BaseClass.ResultSet rs = bc.commitRecordsPartial();

		for (String sObjectType : rs.errorMap.keySet()) {
			for(BaseClass.ErrorRecord errorRec : rs.errorMap.get(sObjectType)) {

				SObject sObj = errorRec.record;
				String contactId;

				switch on sObjectType {
					//CASE 1: Error occurred in Lead
					when 'Lead' {
						contactId = String.valueOf(sObj.get('Active_Lead_Contact_Id__c'));
					}
					// CASE 2: Error occurred in Role, Channel, or Contact Qualification
					when 'Roles__c', 'Channel__c', 'Contact_Qualification__c' {
						contactId = String.valueOf(sObj.get('Contact__c'));
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

		//reset BaseClass instance
		this.bc = new BaseClass(StagedProspectiveStudentUtil.commitOrder);
		return partialErrorContacts;
	}

	/**
	 *  @description for getting the collected SPS information mapped by Contact ID.
	 *      This is being referenced by LWC Controllers
	 */
	public Map<Id, StagedProspectiveStudentDAO> getSpsDAOMap() {
		return collection.getBulkCollectionResultMap();
	}

	/**
	 * @description Updates the SPS records after all the processing.
	 *  - Updates Exploded Target field with the resulting Contact record
	 *  - Updates the Exploded Lead field with the resulting Lead record
	 *  - Updates the Exploded Enquiry with the resulting Case record
	 *  - Updates SPS Status to 'Partial Error' if any errors occurred after creating the Contact
	 *  - Updates SPS Status to 'Success' if there are zero errors.
	 */
	public void updateSPSRecords(Set<Id> partialErrorContacts) {
		try {
			Map<Id, StagedProspectiveStudentDAO> spsDAOByContactId = collection.getBulkCollectionResultMap();

			//create a map of SPS records that contains a new instance of each record for update
			//this is to prevent record locking due to currently running Triggers
			Map<Id, Staged_Prospective_Student__c> spsMap = new Map<Id, Staged_Prospective_Student__c>();

			for(Id iConId : spsDAOByContactId.keySet()) {
				StagedProspectiveStudentDAO spsDAO = spsDAOByContactId.get(iConId);
				Lead leadRec = spsDAO.getLead();
				/**
				 * at this stage, theses Cases will now have an ID.
				 * Use these map to link the cases to the source SPS record
				 */
				Map<Id, Case> stagedCases = spsDAO.getStagedCases();

				//link Exploded Lead into SPS
				for(Staged_Prospective_Student__c iSps : spsDAO.getSpsRecords()) {

					Staged_Prospective_Student__c upSpsRec = spsMap.get(iSps.Id);
					Case iCase = stagedCases.get(iSps.Id);
					//instantiate new sps instance to work around read-only locks
					if(upSpsRec == null) {
						upSpsRec = new Staged_Prospective_Student__c(
							Id = iSps.Id,
							Exploded_Target__c = iConId);
					}

					if(leadRec != null) {
						upSpsRec.Exploded_Lead__c = leadRec.Id;
					}

					if(iCase != null) {
						upSpsRec.Exploded_Enquiry__c = iCase.Id;
					}

					if(partialErrorContacts.contains(iConId)) {
						upSpsRec.Status__c = Label.SPS_Status_Partial_Error;
					} else {
						upSpsRec.Status__c = Label.SPS_Status_Success;
					}

					spsMap.put(upSpsRec.Id, upSpsRec);
				}
			}

			//get sps records with invalid contact qualification format and update with Partial Error
			List<Staged_Prospective_Student__c> partialErrorSps = collection.getPartialErrorSps();
			for(Staged_Prospective_Student__c iSps : partialErrorSps) {
				//first, check the sps updated value
				Staged_Prospective_Student__c upSps = spsMap.get(iSps.Id);
				if(upSps == null) {
					upSps = new Staged_Prospective_Student__c(Id = iSps.Id);
				}
				upSps.Status__c = Label.SPS_Status_Partial_Error;
				spsMap.put(upSps.Id, upSps);
			}

			if(!spsMap.isEmpty()) {
				update spsMap.values();
			}
		} catch(Exception e) {
			LogUtilityException.logException(e);
		}
	}

	/**
	 * @description
	 * Roles generation rules:
	 *  -   If Prospective Student Role already exists, only update external ID from
	 *      the latest DNO = false SPS record
	 *  -   If Prospective Student Role doesn't exist yet, create a new one
	 */
	private void generateProspectiveRoles(StagedProspectiveStudentDAO spsDAO) {
		//check for existing Role
		Roles__c psRole = spsDAO.getPersonRole();
		if(psRole != null) {
			psRole.External_ID__c = spsDAO.getLatestSPSId();
		} else {
			//create new Role
			psRole = buildProspectiveRole(spsDAO.getMergedSpsRecords(true));
		}
		spsDAO.setPersonRole(psRole);
	}

    /**
     * @description 
     * Channel generation rules:
     *  -   If Prospective Student Channel already exists, 
     *       update with new details (respecting the "Do not Overwrite" logic)
     *  -   If Prospective Student Channel doesn't exist, 
     *       create a new one based on the merged SPS details (respecting the "Do not Overwrite" logic)
     */
    private void generateProspectiveChannels(StagedProspectiveStudentDAO spsDAO) {
        //check for existing Channel
        Channel__c psChannelExisting = spsDAO.getPersonChannel();
        Channel__c owChannel; //channel record derived from "overwrite" SPS
        Channel__c dnoChannel; //channel record derived from "DNO" SPS
        Channel__c newChannel; //resulting channel record

        //create a channel record for "overwrite" SPS
        owChannel = buildProspectiveChannel(spsDAO.getMergedSpsOw());
        //create a channel record for "overwrite" SPS
        dnoChannel = buildProspectiveChannel(spsDAO.getMergedSpsDNO());
        //then merge then 'overwrite' channel with existing Channel
        newChannel = (Channel__c) CommonUtilities.mergeRecords(psChannelExisting, owChannel);
        //populate null values only, from the DNO channel
        newChannel = (Channel__c) CommonUtilities.mergeRecords(dnoChannel, newChannel);

        if(psChannelExisting != null) {
            newChannel.Id = psChannelExisting.Id;
        }
        //set to false for channel break up to re-process
        newChannel.is_Processed__c = false;
        spsDAO.setPersonChannel(newChannel);
    }

    /**
     * @description 
     * Lead generation rules:
     *  - we must iterate through SPS records of non-Do not overwrite, and overwrite SPS list.
     *  this is to know whether we append, or overwrite Broad Areas of Interest multi picklist value
     */
    private void generateProspectiveLeads(StagedProspectiveStudentDAO spsDAO) {
        Lead psLeadExisting = spsDAO.getLead(); //check for existing Lead
        /**
         * create a Lead record based on spsOverwriteList records
         */
        Lead psLeadOW = buildProspectiveLead(psLeadExisting, spsDAO.getSpsOW());
        /**
         * create a Lead record based on spsDoNotOverwriteList records while considering
         * values provided by the psLeadOW i.e. BAOI and Acquisition Source
         */
        Lead psLeadDNO = buildProspectiveLead(psLeadOW, spsDAO.getSpsDNO());
        /**
         * the Lead record generated from the overwrite list will then be merged to
         * the existing Lead record to overwrite all fields except the null values from psLeadOW
         */
        Lead mergedLead = (Lead) CommonUtilities.mergeRecords(psLeadExisting, psLeadOW, true);
        /**
         * the merged record from the above will then be merged again to the
         * 'psLeadDNO' Lead, meaning psLeadDNO will only populate null
         * values from it.
         */
        mergedLead = (Lead) CommonUtilities.mergeRecords(psLeadDNO, mergedLead, true);

        //assign back original acquisition source of existing lead (if any)
        if(psLeadExisting != null && psLeadExisting.Acquisition_Source__c != null) {
            mergedLead.Acquisition_Source__c = psLeadExisting.Acquisition_Source__c;
        }
        
        //assign back ID of existing Lead, as we lose it during merging
        if(psLeadExisting != null && psLeadExisting.Id != null) {
            mergedLead.Id = psLeadExisting.Id;
        }
        spsDAO.setLead(mergedLead);
    }

    /**
     * @description 
     * Lead Course Association generation rules:
     *  -   if LCA already exists for Lead (determined by course ID), 
     *       only update LCA record if SPS DNO = false; otherwise, ignore.
     *  -   if LCA does not exist for Lead (determined by course ID), 
     *       create a new LCA record, with ranking based on order of input (delimited)
     */
    public void generateLeadInterests(StagedProspectiveStudentDAO spsDAO) {
        Map<Id, Lead_Course_Association__c> newLcaMapByCourseId = new Map<Id, Lead_Course_Association__c>();
        //get existing LCA's mapped by Course Master ID
        Map<Id, Lead_Course_Association__c> lcaByCourseId = spsDAO.getCourseInterestsMap();
        //get collected Course IDs from new SPS
        List<String> newCourseIds = spsDAO.getInterestedCourseIds();
        //sort the list by rank. Do not rank ruplicate IDs
        Map<String, Integer> courseIdByRank = spsDAO.sortCourseIdByRank(newCourseIds);

        for(String courseId : courseIdByRank.keySet()) {
            //check if indicated course ID exists
            Course_Master__c cmRec = collection.getCourseMaster(courseId);
            if(cmRec != null) {
                Lead_Course_Association__c lcaRec = buildLeadCourseAssociation(cmRec.Id, courseIdByRank.get(courseId));
                //if LCA already exists - update
                if(lcaByCourseId.containsKey(cmRec.Id)) {
                    lcaRec.Id = lcaByCourseId.get(cmRec.Id).Id;
                }
                newLcaMapByCourseId.put(cmRec.Id, lcaRec);
            }
        }
        spsDAO.setCourseInterest(newLcaMapByCourseId.values());
    }

    /**
     * Campaign Member generation rules:
     *  -   if loopSPS is overwrite, update Campaign Member if existing.
     *      If Otherwise, do not update
     *  -   Always base the campaign member details off the "merged overwrite" SPS,
     *      if it doesn't exist, use the merged do not overwrite SPS record.
     */
    private void generateCampaignMembers(StagedProspectiveStudentDAO spsDAO) {
        Set<Id> subListIds = spsDAO.getSubscriptionListIds();
        Set<Id> eventIds = spsDAO.getEventCampaignIds();
        Set<Id> acSourceIds = spsDAO.getAcquisitionSourceIds();

        Staged_Prospective_Student__c spsRec;
        spsRec = spsDAO.getMergedSpsOw(); //get sps 'overwrite' list;
        if(spsRec == null) {
            spsRec = spsDAO.getMergedSpsDNO();
        }

        for(Id iSubId : subListIds) {
            generateSubscriptionListMember(spsDAO, spsRec, iSubId);
            eventIds.remove(iSubId);
            acSourceIds.remove(iSubId);
        }

        for(Id iEventId : eventIds) {
            generateEventMember(spsDAO, spsRec, iEventId);
            acSourceIds.remove(iEventId);
        }

        for(Id iAsrcId : acSourceIds) {
            generateAcquisitionSourceMember(spsDAO, spsRec, iAsrcId);
        }
    }

    /**
     * @description for creating a Subscription List Campaign Member.
     *  only updates an existing campaign member if sps do not overwrite = false;
     */
    private void generateSubscriptionListMember(
        StagedProspectiveStudentDAO spsDAO, 
        Staged_Prospective_Student__c spsRec,
        Id campaignId) 
    {
        //check if campaign is existing
        Campaign camp = collection.getExistingCampaign(campaignId);
        if(camp != null) {
            Contact psCon = spsDAO.getPerson();
            CampaignMember cm = spsDAO.getSubscriptionMembers().get(campaignId);
            if(cm == null) {
                cm = new CampaignMember(
                    ContactId = psCon.Id,
                    CampaignId = campaignId
                );
            }
            cm = buildSubscriptionMember(camp, cm, spsRec);
            spsDAO.addSubscriptionMember(cm);
        }
    }

    /**
     * @description for creating a Event Campaign Member.
     *  only updates an existing campaign member if sps do not overwrite = false;
     */
    private void generateEventMember(
        StagedProspectiveStudentDAO spsDAO, 
        Staged_Prospective_Student__c spsRec,
        Id campaignId) 
    {
        //check if campaign is existing
        Campaign camp = collection.getExistingCampaign(campaignId);
        if(camp != null) {
            Contact psCon = spsDAO.getPerson();
            CampaignMember cm = spsDAO.getEventMembers().get(campaignId);
            if(cm == null) {
                cm = new CampaignMember(
                    ContactId = psCon.Id,
                    CampaignId = campaignId,
                    Status = spsRec.Event_Member_Status__c
                );
            }
            cm.Active__c = true;
            cm.Web_Lead_Source__c = spsRec.Web_Lead_Source__c;
            cm.Number_of_Attendees__c = spsRec.Number_of_Attendees__c;
            cm.Dietary_Requirements__c = spsRec.Dietary_Requirements__c;
            cm.Session__c = spsRec.Session__c;
            spsDAO.addEventMembers(cm);
        }
    }

    /**
     * @description for creating an Acquisition Source Campaign Member.
     *  always just creates a new record if it doesn't exist yet. Otherwise, do not
     *  update an existing one.
     */
    private void generateAcquisitionSourceMember(
        StagedProspectiveStudentDAO spsDAO, 
        Staged_Prospective_Student__c spsRec,
        Id campaignId) 
    {
        //check if campaign is existing
        Campaign camp = collection.getExistingCampaign(campaignId);
        if(camp != null) {
            Contact psCon = spsDAO.getPerson();
            CampaignMember cm = spsDAO.getAcquisitionSource().get(campaignId);
            if(cm == null) {
                cm = new CampaignMember(
                    ContactId = psCon.Id,
                    CampaignId = campaignId,
                    Web_Lead_Source__c = spsRec.Web_Lead_Source__c,
                    Active__c = true
                );
            }
            spsDAO.addAcquisitionSource(cm);
        }
    }

    /**
     * Contact Qualification generation rules:
     *  -   Minimum Contact Qualification data: Other_Qualification__c, Institution_Name__c
     *  -   Only create new Contact Qualification based on key: 
     *           Other_Qualification__c.toLowerCase() + ':::' + Institution_Name__c.toLowerCase()
     *  -   if Contact Qualification already exists, do not update
     */
    private void generateContactQualifications(StagedProspectiveStudentDAO spsDAO) {
        Map<String, Contact_Qualification__c> existingCqByKey = new Map<String, Contact_Qualification__c>();
        Map<String, Contact_Qualification__c> newCqByKey = spsDAO.getAllContactQualifications();

        //check for existing Contact Qualifications
        for(Contact_Qualification__c iCq : spsDAO.getPersonContactQualification()) {
            existingCqByKey.put(StagedProspectiveStudentUtil.buildContactQualificationKey(iCq), iCq);
        }

        //get collected Contact Qualifications from SPS
        for(String iCqKey : newCqByKey.keySet()) {
            //if not existing yet based on key, create
            if(!existingCqByKey.containsKey(iCqKey)) {
                spsDAO.addPersonContactQualification(newCqByKey.get(iCqKey));
            }
        }
    }

	/**
	 * Case generation rules:
	 *  -   If Enquiry ID isn't provided in the SPS, use EnquiryGenerator to create a new one
	 *  -   If enquiry already exists, only update the Lead field if it's null
	 */
	private void generateCases(StagedProspectiveStudentDAO spsDAO) {
		//get existing cases - thses cases doesn't have all the fields yet
		Map<Id, Case> existingCases = new Map<Id, Case>();
		for(Case iCase : spsDAO.getProspectiveStudentEnquiries()) {
			existingCases.put(iCase.Id, iCase); //cannot construct directly to map due to potential duplicate IDs
        }
        //get staged cases
        Map<Id, Case> stagedCases = spsDAO.getStagedCases();
        //this will contain the final list of prospective student cases 
        List<Case> newCaseList = new List<Case>();

        //get the Case instance that contains the queried fields
        for(Case iCase : existingCases.values()) {
            Case c = collection.getExistingCase(iCase.Id);
            if(c != null) {
                newCaseList.add(c);
            }
        }

        //groom the staged cases with more details
        for(Id spsId : stagedCases.keySet()) {
            Case iCase = stagedCases.get(spsId);
            EnquiryGenerator enqGenerator = new EnquiryGenerator(
                                                EnquiryUtil.EnquiryPurpose.STUDENT,
                                                spsDAO.getPerson(),
                                                spsDAO.getLead());
            iCase = enqGenerator.generateEnquiry(iCase.Subject, iCase.Description);
            newCaseList.add(iCase);
            /**
             * update stagedCases map - this is so that we can link back 
             * the "Exploded Enquiry" to the source SPS
             */
            stagedCases.put(spsId, iCase);
        }

        //replace the existing related enquiries with the Prospective Student
        spsDAO.setProspectiveStudentEnquiries(newCaseList);
        //replace the existing stagedCases map
        spsDAO.setStagedCases(stagedCases);
    }

    /**
     * @description assigns contact record to each related SPS record
     */
    private List<Staged_Prospective_Student__c> propagateContactIds(List<StagedProspectiveStudentDAO> spsDAOList) {
        List<Staged_Prospective_Student__c> spsRecs = new List<Staged_Prospective_Student__c>();
        for(StagedProspectiveStudentDAO iSpsDAO : spsDAOList) {
            iSpsDAO.propagateContactIds();
            spsRecs.addAll(iSpsDAO.getSpsRecords());
        }
        this.processSPS = spsRecs;
        return spsRecs;
	}
}