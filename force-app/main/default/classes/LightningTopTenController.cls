/**
* controller Class to get TopTen articles. 
* 
* @author Veera, PwC
* @Created Date: 22.May.2017
*/
public class LightningTopTenController {
    
    
    
    /*******************************************************************************
    * @author       Veera, PwC
    * @date         22.May.2017       
    * @description  method to get query to find Top Ten Articles depending upon profile
    * @return type  string
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static string getQuery(){
        
        string query ='Select Name,Title__c,Article_Link__c,Article_UrlName__c,ArticleType__c,External__c,External_Order__c,Staff__c,Staff_Order__c,Student__c,Student_Order__c from TopTenArticle__c';
        string currentUserProfileName = [select id,name from Profile where Id =: userInfo.getProfileId() Limit 1].name; 
        string todayDate = string.valueof(system.today()).remove('00:00:00');
        
        if(currentUserProfileName == Label.Guest_User_Profile_Name) {
            query = query + ' Where External__c = true AND StartDate__c <='+todayDate+' AND (EndDate__c >='+todayDate+' OR EndDate__c = NULL) Order By External_Order__c ASC Limit 10';
        } else if(currentUserProfileName == Label.Community_Student_Profile_Name) {
            query = query + ' Where Student__c = true AND StartDate__c <='+todayDate+' AND (EndDate__c >='+todayDate+' OR EndDate__c = NULL) Order By Student_Order__c ASC Limit 10';
        } else if(currentUserProfileName == Label.Community_Staff_Profile_Name) {
            query = query + ' Where Staff__c = true AND StartDate__c <='+todayDate+' AND (EndDate__c >='+todayDate+' OR EndDate__c = NULL) Order By Staff__c DESC, Staff_Order__c ASC Limit 10';
        } else {
            query = query + ' Where Staff__c = true AND StartDate__c <='+todayDate+' AND (EndDate__c >='+todayDate+' OR EndDate__c = NULL) Order By Staff__c DESC, Staff_Order__c ASC Limit 10';
        }
        
        return query;    
    }
    
    /*******************************************************************************
    * @author       Veera, PwC
    * @date         22.May.2017       
    * @description  method to fetch records from Top Ten Article Object
    * @return type  list<TopTenArticle__c>
    * @revision     
    *******************************************************************************/
    
    @AuraEnabled
    public static list<TopTenArticle__c> getTopTenArticles() {
        string query = getQuery();
        if(!string.isBlank(query)) {
            return database.query(query);
        } else {
            return new list<TopTenArticle__c>();
        }
        
    }
    
}