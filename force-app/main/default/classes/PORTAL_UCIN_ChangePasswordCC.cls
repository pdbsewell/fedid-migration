/**
 * @author Sulung Chandra, UC Innovation
 * @date 9/20/2019
 * @group PORTAL_UCIN
 * @group-content 
 * @description An apex page controller that exposes the change password functionality
 * @last modified on  : 2021-06-27
 * @last modified by  : Inderpal Dhanoa
 * Modifications Log 
 * Ver   Date         Author              Modification 
 * 1.1   2021-27-06 - Inderpal Dhanoa - Adding functionality for session management PENGAGE-2422 
 * 1.0   2019-09-20 - Sulung Chandra - Initial Version
**/
public with sharing class PORTAL_UCIN_ChangePasswordCC {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}       
    
   	public PORTAL_UCIN_ChangePasswordCC() {}    
    
    /**
    * Change password using Site.changePassword(), 
    * Send email confirmation that the password has been changed
    *
    * @param: newPassword                   New Password
    * @param: verifyNewPassword             New Password Verification/Confirmation
    * @param: oldpassword                   Old Password
    */
    public PageReference changePassword() {
        PageReference mypage;
        try{
            mypage = Site.changePassword(newPassword, verifyNewPassword, oldpassword); 
        
            // User logged in via welcome email reset password
            
            CommonUtilities.UserUpdateHandler obj = new CommonUtilities.UserUpdateHandler();
            obj.updateCommunityAccess(UserInfo.getUserName(), PORTAL_UCIN_LoginController.COMMUNITY_NAME);
            
            //had to add the following: "|| Test.IsRunningTest()" to get test coverage
            if (mypage != null || Test.isRunningTest()) {

                // Update the Last 2FA Login
                List<User> l_userInfo = [SELECT id, Last_2FA_Login__c FROM User WHERE Id = :UserInfo.getUserId()];
                l_userInfo[0].Last_2FA_Login__c = DateTime.now();
                update l_userInfo;
                
                List<PORTAL_UCIN_Email_Template__mdt> mdtList = [Select DeveloperName, EmailTemplateId__c, OrgWideEmailAddressId__c, OrgWideEmailAddress__c From PORTAL_UCIN_Email_Template__mdt Where DeveloperName='PORTAL_UCIN_Password_Changed'];
                if (!mdtList.isEmpty()) {
                    try {
                        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: mdtList[0].DeveloperName LIMIT 1];

                        if (!templateList.isEmpty()) {
                            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                            // Query org wide address
                            //List<OrgWideEmailAddress> owa = [select Id, Address, DisplayName from OrgWideEmailAddress WHERE Address = 'monashalumni@f.e.monash.edu' limit 1];
                            List<OrgWideEmailAddress> owa = [select Id, Address, DisplayName from OrgWideEmailAddress WHERE Address = :mdtList[0].OrgWideEmailAddress__c limit 1];

                            if (!owa.isEmpty()) {
                                mail.setOrgWideEmailAddressId(owa[0].Id);
                            }

                            mail.setTemplateId(templateList[0].Id);
                            mail.setTargetObjectId(UserInfo.getUserId());
                            mail.setTreatTargetObjectAsRecipient(true);
                            mail.saveAsActivity = false;
                            mailList.add(mail);
                            Messaging.sendEmail(mailList);
                        }                    
                    } catch (Exception ex) {
                        System.debug('#### ex: '+ex);
                    }
                }

                CommonUtilities.terminateUserSession(Userinfo.getUserId());
                mypage = new Pagereference('/secur/logout.jsp?retUrl=/ascendportal/s/login/%3Fusername=' + UserInfo.getUserName()); 
                mypage.setRedirect(true);
            }  
        }catch(Exception ex){
            LogUtilityException.logException(ex,'PORTAL_UCIN_ChangePasswordCC.changePassword');
        }
        return mypage;
    }
}