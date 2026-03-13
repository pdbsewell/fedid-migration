/*******************************************************************************
* @author:		K Liew
* @date:		30.July.2018
* @description:	Apex code exposing MiX integration capabilities to calling Flow.
*
* @revision:
*				30.JUL.2018 KL  >   Initial class creation.
*               18.DEC.2019 KL  >   Introducing logic to completely bypass AM
*                                   integration right at the tip of the chain.
*******************************************************************************/

public class InvokeCallistaAgencyInsert {

    @InvocableMethod(label='Insert Agency in Callista' description='Method used to consume MiX APIs to create Agency / Agencies in Callista')
    public static void createAgencyInCallista (List<Id> createdRoleAccountContactIDs) {
        
        try {
            Agent_Onboarding_Settings__c amSetting = Agent_Onboarding_Settings__c.getOrgDefaults();
            if (amSetting.Callista_Integration_Enabled__c) {
			
                List<Contact> createdRoleAccountContacts = [SELECT
                                                                Id,
                                                                AccountId,
                                                                Account.Callista_Org_Unit_Code__c
                                                            FROM Contact
                                                            WHERE Id in :createdRoleAccountContactIDs];
                
                for (Contact contactInLoop : createdRoleAccountContacts) {

                    AgencyCreateInterface agencyInterfaceCall = new AgencyCreateInterface(contactInLoop.AccountId);
                    Id jobId = System.enqueueJob(agencyInterfaceCall); // doubt there's use for the Job Id for now, keep for future use if need.
                    System.debug('!@#$% Inside InvokeCallistaAgencyInsert\'s createAgencyInCallista method, JobId is: ' + jobId);

                }
            }

        } catch (Exception ex) {

            System.debug('Class: InvokeCallistaAgencyInsert, Method: createAgencyInCallista, Message: ' + ex.getMessage());
            ExLog.add('InvokeCallistaAgencyInsert','Account / Agent Management Integration','createAgencyInCallista', ex);
            
        }
        
    }
    
}