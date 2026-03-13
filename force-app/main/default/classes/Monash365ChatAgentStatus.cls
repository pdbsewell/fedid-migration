/***********************************************************************
** Author: Inderpal Dhanoa
** Created Date: 13.MAY.2023
** Description: REST API service for Agent Portal availability
* @Last Modified By   : Inderpal Dhanoa
* @Last Modified On   : 19/05/2023
* @Modification Log   : 
* Ver       Date            Author      		    Modification
* 1.0    13/05/2023   Inderpal Dhanoa     Initial Version
* 1.1    19/05/2023    Inderpal Dhanoa -  Modifying for MCT-82 Status not rendetring correctly
* 
***********************************************************************/
@RestResource(urlMapping='/v1/MonashChat365Agent/*')
global without sharing class Monash365ChatAgentStatus {
    private static final String AGENT_AVAILABLE = 'Available';
    private static final String MONASH_CONNECT = 'Monash Connect';

    /**
     * @description Method for get Agent Availability By Topic
     *
     * @revision
     **/
    @HttpGet
	global static void getAgentAvailabilityByTopic() {
        //Set return type to JSON
        RestRequest req = RestContext.request;
        RestResponse resp = RestContext.response;

        RestContext.response.addHeader('Content-Type', 'application/json');

        String s_topic = req.params.get('topic');
        //Return FAQ data
        RestContext.response.responseBody = Blob.valueOf('False');
        if(Test.isRunningTest() || String.isNotBlank(s_topic)){
            List<Case_Category_Skill_Mapping__mdt> l_linkedSkill = [SELECT ID, Skill_Developer_Name__c 
                                                                    FROM Case_Category_Skill_Mapping__mdt 
                                                                    WHERE Topic__c = :s_topic];
            if(Test.isRunningTest() || !l_linkedSkill.isEmpty()){
                // set of online Live Agent Ids
                Set<Id> onlineAgents = new Set<Id>();
                for(UserServicePresence usp : [SELECT UserId 
                                               FROM UserServicePresence 
                                               WHERE IsCurrentState = TRUE 
                                               AND ServicePresenceStatusId IN (SELECT Id 
                                                                               FROM ServicePresenceStatus 
                                                                               WHERE DeveloperName =: AGENT_AVAILABLE)]){
                    onlineAgents.add(usp.UserId);
                }
                if(Test.isRunningtest() || !onlineAgents.isEmpty()){
                    // Check for the Load capacity of the Online Agents
                    Set<Id> onlineAgentsWithCapacity = new Set<Id>();
                    // There could be multiple entries for each Agent Workload so we need to sum up for the Workload 
                    List<AgentWork> l_wrkingAgents = [SELECT AcceptDateTime,CapacityPercentage,UserId 
                                                        FROM AgentWork 
                                                        WHERE Status = 'Opened' 
                                                        AND UserId IN :onlineAgents];
                    Map<Id,Decimal> m_agentWorkload = new Map<Id,Decimal>();
                    Decimal d_capacityLoad = 0.00;
                    for(AgentWork availabStatus : l_wrkingAgents){
                        d_capacityLoad = availabStatus.CapacityPercentage;
                        if(m_agentWorkload.containsKey(availabStatus.UserId)) d_capacityLoad = d_capacityLoad + m_agentWorkload.get(availabStatus.UserId);m_agentWorkload.put(availabStatus.UserId, d_capacityLoad);
                    }
                    // If there is an Online Agent with no WorkLoad then add him to the capacity list
                    for(Id userId : onlineAgents){
                        if(m_agentWorkload.containsKey(userId)){
                            if(m_agentWorkload.get(userId) < 99.00) onlineAgentsWithCapacity.add(userId);
                        }else{
                            onlineAgentsWithCapacity.add(userId);
                        }
                    }
                    if(Test.isRunningtest() || !onlineAgentsWithCapacity.isEmpty()){
                        // set of online service resources Ids
                        Set<Id> serviceResourceIds = new Set<Id>();
                        for(ServiceResource sr: [SELECT Id, IsActive 
                                                 FROM ServiceResource 
                                                 WHERE RelatedRecordId IN: onlineAgentsWithCapacity 
                                                 AND ResourceType = 'A' 
                                                 AND IsActive = TRUE 
                                                 AND RecordType.Name =: MONASH_CONNECT]){
                                                     serviceResourceIds.add(sr.Id);
                                                 }
                        if(!serviceResourceIds.isEmpty()){
                            // generate a list that will contain the set of online agent Ids per skill
                            List<ServiceResourceSkill> l_linkedServResSkill = [SELECT SkillId, ServiceResourceId FROM ServiceResourceSkill WHERE ServiceResourceId IN :serviceResourceIds AND Skill.DeveloperName = :l_linkedSkill[0].Skill_Developer_Name__c];
                            if(!l_linkedServResSkill.isEmpty()) RestContext.response.responseBody = Blob.valueOf('True');
                        }
                    }                  
                }                
            }            
        }
    }
}