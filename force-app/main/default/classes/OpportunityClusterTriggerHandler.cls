/*
 * @File Name          : OpportunityTriggerHandler.cls
 * @Description        : Service layer containing most business logic for opportunity object 
 * @Author             : Inderpal Dhanoa
 * @Group              : Enterprise
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    08/09/2021   Inderpal Dhanoa     Initial Version of the class
 * 1.1    08/09/2021   Inderpal Dhanoa     Modifying for ENGAGEIE - 1406 Update AWARD ID
 * 
**/
public with sharing class OpportunityClusterTriggerHandler {
    /**
	 * Sync Method to provide Opportunity Support
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	Sync VisibilityCategory with IsPrivate for before Update.
	*******************************************************************************/
    public class SyncPureIdWithOpportunity extends TriggerAbstract {
        List<Opportunity_Cluster__c> l_impactedRecords = new List<Opportunity_Cluster__c>();
        Set<Id> s_impactedRecordIds = new Set<Id>();

        public override void process(SObject record) {
            // before and or after update logic here
            Opportunity_Cluster__c newOpptyCluster = (Opportunity_Cluster__c)record;
            s_impactedRecordIds.add(newOpptyCluster.Id);
            l_impactedRecords.add(newOpptyCluster);
        }

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity_Cluster__c newOpptyCluster = (Opportunity_Cluster__c)record;
            Opportunity_Cluster__c oldOpptyCluster = (Opportunity_Cluster__c)oldRec;
            if(newOpptyCluster.PURE_Application_ID__c != oldOpptyCluster.PURE_Application_ID__c || newOpptyCluster.PURE_Award_ID__c != oldOpptyCluster.PURE_Award_ID__c){ 
                s_impactedRecordIds.add(newOpptyCluster.Id);
                l_impactedRecords.add(newOpptyCluster);
            }
        }

        public override void execute(){
            // Get linked Oppty
            if(!s_impactedRecordIds.isEmpty()){
                Map<Id,List<Opportunity>> m_clusterIdLinkedOppty = linkOppWithCluster(s_impactedRecordIds);
                List<Opportunity> l_opptyRecordsToSyncPureId = new List<Opportunity>();
                // Sync Oppty for PURE ID
                for(Opportunity_Cluster__c opptyCluster : l_impactedRecords){
                    // Opportunity's is updated
                    if(m_clusterIdLinkedOppty != null && m_clusterIdLinkedOppty.containsKey(opptyCluster.Id)){
                        for(Opportunity linkedOppty :  m_clusterIdLinkedOppty.get(opptyCluster.Id)){
                            linkedOppty.PURE_Application_ID__c =  opptyCluster.PURE_Application_ID__c;
                            linkedOppty.PURE_Award_ID__c =  opptyCluster.PURE_Award_ID__c;
                            l_opptyRecordsToSyncPureId.add(linkedOppty);
                        } 
                    }    
                }
                if(!l_opptyRecordsToSyncPureId.isEmpty()){
                    try{
                        update l_opptyRecordsToSyncPureId;
                    }catch (Exception e) {
                        LogUtilityException.logException(e,'OpportunityClusterTriggerHandler SyncPureIdWithOpportunity');
                    }
                }
            }
        }


        public Map<Id,List<Opportunity>> linkOppWithCluster(Set<Id> s_impactedRecordIds){
            Map<Id,List<Opportunity>> m_clusterIdLinkedOppty = new Map<Id,List<Opportunity>>();
            for(Opportunity oppty : [SELECT Id, Opportunity_Cluster__c, PURE_Application_ID__c FROM Opportunity WHERE Opportunity_Cluster__c in :s_impactedRecordIds]){
                List<Opportunity> linkedOppty;
                if(m_clusterIdLinkedOppty.containsKey(oppty.Opportunity_Cluster__c)){
                    linkedOppty = m_clusterIdLinkedOppty.get(oppty.Opportunity_Cluster__c);    
                }else{
                    linkedOppty = new List<Opportunity>(); 
                }
                linkedOppty.add(oppty);
                m_clusterIdLinkedOppty.put(oppty.Opportunity_Cluster__c, linkedOppty);
            }
            return m_clusterIdLinkedOppty;
        }
    }
}