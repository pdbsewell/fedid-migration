/**
 * @description       : Controller for PORTAL_UCIN Login, Forgot Password components
 * @author            : Sulung Chandra, UC Innovation
 * @group             : PORTAL_UCIN
 * @last modified on  : 2020-10-19
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.1   2020-10-19   Stefan Scheit   Update of login() method and inner class UserUpdateHandler
 * 1.1   2010-08-10   Ajitabh Jha     Added inner class UserUpdateHandler to set CommunityAccess__c property on User
 * 1.0   2019-08-28   Sulung Chandra  Initial Version
**/
global with sharing class PORTAL_UCIN_LoginController {
    
    public static final String COMMUNITY_NAME = 'ascendportal';

    public PORTAL_UCIN_LoginController() {
    }
    
    /**
    * Login using Site.Login()
    *
    * @return: message			            Error message if there is an exception
    * @param: username                      Login Username
    * @param: password                      Login Password
    * @param: startUrl                      The URL where to redirect the user
    */
    @AuraEnabled
    public static String login(String username, String password, String startUrl) {
        try{
            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
            // set attempt to log into Alumni portal on user record
             CommonUtilities.UserUpdateHandler obj = new CommonUtilities.UserUpdateHandler();
             obj.updateCommunityAccess(username, COMMUNITY_NAME);
            // redirect user
            aura.redirect(lgn);
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();            
        }
    }
    
    /**
    * 
    * Forgot Password using Site.forgotPassword()
    *
    * @return: message			            Error message if there is an exception
    * @param: username                      Login Username
    * @param: checkEmailUrl                 The URL to notify user to check for email to reset password
    */
    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            Site.forgotPassword(username);
            ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
            if(!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            if(!Test.isRunningTest()) {
                aura.redirect(checkEmailRef);
            }
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }
    
    /**
    * Account activation that is validated using Verification Code    * sorting criteria and the maximum number of records to be returned
    *
    * @return: message			            Error message if there is an exception or  validation issue
    * @param: verificationCode              The Code in Activation Token object associated to the user
    * @param: firstname                     The user Firstname
    * @param: lastname                      The user Lastname
    * @param: birthdate                     The user Date of Birth
    * @param: degree                        The user Degree
    * @param: checkEmailUrl                 The URL to notify user to check for email to reset password
    */
    @AuraEnabled
    public static String activateAccount(String verificationCode, String firstname, String lastname, String birthdate, String degree, String checkEmailUrl) {
        List<User> matchingUserList = new List<User>();
        List<Activation_Token__c> tokenList;
        Boolean hasValidToken = false;
        String errorMessage = 'Unable to verify your account.';
        Date dob;
        
        try {
            dob = Date.valueOf(birthdate);
            
        } catch (Exception ex) {
            errorMessage = 'Invalid date';
        }
        
        if (dob != null) {
            matchingUserList = [Select Id, Username From User Where IsActive = true And ContactId != null And Contact.Firstname = :firstname And Contact.Lastname = :lastname 
                    And Contact.BirthDate = :dob Limit 1];
        }
        
        if (!matchingUserList.isEmpty()) {
            tokenList = [Select Id, Token__c, Retry_Count__c, Last_Retried_Date__c From Activation_Token__c Where Active__c = true And User__c = :matchingUserList[0].Id Limit 1];
            if (!tokenList.isEmpty()) {
                if (tokenList[0].Token__c == verificationCode) {
                    hasValidToken = true;
                } else {
                    tokenList[0].Retry_Count__c = tokenList[0].Retry_Count__c + 1;
                    tokenList[0].Last_Retried_Date__c = Datetime.now();
                    update tokenList;
                }
            } else {
                errorMessage = 'Unable to verify your account. Please contact ERDA via Email or Phone.';
            }
            
            if (hasValidToken) {
                try {
                    Site.forgotPassword(matchingUserList[0].Username);
                    ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
                    if(!Site.isValidUsername(matchingUserList[0].Username)) {
                        return Label.Site.invalid_email;
                    }
                    if(!Test.isRunningTest()) {
                        aura.redirect(checkEmailRef);
                    }
                    return null;
                }
                catch (Exception ex) {
                    return ex.getMessage();
                }
            }
        }
        
        return errorMessage;
    }
    
    /**
    * Return the Forgot Password URL from the Community Configuration
    *
    * @return: url			                Community configuration for Forgot Password Url
    */
    @AuraEnabled
    public static String getForgotPasswordUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getForgotPasswordUrl();
    }

    /**
    * Return Community Configuration
    *
    * @return: url			                Community configuration Url
    */    
    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }
    
    /**
    * Retrieve selectable Contact Qualification Degree Level options
    *
    * @return: Qualification Degree Levels  List of selectable Contact Qualification Degree Levels
    */
	@AuraEnabled
    public static List<SelectOptionDetail> getContactQualificationDegreeLevels()
    {
        List<SelectOptionDetail> mylist = new List<SelectOptionDetail>();
        
        Schema.DescribeFieldResult fr = Contact_Qualification__c.Degree_Level__c.getDescribe();
        List<Schema.PicklistEntry> pleList = fr.getPicklistValues();
			
        for(Schema.PicklistEntry ple : pleList)
        {
            mylist.add(new SelectOptionDetail(ple.getLabel(), ple.getValue()));
        }
            
        return mylist;
    }
    
    /**
    * Wrapper class for the Selectable Options used by DropDownList
    */
    public class SelectOptionDetail {
        @AuraEnabled
        public String name {get;set;}
		
        @AuraEnabled
        public String value {get;set;}
		
		public selectOptionDetail(String name, String value) {
			this.name = name;
			this.value = value;
		}
    }
}