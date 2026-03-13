/***************************************************************************************************
* @author:		K Liew
* @date:		17.August.2018
* @description:	Business logic implementation for 'Update Agency to Callista'
*				interface.  Forms request JSON in object form, and initiates
*				actual request via inherited method from framework.
* @revision:
*				17.August.2018  KL > Initial class creation.
*               30.April.2019   SG > Updated to support agent termination 
*				2.May.2019      KL > Commenting out address level Effective To
*                               date due to defect detected during testing. Callista
*                               doesn't like it.
***************************************************************************************************/

public class AgencyUpdateInterface extends UniCRMIntegrationPoint implements Queueable, Database.AllowsCallouts {
    
    Id updatedAccountId;
    Account updatedAccount;
    
    public AgencyUpdateInterface (ID accountId) {
        
        try {
            
            System.debug('!@#$% Inside AgencyUpdateInterface\'s constructor, instantiating object...');            
            this.doInit('IP04_Callista_Agency_Update');
            updatedAccountId = accountId;
            createRequestBody();
            
        } catch (Exception ex) {
            
            System.debug('Class: AgencyUpdateInterface, Method: AgencyUpdateInterface, Message: ' + ex.getMessage());
            ExLog.add('AgencyUpdateInterface','Account / Agent Management Integration','AgencyUpdateInterface', ex);
            
        }
        
    }
    
    private void createRequestBody() {
        
        // prepare json structure and data
        
        System.debug('!@#$% Inside AgencyUpdateInterface\'s createRequestBody method, preparing json structure and data...');
        
        try {
            
            updatedAccount = [SELECT 
                              Callista_Org_Unit_Code__c,
                              Name,
                              Monash_AM_Start_Date__c,
                              Status__c,
                              ShippingStreet,
                              ShippingCity,
                              ShippingState,
                              ShippingPostalCode,
                              ShippingCountry,
                              Phone,
                              Monash_AM_Business_Phone__c,
                              Monash_AM_Mobile__c,
                              Email__c,
                              Country_Lookup__r.Callista_Code__c,
                              Callista_Integration_Status__c,
                              Google_Integration_Status__c,
                              Callista_Address_Type__c,
                              Latest_Contract_End_Date__c
                              FROM Account
                              WHERE Id = :updatedAccountId 
                              LIMIT 1];

            System.debug('!@#$% Inside AgencyUpdateInterface\'s createRequestBody method, Callista_Integration_Status__c = ' + updatedAccount.Callista_Integration_Status__c + ', Google_Integration_Status__c = ' + updatedAccount.Google_Integration_Status__c);
            
            JsonBodyAgency reqJson = new JsonBodyAgency();
            
            reqJson.type = 'agency';
            reqJson.code = updatedAccount.Callista_Org_Unit_Code__c.toUpperCase();
            reqJson.name = updatedAccount.Name.toUpperCase();
            if (updatedAccount.Callista_Address_Type__c == 'OS-POSTAL'){
                reqJson.countryCode = updatedAccount.Country_Lookup__r.Callista_Code__c;
            }
            reqJson.effectiveFrom = updatedAccount.Monash_AM_Start_Date__c;
            reqJson.effectiveTo = updatedAccount.Status__c =='Contract Terminated'?updatedAccount.Latest_Contract_End_Date__c:Null;                
            if (updatedAccount.Status__c != null) {
                reqJson.status = updatedAccount.Status__c.toUpperCase();
            }
            reqJson.isSuspended = false;
            reqJson.isOfferAlllowed = false;
            reqJson.isFeeWaiveAllowed = false;
            
            reqJson.addresses.add(new JsonBodyAgency.Address());
            reqJson.addresses.get(0).streetAddress = updatedAccount.ShippingStreet;
            reqJson.addresses.get(0).suburbOrTown = updatedAccount.ShippingCity;
            reqJson.addresses.get(0).stateOrRegion = updatedAccount.ShippingState;
            reqJson.addresses.get(0).postcode = updatedAccount.ShippingPostalCode;
            
            // fields below should be set accordingly based on whether an Australian or overseas address is detected
            reqJson.addresses.get(0).type = 'address';
            reqJson.addresses.get(0).usage = updatedAccount.Callista_Address_Type__c;
            if (updatedAccount.Callista_Address_Type__c == 'OS-POSTAL'){
            reqJson.addresses.get(0).country = updatedAccount.ShippingCountry;
            }
            
            // Comms
            reqJson.addresses.get(0).phoneNumber = updatedAccount.Phone;
            reqJson.addresses.get(0).businessNumber = updatedAccount.Monash_AM_Business_Phone__c;
            reqJson.addresses.get(0).mobileNumber = updatedAccount.Monash_AM_Mobile__c;
            reqJson.addresses.get(0).emailAddress = updatedAccount.Email__c;
            reqJson.addresses.get(0).effectiveFrom = updatedAccount.Monash_AM_Start_Date__c;
            // reqJson.addresses.get(0).effectiveTo = updatedAccount.Status__c =='Contract Terminated'? updatedAccount.Latest_Contract_End_Date__c: Null;                
            
            this.jsonRequest = reqJson;
            
            Map<String, String> urlReplaceKeyValuePairs = new Map<String, String>();
            urlReplaceKeyValuePairs.put('{0}', updatedAccount.Callista_Org_Unit_Code__c.toUpperCase());
            this.constructEndPoint(urlReplaceKeyValuePairs);
            
        } catch (Exception ex) {
            
            System.debug('Class: AgencyUpdateInterface, Method: createRequestBody, Message: ' + ex.getMessage());
            ExLog.add('AgencyUpdateInterface','Account / Agent Management Integration','createRequestBody', ex);
            
        }
        
    }
    
    public void execute(QueueableContext ctx) {
        
        System.debug('!@#$% Inside AgencyUpdateInterface\'s execute method, performing callout...');            
        
        this.ctx = ctx;
        this.sendMessage();
        handleResponse();
        
    }
    
    private void handleResponse() {
        
        System.debug('!@#$% Inside AgencyUpdateInterface\'s handleResponse method, handling response...');
        
        // update Account record's integration status.
        try {
            
            if (this.httpResponseCode == 200 || this.httpResponseCode == 201) { // successful callout.
                //                updatedAccount.Callista_Sync_Status__c = true;
                updatedAccount.Callista_Integration_Status__c = 'Updated';
                update updatedAccount;
            }
            
        } catch (Exception ex) {
            
            System.debug('Class: AgencyUpdateInterface, Method: handleResponse, Message: ' + ex.getMessage());
            ExLog.add('AgencyUpdateInterface','Account / Agent Management Integration','handleResponse', ex);
            
        }
    }
}