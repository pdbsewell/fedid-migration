/*
 * @File Name          : OpportunityFoRTriggerHandler.cls
 * @Description        : Trigger Handler for the Opportunity FoR Object DML transactions
 * @Author             : Inderpal Dhanoa
 * @Group              : Enterprise
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0      18/05/2022      Inderpal Dhanoa         Initial Version
 * 
**/
public with sharing class OpportunityFoRTriggerHandler {
    
    /**
     * @Update the UID on Opportunity FoR when FoR's are created, updated
     */
    public class setupUID extends TriggerAbstract {
        List<Opportunity_FoR__c> l_impactedrecords = new List<Opportunity_FoR__c>();
        public override void process(SObject record) {  
            // before and or after update logic here
            Opportunity_FoR__c newOpportunityFoR = (Opportunity_FoR__c)record;
            l_impactedrecords.add(newOpportunityFoR);
        }

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity_FoR__c newOpportunityFoR = (Opportunity_FoR__c)record;
            Opportunity_FoR__c oldOpportunityFoR = (Opportunity_FoR__c)oldRec;
            if(newOpportunityFoR.Fields_of_Research__c != oldOpportunityFoR.Fields_of_Research__c || newOpportunityFoR.Opportunity__c != oldOpportunityFoR.Opportunity__c){  
                l_impactedrecords.add(newOpportunityFoR);
            }
        }

        public override void execute() { 
            // Iterate through the records (Incoming & Existing) and populate the UID
            for(Opportunity_FoR__c newOppFoR : l_impactedrecords){
                newOppFoR.UID__c = String.Valueof(newOppFoR.Fields_of_Research__c) + String.Valueof(newOppFoR.Opportunity__c);
            }
        }
    }

    /**
     * @Validate the Percentage on Opportunity FoR when FoR's are created, updated
     */
    public class ValidateOwnership extends TriggerAbstract {

        Map<Id, List<Opportunity_FoR__c>> m_opptyLinkedFoRRecords = new Map<Id, List<Opportunity_FoR__c>>();
        Set<Id> s_opptyId = new Set<Id>();
        Set<Id> s_existingFoRIds = new Set<Id>();
        List<Opportunity_FoR__c> l_impactedrecords = new List<Opportunity_FoR__c>(); 

        public override void process(SObject record) {  
            // before and or after update logic here
            Opportunity_FoR__c newOpportunityFoR = (Opportunity_FoR__c)record;
            if(String.isNotBlank(String.valueof(newOpportunityFoR.Percentage__c))){    
                m_opptyLinkedFoRRecords = linkToMap(m_opptyLinkedFoRRecords, newOpportunityFoR);
                s_opptyId.add(newOpportunityFoR.Opportunity__c);
                l_impactedrecords.add(newOpportunityFoR);
            }
        }

        public override void process(SObject record, SObject oldRec) {
            // before and or after update logic here
            Opportunity_FoR__c newOpportunityFoR = (Opportunity_FoR__c)record;
            Opportunity_FoR__c oldOpportunityFoR = (Opportunity_FoR__c)oldRec;
            if(String.isNotBlank(String.valueof(newOpportunityFoR.Percentage__c)) && newOpportunityFoR.Percentage__c != oldOpportunityFoR.Percentage__c){ 
                m_opptyLinkedFoRRecords = linkToMap(m_opptyLinkedFoRRecords, newOpportunityFoR);
                s_opptyId.add(newOpportunityFoR.Opportunity__c);
                s_existingFoRIds.add(newOpportunityFoR.Id);
                l_impactedrecords.add(newOpportunityFoR);
            }
        }

        public override void execute() {
            if(!s_opptyId.isEmpty()){
                for(Opportunity_FoR__c existOppFoR : [SELECT Id, Percentage__c, Opportunity__c 
                                                        FROM Opportunity_FoR__c 
                                                        WHERE ID NOT IN :s_existingFoRIds 
                                                        AND Opportunity__c IN :s_opptyId]){
                    m_opptyLinkedFoRRecords = linkToMap(m_opptyLinkedFoRRecords, existOppFoR);
                }
                // Iterate through the records (Incoming & Existing) and check if the total pern is exceeding 100
                for(Opportunity_FoR__c newOppFoR : l_impactedrecords){
                    if(m_opptyLinkedFoRRecords.containsKey(newOppFoR.Opportunity__c) && checkTotalPercentage(m_opptyLinkedFoRRecords, newOppFoR.Opportunity__c)){
                        newOppFoR.addError(System.Label.ResearchCollaboratorsExceeded);
                    }
                }
            }
        }

		/*
		 * Method Name: checkTotalPercentage
		 * @param  records for Oppty Id and List of releted Oppty FoR records
		 * @param  Id of Oppty For Record in the Trigger
		 * Description: method to check if the sum of total percentage exceed 100
		*/
        public Boolean checkTotalPercentage(Map<Id, List<Opportunity_FoR__c>> m_opptyLinkedFoRRecords, Id linkedOpptyId){
            Decimal d_totalPercentage = 0;
            for(Opportunity_FoR__c linkedOpptyFoR : m_opptyLinkedFoRRecords.get(linkedOpptyId)){
                d_totalPercentage = d_totalPercentage + linkedOpptyFoR.Percentage__c;
                if(d_totalPercentage > 100){
                    return true;
                }
            }
            return false;
        }

		/*
		 * Method Name: linkToMap
		 * @param  records for Oppty Id and List of releted Oppty FoR records
		 * @param  related Oppty For Record in the Trigger
		 * Description: method to link the Oppty with related FoR
		*/
        public Map<Id, List<Opportunity_FoR__c>> linkToMap(Map<Id, List<Opportunity_FoR__c>> m_opptyLinkedFoRRecords, Opportunity_FoR__c newOpportunityFoR){
            List<Opportunity_FoR__c> l_relatedFoRs = m_opptyLinkedFoRRecords.get(newOpportunityFoR.Opportunity__c);  
            if(l_relatedFoRs != null && !l_relatedFoRs.isEmpty()){
                l_relatedFoRs.add(newOpportunityFoR);
            }else{
                l_relatedFoRs = new List<Opportunity_FoR__c>();
                l_relatedFoRs.add(newOpportunityFoR);
            }
            m_opptyLinkedFoRRecords.put(newOpportunityFoR.Opportunity__c, l_relatedFoRs);
            return m_opptyLinkedFoRRecords;
        }
    }
}