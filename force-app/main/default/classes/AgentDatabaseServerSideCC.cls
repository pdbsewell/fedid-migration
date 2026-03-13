/*******************************************************************************
* @author:		K Liew
* @date:		5.September.2018
* @description:	Server side controller for the AgenciesController Lightning 
*				Component.  Purpose is to Get and Return Agency records back to
*				client-side controller.
* @revision:
*				05.Sep.2018 KL > Initial class creation.
*******************************************************************************/

public without sharing class AgentDatabaseServerSideCC {

    @TestVisible private static Agent_Onboarding_Settings__c cs = Agent_Onboarding_Settings__c.getOrgDefaults();

    @AuraEnabled
    public static List<AggregateResult> getAllCountries () {
        
        try {
            
            List<AggregateResult> countries = [SELECT 
                                               ShippingCountry
                                               FROM Account 
                                               WHERE RecordTypeId in (SELECT Id 
                                                                      FROM RecordType
                                                                      WHERE SobjectType = 'Account'
                                                                      AND DeveloperName = :cs.Account_RT_Developer_Name__c 
                                                                      AND IsActive = true)
                                               AND Monash_AM_Web_Status__c = true 
                                               AND ShippingCountry != NULL
                                               GROUP BY ShippingCountry
                                               ORDER BY ShippingCountry
                                              ];
            
            return countries;
            
        } catch (Exception ex) {
            
            System.debug('Class: AgentDatabaseServerSideCC, Method: getAllCountries, Message: ' + ex.getMessage());
            ExLog.add('AgentDatabaseServerSideCC','Account / Agent Management','getAllCountries', ex);
            return null;
            
        }
        
    }
    
}