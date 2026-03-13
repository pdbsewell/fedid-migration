/*******************************************************************************
* @author		Davey Yu
* @date         11/1/2025   
* @description  Apex Class for My App Site Banner 
* @revision     11/1/2025 - Initial Version
*******************************************************************************/
public with sharing class HDRGraduateResearchBannerCC {
    
   /*******************************************************************************
    * @author		Davey Yu
    * @date         11/1/2025   
    * @description  Retrieve site banner details from custom settings
    * @revision     11/1/2025 - Initial Version
    *******************************************************************************/
    @AuraEnabled(cacheable=true)  
    public static Community_Experience_Site_Banner__c getBannerDetail(){
        Community_Experience_Site_Banner__c banner = Community_Experience_Site_Banner__c.getInstance(UserInfo.getUserId());
        return banner;
    }
}