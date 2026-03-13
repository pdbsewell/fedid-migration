/**
 * @File Name          : IProspectiveStudentCampaign.cls
 * @Description        : interface for ProspectiveStudentCampaignDAO
 * @Author             : Nick Guia
 * @Group              : Lead Management
 * TO BE DEPRECATED AFTER MOVING TO V2
**/
public interface IProspectiveStudentCampaign {
    /**
    * @description retrieves all campaign member records from Subscription List campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    Map<Id, CampaignMember> getSubscriptionMembers();
    /**
    * @description retrieves all campaign member records from Event campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    Map<Id, CampaignMember> getEventMembers();
    /**
    * @description retrieves all campaign member records from Acquisition Source campaigns
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    Map<Id, CampaignMember> getAcquisitionSource();
    /**
    * @description retrieves all campaign member records related to this Prospective Student
    * @return Map<Id, CampaignMember> : Map format of Campaign Member with CampaignID as key
    */
    Map<Id, CampaignMember> getAllMembers();
    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Subscription List type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    */
    void addSubscriptionMember(CampaignMember cm);
    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Event type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    */
    void addEventMembers(CampaignMember cm);   
    /**
    * @description adds a campaign member record for this Prospective Student in a
    *   Acquisition Source type of campaign
    * @param CampaignMember cm : the Campaign Member record to be added
    * @return void
    */ 
    void addAcquisitionSource(CampaignMember cm);
    /**
    * @description resolves dependencies and object relationships of all associated
    *   records within the Data Access Object and all child objects
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @param Lead leadRec : associated Prospective Student Lead
    * @return void
    */
    void resolveDependencies(BaseClass bc, Lead leadRec);
}