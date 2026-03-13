/*************************************************************************
 * @author      Inderpal Dhanoa
 * @description Trigger handler for Opportunity Collaborator
 * @created 16-03-2021 
 * @last modified by  : Inderpal Dhanoa idha0002
 * Modifications Log 
 * Ver   Date         Author          	Modification
 * 1.5   07-03-2024   Davey Yu          ENGAGEIE-1908 Set Related Faculties based on Monash Faculty Area Name
 * 1.4   08-11-2023   Davey Yu   		ENGAGEIE-1812 Set Opportunity Collaborator Lead
 * 1.3   07-06-2022   Inderpal Dhanoa   ENGAGEIE-1413 Update Related Faculties 
 * 1.2   15-03-2022   Inderpal Dhanoa   ENGAGEIE-1371 Remove Set Unique ID 
 * 1.1   04-03-2022   Inderpal Dhanoa   ENGAGEIE-1303 Set Unique ID
 * 1.0   16-03-2021   Inderpal Dhanoa   Initial Version
 * 
 * @test Class name is : OpportunityCollabTriggerHandler_Test
 ***********************************************************************/
public class OpportunityCollaboratorTriggerHandler {
        /**
     * @Update the Faculties on Opportunity when Internal Collaborators are created, updated or Deleted
     */
    public class UpdateOpportunityFaculties extends TriggerAbstract {

        List<Opportunity> l_opportunityList = new List<Opportunity>();
        Set<Id> st_opportunityIds = new Set<Id>();

        /**
         * On After insert */
        public override void process(SObject record) {
            if(((Opportunity_Collaborator__c)record).Organisation__c != null && ((Opportunity_Collaborator__c)record).Relationship_Type__c == 'Internal Organisation') {
                st_opportunityIds.add(((Opportunity_Collaborator__c)record).Opportunity__c);
            }
        } 

        /**
         * On After update, find the records and update the concatenate the Faculties name 
         */
        public override void process(SObject record, SObject oldRecord){
            if(CommonUtilities.fieldHasChanged('Organisation__c', ((Opportunity_Collaborator__c)record), ((Opportunity_Collaborator__c)oldRecord)) 
                && ((Opportunity_Collaborator__c)record).Relationship_Type__c == 'Internal Organisation'){
                st_opportunityIds.add(((Opportunity_Collaborator__c)record).Opportunity__c);
            }
        }

        public override void execute() {
            try{
                Map<Id,String> mp_opportunityFaculty = new Map<Id,String>();
                for(Opportunity_Collaborator__c newUpdatedCollaborator : [SELECT Id, Opportunity__c, Organisation__r.Name, Organisation__r.Monash_Faculty_Area_Name__c FROM Opportunity_Collaborator__c WHERE Opportunity__c IN: st_opportunityIds AND Relationship_Type__c = 'Internal Organisation']){
                    if(mp_opportunityFaculty.containsKey(newUpdatedCollaborator.Opportunity__c)){
                        String faculties = mp_opportunityFaculty.get(newUpdatedCollaborator.Opportunity__c);
                        faculties = faculties + ';' + newUpdatedCollaborator.Organisation__r.Monash_Faculty_Area_Name__c;
                        mp_opportunityFaculty.put(newUpdatedCollaborator.Opportunity__c, faculties);
                    }else{
                        mp_opportunityFaculty.put(newUpdatedCollaborator.Opportunity__c, newUpdatedCollaborator.Organisation__r.Monash_Faculty_Area_Name__c);
                    }
                }
                if(!mp_opportunityFaculty.isEmpty()) {
                    for(Id opportunityId : mp_opportunityFaculty.keySet()){
                        Opportunity newUpdateOpportunity = new Opportunity();
                        newUpdateOpportunity.Id = opportunityId;
                        newUpdateOpportunity.Related_Faculties__c = mp_opportunityFaculty.get(opportunityId);  
                        l_opportunityList.add(newUpdateOpportunity);
                    }
                    if(!l_opportunityList.isEmpty()) {
                        update l_opportunityList;
                    }                
                }

            }catch(Exception err){
                //LogUtilityException.logException(err, st_opportunityIds);
                Nebula.logger.error(err.getMessage(), l_opportunityList);
                Nebula.logger.saveLog();
            }
        }
    }
    
    /**
     * @description Set the Opportunity Collaborator Lead Field to True
     * @param       N/A
     * @return      N/A
     * @revision    08-11-2023     Davey Yu       Initial Creation
     */
    public class SetLeadCollaborator extends TriggerAbstract {
    	Id enterpriseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(); 
        Set<Id> s_opportunityIds = new Set<Id>();
        //after insert
        public override void process(SObject record) {
            if(((Opportunity_Collaborator__c)record).Relationship_Type__c == System.label.Opportunity_Collaborator_Internal_Organisation
              && !((Opportunity_Collaborator__c)record).Lead__c) {
                records.add(record);
                s_opportunityIds.add(((Opportunity_Collaborator__c)record).Opportunity__c);
            }
        } 
		    
    	public override void execute() {
            try{
                Set<Id> s_entrpOpportunityIds = new Set<Id>();
                for(Opportunity enterpOpp : [SELECT Id, Lead_Collaborator__c FROM Opportunity WHERE Id in :s_opportunityIds AND RecordTypeId = :enterpriseRecordTypeId
                                             AND Lead_Collaborator__c =: System.label.Opportunity_Lead_Collaborator_Monash_Led]){
                                                 s_entrpOpportunityIds.add(enterpOpp.Id);
                                             }
                if(!s_entrpOpportunityIds.isEmpty()){
                    Opportunity_Collaborator__c collab;
                    for(sObject loopRecord : records) {
                        collab = (Opportunity_Collaborator__c)loopRecord;
                        if(s_entrpOpportunityIds.contains(collab.Opportunity__c)){
                            if(!collab.Lead__c){
                                collab.Lead__c = true;
                            }
                            
                        }                            
                    }
                }                    
                
            }catch(Exception err){
                //LogUtilityException.logException(err, records);
                Nebula.logger.error(err.getMessage(), records);
                Nebula.logger.saveLog();
            }
        }
    }
	
	/**
     * @Update the UID on Opportunity Collab when Collaborators are created, updated
     */
    public class SetOpportunityCollaboratorUniqueId extends TriggerAbstract {

        Id enterpriseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId(); 
        Set<Id> s_opportunityIds = new Set<Id>();

        public Boolean b_executeTriggerLogic {
            get {
                if(b_executeTriggerLogic == null){ 
                    // Do not execute the trigger logic if the Transaction is initiated by a PURE User
                    b_executeTriggerLogic = true; 
                    Profile userProfile = [Select Name from Profile where Id =: userinfo.getProfileId()];
                    if(userProfile !=null && userProfile.Name == String.valueOf(Label.Mix_Pure_Enterprise_User_Profile)){
                        b_executeTriggerLogic = false;
                        return b_executeTriggerLogic;
                    }
                    return b_executeTriggerLogic;
                } 
                return b_executeTriggerLogic;               
            }
            private set;
        }        

        /**
         * On After insert */
        public override void process(SObject record) {
            if(((Opportunity_Collaborator__c)record).Organisation__c != null) {
                records.add(record);
                s_opportunityIds.add(((Opportunity_Collaborator__c)record).Opportunity__c);
            }
        } 

        /**
         * On After update, find the records and update the UID 
         */
        public override void process(SObject record, SObject oldRecord){
            if(((Opportunity_Collaborator__c)record).Organisation__c != ((Opportunity_Collaborator__c)oldRecord).Organisation__c ||
                ((Opportunity_Collaborator__c)record).Opportunity__c != ((Opportunity_Collaborator__c)oldRecord).Opportunity__c) {
                    records.add(record);
                    s_opportunityIds.add(((Opportunity_Collaborator__c)record).Opportunity__c);
            }
        }

        public override void execute() {
            
            try{
                if(b_executeTriggerLogic){
                    Set<Id> s_entrpOpportunityIds = new Set<Id>();
                    for(Opportunity enterpOpp : [SELECT Id FROM Opportunity WHERE Id in :s_opportunityIds AND RecordTypeId = :enterpriseRecordTypeId]){
                        s_entrpOpportunityIds.add(enterpOpp.Id);
                    }
                    if(!s_entrpOpportunityIds.isEmpty()){
                        Opportunity_Collaborator__c collab;
                        for(sObject loopRecord : records) {
                            collab = (Opportunity_Collaborator__c)loopRecord;
                            if(s_entrpOpportunityIds.contains(collab.Opportunity__c)){
                                if(String.isNotBlank(collab.Organisation__c)){
                                    collab.UID__c = String.valueOf(collab.Opportunity__c) + String.valueOf(collab.Organisation__c);
                                }else{
                                    collab.UID__c = '';
                                }
                            }                            
                        }
                    }                    
                }    
            }catch(Exception err){
                //LogUtilityException.logException(err, records);
                Nebula.logger.error(err.getMessage(), records);
                Nebula.logger.saveLog();
            }
        }
    }

    public class DeleteOpportunityFaculties extends TriggerAbstract {

        List<Opportunity> l_opportunityList = new List<Opportunity>();
        Set<Id> st_deletedCollaboratorIds = new Set<Id>();

        /**
         * On Before Delete */
        public override void process(SObject record) {
            if(((Opportunity_Collaborator__c)record).Organisation__c != null && ((Opportunity_Collaborator__c)record).Relationship_Type__c == 'Internal Organisation') {
                st_deletedCollaboratorIds.add(((Opportunity_Collaborator__c)record).Id);
            }
        } 

        public override void execute() {
            try{
                Map<Id,String> mp_opportunityFaculty = new Map<Id,String>();
                for(Opportunity_Collaborator__c deletedCollaborator : [SELECT Id, Opportunity__c, Opportunity__r.Related_Faculties__c, Organisation__r.Name, Organisation__r.Monash_Faculty_Area_Name__c FROM Opportunity_Collaborator__c WHERE Id IN: st_deletedCollaboratorIds]){
                    String updatedFaculty = '';
                    if(deletedCollaborator.Opportunity__r.Related_Faculties__c.contains(';')){
                        List<String> l_AllFaculties = deletedCollaborator.Opportunity__r.Related_Faculties__c.split(';');
                        for(Integer i = 0; i < l_AllFaculties.size(); i++){
                            if(l_AllFaculties[i] == deletedCollaborator.Organisation__r.Monash_Faculty_Area_Name__c){
                                l_AllFaculties.remove(i);
                                break;
                            }
                        }
                        updatedFaculty = string.join(l_AllFaculties,';');
                    }
                    Opportunity newUpdateOpportunity = new Opportunity();
                    newUpdateOpportunity.Id = deletedCollaborator.Opportunity__c; 
                    newUpdateOpportunity.Related_Faculties__c = updatedFaculty;  
                    l_opportunityList.add(newUpdateOpportunity);
                } 
                if(!l_opportunityList.isEmpty()) {
                    update l_opportunityList;
                }

            }catch(Exception err){
                //LogUtilityException.logException(err, st_deletedCollaboratorIds);
                Nebula.logger.error(err.getMessage(), l_opportunityList);
                Nebula.logger.saveLog();
            } 
        }
    }
}