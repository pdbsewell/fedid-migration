/*******************************************************************************
* @author:		K Liew
* @date:		16.AUG.2018
* @description:	Apex code exposing Google App's Agency / Agent integration
*				capabilities to calling PB / Flow.
* @revision:
*				16.AUG.2018 KL  >   Initial class creation.
*               18.DEC.2019 KL  >   Introducing logic to completely bypass AM
*                                   integration right at the tip of the chain.
*******************************************************************************/

public class InvokeAgentPortalAgentInsert {

    @InvocableMethod(label='Insert Agency & Agent in Google Apps Agent Portal' description='Method used to consume Google App\'s API to create Agent(s) in Agent Portal')
    public static void createAgencyAndAgentInAgentPortal (List<Id> syncedContactIDs) {

        System.debug('!@#$% Inside InvokeAgentPortalAgentInsert\'s createAgencyAndAgentInAgentPortal method...');

        try {

            Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();
            if (amSetting.Callista_Integration_Enabled__c) {
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
                    AgentPortalCreateAgentInterface intfCall = new AgentPortalCreateAgentInterface(contactInLoop.Id);
                    Id jobId = System.enqueueJob(intfCall);
                    System.debug('!@#$% Inside InvokeAgentPortalAgentInsert\'s createAgencyAndAgentInAgentPortal method, JobId is: ' + jobId);
                }
            }
            
        } catch (Exception ex) {

            System.debug('Class: InvokeAgentPortalAgentInsert, Method: createAgencyAndAgentInAgentPortal, Message: ' + ex.getMessage());
            ExLog.add('InvokeAgentPortalAgentInsert','Account / Agent Management Integration','createAgencyAndAgentInAgentPortal', ex);
            
        }
    }
}