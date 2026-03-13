/**
 * @description       : Trigger Handler to manage all DML on ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c
 * @author            : Inderpal Dhanoa
 * @group             : Engage Enterprise 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   2021-10-18 - Inderpal Dhanoa -   Added a functionality to handle insert, Update and Delete for the Funders
**/
public without sharing class FundraiserContReportRelationHandler {

    /**
     * @author      Inderpal Dhanoa
     * @description Sync the task Linked to the COntact Report if new Funders are added, edited or removed
     * @revision    2021-10-18 - Inderpal Dhanoa - Created
     */
    public class SyncUpdateTasks extends TriggerAbstract {
        /**
        * Handle after insert event checking and filtering
        */
        public override void process(SObject record) {
            //Process all records
            records.add(record);
        }

        public override void process(SObject record, SObject oldRec) {
            //Process all records
            ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c fundRaiserContReportReln = (ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c)record;
            ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c oldFundRaiserContReportReln = (ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c)oldRec;
            if(fundRaiserContReportReln.ucinn_ascendv2__Fundraiser__c != oldFundRaiserContReportReln.ucinn_ascendv2__Fundraiser__c){
                records.add(record);
            }
        } 

        /**
        * Run functionality logic
        */
        public override void execute() {
            try{
				TaskServices.skipContactReportValidation = true; 
                Map<Id,List<ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c>> m_contReportFundraisers = new Map<Id,List<ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c>>();
                Set<Id> s_fundRaiserContReportReln = new Set<Id>();
                List<Id> s_fundraisers = new List<Id>();
                for(ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c fundRaiserContReportReln : (List<ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c>)records){
                    s_fundRaiserContReportReln.add(fundRaiserContReportReln.ucinn_ascendv2__Contact_Report__c);
                }
                // retrirve all the Funders linked to each Contact Report and create a new Line separated String
                for(ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c relFundRaiserContReportReln :[SELECT Id, ucinn_ascendv2__Contact_Report__c, ucinn_ascendv2__Fundraiser__r.Name,ucinn_ascendv2__Fundraiser__c 
                                                                                                        FROM ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c 
                                                                                                        WHERE ucinn_ascendv2__Contact_Report__c IN :s_fundRaiserContReportReln]){
                    List<ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c> relatedFunders;
                    if(m_contReportFundraisers.containsKey(relFundRaiserContReportReln.ucinn_ascendv2__Contact_Report__c)){
                        relatedFunders = m_contReportFundraisers.get(relFundRaiserContReportReln.ucinn_ascendv2__Contact_Report__c);
                    }else{
                        relatedFunders = new List<ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c>();   
                    }
                    relatedFunders.add(relFundRaiserContReportReln);
                    m_contReportFundraisers.put(relFundRaiserContReportReln.ucinn_ascendv2__Contact_Report__c, relatedFunders);                        
                }
                List<Task> l_relContReptasks = new List<Task>();
                // Update the Task Description and if owner is not a funder then update the Task Owner based on the First Funder
                if(!m_contReportFundraisers.isEmpty()){
                    for(Task relTask : [SELECT Id, OwnerId, Description, Contact_Report__c FROM TASK WHERE Contact_Report__c in :m_contReportFundraisers.keyset()]){
                        if(m_contReportFundraisers.containsKey(relTask.Contact_Report__c)){
                            String sDescription = '';
                            List<Id> s_fundRaisersForContReport = new List<Id>();
                            // Generate Description
                            for(ucinn_ascendv2__Fundraiser_Contact_Report_Relation__c relatedFunders : m_contReportFundraisers.get(relTask.Contact_Report__c)){
                                sDescription = sDescription + relatedFunders.ucinn_ascendv2__Fundraiser__r.Name + '\n';
                                s_fundRaisersForContReport.add(relatedFunders.ucinn_ascendv2__Fundraiser__c);
                            }
                            if(String.isNotBlank(sDescription)){
                                // Update the Description with the list of Funders, removing the extra \n at the end
                                relTask.Description = sDescription.substring(0,sDescription.length()-1);
                            }
                            // Update Owner is not a funder then update the Task Owner based on the First Funder
                            if(!s_fundRaisersForContReport.contains(relTask.OwnerId)){
                                relTask.OwnerId = s_fundRaisersForContReport[0];
                            }
                        }
                        l_relContReptasks.add(relTask);
                    }
                }
                // Delete Scenario where all the Funders have been deleted 
                if(trigger.isDelete && !s_fundRaiserContReportReln.isEmpty()){
                    Set<Id> s_contactRepWithNoFunders = new Set<Id>();
                    for(Id noFundersContRep : s_fundRaiserContReportReln){
                        if(!m_contReportFundraisers.containsKey(noFundersContRep)){
                            s_contactRepWithNoFunders.add(noFundersContRep);
                        }
                    }
                    if(!s_contactRepWithNoFunders.isEmpty()){
                        for(Task relTask : [SELECT Id, OwnerId, Description, Contact_Report__r.OwnerId FROM TASK WHERE Contact_Report__c in :s_contactRepWithNoFunders]){
                            relTask.Description = '';
                            relTask.OwnerId = relTask.Contact_Report__r.OwnerId;
                            l_relContReptasks.add(relTask);
                        }  
                    }
                }
                // Update the Task
                if(!l_relContReptasks.isEmpty()){ 
                    update l_relContReptasks;
                }
            } catch(Exception e) {
                LogUtilityException.logException(e);
            }
        }
    }
}