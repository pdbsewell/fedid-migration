/**
 * @author Nick Guia
 * @description Wrapper class for a Prospective Student
 * @date MAY.21.2018
 * @revision
 */
public class ProspectiveStudentwrapper {
	public Contact conRec {get; set;} // 'Prospective Student' contact
	public Lead leadRec {get; set;} // 'Prospective Student' lead
	public Roles__c roleRec {get; set;} // 'Prospective Student' role
	public Channel__c channelRec {get; set;} // map of channel ID and channel record
    public Map<Id, CampaignMember> cmByCampaignId {get; set;} // map of campaign ID and campaign member record
    public Map<String, Contact_Qualification__c> cqMap {get; set;} // map of CQ key and CQ record
    public Map<Id, List<Lead_Course_Association__c>> lcaMap {get; set;} // map of Lead ID and LCA record
    // set of Campaign IDs that this Prospective Student is to be added to
    public Set<Id> subscriptionListIDs {get; set;}
    public Set<Id> eventCampaignIDs {get; set;}
    public Set<Id> aSourceCampaignIds {get; set;}
    public List<Case> caseList {get; set;}
    public SPSRecords spsRecords {get; set;}

    //constructor
    public ProspectiveStudentwrapper() {
		this.cmByCampaignId = new Map<Id, CampaignMember>();
		this.cqMap = new Map<String, Contact_Qualification__c>();
		this.lcaMap = new Map<Id, List<Lead_Course_Association__c>>();
		this.subscriptionListIDs = new Set<Id>();
		this.eventCampaignIDs = new Set<Id>();
		this.aSourceCampaignIds = new Set<Id>();
        this.caseList = new List<Case>();
		this.spsRecords = new SPSRecords();
    }

    /**
     * @description add Lead Course Associations for this Prospective Student
     *				using Lead ID as the key
     */
    public void addLeadCourseAssociation(Id leadId, Lead_Course_Association__c lca) {
    	List<Lead_Course_Association__c> lcaList = this.lcaMap.get(lca.Lead__c);
        if(lcaList == null) lcaList = new List<Lead_Course_Association__c>();
        lcaList.add(lca);

        this.lcaMap.put(lca.Lead__c, lcaList);
    }

    /**
     * @description store Contact Qualifications by matching:
     * 				Contact__c:::Other_Qualification__c:::Institution_Name__c
     */
    public void addContactQualificationByKey(Contact_Qualification__c cq) {
    	
        String key = StagedProspectiveStudentUtil.buildContactQualificationKey(cq.Contact__c,
                                                                               cq.Other_Qualification__c,
                                                                               cq.Institution_Name__c);
        this.cqMap.put(key, cq);
    }

    //Internal wrapper class for SPS records
    public class SPSRecords {
    	public Map<Id, Staged_Prospective_Student__c> spsMap {get; set;} // map of sps ID and sps record
    	/**
    	 * @description maps all SPS by 'Do Not Overwrite' value
    	 */
    	public Map<Boolean, List<Staged_Prospective_Student__c>> spsByDNOMap {
    		get {
    			//if already populated, return. Assumption is that spsMap value won't change further
	    		if(this.spsByDNOMap.isEmpty()) {
	    			for(Staged_Prospective_Student__c sps : this.spsMap.values()) {
		                List<Staged_Prospective_Student__c> lSPS = this.spsByDNOMap.get(sps.Do_Not_Overwrite__c);
		                if (lSPS == null) lSPS = new List<Staged_Prospective_Student__c>();
		                lSPS.add(sps);
		                this.spsByDNOMap.put(sps.Do_Not_Overwrite__c, lSPS);
		            }
	    		}

	            return this.spsByDNOMap;
    		} set;
    	}
    	/**
    	 * @description merges all SPS records into one single object
    	 *				this won't be updated anymore after the first merge
    	 */
    	public Staged_Prospective_Student__c mergedAllSPS {
    		get {
    			if(mergedAllSPS == null) {
    				mergedAllSPS = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordList(this.spsMap.values());
    			}
    			return mergedAllSPS;
    		} set;
    	}
    	/**
    	 * @description merges all DNO SPS records into one single object
    	 *				this won't be updated anymore after the first merge
    	 */
    	public Staged_Prospective_Student__c mergedDNOSps {
    		get {
    			if(mergedDNOSps == null) {
    				mergedDNOSps = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordListOldestGreatest(this.spsByDNOMap.get(true));
    			}
    			return mergedDNOSps;
    		} set;
    	}
    	/**
    	 * @description merges all 'Overwrite' SPS records into one single object
    	 *				this won't be updated anymore after the first merge
    	 */
    	public Staged_Prospective_Student__c mergedOverwriteSps {
    		get {
    			if(mergedOverwriteSps == null) {
    				mergedOverwriteSps = (Staged_Prospective_Student__c) CommonUtilities.mergeRecordList(this.spsByDNOMap.get(false));
    			}
    			return mergedOverwriteSps;
    		} set;
    	}

    	public SPSRecords() {
    		this.spsMap = new Map<Id, Staged_Prospective_Student__c>();
    		this.spsByDNOMap = new Map<Boolean, List<Staged_Prospective_Student__c>>();
    	}
    }
}