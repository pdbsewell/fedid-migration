/**
 * @description       : Handler class for FundingTrigger.
 * @author            : Angelo Rivera
 * @group             : Engage Enterprise
 * @version           : Modifications Log
 * Ver   Date           Author              Modification
 * 1.0   04-10-2023     Angelo Rivera       Initial Creation
**/

public with sharing class FundingTriggerHandler {


    /**
     * @Update the UID on Funding when created or updated
     */
    public class SeFundingUniqueId extends TriggerAbstract {

        Id enterpriseRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enterprise').getRecordTypeId();
        Set<Id> s_opportunityIds = new Set<Id>();

        public Boolean b_executeTriggerLogic {
            get {
                if(b_executeTriggerLogic == null){
                    // Do not execute the trigger logic if the Transaction is initiated by a PURE User
                    b_executeTriggerLogic = true;
                    Profile userProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
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
         * On insert */
        public override void process(SObject record) {
            if(((Funding__c)record).Funder__c != null) {
                records.add(record);
                s_opportunityIds.add(((Funding__c)record).Opportunity__c);
            }
        }

        public override void execute() {

            try{
                if(b_executeTriggerLogic){
                    Set<Id> s_entrpOpportunityIds = new Set<Id>();
                    for(Opportunity enterpOpp : [SELECT Id FROM Opportunity WHERE Id IN :s_opportunityIds AND RecordTypeId = :enterpriseRecordTypeId]){
                        s_entrpOpportunityIds.add(enterpOpp.Id);
                    }
                    if(!s_entrpOpportunityIds.isEmpty()){
                        Funding__c funder;
                        for(sObject loopRecord : records) {
                            funder = (Funding__c)loopRecord;
                            if(s_entrpOpportunityIds.contains(funder.Opportunity__c)){
                                if(String.isNotBlank(funder.Funder__c)){
                                    funder.UID__c = String.valueOf(funder.Opportunity__c) + String.valueOf(funder.Funder__c) + String.valueOf(funder.Funding_Type__c) + String.valueOf(funder.Primary_Funder__c);
                                }
                            }
                        }
                    }
                }
            }catch(Exception err){
                LogUtilityException.logException(err, records);
            }
        }
    }
}