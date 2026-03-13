/**
 * @Description        : Data access object for Staged Prospective Student
 * @Author             : Nick Guia
 * @Group              : Lead Management
 * TO BE DEPRECATED AFTER MOVING TO V2
 */
public inherited sharing class StagedProspectiveStudentDAO extends ProspectiveStudentDAO {
    //all sps list
    @TestVisible
    private List<Staged_Prospective_Student__c> spsList; 
    //all 'Do not Overwrite' SPS List
    private List<Staged_Prospective_Student__c> dnoSPSList; 
    //all 'Overwrite' SPS List
    private List<Staged_Prospective_Student__c> owSPSList; 
    //merged SPS regardless of DNO
    private Staged_Prospective_Student__c mergedSps; 
    //merged SPS considering DNO
    private Staged_Prospective_Student__c mergedSPSWithDNO; 
    //merged SPS of all 'overwrite'
    private Staged_Prospective_Student__c mergedOw; 
    //merged sps of all DNO
    private Staged_Prospective_Student__c mergedDNO; 
    //set of all subscription list campaign IDs collected
    private Set<Id> subscriptionListIDs {get; set;} 
    //filtered set of campaign IDs considering SPS DNO and existing Campaign Member records
    private Set<Id> filteredSubListIDs {get; set;} 
    //set of all event campaign IDs collected
    private Set<Id> eventCampaignIDs {get; set;} 
    //filtered set of campaign IDs considering SPS DNO and existing Campaign Member records
    private Set<Id> filteredEventCampaignIDs {get; set;} 
    //set of all acquisition source campaign IDs collected
    private Set<Id> aSourceCampaignIDs {get; set;} 
    //filtered set of campaign IDs considering SPS DNO and existing Campaign Member records
    private Set<Id> filteredASourceCampaignIDs {get; set;} 
    //needs to be a list to retain order
    private List<String> interestedCourseIds; 
    //filtered set of Course IDs considering SPS DNO and existing LCA's
    private List<String> filteredCourseIds; 
    //map of all contact qualifications mapped by String key
    private Map<String, Contact_Qualification__c> allContactQualifications; 
    //map of all "Staged" Cases without IDs with SPS Id as key
    private Map<Id, Case> stagedCases;
    
    private Id latestSPSId;

    public StagedProspectiveStudentDAO(Staged_Prospective_Student__c spsRec) {
        super();
        init();
        addSps(spsRec);
    }

    /**
     * @description stores all sps information that's associated with this
     *  Prospective Student record.
     */
    public void addSps(Staged_Prospective_Student__c spsRec) {
        spsList.add(spsRec);
        collectInterestedCourseIds(spsRec);
        collectAllContactQualifications(spsRec);
        collectSubListIds(spsRec);
        collectEventCampaignIds(spsRec);
        collectAcqSrcIds(spsRec);
        collectEnquiryDetails(spsRec);
    }

    /**
     * @description for getting the "Merged" version of bulkified SPS (points to the same Person / Contact)
     * @param isAll : determines whether the "Do Not Overwrite" checkbox needs to be respected.
     *                i.e. DNO == false wil always supersede field values
     * @return Staged_Prospective_Student__c : merged version of collected SPS for the same Person / Contact
     */
    public virtual Staged_Prospective_Student__c getMergedSpsRecords(Boolean isAll) {
        if(isAll) {
            if(this.mergedSps == null) {
                mergeSPSCombinations();
            }
            return this.mergedSps;
        } else {
            if(this.mergedSPSWithDNO == null) {
                mergeSPSCombinations();
            }
            return this.mergedSPSWithDNO;
        }
    }

    /**
     * @description retrieves all SPS records related with this Person
     * @return List<Staged_Prospective_Student__c> - all related SPS records
     */
    public List<Staged_Prospective_Student__c> getSpsRecords() {
        return this.spsList;
    }

    /**
     * @description retrieves all SPS marked as Do not overwrite = true
     * @return List<Staged_Prospective_Student__c> - all DNO SPS records
     */
    public List<Staged_Prospective_Student__c> getSpsDNO() {
        if(this.dnoSPSList.isEmpty()) {
            mergeSPSCombinations();
        }
        return this.dnoSPSList;
    }

    /**
     * @description retrieves all SPS marked as "Do not overwrite = false" i.e. Overwrite (OW)
     * @return List<Staged_Prospective_Student__c> - all OW SPS records
     */
    public List<Staged_Prospective_Student__c> getSpsOW() {
        if(this.owSPSList.isEmpty()) {
            mergeSPSCombinations();
        }
        return this.owSPSList;
    }

    /**
     * @description retrieves a merged version of all OW SPS records
     * @return Staged_Prospective_Student__c - merged version of all OW SPS records
     */
    public Staged_Prospective_Student__c getMergedSpsOw() {
        if(this.mergedOw == null) {
            mergeSPSCombinations();
        }
        return this.mergedOw;
    }

    /**
     * @description retrieves a merged version of all DNO SPS records
     * @return Staged_Prospective_Student__c - merged version of all DNO SPS records
     */
    public Staged_Prospective_Student__c getMergedSpsDNO() {
        if(this.mergedDNO == null) {
            mergeSPSCombinations();
        }
        return this.mergedDNO;
    }

    /**
     * @description Add Campaign ID into the collection if it passes criteria:
     *  - if SPS is DNO - create, but do not update existing campaign member
     *  - Otherwise, create/update
     */
    public Set<Id> getSubscriptionListIds() {
        if(!this.subscriptionListIDs.isEmpty() && this.filteredSubListIDs.isEmpty()) {
            //get existing campaign members
            Map<Id, CampaignMember> members = getAllMembers();

            for(Staged_Prospective_Student__c iSps : this.spsList) {
                try {
                    for(String strId : StagedProspectiveStudentUtil.collectIdsFromString(iSps.Subscription_Lists__c)) {
                        if(iSps.Do_Not_Overwrite__c) {
                            //if SPS DNO = true, only add ID if it's not a member yet
                            if(!members.containsKey(strId)) {
                                this.filteredSubListIDs.add(strId);
                            }
                        } else {
                            this.filteredSubListIDs.add(strId);
                        }
                    }
                } catch(Exception e) {
                    //silent handle to avoid fatal error
                    //exception logged by BulkSPSDAO
                    //todo: improve bulk collection
                    System.debug('!@# sps dao collectSubListIds error : ' + e.getMessage());
                }
            }
        }
        return this.filteredSubListIDs;
    }

    /**
     * @description Add Campaign ID into the collection if it passes criteria:
     *  - if SPS is DNO - create, but do not update existing campaign member
     *  - Otherwise, create/update
     */
    public Set<Id> getEventCampaignIds() {
        if(!this.eventCampaignIDs.isEmpty() && this.filteredEventCampaignIDs.isEmpty()) {
            //get existing campaign members
            Map<Id, CampaignMember> members = getAllMembers();

            for(Staged_Prospective_Student__c iSps : this.spsList) {
                try {
                    for(String strId : StagedProspectiveStudentUtil.collectIdsFromString(iSps.Event_Campaigns__c)) {
                        if(iSps.Do_Not_Overwrite__c) {
                            //if SPS DNO = true, only add ID if it's not a member yet
                            if(!members.containsKey(strId)) {
                                this.filteredEventCampaignIDs.add(strId);
                            }
                        } else {
                            this.filteredEventCampaignIDs.add(strId);
                        }
                    }
                } catch(Exception e) {
                    //silent handle to avoid fatal error
                    //exception logged by BulkSPSDAO
                    //todo: improve bulk collection
                    System.debug('!@# sps dao collectSubListIds error : ' + e.getMessage());
                }
            }
        }
        return this.filteredEventCampaignIDs;
    }

    /**
     * @description retrieves all collected acquisition source IDs
     * @return Set<Id> - all collected acquisition source IDs
     */
    public Set<Id> getAcquisitionSourceIds() {
        return this.aSourceCampaignIDs;
    }

    /**
     * @description for getting the filtered course IDs:
     *  -   if LCA already exists for Lead (determined by course ID), 
     *       only update LCA record if SPS DNO = false; otherwise, ignore.
     */
    public List<String> getInterestedCourseIds() {
        List<String> courseIds = new List<String>();
        if(!this.interestedCourseIds.isEmpty() && this.filteredCourseIds.isEmpty()) {
            
            Map<String, Lead_Course_Association__c> lcaMap = psLead.getCourseInterestsMapStr();
            for(Staged_Prospective_Student__c iSps : this.spsList) {
                for(String iCourseId : StagedProspectiveStudentUtil.collectCourseIdsFromString(iSps.Interested_Course_List__c)) {
                    //if sps is DNO and is an existing LCA - ignore 
                    if(!(iSps.Do_Not_Overwrite__c && lcaMap.containsKey(iCourseId))) {
                        courseIds.add(icourseId);
                    }
                }
            }
        }
        //last in - first out
        courseIds.addAll(this.filteredCourseIds);
        this.filteredCourseIds = courseIds;
        return this.filteredCourseIds;
    }

    /**
     * @description for sorting LCA rank by correct rank based on collect course IDs
     * @param courseList : list if collected Course Master IDs
     * @return map of course rank by ID
     */
    public Map<String, Integer> sortCourseIdByRank(List<String> courseList) {
        Map<String, Integer> rankByLcaID = new Map<String, Integer>();
        Integer rank = 1;
        for(String iCourseId : courseList) {
            if(!rankByLcaID.containsKey(iCourseId)) {
                rankByLcaID.put(iCourseId, rank);
                rank++;
            }
        }
        return rankByLcaID;
    }

    /**
     * @description retrieves all staged Contact Qualifications related to this Contact
     * @return Map<String, Contact_Qualification__c> - all staged Contact Qualifications related to this Contact
     */
    public Map<String, Contact_Qualification__c> getAllContactQualifications() {
        if(this.allContactQualifications.isEmpty()) {
            for(Staged_Prospective_Student__c iSps : this.spsList) {
                collectAllContactQualifications(iSps);
            }
        }
        return this.allContactQualifications;
    }

    public Map<Id, Case> getStagedCases() {
        return this.stagedCases;
    }

    public void setStagedCases(Map<Id, Case> stCases) {
        this.stagedCases = stCases;
    }

    //initialise variables
    private void init() {
        this.spsList = new List<Staged_Prospective_Student__c>();
        this.dnoSPSList = new List<Staged_Prospective_Student__c>();
        this.owSPSList = new List<Staged_Prospective_Student__c>();
        this.subscriptionListIDs = new Set<Id>();
        this.filteredSubListIDs = new Set<Id>();
        this.eventCampaignIDs = new Set<Id>();
        this.filteredEventCampaignIDs = new Set<Id>();
        this.aSourceCampaignIDs = new Set<Id>();
        this.filteredASourceCampaignIDs = new Set<Id>();
        this.interestedCourseIds = new List<String>();
        this.filteredCourseIds = new List<String>();
        this.allContactQualifications = new Map<String, Contact_Qualification__c>();
        this.stagedCases = new Map<Id, Case>();
    }

    /**
     * @description process all merged versions of SPS :
     *  mergedSps : get merged version of all SPS regardless of DNO
     *  dnoSPSList : List of SPS records with DNO = true
     *  owSPSList : List of SPS records with DNO = false
     *  mergedOw : merged SPS record of all OW SPS
     *  mergedDNO : merged SPS record of all DNO SPS
     *  mergedSPSWithDNO : merged version of all SPS records, but with consideration to the
     *      superseding value based on DNO i.e DNO = true field values only gets merged if base SPS field is null
     */
    private void mergeSPSCombinations() {
        //get merged version of all SPS regardless of DNO
        this.mergedSps = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordList(this.spsList);

        //collect all 'DNO', and 'OW' SPS
        for(Staged_Prospective_Student__c iSps : this.spsList) {
            if(iSps.Do_Not_Overwrite__c) {
                this.dnoSPSList.add(iSps);
            } else {
                this.owSPSList.add(iSps);
            }
        }

        //get merged version of all SPS considering 'DNO'
        this.mergedOw = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordList(this.owSPSList);
        this.mergedDNO = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordList(this.dnoSPSList);
        this.mergedSPSWithDNO = (Staged_Prospective_Student__c) CommonUtilities.mergeRecords(this.mergedDNO, this.mergedOw);
    }

    /**
     * @description for retrieving the SPS ID from the last index of the collection
     */
    public Id getLatestSPSId() {
        if(this.latestSPSId == null) {
            Integer lastIndex;

            if(this.dnoSPSList.isEmpty() && this.owSPSList.isEmpty()) {
                //lists have not yet been evaluated
                mergeSPSCombinations();
            }
            
            if(!this.owSPSList.isEmpty()) {
                //get latest ID from "Overwrite value"
                lastIndex = this.owSPSList.size() - 1;
                this.latestSPSId = this.owSPSList[lastIndex].Id;
            } else if(!this.dnoSPSList.isEmpty()) {
                //get latest ID from "Do Not Overwrite value"
                lastIndex = this.dnoSPSList.size() - 1;
                this.latestSPSId = this.dnoSPSList[lastIndex].Id;
            }
        }
        return this.latestSPSId;
    }

    /**
     * @description Assigns contact ID to all related SPS records. 
     *  If contact ID is null, it means contact creation is unsuccessful, if
     *  this is the case, update SPS Status to 'Fatal Error'
     */
    public void propagateContactIds() {
        Contact psContact = getPerson();
        for(Staged_Prospective_Student__c sps : this.spsList) {
            if(psContact != null && psContact.Id != null) {
                sps.Exploded_Target__c = psContact.Id;
            } else {
                sps.Status__c = Label.SPS_Status_Fatal_Error;
            }
        }
    }

    /**
     * @description Collects all Subscription List Campaign IDs from all SPS
     */
    private void collectSubListIds(Staged_Prospective_Student__c sps) {
        try {
            for(String strId : StagedProspectiveStudentUtil.collectIdsFromString(sps.Subscription_Lists__c)) {
                this.subscriptionListIDs.add(strId);
            }
        } catch(Exception e) {
            //silent handle to avoid fatal error
            //exception logged by BulkSPSDAO
            //todo: improve bulk collection
            System.debug(LoggingLevel.INFO, e.getMessage());
        }
    }

    /**
     * @description Collects all Event Campaign IDs from all SPS
     */
    private void collectEventCampaignIds(Staged_Prospective_Student__c sps) {
        try {
            for(String strId : StagedProspectiveStudentUtil.collectIdsFromString(sps.Event_Campaigns__c)) {
                this.eventCampaignIDs.add(strId);
            }
        } catch(Exception e) {
            //silent handle to avoid fatal error
            //exception logged by BulkSPSDAO
            //todo: improve bulk collection
            System.debug(LoggingLevel.INFO, e.getMessage());
        }
    }

    /**
     * @description Collects all Acquisition Source Campaign IDs from all SPS
     */
    private void collectAcqSrcIds(Staged_Prospective_Student__c sps) {
        if(sps.Acquisition_Source_Campaign__c != null) {
            aSourceCampaignIDs.add(sps.Acquisition_Source_Campaign__c);
        }
    }

    /**
     * @description Collects all Course Name/ID from all SPS
     */
    private void collectInterestedCourseIds(Staged_Prospective_Student__c sps) {
        for(String icourseId : StagedProspectiveStudentUtil.collectCourseIdsFromString(sps.Interested_Course_List__c)) {
            if(!this.interestedCourseIds.contains(icourseId)) {
                this.interestedCourseIds.add(icourseId);
            }
        }
    }

    /**
     * @description collects all Contact Qualification JSON string from all SPS, then deserialise them
     *  into a List<SObject>
     */
    private void collectAllContactQualifications(Staged_Prospective_Student__c sps) {
        if(String.isNotBlank(sps.Contact_Qualification_JSON__c)) {
            try {
                List<Contact_Qualification__c> cqList = 
                    (List<Contact_Qualification__c>) JSON.deserializeStrict(sps.Contact_Qualification_JSON__c,
                    List<Contact_Qualification__c>.class);
                for(Contact_Qualification__c iCq : cqList) {
                    String cqKey = StagedProspectiveStudentUtil.buildContactQualificationKey(iCq);
                    this.allContactQualifications.put(cqKey, iCq);
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            }
        }
    }

    /**
     * @description only collect enquiry details if SPS Do_Not_Overwrite__c field is false
     */
    private void collectEnquiryDetails(Staged_Prospective_Student__c spsRec) {
        //process enquiry only if DNO = false
        if(!spsRec.Do_Not_Overwrite__c) {
            Case caseRec;
            if(spsRec.Exploded_Enquiry__c != null) {
                //if enquiry already exists, collect for future query and populating Lead field
                caseRec = new Case(Id = spsRec.Exploded_Enquiry__c, ContactId = spsRec.Exploded_Target__c);
                addProspectiveStudentEnquiry(caseRec);
            } else {
                //otherwise, create a new case and collect in the staged cases
                //this is so that Cases with IDs (existing) won't mix up with new cases
                if(String.isNotBlank(spsRec.Enquiry_Subject__c) &&
                   String.isNotBlank(spsRec.Enquiry_Description__c)) 
                {
                    caseRec = new Case();
                    caseRec.Subject = spsRec.Enquiry_Subject__c;
                    caseRec.Description = spsRec.Enquiry_Description__c;
                    stagedCases.put(spsRec.Id, caseRec);
                }
            }
        }
    }
}