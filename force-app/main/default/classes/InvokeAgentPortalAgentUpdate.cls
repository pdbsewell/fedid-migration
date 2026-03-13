/*******************************************************************************
* @author:		K Liew
* @date:		19.August.2018
* @description:	Apex code exposing Google App's Agency / Agent integration
*				capabilities to calling PB / Flow.
* @revision:
*				19.August.2018 KL > Initial class creation.
*******************************************************************************/

public class InvokeAgentPortalAgentUpdate {

    @InvocableMethod(label='Update Agency & Agent in Google Apps Agent Portal' description='Method used to consume Google App\'s API to update Agent(s) in Agent Portal')
    public static void updateAgencyAndAgentInAgentPortal (List<Id> syncedContactIDs) {

        try {

            System.debug('!@#$% Inside InvokeAgentPortalAgentUpdate\'s updateAgencyAndAgentInAgentPortal method...');
            Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();
            if (amSetting.Google_AP_Integration_Enabled__c) {
                // get list of contacts to process.
                List<Contact> listOfRoleAccountContacts = 
                    [SELECT
                    Id,
                    Account.Callista_Org_Unit_Code__c
                    FROM Contact
                    WHERE Id in :syncedContactIDs
                    AND Role_Account_Flag__c = true
                    ];
                
                // loop through, for each perform callout
                for (Contact contactInLoop : listOfRoleAccountContacts) {
                    AgentPortalUpdateAgentInterface intfCall = new AgentPortalUpdateAgentInterface(contactInLoop.Id);
                    Id jobId = System.enqueueJob(intfCall);
                    System.debug('!@#$% Inside InvokeAgentPortalAgentUpdate\'s updateAgencyAndAgentInAgentPortal method, JobId is: ' + jobId);
                }
            }
            
        } catch (Exception ex) {

            System.debug('Class: InvokeAgentPortalAgentUpdate, Method: updateAgencyAndAgentInAgentPortal, Message: ' + ex.getMessage());
            ExLog.add('InvokeAgentPortalAgentUpdate','Account / Agent Management Integration','updateAgencyAndAgentInAgentPortal', ex);
            
        }
    }
}