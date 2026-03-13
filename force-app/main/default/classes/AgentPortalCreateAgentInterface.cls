/***************************************************************************************************
* @author:		K Liew
* @date:		16.August.2018
* @description:	Business logic implementation for 'Insert Agency + Agent details
*				to Google App's Agent Portal' interface.  Forms request JSON in
* 				object form, and initiates actual request via inherited method
*				from framework.
* @revision:
*				16.August.2018  KL > Initial class creation.
*               29.April.2019   KL > Updated for SFTDC-378, included 2
*                               additional fields to support Agent Termination
*               2.May.2019      KL > Removal of isEnabled and isSuspend fields in JSON as this
*                               is not necessary based on what's discovered in testing. Agent Portal
*                               automatically sets these values based on Status.
*               3.Aug.2022      Shalini Mendu - Add Monash Campus in the request payload
***************************************************************************************************/

public class AgentPortalCreateAgentInterface extends UniCRMIntegrationPoint implements Queueable, Database.AllowsCallouts {

    Id contactId;
    Contact roleAccountContactRecord;
    
    // constructor, initialise interface details from custom metadata
    public AgentPortalCreateAgentInterface (Id conId) {
        
        try {
			System.debug('!@#$% Inside AgentPortalCreateAgentInterface\'s constructor, instantiating object...');
            
            this.doInit('IP03_Google_Agent_Portal_Create_Agent');
            contactId = conId;
            createRequestBody();
            
        } catch(Exception ex) {
            System.debug('Class: AgentPortalCreateAgentInterface, Method: AgentPortalCreateAgentInterface, Message: ' + ex.getMessage());
            ExLog.add('AgentPortalCreateAgentInterface','Account / Agent Management Integration','AgentPortalCreateAgentInterface', ex);
        }
        
    }
    
    private void createRequestBody() {

        System.debug('!@#$% Inside AgentPortalCreateAgentInterface\'s createRequestBody method, preparing json structure and data...');
        List<String> campusList = new List<String>();
        // prepare json structure and data
        try {
            
            roleAccountContactRecord = [SELECT
                                        Id,
                                        Account.Headquarters__c,
                                        Account.Agency_HQ__c,
                                        Account.Name,
                                        Account.ShippingStreet,
                                        Account.ShippingCity,
                                        Account.ShippingState,
                                        Account.ShippingCountry,
                                        Account.Callista_Org_Unit_Code__c,
                                        Account.Email__c,
                                        Account.Phone,
                                        Account.Status__c,
                                        Account.Agent_Portal_Access_Is_Enabled__c,
                                        Account.Agent_Portal_Access_Is_Suspended__c,
                                        Account.Monash_AM_Campus__c,
                                        Person_ID_unique__c
                                        FROM Contact
                                        WHERE Id = :contactId];
            
            JsonBodyAgentPortalAgent reqJson = new JsonBodyAgentPortalAgent();

            reqJson.officeBranch = roleAccountContactRecord.Account.Name;
            
            if ((roleAccountContactRecord.Account.Agency_HQ__c == null || roleAccountContactRecord.Account.Agency_HQ__c == '') && roleAccountContactRecord.Account.Headquarters__c) {
                reqJson.name = roleAccountContactRecord.Account.Name;
            } else {
                reqJson.name = roleAccountContactRecord.Account.Agency_HQ__c;
            }
                
            reqJson.country = roleAccountContactRecord.Account.ShippingCountry;
            reqJson.agentId = roleAccountContactRecord.Person_ID_unique__c;
            reqJson.orgUnitId = roleAccountContactRecord.Account.Callista_Org_Unit_Code__c;
            reqJson.email = roleAccountContactRecord.Account.Email__c;
            reqJson.financeEmail = '';
            reqJson.address = roleAccountContactRecord.Account.ShippingStreet;
            reqJson.suburb = roleAccountContactRecord.Account.ShippingCity;
            reqJson.regionState = roleAccountContactRecord.Account.ShippingState;
            reqJson.phoneNumber = roleAccountContactRecord.Account.Phone;
            reqJson.status = roleAccountContactRecord.Account.Status__c;
            // reqJson.isEnabled = roleAccountContactRecord.Account.Agent_Portal_Access_Is_Enabled__c;
            // reqJson.isSuspended = roleAccountContactRecord.Account.Agent_Portal_Access_Is_Suspended__c;
            
            //Convert multipicklist value to String
            String acccamps = (String)roleAccountContactRecord.Account.Monash_AM_Campus__c;
            //Split multipicklist by the delimited ;
            for(String campus: acccamps.split(';'))
            {
                campusList.add(campus);
            }
            
            //add campusList to the Request
            reqJson.campus = campusList;
      
            this.jsonRequest = reqJson;

        } catch (Exception ex) {

            System.debug('Class: AgentPortalCreateAgentInterface, Method: createRequestBody, Message: ' + ex.getMessage());
            ExLog.add('AgentPortalCreateAgentInterface','Account / Agent Management Integration','createRequestBody', ex);

        }

    }

    public void execute(QueueableContext ctx) {

        System.debug('!@#$% Inside AgentPortalCreateAgentInterface\'s execute method, performing callout...');            

        this.ctx = ctx;
        this.sendMessage();
        handleResponse();
        
    }

    private void handleResponse() {

        System.debug('!@#$% Inside AgentPortalCreateAgentInterface\'s handleResponse method, handling response...');
        
        // update Contact record's integration status.
        try {
            
            if (this.httpResponseCode == 200 || this.httpResponseCode == 201) { // successful callout.
                roleAccountContactRecord.Google_Integration_Status__c = 'Inserted';
                //roleAccountContactRecord.Account.Google_Integration_Status__c = 'Inserted';
                update roleAccountContactRecord;
            }
            
        } catch (Exception ex) {

            System.debug('Class: AgentPortalCreateAgentInterface, Method: handleResponse, Message: ' + ex.getMessage());
            ExLog.add('AgentPortalCreateAgentInterface','Account / Agent Management Integration','handleResponse', ex);
            
        }

    }
    
}