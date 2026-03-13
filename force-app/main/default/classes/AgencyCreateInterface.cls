/***************************************************************************************************
* @author:		K Liew
* @date:		6.August.2018
* @description:	Business logic implementation for 'Insert Agency to Callista'
*				interface.  Forms request JSON in object form, and initiates
*				actual request via inherited method from framework.
* @revision:
*				6.August.2018   KL > Initial class creation.
*               30.April.2019   SG > Updated to support agent termination 
*				2.May.2019      KL > Commenting out address level Effective To
*                               date due to defect detected during testing. Callista
*                               doesn't like it.
***************************************************************************************************/

public class AgencyCreateInterface extends UniCRMIntegrationPoint implements Queueable, Database.AllowsCallouts {
    
    Id accntId;
    Account newAgencyRecord;
    
    public AgencyCreateInterface (ID accountId) {
        //    public AgencyCreateInterface (Account accountId) {
        
        try {
            
            System.debug('!@#$% Inside AgencyCreateInterface\'s constructor, instantiating object...');            
            this.doInit('IP01_Callista_Agency_Insert');
            accntId = accountId;
            //            newAgencyRecord = accountId;
            createRequestBody();
            
        } catch (Exception ex) {
            
            System.debug('Class: AgencyCreateInterface, Method: AgencyCreateInterface, Message: ' + ex.getMessage());
            ExLog.add('AgencyCreateInterface','Account / Agent Management Integration','AgencyCreateInterface', ex);
            
        }
        
    }
    
    private void createRequestBody() {
        
        // prepare json structure and data
        
        System.debug('!@#$% Inside AgencyCreateInterface\'s createRequestBody method, preparing json structure and data...');
        
        try {
            
            newAgencyRecord = [SELECT 
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
                               Callista_Address_Type__c,
                               Latest_Contract_End_Date__c 
                               FROM Account
                               WHERE Id = :accntId 
                               LIMIT 1];
            
            JsonBodyAgency reqJson = new JsonBodyAgency();
            
            // we should be able to further improve on this and refactor, make a framework type logic that uses some "mapping" (custom metadata?) to 
            // generate "integration object instances" / JSONs in a data-driven manner (or is it over-engineering? @future activity if need be).
            reqJson.type = 'agency';
            reqJson.code = newAgencyRecord.Callista_Org_Unit_Code__c.toUpperCase();
            reqJson.name = newAgencyRecord.Name.toUpperCase();
            if (newAgencyRecord.Callista_Address_Type__c == 'OS-POSTAL'){
                reqJson.countryCode = newAgencyRecord.Country_Lookup__r.Callista_Code__c;
            }
            reqJson.effectiveFrom = newAgencyRecord.Monash_AM_Start_Date__c;
            reqJson.effectiveTo = newAgencyRecord.Status__c =='Contract Terminated'?newAgencyRecord.Latest_Contract_End_Date__c:Null;                
            if (newAgencyRecord.Status__c != null) {
                reqJson.status = newAgencyRecord.Status__c.toUpperCase();
            }
            reqJson.isSuspended = false;
            reqJson.isOfferAlllowed = false;
            reqJson.isFeeWaiveAllowed = false;
            
            reqJson.addresses.add(new JsonBodyAgency.Address());
            reqJson.addresses.get(0).streetAddress = newAgencyRecord.ShippingStreet;
            reqJson.addresses.get(0).suburbOrTown = newAgencyRecord.ShippingCity;
            reqJson.addresses.get(0).stateOrRegion = newAgencyRecord.ShippingState;
            reqJson.addresses.get(0).postcode = newAgencyRecord.ShippingPostalCode;
            
            // fields below should be set accordingly based on whether an Australian or overseas address is detected
            reqJson.addresses.get(0).type = 'address';
            reqJson.addresses.get(0).usage = newAgencyRecord.Callista_Address_Type__c;
            if (newAgencyRecord.Callista_Address_Type__c == 'OS-POSTAL'){
                reqJson.addresses.get(0).country = newAgencyRecord.ShippingCountry;
            }
            
            // Comms
            reqJson.addresses.get(0).phoneNumber = newAgencyRecord.Phone;
            reqJson.addresses.get(0).businessNumber = newAgencyRecord.Monash_AM_Business_Phone__c;
            reqJson.addresses.get(0).mobileNumber = newAgencyRecord.Monash_AM_Mobile__c;
            reqJson.addresses.get(0).emailAddress = newAgencyRecord.Email__c;
            reqJson.addresses.get(0).effectiveFrom = newAgencyRecord.Monash_AM_Start_Date__c;
            // reqJson.addresses.get(0).effectiveTo = newAgencyRecord.Status__c =='Contract Terminated'?newAgencyRecord.Latest_Contract_End_Date__c:Null;                
            this.jsonRequest = reqJson;
            
        } catch (Exception ex) {
            
            System.debug('Class: AgencyCreateInterface, Method: createRequestBody, Message: ' + ex.getMessage());
            ExLog.add('AgencyCreateInterface','Account / Agent Management Integration','createRequestBody', ex);
            
        }
    }
    
    public void execute(QueueableContext ctx) {
        
        System.debug('!@#$% Inside AgencyCreateInterface\'s execute (With QueueableContext) method, performing callout...');            
        
        this.ctx = ctx;
        this.sendMessage();
        handleResponse();
        
    }
    
    private void handleResponse() {
        
        System.debug('!@#$% Inside AgencyCreateInterface\'s handleResponse method, handling response...');
        
        // update Account record's integration status.
        try {
            System.debug('!@#$% Inside AgencyCreateInterface\'s handleResponse method, handling response, value is: ' + this.httpResponseCode);
            
            if (this.httpResponseCode == 200 || this.httpResponseCode == 201) { // successful callout.
                System.debug('!@#$% Inside AgencyCreateInterface\'s handleResponse method, handling response 200 / 201...');
                newAgencyRecord.Callista_Integration_Status__c = 'Inserted';
                update newAgencyRecord;
            }
            
        } catch (Exception ex) {
            
            System.debug('Class: AgencyCreateInterface, Method: handleResponse, Message: ' + ex.getMessage());
            ExLog.add('AgencyCreateInterface','Account / Agent Management Integration','handleResponse', ex);
            
        }
        
    }
    
}