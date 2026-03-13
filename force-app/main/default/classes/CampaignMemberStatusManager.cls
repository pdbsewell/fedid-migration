/**
 * @author Nick Guia
 * @date 24-08-2020
 * @group Commons
 * @description Builder class for CampaignMemberStatus object
 * @revision 
 *  15.06.2021  Ibrahim Rumi    - EPBBS-1988 updated class EventCampaignMemberStatuses to fetch the related campaign member status from Campaign_Member_Status__mdt
 *	22-03-2022	Ibrahim Rumi	- EPBBS-2121 updated the builder class to accept multiple campaigns of various record types and process campaignMemberStatuses
 *	21-03-2025	Vinothraja	    - EPCP-4433 updated the builder class to generate campaign member statuses based on campaign type
 **/
public with sharing class CampaignMemberStatusManager {
    
    public static map<Id, List<Campaign_Member_Status__mdt>> campMemStatusesByCampRecType {
            get {
                if(campMemStatusesByCampRecType == null) {
                    campMemStatusesByCampRecType = new CampaignServices().retrieveCampMembStatusesByCampaignRecType();
                }
                return campMemStatusesByCampRecType;
            }
            set;
        }

    public static map<String, List<Campaign_Member_Status__mdt>> campMemStatusesByCampType {
            get {
                if(campMemStatusesByCampType == null) {
                    campMemStatusesByCampType = new CampaignServices().retrieveCampMembStatusesByCampaignType();
                }
                return campMemStatusesByCampType;
            }
            set;
        }
    
    /**
     * Resolves duplicate campaign member statuses from the provided list.
     * -- If a default status already exists in the list, then subsequent statuses with the default flag set, will be ignored.
     * 
     * @param statuses A list of Campaign_member_status__mdt records to process.
     * @return A list of Campaign_member_status__mdt records with duplicates and defaults resolved.
     */
    public static List<Campaign_member_status__mdt> resolveDuplicateAndDefaultStatuses (List<Campaign_member_status__mdt> statuses) {
        Map<String, Campaign_member_status__mdt> mapLabelStatus = new Map<String, Campaign_member_status__mdt>();
        Boolean isDefaultStatusSet = false;
        for(Campaign_member_status__mdt status : statuses) {
            if(!mapLabelStatus.containsKey(status.MasterLabel)) {
                mapLabelStatus.put(status.MasterLabel, status); // add the status to the map
                if (status.Is_Default__c && !isDefaultStatusSet) { // if status has is_default__c checked, then set the flag
                    isDefaultStatusSet = true;
                } else {
                    status.Is_Default__c = false; // Subsequent default status, so set the field to false
                }
            } 
        }
        return mapLabelStatus.values();
    }

    public class Builder {
		@TestVisible
        private Map<id,campaign> campaignMap;
        
        @TestVisible
        private List<CampaignMemberStatus> defaultStatusList;
        
        public Builder(Campaign campaign) {
            this.campaignMap = new Map<Id,campaign>{campaign.Id => campaign};
        }

        public Builder(List<campaign> campaigns) {
            this.campaignMap = new Map<id,campaign>(campaigns);
        }

        /**
         * @description gets all current campaign member statuses of the campaign
         */
        public Builder getExistingStatuses() {
            this.defaultStatusList = [SELECT Id, Label, IsDefault
                                    FROM CampaignMemberStatus 
                                    WHERE CampaignId IN :this.campaignMap.keyset()];
            
            return this;
        }

        /**
         * @description builds the campaign member statuses
         */
        public Builder build() {
            try {
                List<CampaignMemberStatus> cmStatuses = new List<CampaignMemberStatus>();
                    for(campaign iCamp : this.campaignMap.values()) {
                            cmStatuses.addAll(buildCampaignMemberStatuses(iCamp.id, iCamp.recordtypeid, iCamp.Type));
                    }

                if(cmStatuses.size() >0) insert cmStatuses;
                
            } catch(Exception e) {
                throw new CampaignMemberStatusManagerException('Unable to build Campaign Member Statuses : ' + e.getMessage());
            }
            return this;
        }

        public Builder deletePreviousStatuses() {
            try {
                if(!this.defaultStatusList.isEmpty()) {
                    delete this.defaultStatusList;
                }
            } catch(Exception e) {
                throw new CampaignMemberStatusManagerException('Unable to delete previous Campaign Member Statuses : ' + e.getMessage());
            }
            return this;
        }
        /**
         * @description sets the campaignmemberstatuses
         * @param campId : campaign id 
         * @param campRecType : campaign record type
         * @param campType : campaign type
         */
        private List <CampaignMemberStatus> buildCampaignMemberStatuses(Id campId, Id campRecType, String campType) {
            
            List<CampaignMemberStatus> cmstatus = new List<CampaignMemberStatus>();

            List<Campaign_Member_Status__mdt> cmStatusList = new List<Campaign_Member_Status__mdt>();
            if(campType != null && campMemStatusesByCampType?.containsKey(campType)) { // campaign type based statuses
                cmStatusList.addAll(campMemStatusesByCampType?.get(campType));
            }  
            if (campRecType != null && campMemStatusesByCampRecType?.containsKey(campRecType)) { // campaign record type based statuses
                cmStatusList.addAll(campMemStatusesByCampRecType?.get(campRecType));
            }
            if(!cmStatusList?.isEmpty()){
                cmStatusList = resolveDuplicateAndDefaultStatuses(cmStatusList); 
                for(Campaign_Member_Status__mdt evStatus: cmStatusList){
                
                    CampaignMemberStatus cms = new CampaignMemberStatus();
                    cms.CampaignId = campId;
                    cms.Label = evStatus.MasterLabel;
                    cms.HasResponded = evStatus.Has_Responded__c;
                    cms.IsDefault = evStatus.Is_Default__c;
                    
                    cmstatus.add(cms);
                }
            }

            return cmstatus;
        }
    }

    public class CampaignMemberStatusManagerException extends Exception { }
}