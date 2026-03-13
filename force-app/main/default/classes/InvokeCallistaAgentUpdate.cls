/*******************************************************************************
* @author:		K Liew
* @date:		17.August.2018
* @description:	Apex code exposing MiX integration capabilities to calling Flow.
*
* @revision:
*				17.August.2018 KL > Initial class creation.
*******************************************************************************/

public class InvokeCallistaAgentUpdate {

    @InvocableMethod(label='Update Agent in Callista' description='Method used to consume MiX API to update Agent(s) in Callista')
    public static void updateAgentInCallista (List<Id> updatedContactIDs) {
        
        try {
            
            System.debug('!@#$% Inside InvokeCallistaAgentUpdate\'s updateAgentInCallista method...');
            Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();
            if (amSetting.Callista_Integration_Enabled__c) {
                // loop through, for each perform callout
                for (Id contactIdInLoop : updatedContactIDs) {
                    AgentUpdateInterface intfCall = new AgentUpdateInterface(contactIdInLoop);
                    Id jobId = System.enqueueJob(intfCall);
                    System.debug('!@#$% Inside InvokeCallistaAgentUpdate\'s updateAgentInCallista method, JobId is: ' + jobId);
                }
            }            
            
        } catch (Exception ex) {
            System.debug('Class: InvokeCallistaAgentUpdate, Method: updateAgentInCallista, Message: ' + ex.getMessage());
            ExLog.add('InvokeCallistaAgentUpdate','Account / Agent Management Integration','updateAgentInCallista', ex);
        }
        
    }

}