/**
 * @author Nick Guia
 * @description prospective student's Campaigns data access object
 * @group Lead Management
 **/
public virtual inherited sharing class ProspectiveStudentCampaignDAO implements IProspectiveStudentCampaign {
    
    @TestVisible
    public Map<Id, CampaignMember> subscriptionListMembers;
    @TestVisible
    public Map<Id, CampaignMember> eventMembers;
    @TestVisible
    public Map<Id, CampaignMember> acquisitionSourceMembers;
    @TestVisible
    private Map<Id, CampaignMember> allMembers;

    public ProspectiveStudentCampaignDAO() {
        this.subscriptionListMembers = new Map<Id, CampaignMember>();
        this.eventMembers = new Map<Id, CampaignMember>();
        this.acquisitionSourceMembers = new Map<Id, CampaignMember>();
        this.allMembers = new Map<Id, CampaignMember>();
    }

    /**
    * @description retrieves all campaign member records related to this Prospective Student
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    public Map<Id, CampaignMember> getAllMembers() {
        Map<Id, CampaignMember> cmMap = this.allMembers;

        for(CampaignMember iCM : this.subscriptionListMembers.values()) {
            cmMap.put(iCM.CampaignId, iCM);
        }

        for(CampaignMember iCM : this.eventMembers.values()) {
            cmMap.put(iCM.CampaignId, iCM);
        }

        for(CampaignMember iCM : this.acquisitionSourceMembers.values()) {
            cmMap.put(iCM.CampaignId, iCM);
        }
        
        return cmMap;
    }

    /**
    * @description resolves dependencies and object relationships of all associated
    *   records within the Data Access Object and all child objects
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @param Lead leadRec : associated Prospective Student Lead
    * @return void
    */
    public void resolveDependencies(BaseClass bc, Lead leadRec) {
        Map<Id, CampaignMember> cmMap = getAllMembers();

        for(CampaignMember iCM : cmMap.values()) {
            bc.push(iCM, CampaignMember.Related_Prospect__c, leadRec);
        }
    }

    /**
    * @description retrieves all campaign member records from Subscription List campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public Map<Id, CampaignMember> getSubscriptionMembers() {
        return this.subscriptionListMembers;
    }

    /**
    * @description retrieves all campaign member records from Event campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public Map<Id, CampaignMember> getEventMembers() {
        return this.eventMembers;
    }

    /**
    * @description retrieves all campaign member records from Acquisition Source campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public Map<Id, CampaignMember> getAcquisitionSource() {
        return this.acquisitionSourceMembers;
    }

    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Subscription List type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public void addSubscriptionMember(CampaignMember cm) {
        this.subscriptionListMembers.put(cm.CampaignId, cm);
    }

    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Event type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public void addEventMembers(CampaignMember cm) {
        this.eventMembers.put(cm.CampaignId, cm);
    }

    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Acquisition Source type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    * TO BE DEPRECATED AFTER MOVING TO V2
    */ 
    public void addAcquisitionSource(CampaignMember cm) {
        this.acquisitionSourceMembers.put(cm.CampaignId, cm);
    }
}