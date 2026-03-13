/*************************************************************************
 * @author      Ajitabh Jha
 * @description Trigger handler for Faculty_Proposal_Breakdown
 * @created 19-07-2019 
 * @last modified by  : Inderpal Dhanoa idha0002
 * Modifications Log 
 * Ver   Date         Author          	Modification
 * 1.1   07-06-2022   Inderpal Dhanoa   ENGAGEIE-1413 Update Related Faculties 
 * 1.0   19-07-2019   Ajitabh Jha       Initial Version
 * 
 * @test Class name is : EngageFacultyProposalBreakdownTest
 ***********************************************************************/
public with sharing class FacultyProposalBreakdownService {
    public FacultyProposalBreakdownService() {
        
    }

    public class UpdateFaculties implements Triggers.Handler {
        List<Faculty_Proposal_Breakdown__c> facultyProposalBreakdownsToOperateOn = new List<Faculty_Proposal_Breakdown__c>();
        List<Id> proposalIds = new List<Id>();

        public void run() {
            //If the event is insert or undelete, this list takes New Values or else it takes old values
            facultyProposalBreakdownsToOperateOn = (Trigger.isInsert|| Trigger.isUnDelete) ? Trigger.new : Trigger.old;

            updateFaculties();
        }

        /*******************************************************************************
        * @description  Store all FPB Child Records as a String of values in Text Area Field i.e Faculties__c on Opportunity
        *******************************************************************************/
        private void updateFaculties() {
            for (Faculty_Proposal_Breakdown__c fpb : facultyProposalBreakdownsToOperateOn) {
                proposalIds.add(fpb.Proposal__c);
            }

            //Get all FCB related to an opportunity
            //Order by Faculty so concatenated value of multiple faculties is in alphabetical order
            List<Opportunity> proposalList =    [SELECT Id,
                                                    (SELECT Id, Name, Proposal__r.Name, Faculty__c 
                                                    FROM Faculty_Proposal_Breakdown__r 
                                                    ORDER BY Faculty__c) 
                                                FROM Opportunity
                                                WHERE Id IN :proposalIds];

            //Loop through the List and store the Child Records as a String of values in Text Area Field i.e Faculties__c
            for (Opportunity proposal : proposalList) {

                if(proposal.Faculty_Proposal_Breakdown__r.size() > 0) {
                    proposal.Related_Faculties__c = string.valueOf(proposal.Faculty_Proposal_Breakdown__r[0].Faculty__c);

                    for(Integer fcbIndex = 1; fcbIndex < proposal.Faculty_Proposal_Breakdown__r.size(); fcbIndex++) {
                        proposal.Related_Faculties__c = proposal.Related_Faculties__c + ';' + String.valueOf(proposal.Faculty_Proposal_Breakdown__r[fcbIndex].Faculty__c);
                    }
                } else {
                    proposal.Related_Faculties__c = null;
                }
            }

            update proposalList;
        }
    }



}