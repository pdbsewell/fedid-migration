/**
 * @author          Inderpal Dhanoa
 * @description     Trigger class specific to Contact Team sObject
 * @revision
 * 03/02/2022 - Inderpal Dhanoa - Added method to sync PRM Members (ENGAGEIE-1259)
 */
public with sharing class ContactTeamTriggerHandler {

    /**
	 * Populate Unique Field by combining Contact and User
	 * 
	 * @author Inderpal Dhanoa - idha0002
	 */
	/*******************************************************************************
	* @description 	PopulateUnique Field for before Update and before Insert.
	*******************************************************************************/
    public class PopulateUniqueField extends TriggerAbstract {
        List<ContactTeam__c> l_impactedRecords = new List<ContactTeam__c>();
        
        public override void process(SObject record) {
            // before insert logic here
            ContactTeam__c newContTeam = (ContactTeam__c)record;
            l_impactedRecords.add(newContTeam);            
        }

        public override void process(SObject record, SObject oldRec) {
            // before update logic here
            ContactTeam__c newContTeam = (ContactTeam__c)record;
            l_impactedRecords.add(newContTeam);
        }

        public override void execute(){
            if(!l_impactedRecords.isEmpty()){
                for(ContactTeam__c contTeam : l_impactedRecords){
                    // Contact Team's is updated
                    contTeam.UniqueID__c =  String.valueOf(contTeam.Contact__c) + String.valueOf(contTeam.Team_Member__c);   
                }
            }
        }
    }
}