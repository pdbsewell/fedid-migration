/*
 * @author       Kristian Vegerano
 * @date         29/07/2020
 * @description  class used by my.app welcome visualforce email template. without sharing is required for the guest user to access the offer details
 *               email content is based off from the user's offer details
 */
public without sharing class MyAppWelcomeEmailController {
    public static final String SSO_IDENTIFIER = 'SAML';
    public Boolean initialized {get;set;}    
    public String contactEmail {get;set;} 
    public String networkUrlForUserEmails {get;set;}
    
    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  Constructor
     */
    public MyAppWelcomeEmailController() {
    }
    
    public String UserContactID {
        get {
            return UserContactID;
        }
        set {
            UserContactID = value;
        }
    }
    
    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns the contact's first name
     * @revision
     * 14/09/2022   Vinothraja  SFTG-2604 Handling Mononymous names
     */
    public String getUserFirstName() {
        String userFirstName = '';
        for(User loopUser : [SELECT Id, FirstName, LastName 
                             FROM User 
                             WHERE ContactId = :UserContactID 
                             LIMIT 1]){   
            if (String.isNotBlank(loopUser.FirstName)) {
                userFirstName = loopUser.FirstName;
            } else { // Handling Mononymous named users; who will not have First Names 
                userFirstName = loopUser.LastName;
            }
        }
        return userFirstName;
    }

    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns the header content blurb
     */
    public String getHeaderContent() {
        String headerContent = 'We\'re absolutely delighted to tell you that you have an offer to study at Monash University';
        for(Opportunity loopOpportunity : [SELECT Id, SBQQ__PrimaryQuote__r.Offer_has_grant__c, SBQQ__PrimaryQuote__r.Offer_has_scholarship__c
                                           FROM Opportunity 
                                           WHERE PrimaryContact__c = :UserContactID 
                                               AND StageName = 'Publish' 
                                               AND RecordType.DeveloperName = 'Applicant_Enrolment'
                                           ORDER BY LastModifiedDate DESC
                                           LIMIT 1]){   
            if(loopOpportunity.SBQQ__PrimaryQuote__r.Offer_has_grant__c != 0){
                headerContent = headerContent + ' including a grant';
            }
            if(loopOpportunity.SBQQ__PrimaryQuote__r.Offer_has_scholarship__c != 0){
                headerContent = headerContent + ' including a scholarship';
            }
        }
        headerContent = headerContent + '.';
        return headerContent;
    }

    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns a boolean to determine if the applicant has an offer
     */
    public Boolean getHasOffer() {
        Boolean hasOffer = false;
        for(Opportunity loopOpportunity : [SELECT Id, PrimaryContact__r.Email
                                           FROM Opportunity 
                                           WHERE PrimaryContact__c = :UserContactID 
                                               AND StageName = 'Publish' 
                                               AND RecordType.DeveloperName = 'Applicant_Enrolment'
                                           ORDER BY LastModifiedDate DESC
                                           LIMIT 1]){   
            hasOffer = true;
        }
        return hasOffer;
    }

    /*
     * @author       Kristian Vegerano
     * @date         22/04/2021
     * @description  returns a boolean to determine if the latest application has been created by a partner user
     */
    public Boolean getHasPartnerInitiatedApplication() {
        Boolean hasPartnerInitiatedApplication = false;
        for(Application__c loopApplication : [SELECT Id, Owner_Profile_Name__c
                                              FROM Application__c 
                                              WHERE Applicant__c = :UserContactID 
                                                AND Status__c = 'Draft' 
                                            ORDER BY LastModifiedDate DESC
                                            LIMIT 1]){  
            if(loopApplication.Owner_Profile_Name__c.containsIgnoreCase('partner')){
                hasPartnerInitiatedApplication = true;
            }
        }
        return hasPartnerInitiatedApplication;
    }

    /*
     * @author       Kristian Vegerano
     * @date         22/04/2021
     * @description  returns the name of the partner account that sent the application on behalf of the applicant
     */
    public String getPartnerName() {
        String partnerName = '';
        for(Application__c loopApplication : [SELECT Id, Agent__r.Name
                                              FROM Application__c 
                                              WHERE Applicant__c = :UserContactID 
                                                AND Status__c = 'Draft' 
                                            ORDER BY LastModifiedDate DESC
                                            LIMIT 1]){  
            partnerName = loopApplication.Agent__r.Name;
        }
        return partnerName;
    }

    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns a boolean that determines if the applicant is under 18
     */
    public Boolean getIsUnder18() {
        Boolean isUnder18 = false;
        for(User loopUser : [SELECT Id, Contact.Under_18__c
                             FROM User 
                             WHERE ContactId = :UserContactID 
                             LIMIT 1]){   
            if(loopUser.Contact.Under_18__c){
                isUnder18 = true;
            }
        }
        return isUnder18;
    }
    
    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns boolean if the expiration message should be shown
     */
    public Boolean getIsShowExpire() {
        Boolean isShowExpire = false;
        for(Opportunity loopOpportunity : [SELECT Id, Calculated_Expiry_Date__c
                                           FROM Opportunity 
                                           WHERE PrimaryContact__c = :UserContactID 
                                               AND StageName = 'Publish' 
                                               AND RecordType.DeveloperName = 'Applicant_Enrolment'
                                           ORDER BY LastModifiedDate DESC
                                           LIMIT 1]){   
            //If quote expiry date is seven days or less from send date
            isShowExpire = loopOpportunity.Calculated_Expiry_Date__c > System.TODAY().addDays(-7);
        }
        return isShowExpire;
    }

    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns expire date of the offer
     */
    public String getExpireDate() {
        String expireDate = '';
        for(Opportunity loopOpportunity : [SELECT Id, Calculated_Expiry_Date__c
                                           FROM Opportunity 
                                           WHERE PrimaryContact__c = :UserContactID 
                                               AND StageName = 'Publish' 
                                               AND RecordType.DeveloperName = 'Applicant_Enrolment'
                                           ORDER BY LastModifiedDate DESC
                                           LIMIT 1]){   
            expireDate = DateTime.newInstance(loopOpportunity.Calculated_Expiry_Date__c.year(), loopOpportunity.Calculated_Expiry_Date__c.month(), loopOpportunity.Calculated_Expiry_Date__c.day()).format('d MMMM yyyy');
        }
        return expireDate;
    }
    
    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns if the offer's opportunity has been regenerated
     */
    public Boolean getIsOfferRegenerated() {
        Boolean isOfferRegenerated = false;
        for(Opportunity loopOpportunity : [SELECT Id, Primary_Quote_Regeneration_Date__c
                                           FROM Opportunity 
                                           WHERE PrimaryContact__c = :UserContactID 
                                               AND StageName = 'Publish' 
                                               AND RecordType.DeveloperName = 'Applicant_Enrolment'
                                           ORDER BY LastModifiedDate DESC
                                           LIMIT 1]){   
            if(loopOpportunity.Primary_Quote_Regeneration_Date__c != null){
                isOfferRegenerated = true;
            }
        }
        return isOfferRegenerated;
    }
    
    /*
     * @author       Kristian Vegerano
     * @date         29/07/2020
     * @description  returns regeneration reason
     */
    public String getOfferRegenerationReason() {
        String regenerationReason = '';
        for(Opportunity loopOpportunity : [SELECT Id, Regeneration_Reason__c
                                           FROM Opportunity 
                                           WHERE PrimaryContact__c = :UserContactID 
                                               AND StageName = 'Publish' 
                                               AND RecordType.DeveloperName = 'Applicant_Enrolment'
                                           ORDER BY LastModifiedDate DESC
                                           LIMIT 1]){   
            if(loopOpportunity.Regeneration_Reason__c != null){
                regenerationReason = loopOpportunity.Regeneration_Reason__c;
            }
        }
        return regenerationReason;
    }
    
     /*
     * @author       SMendu
     * @date         26/06/2023
     * @description  Returns true if the Application belongs to Agentportal and the status  updated to 
     *               AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT
     * @revision     
     */
    public Boolean getInitiatedSendDraftToApplicant() {
        Boolean hasInitiatedSendDraftToApplicant = false;
        for(Application__c loopApplication : [SELECT Id, Source_system__c
                                              FROM Application__c 
                                              WHERE Applicant__c = :UserContactID 
                                                AND Status__c = :AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT 
                                            ORDER BY LastModifiedDate DESC
                                            LIMIT 1]){  
            if(loopApplication.Source_system__c.containsIgnoreCase('AgentPortal')){
                hasInitiatedSendDraftToApplicant = true;
            }
        }
        return hasInitiatedSendDraftToApplicant;
    }
    
     /*
     * @author       SMendu
     * @date         26/06/2023
     * @description  returns if is the Default Application(Non agent/partner or offer)
     */
    public Boolean getDefaultApplication()
    {
        if(!getInitiatedSendDraftToApplicant() && !getHasPartnerInitiatedApplication() && !gethasOffer())
        return true;
        else return false;
    }
    
    /*
     * @author       SMendu
     * @date         26/06/2023
     * @description  returns the Agent Name 
     */
    public String getAgentName() {
        String agentName = '';
        for(Application__c loopApplication : [SELECT Id, Agent__r.Name
                                              FROM Application__c 
                                              WHERE Applicant__c = :UserContactID 
                                                AND Status__c = :AgentPortalConstants.SEND_DRAFT_APPLICATION_TO_APPLICANT
                                            ORDER BY LastModifiedDate DESC
                                            LIMIT 1]){  
                  agentName = loopApplication.Agent__r.Name;
        }
      

        return agentName;
    }

    /*
     * @author       Sethu Venna
     * @description  checks if the user logged in via SSO
     * @return       Boolean
     * @date         11/10/2024
     */
    public boolean getLoggedInViaSSO() {
        return this.isSSOUser(UserContactID);
    }

    /*
     * @author       Sethu Venna
     * @description  returns the custom settings to enable SSO login on my.app login page
     * @return       Feature_Switch__c
     * @date         11/10/2024
     */
    @AuraEnabled
    public static Feature_Switch__c fetchMyAppFeatureToggle() {
        return Feature_Switch__c.getInstance();
    }

    /*
     * @author       Sethu Venna
     * @description  returns the custom settings to enable SSO login on my.app login page
     * @return       URLs__c
     * @date         11/10/2024
     */
    @AuraEnabled
    public static URLs__c fetchURLS() {
        return URLs__c.getInstance();
    }

    /**
	 * @author          Sethu Venna
	 * @description     check whether user logged in via SSO
     * @param           contactId 
     * @return          boolean - true if logged in via SSO else false
	 * @revision        created Sethu Venna  27/09/2024
     */
    public boolean isSSOUser(String contactId) {
        
        User custUser = [SELECT Id, FederationIdentifier FROM User WHERE ContactId = :contactId LIMIT 1];
        
        if(custUser.FederationIdentifier != null)
        {
            for(LoginHistory userLoginHistory : [SELECT Id, LoginType, Status 
                                                FROM LoginHistory 
                                                WHERE NetworkId != null 
                                                AND UserId = :custUser.Id 
                                                ORDER BY LoginTime DESC 
                                                LIMIT 1]) 
            {
                LoginHistoryClass loginHistoryInstance = new LoginHistoryClass(userLoginHistory.LoginType, userLoginHistory.Status);
                if(checkSSOLoginFromHistory(loginHistoryInstance) == true) {
                    return true;
                }
            }
        }
        return false;
    }

    //method created to check the SSO login for a history record
    @TestVisible
    private boolean checkSSOLoginFromHistory(LoginHistoryClass userLoginHistory) {
        if(userLoginHistory.Status == 'Success') {
            if(userLoginHistory.LoginType.startsWithIgnoreCase(SSO_IDENTIFIER)) {
                return true;
            }
        }
        return false;
    }

    /**
	 * @author          Sethu Venna
	 * @description     created to allow TDD for Login History test class
	 * @revision        created Sethu Venna  27/09/2024
     */
    public class LoginHistoryClass {
       
        public String loginType;
        public String status;

        /**
         * @author          Sethu Venna
         * @description     constructor
         * @param           loginType - Type of the user login
         * @param           status - status of the user login - Success or Fail
         * @revision        created Sethu Venna  27/09/2024
         */
        public LoginHistoryClass(String loginType, String status) {
            this.loginType = loginType;
            this.status = status;
        }
    }
}