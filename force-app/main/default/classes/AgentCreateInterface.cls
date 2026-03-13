/*******************************************************************************
* @author:		K Liew
* @date:		6.August.2018
* @description:	Business logic implementation for 'Insert Agent to Callista'
*				interface.  Forms request JSON in object form, and initiates
*				actual request via inherited method from framework.
* @revision:
*				6.August.2018 KL > Initial class creation.
*******************************************************************************/

public class AgentCreateInterface extends UniCRMIntegrationPoint implements Queueable, Database.AllowsCallouts {
    
    Id contactId;
    Contact contactRecord;
    
    public AgentCreateInterface (ID conId, String callistaCode) {

        try {
            
            System.debug('!@#$% Inside AgentCreateInterface\'s constructor...');
            
            this.doInit('IP02_Callista_Agent_Insert');
            contactId = conId;
            createRequestBody();

            Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
            urlReplaceKeyValuePairs.put('{0}', callistaCode);
            this.constructEndPoint(urlReplaceKeyValuePairs);

        } catch (Exception ex) {
            
            System.debug('Class: AgentCreateInterface, Method: AgentCreateInterface, Message: ' + ex.getMessage());
            ExLog.add('AgentCreateInterface','Account / Agent Management Integration','AgentCreateInterface', ex);
            
        }

    }

    private void createRequestBody() {
        
        try {

            contactRecord = [SELECT
                             Id,
                             FirstName,
                             LastName,
                             Account.Monash_AM_Start_Date__c,
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

        } catch (Exception ex) {

            System.debug('Class: AgentCreateInterface, Method: createRequestBody, Message: ' + ex.getMessage());
            ExLog.add('AgentCreateInterface','Account / Agent Management Integration','createRequestBody', ex);
            
        }
        
    }

    public void execute(QueueableContext ctx) {

        System.debug('!@#$% Inside AgentCreateInterface\'s execute method, performing callout...');            
        this.ctx = ctx;
        this.sendMessage();
        handleResponse();

    }

    private void handleResponse() {

        System.debug('!@#$% Inside AgentCreateInterface\'s handleResponse method, handling response...');            

        try {

            // check http response
            if (this.httpResponseCode == 200 || this.httpResponseCode == 201) {

                System.debug('!@#$% Inside AgentCreateInterface\'s handleResponse method, Response Code = 200 / 201...');            

                // if successful, extract Person Id and update Contact
                Map<String, Object> respBody = this.getResponseBody();
                String agentId = String.valueOf(respBody.get('agentId'));
                contactRecord.Person_ID_unique__c = agentId;
                contactRecord.Callista_Integration_Status__c = 'Inserted';
                update contactRecord;

            } else {

                System.debug('!@#$% Inside AgentCreateInterface\'s handleResponse method, Response Code = other...');            

            }

        } catch (Exception ex) {

            System.debug('Class: AgentCreateInterface, Method: handleResponse, Message: ' + ex.getMessage());
            ExLog.add('AgentCreateInterface','Account / Agent Management Integration','handleResponse', ex);

        }

    }

}