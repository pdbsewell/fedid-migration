/**
* This class is to return User First Name of the logged in Community User. 
* 
* @author Veera, PwC
* @Created Date: 8.June.2017 
*/
public class LightningMonashHeadLineController {
    
	/*******************************************************************************
	* @author       Veera, PwC
	* @date         8.June.2017       
	* @description  method to return User First Name
	* @Input Parameters: 
	* @return type: string
	* @revision     	
	*******************************************************************************/
    @AuraEnabled
    public static string getUserFirstName() {
        
        string firstName = ''; 
        string currentUserProfile = [select id,name from Profile where Id =: userInfo.getProfileId() Limit 1].name;
        
        if(currentUserProfile != Label.Guest_User_Profile_Name){
            firstName = ' '+[select id,firstname from user where id = :userinfo.getUserId()].firstname;
        }
        
        
        return firstName;        
    }
    
 
    /*******************************************************************************
	* @author       Veera, PwC
	* @date         8.June.2017       
	* @description  method returns custom settings which store external urls
	* @Input Parameters: 
	* @return type: CustomURLs__c
	* @revision     	
	*******************************************************************************/
	@AuraEnabled
    public static string getHomePageUrl()
    {
        string homepage = CustomURLs__c.getInstance().Community_Home_Page__c != null?CustomURLs__c.getInstance().Community_Home_Page__c:'https://http://www.monash.edu/';
        return homepage;
    }    
}