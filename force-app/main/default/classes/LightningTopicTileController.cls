public class LightningTopicTileController {
    
    @AuraEnabled
    public static list<TopicTileWrapper> getTopicList(){
        list<TopicTileWrapper> wrapperList = new list<TopicTileWrapper>();
        map<string,topic> topicMap = new map<string,topic>();
        map<string,string> topicNameColorCodeMap = new map<string,string>();
        /*Community_Topics__c customSettings = Community_Topics__c.getInstance(userInfo.getProfileId())!=NULL?Community_Topics__c.getInstance(userInfo.getProfileId()):Community_Topics__c.getOrgDefaults();
        string topicFieldAPI = customSettings.Topic_Field_API__c;
        Map<String, Schema.SobjectField> customSettingfields = Community_Topics__c.getSObjectType().getDescribe().fields.getMap();
        
        if(customSettings!= NULL && topicFieldAPI != '' && topicFieldAPI != NULL && !customSettingfields.isEmpty()) {
            list<string> apiList = topicFieldAPI.split(',');
            system.debug('>>>'+apiList);
            for(string topicNameAPI: topicFieldAPI.split(',')){
                if(customSettingfields.containsKey(topicNameAPI)) {
                    if(customSettings.get(topicNameAPI)!=NULL) {
                        string colorCodeAPI = topicNameAPI.removeEnd('__c') + '_Color__c';
                        string colourCode = string.valueOf(customSettings.get(colorCodeAPI)) != NULL? string.valueOf(customSettings.get(colorCodeAPI)) : string.valueOf(customSettings.get('Default_Color_Code__c'));
                        topicNameColorCodeMap.put(string.valueOf(customSettings.get(topicNameAPI)).toUpperCase(),colourCode);
                    }
                }
            }
            system.debug('>>>>>>topicNameColorCodeMap'+topicNameColorCodeMap);
        }*/        
        String currentProfileId=String.valueOf(userInfo.getProfileId()).subString(0,15);
        String orgId=String.valueOf(UserInfo.getOrganizationId()).subString(0,15);
        Map<String,List<ConfigureCommunityTopic__c>> configureTopicMap=new Map<String,List<ConfigureCommunityTopic__c>>();
        // list of topics visible per profile
		List<ConfigureCommunityTopic__c> communityTopicsByProfile=[select id,Name,ColorCode__c,ProfileId__c, PermissionSetName__c, Order__c from ConfigureCommunityTopic__c where ProfileId__c=:currentProfileId  or ProfileId__c=:orgId order by Order__c asc]; 

		// set of permission sets assigned to the user
		Set<String> permissionSetsAssigned = new Set<String>();

		// loop through the query and populate the set
		for(PermissionSetAssignment psa: [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId =: UserInfo.getUserId()]){
			permissionSetsAssigned.add(psa.PermissionSet.Name);
		}

		// generate a map of profile and the list of topics visible
		for(ConfigureCommunityTopic__c topic: communityTopicsByProfile) {
			if(configureTopicMap.containsKey(topic.ProfileId__c)) {
				configureTopicMap.get(topic.ProfileId__c).add(topic);
			}
			else {
				configureTopicMap.put(topic.ProfileId__c,new List<ConfigureCommunityTopic__c>{topic});
			}
		}


		if(configureTopicMap.containsKey(currentProfileId)) {
			
			//if profile == staff or student, check the perm set if exists
			for(ConfigureCommunityTopic__c topic: configureTopicMap.get(currentProfileId)) {
				// if the topic.PermissionSetName__c is not blank, then validate if the user has the permission assigned to it before
				if(String.isBlank(topic.PermissionSetName__c) || (String.isNotBlank(topic.PermissionSetName__c) && permissionSetsAssigned.contains(topic.PermissionSetName__c))){
					topicNameColorCodeMap.put(topic.Name.toUpperCase(),topic.ColorCode__c);
				}                
			}
		}
		else {
			for(ConfigureCommunityTopic__c topic: configureTopicMap.get(orgId)) {
				topicNameColorCodeMap.put(topic.Name.toUpperCase(),topic.ColorCode__c);
			}
		}
        system.debug('topicNameColorCodeMap is '+topicNameColorCodeMap);
        if(!topicNameColorCodeMap.isEmpty()) {
            for(topic topicRecord:[select id,Name from topic where Name in :topicNameColorCodeMap.keyset()]) {
                topicMap.put(topicRecord.Name.toUpperCase(),topicRecord);
            }
        }
        system.debug('topicMap is '+topicMap);
        if(!topicMap.isEmpty() && !topicNameColorCodeMap.isEmpty()) {
            for(string topicName:topicNameColorCodeMap.keySet()) {
                if(topicMap.containsKey(topicName)){
                    wrapperList.add(new TopicTileWrapper(string.valueof(topicNameColorCodeMap.get(topicName)),topicMap.get(topicName)));
                }                    
            }
            system.debug('>>>>>>wrapperList'+wrapperList);
        }
        
        return wrapperList;
    }
    
    public class TopicTileWrapper {
        
        @AuraEnabled
        public string colourCode;
        @AuraEnabled
        public topic topicRecord;
        
        public TopicTileWrapper(string code,topic topicRec) {
            colourCode = code;
            topicRecord = topicRec;
        }
    }
    
}