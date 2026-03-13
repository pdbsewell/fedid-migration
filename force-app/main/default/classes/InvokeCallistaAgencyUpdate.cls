/*******************************************************************************
* @author:		K Liew
* @date:		17.August.2018
* @description:	Apex code exposing MiX integration capabilities to calling Flow.
*
* @revision:
*				17.August.2018 KL > Initial class creation.
*******************************************************************************/

public class InvokeCallistaAgencyUpdate {
    
    @InvocableMethod(label='Update Agency in Callista' description='Method used to consume MiX APIs to update Agency / Agencies in Callista')
    public static void updateAgencyInCallista (List<Id> updatedRoleAccountIDs) {
        
        try {

            System.debug('!@#$% Inside InvokeCallistaAgencyUpdate\'s updateAgencyInCallista method...');
            Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();
            if (amSetting.Callista_Integration_Enabled__c) {
                for (Id agencyIdInLoop : updatedRoleAccountIDs) {
                    
                    AgencyUpdateInterface agencyInterfaceCall = new AgencyUpdateInterface(agencyIdInLoop);
                    Id jobId = System.enqueueJob(agencyInterfaceCall);
                    System.debug('!@#$% Inside InvokeCallistaAgencyUpdate\'s updateAgencyInCallista method, JobId is: ' + jobId);
                    
                }
            }            
            
        } catch (Exception ex) {
            
            System.debug('Class: InvokeCallistaAgencyUpdate, Method: updateAgencyInCallista, Message: ' + ex.getMessage());
            ExLog.add('InvokeCallistaAgencyUpdate','Account / Agent Management Integration','updateAgencyInCallista', ex);
            
        }
        
    }
    
}