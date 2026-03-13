/**
 * Author: Inderpal Dhanoa
 * Date: 2020-09-05
 * Description: Contains Controller Logic for LWC ResetDnBFields
 * group : Enterprise ERDA
 * @Last Modified By   : Sachin Shetty
 * @Last Modified On   : 2024-17-04
 * Modifications Log 
 * Date         Author       		    Modification
 * 2020-09-05   Inderpal Dhan   		Initial Version
 * 2022-09-21 	Inderpal Dhan			Captcha Fix ENGAGEIE-1494 
 * 2024-17-04   Sachin Shetty           Update to point to DBConnect fields
 */
public with sharing class ResetDnBFieldsController {
    /*******************************************************************************
     * @author       Inderpal Dhanoa
     * @date         2020-09-05
     * @description  ClearFields to reset the DnB fields
     * @revision     2020-09-05 - Inderpal Dhanoa - Initial version
     *               2024-04-10 - Sachin Shetty   - Update to point to DBConnect fields
     *******************************************************************************/
    @AuraEnabled
    public static String clearFields(Id accountId){
        try{
            List<Account> relatedAcc = [SELECT Id , DBC_DUNS_Number__c, NumberOfEmployees, Employees_Overall__c, Fortune_1000_Rank__c, Global_Ultimate_Account_Name__c, 
                                        Global_Ultimate_DUNS_Number__c, Legal_Structure__c, ShippingCity, ShippingCountry, ShippingStreet, ShippingPostalCode, ShippingState, 
                                        Match_Score__c, Organisation_Identifier__c, Organisation_Identifier_Alternative__c, Organisation_Identifier_Type__c, 
                                        Organisation_Identifier_Type_Alternative__c, Out_of_Business_Indicator__c, BillingLatitude , BillingLongitude , Public_Private_Indicator__c, 
                                        AnnualRevenue, Sic, SicDesc, SIC8_Code__c, SIC8_Description__c, TickerSymbol, Phone, Trading_Name__c, Website, BillingStreet, BillingCity, 
                                        BillingPostalCode FROM Account WHERE Id = : Id.valueOf(accountId)];
            relatedAcc[0].DBC_DUNS_Number__c = null;
            relatedAcc[0].NumberOfEmployees = null;
            relatedAcc[0].Employees_Overall__c = null; 
            relatedAcc[0].Fortune_1000_Rank__c = null; 
            relatedAcc[0].Global_Ultimate_Account_Name__c = null; 
            relatedAcc[0].Global_Ultimate_DUNS_Number__c = null; 
            relatedAcc[0].Legal_Structure__c = null; 
            relatedAcc[0].ShippingCity = null; 
            relatedAcc[0].ShippingCountry = null; 
            relatedAcc[0].ShippingStreet = null; 
            relatedAcc[0].ShippingPostalCode = null; 
            relatedAcc[0].ShippingState = null; 
            relatedAcc[0].Match_Score__c = null; 
            relatedAcc[0].Organisation_Identifier__c = null; 
            relatedAcc[0].Organisation_Identifier_Alternative__c = null; 
            relatedAcc[0].Organisation_Identifier_Type__c = null; 
            relatedAcc[0].Organisation_Identifier_Type_Alternative__c = null; 
            relatedAcc[0].Out_of_Business_Indicator__c = null; 
            relatedAcc[0].BillingLatitude  = null; 
            relatedAcc[0].BillingLongitude  = null; 
            relatedAcc[0].Public_Private_Indicator__c = null; 
            relatedAcc[0].AnnualRevenue = null; 
            relatedAcc[0].Sic = null; 
            relatedAcc[0].SicDesc = null; 
            relatedAcc[0].SIC8_Code__c = null; 
            relatedAcc[0].SIC8_Description__c = null; 
            relatedAcc[0].TickerSymbol = null;
			relatedAcc[0].Website = null;			
            relatedAcc[0].Phone = null; 
            relatedAcc[0].Trading_Name__c = null;
            relatedAcc[0].BillingStreet = null;
            relatedAcc[0].BillingCity = null;
            relatedAcc[0].BillingPostalCode = null;
            relatedAcc[0].BillingCountry = null;
            update relatedAcc;
            return null;
        }catch(Exception ex){
            Nebula.Logger.error('ResetDnBFieldsController.clearFields', ex);
            Nebula.Logger.saveLog();
            throw ex;
        }        
    }
}