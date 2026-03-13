/*******************************************************************************
* @author:		K Liew
* @date:		17.August.2018
* @description:	Business logic implementation for 'Update Agent to Callista'
*				interface.  Forms request JSON in object form, and initiates
*				actual request via inherited method from framework.
* @revision:
*				17.August.2018 KL > Initial class creation.
*******************************************************************************/

public class AgentUpdateInterface extends UniCRMIntegrationPoint implements Queueable, Database.AllowsCallouts {
	
    Id contactId;
    Contact contactRecord;
    
    public AgentUpdateInterface (ID conId) {

        try {
            
            System.debug('!@#$% Inside AgentUpdateInterface\'s constructor...');
            
            this.doInit('IP05_Callista_Agent_Update');
            contactId = conId;
            createRequestBody();

        } catch (Exception ex) {
            
            System.debug('Class: AgentUpdateInterface, Method: AgentUpdateInterface, Message: ' + ex.getMessage());
            ExLog.add('AgentUpdateInterface','Account / Agent Management Integration','AgentUpdateInterface', ex);
            
        }

    }

    private void createRequestBody() {
        
        try {

            contactRecord = [SELECT
                             Id,
                             FirstName,
                             LastName,
                             Account.Monash_AM_Start_Date__c,
                             Account.Callista_Org_Unit_Code__c ,
                             Person_ID_unique__c
                             FROM Contact
                             WHERE Id = :contactId
                             LIMIT 1];

            JsonBodyAgent reqJson = new JsonBodyAgent();

            reqJson.type = 'agent';
            reqJson.agencyEffectiveFrom = contactRecord.Account.Monash_AM_Start_Date__c;
            reqJson.surname = contactRecord.LastName.toUpperCase();
            reqJson.givenNames = contactRecord.FirstName.toUpperCase();
            reqJson.effectiveFrom = contactRecord.Account.Monash_AM_Start_Date__c;

            this.jsonRequest = reqJson;
            
            // admissions/agencies/{agencyCode}/agents/{agentId}
            Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
            urlReplaceKeyValuePairs.put('{agencyCode}', contactRecord.Account.Callista_Org_Unit_Code__c.toUpperCase());
            urlReplaceKeyValuePairs.put('{agentId}', contactRecord.Person_ID_unique__c.toUpperCase());
            this.constructEndPoint(urlReplaceKeyValuePairs);

        } catch (Exception ex) {

            System.debug('Class: AgentCreateInterface, Method: createRequestBody, Message: ' + ex.getMessage());
            ExLog.add('AgentCreateInterface','Account / Agent Management Integration','createRequestBody', ex);
            
        }
        
    }

    public void execute(QueueableContext ctx) {

        System.debug('!@#$% Inside AgentUpdateInterface\'s execute method, performing callout...');            
        this.ctx = ctx;
        this.sendMessage();
        handleResponse();

    }

    private void handleResponse() {

        System.debug('!@#$% Inside AgentUpdateInterface\'s handleResponse method, handling response...');            

        try {

            // check http response
            if (this.httpResponseCode == 200 || this.httpResponseCode == 201) {

                System.debug('!@#$% Inside AgentUpdateInterface\'s handleResponse method, Response Code = 200 / 201...');            

                // if successful, set Contact record's sync status tracking
                contactRecord.Callista_Integration_Status__c = 'Updated';
                contactRecord.Google_Integration_Status__c = 'Needs Update';
                update contactRecord;

            } else {

                System.debug('!@#$% Inside AgentUpdateInterface\'s handleResponse method, Response Code = other...');            

            }

        } catch (Exception ex) {

            System.debug('Class: AgentUpdateInterface, Method: handleResponse, Message: ' + ex.getMessage());
            ExLog.add('AgentUpdateInterface','Account / Agent Management Integration','handleResponse', ex);

        }

    }

}