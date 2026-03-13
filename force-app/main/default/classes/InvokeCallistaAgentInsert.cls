/*******************************************************************************
* @author:		K Liew
* @date:		15.August.2018
* @description:	Apex code exposing MiX Agent integration capabilities to calling
*				PB / Flow
* @revision:
*				15.AUG.2018 KL  >   Initial class creation.
*               18.DEC.2019 KL  >   Introducing logic to completely bypass AM
*                                   integration right at the tip of the chain.
*******************************************************************************/

public class InvokeCallistaAgentInsert {

    @InvocableMethod(label='Insert Agent in Callista' description='Method used to consume MiX API to create Agent(s) in Callista')
    public static void createAgentInCallista (List<Id> syncedAccountIDs) {
        
        try {

            Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();
            if (amSetting.Callista_Integration_Enabled__c) {
                // get list of contacts to process.
                List<Contact> listOfRoleAccountContacts = 
                    [SELECT
                    Id,
                    Account.Callista_Org_Unit_Code__c
                    FROM Contact
                    WHERE AccountId in :syncedAccountIDs
                    AND Role_Account_Flag__c = true
                    ];
                
                // loop through, for each perform callout
                for (Contact contactInLoop : listOfRoleAccountContacts) {
                    
                    AgentCreateInterface intfCall = new AgentCreateInterface(contactInLoop.Id, contactInLoop.Account.Callista_Org_Unit_Code__c);
                    Id jobId = System.enqueueJob(intfCall); // doubt there's use for the Job Id for now, keep for future use if need.
                    System.debug('!@#$% Inside InvokeCallistaAgentInsert\'s createAgentInCallista method, JobId is: ' + jobId);
                }
            }
            
        } catch (Exception ex) {
            System.debug('Class: InvokeCallistaAgentInsert, Method: createAgentInCallista, Message: ' + ex.getMessage());
            ExLog.add('InvokeCallistaAgentInsert','Account / Agent Management Integration','createAgentInCallista', ex);
        }
        
    }
    
}